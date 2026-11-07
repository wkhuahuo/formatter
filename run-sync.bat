@echo off
chcp 65001 >nul
echo 正在运行同步脚本...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\sync-push.ps1"
pause
