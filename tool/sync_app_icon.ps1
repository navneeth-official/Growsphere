# Keeps launcher art in sync from assets/branding/app_icon_source.png
# - Android: runs tool/render_round_app_icon.py (mipmap + adaptive + splash colors)
# - iOS / macOS / Web: runs flutter_launcher_icons (see pubspec.yaml flutter_launcher_icons:)
#
# RUN (repo root, Flutter on PATH):
#   powershell -ExecutionPolicy Bypass -File tool/sync_app_icon.ps1

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..' | Resolve-Path
$brandDir = Join-Path $root.Path 'assets\branding'
$src = Join-Path $brandDir 'app_icon_source.png'

# Raw Cursor drops use huge filenames (break `git add` on Windows). Remove if present.
$drive = 'Z'
if (Test-Path "${drive}:\") { subst.exe "${drive}:" /d 2>$null }
subst.exe "${drive}:" $brandDir | Out-Null
try {
  cmd /c "del /f /q ${drive}:\c__Users*.png" 2>$null
} finally {
  subst.exe "${drive}:" /d 2>$null
}

if (-not (Test-Path -LiteralPath $src)) {
  Write-Error "Missing $src — add your 1024+ square master there, then re-run."
}

python (Join-Path $PSScriptRoot 'render_round_app_icon.py')
if ($LASTEXITCODE -ne 0) { throw 'render_round_app_icon.py failed' }

Push-Location $root.Path
try {
  flutter pub get
  dart run flutter_launcher_icons
  Write-Host 'OK flutter_launcher_icons (iOS / macOS / web)'
} finally {
  Pop-Location
}
