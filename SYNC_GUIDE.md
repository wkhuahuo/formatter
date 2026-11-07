# 仓库同步指南

## 📊 当前状态

### 本地仓库
- ✅ 所有代码已提交
- ✅ master 分支包含最新更改
- ✅ 已推送到 Gitee

### 远程仓库
- **Gitee**: ✅ 已同步到最新
- **GitHub**: ⚠️ 需要手动推送（网络限制）

## 🔧 需要手动执行的命令

### 1. 推送 master 分支到 GitHub

```powershell
# 强制推送本地 master 到 GitHub（覆盖远程初始提交）
git push -f origin master
```

### 2. 推送所有分支到 GitHub

```powershell
# 推送所有本地分支
git push origin --all

# 推送所有标签
git push origin --tags
```

### 3. 验证同步状态

```powershell
# 查看远程仓库状态
git remote show origin
git remote show gitee

# 查看所有分支
git branch -a

# 查看所有标签
git tag -l
```

## 🎯 推荐的默认关联

### 问题：应该自动关联 Gitee 还是 GitHub？

**答案：关联 GitHub（origin）**

### 理由：

1. **开发流程**
   - ✅ 所有开发活动在 GitHub 进行
   - ✅ Pull Request 在 GitHub 审查
   - ✅ Issues 和 Projects 在 GitHub 管理
   - ✅ GitHub Actions 自动构建

2. **Gitee 作为镜像**
   - 📥 提供国内快速下载
   - 🪞 代码备份
   - 👀 国内用户浏览

3. **推送顺序**
   ```
   本地开发 → 推送到 GitHub (origin)
                    ↓
              同步到 Gitee (镜像)
   ```

## 📝 日常操作流程

### 提交代码

```powershell
# 1. 提交更改
git add .
git commit -m "描述你的更改"

# 2. 推送到 GitHub（主仓库）
git push origin

# 3. 同步到 Gitee（镜像）
git push gitee

# 或使用一键同步脚本
.\scripts\sync-push.ps1
# 或
run-sync.bat
```

### 发布版本

```powershell
# 一键发布（自动推送到两个仓库）
.\scripts\publish-all.ps1 -Version "1.0.0"
# 或
run-publish.bat 1.0.0
```

## 🔍 检查同步状态

### 比较本地和远程

```powershell
# 查看与 GitHub 的差异
git log origin/master..master

# 查看与 Gitee 的差异
git log gitee/master..master
```

### 查看远程仓库信息

```powershell
# 查看所有远程仓库
git remote -v

# 应该输出：
# gitee    https://gitee.com/wkhuahuo/latexOnline.git (fetch/push)
# origin   https://github.com/wkhuahuo/formatter.git (fetch/push)
```

## ⚠️ 常见问题

### Q: 为什么 GitHub 推送失败？

**A**: 可能原因：
1. 网络连接问题
2. GitHub Token 过期
3. 仓库权限问题

**解决方案**：
```powershell
# 重新认证
gh auth login

# 或更新 Token
git remote set-url origin https://YOUR_TOKEN@github.com/wkhuahuo/formatter.git
```

### Q: 如何处理冲突？

**A**: 如果 GitHub 和 Gitee 有不同的历史：
```powershell
# 1. 以 GitHub 为准（推荐）
git pull origin master --rebase
git push gitee master --force

# 2. 以 Gitee 为准
git pull gitee master --rebase
git push origin master --force
```

### Q: 可以只使用一个仓库吗？

**A**: 可以，但建议保持两个仓库同步：
- **只用 GitHub**: 国内访问慢
- **只用 Gitee**: 缺少 GitHub 的生态和功能
- **两者结合**: 最佳实践 ✅

## 📚 相关文档

- [主镜像仓库配置](./MIRROR_CONFIG.md)
- [分支管理策略](./BRANCH_STRATEGY.md)
- [一键发布指南](./ONE_CLICK_PUBLISH.md)

## 🎉 快速开始

```powershell
# 1. 推送到 GitHub
git push -f origin master

# 2. 推送到 Gitee（如果还没推送）
git push gitee master

# 3. 验证
git remote show origin
git remote show gitee

# 4. 开始日常开发
# 使用 sync-push.ps1 一键同步
```

---

**最后更新**: 2026-11-07  
**状态**: 等待手动推送到 GitHub
