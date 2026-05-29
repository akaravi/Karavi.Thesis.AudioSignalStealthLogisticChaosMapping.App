# Run all local dev targets on ports 5320-5329 (see _dev-ports.ps1).
param(
    [switch]$RestartAll,
    [switch]$SkipAnalyze,
    [switch]$SkipTests,
    [switch]$SkipBuild,
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root '_dev-ports.ps1')
. (Join-Path $root '_last-run-info.ps1')

$lastRunInfoPath = Join-Path $root 'LastRunInfo.html'
$script:RunResults = New-Object System.Collections.Generic.List[object]
$script:ServiceAddresses = New-Object System.Collections.Generic.List[object]
$script:OverallSuccess = $true
$script:ExitCode = 0

$solutionPath = Join-Path $root 'src\audio_stegano_desktop\AudioStegano.sln'
$desktopProj = Join-Path $root 'src\audio_stegano_desktop\src\AudioStegano.Desktop\AudioStegano.Desktop.csproj'
$flutterAppPath = Join-Path $root 'src\audio_stegano_app'
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$webPort = Get-KaraviDevPort -Name 'FlutterWeb'
$vmPort = Get-KaraviDevPort -Name 'FlutterWindowsVm'
$devtoolsPort = Get-KaraviDevPort -Name 'FlutterDevTools'
$chromePort = Get-KaraviDevPort -Name 'FlutterWebChrome'
$webUrl = Get-KaraviDevHttpUrl -Port $webPort
$devtoolsUrl = Get-KaraviDevHttpUrl -Port $devtoolsPort

function Add-RunResult {
    param(
        [string]$Step,
        [string]$Status,
        [string]$Detail = ''
    )
    $script:RunResults.Add((New-KaraviRunResultRow -Step $Step -Status $Status -Detail $Detail)) | Out-Null
    if ($Status -eq 'Failed') {
        $script:OverallSuccess = $false
    }
}

function Add-ServiceAddress {
    param(
        [string]$Service,
        [string]$Address,
        [string]$Notes = ''
    )
    $script:ServiceAddresses.Add([ordered]@{
            Service = $Service
            Address = $Address
            Notes   = $Notes
        }) | Out-Null
}

function Write-LastRunReport {
    $services = [object[]]@()
    foreach ($item in $script:ServiceAddresses) {
        $services += $item
    }
    if ($services.Length -eq 0) {
        $services = @([ordered]@{
                Service = '(none)'
                Address = '-'
                Notes   = 'NoLaunch or services not started'
            })
    }
    Write-KaraviLastRunInfoHtml `
        -OutputPath $lastRunInfoPath `
        -InvokedBy '_run-all-local.ps1' `
        -RunResults ([object[]]($script:RunResults | ForEach-Object { $_ })) `
        -ServiceAddresses $services `
        -OverallSuccess $script:OverallSuccess `
        -Summary $(if ($NoLaunch) { 'Build and checks without launching services' } else { 'Local run: WPF + Flutter Windows + Flutter Web' })
}

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
$flutterCommand = if ($flutterCmd) { $flutterCmd.Source } else { $null }
if (-not $flutterCommand) {
    foreach ($candidate in @(
            $(if ($env:FLUTTER_HOME) { Join-Path $env:FLUTTER_HOME 'bin\flutter.bat' }),
            'D:\Android\flutter\bin\flutter.bat'
        )) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            $flutterCommand = $candidate
            break
        }
    }
}

try {
    if (-not $flutterCommand) {
        Add-RunResult -Step 'Flutter SDK' -Status 'Failed' -Detail 'Flutter not found on PATH'
        throw 'Flutter was not found on PATH.'
    }
    Add-RunResult -Step 'Flutter SDK' -Status 'Success' -Detail $flutterCommand

    function Stop-PortListener {
        param([int]$Port)
        try {
            $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
            foreach ($c in $conn) {
                Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }
    }

    function Stop-DevProcesses {
        foreach ($name in @('AudioStegano.Desktop', 'audio_stegano_app', 'dart')) {
            Get-Process -Name $name -ErrorAction SilentlyContinue |
                Stop-Process -Force -ErrorAction SilentlyContinue
        }
        foreach ($entry in $script:KaraviDevPorts.Values) {
            Stop-PortListener -Port $entry
        }
        foreach ($pidFile in @('wpf.pid', 'flutter_windows.pid', 'flutter_web.pid')) {
            $path = Join-Path $logDir $pidFile
            if (Test-Path -LiteralPath $path) {
                $oldPid = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($oldPid) {
                    Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
                }
                Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($RestartAll) {
        Stop-DevProcesses
        Add-RunResult -Step 'Stop previous run' -Status 'Success' -Detail 'RestartAll'
    }
    else {
        Add-RunResult -Step 'Stop previous run' -Status 'Skipped' -Detail 'no RestartAll'
    }

    Write-Host '==> dotnet build (Debug)' -ForegroundColor Cyan
    Push-Location (Join-Path $root 'src\audio_stegano_desktop')
    try {
        dotnet build $solutionPath -c Debug 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Add-RunResult -Step 'dotnet build (Debug)' -Status 'Failed' -Detail "exit $LASTEXITCODE"
            throw 'dotnet build failed'
        }
        Add-RunResult -Step 'dotnet build (Debug)' -Status 'Success'
    }
    finally {
        Pop-Location
    }

    Push-Location $flutterAppPath
    try {
        Write-Host '==> flutter pub get' -ForegroundColor Cyan
        & $flutterCommand pub get 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Add-RunResult -Step 'flutter pub get' -Status 'Failed' -Detail "exit $LASTEXITCODE"
            throw 'flutter pub get failed'
        }
        Add-RunResult -Step 'flutter pub get' -Status 'Success'

        if (-not $SkipAnalyze) {
            Write-Host '==> flutter analyze' -ForegroundColor Cyan
            & $flutterCommand analyze --no-fatal-infos 2>&1 |
                Tee-Object -FilePath (Join-Path $logDir 'analyze.log') | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Add-RunResult -Step 'flutter analyze' -Status 'Failed' -Detail "exit $LASTEXITCODE"
                throw 'flutter analyze failed'
            }
            Add-RunResult -Step 'flutter analyze' -Status 'Success'
        }
        else {
            Add-RunResult -Step 'flutter analyze' -Status 'Skipped'
        }

        if (-not $SkipTests) {
            Write-Host '==> flutter test' -ForegroundColor Cyan
            & $flutterCommand test 2>&1 |
                Tee-Object -FilePath (Join-Path $logDir 'test.log') | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Add-RunResult -Step 'flutter test' -Status 'Failed' -Detail "exit $LASTEXITCODE"
                throw 'flutter test failed'
            }
            Add-RunResult -Step 'flutter test' -Status 'Success'
        }
        else {
            Add-RunResult -Step 'flutter test' -Status 'Skipped'
        }

        if (-not $SkipBuild) {
            Write-Host '==> flutter build windows (debug)' -ForegroundColor Cyan
            & $flutterCommand build windows --debug 2>&1 |
                Tee-Object -FilePath (Join-Path $logDir 'build_windows_debug.log') | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Add-RunResult -Step 'flutter build windows (debug)' -Status 'Failed' -Detail "exit $LASTEXITCODE"
                throw 'flutter build windows failed'
            }
            Add-RunResult -Step 'flutter build windows (debug)' -Status 'Success'
        }
        else {
            Add-RunResult -Step 'flutter build windows (debug)' -Status 'Skipped'
        }
    }
    finally {
        Pop-Location
    }

    if ($NoLaunch) {
        Add-RunResult -Step 'Launch services' -Status 'Skipped' -Detail 'NoLaunch'
        Write-KaraviDevPortLegend
        Write-Host 'NoLaunch: skipped starting dev processes.' -ForegroundColor Yellow
        return
    }

    Write-Host '==> Starting dev processes (background)' -ForegroundColor Cyan

    $wpfLog = Join-Path $logDir 'wpf_run.log'
    $wpfProc = Start-Process -FilePath 'dotnet' `
        -ArgumentList @('run', '--project', $desktopProj) `
        -WorkingDirectory (Join-Path $root 'src\audio_stegano_desktop') `
        -RedirectStandardOutput $wpfLog `
        -RedirectStandardError (Join-Path $logDir 'wpf_run.err') `
        -PassThru -WindowStyle Hidden
    $wpfProc.Id | Out-File -Encoding ascii (Join-Path $logDir 'wpf.pid')
    Add-RunResult -Step 'AudioStegano.Desktop (WPF)' -Status 'Started' -Detail "pid=$($wpfProc.Id)"
    Add-ServiceAddress -Service 'WPF - AudioStegano.Desktop' `
        -Address ('desktop window, pid ' + $wpfProc.Id) `
        -Notes ('port ' + (Get-KaraviDevPort WpfDesktop) + ' reserved, no HTTP')

    $flutterWinLog = Join-Path $logDir 'flutter_windows_run.log'
    $flutterWinArgs = @(
        'run', '-d', 'windows',
        "--host-vmservice-port=$vmPort",
        "--device-vmservice-port=$vmPort",
        "--devtools-port=$devtoolsPort"
    )
    $flutterWinProc = Start-Process -FilePath $flutterCommand `
        -ArgumentList $flutterWinArgs `
        -WorkingDirectory $flutterAppPath `
        -RedirectStandardOutput $flutterWinLog `
        -RedirectStandardError (Join-Path $logDir 'flutter_windows_run.err') `
        -PassThru -WindowStyle Hidden
    $flutterWinProc.Id | Out-File -Encoding ascii (Join-Path $logDir 'flutter_windows.pid')
    Add-RunResult -Step 'Flutter Windows' -Status 'Started' -Detail "pid=$($flutterWinProc.Id); VM $vmPort"
    Add-ServiceAddress -Service 'Flutter Windows (VM service)' `
        -Address "http://127.0.0.1:$vmPort/" `
        -Notes ('DevTools: ' + $devtoolsUrl + '، pid ' + $flutterWinProc.Id)

    $flutterWebLog = Join-Path $logDir 'flutter_web_run.log'
    $flutterWebArgs = @(
        'run', '-d', 'web-server',
        "--web-port=$webPort",
        '--web-hostname=127.0.0.1'
    )
    $flutterWebProc = Start-Process -FilePath $flutterCommand `
        -ArgumentList $flutterWebArgs `
        -WorkingDirectory $flutterAppPath `
        -RedirectStandardOutput $flutterWebLog `
        -RedirectStandardError (Join-Path $logDir 'flutter_web_run.err') `
        -PassThru -WindowStyle Hidden
    $flutterWebProc.Id | Out-File -Encoding ascii (Join-Path $logDir 'flutter_web.pid')
    Add-RunResult -Step 'Flutter Web (web-server)' -Status 'Started' -Detail "pid=$($flutterWebProc.Id); port $webPort"

    Add-ServiceAddress -Service 'Flutter Web' -Address $webUrl -Notes ("chrome/edge port " + $chromePort)
    Add-ServiceAddress -Service 'Dart DevTools' -Address $devtoolsUrl -Notes 'with Flutter Windows'

    Write-Host 'Waiting for Flutter web dev server...' -ForegroundColor DarkGray
    $webHealthy = $false
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 2
        try {
            $resp = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -eq 200) {
                $webHealthy = $true
                break
            }
        }
        catch { }
    }

    if ($webHealthy) {
        Add-RunResult -Step 'Health - Flutter Web' -Status 'Success' -Detail 'HTTP 200'
    }
    else {
        Add-RunResult -Step 'Health - Flutter Web' -Status 'Failed' -Detail ('no response at ' + $webUrl)
        $script:OverallSuccess = $false
        $script:ExitCode = 1
    }

    Write-Host ''
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host 'Local dev - addresses' -ForegroundColor Cyan
    Write-Host "  Flutter Web: $webUrl $(if ($webHealthy) { '[HTTP 200]' } else { '[failed]' })"
    Write-Host "  LastRunInfo: $lastRunInfoPath"
    Write-KaraviDevPortLegend
    Write-Host '============================================' -ForegroundColor Cyan
}
catch {
    $script:OverallSuccess = $false
    if ($script:ExitCode -eq 0) { $script:ExitCode = 1 }
    if ($_.Exception.Message) {
        Add-RunResult -Step 'Fatal error' -Status 'Failed' -Detail $_.Exception.Message
    }
    throw
}
finally {
    Write-LastRunReport
}

if ($script:ExitCode -ne 0) {
    exit $script:ExitCode
}
