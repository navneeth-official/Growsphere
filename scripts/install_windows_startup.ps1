#Requires -Version 5.1
<#
.SYNOPSIS
  Add or remove a Windows login shortcut that runs Growsphere via the batch launcher.

.DESCRIPTION
  Creates a .lnk in the user's Startup folder (shell:startup) pointing to
  run_growsphere_windows.bat. On each sign-in, a console window opens and runs
  `flutter run -d windows` (dev workflow). For a silent start, build a release
  first and point the shortcut to the .exe under build\windows\...\runner\Release\.

.PARAMETER Remove
  Remove the Growsphere startup shortcut if present.
#>
param([switch]$Remove)

$ErrorActionPreference = 'Stop'
$bat = Join-Path $PSScriptRoot 'run_growsphere_windows.bat'
if (-not (Test-Path -LiteralPath $bat)) {
  Write-Error "Missing: $bat"
}

$startup = [Environment]::GetFolderPath('Startup')
$linkPath = Join-Path $startup 'Growsphere (Flutter run).lnk'

if ($Remove) {
  if (Test-Path -LiteralPath $linkPath) {
    Remove-Item -LiteralPath $linkPath -Force
    Write-Host "Removed: $linkPath" -ForegroundColor Green
  } else {
    Write-Host "Nothing to remove: $linkPath" -ForegroundColor Yellow
  }
  exit 0
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($linkPath)
$shortcut.TargetPath = $bat
$shortcut.WorkingDirectory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$shortcut.WindowStyle = 1
$shortcut.Description = 'Run Growsphere Flutter app on Windows (dev)'
$shortcut.Save()

Write-Host "Startup shortcut created:" -ForegroundColor Green
Write-Host "  $linkPath"
Write-Host ""
Write-Host "To remove later: powershell -File install_windows_startup.ps1 -Remove"
Write-Host "Or delete the shortcut from: shell:startup"
Write-Host ""
Write-Host "Note: This runs the dev launcher (flutter run). For production, use a shortcut to the built Release .exe instead."
