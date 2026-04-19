#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_ROOT="${1:-${PROJECT_ROOT}/runtime}"
BACKEND_ROOT="${RUNTIME_ROOT}/backend"
BACKEND_BIN="${BACKEND_ROOT}/bin/GrabSystem"
CONFIG_FILE="${BACKEND_ROOT}/bin/config/config.ini"
FRONTEND_DIST="${RUNTIME_ROOT}/frontend/dist/index.html"
BACKEND_WEB="${BACKEND_ROOT}/web/index.html"
BACKEND_LOGS="${BACKEND_ROOT}/bin/logs"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
    local path="$1"
    local label="$2"
    if [[ -e "${path}" ]]; then
        pass "${label}: ${path}"
    else
        fail "${label}: ${path}"
    fi
}

check_command() {
    local cmd="$1"
    local label="$2"
    if command -v "${cmd}" >/dev/null 2>&1; then
        pass "${label}: ${cmd}"
        return 0
    fi

    fail "${label}: ${cmd}"
    return 1
}

echo "========================================"
echo "GOGS 原生运行目录验证"
echo "========================================"
echo "运行目录: ${RUNTIME_ROOT}"
echo

check_file "${BACKEND_BIN}" "后端二进制"
check_file "${CONFIG_FILE}" "后端配置文件"
check_file "${BACKEND_ROOT}/config/mediamtx.yml" "mediamtx 配置"
check_file "${BACKEND_LOGS}" "日志目录"
check_file "${BACKEND_ROOT}/data/videos" "录像目录"
check_file "${BACKEND_ROOT}/data/maps" "点云地图目录"

if [[ -f "${FRONTEND_DIST}" ]]; then
    pass "独立前端静态资源: ${FRONTEND_DIST}"
elif [[ -f "${BACKEND_WEB}" ]]; then
    pass "后端托管静态资源: ${BACKEND_WEB}"
else
    fail "未找到前端静态资源（runtime/frontend/dist 或 backend/web）"
fi

if [[ -x "${BACKEND_BIN}" ]]; then
    pass "后端二进制可执行"
else
    fail "后端二进制不可执行"
fi

if check_command systemctl "systemd"; then
    for service in mysql mediamtx grab-system; do
        if systemctl is-enabled "${service}" >/dev/null 2>&1; then
            pass "systemd 已启用: ${service}"
        else
            fail "systemd 未启用: ${service}"
        fi

        if systemctl is-active "${service}" >/dev/null 2>&1; then
            pass "systemd 已运行: ${service}"
        else
            fail "systemd 未运行: ${service}"
        fi
    done
fi

if check_command curl "HTTP 检测工具"; then
    if curl -fsS "http://127.0.0.1:8080/api/system/info" >/dev/null 2>&1; then
        pass "HTTP API 可访问: /api/system/info"
    else
        fail "HTTP API 不可访问: /api/system/info"
    fi
fi

if command -v ss >/dev/null 2>&1; then
    if ss -ltn | grep -q ":12345 "; then
        pass "WebSocket 端口已监听: 12345"
    else
        fail "WebSocket 端口未监听: 12345"
    fi
elif command -v netstat >/dev/null 2>&1; then
    if netstat -ltn 2>/dev/null | grep -q ":12345 "; then
        pass "WebSocket 端口已监听: 12345"
    else
        fail "WebSocket 端口未监听: 12345"
    fi
else
    fail "缺少端口检测工具（ss/netstat）"
fi

if check_command mysqladmin "MySQL 管理工具"; then
    if mysqladmin ping >/dev/null 2>&1; then
        pass "MySQL 可连通"
    else
        fail "MySQL 不可连通"
    fi
fi

echo
echo "验证完成: PASS=${PASS_COUNT} FAIL=${FAIL_COUNT}"
if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
fi
