# 用 jlink 生成一个可随包分发的精简 Java 运行时。
# 模块说明：
#   java.se         Spring Boot / Tomcat / POI 主体所需（含 java.xml、java.desktop、java.sql 等）
#   jdk.unsupported 部分库依赖 sun.misc.Unsafe
#   jdk.crypto.ec   TLS/HTTPS
#   jdk.xml.dom     XMLBeans（poi-ooxml 依赖）

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Out = Join-Path $Root "electron\resources\jre"

# 查找 jlink
$Jlink = $null
if ($env:JAVA_HOME) {
    $candidate = Join-Path $env:JAVA_HOME "bin\jlink.exe"
    if (Test-Path $candidate) { $Jlink = $candidate }
}
if (-not $Jlink) {
    $found = Get-Command jlink -ErrorAction SilentlyContinue
    if ($found) { $Jlink = $found.Source }
}
if (-not $Jlink) {
    Write-Host "[JRE] 错误：未找到 jlink，请安装 JDK 17+ 或设置 JAVA_HOME" -ForegroundColor Red
    exit 1
}

$Jdk = Split-Path (Split-Path $Jlink)
Write-Host "[JRE] 使用 JDK: $Jdk" -ForegroundColor Cyan

# 清理旧输出
if (Test-Path $Out) {
    Remove-Item -Recurse -Force $Out
}

Write-Host "[JRE] 正在生成精简运行时..." -ForegroundColor Yellow

$jlinkArgs = @(
    "--module-path", "$Jdk\jmods",
    "--add-modules", "java.se,jdk.unsupported,jdk.crypto.ec,jdk.xml.dom",
    "--strip-debug", "--no-man-pages", "--no-header-files",
    "--output", $Out
)

& $Jlink @jlinkArgs 2>&1

if ($LASTEXITCODE -eq 0) {
    $size = (Get-ChildItem $Out -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "[JRE] 精简运行时已生成: $Out ($([math]::Round($size, 1)) MB)" -ForegroundColor Green
} else {
    Write-Host "[JRE] 警告：jlink 失败，回退为拷贝完整 JDK" -ForegroundColor Yellow
    if (Test-Path $Out) { Remove-Item -Recurse -Force $Out }
    Copy-Item -Recurse $Jdk $Out
    $size = (Get-ChildItem $Out -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "[JRE] 已拷贝完整 JDK: $Out ($([math]::Round($size, 1)) MB)" -ForegroundColor Yellow
}
