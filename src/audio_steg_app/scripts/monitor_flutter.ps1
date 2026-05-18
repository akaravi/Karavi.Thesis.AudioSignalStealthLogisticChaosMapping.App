# Tails Flutter session + run logs while testing. Run from audio_steg_app/.
param(
    [int]$PollSeconds = 2
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot
$LogDir = Join-Path $ProjectRoot 'logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$SessionLog = Join-Path $LogDir 'flutter_session.log'
$RunLog     = Join-Path $LogDir 'flutter_run_monitor.log'
$ErrorLog   = Join-Path $LogDir 'flutter_errors.log'

Write-Host "Monitoring Flutter logs (Ctrl+C to stop)"
Write-Host "  Session : $SessionLog"
Write-Host "  Run     : $RunLog"
Write-Host "  Errors  : $ErrorLog"
Write-Host ""

$lastSessionSize = 0L
$lastRunSize = 0L

while ($true) {
    $proc = Get-Process -Name 'audio_steg_app' -ErrorAction SilentlyContinue
    $alive = $null -ne $proc

    foreach ($pair in @(
            @{ Path = $SessionLog; Ref = [ref]$lastSessionSize },
            @{ Path = $RunLog; Ref = [ref]$lastRunSize }
        )) {
        $path = $pair.Path
        if (-not (Test-Path $path)) { continue }
        $info = Get-Item $path
        if ($info.Length -le $pair.Ref.Value) { continue }
        $pair.Ref.Value = $info.Length
        $newLines = Get-Content $path -Tail 40
        foreach ($line in $newLines) {
            if ($line -match 'FlutterError|UncaughtZonedError|Exception|ERROR|FATAL|crash|Lost connection') {
                $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                $entry = "[$stamp] $line"
                Add-Content -Path $ErrorLog -Value $entry
                Write-Host $entry -ForegroundColor Red
            }
        }
    }

    if (-not $alive) {
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $msg = "[$stamp] PROCESS EXIT: audio_steg_app not running"
        Add-Content -Path $ErrorLog -Value $msg
        Write-Host $msg -ForegroundColor Yellow
    }

    Start-Sleep -Seconds $PollSeconds
}
