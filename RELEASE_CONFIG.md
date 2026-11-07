# GitHub Release 配置总结

本文档总结了为 WPS 公文编辑器项目配置的 GitHub Release 自动构建和发布系统。

## 📦 已创建的文件

### 1. GitHub Actions 工作流
- **文件**: `.github/workflows/release.yml`
- **功能**: 自动构建和发布到 GitHub Release
- **触发条件**: 推送版本标签（如 `v1.0.0`）时自动执行
- **构建产物**: Windows 64位免安装版（zip）

### 2. 构建脚本

#### PowerShell 构建脚本
- **文件**: `scripts/build.ps1`
- **功能**: Windows 环境下的本地构建
- **用法**: `.\scripts\build.ps1`

#### 发布脚本
- **文件**: `scripts/publish.ps1`
- **功能**: 一键发布（更新版本号、构建、提交、打标签、推送）
- **用法**: `.\scripts\publish.ps1 -Version "1.0.0"`

#### Gitee 上传脚本
- **文件**: `scripts/upload-to-gitee.ps1`
- **功能**: 自动上传构建产物到 Gitee Release
- **用法**: `.\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_TOKEN"`

### 3. 文档

#### 发布指南
- **文件**: `RELEASE_GUIDE.md`
- **内容**: 详细的发布流程说明

#### 快速开始
- **文件**: `PUBLISH_QUICKSTART.md`
- **内容**: 快速发布步骤指南

#### 配置总结（本文档）
- **文件**: `RELEASE_CONFIG.md`
- **内容**: 配置概览和快速参考

## 🎯 使用流程

### 快速发布（推荐）

```powershell
# 1. 配置 GitHub 远程仓库（首次使用）
git remote add github https://github.com/YOUR_USERNAME/latexOnline.git

# 2. 运行发布脚本
.\scripts\publish.ps1 -Version "1.0.0"

# 3. 等待 GitHub Actions 构建完成
# 访问: https://github.com/YOUR_USERNAME/latexOnline/actions

# 4. 从 GitHub 下载构建产物到 release/ 目录

# 5. 上传到 Gitee（可选）
.\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_GITEE_TOKEN"
```

### 手动发布

```powershell
# 1. 构建
.\scripts\build.ps1

# 2. 更新版本号
npm version patch  # 或 minor, major

# 3. 推送代码和标签
git push github main
git tag v1.0.0
git push github v1.0.0

# 4. 等待 GitHub Actions 构建完成

# 5. 手动上传到 Gitee
```

## 🔧 GitHub Actions 工作流说明

### 触发条件
- 推送版本标签：`v*`（如 `v1.0.0`, `v1.1.0`）
- 手动触发：通过 GitHub Actions 页面手动运行

### 构建步骤
1. **环境准备**
   - 安装 Node.js 18
   - 安装 Java 17
   - 安装 Maven 3.9.6

2. **构建前端**
   - 安装依赖：`npm install`
   - 构建：`npm run build`

3. **构建后端**
   - 清理打包：`mvn clean package -DskipTests`
   - 复制 JAR：`latex-online-backend-*.jar` → `electron/resources/backend/app.jar`

4. **打包 Electron**
   - 安装依赖：`npm install`
   - 打包：`npx electron-builder --win --x64`

5. **创建 Release**
   - 自动生成版本说明
   - 上传构建产物（*.zip）
   - 保存 30 天供下载

### 构建产物
- **文件名**: `WpsDocEditor-X.Y.Z-win.zip`
- **类型**: Windows 64位免安装版
- **包含**: 应用 + JRE + 前端 + 后端

## 📋 Gitee 同步方案

### 方案 A：手动上传（推荐初期使用）
1. 从 GitHub Release 下载构建产物
2. 在 Gitee 创建 Release
3. 上传相同的文件

**优点**: 简单可靠，无需额外配置
**缺点**: 需要手动操作

### 方案 B：Gitee 镜像同步
1. 访问 https://gitee.com/mirrors
2. 导入 GitHub 仓库
3. 配置自动同步代码
4. Release 仍需手动创建

**优点**: 代码自动同步
**缺点**: Release 需要手动

### 方案 C：使用上传脚本
1. 获取 Gitee API Token
2. 从 GitHub 下载构建产物到本地 `release/` 目录
3. 运行上传脚本

**优点**: 自动化上传
**缺点**: 需要先下载再上传

## ⚙️ 配置详情

### package.json 配置
```json
{
  "build": {
    "appId": "com.latexonline.wpsdoc",
    "productName": "WpsDocEditor",
    "directories": {
      "output": "release"
    },
    "win": {
      "target": ["zip"]
    }
  }
}
```

### 版本管理
- 使用语义化版本（Semantic Versioning）
- 格式：`X.Y.Z`
  - X：主版本号（重大更新）
  - Y：次版本号（功能更新）
  - Z：修订号（Bug 修复）

### 标签规范
- 格式：`vX.Y.Z`（必须有 `v` 前缀）
- 示例：`v1.0.0`, `v1.1.0`, `v2.0.0`

## 🔐 环境变量和密钥

### GitHub Token
- **名称**: `GITHUB_TOKEN`
- **来源**: GitHub Actions 自动提供
- **权限**: 创建 Release 和上传资产

### Gitee Token
- **获取**: https://gitee.com/profile/personal_access_tokens
- **权限**: `projects`
- **用途**: 调用 Gitee API 创建 Release 和上传文件

## 📊 构建时间估算

- **前端构建**: ~1-2 分钟
- **后端构建**: ~1-2 分钟
- **Electron 打包**: ~2-3 分钟
- **总计**: ~5-10 分钟

## ⚠️ 注意事项

### JRE 问题
GitHub Actions 环境中可能没有预构建的 JRE。解决方案：

1. **方案一**（推荐）：在本地构建 JRE 并提交
   ```bash
   ./scripts/build-runtime.sh
   git add electron/resources/jre
   git commit -m "Add JRE"
   git push
   ```

2. **方案二**：修改工作流，使用系统 JRE
   - 需要安装 JDK 并配置 jlink

3. **方案三**：将 JRE 构建步骤加入工作流
   - 增加构建时间约 2-3 分钟

### 大文件问题
- Electron 应用包含 JRE，文件较大（约 200-300 MB）
- GitHub Release 限制单个文件 2GB，总大小 2GB
- Gitee Release 限制单个文件 50MB（需要 LFS 或分卷）

### 网络问题
- GitHub Actions 服务器在国外，构建速度可能较慢
- npm 和 Maven 依赖下载可能需要较长时间
- 建议配置缓存（已配置）

## 🚀 下一步操作

### 1. 创建 GitHub 仓库
- [ ] 访问 https://github.com/new
- [ ] 创建仓库 `latexOnline`
- [ ] 复制仓库地址

### 2. 配置本地仓库
- [ ] 添加 GitHub 远程仓库
  ```bash
  git remote add github https://github.com/YOUR_USERNAME/latexOnline.git
  ```
- [ ] 验证配置
  ```bash
  git remote -v
  ```

### 3. 推送代码
- [ ] 推送主分支
  ```bash
  git push github main
  ```
- [ ] 推送标签（触发构建）
  ```bash
  git tag v1.0.0
  git push github v1.0.0
  ```

### 4. 验证构建
- [ ] 访问 GitHub Actions 查看构建进度
- [ ] 等待构建完成
- [ ] 检查 Release 页面

### 5. 同步到 Gitee（可选）
- [ ] 下载构建产物
- [ ] 创建 Gitee Release
- [ ] 上传文件

## 📚 参考资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [electron-builder 文档](https://www.electron.build/)
- [Gitee API 文档](https://gitee.com/api/v5/swagger)
- [语义化版本规范](https://semver.org/lang/zh-CN/)

## 🆘 获取帮助

遇到问题？检查以下项目：

1. **构建失败**: 查看 GitHub Actions 日志
2. **标签问题**: 确保格式为 `vX.Y.Z`
3. **权限问题**: 检查 Token 权限设置
4. **网络问题**: 确认网络连接正常

---

**最后更新**: 2026-11-07
**配置版本**: v1.0.0
