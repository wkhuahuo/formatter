@echo off
chcp 65001 >nul
echo ====================================
echo   WPS 公文编辑器 - 一键发布
echo ====================================
echo.

if "%~1"=="" (
    echo 错误: 请提供版本号
    echo 用法: run-publish.bat 1.0.0
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0scripts\publish-all.ps1" -Version "%~1"
pause
