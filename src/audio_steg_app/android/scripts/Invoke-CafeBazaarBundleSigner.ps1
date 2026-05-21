<#
.SYNOPSIS
  Generate Cafe Bazaar upload binary (.bin) from a signed AAB using official bundle-signer.

.DESCRIPTION
  Cafe Bazaar does not store your signing key. After flutter build appbundle, run genbin
  per https://developers.cafebazaar.ir/fa/guidelines/feature/app_bundle#Bundle-Signer

.EXAMPLE
  .\Invoke-CafeBazaarBundleSigner.ps1 `
    -BundlePath ..\..\..\publish\cafebazaar\AudioSteg_1.0.0_1.aab `
    -OutputDirectory ..\..\..\publish\cafebazaar
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BundlePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$KeyPropertiesPath = "",
    [string]$BundleSignerJarPath = "",
    [switch]$SkipJarDownload
)

$ErrorActionPreference = "Stop"

function Get-JavaExecutable {
    if ($env:JAVA_HOME) {
        $java = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path -LiteralPath $java) { return $java }
    }
    $cmd = Get-Command java -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Java 8+ required for Cafe Bazaar bundle-signer. Install JDK and set JAVA_HOME."
}

function Get-BundleSignerJarCandidates {
    param([string]$AndroidRoot)

    $jarName = "bundlesigner-0.1.13.jar"
    @(
        if ($env:CAFEBAZAAR_BUNDLESIGNER_JAR) { $env:CAFEBAZAAR_BUNDLESIGNER_JAR }
        (Join-Path $AndroidRoot "tools\$jarName")
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Resolve-BundleSignerJarPath {
    param(
        [string]$RequestedPath,
        [string]$AndroidRoot,
        [switch]$NoDownload
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        if (-not (Test-Path -LiteralPath $RequestedPath)) {
            throw "bundle-signer JAR not found: $RequestedPath"
        }
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    foreach ($candidate in (Get-BundleSignerJarCandidates -AndroidRoot $AndroidRoot)) {
        if (Test-Path -LiteralPath $candidate) {
            $resolved = (Resolve-Path -LiteralPath $candidate).Path
            Write-Host "Using bundle-signer: $resolved" -ForegroundColor DarkGray
            return $resolved
        }
    }

    $downloadTarget = Join-Path $AndroidRoot "tools\bundlesigner-0.1.13.jar"
    if ($NoDownload) {
        $searched = (Get-BundleSignerJarCandidates -AndroidRoot $AndroidRoot) -join "`n  "
        throw @"
bundle-signer JAR not found. Set -BundleSignerJarPath, CAFEBAZAAR_BUNDLESIGNER_JAR, or place the file at:
  $searched
"@
    }

    $jarDir = Split-Path -Parent $downloadTarget
    if (-not (Test-Path $jarDir)) {
        New-Item -ItemType Directory -Path $jarDir -Force | Out-Null
    }

    $version = "0.1.13"
    $url = "https://github.com/cafebazaar/bundle-signer/releases/download/v$version/bundlesigner-$version.jar"
    Write-Host "Downloading Cafe Bazaar bundle-signer v$version to tools/ ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $downloadTarget -UseBasicParsing
    if (-not (Test-Path -LiteralPath $downloadTarget)) {
        throw "Download failed: $downloadTarget"
    }
    return (Resolve-Path -LiteralPath $downloadTarget).Path
}

function Read-AndroidKeyProperties {
    param([string]$PropertiesFile, [string]$AndroidRoot)

    if (-not (Test-Path -LiteralPath $PropertiesFile)) {
        throw "key.properties not found: $PropertiesFile"
    }

    $props = @{}
    foreach ($line in Get-Content -LiteralPath $PropertiesFile) {
        if ($line -match '^\s*#' -or $line -notmatch '=') { continue }
        $kv = $line -split '=', 2
        $props[$kv[0].Trim()] = $kv[1].Trim()
    }

    foreach ($required in @("storePassword", "keyPassword", "keyAlias", "storeFile")) {
        if (-not $props.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($props[$required])) {
            throw "key.properties missing '$required'"
        }
    }

    $storePath = $props["storeFile"]
    if (-not [System.IO.Path]::IsPathRooted($storePath)) {
        $storePath = Join-Path $AndroidRoot $storePath
    }
    if (-not (Test-Path -LiteralPath $storePath)) {
        throw "Keystore not found: $storePath"
    }

    return @{
        StorePath      = (Resolve-Path -LiteralPath $storePath).Path
        StorePassword  = $props["storePassword"]
        KeyPassword    = $props["keyPassword"]
        KeyAlias       = $props["keyAlias"]
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidRoot = Split-Path -Parent $scriptDir
if ([string]::IsNullOrWhiteSpace($KeyPropertiesPath)) {
    $KeyPropertiesPath = Join-Path $androidRoot "key.properties"
}

$bundleFull = (Resolve-Path -LiteralPath $BundlePath).Path
if (-not (Test-Path -LiteralPath $bundleFull)) {
    throw "AAB not found: $BundlePath"
}

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}
$outDir = (Resolve-Path -LiteralPath $OutputDirectory).Path

$jarPath = Resolve-BundleSignerJarPath `
    -RequestedPath $BundleSignerJarPath `
    -AndroidRoot $androidRoot `
    -NoDownload:$SkipJarDownload

$key = Read-AndroidKeyProperties -PropertiesFile $KeyPropertiesPath -AndroidRoot $androidRoot
$java = Get-JavaExecutable

# Official Cafe Bazaar example: v2 on, v3 off (developers.cafebazaar.ir app_bundle#Bundle-Signer)
$genbinArgs = @(
    "-jar", $jarPath,
    "genbin",
    "-v",
    "--bundle", $bundleFull,
    "--bin", $outDir,
    "--v2-signing-enabled", "true",
    "--v3-signing-enabled", "false",
    "--ks", $key.StorePath,
    "--ks-key-alias", $key.KeyAlias,
    "--ks-pass", "pass:$($key.StorePassword)",
    "--key-pass", "pass:$($key.KeyPassword)",
    "--ks-type", "JKS"
)

Write-Host "Cafe Bazaar bundle-signer genbin ..." -ForegroundColor Cyan
Write-Host "  bundle: $bundleFull" -ForegroundColor DarkGray
Write-Host "  output: $outDir" -ForegroundColor DarkGray

& $java @genbinArgs
if ($LASTEXITCODE -ne 0) {
    throw "bundle-signer genbin failed (exit $LASTEXITCODE). If keystore format fails, migrate JKS to PKCS12 (see docs/cafebazaar-publish-guide.md)."
}

$binFiles = @(Get-ChildItem -Path $outDir -Filter "*.bin" -File | Sort-Object LastWriteTime -Descending)
if ($binFiles.Count -eq 0) {
    throw "genbin finished but no .bin file in $outDir"
}

$latestBin = $binFiles[0]
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($bundleFull)
$destName = if ($baseName -match '^AudioSteg_') { "${baseName}.bin" } else { "$($latestBin.Name)" }
$destPath = Join-Path $outDir $destName
if ($latestBin.FullName -ne $destPath) {
    if (Test-Path -LiteralPath $destPath) { Remove-Item -Force $destPath }
    Move-Item -Force $latestBin.FullName $destPath
}

Write-Host "Cafe Bazaar upload file:" -ForegroundColor Green
Write-Host "  $destPath" -ForegroundColor Yellow
return $destPath
