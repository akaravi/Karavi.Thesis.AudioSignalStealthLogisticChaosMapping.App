# Registers AudioStegano.Desktop in Explorer "Open with" for .wav / .mp3 / .mp4 (HKCU).
# Usage:
#   .\_register-windows-open-with.ps1
#   .\_register-windows-open-with.ps1 -Unregister
param(
    [switch]$Unregister,
    [string]$ExePath
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

if (-not $ExePath) {
    $publish = Join-Path $repoRoot 'publish\deploy-staging\AudioStegano.Desktop\AudioStegano.Desktop.exe'
    $debug = Join-Path $repoRoot 'src\audio_stegano_desktop\src\AudioStegano.Desktop\bin\Debug\net10.0-windows\AudioStegano.Desktop.exe'
    $release = Join-Path $repoRoot 'src\audio_stegano_desktop\src\AudioStegano.Desktop\bin\Release\net10.0-windows\AudioStegano.Desktop.exe'
    if (Test-Path $publish) { $ExePath = $publish }
    elseif (Test-Path $release) { $ExePath = $release }
    elseif (Test-Path $debug) { $ExePath = $debug }
    else {
        Write-Error "AudioStegano.Desktop.exe not found. Build first or pass -ExePath."
    }
}

$ExePath = (Resolve-Path $ExePath).Path
$progId = 'Karavi.AudioStegano.AudioFile'
$displayName = 'نهان‌نگاری پیام در صوت'
$extensions = @('.wav', '.mp3', '.mp4')

function Remove-KeySafe($path) {
    if (Test-Path "Registry::HKEY_CURRENT_USER\$path") {
        Remove-Item -Path "Registry::HKEY_CURRENT_USER\$path" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($Unregister) {
    Remove-KeySafe "Software\Classes\$progId"
    foreach ($ext in $extensions) {
        $ow = "Software\Classes\$ext\OpenWithProgids"
        if (Test-Path "Registry::HKEY_CURRENT_USER\$ow") {
            Remove-ItemProperty -Path "Registry::HKEY_CURRENT_USER\$ow" -Name $progId -ErrorAction SilentlyContinue
        }
    }
    Remove-KeySafe 'Software\Clients\Media\AudioStegano'
    if (Test-Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications') {
        Remove-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications' -Name 'AudioStegano.Desktop' -ErrorAction SilentlyContinue
    }
    Write-Host "Unregistered Open-with for: $($extensions -join ', ')"
    exit 0
}

$quoted = "`"$ExePath`""
New-Item -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$progId" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$progId" -Name '(default)' -Value $displayName
New-Item -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$progId\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$progId\DefaultIcon" -Name '(default)' -Value "$quoted,0"
New-Item -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$progId\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$progId\shell\open\command" -Name '(default)' -Value "$quoted `"%1`""

$exeName = [IO.Path]::GetFileName($ExePath)
New-Item -Path "Registry::HKEY_CURRENT_USER\Software\Classes\Applications\$exeName\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Classes\Applications\$exeName\shell\open\command" -Name '(default)' -Value "$quoted `"%1`""

foreach ($ext in $extensions) {
    New-Item -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$ext\OpenWithProgids" -Force | Out-Null
    New-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Classes\$ext\OpenWithProgids" -Name $progId -PropertyType None -Force | Out-Null
}

New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano' -Force | Out-Null
Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano' -Name '(default)' -Value $displayName
New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano\Capabilities' -Force | Out-Null
foreach ($ext in $extensions) {
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano\Capabilities' -Name $ext -Value $progId
}
New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications' -Force | Out-Null
Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications' -Name 'AudioStegano.Desktop' -Value 'Software\Clients\Media\AudioStegano'

Write-Host "Registered Open-with:"
Write-Host "  EXE: $ExePath"
Write-Host "  Extensions: $($extensions -join ', ')"
