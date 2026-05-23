# Creates directory junctions for Flutter Windows plugins when Developer Mode
# symlinks are unavailable. Junctions do not require elevated Developer Mode.
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$depsFile = Join-Path $ProjectRoot '.flutter-plugins-dependencies'
if (-not (Test-Path $depsFile)) {
    Write-Error "Run 'flutter pub get' in $ProjectRoot first."
    exit 1
}

$deps = Get-Content $depsFile -Raw | ConvertFrom-Json
$linkRoot = Join-Path $ProjectRoot 'windows\flutter\ephemeral\.plugin_symlinks'
New-Item -ItemType Directory -Force -Path $linkRoot | Out-Null

foreach ($plugin in $deps.plugins.windows) {
    $name = $plugin.name
    $src = $plugin.path -replace '\\\\', '\'
    $dest = Join-Path $linkRoot $name
    if (Test-Path $dest) {
        $item = Get-Item $dest -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            continue
        }
        Remove-Item $dest -Recurse -Force
    }
    cmd /c mklink /J "`"$dest`"" "`"$src`"" | Out-Null
    if (-not (Test-Path $dest)) {
        Write-Error "Failed to create junction: $name -> $src"
        exit 1
    }
    Write-Host "Junction OK: $name"
}

Write-Host "Plugin junctions ready at $linkRoot"
exit 0
