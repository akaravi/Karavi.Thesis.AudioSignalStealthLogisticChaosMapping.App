<#
.SYNOPSIS
  Documents enabling automatic tag-triggered releases after self-hosted runner is online.

.DESCRIPTION
  Set repository variable SELF_HOSTED_RUNNER_READY=true in GitHub UI, or use gh:
  gh variable set SELF_HOSTED_RUNNER_READY --body true --repo OWNER/REPO
#>
param(
    [switch]$SetVariable
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$url = (git -C $root remote get-url origin 2>$null).Trim()
if ($url -notmatch 'github\.com[:/]([^/]+)/([^/.]+)') {
    throw "Could not parse origin remote."
}
$owner = $Matches[1]
$repo = ($Matches[2] -replace '\.git$', '')
$full = "$owner/$repo"

Write-Host @"
Repository: $full

1. Register runner (once):
   .\scripts\ci\Setup-GitHubSelfHostedRunner.ps1
   cd .github-runner
   .\config.cmd --url https://github.com/$full --token <TOKEN>
   .\run.cmd

2. When runner shows Online in GitHub → Settings → Actions → Runners,
   enable automatic releases on tag push:

   GitHub UI: Settings → Secrets and variables → Actions → Variables
   Name: SELF_HOSTED_RUNNER_READY
   Value: true

   Or: gh variable set SELF_HOSTED_RUNNER_READY --body true --repo $full

3. Push tag:
   git push origin publish

Without the variable, tag push will SKIP the workflow job (no stuck queue).
Use workflow_dispatch or .\_publish-local-github-release.ps1 anytime.
"@ -ForegroundColor Cyan

if ($SetVariable) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) { throw "gh CLI required for -SetVariable" }
    gh variable set SELF_HOSTED_RUNNER_READY --body "true" --repo $full
    Write-Host "Variable SELF_HOSTED_RUNNER_READY set for $full" -ForegroundColor Green
}
