# 🚀 发布系统快速参考

## 📦 已创建的文件清单

```
latexOnline/
├── .github/
│   └── workflows/
│       └── release.yml          # GitHub Actions 自动构建发布
├── scripts/
│   ├── build.ps1                # Windows 构建脚本
│   ├── publish.ps1              # 一键发布脚本
│   └── upload-to-gitee.ps1      # Gitee 上传脚本
├── RELEASE_GUIDE.md             # 详细发布指南
├── PUBLISH_QUICKSTART.md        # 快速开始指南
├── RELEASE_CONFIG.md            # 配置总结
├── RELEASE_TEMPLATE.md          # Release 说明模板
└── RELEASE_REFERENCE.md         # 本文档
```

## ⚡ 最常用的命令

### 发布新版本（一键完成）
```powershell
.\scripts\publish.ps1 -Version "1.0.0"
```

### 本地构建
```powershell
.\scripts\build.ps1
```

### 上传到 Gitee
```powershell
.\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_TOKEN"
```

## 🎯 完整发布流程

### 首次发布
```powershell
# 1. 添加 GitHub 远程仓库
git remote add github https://github.com/YOUR_USERNAME/latexOnline.git

# 2. 运行发布脚本
.\scripts\publish.ps1 -Version "1.0.0"

# 3. 等待 GitHub Actions 构建完成（5-10分钟）
# 访问: https://github.com/YOUR_USERNAME/latexOnline/actions

# 4. 从 GitHub 下载构建产物到 release/ 目录

# 5. 上传到 Gitee
.\scripts\upload-to-gitee.ps1 -Version "1.0.0" -Token "YOUR_GITEE_TOKEN"
```

### 后续更新
```powershell
# 1. 运行发布脚本
.\scripts\publish.ps1 -Version "1.0.1"

# 2. 等待构建完成并下载产物

# 3. 上传到 Gitee
.\scripts\upload-to-gitee.ps1 -Version "1.0.1" -Token "YOUR_GITEE_TOKEN"
```

## 📋 检查清单

发布前确认：
- [ ] 已创建 GitHub 仓库
- [ ] 已配置 GitHub 远程仓库
- [ ] 代码已提交并推送
- [ ] 版本号正确
- [ ] 本地构建测试通过（可选）

发布后确认：
- [ ] GitHub Actions 构建成功
- [ ] GitHub Release 已创建
- [ ] 构建产物已上传到 GitHub
- [ ] 构建产物已上传到 Gitee（可选）
- [ ] Release 说明已填写

## 🔗 快速链接

### GitHub
- 仓库: `https://github.com/YOUR_USERNAME/latexOnline`
- Actions: `https://github.com/YOUR_USERNAME/latexOnline/actions`
- Releases: `https://github.com/YOUR_USERNAME/latexOnline/releases`

### Gitee
- 仓库: `https://gitee.com/wkhuahuo/latexOnline`
- Releases: `https://gitee.com/wkhuahuo/latexOnline/releases`
- API Token: `https://gitee.com/profile/personal_access_tokens`

## 🎨 版本号规则

```
X.Y.Z
│ │ │
│ │ └─ 修订号（Bug 修复）
│ └─── 次版本号（新功能）
└───── 主版本号（重大更新）
```

示例：
- `1.0.0` → `1.0.1`：修复 bug
- `1.0.0` → `1.1.0`：新增功能
- `1.0.0` → `2.0.0`：重大更新

## 📝 Git 标签操作

```bash
# 创建标签
git tag v1.0.0

# 推送标签到 GitHub
git push github v1.0.0

# 查看所有标签
git tag -l

# 删除本地标签
git tag -d v1.0.0

# 删除远程标签
git push github :refs/tags/v1.0.0
```

## ⚠️ 常见问题速查

### Q: 构建失败？
**A**: 检查 GitHub Actions 日志，常见原因：
- 网络连接问题
- 依赖下载失败
- 代码编译错误

### Q: 没有触发构建？
**A**: 确保：
- 标签格式正确：`v1.0.0`（必须有 `v`）
- 已推送 `.github/workflows/release.yml`
- 标签已推送到 GitHub

### Q: Gitee 上传失败？
**A**: 检查：
- Token 是否正确
- Token 权限是否包含 `projects`
- 网络连接是否正常

### Q: 如何回滚？
**A**: 
```bash
# 1. 删除 GitHub Release（网页操作）
# 2. 删除标签
git tag -d v1.0.0
git push github :refs/tags/v1.0.0
# 3. 修复后重新发布
```

## 📊 构建产物说明

每次构建生成：
- **文件**: `WpsDocEditor-X.Y.Z-win.zip`
- **大小**: 约 200-300 MB
- **包含**: 
  - Electron 应用
  - JRE 运行环境
  - 前端资源
  - 后端服务

## 🔐 Token 管理

### GitHub Token
- **位置**: Settings → Developer settings → Personal access tokens
- **权限**: `repo`（完整仓库访问）
- **用途**: Actions 自动使用，无需手动配置

### Gitee Token
- **位置**: https://gitee.com/profile/personal_access_tokens
- **权限**: `projects`
- **用途**: 上传脚本需要
- **保存**: 妥善保管，不要提交到代码库

## 💡 提示与技巧

### 加速构建
- 已配置 npm 和 Maven 缓存
- 首次构建较慢，后续构建会快一些

### 测试构建
- 推送前可先在本地运行 `.\scripts\build.ps1`
- 确保本地构建成功后再推送

### 批量操作
- 可以一次推送多个标签
- 但建议逐个发布，便于管理

### 文档维护
- 及时更新 CHANGELOG
- 保留所有版本的 Release 说明

## 📞 获取帮助

遇到问题？
1. 查看详细文档：`RELEASE_GUIDE.md`
2. 查看快速开始：`PUBLISH_QUICKSTART.md`
3. 查看配置说明：`RELEASE_CONFIG.md`
4. 查看 GitHub Actions 日志

## 🎉 成功发布的标志

当你看到以下内容时，说明发布成功：
- ✅ GitHub Actions 显示绿色对勾
- ✅ GitHub Release 页面有构建产物
- ✅ Gitee Release 页面有构建产物
- ✅ 用户可以下载并使用

---

**记住**: 发布是一个迭代过程，第一次可能需要多次尝试才能成功，这是正常的！
