#!/bin/bash

# 获取脚本所在目录（兼容 Ubuntu / macOS）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.pids"

echo "============================="
echo " WPS 在线编辑系统 启动中..."
echo "============================="

# --- Clean up any existing processes ---
if [ -f "$PID_FILE" ]; then
  echo "[清理] 发现残留 PID 文件，正在清理..."
  read BPID FPID < $PID_FILE 2>/dev/null
  kill $BPID $FPID 2>/dev/null
  rm -f $PID_FILE
fi

# Kill anything still occupying the ports (cross-platform: lsof works on both Linux and macOS)
for PORT in 8080 5174; do
  PIDS=$(lsof -ti :$PORT 2>/dev/null)
  if [ -n "$PIDS" ]; then
    echo "[清理] 关闭 $PORT 端口残留进程..."
    kill -9 $PIDS 2>/dev/null
    sleep 1
  fi
done

# --- Start backend ---
echo "[1/2] 启动后端 (Spring Boot :8080)..."
cd "$SCRIPT_DIR/backend"
mvn spring-boot:run -q > /tmp/latex-backend.log 2>&1 &
BACKEND_PID=$!

echo "      等待后端启动..."
for i in $(seq 1 60); do
  if curl -s http://localhost:8080/api/compile > /dev/null 2>&1; then
    break
  fi
  sleep 1
done
echo "      后端已就绪 (PID: $BACKEND_PID)"

# --- Start frontend ---
echo "[2/2] 启动前端 (Vue :5174)..."
cd "$SCRIPT_DIR/frontend"
npm run dev > /tmp/latex-frontend.log 2>&1 &
FRONTEND_PID=$!
echo "      前端已就绪 (PID: $FRONTEND_PID)"

# Save PIDs
echo "$BACKEND_PID $FRONTEND_PID" > "$PID_FILE"

echo ""
echo "============================="
echo " 前端: http://localhost:5174"
echo " 后端: http://localhost:8080"
echo " 日志: /tmp/latex-backend.log"
echo "       /tmp/latex-frontend.log"
echo "============================="
echo " 停止服务: ./stop.sh"
