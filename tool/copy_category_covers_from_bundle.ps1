# Optional: refresh category PNGs from your Downloads bundle into the app.
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool/copy_category_covers_from_bundle.ps1

$ErrorActionPreference = 'Stop'
$src = 'C:\Users\NavaneethKrishnan(G1\Downloads\agricultural_images_bundle'
$dst = Join-Path $PSScriptRoot '..\assets\images\categories' | Resolve-Path
if (-not (Test-Path -LiteralPath $src)) { throw "Missing folder: $src" }
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item (Join-Path $src 'vegetables.png') (Join-Path $dst 'vegetables.png') -Force
Copy-Item (Join-Path $src 'fruits.png') (Join-Path $dst 'fruits.png') -Force
Copy-Item (Join-Path $src 'kharif_crops.png') (Join-Path $dst 'kharif_crops.png') -Force
Copy-Item (Join-Path $src 'rabi_crops.png') (Join-Path $dst 'rabi_crops.png') -Force
Copy-Item (Join-Path $src 'flowers_herbs.png') (Join-Path $dst 'flowers_herbs.png') -Force
Copy-Item (Join-Path $src 'vegetables.png') (Join-Path $dst 'all_crops.png') -Force
Write-Host "Copied category PNGs into $dst"
