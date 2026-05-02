#Requires -Version 5.1
<#
.SYNOPSIS
  Prepare and run Growsphere (Flutter) on Windows desktop.

.DESCRIPTION
  Resolves Flutter, runs from the project root (parent of /scripts), executes
  pub get, generates l10n, then `flutter run -d windows`.

.PARAMETER Doctor
  Run `flutter doctor -v` first, then exit (no run).

.PARAMETER BuildRelease
  Run `flutter build windows` instead of `flutter run` (output under build\windows\...).
#>
param(
  [switch]$Doctor,
  [switch]$BuildRelease
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $ProjectRoot

function Find-Flutter {
  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat'),
    (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'),
    (Join-Path $env:USERPROFILE 'dev\flutter\bin\flutter.bat'),
    'C:\flutter\bin\flutter.bat',
    'C:\src\flutter\bin\flutter.bat'
  )
  foreach ($p in $candidates) {
    if ($p -and (Test-Path -LiteralPath $p)) { return $p }
  }
  return $null
}

$flutter = Find-Flutter
if (-not $flutter) {
  Write-Error @"
Flutter was not found in PATH or common install locations.

Install Flutter: https://docs.flutter.dev/get-started/install/windows
Then either:
  - Add Flutter's bin folder to your user PATH, or
  - Re-run this script after installing to the default location under %LOCALAPPDATA%\flutter
"@
}

Write-Host "Using Flutter: $flutter" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot" -ForegroundColor Cyan

if ($Doctor) {
  & $flutter doctor -v
  exit $LASTEXITCODE
}

Write-Host "`n>>> flutter pub get" -ForegroundColor Yellow
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n>>> flutter gen-l10n" -ForegroundColor Yellow
& $flutter gen-l10n
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($BuildRelease) {
  Write-Host "`n>>> flutter build windows" -ForegroundColor Yellow
  & $flutter build windows
  exit $LASTEXITCODE
}

Write-Host "`n>>> flutter run -d windows (Ctrl+C to stop)" -ForegroundColor Yellow
& $flutter run -d windows
exit $LASTEXITCODE
