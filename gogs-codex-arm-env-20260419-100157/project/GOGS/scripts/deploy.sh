#!/bin/bash

set -euo pipefail

PRESET="${1:-backend-linux-release}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_BINARY="${PROJECT_ROOT}/backend/build/${PRESET}/GrabSystem"
RUNTIME_ROOT="${PROJECT_ROOT}/runtime"
BACKEND_RUNTIME="${RUNTIME_ROOT}/backend"
FRONTEND_RUNTIME="${RUNTIME_ROOT}/frontend"

echo "========================================"
echo "抓斗作业引导及盘存系统原生部署脚本"
echo "========================================"
echo "后端预设: ${PRESET}"
echo

if [[ ! -f "${BACKEND_BINARY}" ]]; then
    echo "错误: 未找到后端二进制 ${BACKEND_BINARY}"
    echo "请先执行: ./scripts/build.sh ${PRESET}"
    exit 1
fi

mkdir -p \
    "${BACKEND_RUNTIME}/bin" \
    "${BACKEND_RUNTIME}/bin/config" \
    "${BACKEND_RUNTIME}/config" \
    "${BACKEND_RUNTIME}/web" \
    "${RUNTIME_ROOT}/systemd" \
    "${BACKEND_RUNTIME}/data/videos" \
    "${BACKEND_RUNTIME}/data/maps" \
    "${BACKEND_RUNTIME}/data/hls" \
    "${BACKEND_RUNTIME}/data/mysql" \
    "${BACKEND_RUNTIME}/bin/logs" \
    "${FRONTEND_RUNTIME}"

cp "${BACKEND_BINARY}" "${BACKEND_RUNTIME}/bin/GrabSystem"
chmod +x "${BACKEND_RUNTIME}/bin/GrabSystem"

if [[ ! -f "${BACKEND_RUNTIME}/bin/config/config.ini" && -f "${PROJECT_ROOT}/config/config.ini" ]]; then
    cp "${PROJECT_ROOT}/config/config.ini" "${BACKEND_RUNTIME}/bin/config/config.ini"
fi

if [[ -f "${PROJECT_ROOT}/config/mediamtx.yml" ]]; then
    cp "${PROJECT_ROOT}/config/mediamtx.yml" "${BACKEND_RUNTIME}/config/mediamtx.yml"
fi

if [[ -f "${PROJECT_ROOT}/backend/SDK/LidarView/armlinux2026123/sdk/config/algo_table.json" ]]; then
    cp "${PROJECT_ROOT}/backend/SDK/LidarView/armlinux2026123/sdk/config/algo_table.json" \
       "${BACKEND_RUNTIME}/config/algo_table.json"
fi

if [[ -f "${PROJECT_ROOT}/backend/SDK/LidarView/armlinux2026123/sdk/config/lidar_config.json" ]]; then
    cp "${PROJECT_ROOT}/backend/SDK/LidarView/armlinux2026123/sdk/config/lidar_config.json" \
       "${BACKEND_RUNTIME}/config/lidar_config.json"
fi

if [[ -d "${PROJECT_ROOT}/frontend/dist" ]]; then
    rm -rf "${FRONTEND_RUNTIME}/dist"
    cp -r "${PROJECT_ROOT}/frontend/dist" "${FRONTEND_RUNTIME}/dist"
    rm -rf "${BACKEND_RUNTIME}/web"
    cp -r "${PROJECT_ROOT}/frontend/dist" "${BACKEND_RUNTIME}/web"
fi

if [[ -d "${PROJECT_ROOT}/deploy/systemd" ]]; then
    cp -r "${PROJECT_ROOT}/deploy/systemd/." "${RUNTIME_ROOT}/systemd/"
fi

echo
echo "原生运行目录已准备完成:"
echo "  后端目录: ${BACKEND_RUNTIME}"
echo "  前端目录: ${FRONTEND_RUNTIME}"
echo
echo "启动后端:"
  echo "  cd ${BACKEND_RUNTIME}/bin"
  echo "  ./GrabSystem"
echo
echo "systemd 模板:"
echo "  ${RUNTIME_ROOT}/systemd"
echo
echo "发布前端:"
echo "  cd ${FRONTEND_RUNTIME}"
echo "  python3 -m http.server 8081"
