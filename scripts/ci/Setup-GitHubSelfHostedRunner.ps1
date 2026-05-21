<#
.SYNOPSIS
  Opens GitHub runner registration and downloads actions-runner for Windows (no Actions billing on GitHub-hosted runners).

.EXAMPLE
  .\scripts\ci\Setup-GitHubSelfHostedRunner.ps1
#>
param(
    [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path $root ".github-runner"
}

$url = (git -C $root remote get-url origin 2>$null).Trim()
if ($url -match 'github\.com[:/]([^/]+)/([^/.]+)') {
    $owner = $Matches[1]
    $repo = $Matches[2] -replace '\.git$', ''
    $settingsUrl = "https://github.com/$owner/$repo/settings/actions/runners/new?os=win"
}
else {
    $settingsUrl = "https://github.com/settings/actions/runners/new?os=win"
}

Write-Host @"

=== GitHub Self-Hosted Runner (Windows) ===
Billing error on windows-latest is avoided: jobs run on YOUR PC (free for Actions).

1. Browser opens: New self-hosted runner registration.
2. Copy the config token from GitHub (valid ~1 hour).
3. Run in PowerShell (after download):

   cd `"$InstallDir`"
   .\config.cmd --url https://github.com/$owner/$repo --token YOUR_TOKEN
   .\run.cmd

Keep run.cmd window open while publishing tags.

"@ -ForegroundColor Cyan

Start-Process $settingsUrl | Out-Null

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
$zipUrl = "https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-win-x64-2.321.0.zip"
$zipPath = Join-Path $InstallDir "actions-runner.zip"

if (-not (Test-Path (Join-Path $InstallDir "config.cmd"))) {
    Write-Host "Downloading actions-runner ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    Remove-Item -Force $zipPath
}

Write-Host "Runner files: $InstallDir" -ForegroundColor Green
Write-Host "After config.cmd + run.cmd, push tag publish again." -ForegroundColor Yellow
