# WPS 公文编辑器 - 快速开始指南

## 📖 项目简介

**WPS 公文编辑器** 是一款专为政府机关和企事业单位设计的公文编辑桌面应用。基于 Electron + Spring Boot + Vue 3 技术栈，支持在线编辑红头文件、会议纪要，自动生成符合 GB/T 9704-2012 标准的 Word 文档。

### ✨ 核心特性

- 📝 **公文编辑**: 红头文件、会议纪要在线编辑
- 🎨 **标准格式**: 符合 GB/T 9704-2012 国家公文标准
- 📄 **文档生成**: 一键生成 Word (.docx) 和 PDF 格式
- 💾 **历史持久化**: SQLite 数据库存储，重启不丢失
- 🔐 **用户管理**: JWT 认证，多用户权限控制
- 🖥️ **桌面应用**: Electron 打包，开箱即用

---

## 🚀 5 分钟快速启动

### 前置要求

- ✅ Java 17 或更高版本
- ✅ Node.js 16 或更高版本
- ✅ Maven 3.6+
- ✅ XeLaTeX（可选，用于 PDF 编译）

### 步骤 1: 克隆项目

```bash
git clone https://github.com/yourusername/latexOnline.git
cd latexOnline
```

### 步骤 2: 初始化数据库

首次运行会自动创建 SQLite 数据库和默认管理员账户：
- **用户名**: `admin`
- **密码**: `admin123`

### 步骤 3: 启动后端服务

```bash
cd backend
mvn spring-boot:run
```

后端将在 `http://localhost:8080` 启动。

### 步骤 4: 启动前端（开发模式）

```bash
cd frontend
npm install
npm run dev
```

访问 `http://localhost:5174` 即可使用。

### 步骤 5: 启动桌面应用（可选）

```bash
# 先构建前端和后端
cd frontend && npm run build
cd ../backend && mvn clean package -DskipTests

# 复制 jar 到 Electron 资源目录
mkdir -p ../electron/resources/backend
cp target/latex-online-backend-*.jar ../electron/resources/backend/app.jar

# 启动 Electron
cd ../electron
npm install
npm run dev
```

---

## 📦 一键构建（生产版本）

### Windows 用户

```bash
# 使用 Git Bash 或 WSL
./scripts/build.sh
```

### 手动构建步骤

1. **构建前端**
```bash
cd frontend
npm install
npm run build
```

2. **构建后端**
```bash
cd backend
mvn clean package -DskipTests
```

3. **生成精简 JRE**
```bash
./scripts/build-runtime.sh
```

4. **打包 Electron**
```bash
cd electron
npm install
npm run build:win
```

构建完成后，在 `release/` 目录下找到可执行文件。

---

## 🎯 使用指南

### 1. 登录系统

首次使用需要注册并等待管理员审批，或使用默认管理员账户登录。

### 2. 编辑红头文件

1. 点击首页"公文格式化"卡片
2. 填写红头单位、文号、标题等信息
3. 在正文区域输入内容（支持 Markdown 风格标题）
4. 右侧实时预览 PDF 效果
5. 点击"下载 PDF"或"保存 Word"

### 3. 编辑会议纪要

1. 点击首页"会议纪要格式化"卡片
2. 填写会议基本信息（时间、地点、主持人）
3. 添加参会人员
4. 编辑议题和决议内容
5. 生成 Word 文档

### 4. 查看历史文档

- 登录后自动显示最近编辑的文档列表
- 点击文档可重新下载或编辑
- 支持删除历史记录

### 5. 用户管理（管理员）

1. 点击右上角"用户管理"按钮
2. 查看待审批用户列表
3. 审批或拒绝用户注册

---

## 🗂️ 数据存储位置

### 开发模式
```
backend/data/wpsdoc.db    # SQLite 数据库文件
```

### 桌面应用
```
Windows: %APPDATA%/WpsDocEditor/data/wpsdoc.db
macOS:   ~/Library/Application Support/WpsDocEditor/data/wpsdoc.db
Linux:   ~/.config/WpsDocEditor/data/wpsdoc.db
```

### 备份数据库
```bash
# Windows
copy "%APPDATA%\WpsDocEditor\data\wpsdoc.db" "backup.db"

# macOS/Linux
cp ~/Library/Application\ Support/WpsDocEditor/data/wpsdoc.db backup.db
```

---

## 🔧 配置说明

### 修改端口

编辑 `backend/src/main/resources/application.properties`:
```properties
server.port=8080  # 修改为其他端口
```

### 修改 JWT 密钥

```properties
jwt.secret=your-new-secret-key-here
```

### 修改数据库路径

启动时指定环境变量:
```bash
# Windows
set DB_URL=jdbc:sqlite:D:/data/wpsdoc.db

# macOS/Linux
export DB_URL=jdbc:sqlite:/path/to/wpsdoc.db

# 启动后端
mvn spring-boot:run
```

---

## 🐛 常见问题

### 1. 后端启动失败

**错误**: `Port 8080 already in use`

**解决**: 
```bash
# 查找占用端口的进程
netstat -ano | findstr :8080

# 杀死进程（Windows）
taskkill /PID <进程ID> /F

# 或修改配置文件使用其他端口
```

### 2. Electron 无法启动

**错误**: `缺少运行资源`

**解决**:
```bash
# 确保已构建前端和后端
cd frontend && npm run build
cd ../backend && mvn clean package -DskipTests

# 复制 jar 到正确位置
mkdir -p ../electron/resources/backend
cp target/latex-online-backend-*.jar ../electron/resources/backend/app.jar
```

### 3. 数据库锁定

**错误**: `database locked`

**解决**:
```bash
# 关闭所有应用实例
# 删除锁文件
rm -f backend/data/*.db-shm backend/data/*.db-wal

# 重新启动
```

### 4. PDF 编译失败

**错误**: `xelatex: command not found`

**解决**: 安装 TeX Live 或 MiKTeX，并确保 `xelatex` 在 PATH 中。

---

## 📚 技术文档

详细技术文档请查看：
- [BUILD.md](./BUILD.md) - 完整构建与部署指南
- [electron/build/README.md](./electron/build/README.md) - 应用图标说明

---

## 🔐 安全建议

1. **修改默认密码**: 首次登录后立即修改 `admin` 账户密码
2. **定期备份数据库**: 复制 `wpsdoc.db` 文件到安全位置
3. **限制注册功能**: 生产环境可禁用用户自助注册
4. **更新 JWT 密钥**: 使用强随机字符串替换默认密钥

---

## 📞 获取帮助

- 📖 查看完整文档: [BUILD.md](./BUILD.md)
- 🐛 报告问题: [GitHub Issues](https://github.com/yourusername/latexOnline/issues)
- 💬 讨论交流: [GitHub Discussions](https://github.com/yourusername/latexOnline/discussions)

---

## 🎉 开始使用

现在你已经准备好了！启动应用并开始编辑你的第一份公文吧。

```bash
# 快速启动命令
cd backend && mvn spring-boot:run
# 另一个终端
cd frontend && npm run dev
```

祝你使用愉快！ 🚀
