# 发布检查清单

使用此清单确保每次发布都遵循正确的流程。

## 📋 发布前准备

### 代码检查
- [ ] 所有功能已开发完成
- [ ] 代码已通过审查
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] CHANGELOG.md 已更新（如有）

### 版本号确认
- [ ] 确定版本号类型（patch/minor/major）
- [ ] 版本号符合语义化版本规范（X.Y.Z）
- [ ] 与团队确认版本号

## 🚀 发布流程

### 步骤 1：创建发布分支

```bash
# 从 master 创建 release 分支
git checkout master
git pull origin master
git checkout -b release-X.Y.Z
```

- [ ] 已创建 release-X.Y.Z 分支
- [ ] 分支命名正确

### 步骤 2：更新版本号和文档

```bash
# 更新 package.json 版本号
npm version patch  # 或 minor, major

# 更新相关文档
# - README.md
# - CHANGELOG.md
# - RELEASE_NOTES.md
```

- [ ] package.json 版本号已更新
- [ ] 文档已更新
- [ ] 版本号一致

### 步骤 3：构建和测试

```bash
# 构建应用
.\scripts\build.ps1

# 测试构建产物
# - 运行应用
# - 检查功能
# - 验证性能
```

- [ ] 构建成功
- [ ] 本地测试通过
- [ ] 构建产物已验证

### 步骤 4：提交更改

```bash
git add .
git commit -m "chore: bump version to X.Y.Z"
```

- [ ] 所有更改已提交
- [ ] 提交信息规范

### 步骤 5：创建版本标签

```bash
git tag vX.Y.Z -m "Release version X.Y.Z"
```

- [ ] 标签已创建
- [ ] 标签格式正确（vX.Y.Z）
- [ ] 标签说明完整

### 步骤 6：合并到 master

```bash
git checkout master
git merge release-X.Y.Z
```

- [ ] 已合并到 master
- [ ] 无合并冲突
- [ ] master 分支稳定

### 步骤 7：推送到远程仓库

```bash
# 推送代码到 Gitee
git push origin master
git push origin vX.Y.Z

# 推送代码到 GitHub
git push github master
git push github vX.Y.Z
```

- [ ] Gitee 推送成功
- [ ] GitHub 推送成功（如网络允许）
- [ ] 标签已推送

### 步骤 8：验证 GitHub Actions

```bash
# 访问 GitHub Actions 查看构建
# https://github.com/YOUR_USERNAME/formatter/actions
```

- [ ] GitHub Actions 触发成功
- [ ] 构建进度正常
- [ ] 构建成功完成

### 步骤 9：检查 GitHub Release

```bash
# 访问 Release 页面
# https://github.com/YOUR_USERNAME/formatter/releases/tag/vX.Y.Z
```

- [ ] Release 已创建
- [ ] 构建产物已上传
- [ ] Release 说明完整

### 步骤 10：同步到 Gitee Release（可选）

```bash
# 从 GitHub 下载构建产物
# 上传到 Gitee Release

# 或使用脚本
.\scripts\upload-to-gitee.ps1 -Version "X.Y.Z" -Token "YOUR_TOKEN"
```

- [ ] Gitee Release 已创建
- [ ] 构建产物已上传
- [ ] 下载链接有效

## ✅ 发布后验证

### 功能验证
- [ ] 下载构建产物
- [ ] 解压并运行应用
- [ ] 核心功能正常
- [ ] 无严重 Bug

### 文档验证
- [ ] README 链接有效
- [ ] 下载说明清晰
- [ ] 版本历史更新

### 通知相关方
- [ ] 通知团队成员
- [ ] 更新项目文档
- [ ] 发布通知（如需要）

## 🧹 清理工作

### 删除发布分支

```bash
# 删除本地分支
git branch -d release-X.Y.Z

# 删除远程分支（如已推送）
git push origin :release-X.Y.Z
```

- [ ] 发布分支已删除
- [ ] 仓库整洁

## 📊 发布记录

记录发布信息：

- **版本号**: v____
- **发布日期**: ____-__-__
- **发布说明**: 
  - 
  - 
  - 
- **构建产物**:
  - [ ] Windows 版本
  - [ ] macOS 版本（如有）
  - [ ] Linux 版本（如有）
- **已知问题**:
  - 
  - 

## ⚠️ 问题处理

### 如果构建失败

1. 检查 GitHub Actions 日志
2. 定位问题原因
3. 修复问题
4. 重新创建发布分支
5. 重新执行发布流程

### 如果发现严重 Bug

1. 创建 hotfix 分支
2. 修复 Bug
3. 更新版本号（Z+1）
4. 重新执行发布流程
5. 通知用户更新

## 📚 相关文档

- [分支管理策略](./BRANCH_STRATEGY.md)
- [快速参考](./GIT_QUICK_REFERENCE.md)
- [发布快速开始](./PUBLISH_QUICKSTART.md)
- [详细发布指南](./RELEASE_GUIDE.md)

## 🎯 发布模板

### 标准发布命令序列

```bash
# 1. 创建发布分支
git checkout master
git pull origin master
git checkout -b release-1.0.0

# 2. 更新版本号
npm version patch

# 3. 构建和测试
.\scripts\build.ps1

# 4. 提交更改
git add .
git commit -m "chore: bump version to 1.0.1"

# 5. 创建标签
git tag v1.0.1 -m "Release version 1.0.1"

# 6. 合并到 master
git checkout master
git merge release-1.0.0

# 7. 推送到远程
git push origin master
git push origin v1.0.1
git push github master
git push github v1.0.1

# 8. 清理分支
git branch -d release-1.0.0
```

---

**使用提示**：
- 打印此清单或保存在常用位置
- 每次发布时逐项检查
- 发现问题及时记录和处理
- 持续优化发布流程

**最后更新**: 2026-11-07
