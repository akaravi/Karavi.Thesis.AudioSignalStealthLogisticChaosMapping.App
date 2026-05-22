# restart_all.ps1
# Stop the running Audio Stegano desktop app and restart from the latest release build.

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$LogDir  = Join-Path $ProjectRoot 'logs'
$PidFile = Join-Path $LogDir 'app.pid'
$Exe     = Join-Path $ProjectRoot 'build\windows\x64\runner\Release\audio_stegano_app.exe'

if (Test-Path $PidFile) {
    $existingPid = Get-Content $PidFile | Select-Object -First 1
    if ($existingPid) {
        try {
            Stop-Process -Id $existingPid -Force -ErrorAction Stop
            Write-Host ("Stopped pid={0}" -f $existingPid)
        } catch {
            Write-Host "Stale pid file (process already gone)"
        }
    }
    Remove-Item $PidFile -ErrorAction SilentlyContinue
}

# Also clean up any orphan instance launched outside the pid file.
Get-Process -Name 'audio_stegano_app' -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }

if (-not (Test-Path $Exe)) {
    Write-Host "Release build missing — running flutter build windows --release ..."
    $flutterCmd = (Get-Command flutter -ErrorAction SilentlyContinue).Source
    if (-not $flutterCmd) { throw "Flutter not found on PATH." }
    . (Join-Path $PSScriptRoot "invoke_flutter_windows_build.ps1")
    Invoke-FlutterWindowsReleaseBuild -ProjectDirectory $ProjectRoot -FlutterExecutable $flutterCmd
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$proc = Start-Process -FilePath $Exe -PassThru -WindowStyle Normal
$proc.Id | Out-File -Encoding ascii $PidFile
Start-Sleep -Seconds 2

if ($proc.HasExited) {
    Write-Host ("App failed to start. Exit code: {0}" -f $proc.ExitCode)
} else {
    $alive = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
    $resp  = if ($alive) { $alive.Responding } else { 'unknown' }
    Write-Host ("Restarted. pid={0} responding={1}" -f $proc.Id, $resp)
}
