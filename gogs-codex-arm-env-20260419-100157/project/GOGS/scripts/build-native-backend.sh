#!/bin/bash

set -euo pipefail

PRESET="${1:-backend-linux-debug}"

echo "========================================"
echo "原生 Qt 后端构建脚本"
echo "========================================"
echo "使用预设: ${PRESET}"
echo

if [[ -z "${Qt6_DIR:-}" ]]; then
    echo "错误: 未设置 Qt6_DIR"
    echo "例如: export Qt6_DIR=/opt/Qt/6.2.4/gcc_64/lib/cmake/Qt6"
    exit 1
fi

CONFIGURE_ARGS=()

if [[ -n "${PCL_DIR:-}" ]]; then
    CONFIGURE_ARGS+=("-DPCL_DIR=${PCL_DIR}")
fi

if [[ -n "${Eigen3_DIR:-}" ]]; then
    CONFIGURE_ARGS+=("-DEigen3_DIR=${Eigen3_DIR}")
fi

if [[ ${#CONFIGURE_ARGS[@]} -eq 0 ]]; then
    echo "提示: 未显式设置 PCL_DIR / Eigen3_DIR，默认从系统路径自动发现"
fi

cmake --preset "${PRESET}" "${CONFIGURE_ARGS[@]}"
cmake --build --preset "${PRESET}" -j

echo
echo "成功: 后端构建完成"
