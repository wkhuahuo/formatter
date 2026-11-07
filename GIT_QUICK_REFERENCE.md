# Git 分支管理 - 快速参考

## 🌳 分支结构

```
master (稳定版本，跟踪最终发布)
  ↑
  └── release-X.Y.Z (发布准备分支)
        ↑
        └── feature-xxx (功能开发分支)
```

## 📝 分支命名规范

| 类型 | 格式 | 示例 |
|------|------|------|
| 主分支 | `master` | `master` |
| 发布分支 | `release-X.Y.Z` | `release-1.0.0` |
| 功能分支 | `feature-功能名` | `feature-dark-mode` |
| 修复分支 | `hotfix-X.Y.Z` | `hotfix-1.0.1` |

## 🚀 常用操作

### 1. 开发新功能

```bash
# 创建功能分支
git checkout master
git checkout -b feature-xxx

# 开发和提交
git add .
git commit -m "feat: 添加新功能"

# 推送到远程
git push origin feature-xxx
```

### 2. 发布新版本

```bash
# 创建发布分支
git checkout master
git checkout -b release-1.0.0

# 更新版本号
npm version patch  # 或 minor, major

# 提交更改
git add .
git commit -m "chore: bump version to 1.0.0"

# 创建标签
git tag v1.0.0 -m "Release version 1.0.0"

# 合并到 master
git checkout master
git merge release-1.0.0

# 推送
git push origin master
git push origin v1.0.0
git push github master
git push github v1.0.0
```

### 3. 紧急修复

```bash
# 创建修复分支
git checkout master
git checkout -b hotfix-1.0.1

# 修复问题
git add .
git commit -m "fix: 修复紧急问题"

# 更新版本号
npm version patch

# 创建标签
git tag v1.0.1

# 合并到 master
git checkout master
git merge hotfix-1.0.1

# 推送
git push origin master
git push origin v1.0.1
```

## 🏷️ 标签操作

```bash
# 创建标签
git tag vX.Y.Z -m "Release version X.Y.Z"

# 查看标签
git tag -l

# 推送标签
git push origin vX.Y.Z
git push github vX.Y.Z

# 删除标签
git tag -d vX.Y.Z              # 本地
git push origin :refs/tags/vX.Y.Z   # 远程
```

## 📊 提交信息规范

```
<type>(<scope>): <subject>

类型：
- feat: 新功能
- fix: 修复 Bug
- docs: 文档更新
- style: 代码格式
- refactor: 重构
- test: 测试
- chore: 构建/工具
```

## 🔄 同步操作

```bash
# 推送到所有远程仓库
git push origin master
git push github master

# 推送所有分支
git push origin --all
git push github --all

# 推送所有标签
git push origin --tags
git push github --tags
```

## 🧹 清理分支

```bash
# 删除本地分支
git branch -d feature-xxx

# 删除远程分支
git push origin :feature-xxx

# 查看已删除的分支
git remote prune origin
```

## 📖 查看历史

```bash
# 查看提交历史
git log --oneline --graph --all

# 查看分支差异
git diff master..feature-xxx

# 查看标签
git show v1.0.0
```

## ⚡ 快速发布命令

```powershell
# 使用发布脚本（推荐）
.\scripts\publish.ps1 -Version "1.0.0"

# 或手动发布
npm version patch
git tag v1.0.1
git push origin master
git push origin v1.0.1
```

## 🎯 分支保护规则

### master 分支
- ❌ 禁止直接提交
- ✅ 必须通过 Pull Request
- ✅ 需要代码审查
- ✅ CI/CD 必须通过

### release 分支
- ⚠️ 只允许 Bug 修复
- ❌ 不允许新功能
- ✅ 必须测试通过

## 📚 详细文档

查看完整文档：[BRANCH_STRATEGY.md](./BRANCH_STRATEGY.md)

---

**提示**：将此文档保存为常用参考，团队所有成员应遵循此规范。
