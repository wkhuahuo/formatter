#!/bin/bash

PID_FILE=/home/administrator/latexOnline/.pids
PROJECT_DIR=/home/administrator/latexOnline

echo "============================="
echo " LaTeX 在线编辑系统 启动中..."
echo "============================="

# --- Clean up any existing processes ---
if [ -f "$PID_FILE" ]; then
  echo "[清理] 发现残留 PID 文件，正在清理..."
  read BPID FPID < $PID_FILE 2>/dev/null
  kill $BPID $FPID 2>/dev/null
  rm -f $PID_FILE
fi

# Kill anything still occupying the ports
for PORT in 8080 5174; do
  if fuser $PORT/tcp &>/dev/null; then
    echo "[清理] 关闭 $PORT 端口残留进程..."
    fuser -k $PORT/tcp 2>/dev/null
    sleep 1
  fi
done

# --- Start backend ---
echo "[1/2] 启动后端 (Spring Boot :8080)..."
cd $PROJECT_DIR/backend
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
cd $PROJECT_DIR/frontend
npm run dev > /tmp/latex-frontend.log 2>&1 &
FRONTEND_PID=$!
echo "      前端已就绪 (PID: $FRONTEND_PID)"

# Save PIDs
echo "$BACKEND_PID $FRONTEND_PID" > $PID_FILE

echo ""
echo "============================="
echo " 前端: http://localhost:5174"
echo " 后端: http://localhost:8080"
echo " 日志: /tmp/latex-backend.log"
echo "       /tmp/latex-frontend.log"
echo "============================="
echo " 停止服务: ./stop.sh"
