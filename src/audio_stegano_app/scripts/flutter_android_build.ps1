# Shared Flutter Android release build helpers (APK / App Bundle).

function Get-FlutterPubspecVersionLabel {
    param([Parameter(Mandatory = $true)][string]$FlutterProjectPath)

    $pubspec = Join-Path $FlutterProjectPath "pubspec.yaml"
    foreach ($line in Get-Content -LiteralPath $pubspec) {
        if ($line -match '^\s*version:\s*(.+?)\s*(?:#.*)?$') {
            return $Matches[1].Trim()
        }
    }
    throw "Could not read version from $pubspec"
}

function Get-SafeVersionFileToken {
    param([Parameter(Mandatory = $true)][string]$VersionLabel)
    return ($VersionLabel -replace '\+', '_' -replace '[^\w\.\-]', '_')
}

function Get-PublishedAndroidArtifactFileName {
    param(
        [Parameter(Mandatory = $true)][string]$SourceFileName,
        [Parameter(Mandatory = $true)][string]$VersionToken
    )

    if ($SourceFileName -eq 'app-release.apk') {
        return "AudioStegano_${VersionToken}.apk"
    }
    if ($SourceFileName -match '^app-(.+)-release\.apk$') {
        return "AudioStegano_${VersionToken}_$($Matches[1]).apk"
    }
    if ($SourceFileName -eq 'app-release.aab') {
        return "AudioStegano_${VersionToken}.aab"
    }

    $base = [System.IO.Path]::GetFileNameWithoutExtension($SourceFileName)
    $ext = [System.IO.Path]::GetExtension($SourceFileName)
    return "${base}_${VersionToken}${ext}"
}

function Assert-AndroidSdkAvailable {
    $sdk = $env:ANDROID_HOME
    if ([string]::IsNullOrWhiteSpace($sdk)) { $sdk = $env:ANDROID_SDK_ROOT }
    if ([string]::IsNullOrWhiteSpace($sdk) -or -not (Test-Path $sdk)) {
        throw "Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT and install SDK via Android Studio."
    }
    Write-Host "Android SDK: $sdk" -ForegroundColor DarkGray
}

function Resolve-FlutterApkOutputs {
    param(
        [Parameter(Mandatory = $true)][string]$FlutterRoot,
        [switch]$SplitPerAbi
    )

    $apkDir = Join-Path $FlutterRoot "build\app\outputs\flutter-apk"
    if (-not (Test-Path $apkDir)) {
        throw "APK output folder not found: $apkDir"
    }
    $apks = @(Get-ChildItem -Path $apkDir -Filter "*.apk" -File | Sort-Object LastWriteTime -Descending)
    if ($apks.Count -eq 0) {
        throw "No APK files under $apkDir"
    }

    if ($SplitPerAbi) {
        $arm64 = @($apks | Where-Object { $_.Name -match 'arm64-v8a' })
        if ($arm64.Count -gt 0) {
            Write-Host "APK publish: using arm64-v8a split (smallest for modern phones)." -ForegroundColor DarkGray
            return $arm64
        }
    }

    return $apks
}

function Resolve-FlutterAppBundleOutput {
    param([Parameter(Mandatory = $true)][string]$FlutterRoot)

    $aab = Join-Path $FlutterRoot "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path $aab)) {
        throw "App bundle not found. Expected '$aab'. Run 'flutter build appbundle --release'."
    }
    return (Get-Item $aab)
}

function Copy-AndroidArtifactsToPublish {
    param(
        [Parameter(Mandatory = $true)][object[]]$SourceFiles,
        [Parameter(Mandatory = $true)][string]$DestinationDir,
        [Parameter(Mandatory = $true)][string]$VersionToken
    )

    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    foreach ($src in $SourceFiles) {
        $item = if ($src -is [System.IO.FileInfo]) { $src } else { Get-Item $src.FullName }
        $destName = Get-PublishedAndroidArtifactFileName -SourceFileName $item.Name -VersionToken $VersionToken
        $dest = Join-Path $DestinationDir $destName
        if (Test-Path -LiteralPath $dest) { Remove-Item -Force $dest }
        Copy-Item -Force $item.FullName $dest
        Write-Host "  android -> $dest" -ForegroundColor Yellow
    }
}

function Invoke-FlutterAndroidReleaseBuild {
    param(
        [Parameter(Mandatory = $true)][string]$FlutterProjectPath,
        [Parameter(Mandatory = $true)][string]$FlutterExecutable,
        [Parameter(Mandatory = $true)][string]$AndroidPublishDir,
        [ValidateSet("Apk", "AppBundle", "Both")]
        [string]$AndroidArtifact = "Apk",
        [switch]$FatApk,
        [Parameter(Mandatory = $true)][scriptblock]$InvokeFlutterInProject
    )

    $androidModule = Join-Path $FlutterProjectPath "android"
    if (-not (Test-Path -LiteralPath $androidModule)) {
        throw "Android module not found: $androidModule"
    }

    Assert-AndroidSdkAvailable

    $versionLabel = Get-FlutterPubspecVersionLabel -FlutterProjectPath $FlutterProjectPath
    $versionToken = Get-SafeVersionFileToken -VersionLabel $versionLabel
    Write-Host "App version (pubspec): $versionLabel" -ForegroundColor DarkGray

    Write-Host "Flutter precache (android)..." -ForegroundColor Cyan
    & $InvokeFlutterInProject $FlutterProjectPath @("precache", "--android")

    $builtAndroidFiles = @()
    $buildApk = $AndroidArtifact -in @("Apk", "Both")
    $buildBundle = $AndroidArtifact -in @("AppBundle", "Both")

    if ($buildApk) {
        $useSplitAbi = -not $FatApk
        $apkArgs = @("build", "apk", "--release", "--tree-shake-icons")
        if ($useSplitAbi) { $apkArgs += "--split-per-abi" }
        Write-Host "Building Android APK (release$(if ($useSplitAbi) { ', split-per-abi arm64' } else { ', universal' }))..." -ForegroundColor Cyan
        & $InvokeFlutterInProject $FlutterProjectPath $apkArgs
        $builtAndroidFiles += Resolve-FlutterApkOutputs -FlutterRoot $FlutterProjectPath -SplitPerAbi:$useSplitAbi
    }

    if ($buildBundle) {
        Write-Host "Building Android App Bundle (release)..." -ForegroundColor Cyan
        & $InvokeFlutterInProject $FlutterProjectPath @("build", "appbundle", "--release")
        $builtAndroidFiles += Resolve-FlutterAppBundleOutput -FlutterRoot $FlutterProjectPath
    }

    Write-Host "Publishing Android artifacts to $AndroidPublishDir ..." -ForegroundColor Cyan
    Copy-AndroidArtifactsToPublish -SourceFiles $builtAndroidFiles -DestinationDir $AndroidPublishDir -VersionToken $versionToken

    return @{
        VersionLabel = $versionLabel
        VersionToken = $versionToken
        PublishDir   = $AndroidPublishDir
    }
}
