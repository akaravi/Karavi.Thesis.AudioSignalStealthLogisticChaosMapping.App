# Pre-deploy verification gate — audio payload timing + core stego tests.
# Run from repo root before Cafe Bazaar / store upload / release publish:
#   .\_test-pre-deploy.ps1
param(
    [switch]$SkipDotnet,
    [switch]$SkipFlutter
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$failed = $false

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

$flutterCmd = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutterCmd) {
    foreach ($c in @(
            $(if ($env:FLUTTER_HOME) { Join-Path $env:FLUTTER_HOME 'bin\flutter.bat' }),
            'D:\Android\flutter\bin\flutter.bat'
        )) {
        if ($c -and (Test-Path -LiteralPath $c)) { $flutterCmd = $c; break }
    }
}

if (-not $SkipDotnet) {
    Write-Step 'dotnet test (Core — envelope + audio duration)'
    Push-Location (Join-Path $root 'src\audio_stegano_desktop')
    try {
        dotnet test tests/AudioStegano.Core.Tests/AudioStegano.Core.Tests.csproj -c Release --nologo
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'FAILED: dotnet Core tests' -ForegroundColor Red
            $failed = $true
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host 'Skipped dotnet tests' -ForegroundColor Yellow
}

if (-not $SkipFlutter) {
    if (-not $flutterCmd) {
        Write-Host 'FAILED: Flutter SDK not found' -ForegroundColor Red
        $failed = $true
    }
    else {
        Write-Step 'flutter test (payload envelope + audio duration — pre-deploy)'
        Push-Location (Join-Path $root 'src\audio_stegano_app')
        try {
            & $flutterCmd test `
                test/core/payload_envelope_test.dart `
                test/core/audio_payload_duration_test.dart `
                test/core/stego_engine_test.dart `
                test/core/lsb_codec_test.dart
            if ($LASTEXITCODE -ne 0) {
                Write-Host 'FAILED: flutter pre-deploy tests' -ForegroundColor Red
                $failed = $true
            }
        }
        finally {
            Pop-Location
        }
    }
}
else {
    Write-Host 'Skipped flutter tests' -ForegroundColor Yellow
}

Write-Host ""
if ($failed) {
    Write-Host 'PRE-DEPLOY GATE: FAILED — do not deploy' -ForegroundColor Red
    exit 1
}

Write-Host 'PRE-DEPLOY GATE: PASSED' -ForegroundColor Green
Write-Host 'Critical checks: ASTG envelope, audio duration (no fast speech), stego round-trip.'
exit 0
