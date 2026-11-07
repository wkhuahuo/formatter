# 跨平台脚本使用指南

本项目提供了适用于不同操作系统的脚本，确保在 Windows、macOS 和 Linux Ubuntu 上都能正常使用。

## 📦 脚本清单

### Windows 脚本（PowerShell）

| 脚本 | 用途 | 用法 |
|------|------|------|
| `scripts/sync-push.ps1` | 同步推送到所有远程仓库 | `.\scripts\sync-push.ps1` |
| `scripts/publish.ps1` | 发布新版本 | `.\scripts\publish.ps1 -Version "1.0.0"` |
| `scripts/build.ps1` | 构建应用 | `.\scripts\build.ps1` |

### macOS/Linux 脚本（Bash）

| 脚本 | 用途 | 用法 |
|------|------|------|
| `scripts/sync-push.sh` | 同步推送到所有远程仓库 | `./scripts/sync-push.sh` |
| `scripts/publish.sh` | 发布新版本 | `./scripts/publish.sh -v 1.0.0` |
| `scripts/build.sh` | 构建应用 | `./scripts/build.sh` |

## 🚀 快速开始

### Windows 用户

```powershell
# 1. 设置执行策略（首次使用需要）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. 赋予脚本执行权限
cd c:\GITProject\latexOnline
.\scripts\sync-push.ps1

# 3. 发布新版本
.\scripts\publish.ps1 -Version "1.0.0"
```

### macOS/Linux 用户

```bash
# 1. 赋予脚本执行权限
cd /path/to/latexOnline
chmod +x scripts/*.sh

# 2. 同步推送
./scripts/sync-push.sh

# 3. 发布新版本
./scripts/publish.sh -v 1.0.0
```

## 📝 详细用法

### 同步脚本（sync-push）

#### Windows
```powershell
# 基本用法
.\scripts\sync-push.ps1

# 预览操作
.\scripts\sync-push.ps1 -DryRun

# 推送特定分支
.\scripts\sync-push.ps1 -Branch "master"

# 不推送标签
.\scripts\sync-push.ps1 -IncludeTags:$false
```

#### macOS/Linux
```bash
# 基本用法
./scripts/sync-push.sh

# 预览操作
./scripts/sync-push.sh --dry-run

# 推送特定分支
./scripts/sync-push.sh -b master

# 不推送标签
./scripts/sync-push.sh --no-tags

# 查看帮助
./scripts/sync-push.sh --help
```

### 发布脚本（publish）

#### Windows
```powershell
# 基本用法
.\scripts\publish.ps1 -Version "1.0.0"

# 跳过构建
.\scripts\publish.ps1 -Version "1.0.0" -SkipBuild

# 不同步到 Gitee
.\scripts\publish.ps1 -Version "1.0.0" -SyncToGitee:$false
```

#### macOS/Linux
```bash
# 基本用法
./scripts/publish.sh -v 1.0.0

# 跳过构建
./scripts/publish.sh -v 1.0.0 --skip-build

# 不同步到 Gitee
./scripts/publish.sh -v 1.0.0 --no-sync-gitee

# 查看帮助
./scripts/publish.sh --help
```

### 构建脚本（build）

#### Windows
```powershell
.\scripts\build.ps1
```

#### macOS/Linux
```bash
./scripts/build.sh
```

## 🔧 环境要求

### Windows
- **PowerShell**: 5.1 或更高版本（Windows 自带）
- **Node.js**: 18 或更高版本
- **Java**: 17 或更高版本
- **Maven**: 3.9.6 或更高版本

### macOS
- **Bash**: 4.0 或更高版本（macOS 自带）
- **Node.js**: 18 或更高版本
- **Java**: 17 或更高版本
- **Maven**: 3.9.6 或更高版本

### Linux Ubuntu
- **Bash**: 4.0 或更高版本
- **Node.js**: 18 或更高版本
- **Java**: 17 或更高版本
- **Maven**: 3.9.6 或更高版本

## 📋 安装依赖

### Windows

```powershell
# 1. 安装 Node.js
# 下载并安装: https://nodejs.org/

# 2. 安装 Java
# 下载并安装: https://adoptium.net/

# 3. 安装 Maven
# 下载并安装: https://maven.apache.org/download.cgi

# 4. 验证安装
node --version
java -version
mvn --version
```

### macOS

```bash
# 使用 Homebrew 安装
brew install node
brew install openjdk@17
brew install maven

# 验证安装
node --version
java -version
mvn --version
```

### Linux Ubuntu

```bash
# 更新包列表
sudo apt update

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 Java
sudo apt install -y openjdk-17-jdk

# 安装 Maven
sudo apt install -y maven

# 验证安装
node --version
java -version
mvn --version
```

## 🎯 跨平台工作流

### 场景 1：团队协作

团队成员使用不同操作系统时：

```bash
# Windows 用户
.\scripts\sync-push.ps1

# macOS/Linux 用户
./scripts/sync-push.sh

# 结果相同：都会推送到 GitHub 和 Gitee
```

### 场景 2：CI/CD 集成

在 GitHub Actions 中使用：

```yaml
# .github/workflows/build.yml
name: Build

on: [push]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [windows-latest, macos-latest, ubuntu-latest]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build (Windows)
        if: runner.os == 'Windows'
        run: .\scripts\build.ps1
        shell: pwsh
      
      - name: Build (macOS/Linux)
        if: runner.os != 'Windows'
        run: ./scripts/build.sh
```

### 场景 3：本地测试

在本地测试跨平台兼容性：

```bash
# 在 Windows 上使用 Git Bash 测试 Bash 脚本
# 安装 Git for Windows: https://git-scm.com/download/win
# 然后在 Git Bash 中运行：
./scripts/sync-push.sh

# 在 macOS/Linux 上测试 PowerShell 脚本
# 安装 PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell
pwsh -File scripts/sync-push.ps1
```

## ⚠️ 常见问题

### Q: Bash 脚本在 Windows 上能运行吗？

**A**: 可以，使用以下方式之一：
1. **Git Bash**（推荐）：随 Git for Windows 安装
2. **WSL**：Windows Subsystem for Linux
3. **Cygwin**：类 Unix 环境

```bash
# 在 Git Bash 中运行
./scripts/sync-push.sh
```

### Q: PowerShell 脚本在 macOS/Linux 上能运行吗？

**A**: 可以，安装 PowerShell Core：

```bash
# macOS
brew install --cask powershell

# Ubuntu
sudo snap install powershell --classic

# 运行脚本
pwsh -File scripts/sync-push.ps1
```

### Q: 如何确保脚本在所有平台上都能执行？

**A**: 
1. 使用正确的行尾符（LF for Bash, CRLF for PowerShell）
2. 设置正确的文件权限（`chmod +x scripts/*.sh`）
3. 使用 `#!/bin/bash` 或 `#!/usr/bin/env bash` 作为 Bash 脚本的第一行
4. 在 PowerShell 脚本中使用 `param()` 定义参数

### Q: 脚本执行权限问题

**A**: 
```bash
# macOS/Linux - 添加执行权限
chmod +x scripts/*.sh

# Windows - 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 📚 脚本对比

| 功能 | PowerShell 版本 | Bash 版本 |
|------|----------------|-----------|
| 参数格式 | `-Parameter "value"` | `--parameter value` 或 `-p value` |
| 颜色输出 | `Write-Host -Color` | ANSI 转义码 |
| 错误处理 | `try-catch` | `set -e` 和 `if` 判断 |
| 用户输入 | `Read-Host` | `read -p` |
| 条件判断 | `if ($var) {}` | `if [ "$var" ]; then fi` |
| 循环 | `foreach ($item in $list)` | `for item in $list; do done` |

## 🔗 相关文档

- [分支管理策略](./BRANCH_STRATEGY.md)
- [主镜像仓库配置](./MIRROR_CONFIG.md)
- [发布检查清单](./RELEASE_CHECKLIST.md)
- [Git 快速参考](./GIT_QUICK_REFERENCE.md)

## 💡 最佳实践

### ✅ 推荐做法

1. **统一使用一种脚本**
   - 团队主要使用 Windows → 统一用 PowerShell
   - 团队主要使用 macOS/Linux → 统一用 Bash
   - 混合团队 → 两种都提供，各自选择

2. **保持脚本同步**
   - 更新一个脚本时，同步更新另一个
   - 确保功能一致
   - 测试跨平台兼容性

3. **文档化**
   - 在脚本中添加注释
   - 提供 `--help` 选项
   - 更新 README 说明

4. **版本控制**
   - 将脚本提交到 Git
   - 使用语义化版本
   - 记录更改历史

### ❌ 避免做法

1. 不要硬编码路径
2. 不要假设特定工具已安装
3. 不要忽略错误处理
4. 不要在不同平台使用不同的逻辑

## 🎉 总结

本项目提供了完整的跨平台脚本支持：

✅ **Windows 用户**：使用 PowerShell 脚本（`.ps1`）  
✅ **macOS/Linux 用户**：使用 Bash 脚本（`.sh`）  
✅ **功能一致**：两种脚本提供相同的功能  
✅ **易于使用**：简单的命令行界面  
✅ **完整文档**：详细的使用说明和示例  

**选择适合你平台的脚本，开始高效的开发工作流吧！** 🚀

---

**最后更新**: 2026-11-07  
**维护者**: 项目团队
