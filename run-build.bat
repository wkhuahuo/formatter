@echo off
chcp 65001 >nul
echo ====================================
echo   WPS Doc Editor - Build
echo ====================================
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\build-simple.ps1" %*
pause
