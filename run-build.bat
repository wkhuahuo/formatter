@echo off
chcp 65001 >nul
echo ====================================
echo   WPS 公文编辑器 - 一键构建打包
echo ====================================
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\build-package.ps1" %*
pause
