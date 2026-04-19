#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-ensure-current-acceptance-packet.log"
packet_dir="${CURRENT_ACCEPTANCE_PACKET_DIR:-${PROJECT_ROOT}/DOC/当前现场验收包}"
latest_workpack_dir="${CURRENT_ACCEPTANCE_PACKET_SOURCE_DIR:-${ARM_LOG_DIR}/latest-remaining-acceptance-workpack}"
refresh_mode="${CURRENT_ACCEPTANCE_PACKET_REFRESH:-0}"

if [[ "${1:-}" == "--refresh" ]]; then
  refresh_mode="1"
fi

mkdir -p "${packet_dir}"

seeded_count=0
kept_count=0

copy_if_needed() {
  local source_path="$1"
  local dest_path="$2"

  if [[ ! -f "${source_path}" ]]; then
    printf 'missing source: %s\n' "${source_path}" >&2
    exit 1
  fi

  if [[ "${refresh_mode}" == "1" || ! -f "${dest_path}" ]]; then
    cp "${source_path}" "${dest_path}"
    seeded_count=$((seeded_count + 1))
    return 0
  fi

  kept_count=$((kept_count + 1))
}

browser_source="${latest_workpack_dir}/browser-matrix.md"
scale_source="${latest_workpack_dir}/scale-protocol.md"
blind_source="${latest_workpack_dir}/blind-zone-workflow.md"
field_source="${PROJECT_ROOT}/DOC/现场联调验收记录模板.md"

if [[ ! -f "${browser_source}" ]]; then
  browser_source="${PROJECT_ROOT}/DOC/视频实机验收矩阵模板.md"
fi
if [[ ! -f "${scale_source}" ]]; then
  scale_source="${PROJECT_ROOT}/DOC/称重设备协议验收记录模板.md"
fi
if [[ ! -f "${blind_source}" ]]; then
  blind_source="${PROJECT_ROOT}/DOC/现场联调盲区补偿参数试验记录模板.md"
fi

copy_if_needed "${browser_source}" "${packet_dir}/视频实机验收矩阵.md"
copy_if_needed "${scale_source}" "${packet_dir}/称重设备协议验收记录.md"
copy_if_needed "${blind_source}" "${packet_dir}/盲区补偿参数试验记录.md"
copy_if_needed "${field_source}" "${packet_dir}/现场联调验收记录.md"

cat >"${packet_dir}/README.md" <<EOF
# 当前现场验收包

- Generated At: $(date -Iseconds)
- Packet Dir: ${packet_dir}
- Refresh Mode: ${refresh_mode}
- Browser Source: ${browser_source}
- Scale Source: ${scale_source}
- Blind Source: ${blind_source}
- Field Source: ${field_source}

## 使用规则

1. 在本目录内填写当前真实现场回写内容，不直接修改模板文档。
2. 若需要按最新自动化摘要重置浏览器/称重/盲区三份记录，可执行：
   - \`rtk bash scripts/arm/ensure_current_acceptance_packet.sh --refresh\`
3. 现场填写完成后，执行：
   - \`rtk bash scripts/arm/verify_remaining_acceptance_closure.sh\`
4. 如果第 3 步返回 \`PASS\`，再执行：
   - \`rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh\`

## 包含文件

- \`视频实机验收矩阵.md\`
- \`称重设备协议验收记录.md\`
- \`盲区补偿参数试验记录.md\`
- \`现场联调验收记录.md\`
EOF

print_stage_ok \
  "ensure_current_acceptance_packet" \
  "packet=${packet_dir} refresh=${refresh_mode} seeded=${seeded_count} kept=${kept_count}"
