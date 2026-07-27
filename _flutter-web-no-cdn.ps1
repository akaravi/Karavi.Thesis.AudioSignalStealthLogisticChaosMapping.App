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
    $args += '--tree-shake-icons'
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

function Remove-KaraviFlutterWebDebugArtifacts {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    if (-not (Test-Path -LiteralPath $WebOutputDirectory)) { return }

    $removedBytes = [int64]0
    $removedCount = 0

    function Remove-TrackedItem {
        param([string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) { return }
        $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($null -eq $item) { return }
        if ($item.PSIsContainer) {
            Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                $script:removedBytes += $_.Length
                $script:removedCount++
            }
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
        else {
            $script:removedBytes += $item.Length
            $script:removedCount++
            Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        }
    }

    # Source maps / DWARF-like symbol dumps (not needed at runtime).
    Get-ChildItem -Path $WebOutputDirectory -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Extension -eq '.map' -or
            $_.Name -like '*.js.map' -or
            $_.Name -like '*.symbols'
        } |
        ForEach-Object { Remove-TrackedItem -Path $_.FullName }

    # Default build is dart2js + CanvasKit. skwasm/wimp are for --wasm and are unused here.
    $ck = Join-Path $WebOutputDirectory 'canvaskit'
    if (Test-Path -LiteralPath $ck) {
        Get-ChildItem -Path $ck -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^(skwasm|wimp)' } |
            ForEach-Object { Remove-TrackedItem -Path $_.FullName }

        $chromium = Join-Path $ck 'chromium'
        if (Test-Path -LiteralPath $chromium) {
            Remove-TrackedItem -Path $chromium
        }
    }

    if ($removedCount -gt 0) {
        $mb = [math]::Round($removedBytes / 1MB, 2)
        Write-Host "Removed $removedCount web debug/extra artifact(s) (~$mb MB)." -ForegroundColor DarkCyan
    }
}

function Copy-KaraviFlutterWebBundledNotoFonts {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    # App text fonts ship via pubspec AssetManifest (subsetted TTF under assets/fonts).
    # Boot splash uses system-ui in web/index.html — no duplicate web/fonts/ tree.
    $projectRoot = Split-Path (Split-Path $WebOutputDirectory -Parent) -Parent
    $sourceRoot = Join-Path $projectRoot 'web\fonts'
    if (Test-Path -LiteralPath $sourceRoot) {
        Write-Host "Skipping obsolete web/fonts copy (use pubspec fonts only)." -ForegroundColor DarkGray
    }
}

function Invoke-KaraviFlutterWebNoCdnPostProcess {
    param(
        [Parameter(Mandatory = $true)][string]$WebOutputDirectory
    )

    Repair-KaraviFlutterWebOutputRemoveExternalCdnLiterals -WebOutputDirectory $WebOutputDirectory
    Copy-KaraviFlutterWebBundledNotoFonts -WebOutputDirectory $WebOutputDirectory
    Remove-KaraviFlutterWebDebugArtifacts -WebOutputDirectory $WebOutputDirectory
    Assert-KaraviFlutterWebOutputNoExternalCdn -WebOutputDirectory $WebOutputDirectory
}
