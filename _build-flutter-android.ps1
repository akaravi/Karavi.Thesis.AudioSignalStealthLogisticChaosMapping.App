<#
.SYNOPSIS
  Build Flutter Android release (APK and/or App Bundle) for audio_stegano_app.

.EXAMPLE
  .\_build-flutter-android.ps1 -ZipOutputDirectory D:\PublishKaravi\ThesisAudioStegano

.EXAMPLE
  .\_build-flutter-android.ps1 -SkipPackage -AndroidArtifact AppBundle -UseFlutterIoCnMirror
#>
param(
    [switch]$SkipRestore,
    [switch]$SkipPackage,
    [string]$ZipOutputDirectory = "",
    [switch]$PackageOnly,
    [ValidateSet("Apk", "AppBundle", "Both")]
    [string]$AndroidArtifact = "Apk",
    [switch]$FatApk,
    [switch]$OfflinePubGet,
    [string]$PubHostedUrl = "",
    [string]$FlutterStorageBaseUrl = "",
    [switch]$UseFlutterIoCnMirror,
    [switch]$DisableAutoMirrorRetry,
    [switch]$OpenDeveloperSettings,
    [switch]$SkipTests,
    [switch]$SkipFlutterAnalyze,
    [string]$AndroidOutputDirectory = ""
)

$ErrorActionPreference = "Stop"

$savedEnvPubHostedAtScriptStart = $env:PUB_HOSTED_URL
$userSuppliedMirrorViaParam = $UseFlutterIoCnMirror -or (-not [string]::IsNullOrWhiteSpace($PubHostedUrl))

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterAppPath = Join-Path $root "src\audio_stegano_app"
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

function Invoke-AndroidZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipDirectory,
        [Parameter(Mandatory = $true)][string]$AndroidPublishDir,
        [Parameter(Mandatory = $true)][string]$VersionToken
    )

    if (-not (Test-Path $AndroidPublishDir)) {
        throw "Android publish folder not found: $AndroidPublishDir"
    }

    $artifacts = @(
        Get-ChildItem -Path $AndroidPublishDir -File -Filter "*.apk" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $AndroidPublishDir -File -Filter "*.aab" -ErrorAction SilentlyContinue
    )
    if ($artifacts.Count -eq 0) {
        throw "No APK/AAB files in $AndroidPublishDir for ZIP."
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $resolvedZipDir = Resolve-ExistingOrNewDirectory -Path $ZipDirectory
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "KaraviThesis_AudioStegano_Android_${VersionToken}_$stamp.zip"
    $zipFullPath = Join-Path $resolvedZipDir $zipName
    $stageRoot = Join-Path $root "publish\android-staging"
    if (Test-Path $stageRoot) { Remove-Item -Recurse -Force $stageRoot }
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

    foreach ($f in $artifacts) {
        Copy-Item -Force $f.FullName (Join-Path $stageRoot $f.Name)
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

$flutterAndroidBuildHelper = Join-Path $flutterAppPath "scripts\flutter_android_build.ps1"
if (-not (Test-Path -LiteralPath $flutterAndroidBuildHelper)) {
    throw "Flutter Android build helper was not found: $flutterAndroidBuildHelper"
}
. $flutterAndroidBuildHelper

$flutterInvokeSb = {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )
    Invoke-FlutterInProject -ProjectDirectory $ProjectDirectory -ArgumentList $ArgumentList
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

$appVersionLabel = Get-FlutterPubspecVersionLabel -FlutterProjectPath $flutterAppPath
$appVersionFileToken = Get-SafeVersionFileToken -VersionLabel $appVersionLabel
Write-Host "App version (pubspec): $appVersionLabel" -ForegroundColor DarkGray

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
        Write-Host 'مسیر پوشه برای ZIP خروجی Android را وارد کنید:' -ForegroundColor Cyan
        $ZipOutputDirectory = Read-Host 'ZIP output folder path'
    }
    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        throw "ZIP folder required. Use -ZipOutputDirectory or -SkipPackage."
    }
}

if ($PackageOnly) {
    if ($SkipPackage) {
        throw "-PackageOnly requires ZIP output; do not combine with -SkipPackage."
    }
    Write-Host "Packaging existing Android artifacts (no build)..." -ForegroundColor Cyan
    Invoke-AndroidZip -ZipDirectory $ZipOutputDirectory -AndroidPublishDir $androidPublishDir -VersionToken $appVersionFileToken
    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
    Write-Host "  Android publish: $androidPublishDir" -ForegroundColor Yellow
    exit 0
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

$androidBuildResult = Invoke-FlutterAndroidReleaseBuild `
    -FlutterProjectPath $flutterAppPath `
    -FlutterExecutable $flutterCommand `
    -AndroidPublishDir $androidPublishDir `
    -AndroidArtifact $AndroidArtifact `
    -FatApk:$FatApk `
    -InvokeFlutterInProject $flutterInvokeSb
$appVersionFileToken = $androidBuildResult.VersionToken

if (-not $SkipPackage) {
    Invoke-AndroidZip -ZipDirectory $ZipOutputDirectory -AndroidPublishDir $androidPublishDir -VersionToken $appVersionFileToken
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  Android publish: $androidPublishDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tips:" -ForegroundColor DarkYellow
Write-Host "  -AndroidArtifact Apk|AppBundle|Both  -FatApk (universal, larger)  -SkipPackage" -ForegroundColor DarkYellow
Write-Host "  -UseFlutterIoCnMirror  -ZipOutputDirectory <path>  -PackageOnly (ZIP only)" -ForegroundColor DarkYellow
