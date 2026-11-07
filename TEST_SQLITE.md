# SQLite 数据库持久化测试指南

## 🧪 测试目标

验证 Electron 桌面应用重启后，SQLite 数据库中的文档历史记录是否完好无损。

---

## 📋 测试步骤

### 步骤 1: 首次启动后端（创建数据库）

```bash
cd backend
mvn spring-boot:run
```

**预期结果**:
- 后端在 `http://localhost:8080` 启动
- 自动创建 `backend/data/wpsdoc.db` SQLite 数据库
- 自动创建 `app_user` 和 `doc_record` 数据表
- 插入默认管理员账户（admin/admin123）

**验证命令**:
```bash
# 检查数据库文件是否创建
Test-Path backend\data\wpsdoc.db

# 查看数据库大小
Get-Item backend\data\wpsdoc.db | Select-Object FullName,Length,LastWriteTime
```

---

### 步骤 2: 注册用户并登录

**操作**:
1. 访问 `http://localhost:5174`（前端开发服务器）
2. 点击"登录"按钮
3. 使用默认管理员账户登录：
   - 用户名: `admin`
   - 密码: `admin123`

**预期结果**:
- 登录成功，跳转到首页
- 右上角显示用户名 "admin"

---

### 步骤 3: 创建测试文档

**操作**:
1. 点击"公文格式化"卡片
2. 填写以下信息：
   ```
   红头单位: 测试单位文件
   文号: 测试发〔2026〕1号
   标题: SQLite 数据库持久化测试
   正文: 
   这是一份测试文档，用于验证 SQLite 数据库的持久化功能。
   
   一、测试目的
   
   验证桌面应用重启后，文档历史记录不丢失。
   
   二、测试步骤
   
   1. 创建文档
   2. 保存到数据库
   3. 重启应用
   4. 检查文档是否仍然存在
   ```
3. 点击"保存 Word"按钮

**预期结果**:
- 弹出保存对话框
- 选择保存路径（例如：桌面）
- 文件名：`SQLite 数据库持久化测试.docx`
- 保存成功，数据库插入一条记录

**验证 SQL**:
```sql
-- 使用 SQLite 客户端查看数据库
SELECT id, username, doc_type, title, file_name, size_bytes, created_at 
FROM doc_record 
ORDER BY created_at DESC;
```

**预期输出**:
```
id|username|doc_type|title|file_name|size_bytes|created_at
1|admin|redHeader|SQLite 数据库持久化测试|SQLite 数据库持久化测试.docx|12345|2026-11-05 21:55:00
```

---

### 步骤 4: 查看文档历史列表

**操作**:
1. 刷新页面（F5）
2. 查看"最近文档"列表

**预期结果**:
- 列表中显示刚才创建的文档
- 标题：`SQLite 数据库持久化测试`
- 文件名：`SQLite 数据库持久化测试.docx`
- 创建时间：当前时间

---

### 步骤 5: 重启 Electron 应用

**操作**:
1. 关闭所有应用（Ctrl+C 终止后端和 Electron）
2. 重新启动：
   ```bash
   # 使用启动脚本
   .\start-electron.ps1
   ```

**预期结果**:
- Electron 启动
- 后端自动启动
- 显示启动画面（splash.html）
- 几秒后进入主界面

---

### 步骤 6: 验证文档历史持久化

**操作**:
1. 使用 `admin` 账户重新登录
2. 查看"最近文档"列表

**预期结果**:
- ✅ 文档列表仍然存在
- ✅ 标题、文件名、创建时间未变
- ✅ 可以点击"下载"按钮重新下载文档

**验证 SQL**:
```sql
-- 再次查询数据库
SELECT id, username, doc_type, title, file_name, size_bytes, created_at 
FROM doc_record 
WHERE title = 'SQLite 数据库持久化测试';
```

**预期输出**:
```
id|username|doc_type|title|file_name|size_bytes|created_at
1|admin|redHeader|SQLite 数据库持久化测试|SQLite 数据库持久化测试.docx|12345|2026-11-05 21:55:00
```

---

### 步骤 7: 测试多用户隔离

**操作**:
1. 注册新用户 `testuser`
2. 等待 `admin` 审批
3. 使用 `testuser` 登录
4. 创建一份新文档
5. 查看"最近文档"列表

**预期结果**:
- ✅ `testuser` 只能看到自己创建的文档
- ✅ `admin` 的文档对 `testuser` 不可见
- ✅ 数据库中两条记录的 `username` 字段不同

**验证 SQL**:
```sql
SELECT id, username, doc_type, title, created_at 
FROM doc_record 
ORDER BY username, created_at DESC;
```

**预期输出**:
```
id|username|doc_type|title|created_at
1|admin|redHeader|SQLite 数据库持久化测试|2026-11-05 21:55:00
2|testuser|redHeader|测试用户文档|2026-11-05 22:00:00
```

---

## 🔍 故障排查

### 问题 1: 数据库文件未创建

**可能原因**:
- 后端未正常启动
- `application.properties` 配置错误
- 权限问题

**解决方案**:
```bash
# 检查后端日志
tail -f backend/data/backend.log

# 验证配置文件
cat backend/src/main/resources/application.properties | grep datasource

# 手动创建数据库目录
mkdir -p backend/data
```

---

### 问题 2: 文档历史丢失

**可能原因**:
- 数据库路径配置不一致
- 用户未正确登录
- 数据库文件被覆盖

**解决方案**:
```bash
# 检查数据库位置
Get-ChildItem -Path backend,data -Filter "*.db" -Recurse

# 备份数据库文件
Copy-Item backend\data\wpsdoc.db backend\data\wpsdoc.db.backup

# 查看数据库内容
sqlite3 backend\data\wpsdoc.db "SELECT * FROM doc_record;"
```

---

### 问题 3: Electron 启动失败

**可能原因**:
- 后端 jar 未复制
- 前端未构建
- Java 未安装

**解决方案**:
```bash
# 检查 jar 文件
Test-Path electron\resources\backend\app.jar

# 检查前端构建
Test-Path frontend\dist\index.html

# 检查 Java 版本
java -version
```

---

## 📊 性能测试

### 测试 1: 大量文档历史

**操作**:
1. 创建 100 份测试文档
2. 测量文档列表加载时间
3. 测量数据库查询时间

**预期结果**:
- 列表加载时间 < 2 秒
- 数据库查询时间 < 500 毫秒

**验证 SQL**:
```sql
-- 插入测试数据
INSERT INTO doc_record (username, doc_type, title, file_name, size_bytes, content, created_at)
SELECT 'admin', 'redHeader', '测试文档 ' || i, 
       '测试文档 ' || i || '.docx', 10000, X'', 
       datetime('now', '-' || i || ' minutes')
FROM generate_series(1, 100) AS i;

-- 查询测试
SELECT COUNT(*) FROM doc_record WHERE username = 'admin';
```

---

### 测试 2: 大文件存储

**操作**:
1. 创建包含图片的复杂文档（> 5MB）
2. 保存到数据库
3. 重新下载并验证完整性

**预期结果**:
- ✅ 文件保存成功
- ✅ 文件大小一致
- ✅ 文件内容完整

**验证命令**:
```bash
# 检查数据库大小
Get-Item backend\data\wpsdoc.db | Select-Object Length

# 检查 BLOB 内容
sqlite3 backend\data\wpsdoc.db "SELECT id, title, length(content) FROM doc_record;"
```

---

## ✅ 测试检查清单

- [ ] 后端首次启动创建 SQLite 数据库
- [ ] 数据库包含 `app_user` 和 `doc_record` 表
- [ ] 默认管理员账户（admin）已创建
- [ ] 用户可以注册并登录
- [ ] 创建的文档保存到数据库
- [ ] 文档历史列表正确显示
- [ ] 重启 Electron 应用后文档历史仍在
- [ ] 多用户文档历史相互隔离
- [ ] 可以重新下载历史文档
- [ ] 可以删除历史文档
- [ ] 数据库文件大小合理
- [ ] 查询性能满足要求

---

## 🎯 成功标准

所有测试检查清单项目都通过，且满足以下条件：

1. **数据持久化**: 重启应用后文档历史不丢失
2. **用户隔离**: 不同用户的文档互不可见
3. **完整性**: 下载的文档与保存时一致
4. **性能**: 列表加载和查询速度满足用户体验要求

---

## 📝 测试报告模板

```
测试日期: 2026-11-05
测试人员: [姓名]
应用版本: 1.1.0

测试结果:
- 数据库创建: ✅ 通过 / ❌ 失败
- 文档保存: ✅ 通过 / ❌ 失败
- 文档持久化: ✅ 通过 / ❌ 失败
- 用户隔离: ✅ 通过 / ❌ 失败
- 性能测试: ✅ 通过 / ❌ 失败

问题记录:
1. [问题描述]
2. [问题描述]

建议:
1. [改进建议]
2. [改进建议]
```

---

## 🔗 相关文档

- [BUILD.md](./BUILD.md) - 构建与部署指南
- [QUICKSTART.md](./QUICKSTART.md) - 快速开始指南
- [PROJECT_INFO.md](./PROJECT_INFO.md) - 工程信息检查报告
