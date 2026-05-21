<#
.SYNOPSIS
  Creates/updates a GitHub Release and uploads files via REST API (no gh CLI, no Actions minutes).
#>
param(
    [Parameter(Mandatory = $true)][string]$TagName,
    [Parameter(Mandatory = $true)][string[]]$AssetPaths,
    [string]$Title = "",
    [string]$Notes = "Release built locally.",
    [switch]$Draft
)

$ErrorActionPreference = "Stop"

function Get-GitHubRepoSlug {
    $url = (git remote get-url origin 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        throw "No git remote 'origin'. Add remote first."
    }
    if ($url -match 'github\.com[:/]([^/]+)/([^/.]+)') {
        return @{ Owner = $Matches[1]; Repo = $Matches[2] -replace '\.git$', '' }
    }
    throw "Could not parse GitHub owner/repo from: $url"
}

function Get-GitHubToken {
    if ($env:GITHUB_ACTIONS -eq 'true' -and -not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        return $env:GITHUB_TOKEN.Trim()
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        return $env:GITHUB_TOKEN.Trim()
    }
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        $t = gh auth token 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($t)) {
            return $t.Trim()
        }
    }
    $tokenFile = Join-Path $env:USERPROFILE ".github-token"
    if (Test-Path -LiteralPath $tokenFile) {
        return (Get-Content -LiteralPath $tokenFile -Raw).Trim()
    }
    throw @"
GitHub token not found. Use one of:
  `$env:GITHUB_TOKEN = 'ghp_...'   (scope: repo)
  gh auth login
  Or save PAT to: $tokenFile
"@
}

function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers,
        [object]$Body = $null
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $Headers
        ContentType = "application/json"
    }
    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Compress)
    }
    return Invoke-RestMethod @params
}

$slug = Get-GitHubRepoSlug
$token = Get-GitHubToken
$apiBase = "https://api.github.com/repos/$($slug.Owner)/$($slug.Repo)"
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = "Release $TagName"
}

$encodedTag = [Uri]::EscapeDataString($TagName)
$existing = $null
try {
    $existing = Invoke-GitHubApi -Method GET -Uri "$apiBase/releases/tags/$encodedTag" -Headers $headers
}
catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw }
}

if ($existing) {
    Write-Host "Release exists (id=$($existing.id)); deleting for clean re-upload ..." -ForegroundColor Yellow
    Invoke-GitHubApi -Method DELETE -Uri "$apiBase/releases/$($existing.id)" -Headers $headers | Out-Null
}

$releaseBody = @{
    tag_name = $TagName
    name     = $Title
    body     = $Notes
    draft    = [bool]$Draft
}
$release = Invoke-GitHubApi -Method POST -Uri "$apiBase/releases" -Headers $headers -Body $releaseBody
Write-Host "Release created: id=$($release.id)" -ForegroundColor Green

foreach ($path in $AssetPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Asset not found: $path"
    }
    $fileName = [System.IO.Path]::GetFileName($path)
    $uploadUrl = ($release.upload_url -replace '\{\?name,label\}', "?name=$([Uri]::EscapeDataString($fileName))")
    $bytes = [System.IO.File]::ReadAllBytes($path)
    Write-Host "Uploading $fileName ($([math]::Round($bytes.Length / 1MB, 2)) MB) ..." -ForegroundColor Cyan
    $uploadHeaders = @{
        Authorization = "Bearer $token"
        Accept        = "application/vnd.github+json"
    }
    Invoke-RestMethod -Method POST -Uri $uploadUrl -Headers $uploadHeaders `
        -ContentType "application/octet-stream" -Body $bytes | Out-Null
}

Write-Host "Release URL: $($release.html_url)" -ForegroundColor Green
return $release
