#!/bin/sh

# 说明：
# - 使用 sh 保持镜像精简（不强制依赖 bash）
# - 日志输出由 uvicorn 负责（英文）

set -eu

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
WEB_CONCURRENCY="${WEB_CONCURRENCY:-1}"

exec python -m uvicorn app.main:app \
  --host "${HOST}" \
  --port "${PORT}" \
  --workers "${WEB_CONCURRENCY}"
