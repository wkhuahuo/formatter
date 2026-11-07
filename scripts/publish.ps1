# WPS 公文编辑器 - 发布脚本
# 用法: .\scripts\publish.ps1 -Version "1.0.0"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [string]$RemoteName = "origin",  # GitHub 作为主仓库
    
    [switch]$SkipBuild,
    
    [switch]$SyncToGitee = $true  # 默认同步到 Gitee 镜像
)

$ErrorActionPreference = "Stop"

# 验证版本号格式
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "错误: 版本号格式不正确，应为 X.Y.Z（例如：1.0.0）" -ForegroundColor Red
    exit 1
}

$TagVersion = "v$Version"

Write-Host "=============== WPS 公文编辑器 发布 ===============" -ForegroundColor Cyan
Write-Host "版本号: $TagVersion" -ForegroundColor Yellow
Write-Host "主仓库: $RemoteName (GitHub)" -ForegroundColor Yellow
if ($SyncToGitee) {
    Write-Host "镜像仓库: gitee (Gitee)" -ForegroundColor Yellow
}

# 检查远程仓库是否存在
$Remotes = git remote -v
if (-not ($Remotes | Select-String $RemoteName)) {
    Write-Host "错误: 未找到名为 '$RemoteName' 的远程仓库" -ForegroundColor Red
    Write-Host "当前远程仓库:" -ForegroundColor Yellow
    Write-Host $Remotes
    Write-Host "`n提示: 使用 'git remote add origin https://github.com/YOUR_USERNAME/latexOnline.git' 添加" -ForegroundColor Yellow
    exit 1
}

# 检查是否有未提交的更改
$Status = git status --porcelain
if ($Status) {
    Write-Host "`n警告: 有未提交的更改" -ForegroundColor Yellow
    Write-Host $Status
    $Confirm = Read-Host "是否继续发布？(y/N)"
    if ($Confirm -ne 'y' -and $Confirm -ne 'Y') {
        Write-Host "发布已取消" -ForegroundColor Yellow
        exit 0
    }
}

# 更新 package.json 版本号
Write-Host "`n[1/4] 更新版本号..." -ForegroundColor Yellow
$PackageJsonPath = "package.json"
$PackageJson = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
$PackageJson.version = $Version
$PackageJson | ConvertTo-Json -Depth 100 | Set-Content $PackageJsonPath -Encoding UTF8
Write-Host "      已更新 package.json 版本号为 $Version" -ForegroundColor Green

# 构建（可选）
if (-not $SkipBuild) {
    Write-Host "`n[2/4] 执行构建..." -ForegroundColor Yellow
    & "$PSScriptRoot\build.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 构建失败" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[2/4] 跳过构建（使用 -SkipBuild 参数）" -ForegroundColor Yellow
}

# 提交更改
Write-Host "`n[3/4] 提交更改..." -ForegroundColor Yellow
git add package.json
git commit -m "chore: bump version to $Version"
Write-Host "      已提交版本更新" -ForegroundColor Green

# 创建并推送标签
Write-Host "`n[4/5] 创建标签..." -ForegroundColor Yellow
git tag $TagVersion
Write-Host "      已创建标签 $TagVersion" -ForegroundColor Green

# 推送到 GitHub（主仓库）
Write-Host "`n[5/5] 推送到远程仓库..." -ForegroundColor Yellow
Write-Host "      推送到 GitHub ($RemoteName)..." -ForegroundColor White
$CurrentBranch = git rev-parse --abbrev-ref HEAD
git push $RemoteName $CurrentBranch
git push $RemoteName $TagVersion
Write-Host "      ✅ 已推送到 GitHub" -ForegroundColor Green

# 推送到 Gitee（镜像仓库）
if ($SyncToGitee) {
    Write-Host "      同步到 Gitee (gitee)..." -ForegroundColor White
    git push gitee $CurrentBranch 2>&1 | Out-Null
    git push gitee $TagVersion 2>&1 | Out-Null
    Write-Host "      ✅ 已同步到 Gitee" -ForegroundColor Green
}

Write-Host "`n=============== 发布完成 ===============" -ForegroundColor Green
Write-Host "`n后续步骤:" -ForegroundColor Cyan
Write-Host "1. 访问 GitHub Actions 查看构建进度:" -ForegroundColor Yellow
Write-Host "   https://github.com/wkhuahuo/formatter/actions" -ForegroundColor White
Write-Host "`n2. 构建完成后，在 GitHub Release 页面查看:" -ForegroundColor Yellow
Write-Host "   https://github.com/wkhuahuo/formatter/releases/tag/$TagVersion" -ForegroundColor White
Write-Host "`n3. 下载构建产物并上传到 Gitee Release 页面:" -ForegroundColor Yellow
Write-Host "   https://gitee.com/wkhuahuo/latexOnline/releases/new" -ForegroundColor White
Write-Host "`n提示: 使用以下命令查看构建产物" -ForegroundColor Cyan
Write-Host "   Get-ChildItem release\*.zip" -ForegroundColor White
