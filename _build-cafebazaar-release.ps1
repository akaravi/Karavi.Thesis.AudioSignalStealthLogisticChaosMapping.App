<#
.SYNOPSIS
  Build signed Android release artifacts for Cafe Bazaar (AAB + arm64 APK).

.EXAMPLE
  # One-time: create keystore
  .\src\audio_stegano_app\android\scripts\create_release_keystore.ps1
  Copy-Item src\audio_stegano_app\android\key.properties.example src\audio_stegano_app\android\key.properties
  # Edit key.properties with your passwords

  .\_build-cafebazaar-release.ps1
  .\_build-cafebazaar-release.ps1 -OutputDirectory D:\PublishKaravi\CafeBazaar
  # Default output: publish\cafebazaar_yyyyMMdd_HHmmss
#>
param(
    [string]$OutputDirectory = "",
    [string]$BundleSignerJarPath = "",
    [switch]$SkipRestore,
    [switch]$ApkOnly,
    [switch]$AabOnly,
    [switch]$SkipBundleSigner,
    [switch]$UseFlutterIoCnMirror,
    [switch]$OfflinePubGet,
    [switch]$DisableAutoMirrorRetry,
    [switch]$OpenDeveloperSettings
)

$ErrorActionPreference = "Stop"

$savedEnvPubHostedAtScriptStart = $env:PUB_HOSTED_URL
$userSuppliedMirrorViaParam = $UseFlutterIoCnMirror

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterAppPath = Join-Path $root "src\audio_stegano_app"
$androidRoot = Join-Path $flutterAppPath "android"
$keyProperties = Join-Path $androidRoot "key.properties"
$cafeBazaarTemplateRoot = Join-Path $root "publish\cafebazaar"

function New-CafeBazaarTimestampedOutputPath {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [string]$OutputDirectory
    )
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        return Join-Path $RepoRoot "publish\cafebazaar_$stamp"
    }
    return "${OutputDirectory}_$stamp"
}

if (-not (Test-Path -LiteralPath $keyProperties)) {
    throw @"
Release signing not configured.
  1. Run: .\src\audio_stegano_app\android\scripts\create_release_keystore.ps1
  2. Copy key.properties.example to android\key.properties and fill passwords
  3. Re-run this script
"@
}

$flutterCandidates = @(
    if ($env:FLUTTER_HOME) { Join-Path $env:FLUTTER_HOME "bin\flutter.bat" }
    if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT "bin\flutter.bat" }
    if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "Programs\Flutter\bin\flutter.bat" }
    "D:\Android\flutter\bin\flutter.bat"
)
$flutterCmd = $null
foreach ($c in $flutterCandidates) {
    if ($c -and (Test-Path $c)) { $flutterCmd = $c; break }
}
if (-not $flutterCmd) {
    $fc = Get-Command flutter -ErrorAction SilentlyContinue
    if ($fc) { $flutterCmd = $fc.Source }
}
if (-not $flutterCmd) { throw "Flutter not found." }

if ($UseFlutterIoCnMirror) {
    $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
    $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
}

$androidBuildScript = Join-Path $flutterAppPath "scripts\flutter_android_build.ps1"
. $androidBuildScript

$sdk = $env:ANDROID_HOME
if ([string]::IsNullOrWhiteSpace($sdk)) { $sdk = $env:ANDROID_SDK_ROOT }
if ([string]::IsNullOrWhiteSpace($sdk) -or -not (Test-Path $sdk)) {
    throw "ANDROID_HOME / ANDROID_SDK_ROOT required."
}

$appSettingsScript = Join-Path $flutterAppPath "scripts\copy_appsettings_to_flutter_outputs.ps1"
if (Test-Path -LiteralPath $appSettingsScript) {
    . $appSettingsScript
    Sync-AppSettingsToFlutterProjectAssets -RepoRoot $root -FlutterProjectPath $flutterAppPath
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
    Write-Host "flutter pub get failed. Try VPN/proxy, -UseFlutterIoCnMirror, or -OfflinePubGet." -ForegroundColor Yellow
}

function Convert-FlutterPubOutputToLogText {
    param([object[]]$Lines)
    return (($Lines | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message }
            else { "$_" }
        }) -join [Environment]::NewLine)
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

function Invoke-FlutterPubGetForCafeBazaar {
    param([Parameter(Mandatory = $true)][string]$ProjectDirectory)

    Write-Host "flutter pub get ..." -ForegroundColor Cyan
    $pubArgs = @("pub", "get")
    if ($OfflinePubGet) { $pubArgs += "--offline" }

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
                $pubGetOutput = @(& $flutterCmd @pubArgs 2>&1)
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
            Write-Host "flutter pub get: dependencies resolved; ignoring Windows symlink warning (Android build can continue)." -ForegroundColor Yellow
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

if (-not $SkipRestore) {
    Invoke-FlutterPubGetForCafeBazaar -ProjectDirectory $flutterAppPath
}

$outDir = New-CafeBazaarTimestampedOutputPath -RepoRoot $root -OutputDirectory $OutputDirectory
Write-Host "Cafe Bazaar output folder: $outDir" -ForegroundColor DarkCyan
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$outDir = (Resolve-Path -LiteralPath $outDir).Path

$flutterInvokeSb = {
    param([string]$ProjectDirectory, [string[]]$ArgumentList)
    Push-Location $ProjectDirectory
    try {
        & $flutterCmd @ArgumentList
        if ($LASTEXITCODE -ne 0) {
            throw "flutter failed: $($ArgumentList -join ' ')"
        }
    }
    finally { Pop-Location }
}

$artifact = if ($ApkOnly) { "Apk" } elseif ($AabOnly) { "AppBundle" } else { "Both" }
Write-Host "Signed Android release for Cafe Bazaar ($artifact) ..." -ForegroundColor Cyan
$null = Invoke-FlutterAndroidReleaseBuild `
    -FlutterProjectPath $flutterAppPath `
    -FlutterExecutable $flutterCmd `
    -AndroidPublishDir $outDir `
    -AndroidArtifact $artifact `
    -InvokeFlutterInProject $flutterInvokeSb

if (Test-Path -LiteralPath $appSettingsScript) {
    Copy-AppSettingsToFlutterDeployOutputs `
        -RepoRoot $root `
        -FlutterProjectPath $flutterAppPath `
        -IncludeAndroidPublish `
        -AndroidPublishDir $outDir
}

$buildsAab = $artifact -in @("AppBundle", "Both")
if ($buildsAab -and -not $SkipBundleSigner) {
    $bundleSignerScript = Join-Path $androidRoot "scripts\Invoke-CafeBazaarBundleSigner.ps1"
    $aabCandidates = @(Get-ChildItem -Path $outDir -Filter "AudioStegano_*.aab" -File | Sort-Object LastWriteTime -Descending)
    if ($aabCandidates.Count -eq 0) {
        throw "AAB expected in $outDir for Cafe Bazaar bundle-signer but none found."
    }
    Write-Host "Cafe Bazaar bundle-signer (upload .bin per Bazaar guidelines) ..." -ForegroundColor Cyan
    $signerArgs = @{
        BundlePath      = $aabCandidates[0].FullName
        OutputDirectory = $outDir
    }
    if (-not [string]::IsNullOrWhiteSpace($BundleSignerJarPath)) {
        $signerArgs["BundleSignerJarPath"] = $BundleSignerJarPath
    }
    $null = & $bundleSignerScript @signerArgs
}

$mappingSrc = Join-Path $flutterAppPath "build\app\outputs\mapping\release\mapping.txt"
if (Test-Path -LiteralPath $mappingSrc) {
    $versionLabel = Get-FlutterPubspecVersionLabel -FlutterProjectPath $flutterAppPath
    $token = Get-SafeVersionFileToken -VersionLabel $versionLabel
    Copy-Item -Force $mappingSrc (Join-Path $outDir "mapping_${token}.txt")
    Write-Host "ProGuard mapping copied (store for crash deobfuscation)." -ForegroundColor DarkCyan
}

$listingSrc = Join-Path $cafeBazaarTemplateRoot "LISTING.fa.md"
if ((Test-Path -LiteralPath $listingSrc) -and (Resolve-Path $outDir).Path -ne (Resolve-Path (Split-Path $listingSrc)).Path) {
    Copy-Item -Force $listingSrc (Join-Path $outDir "LISTING.fa.md")
}

Write-Host ""
Write-Host "Cafe Bazaar release artifacts:" -ForegroundColor Green
Get-ChildItem -Path $outDir -File | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Yellow }
Write-Host ""
Write-Host "Upload the .bin from bundle-signer (AAB flow) or signed APK at https://developers.cafebazaar.ir/" -ForegroundColor Cyan
Write-Host "Bundle-signer guide: https://developers.cafebazaar.ir/fa/guidelines/feature/app_bundle#Bundle-Signer" -ForegroundColor DarkGray
Write-Host "See docs/cafebazaar-publish-guide.md and LISTING.fa.md in the output folder." -ForegroundColor DarkYellow
