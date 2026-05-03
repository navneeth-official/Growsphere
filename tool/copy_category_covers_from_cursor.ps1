# Copies your Gemini category PNGs into assets/images/categories/ as .jpg filenames
# (same paths as [PlantCatalogCategory.coverImageUrl] — Flutter decodes by content).
#
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool/copy_category_covers_from_cursor.ps1

$ErrorActionPreference = 'Stop'
$dst = Join-Path $PSScriptRoot '..\assets\images\categories' | Resolve-Path
$src = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-NavaneethKrishnan-G1-project-Hackathon-Project-growspehere-v1\assets'
if (-not (Test-Path -LiteralPath $src)) {
  Write-Host "Source not found: $src"
  exit 1
}
function Copy-ByPattern($pattern, $destJpgName) {
  $f = Get-ChildItem -LiteralPath $src -Filter $pattern | Select-Object -First 1
  if ($null -eq $f) { throw "No file matching $pattern under $src" }
  Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $dst $destJpgName) -Force
  Write-Host "OK $destJpgName <= $($f.Name)"
}
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-ByPattern '*99vfwy*' 'category_vegetables.jpg'
Copy-ByPattern '*cq79an*' 'category_flowers_herbs.jpg'
Copy-ByPattern '*ti8d53*' 'category_kharif.jpg'
Copy-ByPattern '*alze1aa*' 'category_rabi.jpg'
Copy-ByPattern '*c2srh0*' 'category_fruits.jpg'
Copy-Item (Join-Path $dst 'category_kharif.jpg') (Join-Path $dst 'category_all.jpg') -Force
Write-Host 'OK category_all.jpg (copy of kharif)'
