# WPS Doc Editor - Clean Build Artifacts
# 仅清除代码相关的构建产物，保留稳定资源（JRE、数据库等）

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  WPS Doc Editor - Clean" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$items = @(
    @{ Path = "node_modules";             Desc = "根目录 node_modules" },
    @{ Path = "frontend/node_modules";    Desc = "前端 node_modules" },
    @{ Path = "frontend/dist";            Desc = "前端构建产物" },
    @{ Path = "backend/target";           Desc = "后端 Maven 构建产物" },
    @{ Path = "release";                  Desc = "Electron 打包产物" },
    @{ Path = "electron/resources/backend/app.jar"; Desc = "后端 JAR 副本" },
    @{ Path = "electron-startup.log";     Desc = "启动日志" }
)

foreach ($item in $items) {
    $fullPath = Join-Path $Root $item.Path
    if (Test-Path $fullPath) {
        Write-Host "  删除: $($item.Desc) ($($item.Path))" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $fullPath
    } else {
        Write-Host "  跳过: $($item.Desc) (不存在)" -ForegroundColor DarkGray
    }
}

# 清除 npm 缓存（可选，注释掉默认不执行）
# Write-Host "`n  清除 npm 缓存..." -ForegroundColor Yellow
# npm cache clean --force

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  Clean Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "`n保留: JRE、数据库等稳定资源" -ForegroundColor DarkGray
Write-Host "提示: 重新构建请执行 .\run-build.bat" -ForegroundColor Cyan

