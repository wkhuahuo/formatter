# WPS 公文编辑器 - Windows 构建脚本
# 用法: .\scripts\build.ps1

$ErrorActionPreference = "Stop"

Write-Host "=============== WPS 公文编辑器 构建 ===============" -ForegroundColor Cyan

# 获取项目根目录
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# 1. 构建前端
Write-Host "`n[1/4] 构建前端 -> frontend/dist" -ForegroundColor Yellow
Set-Location "$Root\frontend"
npm install
npm run build

# 2. 构建后端
Write-Host "`n[2/4] 构建后端 -> backend/target/*.jar" -ForegroundColor Yellow
Set-Location "$Root\backend"
mvn -q clean package -DskipTests

# 复制 JAR 文件
$JarSource = Get-ChildItem "$Root\backend\target\latex-online-backend-*.jar" | Select-Object -First 1
$JarDest = "$Root\electron\resources\backend\app.jar"
New-Item -ItemType Directory -Force -Path "$Root\electron\resources\backend" | Out-Null
Copy-Item $JarSource.FullName $JarDest -Force
Write-Host "      已复制 jar -> $JarDest" -ForegroundColor Green

# 3. 构建 JRE（可选，如果已有则跳过）
$JrePath = "$Root\electron\resources\jre"
if (Test-Path "$JrePath\bin\java.exe") {
    Write-Host "`n[3/4] JRE 已存在，跳过构建" -ForegroundColor Yellow
} else {
    Write-Host "`n[3/4] 生成精简 JRE -> electron/resources/jre" -ForegroundColor Yellow
    Write-Host "      注意：此步骤需要 jlink 工具，如未安装请手动复制 JRE" -ForegroundColor Red
    # 如果有 build-runtime.sh 的 Windows 版本，可以在这里调用
    # & "$Root\scripts\build-runtime.ps1"
}

# 4. 打包 Electron
Write-Host "`n[4/4] 打包 Electron -> release/*.zip" -ForegroundColor Yellow
Set-Location "$Root"
npm install
npx electron-builder --win --x64

# 显示构建结果
Write-Host "`n=============== 构建完成 ===============" -ForegroundColor Green
$ReleaseFiles = Get-ChildItem "$Root\release\*.zip" -ErrorAction SilentlyContinue
if ($ReleaseFiles) {
    Write-Host "构建产物:" -ForegroundColor Cyan
    $ReleaseFiles | ForEach-Object {
        Write-Host "  $($_.Name) - $([math]::Round($_.Length / 1MB, 2)) MB" -ForegroundColor Green
    }
    Write-Host "`n提示: 请手动上传这些文件到 GitHub 和 Gitee 的 Release 页面" -ForegroundColor Yellow
} else {
    Write-Host "未找到构建产物，请检查构建日志" -ForegroundColor Red
}
