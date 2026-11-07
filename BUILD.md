# WPS 公文编辑器 - 构建与部署指南

## 📦 项目概述

**WPS 公文编辑器** 是一个基于 Electron + Spring Boot + Vue 3 的桌面应用程序，用于在线编辑和生成符合 GB/T 9704-2012 标准的公文文档。

### 技术栈
- **前端**: Vue 3.4 + Vite 5.2
- **后端**: Spring Boot 3.2.5 + SQLite
- **桌面**: Electron 31.x
- **文档引擎**: XeLaTeX + Apache POI

---

## 🚀 快速开始

### 开发模式

#### 1. 启动后端服务
```bash
cd backend
mvn spring-boot:run
```
后端将在 `http://localhost:8080` 启动

#### 2. 启动前端开发服务器
```bash
cd frontend
npm install
npm run dev
```
前端将在 `http://localhost:5174` 启动

#### 3. 启动 Electron（可选）
```bash
# 先构建后端 jar
cd backend
mvn clean package -DskipTests

# 构建前端静态文件
cd ../frontend
npm run build

# 启动 Electron
cd ../electron
npm install
npm run dev
```

---

## 🛠️ 生产构建

### Windows 免安装版（ZIP）

**一键构建脚本**：
```bash
./scripts/build.sh
```

**手动构建步骤**：

1. **构建前端**
```bash
cd frontend
npm install
npm run build
```
输出目录: `frontend/dist`

2. **构建后端**
```bash
cd backend
mvn clean package -DskipTests
```
输出文件: `backend/target/latex-online-backend-*.jar`

3. **复制 jar 到 Electron 资源目录**
```bash
mkdir -p electron/resources/backend
cp backend/target/latex-online-backend-*.jar electron/resources/backend/app.jar
```

4. **生成精简 JRE**
```bash
./scripts/build-runtime.sh
```
输出目录: `electron/resources/jre`

5. **打包 Electron**
```bash
cd electron
npm install
npm run build:win
```
输出目录: `release/*.zip`

---

## 📁 构建产物说明

### 开发模式
```
backend/target/*.jar      # 后端可执行 jar
frontend/dist/            # 前端构建产物（静态文件）
electron/resources/
  ├── backend/app.jar     # 后端 jar（固定名称）
  └── jre/                # 精简 Java 运行时
```

### 打包模式（Electron）
```
release/
  └── WpsDocEditor-1.0.0-win-x64.zip
      ├── WpsDocEditor.exe          # 主程序
      ├── resources/
      │   ├── app.asar              # 应用代码
      │   ├── backend/app.jar       # 后端服务
      │   ├── jre/                  # 内置 JRE
      │   └── webroot/              # 前端静态资源
      └── ...
```

---

## 🔧 配置说明

### 后端配置 (application.properties)

```properties
# SQLite 数据库路径
# 开发模式: ./data/wpsdoc.db
# 桌面模式: ${user.home}/AppData/Roaming/WpsDocEditor/data/wpsdoc.db
spring.datasource.url=${DB_URL:jdbc:sqlite:./data/wpsdoc.db}

# JWT 密钥（生产环境请替换）
jwt.secret=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6A1B2C3
jwt.expiration=86400000  # 24小时

# 服务端口（桌面模式使用随机端口）
server.port=8080
```

### Electron 配置 (package.json)

```json
{
  "main": "electron/main.js",
  "build": {
    "appId": "com.latexonline.wpsdoc",
    "productName": "WpsDocEditor",
    "extraResources": [
      { "from": "electron/resources/backend/app.jar", "to": "backend/app.jar" },
      { "from": "frontend/dist", "to": "webroot" },
      { "from": "electron/resources/jre", "to": "jre" }
    ]
  }
}
```

---

## 📊 数据库迁移（H2 → SQLite）

### 迁移要点

1. **驱动替换**
```xml
<!-- pom.xml -->
<dependency>
  <groupId>org.xerial</groupId>
  <artifactId>sqlite-jdbc</artifactId>
</dependency>
<dependency>
  <groupId>org.hibernate.orm</groupId>
  <artifactId>hibernate-community-dialects</artifactId>
</dependency>
```

2. **连接配置**
```properties
spring.datasource.driver-class-name=org.sqlite.JDBC
spring.datasource.url=jdbc:sqlite:./data/wpsdoc.db
spring.jpa.database-platform=org.hibernate.community.dialect.SQLiteDialect
```

3. **单写者模型**
```properties
# SQLite 不支持并发写入，连接池收成 1
spring.datasource.hikari.maximum-pool-size=1
```

### 数据表结构

**app_user 表**
```sql
CREATE TABLE app_user (
  id BIGINT PRIMARY KEY AUTOINCREMENT,
  username VARCHAR UNIQUE NOT NULL,
  password VARCHAR NOT NULL,
  approved BOOLEAN NOT NULL DEFAULT FALSE
);
```

**doc_record 表**
```sql
CREATE TABLE doc_record (
  id BIGINT PRIMARY KEY AUTOINCREMENT,
  username VARCHAR NOT NULL,
  doc_type VARCHAR NOT NULL,
  title VARCHAR NOT NULL,
  file_name VARCHAR NOT NULL,
  size_bytes BIGINT NOT NULL,
  content BLOB NOT NULL,
  created_at TIMESTAMP NOT NULL
);
```

---

## 🔐 默认账户

首次启动时会自动创建管理员账户：
- **用户名**: `admin`
- **密码**: `admin123`
- **角色**: `ADMIN`（已审批）

⚠️ **重要**: 生产环境请立即修改默认密码！

---

## 📝 功能特性

### 1. 用户管理
- ✅ 用户注册（需管理员审批）
- ✅ 用户登录（JWT 认证）
- ✅ 角色权限（ADMIN/USER）
- ✅ 用户列表管理

### 2. 公文编辑
- ✅ 红头文件编辑
- ✅ 会议纪要编辑
- ✅ 实时 PDF 预览
- ✅ Word 文档生成（.docx）
- ✅ 符合 GB/T 9704-2012 标准

### 3. 文档历史
- ✅ 文档持久化（SQLite）
- ✅ 按用户隔离
- ✅ 最近文档列表
- ✅ 重新下载功能
- ✅ 桌面版重启不丢失

### 4. 桌面应用
- ✅ 单实例锁
- ✅ 后端生命周期管理
- ✅ 本地文件保存
- ✅ 启动画面（Splash Screen）
- ✅ 随机端口避免冲突

---

## 🐛 常见问题

### 1. Electron 启动失败：缺少资源

**错误信息**:
```
启动失败：缺少运行资源
- 后端 jar：... → 执行 mvn clean package
- 前端资源：... → 执行 npm run build
```

**解决方案**:
```bash
# 构建后端
cd backend && mvn clean package -DskipTests

# 构建前端
cd ../frontend && npm run build

# 复制 jar
mkdir -p ../electron/resources/backend
cp target/latex-online-backend-*.jar ../electron/resources/backend/app.jar
```

### 2. 后端启动超时

**可能原因**:
- Java 未安装或版本不匹配
- 端口被占用
- SQLite 数据库锁定

**解决方案**:
```bash
# 检查 Java 版本
java -version  # 需要 17+

# 清理数据库锁文件
rm -f backend/data/*.db-shm backend/data/*.db-wal

# 查看后端日志
tail -f electron/resources/backend/app.log
```

### 3. SQLite 并发写入错误

**错误信息**: `database locked`

**解决方案**:
- 确认 `maximum-pool-size=1`
- 避免多进程同时写入
- 桌面版使用单实例锁

### 4. 文档历史丢失

**可能原因**:
- 数据库路径配置错误
- 桌面版未正确关闭

**解决方案**:
```bash
# 查看数据库位置
# Windows: %APPDATA%/WpsDocEditor/data/wpsdoc.db
# macOS: ~/Library/Application Support/WpsDocEditor/data/wpsdoc.db
# Linux: ~/.config/WpsDocEditor/data/wpsdoc.db

# 备份数据库文件
cp wpsdoc.db wpsdoc.db.backup
```

---

## 📦 分发与部署

### Windows
1. 解压 `release/WpsDocEditor-1.0.0-win-x64.zip`
2. 运行 `WpsDocEditor.exe`
3. 首次启动会自动创建配置文件

### macOS
1. 解压 `release/WpsDocEditor-1.0.0-mac.dmg`
2. 拖动到 Applications 文件夹
3. 首次运行需在"系统偏好设置 → 安全性与隐私"中允许

### Linux
1. 解压 `release/WpsDocEditor-1.0.0-linux.AppImage`
2. 添加执行权限: `chmod +x WpsDocEditor-1.0.0-linux.AppImage`
3. 运行: `./WpsDocEditor-1.0.0-linux.AppImage`

---

## 🔧 高级配置

### 自定义数据库路径

启动时通过环境变量指定：
```bash
# Windows
set DB_URL=jdbc:sqlite:D:/data/wpsdoc.db
electron .

# macOS/Linux
DB_URL=jdbc:sqlite:/path/to/wpsdoc.db electron .
```

### 修改 JWT 密钥

编辑 `backend/src/main/resources/application.properties`:
```properties
jwt.secret=your-new-secret-key-here
```

### 禁用用户注册

编辑 `backend/src/main/java/com/latexonline/controller/AuthController.java`:
```java
@PostMapping("/register")
public ResponseEntity<?> register(...) {
    return ResponseEntity.badRequest()
        .body(Map.of("success", false, "message", "注册功能已禁用"));
}
```

---

## 📄 许可证

Copyright © 2026 LaTeX Online Team

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

## 📧 联系方式

- 项目仓库: https://github.com/yourusername/latexOnline
- 问题反馈: https://github.com/yourusername/latexOnline/issues
