# Optional: refresh category hero images from your Downloads bundle (PNG).
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool/copy_category_covers_from_downloads.ps1

$ErrorActionPreference = 'Stop'
$src = 'C:\Users\NavaneethKrishnan(G1\Downloads\agricultural_images_bundle'
$dst = Join-Path $PSScriptRoot '..\assets\images\categories' | Resolve-Path
if (-not (Test-Path -LiteralPath $src)) { throw "Missing folder: $src" }
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Remove-Item (Join-Path $dst '*') -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $src 'Vegetables.png') (Join-Path $dst 'category_vegetables.png') -Force
Copy-Item (Join-Path $src 'Fruits.png') (Join-Path $dst 'category_fruits.png') -Force
Copy-Item (Join-Path $src 'Kharif.png') (Join-Path $dst 'category_kharif.png') -Force
Copy-Item (Join-Path $src 'Rabi.png') (Join-Path $dst 'category_rabi.png') -Force
Copy-Item (Join-Path $src 'Herbs and Flowers.png') (Join-Path $dst 'category_flowers_herbs.png') -Force
Copy-Item (Join-Path $src 'Kharif.png') (Join-Path $dst 'category_all.png') -Force
Write-Host 'Done. category_all.png is a copy of Kharif.png (bundle has no All file).'
