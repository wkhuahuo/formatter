#!/usr/bin/env pwsh
# WPS 公文编辑器 - 一键构建和打包脚本
# 用法: .\scripts\build-package.ps1 [-Version "1.0.0"]

param(
    [string]$Version = "",
    [switch]$SkipJRE,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# 颜色定义
function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host $msg -ForegroundColor Red }

# 获取项目根目录
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Info "====================================="
Write-Info "  WPS 公文编辑器 - 一键构建打包"
Write-Info "====================================="
Write-Host ""

# 检查依赖
Write-Info "[检查] 验证依赖工具..."

$tools = @("node", "npm", "java", "mvn", "git")
$toolNames = @("Node.js", "npm", "Java", "Maven", "Git")

foreach ($tool in $tools) {
    $index = [Array]::IndexOf($tools, $tool)
    $name = $toolNames[$index]
    
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Err "错误: 未找到 $name，请先安装"
        exit 1
    }
}

Write-Success "  ✓ 所有依赖工具已就绪"

# 读取版本号
if ([string]::IsNullOrEmpty($Version)) {
    $PackageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
    $Version = $PackageJson.version
    Write-Info "[信息] 使用 package.json 中的版本号: v$Version"
}
else {
    Write-Info "[信息] 使用指定版本号: v$Version"
}

# 清理（可选）
if ($Clean) {
    Write-Info "[清理] 清除旧的构建产物..."
    Remove-Item -Recurse -Force "frontend/dist" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "backend/target" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "release" -ErrorAction SilentlyContinue
    Write-Success "  ✓ 清理完成"
}

# 1. 构建前端
Write-Host ""
Write-Info "[1/5] 构建前端..."
Push-Location "$Root/frontend"
npm install --silent
npm run build
Pop-Location
Write-Success "  ✓ 前端构建完成"

# 2. 构建后端
Write-Host ""
Write-Info "[2/5] 构建后端..."
Push-Location "$Root/backend"
mvn -q clean package -DskipTests
Pop-Location
Write-Success "  ✓ 后端构建完成"

# 3. 准备资源
Write-Host ""
Write-Info "[3/5] 准备打包资源..."

# 复制 JAR
$JarSource = Get-ChildItem "$Root/backend/target/latex-online-backend-*.jar" | Select-Object -First 1
if (-not $JarSource) {
    Write-Err "错误: 未找到后端 JAR 文件"
    exit 1
}

New-Item -ItemType Directory -Force -Path "$Root/electron/resources/backend" | Out-Null
Copy-Item $JarSource.FullName "$Root/electron/resources/backend/app.jar" -Force
Write-Success "  ✓ JAR 文件已复制"

# 检查 JRE
if (-not $SkipJRE) {
    $JrePath = "$Root/electron/resources/jre"
    if (-not (Test-Path "$JrePath/bin/java.exe")) {
        Write-Warn "  ⚠ JRE 未找到，将尝试使用系统 JRE"
        Write-Warn "    提示: 运行 scripts/build-runtime.sh 生成精简 JRE"
    }
    else {
        Write-Success "  ✓ JRE 已就绪"
    }
}

# 4. 更新版本号
Write-Host ""
Write-Info "[4/5] 更新版本号..."
$PackageJsonPath = "$Root/package.json"
$PackageJson = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
$PackageJson.version = $Version
$PackageJson | ConvertTo-Json -Depth 100 | Set-Content $PackageJsonPath -Encoding UTF8
Write-Success "  ✓ 版本号已更新为 v$Version"

# 5. 打包 Electron
Write-Host ""
Write-Info "[5/5] 打包 Electron 应用..."
Set-Location $Root
npm install --silent

# 执行打包
npx electron-builder --win --x64

# 查找构建产物
$ReleaseDir = "$Root/release"
$ZipFiles = Get-ChildItem "$ReleaseDir/*.zip" -ErrorAction SilentlyContinue

if (-not $ZipFiles) {
    Write-Err "错误: 未找到构建产物"
    exit 1
}

Write-Success "  ✓ Electron 打包完成"

# 显示结果
Write-Host ""
Write-Info "====================================="
Write-Success "  构建完成！"
Write-Info "====================================="
Write-Host ""
Write-Info "构建产物:"
foreach ($file in $ZipFiles) {
    $Size = [math]::Round($file.Length / 1MB, 2)
    Write-Success "  📦 $($file.Name) - $Size MB"
}

Write-Host ""
Write-Info "下一步:"
Write-Host "  运行发布脚本: .\scripts\release-deploy.ps1 -Version `"$Version`""
Write-Host ""

# 返回构建产物路径供其他脚本使用
return $ZipFiles[0].FullName
