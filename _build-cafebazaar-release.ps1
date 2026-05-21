<#
.SYNOPSIS
  Build signed Android release artifacts for Cafe Bazaar (AAB + arm64 APK).

.EXAMPLE
  # One-time: create keystore
  .\src\audio_steg_app\android\scripts\create_release_keystore.ps1
  Copy-Item src\audio_steg_app\android\key.properties.example src\audio_steg_app\android\key.properties
  # Edit key.properties with your passwords

  .\_build-cafebazaar-release.ps1
  .\_build-cafebazaar-release.ps1 -OutputDirectory D:\PublishKaravi\CafeBazaar
#>
param(
    [string]$OutputDirectory = "",
    [switch]$SkipRestore,
    [switch]$ApkOnly,
    [switch]$AabOnly,
    [switch]$UseFlutterIoCnMirror,
    [switch]$OfflinePubGet
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterAppPath = Join-Path $root "src\audio_steg_app"
$androidRoot = Join-Path $flutterAppPath "android"
$keyProperties = Join-Path $androidRoot "key.properties"
$defaultOut = Join-Path $root "publish\cafebazaar"

if (-not (Test-Path -LiteralPath $keyProperties)) {
    throw @"
Release signing not configured.
  1. Run: .\src\audio_steg_app\android\scripts\create_release_keystore.ps1
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

if (-not $SkipRestore) {
    Write-Host "flutter pub get ..." -ForegroundColor Cyan
    Push-Location $flutterAppPath
    try {
        $pubArgs = @("pub", "get")
        if ($OfflinePubGet) { $pubArgs += "--offline" }
        & $flutterCmd @pubArgs
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
    }
    finally { Pop-Location }
}

$outDir = if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $defaultOut } else { $OutputDirectory }
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$outDir = (Resolve-Path -LiteralPath $outDir).Path

$flutterInvokeSb = {
    param([string]$ProjectDirectory, [string[]]$ArgumentList)
    Push-Location $ProjectDirectory
    try {
        & $using:flutterCmd @ArgumentList
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

$mappingSrc = Join-Path $flutterAppPath "build\app\outputs\mapping\release\mapping.txt"
if (Test-Path -LiteralPath $mappingSrc) {
    $versionLabel = Get-FlutterPubspecVersionLabel -FlutterProjectPath $flutterAppPath
    $token = Get-SafeVersionFileToken -VersionLabel $versionLabel
    Copy-Item -Force $mappingSrc (Join-Path $outDir "mapping_${token}.txt")
    Write-Host "ProGuard mapping copied (store for crash deobfuscation)." -ForegroundColor DarkCyan
}

$listingSrc = Join-Path $root "publish\cafebazaar\LISTING.fa.md"
if ((Resolve-Path $outDir).Path -ne (Resolve-Path (Split-Path $listingSrc)).Path) {
    Copy-Item -Force $listingSrc (Join-Path $outDir "LISTING.fa.md")
}

Write-Host ""
Write-Host "Cafe Bazaar release artifacts:" -ForegroundColor Green
Get-ChildItem -Path $outDir -File | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Yellow }
Write-Host ""
Write-Host "Upload the .aab (or signed APK) at https://developers.cafebazaar.ir/" -ForegroundColor Cyan
Write-Host "See LISTING.fa.md for Persian store text and checklist." -ForegroundColor DarkYellow
