#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logfile="${ARM_LOG_DIR}/${timestamp}-generate-remaining-acceptance-workpack.log"
workpack_dir="${REMAINING_ACCEPTANCE_WORKPACK_DIR:-${ARM_LOG_DIR}/${timestamp}-remaining-acceptance-workpack}"
latest_workpack_dir="${REMAINING_ACCEPTANCE_WORKPACK_LATEST_DIR:-${ARM_LOG_DIR}/latest-remaining-acceptance-workpack}"
browser_doc_path="${workpack_dir}/browser-matrix.md"
scale_doc_path="${workpack_dir}/scale-protocol.md"
blind_doc_path="${workpack_dir}/blind-zone-workflow.md"
readme_path="${workpack_dir}/README.md"
test_host="$(require_target test_host.host)"
current_packet_log="${ARM_LOG_DIR}/${timestamp}-ensure-current-acceptance-packet.from-workpack.log"

find_latest_matching_log() {
  local pattern="$1"
  local latest=""
  local candidates=()

  shopt -s nullglob
  candidates=("${ARM_LOG_DIR}"/${pattern})
  shopt -u nullglob

  if (( ${#candidates[@]} > 0 )); then
    latest="$(printf '%s\n' "${candidates[@]}" | sort | tail -n 1)"
  fi

  printf '%s\n' "${latest}"
}

run_stage() {
  local stage_key="$1"
  local script_path="$2"
  local detail_pattern="$3"
  local stage_log="${ARM_LOG_DIR}/${timestamp}-${stage_key}.workpack-stage.log"
  local status="pass"
  local summary=""
  local detail_log=""

  if "${script_path}" >"${stage_log}" 2>&1; then
    summary="$(tail -n 1 "${stage_log}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  else
    status="fail"
    summary="$(tail -n 5 "${stage_log}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  fi

  detail_log="$(find_latest_matching_log "${detail_pattern}")"
  printf 'stage=%s status=%s summary=%s stage_log=%s detail_log=%s\n' \
    "${stage_key}" "${status}" "${summary}" "${stage_log}" "${detail_log}" >>"${logfile}"
  [[ "${status}" == "pass" ]]
}

stage_status() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} status=\\([^ ]*\\) .*$/\\1/p" "${logfile}" | tail -n 1
}

stage_summary() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} status=[^ ]* summary=\\(.*\\) stage_log=.*/\\1/p" "${logfile}" | tail -n 1
}

stage_log_path() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} .*stage_log=\\([^ ]*\\) detail_log=.*/\\1/p" "${logfile}" | tail -n 1
}

stage_detail_log_path() {
  local stage_key="$1"
  sed -n "s/^stage=${stage_key} .*detail_log=\\(.*\\)$/\\1/p" "${logfile}" | tail -n 1
}

extract_log_value() {
  local file_path="$1"
  local prefix="$2"
  if [[ -z "${file_path}" || ! -f "${file_path}" ]]; then
    return 0
  fi
  sed -n "s/^${prefix}=//p" "${file_path}" | tail -n 1
}

classify_blocker() {
  local stage_key="$1"
  local summary="$2"
  local stage_log="$3"
  local detail_log="$4"
  local haystack="${summary}"

  if [[ -n "${stage_log}" && -f "${stage_log}" ]]; then
    haystack+=$'\n'"$(cat "${stage_log}")"
  fi
  if [[ -n "${detail_log}" && -f "${detail_log}" ]]; then
    haystack+=$'\n'"$(cat "${detail_log}")"
  fi

  case "${stage_key}" in
    scale)
      if grep -Fq 'ui/scale_devices is empty' <<<"${haystack}"; then
        printf 'ui/scale_devices empty'
        return 0
      fi
      if grep -Fq 'none are enabled for sampling' <<<"${haystack}"; then
        printf 'no enabled scale devices'
        return 0
      fi
      if grep -Fq 'configured scale devices are not online yet' <<<"${haystack}"; then
        printf 'scale devices not online'
        return 0
      fi
      ;;
    blind)
      if grep -Fq 'processing diagnostics are not ready' <<<"${haystack}"; then
        printf 'processing diagnostics not ready'
        return 0
      fi
      if grep -Fq 'blind-zone support ratio dropped below threshold' <<<"${haystack}"; then
        printf 'support ratio below threshold'
        return 0
      fi
      ;;
  esac

  printf 'none'
}

mkdir -p "${workpack_dir}" "${latest_workpack_dir}"
: >"${logfile}"

run_stage browser "${script_dir}/verify_browser_matrix_readiness.sh" '*-verify-browser-matrix-readiness.log' || true
run_stage scale "${script_dir}/verify_scale_protocol.sh" '*-verify-scale-protocol.log' || true
run_stage blind "${script_dir}/verify_blind_zone_workflow.sh" '*-verify-blind-zone-workflow.log' || true

browser_status="$(stage_status browser)"
browser_summary="$(stage_summary browser)"
browser_stage_log="$(stage_log_path browser)"
browser_detail_log="$(stage_detail_log_path browser)"

scale_status="$(stage_status scale)"
scale_summary="$(stage_summary scale)"
scale_stage_log="$(stage_log_path scale)"
scale_detail_log="$(stage_detail_log_path scale)"
scale_blocker="$(classify_blocker scale "${scale_summary}" "${scale_stage_log}" "${scale_detail_log}")"

blind_status="$(stage_status blind)"
blind_summary="$(stage_summary blind)"
blind_stage_log="$(stage_log_path blind)"
blind_detail_log="$(stage_detail_log_path blind)"
blind_blocker="$(classify_blocker blind "${blind_summary}" "${blind_stage_log}" "${blind_detail_log}")"

browser_monitor_url="$(extract_log_value "${browser_detail_log}" 'browser_monitor_url')"
browser_hls_url="$(extract_log_value "${browser_detail_log}" 'browser_hls_url')"
browser_webrtc_player_url="$(extract_log_value "${browser_detail_log}" 'browser_webrtc_player_url')"
browser_webrtc_whep_url="$(extract_log_value "${browser_detail_log}" 'browser_webrtc_whep_url')"
browser_stream_summary="$(extract_log_value "${browser_detail_log}" 'stream')"
browser_self_check_summary="$(extract_log_value "${browser_detail_log}" 'self_check')"
browser_recording_summary="$(extract_log_value "${browser_detail_log}" 'recording')"
browser_baseline_summary="$(extract_log_value "${browser_detail_log}" 'baseline')"
browser_matrix_template="$(extract_log_value "${browser_detail_log}" 'matrix_template')"
browser_checklist="$(extract_log_value "${browser_detail_log}" 'checklist')"
main_profile="$(printf '%s\n' "${browser_baseline_summary}" | sed -n 's/.*main=\([^ ]*\).*/\1/p')"
sub_profile="$(printf '%s\n' "${browser_baseline_summary}" | sed -n 's/.*sub=\([^ ]*\) record=.*/\1/p')"
record_profile="$(printf '%s\n' "${browser_baseline_summary}" | sed -n 's/.*record=\([^ ]*\).*/\1/p')"

{
  echo "# ARM Remaining Acceptance Workpack"
  echo
  echo "- Generated At: $(date -Iseconds)"
  echo "- Target Host: ${test_host}"
  echo "- Workpack Dir: ${workpack_dir}"
  echo "- Latest Stable Dir: ${latest_workpack_dir}"
  echo "- Current Acceptance Packet: ${PROJECT_ROOT}/DOC/当前现场验收包"
  echo
  echo "## 包含内容"
  echo
  echo "- 浏览器矩阵草稿：${browser_doc_path} （status=${browser_status:-unknown}）"
  echo "- 称重协议草稿：${scale_doc_path} （status=${scale_status:-unknown}）"
  echo "- 盲区补偿草稿：${blind_doc_path} （status=${blind_status:-unknown}）"
  echo
  echo "## 当前自动化摘要"
  echo
  echo "- 浏览器矩阵准备：${browser_summary:-not-run}"
  echo "- 称重协议：${scale_summary:-not-run}"
  echo "- 盲区补偿：${blind_summary:-not-run}"
  echo
  echo "## 现场使用顺序"
  echo
  echo "1. 先在浏览器草稿里完成真实终端的 WebRTC/HLS × H.264/H.265 矩阵。"
  echo "2. 称重设备到位后，按称重草稿补寄存器映射、三点实称和异常码。"
  echo "3. 慢速扫描场景形成活跃诊断后，按盲区草稿补参数矩阵和现场结论。"
  echo "4. 三份草稿回写正式文档后，再更新 todo 与版本化验收状态。"
  echo "5. 最后运行 rtk bash scripts/arm/verify_remaining_acceptance_closure.sh，确认项目已经满足正式关单门槛。"
  echo "6. 如果第 5 步返回 PASS，再运行 rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh，生成正式归档并关闭 todo。"
  echo
  echo "## 日志"
  echo
  echo "- 浏览器阶段日志：${browser_stage_log:-n/a}"
  echo "- 浏览器详情日志：${browser_detail_log:-n/a}"
  echo "- 称重阶段日志：${scale_stage_log:-n/a}"
  echo "- 称重详情日志：${scale_detail_log:-n/a}"
  echo "- 盲区阶段日志：${blind_stage_log:-n/a}"
  echo "- 盲区详情日志：${blind_detail_log:-n/a}"
  echo "- 汇总日志：${logfile}"
  echo "- 当前现场验收包同步日志：${current_packet_log}"
} >"${readme_path}"

{
  echo "# 浏览器实机矩阵预填草稿"
  echo
  echo "- 自动生成于：$(date -Iseconds)"
  echo "- 目标机：${test_host}"
  echo "- 自动化准备结果：${browser_summary:-not-run}"
  echo "- stream-info 摘要：${browser_stream_summary:-n/a}"
  echo "- self-check 摘要：${browser_self_check_summary:-n/a}"
  echo "- recording 摘要：${browser_recording_summary:-n/a}"
  echo "- 主码流基线：${main_profile:-n/a}"
  echo "- 子码流基线：${sub_profile:-n/a}"
  echo "- 录像输入编码：${record_profile:-n/a}"
  echo "- Monitor 地址：${browser_monitor_url:-n/a}"
  echo "- HLS 地址：${browser_hls_url:-n/a}"
  echo "- WebRTC Player 地址：${browser_webrtc_player_url:-n/a}"
  echo "- WebRTC WHEP 地址：${browser_webrtc_whep_url:-n/a}"
  echo "- 矩阵模板来源：${browser_matrix_template:-DOC/视频实机验收矩阵模板.md}"
  echo "- 版本化验收清单：${browser_checklist:-DOC/V1.1视频链路版本化验收清单.md}"
  echo "- 日志：${browser_stage_log:-n/a}"
  echo "- 详情日志：${browser_detail_log:-n/a}"
  echo
  echo "填写要求：必须在有显示输出的真实终端上填写，不能用 headless 浏览器替代画面结论。"
  echo
  echo "---"
  echo
  cat "${PROJECT_ROOT}/DOC/视频实机验收矩阵模板.md"
} >"${browser_doc_path}"

{
  echo "# 称重协议验收预填草稿"
  echo
  echo "- 自动生成于：$(date -Iseconds)"
  echo "- 目标机：${test_host}"
  echo "- 自动化脚本结果：${scale_summary:-not-run}"
  echo "- 当前阻塞：${scale_blocker:-none}"
  echo "- 推荐命令：rtk bash scripts/arm/verify_scale_protocol.sh"
  echo "- 可选期望映射：SCALE_VERIFY_EXPECTED_SPEC='{\"devices\":[...]}'"
  echo "- 阶段日志：${scale_stage_log:-n/a}"
  echo "- 详情日志：${scale_detail_log:-n/a}"
  echo
  echo "填写建议：先把设备手册映射整理成 JSON，再做现场三点实称、心跳节奏和异常码回写。"
  echo
  echo "---"
  echo
  cat "${PROJECT_ROOT}/DOC/称重设备协议验收记录模板.md"
} >"${scale_doc_path}"

{
  echo "# 盲区补偿验收预填草稿"
  echo
  echo "- 自动生成于：$(date -Iseconds)"
  echo "- 目标机：${test_host}"
  echo "- 自动化脚本结果：${blind_summary:-not-run}"
  echo "- 当前阻塞：${blind_blocker:-none}"
  echo "- 推荐命令：rtk bash scripts/arm/verify_blind_zone_workflow.sh"
  echo "- 阶段日志：${blind_stage_log:-n/a}"
  echo "- 详情日志：${blind_detail_log:-n/a}"
  echo
  echo '填写建议：先确认 `/api/rescan/analyze` 已形成活跃诊断，再在真实慢速扫描场景里补参数矩阵。'
  echo
  echo "---"
  echo
  cat "${PROJECT_ROOT}/DOC/现场联调盲区补偿参数试验记录模板.md"
} >"${blind_doc_path}"

cp "${readme_path}" "${latest_workpack_dir}/README.md"
cp "${browser_doc_path}" "${latest_workpack_dir}/browser-matrix.md"
cp "${scale_doc_path}" "${latest_workpack_dir}/scale-protocol.md"
cp "${blind_doc_path}" "${latest_workpack_dir}/blind-zone-workflow.md"

"${script_dir}/ensure_current_acceptance_packet.sh" >"${current_packet_log}" 2>&1

print_stage_ok \
  "generate_remaining_acceptance_workpack" \
  "dir=${workpack_dir} latest=${latest_workpack_dir} browser_status=${browser_status:-unknown} scale_status=${scale_status:-unknown} blind_status=${blind_status:-unknown}"
