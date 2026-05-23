# Shared helper: flutter build windows --release on hosts without plugin symlinks.
# Tries junctions first, then normal build, then elevated build (UAC).

function Test-WindowsSymlinkCreationAllowed {
    $testDir = Join-Path ([IO.Path]::GetTempPath()) "karavi_fl_symlink_test"
    try {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $target = Join-Path $testDir "target.txt"
        $link = Join-Path $testDir "link.txt"
        Set-Content -Path $target -Value "t" -NoNewline
        New-Item -ItemType SymbolicLink -Path $link -Target $target -Force -ErrorAction Stop | Out-Null
        return (Test-Path $link)
    }
    catch {
        return $false
    }
    finally {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Write-FlutterWindowsSymlinkFailureHints {
    param([switch]$LaunchDeveloperSettingsPage)

    Write-Host ""
    Write-Host "flutter build windows failed: Windows blocked symlink creation for plugins or pub get failed." -ForegroundColor Yellow
    Write-Host "  Option A: Settings -> System -> For developers -> Developer Mode ON, then restart the terminal." -ForegroundColor Yellow
    Write-Host "    start ms-settings:developers" -ForegroundColor White
    Write-Host "  Option B: Run this build from an elevated (Run as administrator) PowerShell." -ForegroundColor Yellow
    Write-Host "  Option C: Package without Windows exe: -SkipFlutterWindows on _build-all-projects.ps1" -ForegroundColor Yellow
    Write-Host "  Option D: If pub.dev returns exit 69, use -UseFlutterIoCnMirror on _build-all-projects.ps1" -ForegroundColor Yellow
    if ($LaunchDeveloperSettingsPage) {
        try {
            Start-Process "ms-settings:developers" -ErrorAction Stop
            Write-Host "  Opened Windows Developer settings." -ForegroundColor DarkCyan
        }
        catch {
            Write-Host "  Could not open settings automatically; use the command above." -ForegroundColor DarkYellow
        }
    }
}

function Invoke-EnsureFlutterWindowsPluginJunctions {
    param([Parameter(Mandatory = $true)][string]$FlutterProjectPath)

    $junctionScript = Join-Path $FlutterProjectPath "scripts\ensure_windows_plugin_junctions.ps1"
    if (-not (Test-Path -LiteralPath $junctionScript)) {
        return
    }

    & $junctionScript -ProjectRoot $FlutterProjectPath
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "ensure_windows_plugin_junctions.ps1 failed (exit $LASTEXITCODE)"
    }
}

function New-FlutterWindowsElevatedBuildScript {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string]$FlutterExecutable,
        [string]$PubHostedUrl = $env:PUB_HOSTED_URL,
        [string]$FlutterStorageBaseUrl = $env:FLUTTER_STORAGE_BASE_URL
    )

    $escapedDir = $ProjectDirectory.Replace("'", "''")
    $escapedFlutter = $FlutterExecutable.Replace("'", "''")
    if (-not $PubHostedUrl) { $PubHostedUrl = '' }
    if (-not $FlutterStorageBaseUrl) { $FlutterStorageBaseUrl = '' }
    $escapedPub = $PubHostedUrl.Replace("'", "''")
    $escapedStorage = $FlutterStorageBaseUrl.Replace("'", "''")

    return @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$escapedDir'
if ('$escapedPub') { `$env:PUB_HOSTED_URL = '$escapedPub' }
if ('$escapedStorage') { `$env:FLUTTER_STORAGE_BASE_URL = '$escapedStorage' }
& '$escapedFlutter' build windows --release
exit `$LASTEXITCODE
"@
}

function Invoke-FlutterWindowsReleaseBuild {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string]$FlutterExecutable,
        [switch]$LaunchDeveloperSettingsPage
    )

    Invoke-EnsureFlutterWindowsPluginJunctions -FlutterProjectPath $ProjectDirectory

    $buildOk = $false
    $buildLog = ""
    Push-Location $ProjectDirectory
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            # Junctions are the supported workaround when Developer Mode symlinks are blocked.
            # Always attempt a normal build first — do not skip when Test-WindowsSymlinkCreationAllowed is false.
            & $FlutterExecutable build windows --release
            if ($LASTEXITCODE -eq 0) {
                $buildOk = $true
            }
            elseif ($LASTEXITCODE -eq 69 -and -not $env:PUB_HOSTED_URL) {
                Write-Host "flutter build windows: exit 69 — retrying with pub.flutter-io.cn mirror ..." -ForegroundColor Yellow
                $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
                $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
                & $FlutterExecutable build windows --release
                if ($LASTEXITCODE -eq 0) {
                    $buildOk = $true
                }
                else {
                    $buildLog = "exit $LASTEXITCODE (after mirror retry)"
                }
            }
            else {
                $buildLog = "exit $LASTEXITCODE"
            }

            if (-not $buildOk) {
                Write-Host "flutter build windows: $buildLog — retrying elevated (UAC may appear) ..." -ForegroundColor Yellow
            }
        }
        finally {
            $ErrorActionPreference = $prevEap
        }
    }
    finally {
        Pop-Location
    }

    if (-not $buildOk) {
        $inner = New-FlutterWindowsElevatedBuildScript `
            -ProjectDirectory $ProjectDirectory `
            -FlutterExecutable $FlutterExecutable
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
        $proc = Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded) `
            -Verb RunAs -Wait -PassThru

        if ($proc.ExitCode -ne 0 -and -not $env:PUB_HOSTED_URL) {
            Write-Host "flutter build windows (elevated): exit $($proc.ExitCode) — retrying elevated with pub.flutter-io.cn mirror ..." -ForegroundColor Yellow
            $inner = New-FlutterWindowsElevatedBuildScript `
                -ProjectDirectory $ProjectDirectory `
                -FlutterExecutable $FlutterExecutable `
                -PubHostedUrl "https://pub.flutter-io.cn" `
                -FlutterStorageBaseUrl "https://storage.flutter-io.cn"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
            $proc = Start-Process -FilePath "powershell.exe" `
                -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded) `
                -Verb RunAs -Wait -PassThru
        }

        if ($proc.ExitCode -ne 0) {
            Write-FlutterWindowsSymlinkFailureHints -LaunchDeveloperSettingsPage:$LaunchDeveloperSettingsPage
            throw "Flutter failed (exit $($proc.ExitCode)) in '$ProjectDirectory': flutter build windows --release"
        }
    }

    $repoRoot = (Resolve-Path (Join-Path $ProjectDirectory "..\..")).Path
    $copyScript = Join-Path $ProjectDirectory "scripts\copy_appsettings_to_flutter_outputs.ps1"
    if (Test-Path -LiteralPath $copyScript) {
        . $copyScript
        Sync-AppSettingsToFlutterProjectAssets -RepoRoot $repoRoot -FlutterProjectPath $ProjectDirectory
        Copy-AppSettingsToFlutterDeployOutputs -RepoRoot $repoRoot -FlutterProjectPath $ProjectDirectory -IncludeWindows
    }
}
