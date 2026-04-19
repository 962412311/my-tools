#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_ROOT="${1:-${PROJECT_ROOT}/runtime}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:8080}"
NATIVE_REPORT="${NATIVE_REPORT:-${PROJECT_ROOT}/native-runtime-report.md}"
FIELD_REPORT="${FIELD_REPORT:-${PROJECT_ROOT}/field-acceptance-report.md}"
ARM_REPORT="${ARM_REPORT:-${PROJECT_ROOT}/arm-deployment-report.md}"

NATIVE_STATUS=0
FIELD_STATUS=0

echo "========================================"
echo "ARM Debian 11 原生部署验收入口"
echo "========================================"
echo "运行目录: ${RUNTIME_ROOT}"
echo "后端地址: ${BACKEND_URL}"
echo "原生运行报告: ${NATIVE_REPORT}"
echo "现场验收报告: ${FIELD_REPORT}"
echo "汇总报告: ${ARM_REPORT}"
echo

if "${PROJECT_ROOT}/scripts/verify-native-runtime.sh" "${RUNTIME_ROOT}" | tee "${NATIVE_REPORT}"; then
    echo "[PASS] 原生运行目录检查通过"
else
    NATIVE_STATUS=$?
    echo "[FAIL] 原生运行目录检查失败"
fi

echo

if BACKEND_URL="${BACKEND_URL}" "${PROJECT_ROOT}/scripts/verify-field-acceptance.sh" "${RUNTIME_ROOT}" "${FIELD_REPORT}"; then
    echo "[PASS] 现场联调验收检查通过"
else
    FIELD_STATUS=$?
    echo "[FAIL] 现场联调验收检查失败"
fi

echo
echo "汇总: native=${NATIVE_STATUS} field=${FIELD_STATUS}"

if [[ "${NATIVE_STATUS}" -ne 0 || "${FIELD_STATUS}" -ne 0 ]]; then
    cat > "${ARM_REPORT}" <<EOF
# ARM Debian 11 原生部署验收汇总

- 运行目录: ${RUNTIME_ROOT}
- 后端地址: ${BACKEND_URL}
- 原生运行报告: ${NATIVE_REPORT}
- 现场验收报告: ${FIELD_REPORT}
- 原生运行状态: ${NATIVE_STATUS}
- 现场验收状态: ${FIELD_STATUS}
- 最终结果: 失败

EOF
    exit 1
fi

cat > "${ARM_REPORT}" <<EOF
# ARM Debian 11 原生部署验收汇总

- 运行目录: ${RUNTIME_ROOT}
- 后端地址: ${BACKEND_URL}
- 原生运行报告: ${NATIVE_REPORT}
- 现场验收报告: ${FIELD_REPORT}
- 原生运行状态: ${NATIVE_STATUS}
- 现场验收状态: ${FIELD_STATUS}
- 最终结果: 通过

EOF
