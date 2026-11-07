#!/usr/bin/env pwsh
# WPS 公文编辑器 - 一键发布到 GitHub Release
# 用法: .\scripts\release-deploy.ps1 -Version "1.0.0" [-BuildFirst] [-SkipGitee]

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [switch]$BuildFirst = $false,
    [switch]$SkipGitee = $false,
    [string]$ReleaseNotes = ""
)

$ErrorActionPreference = "Stop"

# 颜色定义
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

# 获取项目根目录
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Info "====================================="
Write-Info "  发布到 GitHub Release"
Write-Info "====================================="
Write-Host ""

# 验证版本号格式
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "错误: 版本号格式不正确，应为 X.Y.Z（例如：1.0.0）"
    exit 1
}

$TagVersion = "v$Version"

# 检查 GitHub CLI
Write-Info "[检查] 验证 GitHub CLI..."
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Error "错误: 未找到 GitHub CLI (gh)"
    Write-Host ""
    Write-Warning "请先安装 GitHub CLI:"
    Write-Host "  方式 1: winget install GitHub.cli"
    Write-Host "  方式 2: 访问 https://cli.github.com/"
    Write-Host ""
    Write-Info "或者使用传统方式（需要手动上传）:"
    Write-Host "  1. 创建标签: git tag $TagVersion"
    Write-Host "  2. 推送标签: git push origin $TagVersion"
    Write-Host "  3. 在 GitHub 网页上创建 Release 并上传文件"
    exit 1
}

# 检查 GitHub CLI 认证
try {
    $null = gh auth status 2>&1
    Write-Success "  ✓ GitHub CLI 已认证"
} catch {
    Write-Error "错误: GitHub CLI 未认证"
    Write-Host "请运行: gh auth login"
    exit 1
}

# 构建（可选）
if ($BuildFirst) {
    Write-Host ""
    Write-Info "[构建] 先执行构建..."
    & "$PSScriptRoot\build-package.ps1" -Version $Version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "构建失败，取消发布"
        exit 1
    }
}

# 查找构建产物
$ReleaseDir = "$Root/release"
$ZipFiles = Get-ChildItem "$ReleaseDir/*.zip" -ErrorAction SilentlyContinue

if (-not $ZipFiles) {
    Write-Error "错误: 未找到构建产物"
    Write-Host "请先运行: .\scripts\build-package.ps1 -Version `"$Version`""
    exit 1
}

Write-Info "[信息] 找到构建产物:"
foreach ($file in $ZipFiles) {
    $Size = [math]::Round($file.Length / 1MB, 2)
    Write-Success "  📦 $($file.Name) - $Size MB"
}

# 检查 Git 状态
Write-Host ""
Write-Info "[检查] 验证 Git 状态..."

$Status = git status --porcelain
if ($Status) {
    Write-Warning "  ⚠ 有未提交的更改"
    Write-Host $Status
    $Confirm = Read-Host "是否继续发布？(y/N)"
    if ($Confirm -ne 'y' -and $Confirm -ne 'Y') {
        Write-Info "发布已取消"
        exit 0
    }
}

# 创建标签
Write-Host ""
Write-Info "[1/4] 创建 Git 标签..."

$ExistingTag = git tag -l $TagVersion
if ($ExistingTag) {
    Write-Warning "  ⚠ 标签 $TagVersion 已存在"
    $Overwrite = Read-Host "是否覆盖？(y/N)"
    if ($Overwrite -eq 'y' -or $Overwrite -eq 'Y') {
        git tag -d $TagVersion
        git tag $TagVersion -m "Release version $Version"
        Write-Success "  ✓ 标签已更新"
    } else {
        Write-Info "使用现有标签"
    }
} else {
    git tag $TagVersion -m "Release version $Version"
    Write-Success "  ✓ 标签已创建: $TagVersion"
}

# 推送标签
Write-Host ""
Write-Info "[2/4] 推送标签到远程仓库..."

try {
    git push origin $TagVersion 2>&1 | Out-Null
    Write-Success "  ✓ 已推送到 GitHub (origin)"
} catch {
    Write-Warning "  ⚠ 推送到 GitHub 失败，尝试重试..."
    git push origin $TagVersion
}

if (-not $SkipGitee) {
    try {
        git push gitee $TagVersion 2>&1 | Out-Null
        Write-Success "  ✓ 已推送到 Gitee (镜像)"
    } catch {
        Write-Warning "  ⚠ 推送到 Gitee 失败（可忽略）"
    }
}

# 准备 Release Notes
Write-Host ""
Write-Info "[3/4] 创建 GitHub Release..."

if ([string]::IsNullOrEmpty($ReleaseNotes)) {
    $ReleaseNotes = @"
## WPS 公文编辑器 $TagVersion

### 📦 下载说明

- **$($ZipFiles[0].Name)** - Windows 64位免安装版

### 🚀 使用方法

1. 下载 zip 文件
2. 解压到任意目录（建议：`C:\Program Files\WpsDocEditor`）
3. 双击运行 `WpsDocEditor.exe`
4. 首次启动可能需要等待 10-20 秒初始化

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
    
    Write-Success "  ✓ Release 已创建: $ReleaseUrl"
} catch {
    Write-Error "错误: 创建 Release 失败"
    Write-Host $_.Exception.Message
    exit 1
}

# 上传构建产物
Write-Host ""
Write-Info "[4/4] 上传构建产物..."

foreach ($file in $ZipFiles) {
    Write-Info "  上传 $($file.Name)..."
    try {
        gh release upload $TagVersion $file.FullName --clobber 2>&1 | Out-Null
        Write-Success "  ✓ 上传成功: $($file.Name)"
    } catch {
        Write-Error "  ✗ 上传失败: $($file.Name)"
        Write-Host $_.Exception.Message
    }
}

# 显示结果
Write-Host ""
Write-Info "====================================="
Write-Success "  发布完成！🎉"
Write-Info "====================================="
Write-Host ""
Write-Success "GitHub Release 地址:"
Write-Host "  https://github.com/wkhuahuo/formatter/releases/tag/$TagVersion"
Write-Host ""

if (-not $SkipGitee) {
    Write-Info "Gitee Release 地址（需要手动同步）:"
    Write-Host "  https://gitee.com/wkhuahuo/latexOnline/releases/new"
    Write-Host ""
    Write-Warning "提示: 请手动下载构建产物并上传到 Gitee Release"
    Write-Host ""
}

Write-Info "构建产物位置:"
foreach ($file in $ZipFiles) {
    Write-Host "  📦 $($file.FullName)"
}

Write-Host ""
Write-Info "下一步:"
Write-Host "  1. 测试下载的应用程序"
Write-Host "  2. 更新文档（如需要）"
Write-Host "  3. 通知团队成员和用户"
Write-Host ""
