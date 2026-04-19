#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logfile="${ARM_LOG_DIR}/${timestamp}-finalize-remaining-acceptance-closure.log"
closure_log="${ARM_LOG_DIR}/${timestamp}-verify-remaining-acceptance-closure.from-finalize.log"
report_path="${ARM_LOG_DIR}/${timestamp}-remaining-acceptance-closure-report.md"
latest_report_path="${ARM_LOG_DIR}/latest-remaining-acceptance-closure-report.md"

if ! "${script_dir}/verify_remaining_acceptance_closure.sh" >"${closure_log}" 2>&1; then
  print_stage_fail "finalize_remaining_acceptance_closure" "${closure_log}" "closure gate is not ready"
  exit 1
fi

if run_capture \
  "${logfile}" \
  env \
  PROJECT_ROOT="${PROJECT_ROOT}" \
  ARM_LOG_DIR="${ARM_LOG_DIR}" \
  FINALIZE_TIMESTAMP="${timestamp}" \
  FINALIZE_CLOSURE_LOG="${closure_log}" \
  FINALIZE_REPORT_PATH="${report_path}" \
  FINALIZE_LATEST_REPORT_PATH="${latest_report_path}" \
  python3 - <<'PY'
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import os
import re
import shutil

project_root = Path(os.environ['PROJECT_ROOT'])
arm_log_dir = Path(os.environ['ARM_LOG_DIR'])
timestamp = os.environ['FINALIZE_TIMESTAMP']
closure_log = Path(os.environ['FINALIZE_CLOSURE_LOG'])
report_path = Path(os.environ['FINALIZE_REPORT_PATH'])
latest_report_path = Path(os.environ['FINALIZE_LATEST_REPORT_PATH'])

iso_now = datetime.now(timezone.utc).astimezone().isoformat(timespec='seconds')
packet_dir = project_root / 'DOC/当前现场验收包'
archive_root = project_root / 'DOC/现场验收归档'
archive_dir = archive_root / f'{timestamp}-remaining-acceptance-closure'
archive_dir.mkdir(parents=True, exist_ok=False)
latest_field_report_path = arm_log_dir / 'latest-field-acceptance-report.md'
latest_workpack_dir = arm_log_dir / 'latest-remaining-acceptance-workpack'

packet_files = [
    '视频实机验收矩阵.md',
    '称重设备协议验收记录.md',
    '盲区补偿参数试验记录.md',
    '现场联调验收记录.md',
]

for name in packet_files:
    source = packet_dir / name
    if not source.exists():
        raise RuntimeError(f'missing current acceptance packet file: {source}')
    shutil.copy2(source, archive_dir / name)

packet_readme_path = packet_dir / 'README.md'
if not packet_readme_path.exists():
    raise RuntimeError(f'missing current acceptance packet file: {packet_readme_path}')
shutil.copy2(packet_readme_path, archive_dir / '当前现场验收包-README.md')

if not latest_field_report_path.exists():
    raise RuntimeError(f'missing latest field acceptance report: {latest_field_report_path}')
shutil.copy2(latest_field_report_path, archive_dir / 'latest-field-acceptance-report.md')

if not latest_workpack_dir.exists():
    raise RuntimeError(f'missing latest remaining acceptance workpack: {latest_workpack_dir}')
shutil.copytree(latest_workpack_dir, archive_dir / 'latest-remaining-acceptance-workpack')

if not closure_log.exists():
    raise RuntimeError(f'missing closure gate log: {closure_log}')
shutil.copy2(closure_log, archive_dir / 'verify-remaining-acceptance-closure.from-finalize.log')


def read_text(path: Path) -> str:
    return path.read_text(encoding='utf-8')


def write_text(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + '\n', encoding='utf-8')


def replace_line(text: str, before: str, after: str, label: str) -> str:
    if before in text:
        return text.replace(before, after, 1)
    if after in text:
        return text
    raise RuntimeError(f'missing expected {label}')


def replace_section(text: str, heading: str, replacement: str) -> str:
    pattern = re.compile(rf'^## {re.escape(heading)}\n.*?(?=^## |\Z)', re.MULTILINE | re.DOTALL)
    if pattern.search(text):
        return pattern.sub(replacement.rstrip() + '\n\n', text, count=1)
    return text


v11_path = project_root / 'DOC/V1.1视频链路版本化验收清单.md'
todo_path = project_root / 'todo.md'
project_status_path = project_root / 'DOC/项目完成状态说明.md'
archive_index_path = archive_root / 'README.md'

v11_text = read_text(v11_path)
v11_text = replace_line(
    v11_text,
    '- 当前仓库状态属于 `验收中`',
    '- 当前仓库状态属于 `已通过`',
    'v1.1 current status line',
)
v11_text = replace_line(
    v11_text,
    '- 还不能把 `V1.1` 视频链路标记为 `已通过`',
    '- 已通过当前正式收口流程把 `V1.1` 视频链路标记为 `已通过`',
    'v1.1 closure line',
)
final_v11_section = f"""## 六、最终关单记录

- 正式关单时间：{iso_now}
- 当前现场验收包：`DOC/当前现场验收包/`
- 正式归档目录：`DOC/现场验收归档/{archive_dir.name}/`
- 最新正式收口报告：`logs/arm/{report_path.name}`
- 浏览器实机矩阵、允许清单、现场联调记录、称重协议记录和盲区补偿记录均已完成回写
- 本清单状态现已固定为 `已通过`
"""
v11_text = replace_section(v11_text, '六、当前阻塞', final_v11_section)
v11_text = replace_section(v11_text, '六、最终关单记录', final_v11_section)
write_text(v11_path, v11_text)

todo_text = f"""# GOGS 当前剩余待办

状态说明、现场已确认事实和历史完成事项不再写在本文件。

参考文档：

- [系统成熟化实施计划](DOC/系统成熟化实施计划.md)
- [项目完成状态说明](DOC/项目完成状态说明.md)
- [历史已完成事项归档](DOC/todo历史已完成归档.md)
- [ARM Field Notes](.codex/skills/arm-crosscompile-test/references/field-notes.md)
- 当前自动化现场摘要入口：`rtk bash scripts/arm/verify_field_acceptance_bundle.sh`
- 当前剩余现场预填工作包入口：`rtk bash scripts/arm/generate_remaining_acceptance_workpack.sh`
- 当前稳定现场回写包入口：`rtk bash scripts/arm/ensure_current_acceptance_packet.sh`
- 当前最终现场收口校验入口：`rtk bash scripts/arm/verify_remaining_acceptance_closure.sh`
- 当前最终现场关单入口：`rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`
- 最近正式归档：`DOC/现场验收归档/{archive_dir.name}/`

## 剩余待办

当前无剩余待办。

## 维护规则

- 历史已完成事项只维护在 [DOC/todo历史已完成归档.md](DOC/todo历史已完成归档.md)。
- 新出现的事项只把当前未完成项写回本文件，已完成项继续迁回归档文档。
- 每次推进剩余项，都要同时更新实现、验证记录、相关文档和本清单。
- 任何 ARM 构建或发布动作都只能通过编译机完成，不允许在测试机本地编译。
"""
write_text(todo_path, todo_text)

project_status_text = read_text(project_status_path)
latest_closure_section = f"""## 最新正式收口

- 正式关单时间：{iso_now}
- 已执行 `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`
- 当前现场验收包来源：`DOC/当前现场验收包/`
- 最新正式归档目录：`DOC/现场验收归档/{archive_dir.name}/`
- 最新正式收口报告：`logs/arm/{report_path.name}`，稳定路径 `logs/arm/{latest_report_path.name}`
- `DOC/V1.1视频链路版本化验收清单.md` 已改为 `已通过`
- `todo.md` 已改为 `当前无剩余待办`
"""
latest_section_pattern = re.compile(r'^## 最新正式收口\n.*?(?=^## |\Z)', re.MULTILINE | re.DOTALL)
if latest_section_pattern.search(project_status_text):
    project_status_text = latest_section_pattern.sub(latest_closure_section.rstrip() + '\n\n', project_status_text, count=1)
else:
    marker = '## 已完成范围'
    if marker not in project_status_text:
        raise RuntimeError('missing project status insertion point')
    project_status_text = project_status_text.replace(marker, latest_closure_section.rstrip() + '\n\n' + marker, 1)
write_text(project_status_path, project_status_text)

archive_index_text = f"""# 现场验收归档

- Latest Archive: `DOC/现场验收归档/{archive_dir.name}/`
- Latest Final Closure Report: `logs/arm/{report_path.name}`
- Latest Stable Report: `logs/arm/{latest_report_path.name}`
- Latest Field Acceptance Evidence: `logs/arm/{latest_field_report_path.name}`
- Latest Remaining Workpack: `logs/arm/{latest_workpack_dir.name}/`

## 使用规则

1. `DOC/当前现场验收包/` 只用于当前这轮现场填写。
2. 正式关单后，统一通过 `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh` 生成时间戳归档。
3. 本目录只保存已经完成正式收口的固定记录快照。
"""
write_text(archive_index_path, archive_index_text)

post_update_snapshot_files = [
    (project_root / 'DOC/视频浏览器兼容矩阵.md', '视频浏览器兼容矩阵.md'),
    (v11_path, 'V1.1视频链路版本化验收清单.md'),
    (project_status_path, '项目完成状态说明.md'),
    (todo_path, 'todo.md'),
]
for source, name in post_update_snapshot_files:
    shutil.copy2(source, archive_dir / name)

archive_readme = f"""# 剩余现场项正式关单归档

- Archived At: {iso_now}
- Archive Dir: {archive_dir}
- Source Packet: {packet_dir}
- Closure Gate Log: {closure_log}
- Field Acceptance Evidence: {latest_field_report_path}
- Remaining Workpack Evidence: {latest_workpack_dir}
- Final Closure Report: {report_path}
- Stable Final Closure Report: {latest_report_path}

## 包含内容

- 当前现场验收包快照
- `当前现场验收包-README.md`
- `latest-field-acceptance-report.md`
- `latest-remaining-acceptance-workpack/`
- `verify-remaining-acceptance-closure.from-finalize.log`
- 视频浏览器兼容矩阵最终版本
- `V1.1` 视频链路版本化验收清单最终版本
- `项目完成状态说明.md` 最终版本
- `todo.md` 关单后版本
"""
write_text(archive_dir / 'README.md', archive_readme)

report_body = f"""# 剩余现场项正式关单报告

- Time: {iso_now}
- Current Packet: `DOC/当前现场验收包/`
- Archive Dir: `DOC/现场验收归档/{archive_dir.name}/`
- Closure Gate Log: `{closure_log}`
- Latest Field Acceptance Evidence: `logs/arm/{latest_field_report_path.name}`
- Latest Remaining Workpack Evidence: `logs/arm/{latest_workpack_dir.name}/`
- `V1.1` Status: `已通过`
- `todo.md`: `当前无剩余待办`

## 已完成动作

1. 重新执行 `verify_remaining_acceptance_closure.sh`，确认现场回写已满足正式关单门槛。
2. 把 `DOC/当前现场验收包/` 复制为时间戳正式归档。
3. 把 `logs/arm/latest-field-acceptance-report.md`、`logs/arm/latest-remaining-acceptance-workpack/` 和 closure log 一并纳入正式归档。
4. 更新 `DOC/V1.1视频链路版本化验收清单.md` 为 `已通过`。
5. 更新 `todo.md` 为仅保留“当前无剩余待办”。
6. 更新 `DOC/项目完成状态说明.md`，写入最新正式收口记录。

## 正式归档内容

- `视频实机验收矩阵.md`
- `称重设备协议验收记录.md`
- `盲区补偿参数试验记录.md`
- `现场联调验收记录.md`
- `latest-field-acceptance-report.md`
- `latest-remaining-acceptance-workpack/`
- `verify-remaining-acceptance-closure.from-finalize.log`
- `视频浏览器兼容矩阵.md`
- `V1.1视频链路版本化验收清单.md`
- `项目完成状态说明.md`
- `todo.md`
"""
write_text(report_path, report_body)
shutil.copyfile(report_path, latest_report_path)

print(f'archive={archive_dir}')
print(f'report={report_path}')
print(f'latest_report={latest_report_path}')
print('v11=passed')
print('todo=cleared')
PY
then
  archive_summary="$(sed -n 's/^archive=//p' "${logfile}")"
  report_summary="$(sed -n 's/^report=//p' "${logfile}")"
  latest_report_summary="$(sed -n 's/^latest_report=//p' "${logfile}")"
  v11_summary="$(sed -n 's/^v11=//p' "${logfile}")"
  todo_summary="$(sed -n 's/^todo=//p' "${logfile}")"
  print_stage_ok \
    "finalize_remaining_acceptance_closure" \
    "archive='${archive_summary}' report='${report_summary}' latest_report='${latest_report_summary}' v11='${v11_summary}' todo='${todo_summary}'"
  exit 0
fi

print_stage_fail "finalize_remaining_acceptance_closure" "${logfile}" "failed to finalize remaining acceptance closure"
exit 1
