<#
.SYNOPSIS
  Build Flutter Android (APK/AAB) and Web release for audio_steg_app.

.EXAMPLE
  .\_build-android-web.ps1 -ZipOutputDirectory D:\PublishKaravi\ThesisAudioSteg

.EXAMPLE
  .\_build-android-web.ps1 -SkipPackage -AndroidArtifact AppBundle -UseFlutterIoCnMirror
#>
param(
    [switch]$SkipRestore,
    [switch]$SkipPackage,
    [string]$ZipOutputDirectory = "",
    [switch]$PackageOnly,
    [switch]$SkipAndroid,
    [switch]$SkipWeb,
    [ValidateSet("Apk", "AppBundle", "Both")]
    [string]$AndroidArtifact = "Apk",
    [switch]$SplitPerAbi,
    [switch]$OfflinePubGet,
    [string]$PubHostedUrl = "",
    [string]$FlutterStorageBaseUrl = "",
    [switch]$UseFlutterIoCnMirror,
    [switch]$DisableAutoMirrorRetry,
    [switch]$OpenDeveloperSettings,
    [switch]$SkipTests,
    [switch]$SkipFlutterAnalyze,
    [string]$WebBaseHref = "/",
    [string]$WebOutputDirectory = "",
    [string]$AndroidOutputDirectory = ""
)

$ErrorActionPreference = "Stop"

$savedEnvPubHostedAtScriptStart = $env:PUB_HOSTED_URL
$userSuppliedMirrorViaParam = $UseFlutterIoCnMirror -or (-not [string]::IsNullOrWhiteSpace($PubHostedUrl))

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterAppPath = Join-Path $root "src\audio_steg_app"
$defaultWebPublishDir = Join-Path $root "publish\flutter\web"
$defaultAndroidPublishDir = Join-Path $root "publish\flutter\android"

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [string[]]$CandidatePaths = @()
    )

    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($candidate in $CandidatePaths) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        if (Test-Path $expanded) { return $expanded }
    }
    return $null
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)][string]$PathToCheck,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if (-not (Test-Path $PathToCheck)) {
        throw "$Label was not found: $PathToCheck"
    }
}

function Resolve-ExistingOrNewDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return (New-Item -ItemType Directory -Path $Path -Force).FullName
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Normalize-WebBaseHref {
    param([string]$BaseHref)
    $normalized = $BaseHref.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) { $normalized = "/" }
    if (-not $normalized.EndsWith("/")) { $normalized = "$normalized/" }
    if (-not $normalized.StartsWith("/")) { $normalized = "/$normalized" }
    return $normalized
}

function Write-PubGet403Hints {
    Write-Host ""
    Write-Host "flutter pub get failed. Try VPN/proxy, -UseFlutterIoCnMirror, or -OfflinePubGet." -ForegroundColor Yellow
    Write-Host "  Auto-retry: flutter-io.cn then Tsinghua (-DisableAutoMirrorRetry to skip)." -ForegroundColor Yellow
}

function Test-FlutterPubGetPackagesResolved {
    param([Parameter(Mandatory = $true)][string]$ProjectDirectory)
    return (Test-Path (Join-Path $ProjectDirectory ".dart_tool\package_config.json"))
}

function Test-FlutterPubGetSymlinkOnlyWarning {
    param([Parameter(Mandatory = $true)][string]$LogText)
    return $LogText -match '(?i)Developer Mode|symlink support'
}

function Write-FlutterPubGetFailureHints {
    param(
        [Parameter(Mandatory = $true)][string]$LogText,
        [switch]$LaunchDeveloperSettingsPage
    )
    if ($LogText -match '(?i)Developer Mode|symlink support') {
        Write-Host "flutter pub get: enable Windows Developer Mode (symlink support):" -ForegroundColor Yellow
        Write-Host "  start ms-settings:developers" -ForegroundColor White
        if ($LaunchDeveloperSettingsPage) {
            try { Start-Process "ms-settings:developers" -ErrorAction Stop } catch { }
        }
        return
    }
    Write-PubGet403Hints
}

function Write-FlutterPubOutputLines {
    param([object[]]$Lines)
    foreach ($item in $Lines) {
        if ($item -is [System.Management.Automation.ErrorRecord]) {
            $msg = $item.Exception.Message
            if (-not [string]::IsNullOrWhiteSpace($msg)) { Write-Host $msg }
        }
        else { Write-Host $item }
    }
}

function Convert-FlutterPubOutputToLogText {
    param([object[]]$Lines)
    return (($Lines | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message }
            else { "$_" }
        }) -join [Environment]::NewLine)
}

function Invoke-FlutterPubGetWithMirrorRetry {
    param([Parameter(Mandatory = $true)][string]$ProjectDirectory)

    $tryAutoMirror = -not $DisableAutoMirrorRetry -and -not $OfflinePubGet -and -not $userSuppliedMirrorViaParam -and [string]::IsNullOrWhiteSpace($savedEnvPubHostedAtScriptStart)
    $mirrorFallbacks = @(
        @{ Label = "flutter-io.cn"; Pub = "https://pub.flutter-io.cn"; Storage = "https://storage.flutter-io.cn" }
        @{ Label = "Tsinghua"; Pub = "https://mirrors.tuna.tsinghua.edu.cn/dart-pub/"; Storage = "https://mirrors.tuna.tsinghua.edu.cn/flutter" }
    )
    $maxAttempts = if ($tryAutoMirror) { 1 + $mirrorFallbacks.Count } else { 1 }
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $attempt++
        $exitCode = 0
        $pubLogText = ""
        Push-Location $ProjectDirectory
        try {
            $prevEap = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $pubGetOutput = @(& $flutterCommand @flutterPubGetArgs 2>&1)
                Write-FlutterPubOutputLines -Lines $pubGetOutput
                $exitCode = $LASTEXITCODE
                $pubLogText = Convert-FlutterPubOutputToLogText -Lines $pubGetOutput
            }
            finally { $ErrorActionPreference = $prevEap }
        }
        finally { Pop-Location }

        if ($exitCode -eq 0) { return }
        if ((Test-FlutterPubGetSymlinkOnlyWarning -LogText $pubLogText) -and
            (Test-FlutterPubGetPackagesResolved -ProjectDirectory $ProjectDirectory)) {
            Write-Host "flutter pub get: dependencies resolved; ignoring symlink warning." -ForegroundColor Yellow
            return
        }
        if ($OfflinePubGet) {
            Write-FlutterPubGetFailureHints -LogText $pubLogText
            throw "flutter pub get failed (exit $exitCode)"
        }
        if ($attempt -lt $maxAttempts -and $tryAutoMirror) {
            $mirror = $mirrorFallbacks[$attempt - 1]
            Write-Host "Retry $($attempt + 1)/$maxAttempts with $($mirror.Label) mirror..." -ForegroundColor Yellow
            $env:PUB_HOSTED_URL = $mirror.Pub
            $env:FLUTTER_STORAGE_BASE_URL = $mirror.Storage
            continue
        }
        Write-FlutterPubGetFailureHints -LogText $pubLogText -LaunchDeveloperSettingsPage:$OpenDeveloperSettings
        throw "flutter pub get failed (exit $exitCode)"
    }
}

function Invoke-FlutterInProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )
    Push-Location $ProjectDirectory
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & $flutterCommand @ArgumentList
            if ($LASTEXITCODE -ne 0) {
                throw "Flutter failed (exit $LASTEXITCODE): flutter $($ArgumentList -join ' ')"
            }
        }
        finally { $ErrorActionPreference = $prevEap }
    }
    finally { Pop-Location }
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
    param([Parameter(Mandatory = $true)][string]$FlutterRoot)

    $apkDir = Join-Path $FlutterRoot "build\app\outputs\flutter-apk"
    if (-not (Test-Path $apkDir)) {
        throw "APK output folder not found: $apkDir"
    }
    $apks = @(Get-ChildItem -Path $apkDir -Filter "*.apk" -File | Sort-Object LastWriteTime -Descending)
    if ($apks.Count -eq 0) {
        throw "No APK files under $apkDir"
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
        [Parameter(Mandatory = $true)][string]$DestinationDir
    )

    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    foreach ($src in $SourceFiles) {
        $item = if ($src -is [System.IO.FileInfo]) { $src } else { Get-Item $src.FullName }
        $dest = Join-Path $DestinationDir $item.Name
        Copy-Item -Force $item.FullName $dest
        Write-Host "  android -> $dest" -ForegroundColor Yellow
    }
}

function Copy-FlutterWebToPublish {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$DestinationDir
    )
    if (Test-Path $DestinationDir) { Remove-Item -Recurse -Force $DestinationDir }
    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    Copy-Item -Recurse -Force (Join-Path $SourceDir "*") $DestinationDir
    Write-Host "  web build -> $SourceDir" -ForegroundColor Yellow
    Write-Host "  web copy  -> $DestinationDir" -ForegroundColor Yellow
}

function Invoke-AndroidWebZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipDirectory,
        [Parameter(Mandatory = $true)][string]$AndroidPublishDir,
        [Parameter(Mandatory = $true)][string]$WebPublishDir,
        [switch]$IncludeWeb,
        [switch]$IncludeAndroid
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $resolvedZipDir = Resolve-ExistingOrNewDirectory -Path $ZipDirectory
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "KaraviThesis_AudioSteg_AndroidWeb_$stamp.zip"
    $zipFullPath = Join-Path $resolvedZipDir $zipName
    $stageRoot = Join-Path $root "publish\android-web-staging"
    if (Test-Path $stageRoot) { Remove-Item -Recurse -Force $stageRoot }
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

    if ($IncludeAndroid -and (Test-Path $AndroidPublishDir)) {
        $stageAndroid = Join-Path $stageRoot "android"
        New-Item -ItemType Directory -Path $stageAndroid -Force | Out-Null
        $artifacts = @(
            Get-ChildItem -Path $AndroidPublishDir -File -Filter "*.apk" -ErrorAction SilentlyContinue
            Get-ChildItem -Path $AndroidPublishDir -File -Filter "*.aab" -ErrorAction SilentlyContinue
        )
        if ($artifacts.Count -eq 0) {
            throw "No APK/AAB files in $AndroidPublishDir for ZIP staging."
        }
        foreach ($f in $artifacts) {
            Copy-Item -Force $f.FullName (Join-Path $stageAndroid $f.Name)
        }
    }
    if ($IncludeWeb -and (Test-Path $WebPublishDir)) {
        Copy-Item -Recurse -Force $WebPublishDir (Join-Path $stageRoot "web")
    }

    if (Test-Path $zipFullPath) { Remove-Item -Force $zipFullPath }
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stageRoot, $zipFullPath,
        [System.IO.Compression.CompressionLevel]::Optimal, $false)
    Remove-Item -Recurse -Force $stageRoot
    Write-Host ""
    Write-Host "ZIP created: $zipFullPath" -ForegroundColor Green
}

# --- Flutter CLI ---
$flutterCandidates = @(
    if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_HOME)) { Join-Path $env:FLUTTER_HOME "bin\flutter.bat" }
    if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) { Join-Path $env:FLUTTER_ROOT "bin\flutter.bat" }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { Join-Path $env:LOCALAPPDATA "Programs\Flutter\bin\flutter.bat" }
    "D:\Android\flutter\bin\flutter.bat"
    "C:\src\flutter\bin\flutter.bat"
)
$flutterCommand = Resolve-CommandPath -CommandName "flutter" -CandidatePaths $flutterCandidates
if (-not $flutterCommand) {
    throw "Flutter was not found. Add Flutter to PATH or set FLUTTER_HOME/FLUTTER_ROOT."
}

if ($UseFlutterIoCnMirror) {
    if ([string]::IsNullOrWhiteSpace($PubHostedUrl)) { $PubHostedUrl = "https://pub.flutter-io.cn" }
    if ([string]::IsNullOrWhiteSpace($FlutterStorageBaseUrl)) { $FlutterStorageBaseUrl = "https://storage.flutter-io.cn" }
    Write-Host "Using flutter-io.cn mirror for pub/flutter assets." -ForegroundColor DarkCyan
}
if (-not [string]::IsNullOrWhiteSpace($PubHostedUrl)) { $env:PUB_HOSTED_URL = $PubHostedUrl }
if (-not [string]::IsNullOrWhiteSpace($FlutterStorageBaseUrl)) { $env:FLUTTER_STORAGE_BASE_URL = $FlutterStorageBaseUrl }

$flutterPubGetArgs = @("pub", "get")
if ($OfflinePubGet) { $flutterPubGetArgs += "--offline" }

Assert-PathExists -PathToCheck $flutterAppPath -Label "Flutter project"
Assert-PathExists -PathToCheck (Join-Path $flutterAppPath "android") -Label "Android module"

if ($SkipAndroid -and $SkipWeb) {
    throw "Both -SkipAndroid and -SkipWeb are set; nothing to build."
}

$webPublishDir = $defaultWebPublishDir
if (-not [string]::IsNullOrWhiteSpace($WebOutputDirectory)) {
    $webPublishDir = Resolve-ExistingOrNewDirectory -Path $WebOutputDirectory
}
if (-not [string]::IsNullOrWhiteSpace($AndroidOutputDirectory)) {
    $androidPublishDir = Resolve-ExistingOrNewDirectory -Path $AndroidOutputDirectory
}
elseif (-not [string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
    $androidPublishDir = Resolve-ExistingOrNewDirectory -Path $ZipOutputDirectory
}
else {
    $androidPublishDir = $defaultAndroidPublishDir
}

if (-not $SkipPackage) {
    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        Write-Host 'مسیر پوشه برای ZIP خروجی Android + Web را وارد کنید:' -ForegroundColor Cyan
        $ZipOutputDirectory = Read-Host 'ZIP output folder path'
    }
    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        throw "ZIP folder required. Use -ZipOutputDirectory or -SkipPackage."
    }
}

if (-not $SkipRestore) {
    Write-Host "Preparing Flutter dependencies..." -ForegroundColor Cyan
    Invoke-FlutterPubGetWithMirrorRetry -ProjectDirectory $flutterAppPath
}

if (-not $SkipFlutterAnalyze) {
    Write-Host "Flutter analyze..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("analyze", "--no-fatal-infos")
}

if (-not $SkipTests) {
    Write-Host "Flutter test..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("test")
}

$builtAndroidFiles = @()

if (-not $SkipAndroid) {
    Assert-AndroidSdkAvailable
    Write-Host "Flutter precache (android)..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("precache", "--android")
    $buildApk = $AndroidArtifact -in @("Apk", "Both")
    $buildBundle = $AndroidArtifact -in @("AppBundle", "Both")

    if ($buildApk) {
        $apkArgs = @("build", "apk", "--release")
        if ($SplitPerAbi) { $apkArgs += "--split-per-abi" }
        Write-Host "Building Android APK (release$(if ($SplitPerAbi) { ', split-per-abi' }))..." -ForegroundColor Cyan
        Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList $apkArgs
        $builtAndroidFiles += Resolve-FlutterApkOutputs -FlutterRoot $flutterAppPath
    }

    if ($buildBundle) {
        Write-Host "Building Android App Bundle (release)..." -ForegroundColor Cyan
        Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("build", "appbundle", "--release")
        $builtAndroidFiles += Resolve-FlutterAppBundleOutput -FlutterRoot $flutterAppPath
    }

    Write-Host "Publishing Android artifacts..." -ForegroundColor Cyan
    Copy-AndroidArtifactsToPublish -SourceFiles $builtAndroidFiles -DestinationDir $androidPublishDir
}

if (-not $SkipWeb) {
    $normalizedWebBaseHref = Normalize-WebBaseHref -BaseHref $WebBaseHref
    Write-Host "Building Flutter web (release, base-href=$normalizedWebBaseHref)..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @(
        "build", "web", "--release", "--base-href=$normalizedWebBaseHref"
    )
    $webRelease = Join-Path $flutterAppPath "build\web"
    $indexPath = Join-Path $webRelease "index.html"
    if (-not (Test-Path $indexPath)) {
        throw "Web build output missing: $indexPath"
    }
    Write-Host "Publishing web..." -ForegroundColor Cyan
    Copy-FlutterWebToPublish -SourceDir $webRelease -DestinationDir $webPublishDir
}

if (-not $SkipPackage) {
    Invoke-AndroidWebZip `
        -ZipDirectory $ZipOutputDirectory `
        -AndroidPublishDir $androidPublishDir `
        -WebPublishDir $webPublishDir `
        -IncludeAndroid:(-not $SkipAndroid) `
        -IncludeWeb:(-not $SkipWeb)
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
if (-not $SkipAndroid) {
    Write-Host "  Android publish: $androidPublishDir" -ForegroundColor Yellow
}
if (-not $SkipWeb) {
    Write-Host "  Web publish:     $webPublishDir" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Tips:" -ForegroundColor DarkYellow
Write-Host "  -AndroidArtifact Apk|AppBundle|Both  -SplitPerAbi  -SkipWeb  -SkipAndroid" -ForegroundColor DarkYellow
Write-Host "  -SkipPackage  -UseFlutterIoCnMirror  -ZipOutputDirectory <path>" -ForegroundColor DarkYellow

if ($PackageOnly) { exit 0 }
