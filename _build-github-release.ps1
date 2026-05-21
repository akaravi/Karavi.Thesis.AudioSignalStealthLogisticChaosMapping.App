<#
.SYNOPSIS
  Non-interactive full release build for GitHub Actions (tag publish*).

.EXAMPLE
  .\_build-github-release.ps1 -TagName publish
  .\_build-github-release.ps1 -TagName publish/1.0.0+2
#>
param(
    [string]$TagName = "",
    [string]$OutputRoot = "",
    [ValidateSet("Apk", "AppBundle", "Both")]
    [string]$AndroidArtifact = "Both",
    [switch]$SkipTests,
    [switch]$SkipFlutterAnalyze,
    [string]$WebBaseHref = "/"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterAppPath = Join-Path $root "src\audio_steg_app"
$androidRoot = Join-Path $flutterAppPath "android"
$dotnetPublishOutput = Join-Path $root "publish\dotnet\win-x64\AudioSteg.Desktop"
$androidPublishDir = Join-Path $root "publish\flutter\android"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $root "publish\github-release"
}
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
$OutputRoot = (Resolve-Path -LiteralPath $OutputRoot).Path

function Get-PubspecVersionParts {
    param([Parameter(Mandatory = $true)][string]$FlutterProjectPath)

    $pubspec = Join-Path $FlutterProjectPath "pubspec.yaml"
    foreach ($line in Get-Content -LiteralPath $pubspec) {
        if ($line -match '^\s*version:\s*(.+?)\s*(?:#.*)?$') {
            $label = $Matches[1].Trim()
            if ($label -match '^(.+)\+(\d+)$') {
                return @{
                    Label  = $label
                    Name   = $Matches[1].Trim()
                    Number = $Matches[2].Trim()
                    Token  = ($label -replace '\+', '_' -replace '[^\w\.\-]', '_')
                }
            }
            return @{
                Label  = $label
                Name   = $label
                Number = "1"
                Token  = ($label -replace '\+', '_' -replace '[^\w\.\-]', '_')
            }
        }
    }
    throw "Could not read version from $pubspec"
}

function Resolve-ReleaseVersionFromTag {
    param(
        [string]$Tag,
        [hashtable]$PubspecParts
    )

    if ([string]::IsNullOrWhiteSpace($Tag) -or $Tag -eq "publish") {
        return $PubspecParts
    }

    if ($Tag -match '^publish[/\-_](.+)$') {
        $raw = $Matches[1].Trim()
        if ($raw -match '^(.+)\+(\d+)$') {
            $name = $Matches[1].Trim()
            $num = $Matches[2].Trim()
        }
        else {
            $name = $raw
            $num = $PubspecParts.Number
        }
        $label = "${name}+${num}"
        return @{
            Label  = $label
            Name   = $name
            Number = $num
            Token  = ($label -replace '\+', '_' -replace '[^\w\.\-]', '_')
        }
    }

    Write-Host "Tag '$Tag' has no version suffix; using pubspec version." -ForegroundColor Yellow
    return $PubspecParts
}

function New-DirectoryZip {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$ZipFilePath
    )

    if (Test-Path -LiteralPath $ZipFilePath) {
        Remove-Item -Force $ZipFilePath
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $SourceDirectory,
        $ZipFilePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false)
    Write-Host "ZIP: $ZipFilePath" -ForegroundColor Green
}

$pubspecVersion = Get-PubspecVersionParts -FlutterProjectPath $flutterAppPath
$releaseVersion = Resolve-ReleaseVersionFromTag -Tag $TagName -PubspecParts $pubspecVersion
$versionToken = $releaseVersion.Token

Write-Host "Release version: $($releaseVersion.Label) (token: $versionToken)" -ForegroundColor Cyan
Write-Host "Output root: $OutputRoot" -ForegroundColor Cyan

function Sync-ReleaseVersionToProjects {
    param(
        [string]$FlutterProjectPath,
        [string]$DesktopCsprojPath,
        [hashtable]$VersionParts
    )

    if ($VersionParts.Label -eq (Get-PubspecVersionParts -FlutterProjectPath $FlutterProjectPath).Label) {
        return
    }

    Write-Host "Syncing project version to $($VersionParts.Label) ..." -ForegroundColor Cyan
    $pubspecPath = Join-Path $FlutterProjectPath "pubspec.yaml"
    $pubLines = Get-Content -LiteralPath $pubspecPath
    for ($i = 0; $i -lt $pubLines.Count; $i++) {
        if ($pubLines[$i] -match '^\s*version:\s*') {
            $pubLines[$i] = "version: $($VersionParts.Label)"
            break
        }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($pubspecPath, $pubLines, $utf8NoBom)

    if (Test-Path -LiteralPath $DesktopCsprojPath) {
        $csproj = Get-Content -LiteralPath $DesktopCsprojPath
        $semver = $VersionParts.Name
        for ($i = 0; $i -lt $csproj.Count; $i++) {
            if ($csproj[$i] -match '<Version>') { $csproj[$i] = "    <Version>$semver</Version>" }
            if ($csproj[$i] -match '<AssemblyVersion>') { $csproj[$i] = "    <AssemblyVersion>$semver.0</AssemblyVersion>" }
            if ($csproj[$i] -match '<FileVersion>') { $csproj[$i] = "    <FileVersion>$semver.0</FileVersion>" }
            if ($csproj[$i] -match '<InformationalVersion>') {
                $csproj[$i] = "    <InformationalVersion>$($VersionParts.Label)</InformationalVersion>"
            }
        }
        [System.IO.File]::WriteAllLines($DesktopCsprojPath, $csproj, $utf8NoBom)
    }
}

$desktopCsproj = Join-Path $root "src\audio_steg_desktop\src\AudioSteg.Desktop\AudioSteg.Desktop.csproj"
Sync-ReleaseVersionToProjects `
    -FlutterProjectPath $flutterAppPath `
    -DesktopCsprojPath $desktopCsproj `
    -VersionParts $releaseVersion
$versionToken = $releaseVersion.Token

$prepareSigning = Join-Path $root "scripts\ci\Prepare-AndroidReleaseSigning.ps1"
if (Test-Path -LiteralPath $prepareSigning) {
    & $prepareSigning -AndroidRoot $androidRoot
}

$buildAll = Join-Path $root "_build-all-projects.ps1"
$buildArgs = @{
    Configuration           = "Release"
    SkipDevServers            = $true
    SkipStopRunningProjects   = $true
    NonInteractive            = $true
    ZipOutputDirectory        = $OutputRoot
    AndroidArtifact           = $AndroidArtifact
    WebBaseHref               = $WebBaseHref
}
if ($SkipTests) { $buildArgs.SkipTests = $true }
if ($SkipFlutterAnalyze) { $buildArgs.SkipFlutterAnalyze = $true }

& $buildAll @buildArgs
if ($LASTEXITCODE -ne 0) { throw "_build-all-projects.ps1 failed with exit $LASTEXITCODE" }

$flutterWebDir = Join-Path $flutterAppPath "build\web"
$flutterWindowsDir = Join-Path $flutterAppPath "build\windows\x64\runner\Release"

if (-not (Test-Path -LiteralPath (Join-Path $flutterWebDir "index.html"))) {
    throw "Flutter web build missing: $flutterWebDir"
}
if (-not (Test-Path -LiteralPath (Join-Path $flutterWindowsDir "audio_steg_app.exe"))) {
    throw "Flutter Windows build missing: $flutterWindowsDir"
}
if (-not (Test-Path -LiteralPath (Join-Path $dotnetPublishOutput "AudioSteg.Desktop.exe"))) {
    throw ".NET publish missing: $dotnetPublishOutput"
}

$perPlatformZips = @(
    @{
        Source = $flutterWebDir
        Zip    = Join-Path $OutputRoot "KaraviThesis_AudioSteg_FlutterWeb_$versionToken.zip"
    },
    @{
        Source = $flutterWindowsDir
        Zip    = Join-Path $OutputRoot "KaraviThesis_AudioSteg_FlutterWindows_$versionToken.zip"
    },
    @{
        Source = $dotnetPublishOutput
        Zip    = Join-Path $OutputRoot "KaraviThesis_AudioSteg_DotNetDesktop_$versionToken.zip"
    }
)

foreach ($item in $perPlatformZips) {
    New-DirectoryZip -SourceDirectory $item.Source -ZipFilePath $item.Zip
}

if (Test-Path -LiteralPath $androidPublishDir) {
    $androidFiles = @(
        Get-ChildItem -Path $androidPublishDir -File -Filter "*.apk" -ErrorAction SilentlyContinue
        Get-ChildItem -Path $androidPublishDir -File -Filter "*.aab" -ErrorAction SilentlyContinue
    )
    foreach ($f in $androidFiles) {
        $dest = Join-Path $OutputRoot $f.Name
        if (Test-Path -LiteralPath $dest) { Remove-Item -Force $dest }
        Copy-Item -Force $f.FullName $dest
        Write-Host "Android asset: $dest" -ForegroundColor Green
    }
    if ($androidFiles.Count -gt 0) {
        $androidStage = Join-Path $OutputRoot "_android_stage"
        if (Test-Path $androidStage) { Remove-Item -Recurse -Force $androidStage }
        New-Item -ItemType Directory -Path $androidStage -Force | Out-Null
        foreach ($f in $androidFiles) {
            Copy-Item -Force $f.FullName (Join-Path $androidStage $f.Name)
        }
        New-DirectoryZip `
            -SourceDirectory $androidStage `
            -ZipFilePath (Join-Path $OutputRoot "KaraviThesis_AudioSteg_Android_$versionToken.zip")
        Remove-Item -Recurse -Force $androidStage
    }
}

$manifestPath = Join-Path $OutputRoot "RELEASE_MANIFEST.txt"
$manifestLines = @(
    "tag=$TagName"
    "version=$($releaseVersion.Label)"
    "version_token=$versionToken"
    "built_utc=$(Get-Date -Format o)"
    ""
    "artifacts:"
)
Get-ChildItem -Path $OutputRoot -File | Sort-Object Name | ForEach-Object {
    $manifestLines += "  $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)"
}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($manifestPath, $manifestLines, $utf8NoBom)

Write-Host ""
Write-Host "GitHub release assets ready under: $OutputRoot" -ForegroundColor Green
Get-ChildItem -Path $OutputRoot -File | Format-Table Name, @{ Label = "MB"; Expression = { [math]::Round($_.Length / 1MB, 2) } } -AutoSize
