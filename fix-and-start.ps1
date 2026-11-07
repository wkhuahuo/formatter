# WPS 公文编辑器 - Electron 修复和启动脚本

Write-Host "======================================"
Write-Host "  WPS 公文编辑器 - 修复并启动"
Write-Host "======================================"
Write-Host ""

# 设置 PATH
$env:PATH = "C:\Users\dk\AppData\Local\Programs\node20;C:\Users\dk\AppData\Local\Programs\maven39\bin;$env:PATH"

# 步骤 1: 停止所有进程
Write-Host "[1/5] 停止所有 Electron/Java 进程..."
Get-Process | Where-Object { 
    $_.ProcessName -like "*electron*" -or 
    $_.ProcessName -like "*node*" -or 
    $_.ProcessName -like "*java*" 
} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "      ✅ 进程已停止"
Write-Host ""

# 步骤 2: 删除旧的 release 目录
Write-Host "[2/5] 清理旧的打包版本..."
if (Test-Path release) {
    Remove-Item -Recurse -Force release
    Write-Host "      ✅ release 目录已删除"
} else {
    Write-Host "      ℹ️  release 目录不存在，跳过"
}
Write-Host ""

# 步骤 3: 验证后端 jar
Write-Host "[3/5] 验证后端 JAR 文件..."
$jarPath = "electron\resources\backend\app.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "      ⚠️  JAR 文件不存在，正在构建..."
    Set-Location backend
    mvn clean package -DskipTests
    Set-Location ..
    New-Item -ItemType Directory -Force -Path "electron\resources\backend" | Out-Null
    Copy-Item "backend\target\latex-online-backend-*.jar" $jarPath -Force
    Write-Host "      ✅ 后端构建完成"
} else {
    $jarTime = Get-Item $jarPath | Select-Object -ExpandProperty LastWriteTime
    $targetJar = Get-ChildItem backend\target\latex-online-backend-*.jar -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($targetJar -and $targetJar.LastWriteTime -gt $jarTime) {
        Write-Host "      ⚠️  JAR 文件过旧，正在更新..."
        Copy-Item $targetJar.FullName $jarPath -Force
        Write-Host "      ✅ JAR 文件已更新"
    } else {
        Write-Host "      ✅ JAR 文件已是最新"
    }
}
Write-Host ""

# 步骤 4: 验证前端 dist
Write-Host "[4/5] 验证前端构建..."
$distPath = "frontend\dist\index.html"
if (-not (Test-Path $distPath)) {
    Write-Host "      ⚠️  前端未构建，正在构建..."
    Set-Location frontend
    npm install
    node node_modules\vite\bin\vite.js build
    Set-Location ..
    Write-Host "      ✅ 前端构建完成"
} else {
    Write-Host "      ✅ 前端已构建"
}
Write-Host ""

# 步骤 5: 启动 Electron（开发模式）
Write-Host "[5/5] 启动 Electron 应用..."
Write-Host ""
Write-Host "======================================"
Write-Host "  应用即将启动"
Write-Host "  模式: 开发模式"
Write-Host "  数据库: SQLite"
Write-Host "======================================"
Write-Host ""

Set-Location electron
node ..\node_modules\electron\cli.js .
Set-Location ..
