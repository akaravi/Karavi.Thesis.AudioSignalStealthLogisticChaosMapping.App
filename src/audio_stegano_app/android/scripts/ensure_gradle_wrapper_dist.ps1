# Ensures Gradle wrapper distribution is present (fixes Connection reset / stale .part/.lck).
param(
    [Parameter(Mandatory = $true)][string]$AndroidProjectPath
)

$ErrorActionPreference = 'Stop'

function Get-GradleWrapperPropertiesPath {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    return Join-Path $ProjectPath 'gradle\wrapper\gradle-wrapper.properties'
}

function Get-GradleDistributionUrlFromProperties {
    param([Parameter(Mandatory = $true)][string]$PropertiesPath)
    foreach ($line in Get-Content -LiteralPath $PropertiesPath) {
        if ($line -match '^distributionUrl=(.+)$') {
            return $Matches[1].Trim().Replace('\:', ':')
        }
    }
    throw "distributionUrl not found in $PropertiesPath"
}

function Set-GradleDistributionUrlInProperties {
    param(
        [Parameter(Mandatory = $true)][string]$PropertiesPath,
        [Parameter(Mandatory = $true)][string]$DistributionUrl
    )

    $escaped = $DistributionUrl.Replace(':', '\:')
    $lines = Get-Content -LiteralPath $PropertiesPath
    $updated = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^distributionUrl=') {
            $lines[$i] = "distributionUrl=$escaped"
            $updated = $true
            break
        }
    }
    if (-not $updated) {
        throw "Could not update distributionUrl in $PropertiesPath"
    }
    Set-Content -LiteralPath $PropertiesPath -Value $lines -Encoding UTF8
}

function Remove-IncompleteGradleWrapperCaches {
    $distsRoot = Join-Path $env:USERPROFILE '.gradle\wrapper\dists'
    if (-not (Test-Path -LiteralPath $distsRoot)) {
        return
    }

    foreach ($versionDir in Get-ChildItem -LiteralPath $distsRoot -Directory -ErrorAction SilentlyContinue) {
        foreach ($hashDir in Get-ChildItem -LiteralPath $versionDir.FullName -Directory -ErrorAction SilentlyContinue) {
            $completeZip = Get-ChildItem -LiteralPath $hashDir.FullName -Filter 'gradle-*-all.zip' -File -ErrorAction SilentlyContinue |
                Where-Object { -not $_.Name.EndsWith('.part') } |
                Select-Object -First 1
            if ($completeZip) {
                continue
            }

            $hasStale = @(
                Get-ChildItem -LiteralPath $hashDir.FullName -Filter '*.part' -File -ErrorAction SilentlyContinue
                Get-ChildItem -LiteralPath $hashDir.FullName -Filter '*.lck' -File -ErrorAction SilentlyContinue
            ).Count -gt 0

            if ($hasStale -or -not $completeZip) {
                Write-Host "Removing incomplete Gradle wrapper cache: $($hashDir.FullName)" -ForegroundColor Yellow
                Remove-Item -LiteralPath $hashDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Get-GradleDistributionMirrorUrls {
    param([Parameter(Mandatory = $true)][string]$PrimaryUrl)

    if ($PrimaryUrl -notmatch 'gradle-([\d\.]+)-all\.zip') {
        throw "Could not parse Gradle version from distribution URL: $PrimaryUrl"
    }
    $version = $Matches[1]

    $ordered = @(
        $PrimaryUrl
        "https://mirrors.cloud.tencent.com/gradle/gradle-$version-all.zip"
        "https://repo.huaweicloud.com/gradle/gradle-$version-all.zip"
        "https://services.gradle.org/distributions/gradle-$version-all.zip"
    )

    $seen = @{}
    $result = @()
    foreach ($url in $ordered) {
        if (-not $seen.ContainsKey($url)) {
            $seen[$url] = $true
            $result += $url
        }
    }
    return $result
}

function Test-GradleWrapperReady {
    param(
        [Parameter(Mandatory = $true)][string]$AndroidProjectPath,
        [Parameter(Mandatory = $true)][string]$GradlewPath
    )

    Push-Location $AndroidProjectPath
    try {
        & $GradlewPath --version 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    finally {
        Pop-Location
    }
}

$propsPath = Get-GradleWrapperPropertiesPath -ProjectPath $AndroidProjectPath
$gradlew = Join-Path $AndroidProjectPath 'gradlew.bat'
if (-not (Test-Path -LiteralPath $gradlew)) {
    throw "gradlew.bat not found: $gradlew"
}

Remove-IncompleteGradleWrapperCaches

$primaryUrl = Get-GradleDistributionUrlFromProperties -PropertiesPath $propsPath
$mirrorUrls = Get-GradleDistributionMirrorUrls -PrimaryUrl $primaryUrl

$ready = $false
foreach ($url in $mirrorUrls) {
    Write-Host "Gradle wrapper: trying $url" -ForegroundColor DarkGray
    Set-GradleDistributionUrlInProperties -PropertiesPath $propsPath -DistributionUrl $url
    Remove-IncompleteGradleWrapperCaches

    if (Test-GradleWrapperReady -AndroidProjectPath $AndroidProjectPath -GradlewPath $gradlew) {
        Write-Host "Gradle wrapper ready ($url)" -ForegroundColor Green
        $ready = $true
        break
    }

    Write-Host "Gradle wrapper download failed for $url" -ForegroundColor Yellow
}

if (-not $ready) {
    throw @"
Gradle wrapper distribution could not be downloaded.
  - Check VPN/proxy or retry later
  - Manually download gradle-*-all.zip into %USERPROFILE%\.gradle\wrapper\dists\
  - Or run: android\scripts\ensure_gradle_wrapper_dist.ps1 -AndroidProjectPath android
"@
}

exit 0
