# GitHub 为主仓库，Gitee 为镜像 - 配置指南

本文档说明如何配置和使用"GitHub 作为主开发仓库，Gitee 作为镜像仓库"的开发模式。

## 🎯 模式说明

### 架构设计

```
开发者 → GitHub (origin) → 主仓库，所有开发活动在此
         ↓ (镜像同步)
       Gitee (gitee) → 镜像仓库，提供国内快速访问
```

### 工作流程

1. **开发阶段**：所有开发活动在 GitHub 上进行
2. **代码审查**：Pull Request 在 GitHub 上完成
3. **CI/CD**：GitHub Actions 自动构建和测试
4. **发布版本**：在 GitHub 创建 Release
5. **镜像同步**：自动或手动同步到 Gitee

## ⚙️ 已完成的配置

### 1. 远程仓库配置

当前项目的远程仓库已配置为：

```bash
# 查看远程仓库
git remote -v

# 输出：
# origin    https://github.com/wkhuahuo/formatter.git (fetch/push)
# gitee     https://gitee.com/wkhuahuo/latexOnline.git (fetch/push)
```

- **origin** → GitHub（主仓库）
- **gitee** → Gitee（镜像仓库）

### 2. 分支跟踪配置

```bash
# 设置本地分支跟踪 GitHub
git branch --set-upstream-to=origin/master master
git branch --set-upstream-to=origin/v2.2-wps v2.2-wps
```

### 3. 同步脚本

已创建同步脚本：`scripts/sync-push.ps1`

```powershell
# 推送到所有远程仓库
.\scripts\sync-push.ps1

# 预览操作（不实际执行）
.\scripts\sync-push.ps1 -DryRun

# 推送特定分支
.\scripts\sync-push.ps1 -Branch "v2.2-wps"

# 跳过标签推送
.\scripts\sync-push.ps1 -IncludeTags:$false
```

## 📝 日常开发流程

### 场景 1：日常开发提交

```bash
# 1. 在本地开发
git add .
git commit -m "feat: 添加新功能"

# 2. 推送到 GitHub（主仓库）
git push origin

# 3. 同步到 Gitee（镜像）
git push gitee

# 或使用一键同步脚本
.\scripts\sync-push.ps1
```

### 场景 2：创建功能分支

```bash
# 1. 从 master 创建功能分支
git checkout master
git checkout -b feature-new-feature

# 2. 开发和提交
git add .
git commit -m "feat: 开发新功能"

# 3. 推送到 GitHub
git push origin feature-new-feature

# 4. 在 GitHub 上创建 Pull Request

# 5. 合并后同步到 Gitee
.\scripts\sync-push.ps1
```

### 场景 3：发布新版本

```bash
# 1. 创建发布分支
git checkout master
git checkout -b release-1.0.0

# 2. 更新版本号
npm version patch

# 3. 创建标签
git tag v1.0.0 -m "Release version 1.0.0"

# 4. 合并到 master
git checkout master
git merge release-1.0.0

# 5. 推送到所有远程仓库（包括标签）
.\scripts\sync-push.ps1

# 6. 在 GitHub 上创建 Release
# 访问: https://github.com/wkhuahuo/formatter/releases/new

# 7. 清理分支
git branch -d release-1.0.0
```

## 🔄 自动镜像同步配置

### 方案 A：使用 Gitee 自动同步功能（推荐）

Gitee 提供自动同步 GitHub 仓库的功能：

1. **配置 Gitee 仓库**
   - 访问: https://gitee.com/wkhuahuo/latexOnline/settings
   - 找到 "仓库管理" → "自动同步"
   - 配置同步规则

2. **设置同步方式**
   - 同步模式：推送（Push）
   - 远程仓库：GitHub 仓库地址
   - 认证方式：使用 Personal Access Token

3. **配置 Token**
   - 在 GitHub 生成 Token: https://github.com/settings/tokens
   - 权限：repo（完整仓库访问）
   - 在 Gitee 配置此 Token

### 方案 B：使用 GitHub Actions 自动同步

创建 GitHub Actions 工作流自动同步到 Gitee：

```yaml
# .github/workflows/sync-to-gitee.yml
name: Sync to Gitee

on:
  push:
    branches:
      - master
      - 'release-*'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Sync to Gitee
        run: |
          git remote add gitee https://${{ secrets.GITEE_USERNAME }}:${{ secrets.GITEE_TOKEN }}@gitee.com/wkhuahuo/latexOnline.git
          git push gitee --all
          git push gitee --tags
```

**配置 Secrets**：
1. 访问: https://github.com/wkhuahuo/formatter/settings/secrets/actions
2. 添加 `GITEE_USERNAME`：你的 Gitee 用户名
3. 添加 `GITEE_TOKEN`：你的 Gitee API Token

### 方案 C：手动同步（当前配置）

使用提供的脚本手动同步：

```powershell
# 一键同步所有分支和标签
.\scripts\sync-push.ps1
```

## 📊 对比说明

### GitHub（主仓库）

**用途**：
- ✅ 所有开发活动
- ✅ 代码审查（Pull Request）
- ✅ 自动化构建（GitHub Actions）
- ✅ 版本发布（Releases）
- ✅ 问题跟踪（Issues）
- ✅ 项目文档（Wiki）

**优势**：
- 🌍 国际访问快速
- 🔧 功能完善
- 🤖 CI/CD 集成好
- 👥 社区活跃

### Gitee（镜像仓库）

**用途**：
- 📥 国内快速下载
- 🪞 代码备份
- 👀 国内用户浏览

**优势**：
- 🇨🇳 国内访问快速
- 💾 数据备份
- 📊 提供下载镜像

## 🎯 最佳实践

### ✅ 推荐做法

1. **所有开发在 GitHub 进行**
   - 提交代码到 GitHub
   - 在 GitHub 创建 Pull Request
   - 在 GitHub 进行代码审查
   - 在 GitHub 创建 Release

2. **保持镜像同步**
   - 定期同步到 Gitee
   - 发布版本时必须同步
   - 重要分支及时同步

3. **使用同步脚本**
   - 避免遗漏推送
   - 确保两个仓库一致
   - 简化操作流程

4. **配置自动同步**（可选）
   - 使用 Gitee 自动同步功能
   - 或配置 GitHub Actions

### ❌ 避免做法

1. **不要在 Gitee 上直接开发**
   - 所有开发必须在 GitHub
   - Gitee 仅作为镜像

2. **不要只推送一个仓库**
   - 必须同时推送到两个仓库
   - 保持镜像一致性

3. **不要忘记推送标签**
   - 版本标签必须同步
   - 便于版本追溯

## 🔧 配置检查

### 检查远程仓库

```bash
# 查看远程仓库配置
git remote -v

# 应该输出：
# gitee    https://gitee.com/wkhuahuo/latexOnline.git (fetch/push)
# origin   https://github.com/wkhuahuo/formatter.git (fetch/push)
```

### 检查分支跟踪

```bash
# 查看分支跟踪状态
git branch -vv

# 应该显示跟踪的远程分支
```

### 测试同步

```bash
# 测试推送到 GitHub
git push origin --dry-run

# 测试推送到 Gitee
git push gitee --dry-run

# 或使用脚本预览
.\scripts\sync-push.ps1 -DryRun
```

## 📚 相关文档

- [分支管理策略](./BRANCH_STRATEGY.md)
- [快速参考](./GIT_QUICK_REFERENCE.md)
- [发布检查清单](./RELEASE_CHECKLIST.md)
- [发布快速开始](./PUBLISH_QUICKSTART.md)

## 🆘 常见问题

### Q: 如何处理推送冲突？

**A**: 
```bash
# 1. 先拉取最新代码
git pull origin master
git pull gitee master

# 2. 解决冲突
# 编辑冲突文件

# 3. 提交合并
git commit -m "merge: 解决合并冲突"

# 4. 推送到所有远程仓库
.\scripts\sync-push.ps1
```

### Q: GitHub 推送失败怎么办？

**A**: 
1. 检查网络连接
2. 检查 GitHub Token 是否有效
3. 重试推送
4. 如仍失败，先推送到 Gitee，稍后再同步到 GitHub

### Q: 如何验证镜像同步成功？

**A**: 
1. 访问 Gitee 仓库页面
2. 检查提交历史是否一致
3. 检查标签是否同步
4. 检查分支是否一致

### Q: 可以只在 GitHub 开发吗？

**A**: 可以，但建议保持镜像同步：
- 优点：备份、国内访问快
- 缺点：需要额外推送操作
- 解决：使用同步脚本一键推送

## 🎉 总结

你现在已经配置好了"GitHub 为主仓库，Gitee 为镜像"的开发模式：

✅ **远程仓库配置完成**
- origin → GitHub（主仓库）
- gitee → Gitee（镜像仓库）

✅ **同步脚本已创建**
- `scripts/sync-push.ps1` - 一键同步

✅ **文档齐全**
- 本配置指南
- 分支管理策略
- 发布检查清单

**下一步**：
1. 测试同步脚本：`.\scripts\sync-push.ps1 -DryRun`
2. 配置自动同步（可选）
3. 开始开发并遵循新的工作流程

---

**最后更新**: 2026-11-07  
**维护者**: 项目团队
