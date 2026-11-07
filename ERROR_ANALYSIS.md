# 🔍 Electron 启动失败错误分析

**分析日期**: 2026-11-05  
**错误类型**: 数据库配置不匹配 + 使用了旧的打包版本

---

## ❌ 发现的问题

### 问题 1: 使用了旧的 JAR 文件

**症状**:
- 日志显示日期为 2026-11-03（旧日志）
- 日志路径: `release\win-unpacked\resources\backend\app.jar`
- 而不是: `electron\resources\backend\app.jar`

**根本原因**:
Electron 在打包模式下运行的是 `release/win-unpacked/` 目录中的旧版本，而不是开发模式的 `electron/resources/` 目录。

**证据**:
```log
C:\GITProject\latexOnline\release\win-unpacked\resources\backend\app.jar started by dk
```

### 问题 2: 数据库配置为 H2 而非 SQLite

**症状**:
```log
HikariPool-1 - Added connection conn0: url=jdbc:h2:mem:latexdb user=SA
H2 console available at '/h2-console'. Database available at 'jdbc:h2:mem:latexdb'
HHH90000025: H2Dialect does not need to be specified explicitly
```

**根本原因**:
旧的 JAR 文件（`release/win-unpacked/resources/backend/app.jar`）中的 `application.properties` 配置的是 H2 数据库，而不是 SQLite。

**影响**:
- 数据存储在内存中（`jdbc:h2:mem:latexdb`）
- 应用重启后数据丢失
- 无法实现文档历史持久化

### 问题 3: HTTP 请求解析错误

**症状**:
```log
Error parsing HTTP request header
java.lang.IllegalArgumentException: Invalid character found in method name [0x050x010x00...]
```

**根本原因**:
可能是 Electron 的某些内部请求或 WebSocket 连接被误发送到后端。

**影响**:
- 不影响核心功能
- 日志中出现错误信息
- 可能导致性能问题

---

## 📊 日志分析

### 当前日志位置
```
Windows: %APPDATA%\WpsDocEditor\logs\backend.log
实际路径: C:\Users\dk\AppData\Roaming\WpsDocEditor\logs\backend.log
```

### 日志时间戳
```
最后修改时间: 2026/11/3 14:38:39
当前时间: 2026/11/5 22:00
```

**结论**: 日志是旧的（2天前），说明 Electron 没有重新启动后端，或者启动失败。

### 数据库连接日志
```log
2026-11-03T14:37:30.446+08:00  INFO --- HikariPool-1 - Starting...
2026-11-03T14:37:30.802+08:00  INFO --- HikariPool-1 - Added connection conn0: url=jdbc:h2:mem:latexdb
2026-11-03T14:37:30.804+08:00  INFO --- HikariPool-1 - Start completed.
```

**问题**: 
- 使用的是 H2 内存数据库（`jdbc:h2:mem:latexdb`）
- 应该是 SQLite 文件数据库（`jdbc:sqlite:./data/wpsdoc.db`）

### 启动成功日志
```log
2026-11-03T14:37:34.674+08:00  INFO --- Tomcat started on port 8800 (http)
APP_PORT=8800
2026-11-03T14:37:34.705+08:00  INFO --- Started LatexOnlineApplication in 7.724 seconds
```

**说明**: 
- 后端确实启动成功了（端口 8800）
- 但使用的是旧配置

---

## 🔧 解决方案

### 方案 1: 清理旧的打包版本（推荐）

**步骤**:

1. **删除旧的 release 目录**
```powershell
cd c:\GITProject\latexOnline
Remove-Item -Recurse -Force release
```

2. **重新构建 Electron**
```powershell
cd electron
npm run build:win
```

3. **验证新配置**
```powershell
# 解压后检查配置
Expand-Archive release\WpsDocEditor-1.0.0-win-x64.zip -DestinationPath release\test
Get-Content release\test\resources\backend\app.jar
# 应该看到 SQLite 配置
```

### 方案 2: 强制使用开发模式

**步骤**:

1. **修改 electron/main.js**
```javascript
// 临时强制开发模式
const isDev = true;  // 改为 true
```

2. **重新启动 Electron**
```powershell
cd c:\GITProject\latexOnline
.\start-electron.ps1
```

**优点**: 
- 使用最新的 jar 文件
- 使用最新的配置

**缺点**: 
- 需要手动启动后端和前端

### 方案 3: 更新打包版本的配置

**步骤**:

1. **复制最新 jar 到 release 目录**
```powershell
Copy-Item electron\resources\backend\app.jar release\win-unpacked\resources\backend\app.jar -Force
```

2. **重新启动 Electron**
```powershell
cd release\win-unpacked
.\WpsDocEditor.exe
```

**优点**: 
- 快速修复
- 不需要重新打包

**缺点**: 
- 下次打包会覆盖修改

---

## 📝 验证步骤

### 验证 1: 检查数据库配置

启动后端后，查看日志：
```powershell
# 应该看到 SQLite 配置
Select-String -Path backend\data\backend.log -Pattern "sqlite"
```

**预期输出**:
```
spring.datasource.url=jdbc:sqlite:./data/wpsdoc.db
HHH000412: Hibernate ORM core version 6.4.4.Final
```

**不应该看到**:
```
jdbc:h2:mem:latexdb
H2Dialect
```

### 验证 2: 检查数据库文件

```powershell
# 应该看到 SQLite 数据库文件
Test-Path backend\data\wpsdoc.db
```

**预期**: `True`

### 验证 3: 检查数据持久化

1. 创建测试文档
2. 重启应用
3. 查看文档历史列表
4. **预期**: 文档仍然存在

---

## 🎯 推荐修复流程

### 快速修复（5分钟）

```powershell
# 1. 停止所有进程
Get-Process | Where-Object { $_.ProcessName -like "*electron*" -or $_.ProcessName -like "*java*" } | Stop-Process -Force

# 2. 删除旧的 release 目录
Remove-Item -Recurse -Force c:\GITProject\latexOnline\release

# 3. 使用开发模式启动
cd c:\GITProject\latexOnline
.\start-electron.ps1
```

### 完整修复（15分钟）

```powershell
# 1. 停止所有进程
Get-Process | Where-Object { $_.ProcessName -like "*electron*" -or $_.ProcessName -like "*java*" } | Stop-Process -Force

# 2. 重新构建后端
cd c:\GITProject\latexOnline\backend
mvn clean package -DskipTests

# 3. 重新构建前端
cd ..\frontend
npm run build

# 4. 复制最新 jar
cd ..
Copy-Item backend\target\latex-online-backend-1.1.0.jar electron\resources\backend\app.jar -Force

# 5. 重新打包 Electron
cd electron
npm run build:win

# 6. 测试打包版本
cd ..\release\win-unpacked
.\WpsDocEditor.exe
```

---

## 📊 对比分析

### 当前状态 vs 期望状态

| 项目 | 当前状态 | 期望状态 |
|------|----------|----------|
| JAR 文件位置 | `release\win-unpacked\resources\backend\app.jar` | `electron\resources\backend\app.jar` |
| 数据库类型 | H2 内存数据库 | SQLite 文件数据库 |
| 数据库 URL | `jdbc:h2:mem:latexdb` | `jdbc:sqlite:./data/wpsdoc.db` |
| 日志日期 | 2026-11-03 | 2026-11-05（今天） |
| 数据持久化 | ❌ 不支持 | ✅ 支持 |
| 重启后数据 | ❌ 丢失 | ✅ 保留 |

---

## 🔍 根本原因总结

### 主要原因
1. **Electron 运行的是旧的打包版本**（`release/win-unpacked/`）
2. **旧版本使用 H2 数据库配置**
3. **没有清理或更新打包版本**

### 次要原因
1. **开发模式和打包模式混淆**
2. **日志文件位置不明确**
3. **缺少版本检查机制**

---

## 📚 相关文档

- [BUILD.md](./BUILD.md) - 构建与部署指南
- [QUICKSTART.md](./QUICKSTART.md) - 快速开始指南
- [VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md) - 启动验证报告
- [TEST_SQLITE.md](./TEST_SQLITE.md) - SQLite 测试指南

---

## ✅ 修复检查清单

- [ ] 停止所有 Electron 和 Java 进程
- [ ] 删除旧的 `release` 目录
- [ ] 验证 `electron/resources/backend/app.jar` 是最新版本
- [ ] 验证 `application.properties` 配置为 SQLite
- [ ] 重新启动 Electron（开发模式或打包模式）
- [ ] 检查后端日志确认使用 SQLite
- [ ] 创建测试文档验证数据持久化
- [ ] 重启应用验证数据不丢失

---

**修复状态**: ⚠️ 需要手动执行修复步骤  
**预计修复时间**: 5-15 分钟  
**修复难度**: ⭐⭐☆☆☆（简单）
