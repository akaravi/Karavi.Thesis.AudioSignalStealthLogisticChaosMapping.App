# Flutter web — no external CDN (repo law: .cursor/rules/no-external-cdn-assets.mdc).
# CanvasKit and other web resources must ship under build/web/; deploy output must contain zero CDN host literals.

function Get-KaraviFlutterWebNoCdnSwitch {
    return '--no-web-resources-cdn'
}

function Get-KaraviForbiddenCdnHostPatterns {
    return @(
        'fonts\.googleapis\.com'
        'gstatic\.com'
        'cdn\.jsdelivr\.net'
        'unpkg\.com'
        'cdnjs\.cloudflare\.com'
    )
}

function Get-KaraviFlutterWebDeployScanExtensions {
    return @('*.js', '*.html', '*.json', '*.css', '*.wasm', '*.map')
}

function New-KaraviFlutterWebBuildArgumentList {
    param(
        [Parameter(Mandatory = $true)][string]$BaseHref,
        [switch]$DebugBuild
    )

    $normalized = $BaseHref.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) { $normalized = '/' }
    if (-not $normalized.EndsWith('/')) { $normalized = "$normalized/" }
    if (-not $normalized.StartsWith('/')) { $normalized = "/$normalized" }

    $args = @('build', 'web')
    if (-not $DebugBuild) { $args += '--release' }
    $args += Get-KaraviFlutterWebNoCdnSwitch
    $args += "--base-href=$normalized"
    return $args
}

function New-KaraviFlutterWebRunArgumentList {
    param(
        [Parameter(Mandatory = $true)][string]$Device,
        [Parameter(Mandatory = $true)][int]$WebPort,
        [string]$WebHostname = '127.0.0.1'
    )

    return @(
        'run', '-d', $Device,
        "--web-port=$WebPort",
        "--web-hostname=$WebHostname",
        (Get-KaraviFlutterWebNoCdnSwitch)
    )
}

function Repair-KaraviFlutterWebOutputRemoveExternalCdnLiterals {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    if (-not (Test-Path -LiteralPath $WebOutputDirectory)) {
        throw "Flutter web output not found: $WebOutputDirectory"
    }

    $literalReplacements = [ordered]@{
        'https://www.gstatic.com/flutter-canvaskit' = 'canvaskit'
        'http://www.gstatic.com/flutter-canvaskit'  = 'canvaskit'
        'https://fonts.gstatic.com/s/'              = 'assets/fonts/'
        'http://fonts.gstatic.com/s/'               = 'assets/fonts/'
    }

    $extensions = Get-KaraviFlutterWebDeployScanExtensions
    $files = @()
    foreach ($ext in $extensions) {
        $files += Get-ChildItem -Path $WebOutputDirectory -Recurse -File -Filter $ext -ErrorAction SilentlyContinue
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $patchedCount = 0

    foreach ($file in $files) {
        $original = [System.IO.File]::ReadAllText($file.FullName)
        $updated = $original
        foreach ($entry in $literalReplacements.GetEnumerator()) {
            if ($updated.Contains($entry.Key)) {
                $updated = $updated.Replace($entry.Key, $entry.Value)
            }
        }

        if ($updated -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8NoBom)
            $patchedCount++
        }
    }

    # Stale HTML comments may still name CDN hosts; neutralize in deploy HTML only.
    $htmlFiles = Get-ChildItem -Path $WebOutputDirectory -Recurse -File -Filter '*.html' -ErrorAction SilentlyContinue
    foreach ($file in $htmlFiles) {
        $original = [System.IO.File]::ReadAllText($file.FullName)
        $updated = $original
        $updated = $updated.Replace('gstatic.com', 'external CDN')
        $updated = $updated.Replace('fonts.googleapis.com', 'external CDN')
        if ($updated -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8NoBom)
            $patchedCount++
        }
    }

    if ($patchedCount -gt 0) {
        Write-Host "Patched $patchedCount Flutter web file(s) to remove external CDN literals." -ForegroundColor DarkCyan
    }
}

function Assert-KaraviFlutterWebOutputNoExternalCdn {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    if (-not (Test-Path -LiteralPath $WebOutputDirectory)) {
        throw "Flutter web output not found: $WebOutputDirectory"
    }

    $canvaskitDir = Join-Path $WebOutputDirectory 'canvaskit'
    if (-not (Test-Path -LiteralPath $canvaskitDir)) {
        throw @(
            "Local canvaskit/ is missing under '$WebOutputDirectory'.",
            "Rebuild with: flutter build web --release --no-web-resources-cdn"
        ) -join ' '
    }

    $canvaskitJs = Join-Path $canvaskitDir 'canvaskit.js'
    $canvaskitWasm = Join-Path $canvaskitDir 'canvaskit.wasm'
    if (-not (Test-Path -LiteralPath $canvaskitJs) -or -not (Test-Path -LiteralPath $canvaskitWasm)) {
        throw "Local canvaskit bundle is incomplete under '$canvaskitDir' (expected canvaskit.js and canvaskit.wasm)."
    }

    $bootstrapPath = Join-Path $WebOutputDirectory 'flutter_bootstrap.js'
    if (-not (Test-Path -LiteralPath $bootstrapPath)) {
        throw "flutter_bootstrap.js not found under '$WebOutputDirectory'."
    }

    $bootstrapText = [System.IO.File]::ReadAllText($bootstrapPath)
    if ($bootstrapText -notmatch 'useLocalCanvasKit"\s*:\s*true' -and
        $bootstrapText -notmatch 'useLocalCanvasKit:\s*!0') {
        throw @(
            "flutter_bootstrap.js does not enable useLocalCanvasKit.",
            "Rebuild with --no-web-resources-cdn so CanvasKit loads from ./canvaskit/."
        ) -join ' '
    }

    $forbiddenPatterns = Get-KaraviForbiddenCdnHostPatterns
    $extensions = Get-KaraviFlutterWebDeployScanExtensions
    $files = @()
    foreach ($ext in $extensions) {
        $files += Get-ChildItem -Path $WebOutputDirectory -Recurse -File -Filter $ext -ErrorAction SilentlyContinue
    }

    foreach ($file in $files) {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($pattern in $forbiddenPatterns) {
            if ($content -match $pattern) {
                throw @(
                    "External CDN host detected in deploy output (repo rule: zero CDN).",
                    "Pattern '$pattern' in $($file.FullName).",
                    "Run Repair-KaraviFlutterWebOutputRemoveExternalCdnLiterals or rebuild with --no-web-resources-cdn."
                ) -join ' '
            }
        }
    }

    $forbiddenHtmlPatterns = @(
        '<script[^>]+src\s*=\s*["'']https?://'
        '<link[^>]+href\s*=\s*["'']https?://[^"'']*(fonts\.googleapis|gstatic|cdn\.|jsdelivr|unpkg|cdnjs)'
        '@import\s+url\s*\(\s*["'']?https?://'
    )

    $htmlFiles = Get-ChildItem -Path $WebOutputDirectory -Recurse -File -Filter '*.html' -ErrorAction SilentlyContinue
    foreach ($file in $htmlFiles) {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($pattern in $forbiddenHtmlPatterns) {
            if ($content -match $pattern) {
                throw @(
                    "External CDN reference detected in HTML (repo rule: zero CDN).",
                    "Pattern '$pattern' in $($file.FullName)."
                ) -join ' '
            }
        }
    }
}

function Copy-KaraviFlutterWebBundledNotoFonts {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    $projectRoot = Split-Path (Split-Path $WebOutputDirectory -Parent) -Parent
    $sourceRoot = Join-Path $projectRoot 'web\fonts'
    $destRoot = Join-Path $WebOutputDirectory 'assets\fonts'

    if (-not (Test-Path -LiteralPath $sourceRoot)) {
        Write-Warning "Bundled web fonts folder not found: $sourceRoot (CanvasKit fallback text may be invisible)."
        return
    }

    $copied = 0
    Get-ChildItem -Path $sourceRoot -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $destination = Join-Path $destRoot $relative
        $destinationDir = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
        $copied++
    }

    if ($copied -gt 0) {
        Write-Host "Copied $copied bundled font file(s) to assets/fonts/ for offline CanvasKit text." -ForegroundColor DarkCyan
    }
}

function Invoke-KaraviFlutterWebNoCdnPostProcess {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    Repair-KaraviFlutterWebOutputRemoveExternalCdnLiterals -WebOutputDirectory $WebOutputDirectory
    Copy-KaraviFlutterWebBundledNotoFonts -WebOutputDirectory $WebOutputDirectory
    Assert-KaraviFlutterWebOutputNoExternalCdn -WebOutputDirectory $WebOutputDirectory
}
