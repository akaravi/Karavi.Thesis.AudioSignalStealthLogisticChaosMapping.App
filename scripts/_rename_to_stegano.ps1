# Replace Steg -> Stegano (and steg -> stegano) in all source files.
# Only when not followed by a/e/o/y (case-sensitive), to preserve
# Stegano / Steganography / Stego (carrier-related code term).
#
# Excludes build artifacts and history files. Designed to be re-runnable.

[CmdletBinding()]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Write-Host "Repo: $repoRoot"

$excludeDirSegments = @(
    '\.git', 'bin', 'obj', 'build', '\.dart_tool', '\.gradle', '\.vs', '\.idea',
    'node_modules', 'publish', 'logs', 'memo', 'flutter_inappwebview', '\.flutter-plugins-dependencies'
)
$excludeRegex = ($excludeDirSegments | ForEach-Object { "[\\/]$_[\\/]" }) -join '|'

$excludeFiles = @(
    (Join-Path $repoRoot 'Cursor.01.plan.md'),
    (Join-Path $repoRoot 'readmehistory.md'),
    (Join-Path $repoRoot 'scripts\_rename_steg_to_stegano.ps1')
)

$includeExtensions = @(
    '.cs', '.dart', '.xaml', '.xml', '.json', '.yml', '.yaml', '.md', '.ps1',
    '.sh', '.sln', '.csproj', '.props', '.targets', '.gradle', '.kts',
    '.html', '.css', '.scss', '.js', '.ts', '.m', '.txt', '.rc', '.cpp',
    '.cc', '.h', '.hpp', '.cmake', '.mdc', '.lock', '.toml', '.ini',
    '.conf', '.config', '.plist', '.bat', '.gitignore'
)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$rxUpperSteg = [regex]'Steg(?![aeoyAEOY])'
$rxLowerSteg = [regex]'steg(?![aeoy])'

$files = Get-ChildItem -Path $repoRoot -Recurse -File | Where-Object {
    $p = $_.FullName
    if ($p -match $excludeRegex) { return $false }
    if ($excludeFiles -contains $p) { return $false }
    $ext = $_.Extension.ToLowerInvariant()
    if ($_.Name -ieq '.gitignore') { return $true }
    return ($includeExtensions -contains $ext)
}

Write-Host "Candidate files: $($files.Count)"

$changedCount = 0
$report = New-Object System.Collections.Generic.List[string]

foreach ($f in $files) {
    try {
        $raw = [System.IO.File]::ReadAllText($f.FullName, [System.Text.UTF8Encoding]::new($false))
    } catch {
        Write-Warning "skip read: $($f.FullName) — $_"
        continue
    }
    if ([string]::IsNullOrEmpty($raw)) { continue }
    $new = $rxUpperSteg.Replace($raw, 'Stegano')
    $new = $rxLowerSteg.Replace($new, 'stegano')
    if ($new -ne $raw) {
        $changedCount++
        $rel = $f.FullName.Substring($repoRoot.Length + 1)
        $report.Add($rel) | Out-Null
        if (-not $WhatIf) {
            [System.IO.File]::WriteAllText($f.FullName, $new, $utf8NoBom)
        }
    }
}

Write-Host "Changed files: $changedCount"
if ($changedCount -gt 0) {
    $report | ForEach-Object { Write-Host "  $_" }
}
