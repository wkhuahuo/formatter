#!/usr/bin/env pwsh
# WPS 公文编辑器 - 一键发布完整流程（构建 + 发布）
# 用法: .\scripts\publish-all.ps1 -Version "1.0.0"
#
# 此脚本整合了构建和发布的所有步骤，实现真正的一键发布

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [switch]$SkipBuild = $false,
    [switch]$SkipGitee = $false,
    [switch]$Clean = $false,
    [string]$ReleaseNotes = ""
)

$ErrorActionPreference = "Stop"

# 颜色定义
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Step { param($step, $total, $msg) Write-Host "`n[$step/$total] $msg" -ForegroundColor Magenta }

# 获取项目根目录
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Info "====================================="
Write-Info "  WPS 公文编辑器 - 一键发布"
Write-Info "====================================="
Write-Host ""
Write-Info "版本号: v$Version"
Write-Info "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 验证版本号
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "错误: 版本号格式不正确，应为 X.Y.Z"
    exit 1
}

$TagVersion = "v$Version"
$TotalSteps = if ($SkipBuild) { 4 } else { 7 }
$CurrentStep = 0

# ========== 构建阶段 ==========

if (-not $SkipBuild) {
    # 步骤 1: 检查依赖
    $CurrentStep++
    Write-Step $CurrentStep $TotalSteps "检查依赖工具..."
    
    $Dependencies = @("node", "npm", "java", "mvn", "git", "gh")
    foreach ($cmd in $Dependencies) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            if ($cmd -eq "gh") {
                Write-Error "错误: 未找到 GitHub CLI (gh)"
                Write-Host "请安装: winget install GitHub.cli"
                exit 1
            } else {
                Write-Error "错误: 未找到 $cmd"
                exit 1
            }
        }
    }
    Write-Success "  ✓ 所有依赖工具已就绪"
    
    # 步骤 2: 清理（可选）
    if ($Clean) {
        $CurrentStep++
        Write-Step $CurrentStep $TotalSteps "清理旧构建..."
        Remove-Item -Recurse -Force "frontend/dist" -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force "backend/target" -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force "release" -ErrorAction SilentlyContinue
        Write-Success "  ✓ 清理完成"
    }
    
    # 步骤 3: 构建前端
    $CurrentStep++
    Write-Step $CurrentStep $TotalSteps "构建前端..."
    Set-Location "$Root/frontend"
    npm install --silent
    npm run build
    Set-Location $Root
    Write-Success "  ✓ 前端构建完成"
    
    # 步骤 4: 构建后端
    $CurrentStep++
    Write-Step $CurrentStep $TotalSteps "构建后端..."
    Set-Location "$Root/backend"
    mvn -q clean package -DskipTests
    Set-Location $Root
    Write-Success "  ✓ 后端构建完成"
    
    # 步骤 5: 准备资源并打包
    $CurrentStep++
    Write-Step $CurrentStep $TotalSteps "打包 Electron 应用..."
    
    # 复制 JAR
    $JarSource = Get-ChildItem "$Root/backend/target/latex-online-backend-*.jar" | Select-Object -First 1
    if (-not $JarSource) {
        Write-Error "错误: 未找到后端 JAR 文件"
        exit 1
    }
    
    New-Item -ItemType Directory -Force -Path "$Root/electron/resources/backend" | Out-Null
    Copy-Item $JarSource.FullName "$Root/electron/resources/backend/app.jar" -Force
    
    # 更新版本号
    $PackageJsonPath = "$Root/package.json"
    $PackageJson = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
    $PackageJson.version = $Version
    $PackageJson | ConvertTo-Json -Depth 100 | Set-Content $PackageJsonPath -Encoding UTF8
    
    # 执行打包
    Set-Location $Root
    npm install --silent
    npx electron-builder --win --x64 --config.win.target=zip
    
    # 验证构建产物
    $ReleaseDir = "$Root/release"
    $ZipFiles = Get-ChildItem "$ReleaseDir/*.zip" -ErrorAction SilentlyContinue
    
    if (-not $ZipFiles) {
        Write-Error "错误: 未找到构建产物"
        exit 1
    }
    
    Write-Success "  ✓ Electron 打包完成"
    foreach ($file in $ZipFiles) {
        $Size = [math]::Round($file.Length / 1MB, 2)
        Write-Host "    📦 $($file.Name) - $Size MB" -ForegroundColor Gray
    }
} else {
    Write-Warning "跳过构建阶段（使用 -SkipBuild）"
    
    # 查找现有构建产物
    $ReleaseDir = "$Root/release"
    $ZipFiles = Get-ChildItem "$ReleaseDir/*.zip" -ErrorAction SilentlyContinue
    
    if (-not $ZipFiles) {
        Write-Error "错误: 未找到构建产物，请先运行构建"
        exit 1
    }
}

# ========== 发布阶段 ==========

# 步骤 6: Git 操作
$CurrentStep++
Write-Step $CurrentStep $TotalSteps "准备 Git 标签..."

# 检查 Git 状态
$Status = git status --porcelain
if ($Status) {
    Write-Warning "  ⚠ 有未提交的更改"
    $Confirm = Read-Host "是否继续发布？(y/N)"
    if ($Confirm -ne 'y' -or $Confirm -ne 'Y') {
        Write-Info "发布已取消"
        exit 0
    }
    
    # 提交更改
    git add .
    git commit -m "chore: release $TagVersion"
    Write-Success "  ✓ 已提交更改"
}

# 创建标签
$ExistingTag = git tag -l $TagVersion
if ($ExistingTag) {
    Write-Warning "  ⚠ 标签 $TagVersion 已存在，将覆盖"
    git tag -d $TagVersion
}

git tag $TagVersion -m "Release version $Version"
Write-Success "  ✓ 标签已创建: $TagVersion"

# 推送标签
try {
    git push origin $TagVersion 2>&1 | Out-Null
    Write-Success "  ✓ 已推送到 GitHub"
} catch {
    Write-Warning "  ⚠ 推送到 GitHub 失败，重试中..."
    git push origin $TagVersion
}

if (-not $SkipGitee) {
    try {
        git push gitee $TagVersion 2>&1 | Out-Null
        Write-Success "  ✓ 已同步到 Gitee"
    } catch {
        Write-Warning "  ⚠ 同步到 Gitee 失败（可忽略）"
    }
}

# 步骤 7: 创建 GitHub Release
$CurrentStep++
Write-Step $CurrentStep $TotalSteps "创建 GitHub Release..."

# 准备 Release Notes
if ([string]::IsNullOrEmpty($ReleaseNotes)) {
    $ReleaseNotes = @"
## WPS 公文编辑器 $TagVersion

### 📦 下载说明

- **$($ZipFiles[0].Name)** - Windows 64位免安装版

### 🚀 使用方法

1. 下载 zip 文件
2. 解压到任意目录
3. 双击运行 `WpsDocEditor.exe`

### 📋 系统要求

- Windows 7/8/10/11 (64位)
- 无需安装 Java 或 Node.js（已内置）

### 📝 更新日志

- 版本: $TagVersion
- 发布日期: $(Get-Date -Format "yyyy-MM-dd")

---

**完整文档**: [查看 README](https://github.com/wkhuahuo/formatter#readme)
"@
}

# 创建 Release
try {
    $ReleaseUrl = gh release create $TagVersion `
        --title "WPS 公文编辑器 $TagVersion" `
        --notes $ReleaseNotes `
        --target main 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "创建 Release 失败"
    }
    
    Write-Success "  ✓ Release 已创建"
} catch {
    Write-Error "错误: 创建 Release 失败"
    Write-Host $_.Exception.Message
    exit 1
}

# 上传构建产物
Write-Host ""
Write-Info "上传构建产物..."

foreach ($file in $ZipFiles) {
    Write-Info "  📤 上传 $($file.Name)..."
    try {
        gh release upload $TagVersion $file.FullName --clobber 2>&1 | Out-Null
        Write-Success "  ✓ 上传成功"
    } catch {
        Write-Error "  ✗ 上传失败: $($_.Exception.Message)"
    }
}

# ========== 完成 ==========

Write-Host ""
Write-Info "====================================="
Write-Success "  发布完成！🎉"
Write-Info "====================================="
Write-Host ""
Write-Success "📍 GitHub Release:"
Write-Host "   https://github.com/wkhuahuo/formatter/releases/tag/$TagVersion"
Write-Host ""

if (-not $SkipGitee) {
    Write-Info "📍 Gitee Release（需手动同步）:"
    Write-Host "   https://gitee.com/wkhuahuo/latexOnline/releases/new"
    Write-Host ""
}

Write-Info "📦 构建产物:"
foreach ($file in $ZipFiles) {
    $Size = [math]::Round($file.Length / 1MB, 2)
    Write-Host "   $($file.Name) - $Size MB" -ForegroundColor Gray
}

Write-Host ""
Write-Info "📋 后续步骤:"
Write-Host "   1. 测试下载的应用程序"
Write-Host "   2. 更新项目文档（如需要）"
Write-Host "   3. 通知团队成员和用户"
if (-not $SkipGitee) {
    Write-Host "   4. 手动同步到 Gitee Release" -ForegroundColor Yellow
}

Write-Host ""
Write-Success "✨ 恭喜！版本 v$Version 已成功发布！"
Write-Host ""
