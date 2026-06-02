# Launch WPF + Flutter Web + Flutter Windows (ports from _dev-ports.ps1).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
. (Join-Path $root '_dev-ports.ps1')
. (Join-Path $root '_flutter-web-no-cdn.ps1')

foreach ($name in @('AudioStegano.Desktop', 'audio_stegano_app', 'dart')) {
    Get-Process -Name $name -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}
foreach ($entry in $script:KaraviDevPorts.Values) {
    Get-NetTCPConnection -LocalPort $entry -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}

$desktopProj = Join-Path $root 'src\audio_stegano_desktop\src\AudioStegano.Desktop\AudioStegano.Desktop.csproj'
$flutterApp = Join-Path $root 'src\audio_stegano_app'
$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = 'D:\Android\flutter\bin\flutter.bat' }

$wpf = Start-Process -FilePath 'dotnet' `
    -ArgumentList @('run', '--project', $desktopProj) `
    -WorkingDirectory (Join-Path $root 'src\audio_stegano_desktop') `
    -RedirectStandardOutput (Join-Path $logDir 'wpf_run.log') `
    -RedirectStandardError (Join-Path $logDir 'wpf_run.err') `
    -PassThru -WindowStyle Hidden
$wpf.Id | Out-File -Encoding ascii (Join-Path $logDir 'wpf.pid')

$webPort = Get-KaraviDevPort -Name 'FlutterWeb'
$vmPort = Get-KaraviDevPort -Name 'FlutterWindowsVm'
$webArgs = New-KaraviFlutterWebRunArgumentList -Device 'web-server' -WebPort $webPort
$web = Start-Process -FilePath $flutter `
    -ArgumentList $webArgs `
    -WorkingDirectory $flutterApp `
    -RedirectStandardOutput (Join-Path $logDir 'flutter_web_run.log') `
    -RedirectStandardError (Join-Path $logDir 'flutter_web_run.err') `
    -PassThru -WindowStyle Hidden
$web.Id | Out-File -Encoding ascii (Join-Path $logDir 'flutter_web.pid')

$winArgs = @('run', '-d', 'windows', "--host-vmservice-port=$vmPort", "--device-vmservice-port=$vmPort")
$win = Start-Process -FilePath $flutter `
    -ArgumentList $winArgs `
    -WorkingDirectory $flutterApp `
    -RedirectStandardOutput (Join-Path $logDir 'flutter_windows_run.log') `
    -RedirectStandardError (Join-Path $logDir 'flutter_windows_run.err') `
    -PassThru -WindowStyle Hidden
$win.Id | Out-File -Encoding ascii (Join-Path $logDir 'flutter_windows.pid')

Write-Host "WPF pid=$($wpf.Id) Web pid=$($web.Id) Win pid=$($win.Id)"
