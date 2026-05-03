# Pulls your hand-crop photos INTO the Flutter app (assets/images/crops/hands/*.png).
#
# WHERE YOUR IMAGES ACTUALLY ARE
#   Cursor saves chat uploads under your user folder, NOT inside growspehere_v1:
#     %USERPROFILE%\.cursor\projects\<cursor-project-slug>\assets\
#   Files look like: c__Users_...workspaceStorage_..._images_image-<uuid>.png
#   They stay there until this script copies them into the repo's hands/ folder.
#   On Windows, Cursor files sometimes fail Copy-Item/Test-Path; this script uses robocopy first.
#
# RUN (from growspehere_v1 repo root):
#   powershell -ExecutionPolicy Bypass -File tool/sync_hand_crop_images.ps1
#
# Optional: use another Cursor project folder or a manual folder:
#   powershell -ExecutionPolicy Bypass -File tool/sync_hand_crop_images.ps1 -CursorAssets "D:\path\to\assets"
#   powershell -ExecutionPolicy Bypass -File tool/sync_hand_crop_images.ps1 -Source "C:\path\to\Growsphere_hand_crops"
#
# After a good copy: flutter clean && flutter pub get, then uninstall app on device and reinstall.

param(
  [string]$Source = '',
  [string]$CursorAssets = ''
)

$ErrorActionPreference = 'Stop'
$dest = (Join-Path $PSScriptRoot '..\assets\images\crops\hands' | Resolve-Path).Path

# UUID suffixes (…_images_image-<uuid>.png) in chat upload order -> catalog plant id
# Order: chilli, tomato, brinjal, cucumber, french beans, lettuce, pumpkin, strawberries,
#        banana, mangoes, citrus, wheat, green peas, garlic, onions, potato, carrot, radish, spinach
# Batch 2 (chat order): rice, maize, soyabean, ground nut, okra, bottle gourd -> ids soybean, groundnut, bottle_gourd
# Batch 3: rose, marigold, sunflower, mint, basil, coriander
$cursorMap = [ordered]@{
  'c72c1349-f3fb-4abe-a5e9-66fb55c68b2b' = 'chilli'
  '3de4dd21-82d9-45c8-8613-8d9384abb50f' = 'tomato'
  'b7e120ed-c42e-4ab5-817e-f3c787771014' = 'brinjal'
  '866b1b4e-7529-4149-a74f-609f45eec277' = 'cucumber'
  'cf0a353b-ccfc-46bb-831c-588db6a2b3d6' = 'beans'
  '1482e37d-32bf-4470-85bf-57aff78a63b1' = 'lettuce'
  '82d6080b-6b30-480b-bc20-fb13f2dad50e' = 'pumpkin'
  'b78d88b3-7985-4cd5-9bf6-50f781a9966a' = 'strawberry'
  'cd095623-3508-454a-a322-c11281f8f71d' = 'banana'
  '4b04e245-af4b-4883-8028-5efa397fd1d7' = 'mango'
  '5acb7c02-27b7-4fac-a7db-94b3fd8e6931' = 'citrus'
  '309c7a07-2d64-4e0f-9d7c-dbefedab5af6' = 'wheat'
  'f51a3b10-f498-4aef-b1ec-ea06c21f31c7' = 'peas'
  'defd841d-2c91-481c-ad92-c8f09f4c4bea' = 'garlic'
  '2d4dbe5e-5f5c-4d1c-b5cb-a421ca43a791' = 'onion'
  '889268e8-aa19-4390-8320-b57e61e93c38' = 'potato'
  '7e279816-c2fe-4446-ad1e-9906fb0918f8' = 'carrot'
  'bdbc29f7-544c-454d-8f82-6d0a17050688' = 'radish'
  'e26ef911-4c04-497f-a6c2-0f069c9375a2' = 'spinach'
  '46459d95-ff07-413f-b341-b8c2d1814351' = 'rice'
  '85e4180c-c638-44b9-9545-e1190038abd0' = 'maize'
  '14e96cce-4440-49ed-b61b-5248dba0bd00' = 'soybean'
  '575fb0dc-31a0-4a3e-8b91-2a795a6b75a6' = 'groundnut'
  'f7b758cf-0873-4684-9278-2708fe5e834e' = 'okra'
  '252cbfa1-bae4-48a5-95db-21308316ae8d' = 'bottle_gourd'
  '72874225-2146-4008-9348-a1c271f1157c' = 'rose'
  '7d6a7d7b-c14a-4f14-ab6a-ccd683a5eae4' = 'marigold'
  '48fcc8e4-d94e-49ad-87dd-84c980f40ee6' = 'sunflower'
  '0d3eee73-ee92-4654-9de5-d45a5c97b7a3' = 'mint'
  '4de66087-8541-4f44-84ba-83b66e39f465' = 'basil'
  'db101063-7520-419e-a5bd-2f73661eb7a3' = 'coriander'
}

function Get-DefaultCursorAssetsDirs {
  $root = Join-Path $env:USERPROFILE '.cursor\projects'
  if (-not (Test-Path -LiteralPath $root)) { return @() }
  # Prefer the Hackathon / growspehere slug you used in chat
  $preferred = @(
    (Join-Path $root 'c-Users-NavaneethKrishnan-G1-project-Hackathon-Project-growspehere-v1\assets'),
    (Join-Path $root 'c-Users-NavaneethKrishnan-G1-project-Hackathon-Project-growsphere-v1\assets')
  )
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($p in $preferred) {
    if (Test-Path -LiteralPath $p) { $out.Add($p) }
  }
  # Any other .../assets under projects (fallback)
  Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $a = Join-Path $_.FullName 'assets'
    if ((Test-Path -LiteralPath $a) -and -not $out.Contains($a)) { $out.Add($a) }
  }
  return $out
}

function Find-FileByUuid([string[]]$dirs, [string]$uuid) {
  foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) { continue }
    $hits = Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$uuid*" }
    $f = $hits | Select-Object -First 1
    if ($null -ne $f -and (Test-Path -LiteralPath $f.FullName)) { return $f.FullName }
  }
  return $null
}

$cursorDirs = @()
if (-not [string]::IsNullOrWhiteSpace($CursorAssets)) {
  $cursorDirs = @($CursorAssets)
} else {
  $cursorDirs = @(Get-DefaultCursorAssetsDirs)
}

if ([string]::IsNullOrWhiteSpace($Source)) {
  $Source = Join-Path $env:USERPROFILE 'Downloads\Growsphere_hand_crops'
}

$extraRoots = @(
  (Join-Path $env:USERPROFILE 'Downloads\vegetable_hand_crops'),
  (Join-Path $env:USERPROFILE 'Downloads\fruit_hand_crops'),
  (Join-Path $env:USERPROFILE 'Downloads\rabi_hand_crops')
)

function Find-ManualFile([string]$id) {
  foreach ($root in @($Source) + $extraRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    foreach ($ext in @('png', 'jpg', 'jpeg', 'webp')) {
      $p = Join-Path $root "$id.$ext"
      if (Test-Path -LiteralPath $p) { return $p }
    }
  }
  return $null
}

# Robocopy reads some Cursor asset paths where Copy-Item sees a missing file.
# Stage under %TEMP% (not under assets/) so long Cursor filenames never land in the repo (Windows MAX_PATH + git).
function Try-CopyCursorUploadViaRobocopy([string[]]$srcDirs, [string]$destDir, [string]$uuid, [string]$id) {
  $target = Join-Path $destDir "$id.png"
  $stage = Join-Path $env:TEMP 'growspehere_hand_robocopy_staging'
  foreach ($srcDir in $srcDirs) {
    if (-not (Test-Path -LiteralPath $srcDir)) { continue }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Get-ChildItem -LiteralPath $stage -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $null = & robocopy $srcDir $stage "*$uuid*" /NJH /NJS /NDL /NC /NS /NP 2>&1
    $candidates = @(Get-ChildItem -LiteralPath $stage -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like 'c__Users*' -and $_.Name -like "*$uuid*" })
    if ($candidates.Count -lt 1) { continue }
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    Move-Item -LiteralPath $candidates[0].FullName -Destination $target -Force
    if ((Test-Path -LiteralPath $target) -and ((Get-Item -LiteralPath $target).Length -gt 512)) { return $true }
  }
  return $false
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Legacy: staging under hands/ broke `git add` on Windows (path too long)
$legacyStaging = Join-Path $dest '_staging_robocopy'
if (Test-Path -LiteralPath $legacyStaging) {
  cmd /c "rmdir /s /q `"$legacyStaging`"" | Out-Null
}
Get-ChildItem -LiteralPath $dest -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like 'c__Users*' } |
  Remove-Item -Force -ErrorAction SilentlyContinue

$copied = 0
$fromCursor = 0
$missing = New-Object System.Collections.Generic.List[string]

foreach ($pair in $cursorMap.GetEnumerator()) {
  $uuid = $pair.Key
  $id = $pair.Value
  if (Try-CopyCursorUploadViaRobocopy $cursorDirs $dest $uuid $id) {
    $len = (Get-Item -LiteralPath (Join-Path $dest "$id.png")).Length
    Write-Host "OK $id ($len bytes) <= Cursor (robocopy): $uuid"
    $copied++
    $fromCursor++
    continue
  }
  $src = Find-FileByUuid $cursorDirs $uuid
  if ($null -ne $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest "$id.png") -Force
    $len = (Get-Item -LiteralPath (Join-Path $dest "$id.png")).Length
    Write-Host "OK $id ($len bytes) <= Cursor: $(Split-Path $src -Leaf)"
    $copied++
    $fromCursor++
    continue
  }
  $src2 = Find-ManualFile $id
  if ($null -ne $src2) {
    Copy-Item -LiteralPath $src2 -Destination (Join-Path $dest "$id.png") -Force
    $len = (Get-Item -LiteralPath (Join-Path $dest "$id.png")).Length
    Write-Host "OK $id ($len bytes) <= manual: $(Split-Path $src2 -Leaf)"
    $copied++
    continue
  }
  $missing.Add($id)
}

$stageCleanup = Join-Path $env:TEMP 'growspehere_hand_robocopy_staging'
if (Test-Path -LiteralPath $stageCleanup) {
  Remove-Item -LiteralPath $stageCleanup -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "Copied: $copied / $($cursorMap.Count) (from Cursor uploads: $fromCursor)"
if ($missing.Count -gt 0) {
  Write-Warning "Still missing: $($missing -join ', ')"
  Write-Host 'Your originals usually live under:'
  Write-Host ('  ' + (Join-Path $env:USERPROFILE '.cursor\projects\...\assets\'))
  Write-Host 'Or put chilli.png, tomato.png, ... under:'
  Write-Host ('  ' + $Source)
}
