#!/bin/bash

# 获取脚本所在目录（兼容 Ubuntu / macOS）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.pids"
BACKEND_LOG="/tmp/latex-backend.log"
FRONTEND_LOG="/tmp/latex-frontend.log"

echo "============================="
echo " WPS 在线编辑系统 启动中..."
echo "============================="

# --- Pre-flight checks ---
if ! command -v mvn &>/dev/null; then
  echo "[错误] 未找到 mvn 命令，请先安装 Maven"
  exit 1
fi
if ! command -v npm &>/dev/null; then
  echo "[错误] 未找到 npm 命令，请先安装 Node.js"
  exit 1
fi

# --- Clean up any existing processes ---
if [ -f "$PID_FILE" ]; then
  echo "[清理] 发现残留 PID 文件，正在清理..."
  read BPID FPID < $PID_FILE 2>/dev/null
  kill $BPID $FPID 2>/dev/null
  rm -f $PID_FILE
fi

# Kill anything still occupying the ports
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
mvn spring-boot:run -q > "$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!

echo "      等待后端启动（首次需下载依赖，可能较慢）..."
for i in $(seq 1 180); do
  if lsof -ti :8080 >/dev/null 2>&1; then
    echo "      后端已就绪 (PID: $BACKEND_PID, 耗时 ${i}s)"
    break
  fi
  if [ $((i % 5)) -eq 0 ]; then
    echo "      等待中... (${i}s)"
  fi
  # 进程已退出说明启动失败
  if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo ""
    echo "[错误] 后端进程异常退出！最近日志："
    tail -30 "$BACKEND_LOG"
    exit 1
  fi
  sleep 1
done

if ! lsof -ti :8080 >/dev/null 2>&1; then
  echo ""
  echo "[错误] 后端启动超时（180s），最近日志："
  tail -30 "$BACKEND_LOG"
  exit 1
fi

# --- Start frontend ---
echo "[2/2] 启动前端 (Vue :5174)..."
cd "$SCRIPT_DIR/frontend"
npm run dev > "$FRONTEND_LOG" 2>&1 &
FRONTEND_PID=$!

for i in $(seq 1 30); do
  if lsof -ti :5174 >/dev/null 2>&1; then
    echo "      前端已就绪 (PID: $FRONTEND_PID, 耗时 ${i}s)"
    break
  fi
  if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo ""
    echo "[错误] 前端进程异常退出！最近日志："
    tail -20 "$FRONTEND_LOG"
    exit 1
  fi
  sleep 1
done

# Save PIDs
echo "$BACKEND_PID $FRONTEND_PID" > "$PID_FILE"

echo ""
echo "============================="
echo " 前端: http://localhost:5174"
echo " 后端: http://localhost:8080"
echo " 日志: $BACKEND_LOG"
echo "       $FRONTEND_LOG"
echo "============================="
echo " 停止服务: ./stop.sh"
