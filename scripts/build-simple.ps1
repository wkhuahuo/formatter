# WPS Doc Editor - Simple Build Script

param(
    [string]$Version = ""
)

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

# 配置国内镜像（解决 GitHub 下载超时）
$env:ELECTRON_MIRROR = "https://npmmirror.com/mirrors/electron/"
$env:ELECTRON_BUILDER_BINARIES_MIRROR = "https://npmmirror.com/mirrors/electron-builder-binaries/"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  WPS Doc Editor - Build" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Node.js not installed" -ForegroundColor Red
    exit 1
}

# Check Java
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "Java: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Java not installed" -ForegroundColor Red
    exit 1
}

# Read version
if ([string]::IsNullOrEmpty($Version)) {
    $PackageJson = Get-Content "package.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $Version = $PackageJson.version
}
Write-Host "Version: v$Version" -ForegroundColor Cyan

# 1. Build Frontend
Write-Host "`n[1/4] Building Frontend..." -ForegroundColor Yellow
Set-Location "$Root/frontend"
npm install
npm run build

# 2. Build Backend
Write-Host "`n[2/4] Building Backend..." -ForegroundColor Yellow
Set-Location "$Root/backend"
mvn clean package -DskipTests

# 3. Prepare Resources
Write-Host "`n[3/4] Preparing Resources..." -ForegroundColor Yellow
$JarSource = Get-ChildItem "$Root/backend/target/latex-online-backend-*.jar" | Select-Object -First 1
New-Item -ItemType Directory -Force -Path "$Root/electron/resources/backend" | Out-Null
Copy-Item $JarSource.FullName "$Root/electron/resources/backend/app.jar" -Force

# 4. Package Electron
Write-Host "`n[4/4] Packaging Electron..." -ForegroundColor Yellow
Set-Location $Root
npm install
npx electron-builder --win --x64

# Done
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "`nOutput in release/ directory" -ForegroundColor Cyan
