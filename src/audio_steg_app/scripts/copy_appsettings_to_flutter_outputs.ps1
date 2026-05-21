# Copies repo-root appsettings.json beside Flutter web / Windows release outputs (editable at deploy time).

function Copy-AppSettingsToFlutterDeployOutputs {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$FlutterProjectPath,
        [switch]$IncludeWeb,
        [switch]$IncludeWindows
    )

    $source = Join-Path $RepoRoot "appsettings.json"
    if (-not (Test-Path -LiteralPath $source)) {
        throw "appsettings.json not found at repo root: $source"
    }

    if ($IncludeWeb) {
        $webDir = Join-Path $FlutterProjectPath "build\web"
        if (Test-Path -LiteralPath $webDir) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $webDir "appsettings.json") -Force
            Write-Host "appsettings.json -> $webDir" -ForegroundColor DarkCyan
        }
        else {
            Write-Warning "Flutter web output not found: $webDir"
        }
    }

    if ($IncludeWindows) {
        $winDir = Join-Path $FlutterProjectPath "build\windows\x64\runner\Release"
        if (Test-Path -LiteralPath $winDir) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $winDir "appsettings.json") -Force
            Write-Host "appsettings.json -> $winDir" -ForegroundColor DarkCyan
        }
        else {
            Write-Warning "Flutter Windows release output not found: $winDir"
        }
    }
}
