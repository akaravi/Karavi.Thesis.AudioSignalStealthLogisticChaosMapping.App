$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root 'logs'
$flutterApp = Join-Path $root 'src\audio_stegano_app'
$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = 'D:\Android\flutter\bin\flutter.bat' }

Get-NetTCPConnection -LocalPort 5323 -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

Start-Sleep -Seconds 2

$vmPort = 5323
$winArgs = @('run', '-d', 'windows', "--host-vmservice-port=$vmPort", "--device-vmservice-port=$vmPort")
$win = Start-Process -FilePath $flutter `
    -ArgumentList $winArgs `
    -WorkingDirectory $flutterApp `
    -RedirectStandardOutput (Join-Path $logDir 'flutter_windows_run2.log') `
    -RedirectStandardError (Join-Path $logDir 'flutter_windows_run2.err') `
    -PassThru -WindowStyle Hidden
$win.Id | Out-File -Encoding ascii (Join-Path $logDir 'flutter_windows.pid')
Write-Host "Flutter Windows pid=$($win.Id)"
