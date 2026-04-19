#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_ROOT="${1:-${PROJECT_ROOT}/runtime}"
REPORT_FILE="${2:-${PROJECT_ROOT}/field-acceptance-report.md}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:8080}"
AUTH_HEADER="${AUTH_HEADER:-}"
ENABLE_ACTIVE_PTZ_TESTS="${ENABLE_ACTIVE_PTZ_TESTS:-0}"
ENABLE_ACTIVE_RECORDING_TESTS="${ENABLE_ACTIVE_RECORDING_TESTS:-0}"

PASS_COUNT=0
FAIL_COUNT=0
MAYBE_COUNT=0

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

maybe() {
    echo "[MAYBE] $1"
    MAYBE_COUNT=$((MAYBE_COUNT + 1))
}

curl_json() {
    local url="$1"
    shift || true
    if [[ -n "${AUTH_HEADER}" ]]; then
        curl -fsS -H "${AUTH_HEADER}" "$@" "${url}"
    else
        curl -fsS "$@" "${url}"
    fi
}

append_report() {
    cat <<EOF >> "${REPORT_FILE}"
## $1

- 结果: $2
- 说明: $3

EOF
}

: > "${REPORT_FILE}"

{
    echo "# GOGS 现场联调验收报告"
    echo
    echo "- 运行目录: ${RUNTIME_ROOT}"
    echo "- 后端地址: ${BACKEND_URL}"
    echo "- 生成时间: $(date -Iseconds)"
    echo
} >> "${REPORT_FILE}"

echo "========================================"
echo "GOGS 现场联调验收脚本"
echo "========================================"
echo "运行目录: ${RUNTIME_ROOT}"
echo "后端地址: ${BACKEND_URL}"
echo "报告文件: ${REPORT_FILE}"
echo

if "${PROJECT_ROOT}/scripts/verify-native-runtime.sh" "${RUNTIME_ROOT}"; then
    pass "原生运行目录基础检查"
    append_report "原生运行目录" "通过" "基础目录、systemd、HTTP、WebSocket 和前端资源检查通过"
else
    fail "原生运行目录基础检查"
    append_report "原生运行目录" "失败" "基础目录或服务检查未通过"
fi

if command -v gst-launch-1.0 >/dev/null 2>&1 && command -v gst-inspect-1.0 >/dev/null 2>&1; then
    pass "GStreamer 工具可用"
    append_report "GStreamer 工具" "通过" "gst-launch-1.0 和 gst-inspect-1.0 可执行"

    local_plugins=(rtspsrc h264parse mp4mux qtmux)
    missing_plugins=()
    for plugin in "${local_plugins[@]}"; do
        if gst-inspect-1.0 "${plugin}" >/dev/null 2>&1; then
            pass "GStreamer 插件: ${plugin}"
        else
            missing_plugins+=("${plugin}")
            fail "GStreamer 插件: ${plugin}"
        fi
    done

    if [[ ${#missing_plugins[@]} -eq 0 ]]; then
        append_report "GStreamer 插件" "通过" "关键插件齐全: ${local_plugins[*]}"
    else
        append_report "GStreamer 插件" "失败" "缺少插件: ${missing_plugins[*]}"
    fi
else
    maybe "GStreamer 工具不可用"
    append_report "GStreamer 工具" "待现场确认" "目标机未安装 gst-launch-1.0 或 gst-inspect-1.0"
fi

if curl_json "${BACKEND_URL}/api/system/info" >/dev/null 2>&1; then
    pass "系统信息接口可访问"
    append_report "HTTP 基础连通" "通过" "/api/system/info 可访问"
else
    fail "系统信息接口不可访问"
    append_report "HTTP 基础连通" "失败" "/api/system/info 不可访问"
fi

recording_status_json=""
if recording_status_json="$(curl_json "${BACKEND_URL}/api/video/recording/status" 2>/dev/null)"; then
    pass "录像状态接口可访问"
    append_report "录像状态接口" "通过" "/api/video/recording/status 可访问"
    flat_recording_status_json="$(tr -d '\n' <<<"${recording_status_json}")"
    if grep -Eq '"gstLaunchAvailable"[[:space:]]*:[[:space:]]*true' <<<"${recording_status_json}" && \
       grep -Eq '"gstInspectAvailable"[[:space:]]*:[[:space:]]*true' <<<"${recording_status_json}"; then
        pass "录像状态包含 GStreamer 可执行体信息"
        append_report "录像状态细项" "通过" "录像状态接口返回 gst-launch / gst-inspect 可用性"
    else
        maybe "录像状态未返回完整 GStreamer 可执行体信息"
        append_report "录像状态细项" "待现场确认" "录像状态接口未能确认 gst-launch 或 gst-inspect 可用性"
    fi
    if grep -Eq '"allChecksCompleted"[[:space:]]*:[[:space:]]*true' <<<"${flat_recording_status_json}"; then
        pass "录像状态完整性检查已完成"
        append_report "录像状态完整性" "通过" "录像状态接口返回 allChecksCompleted=true"
    else
        maybe "录像状态完整性检查未完成"
        append_report "录像状态完整性" "待现场确认" "录像状态接口返回 allChecksCompleted=false"
    fi
    if grep -Eq '"inputCodec"[[:space:]]*:[[:space:]]*"' <<<"${flat_recording_status_json}"; then
        pass "录像状态包含输入编码"
        append_report "录像状态编码" "通过" "录像状态接口返回 inputCodec"
        recording_input_codec="$(sed -n 's/.*"inputCodec"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${flat_recording_status_json}" | head -n 1)"
        if [[ -n "${recording_input_codec}" ]]; then
            append_report "录像状态编码值" "通过" "当前录像输入编码为 ${recording_input_codec}"
        fi
    else
        maybe "录像状态未返回输入编码"
        append_report "录像状态编码" "待现场确认" "录像状态接口未返回 inputCodec"
    fi
    for plugin in rtspsrc h264parse h265parse mp4mux splitmuxsink qtmux; do
        if grep -Eq "\"plugin\"[[:space:]]*:[[:space:]]*\"${plugin}\".*\"available\"[[:space:]]*:[[:space:]]*true" <<<"${flat_recording_status_json}"; then
            pass "GStreamer 插件状态: ${plugin}"
        else
            maybe "GStreamer 插件状态: ${plugin}"
            append_report "GStreamer 插件 ${plugin}" "待现场确认" "录像状态接口未确认 ${plugin} 可用性"
        fi
    done
else
    fail "录像状态接口不可访问"
    append_report "录像状态接口" "失败" "/api/video/recording/status 不可访问"
fi

video_self_check_json=""
if video_self_check_json="$(curl_json "${BACKEND_URL}/api/video/self-check" 2>/dev/null)"; then
    pass "视频自检摘要接口可访问"
    append_report "视频自检摘要" "通过" "/api/video/self-check 可访问"
    flat_video_self_check_json="$(tr -d '\n' <<<"${video_self_check_json}")"
    video_self_check_status="$(sed -n 's/.*"overallStatus"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${flat_video_self_check_json}" | head -n 1)"
    video_self_check_message="$(sed -n 's/.*"summaryMessage"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${flat_video_self_check_json}" | head -n 1)"
    if [[ -n "${video_self_check_status}" ]]; then
        append_report "视频自检结论" "通过" "overallStatus=${video_self_check_status} / summaryMessage=${video_self_check_message:-无}"
    fi
    for item in stream recording ptz snapshot; do
        if grep -Eq "\"key\"[[:space:]]*:[[:space:]]*\"${item}\"" <<<"${flat_video_self_check_json}"; then
            pass "视频自检项: ${item}"
        else
            maybe "视频自检项: ${item}"
            append_report "视频自检项 ${item}" "待现场确认" "/api/video/self-check 未返回 ${item} 项"
        fi
    done
else
    fail "视频自检摘要接口不可访问"
    append_report "视频自检摘要" "失败" "/api/video/self-check 不可访问"
fi

if curl_json "${BACKEND_URL}/api/video/ptz/presets" >/dev/null 2>&1; then
    pass "PTZ 预置位接口可访问"
    append_report "PTZ 预置位接口" "通过" "/api/video/ptz/presets 可访问"
else
    fail "PTZ 预置位接口不可访问"
    append_report "PTZ 预置位接口" "失败" "/api/video/ptz/presets 不可访问"
fi

ptz_status_json=""
if ptz_status_json="$(curl_json "${BACKEND_URL}/api/video/ptz/status" 2>/dev/null)"; then
    if grep -Eq '"configured"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}" && \
       grep -Eq '"ready"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}" && \
       grep -Eq '"rtspConfigured"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}" && \
       grep -Eq '"onvifConfigured"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}" && \
       grep -Eq '"usernameConfigured"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}"; then
        pass "PTZ 配置完成度已就绪"
        append_report "PTZ 配置完成度" "通过" "PTZ 状态接口返回 configured / ready / rtspConfigured / onvifConfigured / usernameConfigured 全为 true"
    else
        maybe "PTZ 配置完成度待确认"
        append_report "PTZ 配置完成度" "待现场确认" "PTZ 状态接口未能确认全部配置前提均为 true"
    fi
    if grep -Eq '"lastPtzAction"[[:space:]]*:[[:space:]]*"' <<<"${ptz_status_json}"; then
        pass "PTZ 状态包含最近动作"
        append_report "PTZ 状态细项" "通过" "PTZ 状态接口返回最近动作和动作时间"
    else
        maybe "PTZ 状态尚无最近动作"
        append_report "PTZ 状态细项" "待现场确认" "PTZ 状态接口可访问，但尚未记录最近动作"
    fi
    if grep -Eq '"wsSecurityEnabled"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}"; then
        pass "PTZ 状态显示 WS-Security 已启用"
        append_report "PTZ 安全模式" "通过" "PTZ 状态接口返回 wsSecurityEnabled=true"
    else
        maybe "PTZ 状态未显示 WS-Security 已启用"
        append_report "PTZ 安全模式" "待现场确认" "PTZ 状态接口返回 wsSecurityEnabled=false"
    fi
else
    fail "PTZ 状态接口不可访问"
    append_report "PTZ 状态接口" "失败" "/api/video/ptz/status 不可访问"
fi

if grep -Eq '"ready"[[:space:]]*:[[:space:]]*true' <<<"${ptz_status_json}"; then
    if curl_json "${BACKEND_URL}/api/video/snapshot" -o /dev/null >/dev/null 2>&1; then
        pass "视频抓图接口可用"
        append_report "视频抓图接口" "通过" "/api/video/snapshot 可访问且返回成功"
    else
        fail "视频抓图接口不可用"
        append_report "视频抓图接口" "失败" "/api/video/snapshot 在已就绪的 PTZ 状态下仍不可用"
    fi
else
    maybe "视频抓图接口未核查"
    append_report "视频抓图接口" "待现场确认" "PTZ 状态尚未就绪，跳过 /api/video/snapshot 主动核查"
fi

if curl_json "${BACKEND_URL}/api/scales/status" >/dev/null 2>&1; then
    pass "称重状态接口可访问"
    append_report "称重状态接口" "通过" "/api/scales/status 可访问"
else
    maybe "称重状态接口不可访问"
    append_report "称重状态接口" "待现场确认" "/api/scales/status 不可访问或尚未启用"
fi

if [[ "${ENABLE_ACTIVE_PTZ_TESTS}" == "1" ]]; then
    maybe "主动 PTZ 测试已启用"
    append_report "主动 PTZ 测试" "待人工执行" "已启用主动测试，但仍需现场确认方向、速度、停止和预置位行为"
else
    maybe "主动 PTZ 测试未启用"
    append_report "主动 PTZ 测试" "未执行" "未启用主动测试，保留为现场人工动作"
fi

if [[ "${ENABLE_ACTIVE_RECORDING_TESTS}" == "1" ]]; then
    maybe "主动录像测试已启用"
    append_report "主动录像测试" "待人工执行" "已启用主动测试，但仍需现场确认真实视频源、长时稳定性和导出结果"
else
    maybe "主动录像测试未启用"
    append_report "主动录像测试" "未执行" "未启用主动测试，保留为现场人工动作"
fi

if [[ -f "${RUNTIME_ROOT}/backend/bin/config/config.ini" ]]; then
    if grep -Eq '^blind_zone_annulus_thickness_factor=' "${RUNTIME_ROOT}/backend/bin/config/config.ini" && \
       grep -Eq '^blind_zone_height_quantile=' "${RUNTIME_ROOT}/backend/bin/config/config.ini"; then
        pass "盲区补偿配置项存在"
        append_report "盲区补偿配置" "通过" "config.ini 包含环厚和分位数配置项"
    else
        fail "盲区补偿配置项缺失"
        append_report "盲区补偿配置" "失败" "config.ini 未找到环厚或分位数配置项"
    fi
else
    fail "缺少 runtime 配置文件"
    append_report "盲区补偿配置" "失败" "runtime/backend/bin/config/config.ini 不存在"
fi

echo
echo "验收完成: PASS=${PASS_COUNT} FAIL=${FAIL_COUNT} MAYBE=${MAYBE_COUNT}"
if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
fi
