#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logfile="${ARM_LOG_DIR}/${timestamp}-generate-field-acceptance-report.log"
report_path="${FIELD_ACCEPTANCE_REPORT_PATH:-${ARM_LOG_DIR}/${timestamp}-field-acceptance-report.md}"
latest_report_path="${FIELD_ACCEPTANCE_LATEST_REPORT_PATH:-${ARM_LOG_DIR}/latest-field-acceptance-report.md}"

run_stage() {
  local stage_key="$1"
  local script_path="$2"
  local stage_log="${ARM_LOG_DIR}/${timestamp}-${stage_key}.report-stage.log"

  if "${script_path}" >"${stage_log}" 2>&1; then
    local summary
    summary="$(tail -n 1 "${stage_log}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
    printf 'stage=%s status=pass summary=%s log=%s\n' "${stage_key}" "${summary}" "${stage_log}" >>"${logfile}"
    return 0
  fi

  local summary
  summary="$(tail -n 5 "${stage_log}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  printf 'stage=%s status=fail summary=%s log=%s\n' "${stage_key}" "${summary}" "${stage_log}" >>"${logfile}"
  return 1
}

extract_stage_field() {
  local stage_key="$1"
  local field="$2"
  sed -n "s/^stage=${stage_key} ${field}=\\(.*\\)$/\\1/p" "${logfile}" | tail -n 1
}

stage_status() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} status=\\([^ ]*\\) .*$/\\1/p" "${logfile}" | tail -n 1
}

stage_summary() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} status=[^ ]* summary=\\(.*\\) log=.*/\\1/p" "${logfile}" | tail -n 1
}

stage_log_path() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} .*log=\\(.*\\)$/\\1/p" "${logfile}" | tail -n 1
}

append_remaining_action() {
  printf -- "- %s\n" "$1" >>"${report_path}"
}

: >"${logfile}"

run_stage browser "${script_dir}/verify_browser_matrix_readiness.sh" || true
run_stage bundle "${script_dir}/verify_field_acceptance_bundle.sh" || true

browser_status="$(stage_status browser)"
bundle_status="$(stage_status bundle)"
browser_summary="$(stage_summary browser)"
bundle_summary="$(stage_summary bundle)"
browser_log="$(stage_log_path browser)"
bundle_log="$(stage_log_path bundle)"

{
  echo "# ARM Field Acceptance Report"
  echo
  echo "- Generated At: $(date -Iseconds)"
  echo "- Browser Readiness Status: ${browser_status:-unknown}"
  echo "- Field Bundle Status: ${bundle_status:-unknown}"
  echo
  echo "## 当前自动化结论"
  echo
  echo "- 浏览器矩阵准备：${browser_summary:-not-run}"
  echo "- 现场总验收：${bundle_summary:-not-run}"
  echo
  echo "## 日志与证据"
  echo
  echo "- Latest 报告：${latest_report_path}"
  echo "- 浏览器矩阵准备日志：${browser_log:-not-generated}"
  echo "- 现场总验收日志：${bundle_log:-not-generated}"
  echo "- 汇总日志：${logfile}"
  echo
  echo "## 剩余现场动作"
  echo
} >"${report_path}"

if [[ "${browser_status:-fail}" != "pass" ]]; then
  append_remaining_action "先修复浏览器矩阵准备入口，再做真实浏览器矩阵回写。当前准备脚本尚未返回 PASS。"
else
  append_remaining_action '在有显示输出的真实 Chrome / Edge / Firefox / Safari 终端上，根据当前 monitor / HLS / WebRTC 地址填写 `DOC/当前现场验收包/视频实机验收矩阵.md`。'
  append_remaining_action '完成 `WebRTC/HLS × H.264/H.265` 实测后，把允许直放 H.265、必须回退 H.264、必须降级 HLS 的浏览器清单回写到 `DOC/视频浏览器兼容矩阵.md`。'
fi

if grep -Fq "scale='blocked: ui/scale_devices empty'" <<<"${bundle_summary}"; then
  append_remaining_action '测试机当前仍无称重设备运行态配置；接入真实称重设备后，执行 `rtk bash scripts/arm/verify_scale_protocol.sh` 并回写 `DOC/当前现场验收包/称重设备协议验收记录.md`。'
elif grep -Fq "scale='blocked:" <<<"${bundle_summary}"; then
  append_remaining_action '称重专项当前仍被现场条件阻塞；根据 bundle 摘要修复后，再执行 `rtk bash scripts/arm/verify_scale_protocol.sh`。'
fi

if grep -Fq "blind='blocked: processing diagnostics not ready'" <<<"${bundle_summary}"; then
  append_remaining_action '当前尚无可用于盲区补偿验收的活跃处理诊断；在真实慢速扫描场景形成诊断后，执行 `rtk bash scripts/arm/verify_blind_zone_workflow.sh` 并回写 `DOC/当前现场验收包/盲区补偿参数试验记录.md`。'
elif grep -Fq "blind='blocked:" <<<"${bundle_summary}"; then
  append_remaining_action '盲区补偿专项当前仍被现场条件阻塞；根据 bundle 摘要修复后，再执行 `rtk bash scripts/arm/verify_blind_zone_workflow.sh`。'
fi

append_remaining_action '在现场记录全部回写完成并且 closure gate 通过后，执行 `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`，统一归档当前验收包并更新 `V1.1`、`todo.md` 与 `DOC/项目完成状态说明.md`。'

cp "${report_path}" "${latest_report_path}"

print_stage_ok \
  "generate_field_acceptance_report" \
  "report=${report_path} latest=${latest_report_path} browser_status=${browser_status:-unknown} bundle_status=${bundle_status:-unknown}"
