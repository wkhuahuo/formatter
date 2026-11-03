#!/bin/bash

# debug.sh — 调试启动脚本
# 用法:
#   ./debug.sh              tmux 分屏同时运行前后端
#   ./debug.sh backend      仅启动后端（前台，日志实时输出）
#   ./debug.sh frontend     仅启动前端（前台，日志实时输出）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.pids"
BACKEND_LOG="/tmp/latex-backend.log"
FRONTEND_LOG="/tmp/latex-frontend.log"

TARGET="${1:-all}"

# ── 预检 ──
check_prereqs() {
  case "$1" in
    backend)
      command -v mvn &>/dev/null || { echo "[错误] 未找到 mvn"; exit 1; }
      ;;
    frontend)
      command -v npm &>/dev/null || { echo "[错误] 未找到 npm"; exit 1; }
      ;;
  esac
}

# ── 清理端口 ──
kill_port() {
  local PIDS=$(lsof -ti :$1 2>/dev/null)
  [ -n "$PIDS" ] && kill -9 $PIDS 2>/dev/null && echo "[清理] 端口 $1 已释放"
}

# ── 后端（前台运行，日志直接输出到终端） ──
run_backend() {
  check_prereqs backend
  echo "══════════════════════════════════════"
  echo "  后端调试模式 (Spring Boot :8080)"
  echo "  日志实时输出，Ctrl+C 停止"
  echo "══════════════════════════════════════"
  kill_port 8080
  cd "$SCRIPT_DIR/backend"
  mvn spring-boot:run
}

# ── 前端（前台运行，日志直接输出到终端） ──
run_frontend() {
  check_prereqs frontend
  echo "══════════════════════════════════════"
  echo "  前端调试模式 (Vite :5174)"
  echo "  日志实时输出，Ctrl+C 停止"
  echo "══════════════════════════════════════"
  kill_port 5174
  cd "$SCRIPT_DIR/frontend"
  [ ! -d "node_modules" ] && npm install
  npm run dev
}

# ── tmux 分屏模式 ──
run_tmux() {
  if ! command -v tmux &>/dev/null; then
    echo "[提示] 未安装 tmux，以后台 + tail 方式运行"
    run_fallback
    return
  fi

  local SESSION="latex-debug"

  # 清理旧 session
  tmux kill-session -t "$SESSION" 2>/dev/null

  # 预检
  check_prereqs backend
  check_prereqs frontend

  # 清理端口
  kill_port 8080
  kill_port 5174

  # 前端安装依赖（如果需要）
  cd "$SCRIPT_DIR/frontend"
  [ ! -d "node_modules" ] && npm install

  # 创建 tmux session，后端在左，前端在右
  tmux new-session -d -s "$SESSION" -n "backend"
  tmux send-keys -t "$SESSION" "cd $SCRIPT_DIR/backend && echo '════ 后端 Spring Boot :8080 ════' && mvn spring-boot:run" Enter

  tmux new-window -t "$SESSION" -n "frontend"
  tmux send-keys -t "$SESSION:frontend" "cd $SCRIPT_DIR/frontend && echo '════ 前端 Vite :5174 ════' && npm run dev" Enter

  # 分屏显示
  tmux select-window -t "$SESSION:backend"
  tmux split-window -h
  tmux select-pane -t 1
  tmux send-keys -t "$SESSION:backend.1" "cd $SCRIPT_DIR/frontend && echo '════ 前端 Vite :5174 ════' && npm run dev" Enter

  # 清理 backend 窗口
  tmux kill-window -t "$SESSION:frontend"

  echo "══════════════════════════════════════"
  echo "  tmux 调试会话已启动"
  echo "  左窗格: 后端 :8080  |  右窗格: 前端 :5174"
  echo "  tmux attach -t $SESSION    ← 进入"
  echo "  Ctrl+B D                   ← 退出（服务继续运行）"
  echo "  tmux kill-session -t $SESSION  ← 停止全部"
  echo "══════════════════════════════════════"

  # 自动 attach
  tmux attach -t "$SESSION"
}

# ── 后备模式（后台 + tail） ──
run_fallback() {
  check_prereqs backend
  check_prereqs frontend

  kill_port 8080
  kill_port 5174

  echo "══════════════════════════════════════"
  echo "  调试模式（后台运行 + tail 日志）"
  echo "  Ctrl+C 停止日志查看，服务继续运行"
  echo "  ./stop.sh 停止全部服务"
  echo "══════════════════════════════════════"

  # 启动后端
  echo "[后端] 启动中..."
  cd "$SCRIPT_DIR/backend"
  mvn spring-boot:run > "$BACKEND_LOG" 2>&1 &
  local BPID=$!

  # 启动前端
  echo "[前端] 启动中..."
  cd "$SCRIPT_DIR/frontend"
  [ ! -d "node_modules" ] && npm install
  npm run dev > "$FRONTEND_LOG" 2>&1 &
  local FPID=$!

  echo "$BPID $FPID" > "$PID_FILE"

  # 等待就绪
  echo "[等待] 服务启动中..."
  for i in $(seq 1 60); do
    local backend_ok=$(lsof -ti :8080 2>/dev/null)
    local frontend_ok=$(lsof -ti :5174 2>/dev/null)
    if [ -n "$backend_ok" ] && [ -n "$frontend_ok" ]; then
      break
    fi
    sleep 1
  done

  echo ""
  echo "══════════════════════════════════════"
  echo "  后端: http://localhost:8080  (tail -f $BACKEND_LOG)"
  echo "  前端: http://localhost:5174  (tail -f $FRONTEND_LOG)"
  echo "══════════════════════════════════════"

  # tail 两个日志
  tail -f "$BACKEND_LOG" "$FRONTEND_LOG"
}

# ── 主入口 ──
case "$TARGET" in
  all)      run_tmux ;;
  backend)  run_backend ;;
  frontend) run_frontend ;;
  *)
    echo "用法: ./debug.sh [all|backend|frontend]"
    exit 1
    ;;
esac
