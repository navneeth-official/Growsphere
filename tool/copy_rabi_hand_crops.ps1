# Copies eight hand-held crop photos into assets/images/crops/hands/
# Order: wheat, peas (green peas), garlic, onion, potato, carrot, radish, spinach.
#
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool/copy_rabi_hand_crops.ps1
#
# Tries each crop:
#   1) Cursor workspace storage (UUID .png from chat upload)
#   2) %USERPROFILE%\Downloads\rabi_hand_crops\ with:
#        Wheat.png  Peas.png  Garlic.png  Onion.png  Potato.png  Carrot.png  Radish.png  Spinach.png

$ErrorActionPreference = 'Stop'
$dst = Join-Path $PSScriptRoot '..\assets\images\crops\hands' | Resolve-Path

$cursorDir = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-NavaneethKrishnan-G1-project-Hackathon-Project-growspehere-v1\assets'
$dl = Join-Path $env:USERPROFILE 'Downloads\rabi_hand_crops'

$rows = @(
  @{ id = 'wheat';    cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-af5a8898-aeda-40c4-b068-fffa30ed66a2.png'; dl = 'Wheat.png' },
  @{ id = 'peas';     cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-2b1f7eeb-362c-4159-bc2c-3767e527c96e.png'; dl = 'Peas.png' },
  @{ id = 'garlic';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-f304bf89-af82-4179-ade6-c2ca405e0981.png'; dl = 'Garlic.png' },
  @{ id = 'onion';    cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-0975951a-772f-457c-ace1-76a7be480f1b.png'; dl = 'Onion.png' },
  @{ id = 'potato';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-da616121-8f98-42a8-a7c3-67ace3e20761.png'; dl = 'Potato.png' },
  @{ id = 'carrot';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-7dae58ad-9a51-40e6-bf02-6f99d308c59e.png'; dl = 'Carrot.png' },
  @{ id = 'radish';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-e7803f96-438e-410c-a2cf-10c206d9a507.png'; dl = 'Radish.png' },
  @{ id = 'spinach';  cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-0b56f95c-d7d7-4df0-b75b-d675a9d9c0a8.png'; dl = 'Spinach.png' }
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
