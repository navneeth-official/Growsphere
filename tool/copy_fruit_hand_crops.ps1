# Copies five hand-held fruit photos into assets/images/crops/hands/
# Order: pumpkin, strawberry, banana, mango, citrus.
#
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool/copy_fruit_hand_crops.ps1
#
# Tries each crop:
#   1) Cursor workspace storage (UUID .png from chat upload)
#   2) %USERPROFILE%\Downloads\fruit_hand_crops\ with:
#        Pumpkin.png  Strawberry.png  Banana.png  Mango.png  Citrus.png

$ErrorActionPreference = 'Stop'
$dst = Join-Path $PSScriptRoot '..\assets\images\crops\hands' | Resolve-Path

$cursorDir = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-NavaneethKrishnan-G1-project-Hackathon-Project-growspehere-v1\assets'
$dl = Join-Path $env:USERPROFILE 'Downloads\fruit_hand_crops'

$rows = @(
  @{ id = 'pumpkin';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-fb6de9d8-fc5c-4745-9bc0-e01792df3897.png'; dl = 'Pumpkin.png' },
  @{ id = 'strawberry'; cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-7c799c85-a0b4-4814-86e1-be31af52e370.png'; dl = 'Strawberry.png' },
  @{ id = 'banana';    cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-b71103e5-5f32-42bf-a303-470fb927b7c4.png'; dl = 'Banana.png' },
  @{ id = 'mango';     cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-89da98b4-ae87-4972-8446-b7683e278c02.png'; dl = 'Mango.png' },
  @{ id = 'citrus';    cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-3c1e9d96-a01f-4754-ab72-7de7ceabd483.png'; dl = 'Citrus.png' }
)

New-Item -ItemType Directory -Force -Path $dst | Out-Null

function Copy-One($src, $id) {
  if (-not (Test-Path -LiteralPath $src)) { return $false }
  Copy-Item -LiteralPath $src -Destination (Join-Path $dst "$id.png") -Force
  Write-Host "OK ${id}.png <= $(Split-Path $src -Leaf)"
  return $true
}

$miss = @()
foreach ($r in $rows) {
  $c = Join-Path $cursorDir $r.cursor
  $d = Join-Path $dl $r.dl
  if (Copy-One $c $r.id) { continue }
  if (Copy-One $d $r.id) { continue }
  $miss += $r.id
}

if ($miss.Count -gt 0) {
  Write-Warning "No source for: $($miss -join ', ') - keeping existing hands/*.png"
  Write-Host 'Add files to either:'
  Write-Host ('  ' + $cursorDir)
  Write-Host ('  ' + $dl)
}
Write-Host 'Done.'
