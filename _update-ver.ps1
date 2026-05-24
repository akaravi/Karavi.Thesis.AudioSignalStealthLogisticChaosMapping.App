# Bump app version across Flutter (pubspec) and WPF (csproj).
# User command: "update ver" — increases PATCH (third segment) by 1.
# Format: MAJOR.MINOR.PATCH only (no +BUILD suffix). Example: 1.2.3 -> 1.2.4
param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pubspecPath = Join-Path $root "src\audio_stegano_app\pubspec.yaml"
$csprojPath = Join-Path $root "src\audio_stegano_desktop\src\AudioStegano.Desktop\AudioStegano.Desktop.csproj"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Parse-AppVersionLabel {
    param([Parameter(Mandatory = $true)][string]$Label)

    if ($Label -match '^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patchSegment = [int]$Matches[3]
        $buildSuffix = if ($Matches[4]) { [int]$Matches[4] } else { $null }

        # Legacy MAJOR.MINOR.PATCH+BUILD: third display segment = BUILD (e.g. 1.2.0+3 -> 1.2.3).
        $patch = if ($null -ne $buildSuffix) { $buildSuffix } else { $patchSegment }

        return [ordered]@{
            Major = $major
            Minor = $minor
            Patch = $patch
        }
    }

    throw "Invalid version label '$Label'. Expected MAJOR.MINOR.PATCH or legacy MAJOR.MINOR.PATCH+BUILD."
}

function Format-AppVersionLabel {
    param([Parameter(Mandatory = $true)][hashtable]$Version)

    return "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, $Version.Patch
}

function Bump-AppPatchVersion {
    param([Parameter(Mandatory = $true)][hashtable]$Version)

    return [ordered]@{
        Major = $Version.Major
        Minor = $Version.Minor
        Patch = $Version.Patch + 1
    }
}

function Get-FlutterPubspecVersionLabel {
    param([Parameter(Mandatory = $true)][string]$Path)

    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*version:\s*(.+?)\s*(?:#.*)?$') {
            return $Matches[1].Trim()
        }
    }

    throw "Could not read version from $Path"
}

function Set-FlutterPubspecVersionLabel {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$NewLabel
    )

    $lines = [System.IO.File]::ReadAllLines($Path)
    $updated = $false
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^\s*version:\s*.+$') {
            $lines[$i] = "version: $NewLabel"
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        throw "Could not find version: line in $Path"
    }

    Write-Utf8NoBom -Path $Path -Content (($lines -join "`n") + "`n")
}

function Set-DotNetDesktopVersions {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][hashtable]$Version
    )

    $semver = Format-AppVersionLabel -Version $Version
    $assembly = "{0}.{1}.{2}.0" -f $Version.Major, $Version.Minor, $Version.Patch

    $text = [System.IO.File]::ReadAllText($Path)
    $text = $text -replace '(<Version>)[^<]+(</Version>)', "`${1}$semver`${2}"
    $text = $text -replace '(<AssemblyVersion>)[^<]+(</AssemblyVersion>)', "`${1}$assembly`${2}"
    $text = $text -replace '(<FileVersion>)[^<]+(</FileVersion>)', "`${1}$assembly`${2}"
    $text = $text -replace '(<InformationalVersion>)[^<]+(</InformationalVersion>)', "`${1}$semver`${2}"

    Write-Utf8NoBom -Path $Path -Content $text
}

if (-not (Test-Path $pubspecPath)) { throw "Missing pubspec: $pubspecPath" }
if (-not (Test-Path $csprojPath)) { throw "Missing csproj: $csprojPath" }

$currentLabel = Get-FlutterPubspecVersionLabel -Path $pubspecPath
$current = Parse-AppVersionLabel -Label $currentLabel
$currentNormalized = Format-AppVersionLabel -Version $current
$next = Bump-AppPatchVersion -Version $current
$nextLabel = Format-AppVersionLabel -Version $next

Write-Host "update ver" -ForegroundColor Cyan
Write-Host "  Current : $currentLabel" -ForegroundColor DarkGray
if ($currentLabel -ne $currentNormalized) {
    Write-Host "  Normalized: $currentNormalized (legacy +BUILD removed)" -ForegroundColor Yellow
}
Write-Host "  Next    : $nextLabel  (patch +1)" -ForegroundColor Green
Write-Host "  Files   : pubspec.yaml, AudioStegano.Desktop.csproj" -ForegroundColor DarkGray

if ($WhatIf) {
    Write-Host "WhatIf: no files changed." -ForegroundColor Yellow
    exit 0
}

Set-FlutterPubspecVersionLabel -Path $pubspecPath -NewLabel $nextLabel
Set-DotNetDesktopVersions -Path $csprojPath -Version $next

Write-Host "Done." -ForegroundColor Green
