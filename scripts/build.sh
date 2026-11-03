#!/bin/bash
# 一键构建 Windows 免安装版（zip）：前端 -> 后端 -> JRE -> Electron 打包
# 在 Linux/macOS 上交叉构建 Windows 的 zip 目标无需 wine；
# 若改打成 portable（单 exe）则需要 wine，见 package.json 的 win.target。
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=============== WPS 公文编辑器 构建 ==============="

echo "[1/4] 构建前端 -> frontend/dist"
cd "$ROOT/frontend"
npm install
npm run build

echo "[2/4] 构建后端 -> backend/target/*.jar"
cd "$ROOT/backend"
mvn -q clean package -DskipTests

echo "[3/4] 生成精简 JRE -> electron/resources/jre"
"$ROOT/scripts/build-runtime.sh"

echo "[4/4] 打包 Electron -> release/*.zip"
cd "$ROOT"
npm install
./node_modules/.bin/electron-builder --win --x64

echo "=============== 构建完成 ==============="
ls -lh "$ROOT/release"/*.zip 2>/dev/null || true
