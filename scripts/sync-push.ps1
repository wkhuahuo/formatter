# Git 同步脚本 - 推送到所有远程仓库
# 用法: .\scripts\sync-push.ps1

param(
    [string]$Branch = "",
    [switch]$IncludeTags = $true,
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Git 同步推送 - GitHub & Gitee" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor Cyan

# 获取当前分支
if ([string]::IsNullOrEmpty($Branch)) {
    $Branch = git rev-parse --abbrev-ref HEAD
}

Write-Host "当前分支: $Branch" -ForegroundColor Yellow
Write-Host "包含标签: $IncludeTags" -ForegroundColor Yellow
Write-Host ""

# 检查是否有未提交的更改
$Status = git status --porcelain
if ($Status) {
    Write-Host "⚠ 警告: 有未提交的更改" -ForegroundColor Yellow
    Write-Host $Status
    $Confirm = Read-Host "是否继续推送？(y/N)"
    if ($Confirm -ne 'y' -and $Confirm -ne 'Y') {
        Write-Host "`n❌ 同步已取消" -ForegroundColor Red
        exit 0
    }
}

# 推送到 GitHub (origin)
Write-Host "`n[1/2] 推送到 GitHub (origin)..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "  [DRY RUN] git push origin $Branch" -ForegroundColor Gray
} else {
    try {
        git push origin $Branch
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ GitHub 推送成功" -ForegroundColor Green
        } else {
            Write-Host "  ❌ GitHub 推送失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ GitHub 推送失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 推送到 Gitee (gitee)
Write-Host "`n[2/2] 推送到 Gitee (gitee)..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "  [DRY RUN] git push gitee $Branch" -ForegroundColor Gray
} else {
    try {
        git push gitee $Branch
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Gitee 推送成功" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Gitee 推送失败或无更改" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ⚠ Gitee 推送失败: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 推送标签
if ($IncludeTags) {
    Write-Host "`n[标签] 推送所有标签..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] git push origin --tags" -ForegroundColor Gray
        Write-Host "  [DRY RUN] git push gitee --tags" -ForegroundColor Gray
    } else {
        # 推送标签到 GitHub
        try {
            git push origin --tags
            Write-Host "  ✅ 标签已推送到 GitHub" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ 标签推送到 GitHub 失败" -ForegroundColor Red
        }
        
        # 推送标签到 Gitee
        try {
            git push gitee --tags
            Write-Host "  ✅ 标签已推送到 Gitee" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ 标签推送到 Gitee 失败" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  同步完成！" -ForegroundColor Green
Write-Host "=====================================`n" -ForegroundColor Cyan

# 显示远程仓库信息
Write-Host "远程仓库:" -ForegroundColor Yellow
Write-Host "  origin (GitHub): https://github.com/wkhuahuo/formatter" -ForegroundColor White
Write-Host "  gitee  (Gitee):  https://gitee.com/wkhuahuo/latexOnline" -ForegroundColor White

Write-Host "`n提示:" -ForegroundColor Cyan
Write-Host "  - 使用 -DryRun 参数预览操作" -ForegroundColor Gray
Write-Host "  - 使用 -Branch <分支名> 推送特定分支" -ForegroundColor Gray
Write-Host "  - 使用 -IncludeTags:`$false 跳过标签推送" -ForegroundColor Gray
