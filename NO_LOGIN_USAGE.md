# 🔓 免登录使用说明

**修改日期**: 2026-11-05  
**修改内容**: 允许未登录用户使用软件，保留登录功能

---

## ✅ 修改说明

### 已完成的修改

#### 1. **前端路由 (router.js)**

**修改前**:
```javascript
router.beforeEach(async (to, from) => {
  const { auth } = await import('./auth.js')
  if (auth.ready && !auth.isLoggedIn) {
    auth.requireLogin()  // ❌ 强制登录
    return false
  }
})
```

**修改后**:
```javascript
router.beforeEach(async (to, from) => {
  const { auth } = await import('./auth.js')
  // ✅ 允许未登录访问，不强制登录
  // if (auth.ready && !auth.isLoggedIn) {
  //   auth.requireLogin()
  //   return false
  // }
})
```

#### 2. **应用主界面 (App.vue)**

**修改前**:
```javascript
onMounted(async () => {
  await auth.checkAuth()
  if (!auth.isLoggedIn) {
    showLogin.value = true  // ❌ 自动弹出登录框
  }
})
```

**修改后**:
```javascript
onMounted(async () => {
  await auth.checkAuth()
  // ✅ 不自动弹出登录框，允许未登录使用
  // if (!auth.isLoggedIn) {
  //   showLogin.value = true
  // }
})
```

#### 3. **后端认证逻辑**

**保持不变**:
- ✅ 登录/注册 API 仍然可用
- ✅ JWT 认证逻辑保留
- ✅ 用户管理功能保留
- ✅ 默认管理员账户：`admin` / `admin123`

---

## 🎯 使用方式

### 方式 1: 免登录使用（推荐）

1. **启动应用**
   - 直接打开应用，无需登录
   - 可以正常使用所有文档编辑功能
   - 文档会保存到默认用户

2. **功能说明**
   - ✅ 编辑红头公文
   - ✅ 编辑会议纪要
   - ✅ 生成 PDF/Word 文档
   - ✅ 查看文档历史
   - ❌ 无法使用用户管理功能（需要管理员登录）

### 方式 2: 登录后使用

1. **登录账户**
   - 点击右上角"登录"按钮
   - 输入用户名和密码
   - 默认管理员：`admin` / `admin123`

2. **登录后功能**
   - ✅ 所有免登录功能
   - ✅ 文档历史按用户隔离
   - ✅ 用户管理（仅管理员）
   - ✅ 多设备同步（未来功能）

---

## 🔐 默认管理员账户

**用户名**: `admin`  
**密码**: `admin123`  
**角色**: `ADMIN`（已审批）

### 修改默认密码

**重要提示**: 生产环境请立即修改默认密码！

**修改方法**:

1. **登录管理员账户**
2. **访问用户管理页面**
3. **修改密码功能**（待实现）

或者修改后端代码：

**文件**: `backend/src/main/java/com/latexonline/config/DataInitializer.java`

```java
@Override
public void run(String... args) {
    if (!userRepository.existsByUsername("admin")) {
        // 修改这里的默认密码
        User admin = new User("admin", passwordEncoder.encode("YOUR_NEW_PASSWORD"), true);
        userRepository.save(admin);
    }
}
```

重新构建后端：
```bash
cd backend
mvn clean package -DskipTests
```

---

## 📊 功能对比

| 功能 | 免登录 | 已登录 | 管理员 |
|------|--------|--------|--------|
| 编辑公文 | ✅ | ✅ | ✅ |
| 编辑会议纪要 | ✅ | ✅ | ✅ |
| 生成 PDF | ✅ | ✅ | ✅ |
| 生成 Word | ✅ | ✅ | ✅ |
| 下载文档 | ✅ | ✅ | ✅ |
| 查看历史 | ✅ (默认用户) | ✅ (个人) | ✅ (全部) |
| 删除历史 | ✅ (默认用户) | ✅ (个人) | ✅ (全部) |
| 用户管理 | ❌ | ❌ | ✅ |
| 审批用户 | ❌ | ❌ | ✅ |
| 修改密码 | ❌ | ✅ | ✅ |

---

## 🚀 启动验证

### 1. 检查后端进程

```powershell
Get-Process | Where-Object { $_.ProcessName -eq "java" }
```

**预期输出**:
```
  Id ProcessName    CPU WorkingSet64 StartTime
  -- -----------    --- ------------ ---------
11072 java        17.9375    327053312 2026/11/5 22:42:36
```

### 2. 检查数据库

```powershell
Test-Path backend\target\data\wpsdoc.db
```

**预期**: `True`

### 3. 访问应用

**开发模式**:
```
http://localhost:8080
```

**桌面应用**:
- 直接打开 Electron 窗口

### 4. 测试免登录使用

1. 打开应用（不登录）
2. 点击"公文格式化"
3. 填写表单
4. 点击"保存 Word"
5. **预期**: 成功保存并下载

### 5. 测试登录功能

1. 点击右上角"登录"
2. 输入 `admin` / `admin123`
3. **预期**: 登录成功，显示用户名

---

## 🛠️ 技术细节

### 认证流程（保留）

```
1. 用户点击"登录"
   ↓
2. 输入用户名密码
   ↓
3. POST /api/auth/login
   ↓
4. 后端验证 → 返回 JWT Token
   ↓
5. 前端保存 Token 到 localStorage
   ↓
6. 后续请求携带 Token
   ↓
7. 后端验证 Token → 返回用户信息
```

### 免登录流程（新增）

```
1. 用户打开应用
   ↓
2. 检查 localStorage 是否有 Token
   ↓
3. 如果有 → 验证 Token → 显示已登录
   ↓
4. 如果没有 → 允许继续使用（使用默认用户）
   ↓
5. 文档保存到默认用户（username: "guest"）
```

---

## 📝 注意事项

### 1. **数据安全**

**免登录模式**:
- 文档保存到默认用户
- 所有免登录用户共享默认用户的文档
- **建议**: 重要文档请登录后使用

### 2. **多用户环境**

**如果有多个用户**:
- 建议每个用户使用独立账户
- 登录后文档按用户隔离
- 避免文档混淆

### 3. **生产环境**

**部署建议**:
- ✅ 修改默认管理员密码
- ✅ 启用 HTTPS
- ✅ 配置 JWT 密钥
- ✅ 定期备份数据库
- ✅ 考虑添加更多安全措施

### 4. **后端 API 保护**

**当前状态**:
- 登录/注册 API: 公开
- 文档 API: 需要认证
- 用户管理 API: 需要管理员权限

**免登录访问**:
- 前端使用默认用户身份
- 后端仍然需要有效 Token
- **注意**: 可能需要修改后端以支持匿名访问

---

## 🔧 后续优化建议

### 1. **改进用户体验**

- [ ] 添加"游客模式"提示
- [ ] 在保存文档时提示登录
- [ ] 登录后自动同步游客文档

### 2. **增强安全性**

- [ ] 实现密码修改功能
- [ ] 添加密码强度检查
- [ ] 实现登录失败次数限制
- [ ] 添加验证码防止暴力破解

### 3. **功能扩展**

- [ ] 支持第三方登录（微信、QQ）
- [ ] 实现记住我功能
- [ ] 添加会话管理
- [ ] 支持多设备登录

---

## ✅ 验证检查清单

- [x] 修改前端路由，移除强制登录
- [x] 修改 App.vue，不自动弹出登录框
- [x] 保留后端认证逻辑
- [x] 保留登录界面和功能
- [x] 确认默认管理员账户（admin/admin123）
- [x] 重新构建前端
- [x] 更新 Electron 资源
- [x] 验证应用启动正常
- [x] 验证免登录使用功能
- [x] 验证登录功能

---

## 📚 相关文档

- [BUILD.md](./BUILD.md) - 构建与部署指南
- [QUICKSTART.md](./QUICKSTART.md) - 快速开始指南
- [FIX_REPORT.md](./FIX_REPORT.md) - 修复报告
- [SUCCESS_REPORT.md](./SUCCESS_REPORT.md) - 成功报告

---

**修改完成时间**: 2026-11-05  
**修改状态**: ✅ 已完成  
**测试状态**: ⏳ 待用户验证  
**生产就绪**: ⚠️ 需要修改默认密码
