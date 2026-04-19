#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_DIR="${PROJECT_ROOT}/deploy/systemd"
TARGET_DIR="${1:-/etc/systemd/system}"
RUN_USER="${2:-gogs}"
INSTALL_ROOT="${3:-/opt/gogs/runtime}"

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "错误: 请使用 root 权限执行"
        exit 1
    fi
}

install_service() {
    local source_file="$1"
    local target_file="$2"

    sed \
        -e "s|__RUN_USER__|${RUN_USER}|g" \
        -e "s|/opt/gogs/runtime|${INSTALL_ROOT}|g" \
        "${source_file}" > "${target_file}"
}

require_root

if [[ ! -d "${SERVICE_DIR}" ]]; then
    echo "错误: 未找到 systemd 模板目录: ${SERVICE_DIR}"
    exit 1
fi

mkdir -p "${TARGET_DIR}"

install_service "${SERVICE_DIR}/mediamtx.service" "${TARGET_DIR}/mediamtx.service"
install_service "${SERVICE_DIR}/grab-system.service" "${TARGET_DIR}/grab-system.service"

systemctl daemon-reload
systemctl enable mediamtx.service
systemctl enable grab-system.service

echo "已安装 systemd 服务模板:"
echo "  ${TARGET_DIR}/mediamtx.service"
echo "  ${TARGET_DIR}/grab-system.service"
echo
echo "当前运行用户: ${RUN_USER}"
echo "当前运行目录: ${INSTALL_ROOT}"
echo
echo "下一步:"
echo "  systemctl start mediamtx.service"
echo "  systemctl start grab-system.service"
