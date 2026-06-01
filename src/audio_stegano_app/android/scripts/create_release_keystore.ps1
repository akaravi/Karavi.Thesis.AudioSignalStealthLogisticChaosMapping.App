# Legacy: creates upload-keystore.jks in the android module (dev / experiments only).
# Store release builds MUST use: E:\BANK Android Key publish\key.jks (see android-release-signing.mdc).
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$signingModule = Join-Path $repoRoot "_android-release-signing.ps1"
if (Test-Path -LiteralPath $signingModule) {
    . $signingModule
    $official = Get-KaraviAndroidPublishKeystorePath
    if (Test-Path -LiteralPath $official) {
        Write-Host "Official publish keystore already exists — use that for release builds:" -ForegroundColor Yellow
        Write-Host "  $official" -ForegroundColor White
        Write-Host "Aborting local upload-keystore creation." -ForegroundColor Yellow
        exit 0
    }
}

$androidRoot = Split-Path -Parent $PSScriptRoot
$keystorePath = Join-Path $androidRoot "upload-keystore.jks"

if (Test-Path -LiteralPath $keystorePath) {
    throw "Keystore already exists: $keystorePath — delete manually only if you intend to replace it."
}

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    throw "keytool not found. Install JDK and add bin to PATH."
}

Write-Host "Creating release keystore (validity 10000 days)..." -ForegroundColor Cyan
Write-Host "  Path: $keystorePath" -ForegroundColor DarkGray
Write-Host "You will be prompted for keystore password, key password, and certificate fields." -ForegroundColor Yellow

& keytool -genkey -v `
    -keystore $keystorePath `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias upload `
    -storetype JKS

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1. Copy key.properties.example to android/key.properties" -ForegroundColor White
Write-Host "  2. Set storePassword, keyPassword, storeFile=upload-keystore.jks" -ForegroundColor White
Write-Host "  3. Run ..\_build-cafebazaar-release.ps1 from repo root" -ForegroundColor White
