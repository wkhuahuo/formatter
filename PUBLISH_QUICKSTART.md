# WPS 公文编辑器 - 发布快速开始

本文档帮助你快速发布 Electron 应用到 GitHub 和 Gitee。

## 📋 前置准备

### 1. 创建 GitHub 仓库

```bash
# 在 GitHub 上创建仓库后，添加远程仓库
git remote add github https://github.com/YOUR_USERNAME/latexOnline.git

# 验证远程仓库配置
git remote -v
```

### 2. 获取 Gitee API Token（用于自动上传）

1. 访问 https://gitee.com/profile/personal_access_tokens
2. 点击 "生成新令牌"
3. 勾选 `projects` 权限
4. 生成并复制 Token（妥善保存）

## 🚀 快速发布（推荐）

### 方式一：使用发布脚本（一键发布）

```powershell
# 在 PowerShell 中运行
.\scripts\publish.ps1 -Version "1.0.0"
```

这个脚本会自动：
- ✅ 更新 package.json 版本号
- ✅ 构建前端和后端
- ✅ 打包 Electron 应用
- ✅ 提交代码并创建标签
- ✅ 推送到 GitHub（触发自动构建）

### 方式二：手动发布

```powershell
# 1. 构建应用
.\scripts\build.ps1

# 2. 更新版本号（可选，脚本会自动更新）
npm version patch  # 或 minor, major

# 3. 创建并推送标签
git tag v1.0.0
git push github main
git push github v1.0.0
```

## 📦 上传到 Gitee

### 方式一：自动上传（使用脚本）

```powershell
# 等待 GitHub Actions 构建完成后，下载产物到 release/ 目录
# 然后运行上传脚本
.\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_GITEE_TOKEN"
```

### 方式二：手动上传

1. 从 GitHub Release 页面下载构建产物
2. 访问 https://gitee.com/wkhuahuo/latexOnline/releases/new
3. 填写版本信息并上传文件

## 🔧 GitHub Actions 自动构建

推送标签后，GitHub Actions 会自动：
1. 构建前端（npm run build）
2. 构建后端（mvn package）
3. 打包 Electron（electron-builder）
4. 创建 Release 并上传产物

**查看构建进度**: https://github.com/YOUR_USERNAME/latexOnline/actions

## 📝 完整发布流程示例

### 首次发布 v1.0.0

```powershell
# 1. 配置远程仓库（如果还没配置）
git remote add github https://github.com/YOUR_USERNAME/latexOnline.git

# 2. 运行发布脚本
.\scripts\publish.ps1 -Version "1.0.0"

# 3. 等待 GitHub Actions 构建完成（约 5-10 分钟）
# 访问: https://github.com/YOUR_USERNAME/latexOnline/actions

# 4. 构建完成后，从 GitHub 下载产物
# 访问: https://github.com/YOUR_USERNAME/latexOnline/releases/tag/v1.0.0
# 下载 WpsDocEditor-1.0.0-win.zip 到 release/ 目录

# 5. 上传到 Gitee
.\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_GITEE_TOKEN"
```

### 后续更新（v1.0.0 -> v1.0.1）

```powershell
# 1. 运行发布脚本
.\scripts\publish.ps1 -Version "1.0.1"

# 2. 等待 GitHub Actions 构建完成

# 3. 下载并上传到 Gitee
.\scripts\upload-to-gitee.ps1 -Version "1.0.1" -Token "YOUR_GITEE_TOKEN"
```

## 🎯 版本号的含义

- **X.Y.Z** 格式（语义化版本）
  - **X（主版本号）**: 不兼容的重大更新
  - **Y（次版本号）**: 向下兼容的功能新增
  - **Z（修订号）**: 向下兼容的问题修正

```bash
npm version patch  # Z+1: 1.0.0 -> 1.0.1
npm version minor  # Y+1: 1.0.0 -> 1.1.0
npm version major  # X+1: 1.0.0 -> 2.0.0
```

## ⚠️ 常见问题

### Q: 推送标签后没有触发构建？

A: 确保：
1. 标签格式正确：`v1.0.0`（必须有 `v` 前缀）
2. GitHub Actions 工作流已推送到仓库
3. 检查 .github/workflows/release.yml 是否存在

### Q: 构建失败怎么办？

A: 
1. 访问 GitHub Actions 页面查看错误日志
2. 常见错误：
   - Maven 依赖下载失败 → 检查网络连接
   - npm 安装失败 → 清除缓存重试
   - 编译错误 → 本地先运行 `.\scripts\build.ps1` 验证

### Q: 如何修改已发布的 Release？

A: 
- **GitHub**: 访问 Release 页面，点击 "编辑" 按钮
- **Gitee**: 访问 Release 页面，点击 "编辑" 按钮

### Q: 如何删除错误的 Release？

A: 
```bash
# 1. 删除 GitHub Release（在网页上操作）
# 访问: https://github.com/YOUR_USERNAME/latexOnline/releases

# 2. 删除本地和远程标签
git tag -d v1.0.0
git push github :refs/tags/v1.0.0

# 3. 修复问题后重新创建
```

### Q: Gitee 上传失败？

A: 检查：
1. Token 是否正确
2. Token 权限是否包含 `projects`
3. 仓库是否存在且有权限
4. 网络连接是否正常

## 📚 相关文档

- [RELEASE_GUIDE.md](./RELEASE_GUIDE.md) - 详细发布指南
- [BUILD.md](./BUILD.md) - 构建说明
- [QUICKSTART.md](./QUICKSTART.md) - 快速开始

## 🔗 快速链接

- GitHub 仓库: https://github.com/YOUR_USERNAME/latexOnline
- Gitee 仓库: https://gitee.com/wkhuahuo/latexOnline
- GitHub Actions: https://github.com/YOUR_USERNAME/latexOnline/actions
- GitHub Releases: https://github.com/YOUR_USERNAME/latexOnline/releases
- Gitee Releases: https://gitee.com/wkhuahuo/latexOnline/releases

---

**提示**: 首次发布前，请将本文档中的 `YOUR_USERNAME` 替换为你的实际 GitHub 用户名。
