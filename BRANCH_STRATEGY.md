# Git 分支管理策略

本文档定义了项目的 Git 分支管理策略，确保开发、发布和版本控制的规范化。

## 🌳 分支模型

本项目采用类似 **Git Flow** 的分支管理策略：

```
master (稳定版本)
  ↑
  └── release-* (发布准备)
        ↑
        └── feature-* (功能开发)
```

## 📋 分支职责

### 1. **master 分支**（主分支）
- **用途**：跟踪最终稳定版本
- **特点**：
  - ✅ 始终保持稳定状态
  - ✅ 每个提交都应该可以发布
  - ✅ 与版本号标签（tag）绑定
  - ✅ 不允许直接提交
- **更新方式**：
  - 从 `release-*` 分支合并
  - 发布新版本后合并

### 2. **release-* 分支**（发布分支）
- **用途**：准备新版本的发布
- **命名规范**：`release-X.Y.Z`（例如：`release-1.0.0`）
- **特点**：
  - ✅ 从 `master` 或 `feature` 分支创建
  - ✅ 用于集成测试和 Bug 修复
  - ✅ 发布前冻结功能
  - ✅ 与版本号标签绑定
- **生命周期**：
  - 创建 → 开发/测试 → 发布 → 合并到 `master` → 删除

### 3. **feature-* 分支**（功能分支）
- **用途**：开发新功能
- **命名规范**：`feature-功能名称`（例如：`feature-dark-mode`）
- **特点**：
  - ✅ 从 `master` 分支创建
  - ✅ 开发完成后合并到 `release-*` 或直接到 `master`
  - ✅ 可以长期存在
  - ✅ 允许频繁提交
- **生命周期**：
  - 创建 → 开发 → 测试 → 合并 → 删除

## 🔄 工作流程

### 场景 1：开发新功能

```bash
# 1. 从 master 创建功能分支
git checkout master
git checkout -b feature-new-feature

# 2. 开发和提交
git add .
git commit -m "feat: 添加新功能"

# 3. 推送到远程
git push origin feature-new-feature

# 4. 开发完成后，创建 release 分支或直接合并到 master
git checkout master
git merge feature-new-feature
```

### 场景 2：发布新版本

```bash
# 1. 从 master 创建 release 分支
git checkout master
git checkout -b release-1.0.0

# 2. 更新版本号和文档
npm version patch  # 或 minor, major
# 更新 CHANGELOG.md
# 更新文档

# 3. 提交更改
git add .
git commit -m "chore: bump version to 1.0.0"

# 4. 测试和修复 Bug（如有）
git add .
git commit -m "fix: 修复发布前的 Bug"

# 5. 创建版本标签
git tag v1.0.0 -m "Release version 1.0.0"

# 6. 合并到 master
git checkout master
git merge release-1.0.0

# 7. 推送到远程
git push origin master
git push origin v1.0.0

# 8. 同步到 GitHub
git push github master
git push github v1.0.0

# 9. 删除 release 分支（可选）
git branch -d release-1.0.0
```

### 场景 3：紧急修复（Hotfix）

```bash
# 1. 从 master 创建 hotfix 分支
git checkout master
git checkout -b hotfix-1.0.1

# 2. 修复问题
git add .
git commit -m "fix: 修复紧急问题"

# 3. 更新版本号
npm version patch

# 4. 创建标签
git tag v1.0.1 -m "Hotfix version 1.0.1"

# 5. 合并到 master
git checkout master
git merge hotfix-1.0.1

# 6. 推送
git push origin master
git push origin v1.0.1
git push github master
git push github v1.0.1
```

## 📝 命名规范

### 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 主分支 | `master` | `master` |
| 发布分支 | `release-X.Y.Z` | `release-1.0.0`, `release-2.1.0` |
| 功能分支 | `feature-功能名称` | `feature-dark-mode`, `feature-pdf-export` |
| 修复分支 | `hotfix-X.Y.Z` | `hotfix-1.0.1`, `hotfix-2.0.1` |
| 实验分支 | `experiment-实验名称` | `experiment-new-ui` |

### 提交信息规范

使用 **Conventional Commits** 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型（type）**：
- `feat`：新功能
- `fix`：修复 Bug
- `docs`：文档更新
- `style`：代码格式调整
- `refactor`：代码重构
- `test`：测试相关
- `chore`：构建/工具/依赖变动
- `revert`：回滚提交

**示例**：
```
feat(editor): 添加暗色模式支持

- 实现暗色主题切换
- 保存用户偏好设置
- 更新相关文档

Closes #123
```

### 标签命名

- **格式**：`vX.Y.Z`（语义化版本）
- **示例**：`v1.0.0`, `v1.1.0`, `v2.0.0`
- **必须**：
  - 以 `v` 开头
  - 与 `package.json` 中的版本号一致
  - 附加到具体的提交

## 🎯 版本管理

### 语义化版本（Semantic Versioning）

版本号格式：`X.Y.Z`

- **X（主版本号）**：不兼容的重大更新
- **Y（次版本号）**：向下兼容的功能新增
- **Z（修订号）**：向下兼容的问题修正

### 版本更新时机

| 更新类型 | 版本号变化 | 示例 |
|---------|-----------|------|
| 修复 Bug | Z+1 | 1.0.0 → 1.0.1 |
| 新增功能 | Y+1 | 1.0.0 → 1.1.0 |
| 重大更新 | X+1 | 1.0.0 → 2.0.0 |

### 版本标签操作

```bash
# 创建标签
git tag v1.0.0 -m "Release version 1.0.0"

# 查看标签
git tag -l

# 查看标签详情
git show v1.0.0

# 删除本地标签
git tag -d v1.0.0

# 删除远程标签
git push origin :refs/tags/v1.0.0
git push github :refs/tags/v1.0.0

# 推送标签
git push origin v1.0.0
git push github v1.0.0

# 检出特定版本
git checkout v1.0.0
```

## 🚀 发布流程

### 使用发布脚本（推荐）

```powershell
# 自动发布流程
.\scripts\publish.ps1 -Version "1.0.0"
```

脚本会自动：
1. ✅ 更新 `package.json` 版本号
2. ✅ 构建前端和后端
3. ✅ 打包 Electron 应用
4. ✅ 提交代码更改
5. ✅ 创建版本标签
6. ✅ 推送到 Gitee
7. ⚠️ 手动推送到 GitHub（网络问题需重试）

### 手动发布流程

```bash
# 1. 更新版本号
npm version patch  # 或 minor, major

# 2. 构建应用
.\scripts\build.ps1

# 3. 提交更改
git add .
git commit -m "chore: bump version to 1.0.1"

# 4. 创建标签
git tag v1.0.1 -m "Release version 1.0.1"

# 5. 推送代码
git push origin master
git push github master

# 6. 推送标签
git push origin v1.0.1
git push github v1.0.1
```

## 📊 分支保护规则

### master 分支保护

建议在 GitHub/Gitee 设置：

1. **禁止直接推送**
   - 所有更改必须通过 Pull Request
   - 至少需要 1 人审核

2. **要求状态检查通过**
   - CI/CD 构建成功
   - 代码检查通过

3. **要求签名提交**
   - 启用 GPG 签名（可选）

4. **限制推送权限**
   - 只有维护者可以合并到 master

### release 分支保护

1. **冻结功能**
   - 只允许 Bug 修复提交
   - 不允许新功能

2. **要求测试通过**
   - 所有测试必须通过
   - 集成测试完成

## 🔧 工具配置

### Git 配置

```bash
# 设置默认推送分支
git config --global push.default current

# 设置拉取时变基
git config --global pull.rebase true

# 设置别名
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"
```

### IDE 配置

建议在 `.editorconfig` 或 IDE 设置中：

- 自动添加换行符
- 统一缩进风格
- 自动删除行尾空格

## 📚 最佳实践

### ✅ 推荐做法

1. **频繁提交，小步快跑**
   - 每个功能点单独提交
   - 便于回滚和追踪

2. **及时更新分支**
   - 定期从 master 拉取最新代码
   - 避免合并冲突

3. **完整的提交信息**
   - 说明"是什么"和"为什么"
   - 关联 Issue 编号

4. **代码审查**
   - 所有合并必须经过 PR
   - 至少一人审核

5. **自动化测试**
   - 推送前运行测试
   - CI/CD 自动验证

### ❌ 避免做法

1. **不要在 master 上直接开发**
   - 使用 feature 分支
   - 保持 master 稳定

2. **不要提交大量无关更改**
   - 一个 PR 只做一件事
   - 便于审查和回滚

3. **不要忽略测试失败**
   - 修复所有测试
   - 保证代码质量

4. **不要强制推送到公共分支**
   - 避免覆盖他人工作
   - 使用合并而非变基

## 🆘 常见问题

### Q: 如何处理合并冲突？

```bash
# 1. 拉取最新代码
git checkout master
git pull origin master

# 2. 切换到功能分支
git checkout feature-xxx

# 3. 合并 master
git merge master

# 4. 解决冲突
# 编辑冲突文件

# 5. 提交合并
git add .
git commit -m "merge: 合并 master 到 feature-xxx"

# 6. 继续开发
```

### Q: 如何回滚错误提交？

```bash
# 回滚最后一次提交（保留更改）
git reset --soft HEAD~1

# 回滚最后一次提交（丢弃更改）
git reset --hard HEAD~1

# 回滚特定提交
git revert <commit-hash>
```

### Q: 如何清理已合并的分支？

```bash
# 删除本地分支
git branch -d feature-xxx

# 删除远程分支
git push origin :feature-xxx

# 清理已删除的远程分支引用
git remote prune origin
```

### Q: 如何查看分支历史？

```bash
# 查看分支图
git log --oneline --graph --all

# 查看特定分支的提交
git log master..feature-xxx

# 查看两个分支的差异
git diff master..feature-xxx
```

## 📖 相关资源

- [Git Flow 工作流](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [语义化版本规范](https://semver.org/lang/zh-CN/)
- [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

## 🎯 总结

本分支管理策略的核心原则：

1. **master 分支始终稳定** - 随时可以发布
2. **release 分支用于发布准备** - 集成测试和修复
3. **feature 分支用于功能开发** - 独立开发，互不影响
4. **标签标记具体版本** - 可追溯，可回滚
5. **规范的提交流程** - 清晰的历史记录

遵循这个策略，可以：
- ✅ 提高代码质量
- ✅ 降低发布风险
- ✅ 便于团队协作
- ✅ 清晰的历史追踪

---

**最后更新**: 2026-11-07  
**维护者**: 项目团队
