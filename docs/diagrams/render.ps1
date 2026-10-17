$ErrorActionPreference = 'Stop'
# Regenerate the C4 SVGs used by docs/architecture/c4-core.md.
# Requires Java 11+ and network access on first run (the PlantUML jar is downloaded once).

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$vendor = Join-Path $root 'vendor'
$src = Join-Path $root 'src'
$out = Join-Path $root '..\public\diagrams'
$jar = Join-Path $vendor 'plantuml.jar'

if (-not (Test-Path $jar)) {
    Write-Host 'Downloading plantuml.jar ...'
    $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/plantuml/plantuml/releases/latest' -Headers @{ 'User-Agent' = 'dsh' }
    $ver = $rel.tag_name.TrimStart('v')
    Invoke-WebRequest -Uri "https://github.com/plantuml/plantuml/releases/download/$($rel.tag_name)/plantuml-$ver.jar" -OutFile $jar -UseBasicParsing
}

New-Item -ItemType Directory -Force -Path $out | Out-Null
Push-Location $src
try {
    java -jar $jar -tsvg -o (Resolve-Path $out).Path *.puml
    if ($LASTEXITCODE -ne 0) { throw "PlantUML failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Host "Rendered:"
Get-ChildItem $out -Filter *.svg | ForEach-Object { "  " + $_.Name }
