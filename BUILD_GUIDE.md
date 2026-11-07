# 构建桌面应用包 - 完整指南

本文档详细说明如何构建 WPS 公文编辑器的桌面应用包。

## 📋 前置条件

### 必需工具

| 工具 | 版本要求 | 用途 | 状态 |
|------|---------|------|------|
| **Node.js** | 18+ | 前端构建和 Electron 打包 | ❌ 需安装 |
| **npm** | 9+ | Node 包管理器（随 Node.js 安装） | ❌ 需安装 |
| **Java** | 17+ | 后端编译 | ✅ 已安装 |
| **Maven** | 3.9+ | 后端构建 | ✅ 已安装 |
| **Git** | 任意 | 版本控制 | ✅ 已安装 |

## 🚀 快速构建（推荐）

### 方式一：使用构建脚本（一键构建）

```powershell
# 1. 安装 Node.js（见下方说明）
# 2. 运行构建脚本
.\scripts\build.ps1

# 构建产物在 release/ 目录下
```

### 方式二：手动构建（分步执行）

```powershell
# 1. 构建前端
cd frontend
npm install
npm run build
cd ..

# 2. 构建后端
cd backend
mvn clean package -DskipTests
cd ..

# 3. 复制 JAR 文件
mkdir -p electron/resources/backend
copy backend\target\latex-online-backend-*.jar electron\resources\backend\app.jar

# 4. 打包 Electron
npm install
npx electron-builder --win --x64

# 构建产物在 release/ 目录下
```

## 📥 安装 Node.js

### 方法 1：官方安装器（推荐）

1. **下载 Node.js**
   - 访问：https://nodejs.org/
   - 下载 LTS 版本（推荐 18.x 或 20.x）
   - 选择 Windows Installer (.msi)

2. **安装**
   - 双击下载的 .msi 文件
   - 按照向导完成安装
   - 使用默认选项即可

3. **验证安装**
   ```powershell
   # 重新打开 PowerShell
   node --version    # 应显示 v18.x.x 或更高
   npm --version     # 应显示 9.x.x 或更高
   ```

### 方法 2：使用 Chocolatey（Windows 包管理器）

```powershell
# 如果已安装 Chocolatey
choco install nodejs-lts -y

# 验证安装
node --version
npm --version
```

### 方法 3：使用 nvm-windows（Node 版本管理器）

```powershell
# 1. 下载 nvm-windows
# https://github.com/coreybutler/nvm-windows/releases

# 2. 安装后，使用 nvm 安装 Node.js
nvm install 18
nvm use 18

# 3. 验证
node --version
npm --version
```

## 🔧 配置 npm（可选）

### 设置国内镜像（加速下载）

```powershell
# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com

# 验证配置
npm config get registry
```

### 设置代理（如需要）

```powershell
# 如果有代理
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080
```

## 📦 构建流程详解

### 1. 前端构建

```powershell
cd frontend

# 安装依赖
npm install

# 构建生产版本
npm run build

# 输出：frontend/dist/
```

**说明**：
- 使用 Vite 构建工具
- 生成静态文件到 `frontend/dist/`
- 包含 HTML、CSS、JavaScript

### 2. 后端构建

```powershell
cd backend

# 清理并打包
mvn clean package -DskipTests

# 输出：backend/target/latex-online-backend-*.jar
```

**说明**：
- 使用 Maven 构建
- 生成可执行 JAR 文件
- 包含所有依赖

### 3. 准备 Electron 资源

```powershell
# 创建目录
mkdir -p electron/resources/backend

# 复制 JAR
copy backend\target\latex-online-backend-*.jar electron\resources\backend\app.jar
```

**说明**：
- 将后端 JAR 放到固定位置
- Electron 打包时会包含此文件

### 4. JRE 准备（重要）

**方式 A：使用已有 JRE**
```powershell
# 如果 electron/resources/jre/ 已存在，跳过此步骤
```

**方式 B：生成精简 JRE**
```powershell
# 运行 JRE 构建脚本
.\scripts\build-runtime.sh

# 或使用系统 JRE
# 修改 package.json，移除 extraResources 中的 jre 配置
```

**说明**：
- 应用需要 JRE 才能运行
- 可以使用精简版 JRE（推荐）
- 或依赖用户系统的 JRE

### 5. Electron 打包

```powershell
# 安装依赖
npm install

# 打包 Windows 版本
npx electron-builder --win --x64

# 输出：release/WpsDocEditor-X.Y.Z-win.zip
```

**说明**：
- 使用 electron-builder 打包
- 生成 Windows 64位免安装版
- 包含应用、JRE、前端、后端

## 📊 构建产物

### 输出文件

```
release/
└── WpsDocEditor-X.Y.Z-win.zip    # Windows 免安装压缩包
```

### 文件结构（解压后）

```
WpsDocEditor/
├── WpsDocEditor.exe               # 主程序
├── resources/
│   ├── backend/
│   │   └── app.jar               # 后端服务
│   ├── jre/                      # 内置 JRE
│   │   └── bin/
│   │       └── java.exe
│   └── webroot/                  # 前端资源
│       ├── index.html
│       └── ...
└── ...
```

## 🎯 平台特定构建

### Windows（当前平台）

```powershell
# 构建 Windows 版本
npx electron-builder --win --x64

# 或构建所有格式
npx electron-builder --win
```

**输出格式**：
- `.zip` - 免安装压缩包（当前配置）
- `.exe` - 安装程序（需修改 package.json）

### macOS（需要 macOS 系统）

```bash
# 构建 macOS 版本
./scripts/build.sh

# 或单独执行
npx electron-builder --mac --x64
```

**输出格式**：
- `.dmg` - 磁盘镜像
- `.zip` - 压缩包

### Linux Ubuntu

```bash
# 构建 Linux 版本
./scripts/build.sh

# 或单独执行
npx electron-builder --linux
```

**输出格式**：
- `.AppImage` - 免安装运行
- `.deb` - Debian/Ubuntu 安装包
- `.rpm` - RedHat/CentOS 安装包

## ⚙️ 修改构建配置

### package.json 配置

```json
{
  "build": {
    "appId": "com.latexonline.wpsdoc",
    "productName": "WpsDocEditor",
    "directories": {
      "output": "release"
    },
    "extraResources": [
      {
        "from": "electron/resources/backend/app.jar",
        "to": "backend/app.jar"
      },
      {
        "from": "frontend/dist",
        "to": "webroot"
      },
      {
        "from": "electron/resources/jre",
        "to": "jre"
      }
    ],
    "win": {
      "target": ["zip", "nsis"]  // 可添加 nsis 生成安装程序
    },
    "mac": {
      "target": ["dmg", "zip"]
    },
    "linux": {
      "target": ["AppImage", "deb", "rpm"]
    }
  }
}
```

## 🐛 常见问题

### Q1: npm install 失败

**解决方案**：
```powershell
# 清除缓存
npm cache clean --force

# 删除 node_modules
Remove-Item -Recurse -Force node_modules

# 重新安装
npm install

# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com
```

### Q2: 构建时找不到 Java

**解决方案**：
```powershell
# 检查 Java 安装
java -version

# 设置 JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"

# 或永久设置
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-17', 'User')
```

### Q3: electron-builder 打包失败

**解决方案**：
```powershell
# 更新 electron-builder
npm install -g electron-builder@latest

# 清除缓存
Remove-Item -Recurse -Force ~\AppData\Local\electron-builder\Cache

# 重试打包
npx electron-builder --win --x64
```

### Q4: JRE 未找到

**解决方案**：
```powershell
# 方式 1：使用现有 JRE
# 将 JRE 复制到 electron/resources/jre/

# 方式 2：生成精简 JRE
.\scripts\build-runtime.sh

# 方式 3：修改配置，使用系统 JRE
# 编辑 package.json，移除 jre 相关的 extraResources
```

### Q5: 打包文件过大

**优化方案**：
```json
// package.json
{
  "build": {
    "win": {
      "target": "zip"  // 使用 zip 而非 nsis
    },
    "files": [
      "!**/*.map",
      "!**/*.ts"
    ]
  }
}
```

## 📚 相关文档

- [跨平台脚本使用指南](./CROSS_PLATFORM_SCRIPTS.md)
- [分支管理策略](./BRANCH_STRATEGY.md)
- [发布检查清单](./RELEASE_CHECKLIST.md)
- [主镜像仓库配置](./MIRROR_CONFIG.md)

## 🎉 开始构建

### 快速开始（推荐）

```powershell
# 1. 安装 Node.js（如果还没安装）
# 访问: https://nodejs.org/

# 2. 运行构建脚本
.\scripts\build.ps1

# 3. 查看构建产物
Get-ChildItem release\*.zip
```

### 验证构建

```powershell
# 解压构建产物
Expand-Archive release\WpsDocEditor-*.zip -DestinationPath test-release

# 运行应用
.\test-release\WpsDocEditor.exe
```

## 📊 构建时间估算

| 步骤 | 时间 |
|------|------|
| 前端构建 | 1-2 分钟 |
| 后端构建 | 1-2 分钟 |
| Electron 打包 | 2-3 分钟 |
| **总计** | **5-10 分钟** |

**注意**：首次构建会较慢（需要下载依赖），后续构建会快很多。

---

**最后更新**: 2026-11-07  
**适用平台**: Windows/macOS/Linux
