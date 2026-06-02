$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root 'logs'
$desktopProj = Join-Path $root 'src\audio_stegano_desktop\src\AudioStegano.Desktop\AudioStegano.Desktop.csproj'
$wpf = Start-Process -FilePath 'dotnet' `
    -ArgumentList @('run', '--project', $desktopProj) `
    -WorkingDirectory (Join-Path $root 'src\audio_stegano_desktop') `
    -RedirectStandardOutput (Join-Path $logDir 'wpf_run2.log') `
    -RedirectStandardError (Join-Path $logDir 'wpf_run2.err') `
    -PassThru -WindowStyle Hidden
$wpf.Id | Out-File -Encoding ascii (Join-Path $logDir 'wpf.pid')
Start-Sleep -Seconds 6
$proc = Get-Process -Name 'AudioStegano.Desktop' -ErrorAction SilentlyContinue
if ($proc) { Write-Host "WPF running pid=$($proc.Id)" } else { Write-Host 'WPF not yet visible' }
