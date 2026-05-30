param(
    [switch]$SkipRestore,
    [switch]$SkipPackage,
    [string]$ZipOutputDirectory = "",
    [switch]$PackageOnly,
    [switch]$OfflinePubGet,
    [string]$PubHostedUrl = "",
    [string]$FlutterStorageBaseUrl = "",
    [switch]$UseFlutterIoCnMirror,
    [switch]$DisableAutoMirrorRetry,
    [switch]$OpenDeveloperSettings,
    [switch]$SkipTests,
    [switch]$SkipFlutterAnalyze,
    [switch]$SkipDevServers,
    [string]$WebBaseHref = "/",
    [string]$OutputDirectory = "",
    [ValidateSet("chrome", "edge", "web-server")]
    [string]$DevServerDevice = "chrome",
    [int]$WebPort = 0
)

$ErrorActionPreference = "Stop"

$savedEnvPubHostedAtScriptStart = $env:PUB_HOSTED_URL
$userSuppliedMirrorViaParam = $UseFlutterIoCnMirror -or (-not [string]::IsNullOrWhiteSpace($PubHostedUrl))

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root "_dev-ports.ps1")
. (Join-Path $root "_flutter-web-no-cdn.ps1")
if ($WebPort -le 0) {
    if ($DevServerDevice -eq "web-server") {
        $WebPort = Get-KaraviDevPort -Name "FlutterWeb"
    }
    else {
        $WebPort = Get-KaraviDevPort -Name "FlutterWebChrome"
    }
}
$flutterAppPath = Join-Path $root "src\audio_stegano_app"
$flutterWebBuildDir = Join-Path $flutterAppPath "build\web"
$defaultPublishDir = Join-Path $root "publish\flutter\web"

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [string[]]$CandidatePaths = @()
    )

    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    foreach ($candidate in $CandidatePaths) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        if (Test-Path $expanded) {
            return $expanded
        }
    }

    return $null
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)][string]$PathToCheck,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path $PathToCheck)) {
        throw "$Label was not found: $PathToCheck"
    }
}

function Resolve-ExistingOrNewDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return (New-Item -ItemType Directory -Path $Path -Force).FullName
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Resolve-FlutterWebReleasePath {
    param(
        [Parameter(Mandatory = $true)][string]$FlutterRoot
    )

    $releaseDir = Join-Path $FlutterRoot "build\web"
    $indexPath = Join-Path $releaseDir "index.html"
    if (-not (Test-Path $indexPath)) {
        throw "Flutter web release output was not found. Expected '$indexPath'. Run 'flutter build web --release --no-web-resources-cdn'."
    }

    return $releaseDir
}

function Normalize-WebBaseHref {
    param([string]$BaseHref)

    $normalized = $BaseHref.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        $normalized = "/"
    }
    if (-not $normalized.EndsWith("/")) {
        $normalized = "$normalized/"
    }
    if (-not $normalized.StartsWith("/")) {
        $normalized = "/$normalized"
    }
    return $normalized
}

function Copy-FlutterWebToPublish {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$DestinationDir
    )

    if (Test-Path $DestinationDir) {
        Remove-Item -Recurse -Force $DestinationDir
    }
    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    Copy-Item -Recurse -Force (Join-Path $SourceDir "*") $DestinationDir

    Write-Host ""
    Write-Host "Flutter web publish output:" -ForegroundColor Green
    Write-Host "  build -> $SourceDir" -ForegroundColor Yellow
    Write-Host "  copy  -> $DestinationDir" -ForegroundColor Yellow
}

function Invoke-FlutterWebZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipDirectory,
        [Parameter(Mandatory = $true)][string]$WebSourceDir
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $resolvedZipDir = Resolve-ExistingOrNewDirectory -Path $ZipDirectory
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "KaraviThesis_AudioStegano_FlutterWeb_$stamp.zip"
    $zipFullPath = Join-Path $resolvedZipDir $zipName

    $stageRoot = Join-Path $root "publish\flutter-web-staging"
    if (Test-Path $stageRoot) {
        Remove-Item -Recurse -Force $stageRoot
    }
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

    Write-Host "Staging web folder under $stageRoot ..." -ForegroundColor Cyan
    Copy-Item -Recurse -Force $WebSourceDir (Join-Path $stageRoot "audio_stegano_app_web")

    if (Test-Path $zipFullPath) {
        Remove-Item -Force $zipFullPath
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stageRoot,
        $zipFullPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false)

    Remove-Item -Recurse -Force $stageRoot

    Write-Host ""
    Write-Host "Flutter web ZIP created: $zipFullPath" -ForegroundColor Green
}

function Start-FlutterWebDevTerminal {
    param(
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$FlutterExe,
        [Parameter(Mandatory = $true)][string]$Device
    )

    $runArgs = (New-KaraviFlutterWebRunArgumentList -Device $Device -WebPort $WebPort) -join ' '

    $encoded = [Convert]::ToBase64String(
        [Text.Encoding]::Unicode.GetBytes("Set-Location '$WorkingDirectory'; & `"$FlutterExe`" $runArgs"))
    Start-Process powershell -ArgumentList "-NoExit", "-EncodedCommand", $encoded | Out-Null
    $url = Get-KaraviDevHttpUrl -Port $WebPort
    Write-Host "Started: audio_stegano_app - flutter $runArgs ($url)" -ForegroundColor Green
}

$flutterCandidates = @(
    if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_HOME)) { Join-Path $env:FLUTTER_HOME "bin\flutter.bat" }
    if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) { Join-Path $env:FLUTTER_ROOT "bin\flutter.bat" }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { Join-Path $env:LOCALAPPDATA "Programs\Flutter\bin\flutter.bat" }
    "D:\Android\flutter\bin\flutter.bat"
    "C:\src\flutter\bin\flutter.bat"
)
$flutterCommand = Resolve-CommandPath -CommandName "flutter" -CandidatePaths $flutterCandidates

if (-not $flutterCommand) {
    throw "Flutter was not found. Add Flutter to PATH or set FLUTTER_HOME/FLUTTER_ROOT, then run again."
}

$effectivePubHostedUrl = $PubHostedUrl
$effectiveFlutterStorageBaseUrl = $FlutterStorageBaseUrl
if ($UseFlutterIoCnMirror) {
    if ([string]::IsNullOrWhiteSpace($effectivePubHostedUrl)) {
        $effectivePubHostedUrl = "https://pub.flutter-io.cn"
    }
    if ([string]::IsNullOrWhiteSpace($effectiveFlutterStorageBaseUrl)) {
        $effectiveFlutterStorageBaseUrl = "https://storage.flutter-io.cn"
    }
    Write-Host "Pub/Flutter storage: using flutter-io.cn mirror (override with explicit URL params if needed)." -ForegroundColor DarkCyan
}
if (-not [string]::IsNullOrWhiteSpace($effectivePubHostedUrl)) {
    $env:PUB_HOSTED_URL = $effectivePubHostedUrl
}
if (-not [string]::IsNullOrWhiteSpace($effectiveFlutterStorageBaseUrl)) {
    $env:FLUTTER_STORAGE_BASE_URL = $effectiveFlutterStorageBaseUrl
}

$flutterPubGetArgs = @("pub", "get")
if ($OfflinePubGet) {
    $flutterPubGetArgs += "--offline"
}

function Write-PubGet403Hints {
    Write-Host ""
    Write-Host "flutter pub get failed. If the log shows Authentication error (403) or HostedSource._fetchAdvisories:" -ForegroundColor Yellow
    Write-Host "  pub.dev may be blocked or advisory requests return 403 from your network." -ForegroundColor Yellow
    Write-Host "  Try: upgrade Flutter/Dart; use VPN/proxy; or use a pub mirror." -ForegroundColor Yellow
    Write-Host "  Re-run with -OfflinePubGet if dependencies are already in the local pub cache." -ForegroundColor Yellow
    Write-Host "  Quick mirror: -UseFlutterIoCnMirror  (or -PubHostedUrl / -FlutterStorageBaseUrl)" -ForegroundColor Yellow
    Write-Host "  This script retries pub get with flutter-io.cn then Tsinghua mirror if needed (-DisableAutoMirrorRetry to skip)." -ForegroundColor Yellow
    Write-Host "  Or: .\_build-flutter-web.ps1 -UseFlutterIoCnMirror" -ForegroundColor Yellow
}

function Test-FlutterPubGetPackagesResolved {
    param([Parameter(Mandatory = $true)][string]$ProjectDirectory)

    return (Test-Path (Join-Path $ProjectDirectory ".dart_tool\package_config.json"))
}

function Test-FlutterPubGetSymlinkOnlyWarning {
    param([Parameter(Mandatory = $true)][string]$LogText)

    return $LogText -match '(?i)Developer Mode|symlink support'
}

function Write-FlutterPubGetFailureHints {
    param(
        [Parameter(Mandatory = $true)][string]$LogText,
        [switch]$LaunchDeveloperSettingsPage
    )

    if ($LogText -match '(?i)Developer Mode|symlink support') {
        Write-Host ""
        Write-Host "flutter pub get failed: Windows blocked plugin symlinks (not pub.dev 403)." -ForegroundColor Yellow
        Write-Host "  Turn ON Developer Mode (symlink support), then re-run:" -ForegroundColor Yellow
        Write-Host "    start ms-settings:developers" -ForegroundColor White
        if ($LaunchDeveloperSettingsPage) {
            try {
                Start-Process "ms-settings:developers" -ErrorAction Stop
                Write-Host "  Opened Windows Developer settings." -ForegroundColor DarkCyan
            }
            catch {
                Write-Host "  Could not open settings automatically; use the command above." -ForegroundColor DarkYellow
            }
        }
        return
    }
    Write-PubGet403Hints
}

function Write-FlutterPubOutputLines {
    param([object[]]$Lines)

    foreach ($item in $Lines) {
        if ($item -is [System.Management.Automation.ErrorRecord]) {
            $msg = $item.Exception.Message
            if (-not [string]::IsNullOrWhiteSpace($msg)) {
                Write-Host $msg
            }
        }
        else {
            Write-Host $item
        }
    }
}

function Convert-FlutterPubOutputToLogText {
    param([object[]]$Lines)

    return (($Lines | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $_.Exception.Message
            }
            else {
                "$_"
            }
        }) -join [Environment]::NewLine)
}

function Invoke-FlutterPubGetWithMirrorRetry {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory
    )

    $tryAutoMirror = -not $DisableAutoMirrorRetry -and -not $OfflinePubGet -and -not $userSuppliedMirrorViaParam -and [string]::IsNullOrWhiteSpace($savedEnvPubHostedAtScriptStart)
    $mirrorFallbacks = @(
        @{ Label = "flutter-io.cn"; Pub = "https://pub.flutter-io.cn"; Storage = "https://storage.flutter-io.cn" }
        @{ Label = "Tsinghua"; Pub = "https://mirrors.tuna.tsinghua.edu.cn/dart-pub/"; Storage = "https://mirrors.tuna.tsinghua.edu.cn/flutter" }
    )
    $maxAttempts = if ($tryAutoMirror) { 1 + $mirrorFallbacks.Count } else { 1 }
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $attempt++
        $exitCode = 0
        $pubLogText = ""
        Push-Location $ProjectDirectory
        try {
            $prevEap = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $pubGetOutput = @(& $flutterCommand @flutterPubGetArgs 2>&1)
                Write-FlutterPubOutputLines -Lines $pubGetOutput
                $exitCode = $LASTEXITCODE
                $pubLogText = Convert-FlutterPubOutputToLogText -Lines $pubGetOutput
            }
            finally {
                $ErrorActionPreference = $prevEap
            }
        }
        finally {
            Pop-Location
        }
        if ($exitCode -eq 0) {
            return
        }
        if ((Test-FlutterPubGetSymlinkOnlyWarning -LogText $pubLogText) -and
            (Test-FlutterPubGetPackagesResolved -ProjectDirectory $ProjectDirectory)) {
            Write-Host "flutter pub get: dependencies resolved; ignoring Windows symlink warning (web build can continue)." -ForegroundColor Yellow
            return
        }
        if ($OfflinePubGet) {
            Write-FlutterPubGetFailureHints -LogText $pubLogText
            throw "Flutter failed (exit $exitCode) in '$ProjectDirectory': flutter $($flutterPubGetArgs -join ' ')"
        }
        if ($attempt -lt $maxAttempts -and $tryAutoMirror) {
            $mirror = $mirrorFallbacks[$attempt - 1]
            Write-Host "flutter pub get failed; retry $($attempt + 1)/$maxAttempts with $($mirror.Label) mirror (-DisableAutoMirrorRetry to skip)." -ForegroundColor Yellow
            $env:PUB_HOSTED_URL = $mirror.Pub
            $env:FLUTTER_STORAGE_BASE_URL = $mirror.Storage
            continue
        }
        if ((Test-FlutterPubGetSymlinkOnlyWarning -LogText $pubLogText)) {
            Write-FlutterPubGetFailureHints -LogText $pubLogText -LaunchDeveloperSettingsPage:$OpenDeveloperSettings
            throw "Flutter pub get: Enable Windows Developer Mode for plugin symlinks, then re-run. Project: $ProjectDirectory"
        }
        Write-FlutterPubGetFailureHints -LogText $pubLogText
        throw "Flutter failed (exit $exitCode) in '$ProjectDirectory': flutter $($flutterPubGetArgs -join ' ')"
    }
}

function Invoke-FlutterInProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    Push-Location $ProjectDirectory
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & $flutterCommand @ArgumentList
            if ($LASTEXITCODE -ne 0) {
                $isPubGet = $ArgumentList.Count -ge 2 -and $ArgumentList[0] -eq "pub" -and $ArgumentList[1] -eq "get"
                if ($isPubGet) {
                    Write-PubGet403Hints
                }
                throw "Flutter failed (exit $LASTEXITCODE) in '$ProjectDirectory': flutter $($ArgumentList -join ' ')"
            }
        }
        finally {
            $ErrorActionPreference = $prevEap
        }
    }
    finally {
        Pop-Location
    }
}

Assert-PathExists -PathToCheck $flutterAppPath -Label "Flutter project folder"

$publishOutputDir = $defaultPublishDir
if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $publishOutputDir = (Resolve-ExistingOrNewDirectory -Path $OutputDirectory)
}

if (-not $SkipPackage) {
    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        Write-Host 'مسیر پوشه برای ذخیره فایل ZIP خروجی وب را وارد کنید:' -ForegroundColor Cyan
        $ZipOutputDirectory = Read-Host 'ZIP output folder path'
    }

    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        throw "Zip output directory is required when packaging. Re-run with -ZipOutputDirectory, or use -SkipPackage for build only."
    }
}

if (-not $SkipRestore) {
    Write-Host "Preparing Flutter dependencies..." -ForegroundColor Cyan
    if ($OfflinePubGet) {
        Write-Host "flutter pub get: --offline (pub cache only)" -ForegroundColor DarkGray
    }
    Invoke-FlutterPubGetWithMirrorRetry -ProjectDirectory $flutterAppPath
}

if (-not $SkipFlutterAnalyze) {
    Write-Host "Flutter analyze ($flutterAppPath) ..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("analyze", "--no-fatal-infos")
}

if (-not $SkipTests) {
    Write-Host "Flutter test ..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("test")
}

$appSettingsScript = Join-Path $flutterAppPath "scripts\copy_appsettings_to_flutter_outputs.ps1"
if (Test-Path -LiteralPath $appSettingsScript) {
    . $appSettingsScript
    Sync-AppSettingsToFlutterProjectAssets -RepoRoot $root -FlutterProjectPath $flutterAppPath
}

$normalizedWebBaseHref = Normalize-WebBaseHref -BaseHref $WebBaseHref
Write-Host "Building Flutter web [$flutterAppPath] release base-href=$normalizedWebBaseHref ..." -ForegroundColor Cyan
Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList (
    New-KaraviFlutterWebBuildArgumentList -BaseHref $normalizedWebBaseHref
)

$webRelease = Resolve-FlutterWebReleasePath -FlutterRoot $flutterAppPath
Invoke-KaraviFlutterWebNoCdnPostProcess -WebOutputDirectory $webRelease
Write-Host "Verified: Flutter web output has local canvaskit/ and zero CDN literals." -ForegroundColor Green

. (Join-Path $flutterAppPath "scripts\copy_appsettings_to_flutter_outputs.ps1")
Copy-AppSettingsToFlutterDeployOutputs -RepoRoot $root -FlutterProjectPath $flutterAppPath -IncludeWeb

$webRelease = Resolve-FlutterWebReleasePath -FlutterRoot $flutterAppPath
Copy-FlutterWebToPublish -SourceDir $webRelease -DestinationDir $publishOutputDir

if (-not $SkipPackage) {
    Invoke-FlutterWebZip -ZipDirectory $ZipOutputDirectory -WebSourceDir $publishOutputDir
}

if ($PackageOnly) {
    Write-Host "`nPackage-only mode: dev server was not started." -ForegroundColor Yellow
    exit 0
}

if (-not $SkipDevServers) {
    Start-FlutterWebDevTerminal `
        -WorkingDirectory $flutterAppPath `
        -FlutterExe $flutterCommand `
        -Device $DevServerDevice
}

Write-Host "`nDone." -ForegroundColor Yellow
Write-Host 'Tip: -SkipPackage skips ZIP; -SkipDevServers skips flutter run; default copy path is publish\flutter\web.' -ForegroundColor DarkYellow
Write-Host "Dev server: -DevServerDevice chrome|edge|web-server; default web ports 5320 (web-server) / 5321 (chrome|edge); see _dev-ports.ps1." -ForegroundColor DarkYellow
