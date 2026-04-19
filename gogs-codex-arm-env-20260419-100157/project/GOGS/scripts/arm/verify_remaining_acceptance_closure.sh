#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify-remaining-acceptance-closure.log"
current_packet_log="${ARM_LOG_DIR}/${timestamp}-ensure-current-acceptance-packet.from-closure.log"

"${script_dir}/ensure_current_acceptance_packet.sh" >"${current_packet_log}" 2>&1

if run_capture "${logfile}" env PROJECT_ROOT="${PROJECT_ROOT}" python3 - <<'PY'
from pathlib import Path
import os
import re

project_root = Path(os.environ['PROJECT_ROOT'])
packet_dir = project_root / 'DOC/当前现场验收包'

video_matrix_path = packet_dir / '视频实机验收矩阵.md'
browser_matrix_path = project_root / 'DOC/视频浏览器兼容矩阵.md'
field_record_path = packet_dir / '现场联调验收记录.md'
scale_record_path = packet_dir / '称重设备协议验收记录.md'
blind_record_path = packet_dir / '盲区补偿参数试验记录.md'
v11_path = project_root / 'DOC/V1.1视频链路版本化验收清单.md'
todo_path = project_root / 'todo.md'


def read_text(path: Path) -> str:
    if not path.exists():
        raise RuntimeError(f'missing acceptance record: {path}')
    return path.read_text(encoding='utf-8')


def find_line_value(text, prefix):
    for line in text.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    return None


def normalize_value(value):
    if value is None:
        return ''
    return re.sub(r'[\s,，、;；]+', '', value).lower()


def is_unfilled(value):
    if value is None:
        return True
    stripped = value.strip()
    if not stripped:
        return True
    markers = ('待填写', '待确认', '待补充', '待现场补齐', '待回写')
    return any(marker in stripped for marker in markers)


def check_required_values(text, required_items):
    blockers = []
    for key, prefix in required_items:
        value = find_line_value(text, prefix)
        if is_unfilled(value):
            blockers.append(key)
    return blockers


def check_affirmative_values(text, required_items):
    blockers = []
    for key, prefix in required_items:
        value = find_line_value(text, prefix)
        if not is_affirmative(value):
            blockers.append(key)
    return blockers


def is_affirmative(value):
    if is_unfilled(value):
        return False
    normalized = normalize_value(value)
    affirmative_tokens = {
        '是',
        '已同步',
        '已同步回写',
        '同步完成',
        '通过',
        '已通过',
        'pass',
        'passed',
        'ok',
        '完成',
        '完成回写',
        'true',
        'yes',
    }
    return normalized in affirmative_tokens


def compare_normalized_values(left, right):
    if is_unfilled(left) or is_unfilled(right):
        return False
    return normalize_value(left) == normalize_value(right)


def find_section_body(text, heading):
    pattern = rf'^## {heading}\n(.*?)(?=^## |\Z)'
    match = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL)
    if not match:
        return None
    return match.group(1).strip()


video_matrix = read_text(video_matrix_path)
browser_matrix = read_text(browser_matrix_path)
field_record = read_text(field_record_path)
scale_record = read_text(scale_record_path)
blind_record = read_text(blind_record_path)
v11_doc = read_text(v11_path)
todo_doc = read_text(todo_path)

video_blockers = []
if '待填写' in video_matrix:
    video_blockers.append('video_matrix_has_placeholders')

video_matrix_prefixes = [
    ('video_matrix_allow_h265', '- 允许直放 `H.265` 的浏览器/终端：'),
    ('video_matrix_force_h264', '- 必须改回 `H.264` 的浏览器/终端：'),
    ('video_matrix_force_hls', '- 必须强制降级 `HLS` 的浏览器/终端：'),
    ('video_matrix_default_sub_codec', '- 默认子码流编码最终建议：'),
    ('video_matrix_default_main_codec', '- 默认主码流编码最终建议：'),
    ('video_matrix_default_browser', '- 默认浏览器最终建议：'),
    ('video_matrix_allow_h265_policy', '- 是否允许现场继续保留 `H.265`：'),
]
video_blockers.extend(check_required_values(video_matrix, video_matrix_prefixes))

allowlist_prefixes = [
    ('browser_allowlist_h265', '- 允许直放 `H.265` 的浏览器/终端：'),
    ('browser_allowlist_force_h264', '- 必须改回 `H.264` 的浏览器/终端：'),
    ('browser_allowlist_force_hls', '- 必须强制降级到 `HLS` 的浏览器/终端：'),
]
video_blockers.extend(check_required_values(browser_matrix, allowlist_prefixes))

video_matrix_allow_h265_value = find_line_value(video_matrix, '- 允许直放 `H.265` 的浏览器/终端：')
video_matrix_force_h264_value = find_line_value(video_matrix, '- 必须改回 `H.264` 的浏览器/终端：')
video_matrix_force_hls_value = find_line_value(video_matrix, '- 必须强制降级 `HLS` 的浏览器/终端：')
browser_allow_h265_value = find_line_value(browser_matrix, '- 允许直放 `H.265` 的浏览器/终端：')
browser_force_h264_value = find_line_value(browser_matrix, '- 必须改回 `H.264` 的浏览器/终端：')
browser_force_hls_value = find_line_value(browser_matrix, '- 必须强制降级到 `HLS` 的浏览器/终端：')

if not compare_normalized_values(video_matrix_allow_h265_value, browser_allow_h265_value):
    video_blockers.append('video_matrix_allow_h265_mismatch')
if not compare_normalized_values(video_matrix_force_h264_value, browser_force_h264_value):
    video_blockers.append('video_matrix_force_h264_mismatch')
if not compare_normalized_values(video_matrix_force_hls_value, browser_force_hls_value):
    video_blockers.append('video_matrix_force_hls_mismatch')

field_record_prefixes = [
    ('field_record_date', '- 日期:'),
    ('field_record_site', '- 现场:'),
    ('field_record_target', '- 目标机:'),
    ('field_record_backend_version', '- 后端版本:'),
    ('field_record_frontend_version', '- 前端版本:'),
    ('field_record_snapshot', '- `snapshot`:'),
    ('field_record_recording_stop', '- `recording/stop`:'),
    ('field_record_matrix_written_back', '- `视频实机验收矩阵模板` 是否已同步回写:'),
    ('field_record_allow_h265', '- 允许直放 `H.265` 的浏览器/终端:'),
    ('field_record_force_h264', '- 必须回退 `H.264` 的浏览器/终端:'),
    ('field_record_passed', '- 是否通过:'),
]
video_blockers.extend(check_required_values(field_record, field_record_prefixes))
video_blockers.extend(
    check_affirmative_values(
        field_record,
        [
            ('field_record_matrix_not_confirmed', '- `视频实机验收矩阵模板` 是否已同步回写:'),
            ('field_record_not_passed', '- 是否通过:'),
        ],
    )
)

field_record_allow_h265_value = find_line_value(field_record, '- 允许直放 `H.265` 的浏览器/终端:')
field_record_force_h264_value = find_line_value(field_record, '- 必须回退 `H.264` 的浏览器/终端:')
if not compare_normalized_values(field_record_allow_h265_value, browser_allow_h265_value):
    video_blockers.append('field_record_allow_h265_mismatch')
if not compare_normalized_values(field_record_force_h264_value, browser_force_h264_value):
    video_blockers.append('field_record_force_h264_mismatch')

scale_blockers = []
if '待填写' in scale_record:
    scale_blockers.append('scale_record_has_placeholders')
scale_blockers.extend(
    check_required_values(
        scale_record,
        [
            ('scale_record_date', '- 日期：'),
            ('scale_record_site', '- 现场：'),
            ('scale_record_target', '- 目标机：'),
            ('scale_record_backend_version', '- 后端版本：'),
            ('scale_record_passed', '- 本轮是否通过：'),
        ],
    )
)
scale_blockers.extend(
    check_affirmative_values(
        scale_record,
        [
            ('scale_record_not_passed', '- 本轮是否通过：'),
        ],
    )
)

blind_blockers = []
if '待填写' in blind_record:
    blind_blockers.append('blind_record_has_placeholders')
blind_blockers.extend(
    check_required_values(
        blind_record,
        [
            ('blind_record_date', '- 日期：'),
            ('blind_record_site', '- 现场：'),
            ('blind_record_target', '- 目标机：'),
            ('blind_record_backend_version', '- 后端版本：'),
            ('blind_record_passed', '- 本轮是否通过：'),
        ],
    )
)
blind_blockers.extend(
    check_affirmative_values(
        blind_record,
        [
            ('blind_record_not_passed', '- 本轮是否通过：'),
        ],
    )
)

v11_blockers = []
if '当前仓库状态属于 `已通过`' not in v11_doc:
    v11_blockers.append('v11_status_not_passed')
if '还不能把 `V1.1` 视频链路标记为 `已通过`' in v11_doc:
    v11_blockers.append('v11_still_declares_not_passed')

todo_blockers = []
todo_section = find_section_body(todo_doc, '剩余待办')
todo_section_normalized = '' if todo_section is None else ''.join(todo_section.split())
if todo_section_normalized not in {'当前无剩余待办', '当前无剩余待办。'}:
    todo_blockers.append('todo_still_has_remaining_items')


def status(blockers, ready_value):
    if not blockers:
        return ready_value
    return 'pending:' + ','.join(blockers)


video_status = status(video_blockers, 'ready')
scale_status = status(scale_blockers, 'ready')
blind_status = status(blind_blockers, 'ready')
v11_status = status(v11_blockers, 'passed')
todo_status = status(todo_blockers, 'cleared')

print(f'video={video_status}')
print(f'scale={scale_status}')
print(f'blind={blind_status}')
print(f'v11={v11_status}')
print(f'todo={todo_status}')

if any((video_blockers, scale_blockers, blind_blockers, v11_blockers, todo_blockers)):
    raise SystemExit(1)
PY
then
  video_summary="$(sed -n 's/^video=//p' "${logfile}")"
  scale_summary="$(sed -n 's/^scale=//p' "${logfile}")"
  blind_summary="$(sed -n 's/^blind=//p' "${logfile}")"
  v11_summary="$(sed -n 's/^v11=//p' "${logfile}")"
  todo_summary="$(sed -n 's/^todo=//p' "${logfile}")"
  print_stage_ok \
    "verify_remaining_acceptance_closure" \
    "video='${video_summary}' scale='${scale_summary}' blind='${blind_summary}' v11='${v11_summary}' todo='${todo_summary}'"
  exit 0
fi

print_stage_fail "verify_remaining_acceptance_closure" "${logfile}" "remaining acceptance closure is not ready"
exit 1
