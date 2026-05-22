param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    [switch]$SkipRestore,
    [switch]$SkipStopRunningProjects,
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
    [switch]$SkipFlutterWindows,
    [switch]$SkipFlutterAndroid,
    [ValidateSet("Apk", "AppBundle", "Both")]
    [string]$AndroidArtifact = "Apk",
    [switch]$FatAndroidApk,
    [switch]$SkipDevServers,
    [string]$WebBaseHref = "/",
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$savedEnvPubHostedAtScriptStart = $env:PUB_HOSTED_URL
$userSuppliedMirrorViaParam = $UseFlutterIoCnMirror -or (-not [string]::IsNullOrWhiteSpace($PubHostedUrl))

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$solutionPath = Join-Path $root "src\audio_stegano_desktop\AudioStegano.sln"
$desktopProj = Join-Path $root "src\audio_stegano_desktop\src\AudioStegano.Desktop\AudioStegano.Desktop.csproj"
$desktopPath = Split-Path -Parent $desktopProj
$flutterAppPath = Join-Path $root "src\audio_stegano_app"

$runtime = "win-x64"
$publishRoot = Join-Path $root "publish\dotnet\$runtime"
$dotnetPublishOutput = Join-Path $publishRoot "AudioStegano.Desktop"
$androidPublishDir = Join-Path $root "publish\flutter\android"

$flutterAppSettingsScript = Join-Path $flutterAppPath "scripts\copy_appsettings_to_flutter_outputs.ps1"
if (Test-Path -LiteralPath $flutterAppSettingsScript) {
    . $flutterAppSettingsScript
    Sync-AppSettingsToFlutterProjectAssets -RepoRoot $root -FlutterProjectPath $flutterAppPath
}

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

function Stop-RunningProjectProcess {
    param(
        [Parameter(Mandatory = $true)][string]$ProcessName
    )

    $running = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if (-not $running) {
        return
    }

    foreach ($proc in $running) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Host "Stopped running process: $ProcessName (PID: $($proc.Id))" -ForegroundColor DarkYellow
        }
        catch {
            Write-Warning "Could not stop process '$ProcessName' (PID: $($proc.Id)): $($_.Exception.Message)"
        }
    }
}

function Start-ProjectTerminal {
    param(
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$RestartMessage
    )

    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("Set-Location '$WorkingDirectory'; $Command"))
    Start-Process powershell -ArgumentList "-NoExit", "-EncodedCommand", $encoded | Out-Null
    Write-Host $RestartMessage -ForegroundColor Green
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

function Invoke-CorePublish {
    param(
        [Parameter(Mandatory = $true)][string]$Configuration
    )

    Assert-PathExists -PathToCheck $desktopProj -Label "Desktop project file"
    if (-not (Test-Path $publishRoot)) {
        New-Item -ItemType Directory -Path $publishRoot -Force | Out-Null
    }

    if (Test-Path $dotnetPublishOutput) {
        Remove-Item -Recurse -Force $dotnetPublishOutput
    }

    if (-not $SkipStopRunningProjects) {
        Stop-RunningProjectProcess -ProcessName "AudioStegano.Desktop"
    }

    Write-Host "Publishing AudioStegano.Desktop ($Configuration, $runtime) ..." -ForegroundColor Cyan
    dotnet publish $desktopProj -c $Configuration -r $runtime --self-contained false -o $dotnetPublishOutput
    if ($LASTEXITCODE -ne 0) { throw "Publish failed for AudioStegano.Desktop" }

    Write-Host ""
    Write-Host "Publish output (.NET):" -ForegroundColor Green
    Write-Host "AudioStegano.Desktop -> $dotnetPublishOutput" -ForegroundColor Yellow
}

function Resolve-FlutterWindowsReleasePath {
    param(
        [Parameter(Mandatory = $true)][string]$FlutterRoot
    )

    $releaseDir = Join-Path $FlutterRoot "build\windows\x64\runner\Release"
    $exePath = Join-Path $releaseDir "audio_stegano_app.exe"
    if (-not (Test-Path $exePath)) {
        throw "Flutter Windows release output was not found. Expected '$exePath'. Run 'flutter build windows --release'."
    }

    return $releaseDir
}

function Resolve-FlutterWebReleasePath {
    param(
        [Parameter(Mandatory = $true)][string]$FlutterRoot
    )

    $releaseDir = Join-Path $FlutterRoot "build\web"
    $indexPath = Join-Path $releaseDir "index.html"
    if (-not (Test-Path $indexPath)) {
        throw "Flutter web release output was not found. Expected '$indexPath'. Run 'flutter build web --release'."
    }

    return $releaseDir
}

function Invoke-DeployZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipDirectory
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $resolvedZipDir = Resolve-ExistingOrNewDirectory -Path $ZipDirectory

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "KaraviThesis_AudioStegano_Build_$stamp.zip"
    $zipFullPath = Join-Path $resolvedZipDir $zipName

    $flutterWebRelease = Resolve-FlutterWebReleasePath -FlutterRoot $flutterAppPath
    if (-not $SkipFlutterWindows) {
        $flutterWindowsRelease = Resolve-FlutterWindowsReleasePath -FlutterRoot $flutterAppPath
    }

    $stageRoot = Join-Path $root "publish\deploy-staging"
    if (Test-Path $stageRoot) {
        Remove-Item -Recurse -Force $stageRoot
    }
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

    Write-Host "Staging deploy folder under $stageRoot ..." -ForegroundColor Cyan
    Copy-Item -Recurse -Force $dotnetPublishOutput (Join-Path $stageRoot "AudioStegano.Desktop")
    if (-not $SkipFlutterWindows) {
        Copy-Item -Recurse -Force $flutterWindowsRelease (Join-Path $stageRoot "audio_stegano_app_windows_release")
    }
    else {
        Write-Host "ZIP: skipped audio_stegano_app_windows_release (-SkipFlutterWindows)." -ForegroundColor DarkYellow
    }
    Copy-Item -Recurse -Force $flutterWebRelease (Join-Path $stageRoot "audio_stegano_app_web")

    if (-not $SkipFlutterAndroid) {
        if (Test-Path -LiteralPath $androidPublishDir) {
            $androidFiles = @(
                Get-ChildItem -Path $androidPublishDir -File -Filter "*.apk" -ErrorAction SilentlyContinue
                Get-ChildItem -Path $androidPublishDir -File -Filter "*.aab" -ErrorAction SilentlyContinue
            )
            if ($androidFiles.Count -gt 0) {
                $androidStage = Join-Path $stageRoot "audio_stegano_app_android"
                New-Item -ItemType Directory -Path $androidStage -Force | Out-Null
                foreach ($f in $androidFiles) {
                    Copy-Item -Force $f.FullName (Join-Path $androidStage $f.Name)
                }
                Write-Host "ZIP: included audio_stegano_app_android ($($androidFiles.Count) file(s))." -ForegroundColor DarkCyan
            }
            else {
                Write-Warning "ZIP: no APK/AAB in $androidPublishDir — Android folder omitted."
            }
        }
        else {
            Write-Warning "ZIP: Android publish folder not found: $androidPublishDir"
        }
    }
    else {
        Write-Host "ZIP: skipped audio_stegano_app_android (-SkipFlutterAndroid)." -ForegroundColor DarkYellow
    }

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
    Write-Host "Deploy ZIP created: $zipFullPath" -ForegroundColor Green
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

$flutterWindowsBuildHelper = Join-Path $flutterAppPath "scripts\invoke_flutter_windows_build.ps1"
if (-not (Test-Path -LiteralPath $flutterWindowsBuildHelper)) {
    throw "Flutter Windows build helper was not found: $flutterWindowsBuildHelper"
}
. $flutterWindowsBuildHelper

$flutterAndroidBuildHelper = Join-Path $flutterAppPath "scripts\flutter_android_build.ps1"
if (-not (Test-Path -LiteralPath $flutterAndroidBuildHelper)) {
    throw "Flutter Android build helper was not found: $flutterAndroidBuildHelper"
}
. $flutterAndroidBuildHelper

$flutterInvokeSb = {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )
    Invoke-FlutterInProject -ProjectDirectory $ProjectDirectory -ArgumentList $ArgumentList
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

Assert-PathExists -PathToCheck $solutionPath -Label "Solution file"
Assert-PathExists -PathToCheck $flutterAppPath -Label "Flutter project folder"

if (-not $SkipPackage) {
    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        if ($NonInteractive) {
            $ZipOutputDirectory = Join-Path $root "publish\github-release"
            Write-Host "Non-interactive: ZIP output -> $ZipOutputDirectory" -ForegroundColor DarkGray
        }
        else {
            Write-Host "مسیر پوشه برای ذخیره فایل ZIP خروجی استقرار را وارد کنید:" -ForegroundColor Cyan
            $ZipOutputDirectory = Read-Host "ZIP output folder path"
        }
    }

    if ([string]::IsNullOrWhiteSpace($ZipOutputDirectory)) {
        throw "Zip output directory is required when packaging. Re-run with a folder path or use -SkipPackage for local dev only."
    }

    if (-not $SkipRestore) {
        Write-Host "Preparing dependencies (package pipeline)..." -ForegroundColor Cyan
        dotnet restore $solutionPath
        if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed" }

        if ($OfflinePubGet) {
            Write-Host "flutter pub get: --offline (pub cache only)" -ForegroundColor DarkGray
        }
        Invoke-FlutterPubGetWithMirrorRetry -ProjectDirectory $flutterAppPath
    }

    Write-Host "Building AudioStegano.sln ($Configuration) ..." -ForegroundColor Cyan
    if (-not $SkipRestore) {
        dotnet build $solutionPath -c $Configuration --no-restore
    }
    else {
        dotnet build $solutionPath -c $Configuration
    }
    if ($LASTEXITCODE -ne 0) { throw "dotnet build failed" }

    if (-not $SkipTests) {
        Write-Host "Testing AudioStegano.sln ($Configuration) ..." -ForegroundColor Cyan
        dotnet test $solutionPath -c $Configuration --no-build
        if ($LASTEXITCODE -ne 0) { throw "dotnet test failed" }
    }

    Invoke-CorePublish -Configuration $Configuration

    if (-not $SkipFlutterAnalyze) {
        Write-Host "Flutter analyze ($flutterAppPath) ..." -ForegroundColor Cyan
        Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("analyze", "--no-fatal-infos")
    }

    if (-not $SkipTests) {
        Write-Host "Flutter test ..." -ForegroundColor Cyan
        Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @("test")
    }

    if (-not $SkipStopRunningProjects) {
        Stop-RunningProjectProcess -ProcessName "audio_stegano_app"
    }

    $normalizedWebBaseHref = $WebBaseHref.Trim()
    if ([string]::IsNullOrWhiteSpace($normalizedWebBaseHref)) {
        $normalizedWebBaseHref = "/"
    }
    if (-not $normalizedWebBaseHref.EndsWith("/")) {
        $normalizedWebBaseHref = "$normalizedWebBaseHref/"
    }
    if (-not $normalizedWebBaseHref.StartsWith("/")) {
        $normalizedWebBaseHref = "/$normalizedWebBaseHref"
    }
    Write-Host "Building Flutter web ($flutterAppPath, release, base-href=$normalizedWebBaseHref) ..." -ForegroundColor Cyan
    Invoke-FlutterInProject -ProjectDirectory $flutterAppPath -ArgumentList @(
        "build", "web", "--release", "--base-href=$normalizedWebBaseHref"
    )
    if (Test-Path -LiteralPath $flutterAppSettingsScript) {
        Copy-AppSettingsToFlutterDeployOutputs -RepoRoot $root -FlutterProjectPath $flutterAppPath -IncludeWeb
    }

    if (-not $SkipFlutterWindows) {
        Write-Host "Building Flutter Windows ($flutterAppPath, release) ..." -ForegroundColor Cyan
        Invoke-FlutterWindowsReleaseBuild `
            -ProjectDirectory $flutterAppPath `
            -FlutterExecutable $flutterCommand `
            -LaunchDeveloperSettingsPage:$OpenDeveloperSettings
        if (Test-Path -LiteralPath $flutterAppSettingsScript) {
            Copy-AppSettingsToFlutterDeployOutputs -RepoRoot $root -FlutterProjectPath $flutterAppPath -IncludeWindows
        }
    }
    else {
        Write-Host "Skipping Flutter Windows build (-SkipFlutterWindows)." -ForegroundColor Yellow
    }

    if (-not $SkipFlutterAndroid) {
        Write-Host "Building Flutter Android ($flutterAppPath, $AndroidArtifact) ..." -ForegroundColor Cyan
        $null = Invoke-FlutterAndroidReleaseBuild `
            -FlutterProjectPath $flutterAppPath `
            -FlutterExecutable $flutterCommand `
            -AndroidPublishDir $androidPublishDir `
            -AndroidArtifact $AndroidArtifact `
            -FatApk:$FatAndroidApk `
            -InvokeFlutterInProject $flutterInvokeSb
        Write-Host "Android publish: $androidPublishDir" -ForegroundColor Green
        if (Test-Path -LiteralPath $flutterAppSettingsScript) {
            Copy-AppSettingsToFlutterDeployOutputs `
                -RepoRoot $root `
                -FlutterProjectPath $flutterAppPath `
                -IncludeAndroidPublish `
                -AndroidPublishDir $androidPublishDir
        }
    }
    else {
        Write-Host "Skipping Flutter Android build (-SkipFlutterAndroid)." -ForegroundColor Yellow
    }

    if (Test-Path -LiteralPath $flutterAppSettingsScript) {
        Copy-AppSettingsToFlutterDeployOutputs -RepoRoot $root -FlutterProjectPath $flutterAppPath -IncludeLinux
    }

    Invoke-DeployZip -ZipDirectory $ZipOutputDirectory
}
elseif (-not $SkipRestore) {
    Write-Host "Preparing dependencies..." -ForegroundColor Cyan
    dotnet restore $solutionPath
    if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed" }

    if ($OfflinePubGet) {
        Write-Host "flutter pub get: --offline (pub cache only)" -ForegroundColor DarkGray
    }
    Invoke-FlutterPubGetWithMirrorRetry -ProjectDirectory $flutterAppPath
}

if ($PackageOnly) {
    Write-Host "`nPackage-only mode: dev servers were not started." -ForegroundColor Yellow
    exit 0
}

if (-not $SkipDevServers) {
    if (-not $SkipStopRunningProjects) {
        Stop-RunningProjectProcess -ProcessName "AudioStegano.Desktop"
        Stop-RunningProjectProcess -ProcessName "audio_stegano_app"
    }

    Start-ProjectTerminal `
        -WorkingDirectory $desktopPath `
        -Command "dotnet run --project `"$desktopProj`"" `
        -RestartMessage "Started: AudioStegano.Desktop (WPF) — dotnet run"

    Start-ProjectTerminal `
        -WorkingDirectory $flutterAppPath `
        -Command ("& `"$flutterCommand`" run -d windows") `
        -RestartMessage "Started: audio_stegano_app — flutter run -d windows"
}

Write-Host "`nDone." -ForegroundColor Yellow
Write-Host "Tip: -SkipPackage for deps-only / skip release ZIP; -PackageOnly ends before dev servers; -SkipDevServers to skip spawning terminals." -ForegroundColor DarkYellow
Write-Host "Android: default arm64 split APK (smaller); -FatAndroidApk for universal; -AndroidArtifact AppBundle|Both -SkipFlutterAndroid" -ForegroundColor DarkYellow
Write-Host "Pub get auto-retries with flutter-io.cn once on failure unless -DisableAutoMirrorRetry or mirror env/param already set." -ForegroundColor DarkYellow
