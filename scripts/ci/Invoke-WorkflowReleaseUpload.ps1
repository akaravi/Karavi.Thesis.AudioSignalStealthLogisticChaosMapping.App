<#
.SYNOPSIS
  Upload publish/github-release assets to GitHub Releases (used by Actions workflow).
#>
param(
    [Parameter(Mandatory = $true)][string]$TagName,
    [string]$AssetsDirectory = "",
    [string]$Notes = "Built by GitHub Actions (self-hosted Windows runner)."
)

$ErrorActionPreference = "Stop"

$ciDir = $PSScriptRoot
$root = Split-Path -Parent (Split-Path -Parent $ciDir)
if ([string]::IsNullOrWhiteSpace($AssetsDirectory)) {
    $AssetsDirectory = Join-Path $root "publish\github-release"
}

if (-not (Test-Path -LiteralPath $AssetsDirectory)) {
    throw "Assets directory not found: $AssetsDirectory"
}

$files = @(
    Get-ChildItem -Path $AssetsDirectory -File -Filter "*.zip" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $AssetsDirectory -File -Filter "*.apk" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $AssetsDirectory -File -Filter "*.aab" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $AssetsDirectory -File -Filter "RELEASE_MANIFEST.txt" -ErrorAction SilentlyContinue
)
if ($files.Count -eq 0) {
    throw "No release assets in $AssetsDirectory"
}

$publishScript = Join-Path $ciDir "Publish-GitHubReleaseAssets.ps1"
if (-not (Test-Path -LiteralPath $publishScript)) {
    throw "Missing: $publishScript"
}

& $publishScript `
    -TagName $TagName `
    -AssetPaths @($files | ForEach-Object { $_.FullName }) `
    -Title "Release $TagName" `
    -Notes $Notes
