# Android release signing — official publish keystore (repo law: .cursor/rules/android-release-signing.mdc).
# Passwords: E:\BANK Android Key publish\key_password.txt (never commit).

$script:KaraviAndroidPublishKeyDirectoryDefault = 'E:\BANK Android Key publish'
$script:KaraviAndroidPublishKeystoreFileName = 'key.jks'
$script:KaraviAndroidPublishPasswordFileName = 'key_password.txt'
$script:KaraviAndroidPublishBundleSignerFileName = 'bundlesigner-0.1.13.jar'
$script:KaraviAndroidLegacyUploadKeystoreFileName = 'upload-keystore.jks'

function Get-KaraviAndroidPublishKeyDirectory {
    $dir = $env:KARAVI_ANDROID_PUBLISH_KEY_DIR
    if ([string]::IsNullOrWhiteSpace($dir)) {
        $dir = $script:KaraviAndroidPublishKeyDirectoryDefault
    }
    return $dir.TrimEnd('\', '/')
}

function Get-KaraviAndroidPublishKeystorePath {
    return (Join-Path (Get-KaraviAndroidPublishKeyDirectory) $script:KaraviAndroidPublishKeystoreFileName)
}

function Get-KaraviAndroidPublishPasswordFilePath {
    return (Join-Path (Get-KaraviAndroidPublishKeyDirectory) $script:KaraviAndroidPublishPasswordFileName)
}

function Get-KaraviAndroidPublishBundleSignerJarPath {
    return (Join-Path (Get-KaraviAndroidPublishKeyDirectory) $script:KaraviAndroidPublishBundleSignerFileName)
}

function Read-KaraviAndroidPublishPasswordFile {
    param(
        [Parameter(Mandatory = $true)][string]$PasswordFilePath
    )

    if (-not (Test-Path -LiteralPath $PasswordFilePath)) {
        throw "Android publish password file not found: $PasswordFilePath"
    }

    $lines = @(Get-Content -LiteralPath $PasswordFilePath -ErrorAction Stop)
    $props = @{}
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -match '^\s*([^=]+?)\s*=\s*(.+?)\s*$') {
            $props[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    $storePassword = $props['storePassword']
    $keyPassword = $props['keyPassword']
    $keyAlias = $props['keyAlias']

    if ([string]::IsNullOrWhiteSpace($storePassword) -and $lines.Count -ge 1) {
        $storePassword = $lines[0].Trim()
    }
    if ([string]::IsNullOrWhiteSpace($keyPassword) -and $lines.Count -ge 2) {
        $keyPassword = $lines[1].Trim()
    }
    if ([string]::IsNullOrWhiteSpace($keyPassword) -and -not [string]::IsNullOrWhiteSpace($storePassword)) {
        $keyPassword = $storePassword
    }

    if ([string]::IsNullOrWhiteSpace($storePassword) -or [string]::IsNullOrWhiteSpace($keyPassword)) {
        throw "Password file must contain storePassword and keyPassword (lines 1–2 or key=value): $PasswordFilePath"
    }

    return [pscustomobject]@{
        StorePassword = $storePassword
        KeyPassword   = $keyPassword
        KeyAlias      = $keyAlias
    }
}

function Get-KaraviAndroidPublishKeyAliasFromKeystore {
    param(
        [Parameter(Mandatory = $true)][string]$KeystorePath,
        [Parameter(Mandatory = $true)][string]$StorePassword
    )

    $keytool = Get-Command keytool -ErrorAction SilentlyContinue
    if (-not $keytool) {
        throw "keytool not found on PATH. Install JDK and set JAVA_HOME to resolve keyAlias from $KeystorePath."
    }

    $output = & $keytool.Source -list -v -keystore $KeystorePath -storepass $StorePassword 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "keytool -list failed for publish keystore. Check key_password.txt line 1 (store password)."
    }

    foreach ($line in $output) {
        if ($line -match '^\s*Alias name:\s*(.+?)\s*$') {
            return $Matches[1].Trim()
        }
    }

    foreach ($line in $output) {
        if ($line -match '^\s*([^\s,]+(?:\s+[^\s,]+)*),\s*.+,\s*PrivateKeyEntry') {
            return $Matches[1].Trim()
        }
    }

    throw "Could not read alias from keystore: $KeystorePath"
}

function Sync-KaraviAndroidKeyProperties {
    param(
        [Parameter(Mandatory = $true)][string]$AndroidRoot,
        [string]$KeyPropertiesPath = "",
        [switch]$Force
    )

    $publishKeystore = Get-KaraviAndroidPublishKeystorePath
    if (-not (Test-Path -LiteralPath $publishKeystore)) {
        throw @(
            "Official publish keystore not found: $publishKeystore",
            "Repo law: Android release builds must use E:\BANK Android Key publish\key.jks"
        ) -join ' '
    }

    if ([string]::IsNullOrWhiteSpace($KeyPropertiesPath)) {
        $KeyPropertiesPath = Join-Path $AndroidRoot 'key.properties'
    }

    if ((Test-Path -LiteralPath $KeyPropertiesPath) -and -not $Force) {
        return $KeyPropertiesPath
    }

    $passwordFile = Get-KaraviAndroidPublishPasswordFilePath
    $creds = Read-KaraviAndroidPublishPasswordFile -PasswordFilePath $passwordFile

    $keyAlias = $creds.KeyAlias
    if ([string]::IsNullOrWhiteSpace($keyAlias)) {
        $keyAlias = $env:KARAVI_ANDROID_KEY_ALIAS
    }
    if ([string]::IsNullOrWhiteSpace($keyAlias)) {
        $keyAlias = Get-KaraviAndroidPublishKeyAliasFromKeystore -KeystorePath $publishKeystore -StorePassword $creds.StorePassword
    }

    $storeFileGradle = ($publishKeystore -replace '\\', '/')
    $content = @(
        "# Auto-generated by _android-release-signing.ps1 — do not commit."
        "# Official publish keystore (repo law: .cursor/rules/android-release-signing.mdc)"
        "storeFile=$storeFileGradle"
        "storePassword=$($creds.StorePassword)"
        "keyPassword=$($creds.KeyPassword)"
        "keyAlias=$keyAlias"
        ""
    ) -join [Environment]::NewLine

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($KeyPropertiesPath, $content, $utf8NoBom)
    Write-Host "Wrote $KeyPropertiesPath from E:\BANK Android Key publish (passwords from key_password.txt)." -ForegroundColor DarkCyan
    return $KeyPropertiesPath
}

function Read-KaraviAndroidKeyPropertiesFile {
    param([Parameter(Mandatory = $true)][string]$KeyPropertiesPath)

    if (-not (Test-Path -LiteralPath $KeyPropertiesPath)) {
        return $null
    }

    $props = @{}
    foreach ($line in Get-Content -LiteralPath $KeyPropertiesPath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -match '^\s*([^=]+?)\s*=\s*(.+?)\s*$') {
            $props[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    return $props
}

function Test-KaraviAndroidReleaseSigningUsesOfficialPublishKey {
    param(
        [Parameter(Mandatory = $true)][string]$AndroidRoot,
        [string]$KeyPropertiesPath = ""
    )

    if ([string]::IsNullOrWhiteSpace($KeyPropertiesPath)) {
        $KeyPropertiesPath = Join-Path $AndroidRoot 'key.properties'
    }

    $props = Read-KaraviAndroidKeyPropertiesFile -KeyPropertiesPath $KeyPropertiesPath
    if (-not $props -or -not $props.ContainsKey('storeFile')) {
        return $false
    }

    $storeFile = $props['storeFile']
    $resolvedStore = if ([System.IO.Path]::IsPathRooted($storeFile)) {
        $storeFile
    }
    else {
        Join-Path $AndroidRoot $storeFile
    }

    try {
        $official = (Resolve-Path -LiteralPath (Get-KaraviAndroidPublishKeystorePath)).Path
        $configured = (Resolve-Path -LiteralPath $resolvedStore).Path
        return ($official -eq $configured)
    }
    catch {
        return $false
    }
}

function Assert-KaraviAndroidReleaseSigningConfigured {
    param(
        [Parameter(Mandatory = $true)][string]$AndroidRoot,
        [string]$KeyPropertiesPath = ""
    )

    $publishDir = Get-KaraviAndroidPublishKeyDirectory
    $publishKeystore = Get-KaraviAndroidPublishKeystorePath
    $passwordFile = Get-KaraviAndroidPublishPasswordFilePath

    if (-not (Test-Path -LiteralPath $publishDir)) {
        throw "Android publish key folder not found: $publishDir"
    }
    if (-not (Test-Path -LiteralPath $publishKeystore)) {
        throw "Official publish keystore not found: $publishKeystore"
    }
    if (-not (Test-Path -LiteralPath $passwordFile)) {
        throw "Publish password file not found: $passwordFile"
    }

    if ([string]::IsNullOrWhiteSpace($KeyPropertiesPath)) {
        $KeyPropertiesPath = Join-Path $AndroidRoot 'key.properties'
    }

    if (-not (Test-Path -LiteralPath $KeyPropertiesPath)) {
        Sync-KaraviAndroidKeyProperties -AndroidRoot $AndroidRoot -KeyPropertiesPath $KeyPropertiesPath
    }

    $legacyUpload = Join-Path $AndroidRoot $script:KaraviAndroidLegacyUploadKeystoreFileName
    $props = Read-KaraviAndroidKeyPropertiesFile -KeyPropertiesPath $KeyPropertiesPath
    if ($props -and $props['storeFile']) {
        $sf = $props['storeFile'] -replace '/', '\'
        if ($sf -eq $script:KaraviAndroidLegacyUploadKeystoreFileName -or $sf.EndsWith("\$($script:KaraviAndroidLegacyUploadKeystoreFileName)")) {
            throw @(
                "Release signing must not use android/upload-keystore.jks.",
                "Use official keystore: $publishKeystore",
                "Run: Sync-KaraviAndroidKeyProperties -AndroidRoot '$AndroidRoot' -Force"
            ) -join ' '
        }
    }

    if (-not (Test-KaraviAndroidReleaseSigningUsesOfficialPublishKey -AndroidRoot $AndroidRoot -KeyPropertiesPath $KeyPropertiesPath)) {
        throw @(
            "key.properties does not point to the official publish keystore.",
            "Expected storeFile: $publishKeystore",
            "Run: Sync-KaraviAndroidKeyProperties -AndroidRoot '$AndroidRoot' -Force"
        ) -join ' '
    }

    foreach ($required in @('storePassword', 'keyPassword', 'keyAlias', 'storeFile')) {
        if (-not $props -or [string]::IsNullOrWhiteSpace($props[$required])) {
            throw "key.properties missing '$required'. Re-run Sync-KaraviAndroidKeyProperties -Force."
        }
    }
}
