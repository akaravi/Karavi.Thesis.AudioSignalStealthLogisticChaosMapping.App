<#
.SYNOPSIS
  Creates android/key.properties and upload-keystore.jks from CI secrets (GitHub Actions).

.DESCRIPTION
  Expects environment variables when signing is required:
    ANDROID_KEYSTORE_BASE64 — base64 of upload-keystore.jks
    ANDROID_KEYSTORE_PASSWORD
    ANDROID_KEY_PASSWORD
    ANDROID_KEY_ALIAS (optional, default: upload)

  If ANDROID_KEYSTORE_BASE64 is empty, skips setup (Gradle uses debug signing).
#>
param(
    [Parameter(Mandatory = $true)][string]$AndroidRoot
)

$ErrorActionPreference = "Stop"

$base64 = $env:ANDROID_KEYSTORE_BASE64
if ([string]::IsNullOrWhiteSpace($base64)) {
    Write-Host "Android release signing: no ANDROID_KEYSTORE_BASE64 — debug signing for APK/AAB." -ForegroundColor Yellow
    return
}

$storePassword = $env:ANDROID_KEYSTORE_PASSWORD
$keyPassword = $env:ANDROID_KEY_PASSWORD
$keyAlias = if ([string]::IsNullOrWhiteSpace($env:ANDROID_KEY_ALIAS)) { "upload" } else { $env:ANDROID_KEY_ALIAS }

if ([string]::IsNullOrWhiteSpace($storePassword) -or [string]::IsNullOrWhiteSpace($keyPassword)) {
    throw "ANDROID_KEYSTORE_BASE64 is set but ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD are missing."
}

$keystoreFileName = "upload-keystore.jks"
$keystorePath = Join-Path $AndroidRoot $keystoreFileName
$bytes = [Convert]::FromBase64String($base64.Trim())
[System.IO.File]::WriteAllBytes($keystorePath, $bytes)

$keyPropertiesPath = Join-Path $AndroidRoot "key.properties"
$lines = @(
    "storePassword=$storePassword"
    "keyPassword=$keyPassword"
    "keyAlias=$keyAlias"
    "storeFile=$keystoreFileName"
)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($keyPropertiesPath, $lines, $utf8NoBom)

Write-Host "Android release signing: key.properties + keystore written under $AndroidRoot" -ForegroundColor Green
