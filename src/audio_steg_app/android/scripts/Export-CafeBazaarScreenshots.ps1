# Generates Cafe Bazaar phone screenshots (1080x1920 PNG) via Flutter golden tests.
# Output: publish/cafebazaar/screenshots/
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$flutterDir = Join-Path $RepoRoot 'src\audio_steg_app'
$goldens = Join-Path $flutterDir 'test\goldens\cafebazaar'  # not test\store\test\goldens
$publish = Join-Path $RepoRoot 'publish\cafebazaar\screenshots'

Push-Location $flutterDir
try {
    flutter test test/store/cafebazaar_screenshots_test.dart --update-goldens
    if (-not (Test-Path $goldens)) {
        throw "Golden folder not found: $goldens"
    }
    New-Item -ItemType Directory -Force -Path $publish | Out-Null
    Copy-Item -Path (Join-Path $goldens '*.png') -Destination $publish -Force
    Write-Host "Screenshots copied to: $publish"
    Get-ChildItem $publish -Filter '*.png' | ForEach-Object {
        Write-Host ('  ' + $_.Name + '  ' + $_.Length + ' bytes')
    }
}
finally {
    Pop-Location
}
