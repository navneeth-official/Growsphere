# Copies the six hand-held vegetable photos into assets/images/crops/hands/
# Order: Green chilli, tomato, brinjal, cucumber, French beans, lettuce.
#
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File tool/copy_vegetable_hand_crops.ps1
#
# Tries each crop in order:
#   1) Cursor workspace storage (UUID .png names from the chat upload)
#   2) %USERPROFILE%\Downloads\vegetable_hand_crops\ with:
#        Chilli.png  Tomato.png  Brinjal.png  Cucumber.png  FrenchBeans.png  Lettuce.png

$ErrorActionPreference = 'Stop'
$dst = Join-Path $PSScriptRoot '..\assets\images\crops\hands' | Resolve-Path

$cursorDir = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-NavaneethKrishnan-G1-project-Hackathon-Project-growspehere-v1\assets'
$dl = Join-Path $env:USERPROFILE 'Downloads\vegetable_hand_crops'

$rows = @(
  @{ id = 'chilli';    cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-f5ffadea-3e89-4a6b-b011-02c6ffd83ec2.png'; dl = 'Chilli.png' },
  @{ id = 'tomato';    cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-1348685c-d47f-4d2a-a701-8f7a899cd808.png'; dl = 'Tomato.png' },
  @{ id = 'brinjal';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-7f6204d8-d3bd-4a7d-9f9e-7f0c5a789bfc.png'; dl = 'Brinjal.png' },
  @{ id = 'cucumber';  cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-1da87137-b5d5-4627-b6c2-4c27fe5e8613.png'; dl = 'Cucumber.png' },
  @{ id = 'beans';     cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-bc6e495c-ddce-497d-80a2-7a6b50700c37.png'; dl = 'FrenchBeans.png' },
  @{ id = 'lettuce';   cursor = 'c__Users_NavaneethKrishnan_G1_AppData_Roaming_Cursor_User_workspaceStorage_c25d2af9e480bc90ab0b4033cfc2eee1_images_image-2795337d-7da1-49ce-8117-890e2da7f653.png'; dl = 'Lettuce.png' }
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
  Write-Warning "No source for: $($miss -join ', ') - keeping existing assets/images/crops/hands/*.png"
  Write-Host 'Add files to either:'
  Write-Host ('  ' + $cursorDir)
  Write-Host ('  ' + $dl)
}
Write-Host 'Done.'
