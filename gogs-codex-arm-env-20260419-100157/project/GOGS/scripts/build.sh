#!/bin/bash

set -euo pipefail

PRESET="${1:-backend-linux-release}"
SKIP_FRONTEND="${SKIP_FRONTEND:-0}"

echo "========================================"
echo "抓斗作业引导及盘存系统原生构建脚本"
echo "========================================"
echo "后端预设: ${PRESET}"
echo

./scripts/build-native-backend.sh "${PRESET}"

if [[ "${SKIP_FRONTEND}" == "1" ]]; then
    echo "跳过前端构建"
    exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "警告: 未检测到 npm，跳过前端构建"
    exit 0
fi

echo "构建前端..."
./scripts/frontend-build.sh

echo
echo "成功: 原生构建完成"
echo "后端产物: backend/build/${PRESET}/GrabSystem"
echo "前端产物: frontend/dist"
