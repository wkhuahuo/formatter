# 🚀 一键发布和部署指南

本指南帮助你快速构建和发布 WPS 公文编辑器桌面应用。

## 📦 脚本清单

| 脚本 | 功能 | 使用场景 |
|------|------|---------|
| **`publish-all.ps1`** | 一键构建 + 发布（推荐） | 完整发布流程 |
| **`build-package.ps1`** | 仅构建和打包 | 只需要构建产物 |
| **`release-deploy.ps1`** | 仅发布到 GitHub Release | 已有构建产物，只需发布 |

## 🎯 快速开始

### 方式一：一键发布（最简单）⭐

```powershell
# 执行一键发布
.\scripts\publish-all.ps1 -Version "1.0.0"
```

**这个脚本会自动完成**：
1. ✅ 检查所有依赖工具
2. ✅ 构建前端和后端
3. ✅ 打包 Electron 应用
4. ✅ 创建 Git 标签
5. ✅ 推送标签到 GitHub 和 Gitee
6. ✅ 创建 GitHub Release
7. ✅ 上传构建产物

**完成后你会得到**：
- 📦 构建好的桌面应用包
- 🎉 GitHub Release 页面已创建
- 🏷️ Git 标签已标记

### 方式二：分步执行

#### 步骤 1：仅构建

```powershell
# 构建应用包（不发布）
.\scripts\build-package.ps1 -Version "1.0.0"

# 或清理后重新构建
.\scripts\build-package.ps1 -Version "1.0.0" -Clean
```

**输出**：`release/WpsDocEditor-1.0.0-win.zip`

#### 步骤 2：仅发布

```powershell
# 发布到 GitHub Release
.\scripts\release-deploy.ps1 -Version "1.0.0"

# 或先构建再发布
.\scripts\release-deploy.ps1 -Version "1.0.0" -BuildFirst
```

## 📋 前置要求

### 必需工具

| 工具 | 安装方式 | 用途 |
|------|---------|------|
| **Node.js** | https://nodejs.org/ | 前端构建 |
| **Java 17+** | https://adoptium.net/ | 后端编译 |
| **Maven** | https://maven.apache.org/ | 后端构建 |
| **Git** | https://git-scm.com/ | 版本控制 |
| **GitHub CLI** | `winget install GitHub.cli` | 创建 Release |

### 安装 GitHub CLI

```powershell
# Windows
winget install GitHub.cli

# 或下载安装程序
# https://cli.github.com/

# 验证安装
gh --version

# 登录认证
gh auth login
```

## 🔧 常用参数

### publish-all.ps1

```powershell
# 基本用法
.\scripts\publish-all.ps1 -Version "1.0.0"

# 跳过构建（使用现有产物）
.\scripts\publish-all.ps1 -Version "1.0.0" -SkipBuild

# 清理后构建
.\scripts\publish-all.ps1 -Version "1.0.0" -Clean

# 不同步到 Gitee
.\scripts\publish-all.ps1 -Version "1.0.0" -SkipGitee

# 自定义 Release 说明
.\scripts\publish-all.ps1 -Version "1.0.0" -ReleaseNotes "修复了XXX问题"
```

### build-package.ps1

```powershell
# 基本构建
.\scripts\build-package.ps1

# 指定版本号
.\scripts\build-package.ps1 -Version "1.0.0"

# 清理后构建
.\scripts\build-package.ps1 -Clean

# 跳过 JRE 检查
.\scripts\build-package.ps1 -SkipJRE
```

### release-deploy.ps1

```powershell
# 发布现有产物
.\scripts\release-deploy.ps1 -Version "1.0.0"

# 先构建再发布
.\scripts\release-deploy.ps1 -Version "1.0.0" -BuildFirst

# 不同步到 Gitee
.\scripts\release-deploy.ps1 -Version "1.0.0" -SkipGitee
```

## 📊 完整发布流程示例

### 场景 1：首次发布 v1.0.0

```powershell
# 1. 确保所有代码已提交
git add .
git commit -m "准备发布 v1.0.0"

# 2. 一键发布
.\scripts\publish-all.ps1 -Version "1.0.0"

# 3. 等待完成（约 10-15 分钟）
# 脚本会自动：
# - 构建应用
# - 创建标签
# - 推送到 GitHub
# - 创建 Release
# - 上传文件

# 4. 手动同步到 Gitee（可选）
# 访问 GitHub Release 下载文件
# 然后上传到 Gitee Release 页面
```

### 场景 2：快速修复发布 v1.0.1

```powershell
# 1. 修复问题后
git add .
git commit -m "fix: 修复XXX问题"

# 2. 快速发布（跳过构建，使用现有产物）
.\scripts\publish-all.ps1 -Version "1.0.1" -SkipBuild

# 或完整流程
.\scripts\publish-all.ps1 -Version "1.0.1"
```

### 场景 3：只构建不发布

```powershell
# 构建应用包
.\scripts\build-package.ps1 -Version "1.0.0"

# 测试构建产物
Expand-Archive release\WpsDocEditor-1.0.0-win.zip -DestinationPath test
.\test\WpsDocEditor.exe

# 确认无误后再发布
.\scripts\release-deploy.ps1 -Version "1.0.0"
```

## ⚠️ 常见问题

### Q1: GitHub CLI 未安装

**解决方案**：
```powershell
# 安装 GitHub CLI
winget install GitHub.cli

# 或手动下载
# https://cli.github.com/

# 登录后重试
gh auth login
```

### Q2: 构建失败

**检查清单**：
- ✅ Node.js 已安装（`node --version`）
- ✅ Java 已安装（`java -version`）
- ✅ Maven 已安装（`mvn -version`）
- ✅ 网络连接正常
- ✅ 磁盘空间充足（至少 2GB）

**解决方案**：
```powershell
# 清理后重新构建
.\scripts\build-package.ps1 -Version "1.0.0" -Clean
```

### Q3: 推送标签失败

**可能原因**：
- 网络连接问题
- GitHub 认证问题
- 标签已存在

**解决方案**：
```powershell
# 检查认证
gh auth status

# 重新登录
gh auth login

# 如果标签已存在，使用新版本号
.\scripts\publish-all.ps1 -Version "1.0.1"
```

### Q4: 上传文件失败

**可能原因**：
- 文件过大（GitHub 限制 2GB）
- 网络不稳定

**解决方案**：
```powershell
# 手动上传
# 1. 访问 GitHub Release 页面
# 2. 点击 "Edit" 按钮
# 3. 拖拽文件上传

# 或使用 GitHub CLI
gh release upload v1.0.0 release/*.zip --clobber
```

### Q5: 如何修改 Release 说明？

**解决方案**：
```powershell
# 方式 1：在网页上编辑
# 访问: https://github.com/wkhuahuo/formatter/releases/tag/v1.0.0
# 点击 "Edit release notes"

# 方式 2：使用 GitHub CLI
gh release edit v1.0.0 --notes "新的说明内容"
```

## 🎯 最佳实践

### ✅ 推荐做法

1. **发布前测试**
   ```powershell
   # 先构建测试
   .\scripts\build-package.ps1 -Version "1.0.0"
   
   # 测试应用
   .\release\WpsDocEditor-1.0.0-win.zip
   
   # 确认无误后再发布
   .\scripts\release-deploy.ps1 -Version "1.0.0"
   ```

2. **使用语义化版本**
   - `1.0.0` → `1.0.1`：修复 Bug
   - `1.0.0` → `1.1.0`：新增功能
   - `1.0.0` → `2.0.0`：重大更新

3. **编写详细的 Release Notes**
   ```powershell
   $notes = @"
   ## 新功能
   - 添加了XXX功能
   - 支持XXX格式
   
   ## 修复问题
   - 修复了XXX导致的崩溃
   - 解决了XXX的显示问题
   
   ## 改进优化
   - 提升了XXX性能
   - 优化了XXX体验
   "@
   
   .\scripts\publish-all.ps1 -Version "1.0.0" -ReleaseNotes $notes
   ```

4. **保持代码整洁**
   ```powershell
   # 发布前清理
   git add .
   git commit -m "准备发布 v1.0.0"
   git push origin main
   ```

### ❌ 避免做法

1. 不要在未测试的情况下直接发布
2. 不要忘记更新版本号
3. 不要在网络不稳定时发布
4. 不要跳过 Git 标签

## 📚 相关文档

- [构建指南](./BUILD_GUIDE.md)
- [分支管理策略](./BRANCH_STRATEGY.md)
- [发布检查清单](./RELEASE_CHECKLIST.md)
- [跨平台脚本使用](./CROSS_PLATFORM_SCRIPTS.md)

## 🔗 快速链接

- **GitHub 仓库**: https://github.com/wkhuahuo/formatter
- **Gitee 仓库**: https://gitee.com/wkhuahuo/latexOnline
- **GitHub Releases**: https://github.com/wkhuahuo/formatter/releases
- **Gitee Releases**: https://gitee.com/wkhuahuo/latexOnline/releases

## 💡 提示

### 查看构建历史

```powershell
# 查看所有标签
git tag -l

# 查看特定标签详情
git show v1.0.0

# 查看发布历史
gh release list
```

### 回滚发布

```powershell
# 1. 删除 GitHub Release
gh release delete v1.0.0

# 2. 删除本地标签
git tag -d v1.0.0

# 3. 删除远程标签
git push origin :refs/tags/v1.0.0

# 4. 修复问题后重新发布
```

### 批量操作

```powershell
# 推送所有标签
git push origin --tags
git push gitee --tags

# 推送所有分支
git push origin --all
git push gitee --all
```

---

## 🎉 开始发布

现在你已经了解了所有发布方式，选择最适合你的：

### 最简单（推荐）
```powershell
.\scripts\publish-all.ps1 -Version "1.0.0"
```

### 最灵活
```powershell
# 分步执行，每步都可自定义
.\scripts\build-package.ps1 -Version "1.0.0"
# ... 测试 ...
.\scripts\release-deploy.ps1 -Version "1.0.0"
```

**祝你发布顺利！** 🚀
