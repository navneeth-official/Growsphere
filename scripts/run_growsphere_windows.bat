@echo off
setlocal
REM Double-click or run from cmd. Forwards optional args to PowerShell, e.g.:
REM   run_growsphere_windows.bat -Doctor
REM   run_growsphere_windows.bat -BuildRelease
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_growsphere_windows.ps1" %*
set EXITCODE=%ERRORLEVEL%
if not "%EXITCODE%"=="0" (
  echo.
  echo Script exited with code %EXITCODE%.
  pause
)
exit /b %EXITCODE%
