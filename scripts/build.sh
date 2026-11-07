#!/bin/bash
# WPS 公文编辑器 - 构建脚本（适用于 macOS 和 Linux）
# 用法: ./scripts/build.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  WPS 公文编辑器 构建${NC}"
echo -e "${CYAN}=====================================${NC}\n"

# 获取项目根目录
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 1. 构建前端
echo -e "${YELLOW}[1/4] 构建前端 -> frontend/dist${NC}"
cd "$ROOT/frontend"
if npm install && npm run build; then
    echo -e "${GREEN}      ✅ 前端构建成功${NC}"
else
    echo -e "${RED}      ❌ 前端构建失败${NC}"
    exit 1
fi

# 2. 构建后端
echo -e "\n${YELLOW}[2/4] 构建后端 -> backend/target/*.jar${NC}"
cd "$ROOT/backend"
if mvn -q clean package -DskipTests; then
    echo -e "${GREEN}      ✅ 后端构建成功${NC}"
else
    echo -e "${RED}      ❌ 后端构建失败${NC}"
    exit 1
fi

# 复制 JAR 文件
mkdir -p "$ROOT/electron/resources/backend"
JAR_SOURCE=$(ls "$ROOT"/backend/target/latex-online-backend-*.jar 2>/dev/null | head -n 1)
if [ -n "$JAR_SOURCE" ]; then
    cp "$JAR_SOURCE" "$ROOT/electron/resources/backend/app.jar"
    echo -e "${GREEN}      ✅ 已复制 jar -> electron/resources/backend/app.jar${NC}"
else
    echo -e "${RED}      ❌ 未找到 JAR 文件${NC}"
    exit 1
fi

# 3. 构建 JRE（可选）
echo -e "\n${YELLOW}[3/4] 检查 JRE...${NC}"
JRE_PATH="$ROOT/electron/resources/jre"
if [ -f "$JRE_PATH/bin/java" ] || [ -f "$JRE_PATH/bin/java.exe" ]; then
    echo -e "${GREEN}      ✅ JRE 已存在${NC}"
else
    echo -e "${YELLOW}      ⚠ JRE 未找到${NC}"
    echo -e "${YELLOW}      提示: 运行 scripts/build-runtime.sh 生成 JRE${NC}"
    if [ -f "$ROOT/scripts/build-runtime.sh" ]; then
        read -p "是否现在构建 JRE？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chmod +x "$ROOT/scripts/build-runtime.sh"
            "$ROOT/scripts/build-runtime.sh"
        fi
    fi
fi

# 4. 打包 Electron
echo -e "\n${YELLOW}[4/4] 打包 Electron -> release/*.zip${NC}"
cd "$ROOT"
if npm install; then
    echo -e "${GREEN}      ✅ 依赖安装成功${NC}"
else
    echo -e "${RED}      ❌ 依赖安装失败${NC}"
    exit 1
fi

if npx electron-builder --win --x64; then
    echo -e "${GREEN}      ✅ Electron 打包成功${NC}"
else
    echo -e "${RED}      ❌ Electron 打包失败${NC}"
    exit 1
fi

# 显示构建结果
echo -e "\n${CYAN}=====================================${NC}"
echo -e "${GREEN}  构建完成！${NC}"
echo -e "${CYAN}=====================================${NC}\n"

echo -e "${YELLOW}构建产物:${NC}"
if ls "$ROOT"/release/*.zip 1> /dev/null 2>&1; then
    for file in "$ROOT"/release/*.zip; do
        SIZE=$(du -h "$file" | cut -f1)
        echo -e "${GREEN}  $(basename "$file") - $SIZE${NC}"
    done
    echo -e "\n${CYAN}提示:${NC}"
    echo -e "${GRAY}  - 使用 ./scripts/sync-push.sh 推送到远程仓库${NC}"
    echo -e "${GRAY}  - 手动上传到 GitHub 和 Gitee 的 Release 页面${NC}"
else
    echo -e "${RED}未找到构建产物，请检查构建日志${NC}"
fi
