# WPS 公文编辑器 - 发布指南

本文档说明如何使用 GitHub Actions 自动构建和发布 Electron 应用。

## 前置要求

### 1. 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `latexOnline`（或其他名称）
   - **Description**: WPS 公文编辑器桌面版
   - **Visibility**: Public（公开，便于下载）
3. 点击 "Create repository"

### 2. 配置远程仓库

在本地项目中添加 GitHub 远程仓库：

```bash
# 添加 GitHub 远程仓库（替换为你的用户名和仓库名）
git remote add github https://github.com/YOUR_USERNAME/latexOnline.git

# 查看远程仓库配置
git remote -v
```

### 3. 配置 Gitee 镜像同步（可选）

如果你想在 Gitee 也提供下载，可以：

**方案 A：手动上传到 Gitee**
1. 在 GitHub Release 页面下载构建产物
2. 在 Gitee 仓库创建 Release
3. 手动上传相同的文件

**方案 B：配置 Gitee 自动同步**
1. 访问 https://gitee.com/mirrors
2. 导入 GitHub 仓库
3. 配置自动同步

## 发布流程

### 自动发布（推荐）

#### 1. 更新版本号

```bash
# 更新 package.json 中的版本号
npm version patch  # 补丁版本：1.0.0 -> 1.0.1
npm version minor  # 次要版本：1.0.0 -> 1.1.0
npm version major  # 主要版本：1.0.0 -> 2.0.0
```

#### 2. 推送代码到 GitHub

```bash
# 推送到 GitHub 主分支
git push github main

# 或者如果你使用 master 分支
git push github master
```

#### 3. 创建并推送版本标签

```bash
# 创建版本标签（例如 v1.0.0）
git tag v1.0.0

# 推送标签到 GitHub
git push github v1.0.0
```

#### 4. 等待自动构建

推送标签后，GitHub Actions 会自动：
- 构建前端和后端
- 打包 Electron 应用
- 创建 Release
- 上传构建产物

你可以在 https://github.com/YOUR_USERNAME/latexOnline/actions 查看构建进度。

### 手动发布

如果需要手动构建和发布：

```bash
# 1. 运行构建脚本
./scripts/build.sh

# 或者在 PowerShell 中
scripts\build.sh

# 2. 构建产物在 release/ 目录下
# 3. 手动上传到 GitHub Release 页面
```

## 在 Gitee 提供下载

### 方法 1：创建 Gitee Release

1. 访问你的 Gitee 仓库：https://gitee.com/wkhuahuo/latexOnline
2. 进入 "发行版" 页面
3. 点击 "创建发行版"
4. 填写版本信息
5. 上传从 GitHub Release 下载的构建产物
6. 点击 "创建"

### 方法 2：使用 Gitee 镜像

1. 访问 https://gitee.com/mirrors
2. 点击 "导入仓库"
3. 选择 GitHub 仓库
4. 配置同步策略
5. 在 Gitee 仓库中创建 Release

## 版本标签规范

- 格式：`vX.Y.Z`（例如：v1.0.0, v1.1.0, v2.0.0）
- X：主版本号（重大更新）
- Y：次版本号（功能更新）
- Z：修订号（Bug 修复）

## 构建产物说明

每次发布会自动生成以下文件：

- `WpsDocEditor-X.Y.Z-win.zip` - Windows 64位免安装版

## 常见问题

### Q: 构建失败怎么办？

A: 检查 GitHub Actions 日志，常见原因：
- Node.js 版本不兼容
- Maven 依赖下载失败
- 代码编译错误

### Q: 如何修改 Release 说明？

A: 在 GitHub Release 页面点击编辑按钮即可修改。

### Q: 可以同时发布到多个平台吗？

A: 可以，但需要分别配置。GitHub Actions 会自动发布到 GitHub，Gitee 需要手动或配置镜像同步。

### Q: 如何回滚版本？

A: 
1. 在 GitHub Release 页面删除错误的 Release
2. 删除本地和远程标签
3. 修复问题后重新创建标签

```bash
# 删除本地标签
git tag -d v1.0.0

# 删除远程标签
git push github :refs/tags/v1.0.0
```

## 配置 GitHub Token（高级）

如果需要更精细的权限控制：

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 选择权限范围：`repo`（完整仓库访问）
4. 生成 token 并复制
5. 在仓库 Settings -> Secrets and variables -> Actions 中添加
6. 名称必须是 `GITHUB_TOKEN`（工作流已使用此名称）

## 下一步

1. 创建 GitHub 仓库
2. 配置远程仓库
3. 推送代码和标签
4. 在 Gitee 创建镜像或手动同步

祝你发布顺利！🎉
