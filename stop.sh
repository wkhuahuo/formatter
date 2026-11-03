#!/bin/bash

# 定位到脚本所在目录，避免硬编码绝对路径
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$PROJECT_DIR/.pids"

if [ ! -f "$PID_FILE" ]; then
  echo "没有找到运行中的服务，尝试按端口清理..."
  # Fallback: kill by port
  fuser -k 8080/tcp 2>/dev/null
  fuser -k 5174/tcp 2>/dev/null
  echo "已清理 8080 / 5174 端口"
  exit 0
fi

echo "正在停止 WPS 在线编辑系统..."

read BACKEND_PID FRONTEND_PID < "$PID_FILE"

kill $BACKEND_PID 2>/dev/null && echo "后端已停止 (PID: $BACKEND_PID)"
kill $FRONTEND_PID 2>/dev/null && echo "前端已停止 (PID: $FRONTEND_PID)"

# Clean up any remaining child processes on the ports
fuser -k 8080/tcp 2>/dev/null
fuser -k 5174/tcp 2>/dev/null

rm -f "$PID_FILE"
echo "所有服务已停止"
