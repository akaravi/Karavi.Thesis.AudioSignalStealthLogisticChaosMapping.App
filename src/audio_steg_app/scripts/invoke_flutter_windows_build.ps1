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
    Write-Host "flutter build windows failed: Windows blocked symlink creation for plugins." -ForegroundColor Yellow
    Write-Host "  Option A: Settings -> System -> For developers -> Developer Mode ON, then restart the terminal." -ForegroundColor Yellow
    Write-Host "    start ms-settings:developers" -ForegroundColor White
    Write-Host "  Option B: Run this build from an elevated (Run as administrator) PowerShell." -ForegroundColor Yellow
    Write-Host "  Option C: Package without Windows exe: -SkipFlutterWindows on _build-all-projects.ps1" -ForegroundColor Yellow
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
    if ($LASTEXITCODE -ne 0) {
        throw "ensure_windows_plugin_junctions.ps1 failed (exit $LASTEXITCODE)"
    }
}

function Invoke-FlutterWindowsReleaseBuild {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDirectory,
        [Parameter(Mandatory = $true)][string]$FlutterExecutable,
        [switch]$LaunchDeveloperSettingsPage
    )

    Invoke-EnsureFlutterWindowsPluginJunctions -FlutterProjectPath $ProjectDirectory

    $buildOk = $false
    Push-Location $ProjectDirectory
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            if (Test-WindowsSymlinkCreationAllowed) {
                & $FlutterExecutable build windows --release
                if ($LASTEXITCODE -eq 0) {
                    $buildOk = $true
                }
                else {
                    $log = "exit $LASTEXITCODE"
                }
            }
            else {
                $log = "symlink test failed"
            }

            if (-not $buildOk) {
                Write-Host "flutter build windows: $log — retrying elevated (UAC may appear) ..." -ForegroundColor Yellow
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
        $escapedDir = $ProjectDirectory.Replace("'", "''")
        $escapedFlutter = $FlutterExecutable.Replace("'", "''")
        $inner = @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$escapedDir'
& '$escapedFlutter' build windows --release
exit `$LASTEXITCODE
"@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
        $proc = Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded) `
            -Verb RunAs -Wait -PassThru

        if ($proc.ExitCode -ne 0) {
            Write-FlutterWindowsSymlinkFailureHints -LaunchDeveloperSettingsPage:$LaunchDeveloperSettingsPage
            throw "Flutter failed (exit $($proc.ExitCode)) in '$ProjectDirectory': flutter build windows --release"
        }
    }

    $repoRoot = (Resolve-Path (Join-Path $ProjectDirectory "..\..")).Path
    $copyScript = Join-Path $ProjectDirectory "scripts\copy_appsettings_to_flutter_outputs.ps1"
    if (Test-Path -LiteralPath $copyScript) {
        . $copyScript
        Copy-AppSettingsToFlutterDeployOutputs -RepoRoot $repoRoot -FlutterProjectPath $ProjectDirectory -IncludeWindows
    }
}
