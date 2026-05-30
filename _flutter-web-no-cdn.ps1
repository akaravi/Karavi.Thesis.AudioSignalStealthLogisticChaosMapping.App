# Flutter web — no external CDN (repo law: .cursor/rules/no-external-cdn-assets.mdc).
# CanvasKit and other web resources must ship under build/web/, never gstatic.com at runtime.

function Get-KaraviFlutterWebNoCdnSwitch {
    return '--no-web-resources-cdn'
}

function New-KaraviFlutterWebBuildArgumentList {
    param(
        [Parameter(Mandatory = $true)][string]$BaseHref,
        [switch]$Debug
    )

    $normalized = $BaseHref.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) { $normalized = '/' }
    if (-not $normalized.EndsWith('/')) { $normalized = "$normalized/" }
    if (-not $normalized.StartsWith('/')) { $normalized = "/$normalized" }

    $args = @('build', 'web')
    if (-not $Debug) { $args += '--release' }
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
            "Rebuild with --no-web-resources-cdn so CanvasKit loads from ./canvaskit/, not gstatic.com."
        ) -join ' '
    }

    # Runtime HTML must not reference external script/stylesheet/font CDNs.
    $forbiddenHtmlPatterns = @(
        '<script[^>]+src\s*=\s*["'']https?://'
        '<link[^>]+href\s*=\s*["'']https?://[^"'']*(fonts\.googleapis\.com|gstatic\.com|cdn\.|jsdelivr|unpkg|cdnjs)'
        '@import\s+url\s*\(\s*["'']?https?://'
    )

    $htmlFiles = Get-ChildItem -Path $WebOutputDirectory -Recurse -File -Filter '*.html' -ErrorAction SilentlyContinue
    foreach ($file in $htmlFiles) {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($pattern in $forbiddenHtmlPatterns) {
            if ($content -match $pattern) {
                throw @(
                    "External CDN reference detected in HTML (repo rule).",
                    "Pattern '$pattern' in $($file.FullName).",
                    "Serve fonts/scripts/styles only from build/web/."
                ) -join ' '
            }
        }
    }
}
