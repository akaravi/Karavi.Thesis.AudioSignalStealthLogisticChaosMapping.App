# Bump app version across Flutter (pubspec) and WPF (csproj).
# User command: "update ver" — increases semver MINOR by 1, resets PATCH to 0, increments build (+N).
# Example: 1.0.0+1 -> 1.1.0+2
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
        return [ordered]@{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
            Build = if ($Matches[4]) { [int]$Matches[4] } else { 1 }
        }
    }

    throw "Invalid version label '$Label'. Expected MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH+BUILD."
}

function Format-AppVersionLabel {
    param([Parameter(Mandatory = $true)][hashtable]$Version)

    return "{0}.{1}.{2}+{3}" -f $Version.Major, $Version.Minor, $Version.Patch, $Version.Build
}

function Bump-MinorSubVersion {
    param([Parameter(Mandatory = $true)][hashtable]$Version)

    return [ordered]@{
        Major = $Version.Major
        Minor = $Version.Minor + 1
        Patch = 0
        Build = $Version.Build + 1
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

    $semver = "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, $Version.Patch
    $assembly = "{0}.{1}.{2}.0" -f $Version.Major, $Version.Minor, $Version.Patch
    $informational = Format-AppVersionLabel -Version $Version

    $text = [System.IO.File]::ReadAllText($Path)
    $text = $text -replace '(<Version>)[^<]+(</Version>)', "`${1}$semver`${2}"
    $text = $text -replace '(<AssemblyVersion>)[^<]+(</AssemblyVersion>)', "`${1}$assembly`${2}"
    $text = $text -replace '(<FileVersion>)[^<]+(</FileVersion>)', "`${1}$assembly`${2}"
    $text = $text -replace '(<InformationalVersion>)[^<]+(</InformationalVersion>)', "`${1}$informational`${2}"

    Write-Utf8NoBom -Path $Path -Content $text
}

if (-not (Test-Path $pubspecPath)) { throw "Missing pubspec: $pubspecPath" }
if (-not (Test-Path $csprojPath)) { throw "Missing csproj: $csprojPath" }

$currentLabel = Get-FlutterPubspecVersionLabel -Path $pubspecPath
$current = Parse-AppVersionLabel -Label $currentLabel
$next = Bump-MinorSubVersion -Version $current
$nextLabel = Format-AppVersionLabel -Version $next

Write-Host "update ver" -ForegroundColor Cyan
Write-Host "  Current : $currentLabel" -ForegroundColor DarkGray
Write-Host "  Next    : $nextLabel  (minor +1, patch -> 0, build +1)" -ForegroundColor Green
Write-Host "  Files   : pubspec.yaml, AudioStegano.Desktop.csproj" -ForegroundColor DarkGray

if ($WhatIf) {
    Write-Host "WhatIf: no files changed." -ForegroundColor Yellow
    exit 0
}

Set-FlutterPubspecVersionLabel -Path $pubspecPath -NewLabel $nextLabel
Set-DotNetDesktopVersions -Path $csprojPath -Version $next

Write-Host "Done." -ForegroundColor Green
