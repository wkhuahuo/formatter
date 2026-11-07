# WPS 公文编辑器 - Electron 启动脚本（Windows PowerShell）

Write-Host "======================================"
Write-Host "  WPS 公文编辑器 - 开发模式启动"
Write-Host "======================================"
Write-Host ""

# 设置 PATH 环境变量
$env:PATH = "C:\Users\dk\AppData\Local\Programs\node20;C:\Users\dk\AppData\Local\Programs\maven39\bin;$env:PATH"

# 检查后端 jar 是否存在
$jarPath = "electron\resources\backend\app.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "⚠️  后端 jar 未找到，正在构建..."
    Write-Host ""
    
    # 构建后端
    Set-Location backend
    mvn clean package -DskipTests
    Set-Location ..
    
    # 复制 jar
    New-Item -ItemType Directory -Force -Path "electron\resources\backend" | Out-Null
    Copy-Item "backend\target\latex-online-backend-*.jar" $jarPath -Force
    Write-Host "✅ 后端构建完成"
    Write-Host ""
}

# 检查前端 dist 是否存在
$distPath = "frontend\dist\index.html"
if (-not (Test-Path $distPath)) {
    Write-Host "⚠️  前端未构建，正在构建..."
    Write-Host ""
    
    # 构建前端
    Set-Location frontend
    npm install
    node node_modules\vite\bin\vite.js build
    Set-Location ..
    Write-Host "✅ 前端构建完成"
    Write-Host ""
}

# 启动 Electron
Write-Host "🚀 启动 Electron 应用..."
Write-Host ""
Set-Location electron
node ..\node_modules\electron\cli.js .
Set-Location ..
