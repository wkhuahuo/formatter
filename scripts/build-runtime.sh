#!/bin/bash
# 用 jlink 生成一个可随包分发的精简 Java 运行时。
# 模块说明：
#   java.se         Spring Boot / Tomcat / POI 主体所需（含 java.xml、java.desktop、java.sql 等）
#   jdk.unsupported 部分库依赖 sun.misc.Unsafe
#   jdk.crypto.ec   TLS/HTTPS
#   jdk.xml.dom     XMLBeans（poi-ooxml 依赖）
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/electron/resources/jre"

if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/jlink" ]; then
  JDK="$JAVA_HOME"
elif command -v jlink >/dev/null 2>&1; then
  JDK="$(dirname "$(dirname "$(readlink -f "$(command -v jlink)")")")"
else
  echo "[JRE] 错误：未找到 jlink，请安装 JDK 17 或设置 JAVA_HOME。" >&2
  exit 1
fi

rm -rf "$OUT"
echo "[JRE] 使用 JDK：$JDK"

if "$JDK/bin/jlink" \
  --module-path "$JDK/jmods" \
  --add-modules java.se,jdk.unsupported,jdk.crypto.ec,jdk.xml.dom \
  --strip-debug --no-man-pages --no-header-files \
  --output "$OUT"; then
  echo "[JRE] 精简运行时已生成：$OUT"
else
  echo "[JRE] 警告：jlink 失败，回退为拷贝完整 JDK（体积较大）" >&2
  rm -rf "$OUT"
  cp -r "$JDK" "$OUT"
fi

echo "[JRE] 体积：$(du -sh "$OUT" | cut -f1)"
