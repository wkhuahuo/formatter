#!/bin/bash
# Git 同步脚本 - 推送到所有远程仓库（适用于 macOS 和 Linux）
# 用法: ./scripts/sync-push.sh [选项]
#
# 选项:
#   -b, --branch <分支名>    推送特定分支
#   -t, --no-tags           不推送标签
#   -n, --dry-run           预览操作（不实际执行）
#   -h, --help              显示帮助信息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# 默认参数
BRANCH=""
INCLUDE_TAGS=true
DRY_RUN=false

# 显示帮助
show_help() {
    cat << EOF
${CYAN}=====================================${NC}
${CYAN}  Git 同步推送 - GitHub & Gitee${NC}
${CYAN}=====================================${NC}

${YELLOW}用法:${NC}
  ./scripts/sync-push.sh [选项]

${YELLOW}选项:${NC}
  -b, --branch <分支名>    推送特定分支（默认：当前分支）
  -t, --no-tags           不推送标签
  -n, --dry-run           预览操作（不实际执行）
  -h, --help              显示帮助信息

${YELLOW}示例:${NC}
  ./scripts/sync-push.sh                    # 推送当前分支和标签
  ./scripts/sync-push.sh -b master          # 推送 master 分支
  ./scripts/sync-push.sh --no-tags          # 不推送标签
  ./scripts/sync-push.sh --dry-run          # 预览操作

EOF
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -t|--no-tags)
            INCLUDE_TAGS=false
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
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

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}  Git 同步推送 - GitHub & Gitee${NC}"
echo -e "${CYAN}=====================================${NC}\n"

# 获取当前分支
if [ -z "$BRANCH" ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo -e "${YELLOW}当前分支:${NC} $BRANCH"
echo -e "${YELLOW}包含标签:${NC} $INCLUDE_TAGS"
echo -e "${YELLOW}预览模式:${NC} $DRY_RUN\n"

# 检查是否有未提交的更改
STATUS=$(git status --porcelain)
if [ -n "$STATUS" ]; then
    echo -e "${YELLOW}⚠ 警告: 有未提交的更改${NC}"
    echo "$STATUS"
    read -p "是否继续推送？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${RED}❌ 同步已取消${NC}"
        exit 0
    fi
fi

# 推送到 GitHub (origin)
echo -e "\n${YELLOW}[1/2] 推送到 GitHub (origin)...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${GRAY}  [DRY RUN] git push origin $BRANCH${NC}"
else
    if git push origin "$BRANCH"; then
        echo -e "${GREEN}  ✅ GitHub 推送成功${NC}"
    else
        echo -e "${RED}  ❌ GitHub 推送失败${NC}"
    fi
fi

# 推送到 Gitee
echo -e "\n${YELLOW}[2/2] 推送到 Gitee (gitee)...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${GRAY}  [DRY RUN] git push gitee $BRANCH${NC}"
else
    if git push gitee "$BRANCH" 2>/dev/null; then
        echo -e "${GREEN}  ✅ Gitee 推送成功${NC}"
    else
        echo -e "${YELLOW}  ⚠ Gitee 推送失败或无更改${NC}"
    fi
fi

# 推送标签
if [ "$INCLUDE_TAGS" = true ]; then
    echo -e "\n${YELLOW}[标签] 推送所有标签...${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${GRAY}  [DRY RUN] git push origin --tags${NC}"
        echo -e "${GRAY}  [DRY RUN] git push gitee --tags${NC}"
    else
        # 推送标签到 GitHub
        if git push origin --tags 2>/dev/null; then
            echo -e "${GREEN}  ✅ 标签已推送到 GitHub${NC}"
        else
            echo -e "${RED}  ❌ 标签推送到 GitHub 失败${NC}"
        fi
        
        # 推送标签到 Gitee
        if git push gitee --tags 2>/dev/null; then
            echo -e "${GREEN}  ✅ 标签已推送到 Gitee${NC}"
        else
            echo -e "${YELLOW}  ⚠ 标签推送到 Gitee 失败${NC}"
        fi
    fi
fi

echo -e "\n${CYAN}=====================================${NC}"
echo -e "${GREEN}  同步完成！${NC}"
echo -e "${CYAN}=====================================${NC}\n"

# 显示远程仓库信息
echo -e "${YELLOW}远程仓库:${NC}"
echo -e "  origin (GitHub): https://github.com/wkhuahuo/formatter"
echo -e "  gitee  (Gitee):  https://gitee.com/wkhuahuo/latexOnline"

echo -e "\n${CYAN}提示:${NC}"
echo -e "${GRAY}  - 使用 --dry-run 参数预览操作${NC}"
echo -e "${GRAY}  - 使用 -b <分支名> 推送特定分支${NC}"
echo -e "${GRAY}  - 使用 --no-tags 跳过标签推送${NC}"
echo -e "${GRAY}  - 使用 --help 查看完整帮助${NC}"
