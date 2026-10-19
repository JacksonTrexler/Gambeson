@echo off
rem Shim so `Util\gamb ...` works from cmd.exe and PowerShell without touching execution policy.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0gamb.ps1" %*
exit /b %ERRORLEVEL%
