$webUrl = 'http://127.0.0.1:5320/'
$vmUrl = 'http://127.0.0.1:5323/'
$devtoolsUrl = 'http://127.0.0.1:5324/'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root 'logs'

$webCode = 'timeout'
for ($i = 0; $i -lt 45; $i++) {
    try {
        $r = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -TimeoutSec 3
        $webCode = [string]$r.StatusCode
        break
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

function Test-UrlCode([string]$Url) {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return [string]$r.StatusCode
    }
    catch {
        return 'fail'
    }
}

$vmCode = Test-UrlCode $vmUrl
$devtoolsCode = Test-UrlCode $devtoolsUrl

$wpfProc = Get-Process -Name 'AudioStegano.Desktop' -ErrorAction SilentlyContinue
$wpfAlive = if ($wpfProc) { 'running pid=' + $wpfProc.Id } else { 'not found' }

Write-Output "WEB=$webCode VM=$vmCode DEVTOOLS=$devtoolsCode WPF=$wpfAlive"
Write-Output "PIDS wpf=$(Get-Content (Join-Path $logDir 'wpf.pid') -EA SilentlyContinue) web=$(Get-Content (Join-Path $logDir 'flutter_web.pid') -EA SilentlyContinue) win=$(Get-Content (Join-Path $logDir 'flutter_windows.pid') -EA SilentlyContinue)"
