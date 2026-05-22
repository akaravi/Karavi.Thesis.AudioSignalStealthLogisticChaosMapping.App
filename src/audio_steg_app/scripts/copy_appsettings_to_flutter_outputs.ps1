# Syncs repo-root appsettings.json into Flutter project assets and deploy output folders.

function Get-RepoAppSettingsPath {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $source = Join-Path $RepoRoot "appsettings.json"
    if (-not (Test-Path -LiteralPath $source)) {
        throw "appsettings.json not found at repo root: $source"
    }
    return $source
}

function Sync-AppSettingsToFlutterProjectAssets {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$FlutterProjectPath
    )

    $source = Get-RepoAppSettingsPath -RepoRoot $RepoRoot
    $destDir = Join-Path $FlutterProjectPath "assets"
    $dest = Join-Path $destDir "appsettings.json"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $dest -Force
    Write-Host "appsettings.json -> $dest (Flutter asset bundle)" -ForegroundColor DarkCyan
}

function Copy-AppSettingsIfDirExists {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$TargetDir
    )

    if (-not (Test-Path -LiteralPath $TargetDir)) {
        Write-Warning "Skip appsettings copy; directory not found: $TargetDir"
        return
    }
    Copy-Item -LiteralPath $Source -Destination (Join-Path $TargetDir "appsettings.json") -Force
    Write-Host "appsettings.json -> $TargetDir" -ForegroundColor DarkCyan
}

function Copy-AppSettingsToFlutterDeployOutputs {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$FlutterProjectPath,
        [switch]$IncludeWeb,
        [switch]$IncludeWindows,
        [switch]$IncludeLinux,
        [switch]$IncludeAndroidPublish,
        [string]$AndroidPublishDir = ""
    )

    $source = Get-RepoAppSettingsPath -RepoRoot $RepoRoot
    Sync-AppSettingsToFlutterProjectAssets -RepoRoot $RepoRoot -FlutterProjectPath $FlutterProjectPath

    if ($IncludeWeb) {
        Copy-AppSettingsIfDirExists -Source $source -TargetDir (Join-Path $FlutterProjectPath "build\web")
    }

    if ($IncludeWindows) {
        Copy-AppSettingsIfDirExists -Source $source -TargetDir (Join-Path $FlutterProjectPath "build\windows\x64\runner\Release")
        Copy-AppSettingsIfDirExists -Source $source -TargetDir (Join-Path $FlutterProjectPath "build\windows\x64\runner\Debug")
    }

    if ($IncludeLinux) {
        Copy-AppSettingsIfDirExists -Source $source -TargetDir (Join-Path $FlutterProjectPath "build\linux\x64\release\bundle")
        Copy-AppSettingsIfDirExists -Source $source -TargetDir (Join-Path $FlutterProjectPath "build\linux\x64\debug\bundle")
    }

    if ($IncludeAndroidPublish -and -not [string]::IsNullOrWhiteSpace($AndroidPublishDir)) {
        if (Test-Path -LiteralPath $AndroidPublishDir) {
            Copy-AppSettingsIfDirExists -Source $source -TargetDir $AndroidPublishDir
        }
        else {
            Write-Warning "Android publish dir not found: $AndroidPublishDir"
        }
    }
}

function Ensure-FlutterAppSettingsForBuild {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$FlutterProjectPath,
        [switch]$AllDeployOutputs,
        [string]$AndroidPublishDir = ""
    )

    if ($AllDeployOutputs) {
        Copy-AppSettingsToFlutterDeployOutputs `
            -RepoRoot $RepoRoot `
            -FlutterProjectPath $FlutterProjectPath `
            -IncludeWeb `
            -IncludeWindows `
            -IncludeLinux `
            -IncludeAndroidPublish `
            -AndroidPublishDir $AndroidPublishDir
    }
    else {
        Sync-AppSettingsToFlutterProjectAssets -RepoRoot $RepoRoot -FlutterProjectPath $FlutterProjectPath
    }
}
