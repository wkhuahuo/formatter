#!/bin/bash
# WPS 公文编辑器 - 发布脚本（适用于 macOS 和 Linux）
# 用法: ./scripts/publish.sh -v <版本号> [选项]
#
# 选项:
#   -v, --version <版本>     版本号（必填，格式：X.Y.Z）
#   -r, --remote <名称>      远程仓库名称（默认：origin）
#   -s, --skip-build         跳过构建步骤
#   --no-sync-gitee          不同步到 Gitee
#   -h, --help               显示帮助信息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# 默认参数
VERSION=""
REMOTE_NAME="origin"
SKIP_BUILD=false
SYNC_TO_GITEE=true

# 显示帮助
show_help() {
    cat << EOF
${CYAN}=====================================${NC}
${CYAN}  WPS 公文编辑器 发布工具${NC}
${CYAN}=====================================${NC}

${YELLOW}用法:${NC}
  ./scripts/publish.sh -v <版本号> [选项]

${YELLOW}选项:${NC}
  -v, --version <版本>     版本号（必填，格式：X.Y.Z）
  -r, --remote <名称>      远程仓库名称（默认：origin）
  -s, --skip-build         跳过构建步骤
  --no-sync-gitee          不同步到 Gitee 镜像
  -h, --help               显示帮助信息

${YELLOW}示例:${NC}
  ./scripts/publish.sh -v 1.0.0              # 发布版本 1.0.0
  ./scripts/publish.sh -v 1.0.1 --skip-build # 跳过构建
  ./scripts/publish.sh -v 2.0.0 --no-sync-gitee  # 不同步到 Gitee

EOF
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -r|--remote)
            REMOTE_NAME="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --no-sync-gitee)
            SYNC_TO_GITEE=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 验证版本号
if [ -z "$VERSION" ]; then
    echo -e "${RED}错误: 版本号不能为空${NC}"
    show_help
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}错误: 版本号格式不正确，应为 X.Y.Z（例如：1.0.0）${NC}"
    exit 1
fi

TAG_VERSION="v$VERSION"

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  WPS 公文编辑器 发布${NC}"
echo -e "${CYAN}=====================================${NC}\n"

echo -e "${YELLOW}版本号:${NC} $TAG_VERSION"
echo -e "${YELLOW}主仓库:${NC} $REMOTE_NAME (GitHub)"
if [ "$SYNC_TO_GITEE" = true ]; then
    echo -e "${YELLOW}镜像仓库:${NC} gitee (Gitee)"
fi

# 检查远程仓库是否存在
REMOTES=$(git remote -v)
if ! echo "$REMOTES" | grep -q "$REMOTE_NAME"; then
    echo -e "${RED}错误: 未找到名为 '$REMOTE_NAME' 的远程仓库${NC}"
    echo -e "${YELLOW}当前远程仓库:${NC}"
    echo "$REMOTES"
    echo -e "\n${CYAN}提示:${NC} 使用 'git remote add origin https://github.com/YOUR_USERNAME/latexOnline.git' 添加"
    exit 1
fi

# 检查是否有未提交的更改
STATUS=$(git status --porcelain)
if [ -n "$STATUS" ]; then
    echo -e "\n${YELLOW}⚠ 警告: 有未提交的更改${NC}"
    echo "$STATUS"
    read -p "是否继续发布？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${RED}❌ 发布已取消${NC}"
        exit 0
    fi
fi

# 1. 更新版本号
echo -e "\n${YELLOW}[1/5] 更新版本号...${NC}"

# 更新 package.json 版本号（如果存在）
if [ -f "package.json" ]; then
    if command -v node &> /dev/null; then
        node -e "const fs = require('fs'); const pkg = JSON.parse(fs.readFileSync('package.json')); pkg.version = '$VERSION'; fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));"
        echo -e "${GREEN}      ✅ 已更新 package.json 版本号为 $VERSION${NC}"
    else
        echo -e "${YELLOW}      ⚠ Node.js 未安装，跳过 package.json 更新${NC}"
    fi
else
    echo -e "${GRAY}      package.json 不存在，跳过${NC}"
fi

# 2. 构建（可选）
if [ "$SKIP_BUILD" = false ]; then
    echo -e "\n${YELLOW}[2/5] 执行构建...${NC}"
    
    # 检查是否有构建脚本
    if [ -f "scripts/build.sh" ]; then
        chmod +x scripts/build.sh
        if ./scripts/build.sh; then
            echo -e "${GREEN}      ✅ 构建成功${NC}"
        else
            echo -e "${RED}      ❌ 构建失败${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}      ⚠ 构建脚本不存在，跳过构建${NC}"
    fi
else
    echo -e "\n${YELLOW}[2/5] 跳过构建（使用 --skip-build 参数）${NC}"
fi

# 3. 提交更改
echo -e "\n${YELLOW}[3/5] 提交更改...${NC}"
git add package.json 2>/dev/null || true
git add .
if git commit -m "chore: bump version to $VERSION" > /dev/null 2>&1; then
    echo -e "${GREEN}      ✅ 已提交版本更新${NC}"
else
    echo -e "${GRAY}      无更改需要提交${NC}"
fi

# 4. 创建标签
echo -e "\n${YELLOW}[4/5] 创建标签...${NC}"
git tag "$TAG_VERSION" -m "Release version $VERSION"
echo -e "${GREEN}      ✅ 已创建标签 $TAG_VERSION${NC}"

# 5. 推送到远程仓库
echo -e "\n${YELLOW}[5/5] 推送到远程仓库...${NC}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 推送到 GitHub（主仓库）
echo -e "${WHITE}      推送到 GitHub ($REMOTE_NAME)...${NC}"
if git push "$REMOTE_NAME" "$CURRENT_BRANCH" 2>&1; then
    echo -e "${GREEN}      ✅ 已推送到 GitHub${NC}"
else
    echo -e "${RED}      ❌ 推送到 GitHub 失败${NC}"
fi

if git push "$REMOTE_NAME" "$TAG_VERSION" 2>&1; then
    echo -e "${GREEN}      ✅ 标签已推送到 GitHub${NC}"
else
    echo -e "${RED}      ❌ 标签推送到 GitHub 失败${NC}"
fi

# 推送到 Gitee（镜像仓库）
if [ "$SYNC_TO_GITEE" = true ]; then
    echo -e "${WHITE}      同步到 Gitee (gitee)...${NC}"
    if git push gitee "$CURRENT_BRANCH" 2>/dev/null; then
        echo -e "${GREEN}      ✅ 已同步到 Gitee${NC}"
    else
        echo -e "${YELLOW}      ⚠ 同步到 Gitee 失败或无更改${NC}"
    fi
    
    if git push gitee "$TAG_VERSION" 2>/dev/null; then
        echo -e "${GREEN}      ✅ 标签已同步到 Gitee${NC}"
    else
        echo -e "${YELLOW}      ⚠ 标签同步到 Gitee 失败${NC}"
    fi
fi

echo -e "\n${CYAN}=====================================${NC}"
echo -e "${GREEN}  发布完成！${NC}"
echo -e "${CYAN}=====================================${NC}\n"

echo -e "${CYAN}后续步骤:${NC}"
echo -e "${YELLOW}1. 访问 GitHub Actions 查看构建进度:${NC}"
echo -e "   https://github.com/wkhuahuo/formatter/actions"
echo -e "\n${YELLOW}2. 构建完成后，在 GitHub Release 页面查看:${NC}"
echo -e "   https://github.com/wkhuahuo/formatter/releases/tag/$TAG_VERSION"
echo -e "\n${YELLOW}3. 下载构建产物并上传到 Gitee Release 页面:${NC}"
echo -e "   https://gitee.com/wkhuahuo/latexOnline/releases/new"
echo -e "\n${CYAN}提示:${NC}"
echo -e "${GRAY}  - 使用 --help 查看完整帮助${NC}"
echo -e "${GRAY}  - 使用 --skip-build 跳过构建步骤${NC}"
echo -e "${GRAY}  - 使用 --no-sync-gitee 跳过 Gitee 同步${NC}"
