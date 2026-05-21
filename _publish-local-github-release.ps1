<#
.SYNOPSIS
  Build release artifacts locally and publish GitHub Release (REST API or gh CLI — no Actions billing).

.EXAMPLE
  $env:GITHUB_TOKEN = 'ghp_...'   # once, scope repo
  .\_publish-local-github-release.ps1 -TagName publish/1.0.0+2
#>
param(
    [Parameter(Mandatory = $true)][string]$TagName,
    [switch]$SkipBuild,
    [switch]$SkipPushTag,
    [switch]$Draft,
    [switch]$SkipTests,
    [switch]$SkipFlutterAnalyze,
    [switch]$InstallGhCli
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetsDir = Join-Path $root "publish\github-release"
$publishApiScript = Join-Path $root "scripts\ci\Publish-GitHubReleaseAssets.ps1"

function Install-GitHubCliIfRequested {
    if (-not $InstallGhCli) { return }
    if (Get-Command gh -ErrorAction SilentlyContinue) { return }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warning "winget not found; skip gh install."
        return
    }
    Write-Host "Installing GitHub CLI via winget ..." -ForegroundColor Cyan
    & winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
}

function Publish-ReleaseAssets {
    param(
        [string]$Tag,
        [System.IO.FileInfo[]]$Files,
        [switch]$IsDraft
    )

    $assetPaths = @($Files | ForEach-Object { $_.FullName })
    $notes = "Local build via _publish-local-github-release.ps1 (no GitHub Actions hosted runners)."

    if (Test-Path -LiteralPath $publishApiScript) {
        $apiArgs = @{
            TagName     = $Tag
            AssetPaths  = $assetPaths
            Title       = "Release $Tag"
            Notes       = $notes
        }
        if ($IsDraft) { $apiArgs.Draft = $true }
        & $publishApiScript @apiArgs
        return
    }

    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "Publish-GitHubReleaseAssets.ps1 missing and gh not installed. Set GITHUB_TOKEN and ensure scripts/ci exists."
    }
    gh auth status 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "gh auth login required." }

    $releaseArgs = @(
        "release", "create", $Tag,
        "--title", "Release $Tag",
        "--notes", $notes,
        "--clobber"
    )
    if ($IsDraft) { $releaseArgs += "--draft" }
    foreach ($f in $Files) { $releaseArgs += $f.FullName }
    & gh @releaseArgs
    if ($LASTEXITCODE -ne 0) { throw "gh release create failed." }
}

Install-GitHubCliIfRequested

if (-not $SkipBuild) {
    $buildArgs = @{ TagName = $TagName }
    if ($SkipTests) { $buildArgs.SkipTests = $true }
    if ($SkipFlutterAnalyze) { $buildArgs.SkipFlutterAnalyze = $true }
    & (Join-Path $root "_build-github-release.ps1") @buildArgs
}

if (-not (Test-Path -LiteralPath $assetsDir)) {
    throw "Assets folder missing: $assetsDir — run without -SkipBuild first."
}

$files = @(
    Get-ChildItem -Path $assetsDir -File -Filter "*.zip" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $assetsDir -File -Filter "*.apk" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $assetsDir -File -Filter "*.aab" -ErrorAction SilentlyContinue
    Get-ChildItem -Path $assetsDir -File -Filter "RELEASE_MANIFEST.txt" -ErrorAction SilentlyContinue
)
if ($files.Count -eq 0) {
    throw "No release files under $assetsDir"
}

Write-Host "Assets ($($files.Count) files):" -ForegroundColor Cyan
$files | ForEach-Object { Write-Host "  $($_.Name)" }

if (-not $SkipPushTag) {
    $existing = git tag -l $TagName 2>$null
    if (-not $existing) {
        Write-Host "Creating git tag: $TagName" -ForegroundColor Cyan
        git tag $TagName
    }
    else {
        Write-Host "Tag already exists locally: $TagName" -ForegroundColor Yellow
    }
    Write-Host "Pushing tag to origin ..." -ForegroundColor Cyan
    git push origin $TagName
    if ($LASTEXITCODE -ne 0) { throw "git push origin $TagName failed" }
}

Publish-ReleaseAssets -Tag $TagName -Files $files -IsDraft:$Draft

Write-Host ""
Write-Host "Done. Releases: https://github.com/$(git remote get-url origin | ForEach-Object { if ($_ -match 'github\.com[:/]([^/]+)/([^/.]+)') { "$($Matches[1])/$($Matches[2] -replace '\.git$','')" } })/releases" -ForegroundColor Green
