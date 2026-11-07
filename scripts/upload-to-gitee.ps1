# WPS 公文编辑器 - Gitee Release 上传脚本
# 用法: .\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_GITEE_TOKEN"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [string]$Owner = "wkhuahuo",
    
    [string]$Repo = "latexOnline",
    
    [string]$ReleaseDir = "release"
)

$ErrorActionPreference = "Stop"

$TagVersion = "v$Version"

Write-Host "=============== 上传到 Gitee Release ===============" -ForegroundColor Cyan
Write-Host "版本: $TagVersion" -ForegroundColor Yellow
Write-Host "仓库: $Owner/$Repo" -ForegroundColor Yellow

# 检查构建产物
$ZipFiles = Get-ChildItem "$ReleaseDir\*.zip" -ErrorAction SilentlyContinue
if (-not $ZipFiles) {
    Write-Host "错误: 未找到构建产物（*.zip 文件）" -ForegroundColor Red
    Write-Host "提示: 请先运行构建脚本 .\scripts\build.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n找到以下构建产物:" -ForegroundColor Green
$ZipFiles | ForEach-Object {
    Write-Host "  $($_.Name) - $([math]::Round($_.Length / 1MB, 2)) MB" -ForegroundColor White
}

# 准备 Release 内容
$ReleaseBody = @"
## WPS 公文编辑器 $TagVersion

### 下载说明

- **WpsDocEditor-$Version-win.zip** - Windows 64位免安装版

### 使用方法

1. 下载 zip 文件
2. 解压到任意目录
3. 运行 WpsDocEditor.exe

### 系统要求

- Windows 7/8/10/11 (64位)
- 无需安装 Java 或 Node.js（已内置）
"@

# 创建 Release 的 API 请求
$ApiUrl = "https://gitee.com/api/v5/repos/$Owner/$Repo/releases"

# 请求体
$Body = @{
    access_token = $Token
    tag_name = $TagVersion
    name = "WPS 公文编辑器 $TagVersion"
    body = $ReleaseBody
    draft = $false
    prerelease = $false
    target_commitish = "main"
} | ConvertTo-Json

Write-Host "`n[1/2] 创建 Gitee Release..." -ForegroundColor Yellow

try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -ContentType "application/json"
    $ReleaseId = $Response.id
    $ReleaseUrl = $Response.html_url
    Write-Host "      Release 创建成功！" -ForegroundColor Green
    Write-Host "      Release ID: $ReleaseId" -ForegroundColor White
    Write-Host "      URL: $ReleaseUrl" -ForegroundColor White
} catch {
    $ErrorMessage = $_.Exception.Message
    if ($ErrorMessage -match "already exists") {
        Write-Host "警告: Release $TagVersion 已存在" -ForegroundColor Yellow
        Write-Host "尝试获取现有 Release..." -ForegroundColor Yellow
        
        # 获取现有 Release
        try {
            $GetUrl = "https://gitee.com/api/v5/repos/$Owner/$Repo/releases/tags/$TagVersion`?access_token=$Token"
            $ExistingRelease = Invoke-RestMethod -Uri $GetUrl -Method Get
            $ReleaseId = $ExistingRelease.id
            $ReleaseUrl = $ExistingRelease.html_url
            Write-Host "      找到现有 Release ID: $ReleaseId" -ForegroundColor Green
        } catch {
            Write-Host "错误: 无法获取现有 Release" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "错误: 创建 Release 失败" -ForegroundColor Red
        Write-Host $ErrorMessage -ForegroundColor Red
        exit 1
    }
}

# 上传文件
Write-Host "`n[2/2] 上传构建产物..." -ForegroundColor Yellow

foreach ($File in $ZipFiles) {
    $UploadUrl = "https://gitee.com/api/v5/repos/$Owner/$Repo/releases/$ReleaseId/assets"
    
    Write-Host "      上传 $($File.Name)..." -ForegroundColor White
    
    try {
        # 使用 multipart/form-data 上传文件
        $FileBytes = [System.IO.File]::ReadAllBytes($File.FullName)
        $Boundary = [System.Guid]::NewGuid().ToString()
        
        $BodyLines = @(
            "--$Boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"$($File.Name)`"",
            "Content-Type: application/octet-stream",
            "",
            [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($FileBytes),
            "--$Boundary--"
        ) -join "`r`n"
        
        $Headers = @{
            "Authorization" = "token $Token"
        }
        
        $UploadResponse = Invoke-RestMethod -Uri $UploadUrl -Method Post -Body $BodyLines -ContentType "multipart/form-data; boundary=$Boundary" -Headers $Headers
        
        Write-Host "      ✓ $($File.Name) 上传成功" -ForegroundColor Green
    } catch {
        Write-Host "      ✗ $($File.Name) 上传失败" -ForegroundColor Red
        Write-Host "        错误: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=============== 上传完成 ===============" -ForegroundColor Green
Write-Host "`n访问 Gitee Release 页面:" -ForegroundColor Cyan
Write-Host "  $ReleaseUrl" -ForegroundColor White
