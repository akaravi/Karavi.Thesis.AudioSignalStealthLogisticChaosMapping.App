# Registers Flutter Windows app in Explorer "Open with" for .wav / .mp3 / .mp4 (HKCU).
# Usage:
#   .\_register-flutter-windows-open-with.ps1
#   .\_register-flutter-windows-open-with.ps1 -Unregister
param(
    [switch]$Unregister,
    [string]$ExePath
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

if (-not $ExePath) {
    $publish = Join-Path $repoRoot 'publish\deploy-staging\audio_stegano_app_windows_release\audio_stegano_app.exe'
    $release = Join-Path $repoRoot 'src\audio_stegano_app\build\windows\x64\runner\Release\audio_stegano_app.exe'
    if (Test-Path $publish) { $ExePath = $publish }
    elseif (Test-Path $release) { $ExePath = $release }
    else {
        Write-Error "audio_stegano_app.exe not found. Run 'flutter build windows --release' or pass -ExePath."
    }
}

$ExePath = (Resolve-Path $ExePath).Path
$progId = 'Karavi.AudioStegano.Flutter.AudioFile'
$displayName = 'نهان‌نگاری پیام در صوت (Flutter)'
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
    Remove-KeySafe 'Software\Clients\Media\AudioStegano.Flutter'
    if (Test-Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications') {
        Remove-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications' -Name 'AudioStegano.Flutter' -ErrorAction SilentlyContinue
    }
    Write-Host "Unregistered Flutter Open-with for: $($extensions -join ', ')"
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

New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano.Flutter' -Force | Out-Null
Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano.Flutter' -Name '(default)' -Value $displayName
New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano.Flutter\Capabilities' -Force | Out-Null
foreach ($ext in $extensions) {
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Clients\Media\AudioStegano.Flutter\Capabilities' -Name $ext -Value $progId
}
New-Item -Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications' -Force | Out-Null
Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\RegisteredApplications' -Name 'AudioStegano.Flutter' -Value 'Software\Clients\Media\AudioStegano.Flutter'

Write-Host "Registered Flutter Open-with:"
Write-Host "  EXE: $ExePath"
Write-Host "  Extensions: $($extensions -join ', ')"
