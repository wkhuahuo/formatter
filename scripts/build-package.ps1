# WPS 公文编辑器 - 一键构建和打包脚本

param(
    [string]$Version = "",
    [switch]$SkipJRE,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

# 配置国内镜像（解决 GitHub 下载超时）
$env:ELECTRON_MIRROR = "https://npmmirror.com/mirrors/electron/"
$env:ELECTRON_BUILDER_BINARIES_MIRROR = "https://npmmirror.com/mirrors/electron-builder-binaries/"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  WPS 公文编辑器 - 一键构建打包" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 检查依赖
Write-Host "[检查] 验证依赖工具..." -ForegroundColor Cyan

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "错误: 未找到 Node.js，请先安装" -ForegroundColor Red
    exit 1
}

$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmCmd) {
    Write-Host "错误: 未找到 npm，请先安装 Node.js" -ForegroundColor Red
    exit 1
}

$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd) {
    Write-Host "错误: 未找到 Java，请先安装" -ForegroundColor Red
    exit 1
}

$mvnCmd = Get-Command mvn -ErrorAction SilentlyContinue
if (-not $mvnCmd) {
    Write-Host "错误: 未找到 Maven，请先安装" -ForegroundColor Red
    exit 1
}

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Host "错误: 未找到 Git，请先安装" -ForegroundColor Red
    exit 1
}

Write-Host "  OK 所有依赖工具已就绪" -ForegroundColor Green

# 读取版本号
if ([string]::IsNullOrEmpty($Version)) {
    $PackageJson = Get-Content "package.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $Version = $PackageJson.version
    Write-Host "[信息] 使用 package.json 中的版本号: v$Version" -ForegroundColor Cyan
} else {
    Write-Host "[信息] 使用指定版本号: v$Version" -ForegroundColor Cyan
}

# 清理（可选）
if ($Clean) {
    Write-Host "[清理] 清除旧的构建产物..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force "frontend/dist" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "backend/target" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "release" -ErrorAction SilentlyContinue
    Write-Host "  OK 清理完成" -ForegroundColor Green
}

# 1. 构建前端
Write-Host ""
Write-Host "[1/5] 构建前端..." -ForegroundColor Cyan
Push-Location "$Root/frontend"
npm install --silent
npm run build
Pop-Location
Write-Host "  OK 前端构建完成" -ForegroundColor Green

# 2. 构建后端
Write-Host ""
Write-Host "[2/5] 构建后端..." -ForegroundColor Cyan
Push-Location "$Root/backend"
mvn -q clean package -DskipTests
Pop-Location
Write-Host "  OK 后端构建完成" -ForegroundColor Green

# 3. 准备资源
Write-Host ""
Write-Host "[3/5] 准备打包资源..." -ForegroundColor Cyan

$JarSource = Get-ChildItem "$Root/backend/target/latex-online-backend-*.jar" | Select-Object -First 1
if (-not $JarSource) {
    Write-Host "错误: 未找到后端 JAR 文件" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path "$Root/electron/resources/backend" | Out-Null
Copy-Item $JarSource.FullName "$Root/electron/resources/backend/app.jar" -Force
Write-Host "  OK JAR 文件已复制" -ForegroundColor Green

# 检查 JRE
if (-not $SkipJRE) {
    $JrePath = "$Root/electron/resources/jre"
    $JreExists = Test-Path "$JrePath/bin/java.exe"
    if (-not $JreExists) {
        Write-Host "  WARNING JRE 未找到，将尝试使用系统 JRE" -ForegroundColor Yellow
    } else {
        Write-Host "  OK JRE 已就绪" -ForegroundColor Green
    }
}

# 4. 更新版本号
Write-Host ""
Write-Host "[4/5] 更新版本号..." -ForegroundColor Cyan
$PackageJsonPath = "$Root/package.json"
$PackageJson = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
$PackageJson.version = $Version
$PackageJson | ConvertTo-Json -Depth 100 | Set-Content $PackageJsonPath -Encoding UTF8
Write-Host "  OK 版本号已更新为 v$Version" -ForegroundColor Green

# 5. 打包 Electron
Write-Host ""
Write-Host "[5/5] 打包 Electron 应用..." -ForegroundColor Cyan
Set-Location $Root
npm install --silent
npx electron-builder --win --x64

# 查找构建产物
$ReleaseDir = "$Root/release"
$ZipFiles = Get-ChildItem "$ReleaseDir/*.zip" -ErrorAction SilentlyContinue

if (-not $ZipFiles) {
    Write-Host "错误: 未找到构建产物" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Electron 打包完成" -ForegroundColor Green

# 显示结果
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  构建完成" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "构建产物:" -ForegroundColor Cyan
foreach ($file in $ZipFiles) {
    $Size = [math]::Round($file.Length / 1MB, 2)
    Write-Host "  $file - $Size MB" -ForegroundColor Green
}

Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  运行发布脚本: .\scripts\release-deploy.ps1 -Version $Version"
Write-Host ""

return $ZipFiles[0].FullName
