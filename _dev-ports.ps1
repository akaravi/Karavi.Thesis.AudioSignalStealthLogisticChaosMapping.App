# Karavi Thesis Audio Stegano — local dev ports (5320-5329).
# Dot-source from repo root:  . .\_dev-ports.ps1

$script:KaraviDevPorts = [ordered]@{
    FlutterWeb       = 5320  # flutter run -d web-server --web-port
    FlutterWebChrome = 5321  # flutter run -d chrome --web-port (optional)
    WpfDesktop       = 5322  # reserved (WPF: no HTTP listener)
    FlutterWindowsVm = 5323  # flutter run -d windows --host-vmservice-port
    FlutterDevTools  = 5324  # flutter run --devtools-port
    Reserved6        = 5325
    Reserved7        = 5326
    Reserved8        = 5327
    Reserved9        = 5328
    Reserved10       = 5329
}

function Get-KaraviDevPort {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $script:KaraviDevPorts.Contains($Name)) {
        $keys = ($script:KaraviDevPorts.Keys -join ', ')
        throw "Unknown dev port '$Name'. Valid keys: $keys"
    }

    return [int]$script:KaraviDevPorts[$Name]
}

function Get-KaraviDevHttpUrl {
    param(
        [Parameter(Mandatory = $true)][int]$Port,
        [string]$Path = '/',
        [string]$HostName = '127.0.0.1'
    )

    if (-not $Path.StartsWith('/')) {
        $Path = "/$Path"
    }

    return "http://${HostName}:$Port$Path"
}

function Write-KaraviDevPortLegend {
    Write-Host ""
    Write-Host "Local dev ports (5320-5329):" -ForegroundColor Cyan
    foreach ($entry in $script:KaraviDevPorts.GetEnumerator()) {
        $note = switch ($entry.Key) {
            'FlutterWeb'       { 'HTTP — Flutter web-server' }
            'FlutterWebChrome' { 'HTTP — Flutter chrome (optional)' }
            'WpfDesktop'       { 'reserved — WPF desktop (no HTTP)' }
            'FlutterWindowsVm' { 'VM service — Flutter Windows debug' }
            'FlutterDevTools'  { 'Dart DevTools' }
            default            { 'reserved' }
        }
        Write-Host ("  {0,-18} {1,5}  {2}" -f $entry.Key, $entry.Value, $note) -ForegroundColor DarkGray
    }
    Write-Host ""
}
