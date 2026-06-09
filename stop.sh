#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.pids"

if [ ! -f "$PID_FILE" ]; then
  echo "没有找到运行中的服务，尝试按端口清理..."
  # Fallback: kill by port (cross-platform)
  for PORT in 8080 5174; do
    PIDS=$(lsof -ti :$PORT 2>/dev/null)
    if [ -n "$PIDS" ]; then
      kill -9 $PIDS 2>/dev/null
    fi
  done
  echo "已清理 8080 / 5174 端口"
  exit 0
fi

echo "正在停止 LaTeX 在线编辑系统..."

read BACKEND_PID FRONTEND_PID < "$PID_FILE"

kill $BACKEND_PID 2>/dev/null && echo "后端已停止 (PID: $BACKEND_PID)"
kill $FRONTEND_PID 2>/dev/null && echo "前端已停止 (PID: $FRONTEND_PID)"

# Clean up any remaining child processes on the ports
for PORT in 8080 5174; do
  PIDS=$(lsof -ti :$PORT 2>/dev/null)
  if [ -n "$PIDS" ]; then
    kill -9 $PIDS 2>/dev/null
  fi
done

rm -f "$PID_FILE"
echo "所有服务已停止"
