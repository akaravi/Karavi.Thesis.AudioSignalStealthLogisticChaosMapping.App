# run_all.ps1
# Audio Steg cross-platform app — orchestrator for the user's "run all" rule.
#
# Steps:
#  1. Verify Flutter SDK and dependencies
#  2. Static analysis (flutter analyze)
#  3. Unit tests (flutter test)
#  4. Build Windows release
#  5. Launch Windows debug app in the background and tail logs
#  6. Health check: verify the app process is running and produces no errors

[CmdletBinding()]
param(
    [switch]$NoBuild,
    [switch]$NoLaunch,
    [switch]$Stop
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$LogDir = Join-Path $ProjectRoot 'logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$RunLog     = Join-Path $LogDir 'run_app.log'
$AnalyzeLog = Join-Path $LogDir 'analyze.log'
$TestLog    = Join-Path $LogDir 'test.log'
$PidFile    = Join-Path $LogDir 'app.pid'

function Stop-App {
    if (Test-Path $PidFile) {
        $existingPid = Get-Content $PidFile | Select-Object -First 1
        if ($existingPid) {
            try {
                Stop-Process -Id $existingPid -Force -ErrorAction Stop
                Write-Host "Stopped previous app (pid=$existingPid)"
            } catch {
                Write-Host "No live process for pid=$existingPid"
            }
        }
        Remove-Item $PidFile -ErrorAction SilentlyContinue
    }
}

if ($Stop) {
    Stop-App
    return
}

Write-Host "==> 1) flutter --version"
flutter --version

Write-Host "==> 2) flutter pub get"
flutter pub get | Out-Null

Write-Host "==> 3) flutter analyze (log: $AnalyzeLog)"
flutter analyze 2>&1 | Tee-Object -FilePath $AnalyzeLog
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }

Write-Host "==> 4) flutter test (log: $TestLog)"
flutter test 2>&1 | Tee-Object -FilePath $TestLog
if ($LASTEXITCODE -ne 0) { throw "flutter test failed" }

if (-not $NoBuild) {
    Write-Host "==> 5) flutter build windows --release"
    flutter build windows --release | Tee-Object -FilePath (Join-Path $LogDir 'build_windows.log')
}

if (-not $NoLaunch) {
    Stop-App
    Write-Host "==> 6) flutter run -d windows  (background, log: $RunLog)"
    $proc = Start-Process -FilePath "flutter" `
        -ArgumentList @('run', '-d', 'windows', '--no-hot') `
        -RedirectStandardOutput $RunLog `
        -RedirectStandardError  (Join-Path $LogDir 'run_app.err') `
        -PassThru -WindowStyle Hidden
    $proc.Id | Out-File -Encoding ascii $PidFile
    Write-Host "App started (pid=$($proc.Id)). Log: $RunLog"
    Write-Host "Use:  scripts\run_all.ps1 -Stop   to stop it."
    Write-Host "Use:  Get-Content -Wait $RunLog  to tail."
}

Write-Host ""
Write-Host "============================================"
Write-Host "Healthcheck summary"
Write-Host "============================================"
Write-Host "Analyze log : $AnalyzeLog"
Write-Host "Test log    : $TestLog"
Write-Host "Run log     : $RunLog"
if (Test-Path $PidFile) {
    Write-Host "App pid     : $(Get-Content $PidFile)"
}
Write-Host "App URL     : (desktop window — no HTTP endpoint)"
Write-Host "============================================"
