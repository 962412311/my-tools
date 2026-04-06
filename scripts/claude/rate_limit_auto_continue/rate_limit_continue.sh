#!/bin/zsh
set -euo pipefail

HOOK_HOME="${CLAUDE_HOOK_HOME:-$HOME/.claude/hooks}"
LOCK_DIR="$HOOK_HOME/.rate_limit_locks"
LOG_FILE="$HOOK_HOME/rate_limit_continue.log"
mkdir -p "$LOCK_DIR"

json_input="$(cat)"

extract_field() {
  local key="$1"
  HOOK_INPUT="$json_input" python3 - "$key" <<'PY'
import json
import os
import sys

key = sys.argv[1]
raw = os.environ.get("HOOK_INPUT", "")

try:
    obj = json.loads(raw)
    value = obj.get(key, "")
    if value is None:
        value = ""
    if isinstance(value, str):
        print(value)
    else:
        print(json.dumps(value, ensure_ascii=False))
except Exception:
    print("")
PY
}

last_msg="$(extract_field "last_assistant_message")"
session_id="$(extract_field "session_id")"
error_text="$(extract_field "error")"
error_details="$(extract_field "error_details")"
reason_text="$(extract_field "reason")"

full_text="$last_msg
$error_text
$error_details
$reason_text"

reset_time="$(FULL_TEXT="$full_text" python3 - <<'PY'
import os
import re
from datetime import datetime

text = os.environ.get("FULL_TEXT", "")

patterns = [
    r'(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)',
    r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})',
]

for pattern in patterns:
    match = re.search(pattern, text)
    if not match:
        continue

    value = match.group(1)
    try:
        if "T" in value or value.endswith("Z") or "+" in value[19:] or "-" in value[19:]:
            normalized = value.replace("Z", "+00:00")
            parsed = datetime.fromisoformat(normalized)
            if parsed.tzinfo is not None:
                parsed = parsed.astimezone().replace(tzinfo=None)
        else:
            parsed = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
        print(parsed.strftime("%Y-%m-%d %H:%M:%S"))
        break
    except Exception:
        continue
PY
)"

if [[ -z "${reset_time:-}" ]]; then
  echo "$(date '+%F %T') [WARN] 未解析到重置时间" >> "$LOG_FILE"
  exit 0
fi

lock_key="$(printf '%s|%s' "$session_id" "$reset_time" | shasum | awk '{print $1}')"
lock_file="$LOCK_DIR/$lock_key.lock"

if [[ -f "$lock_file" ]]; then
  echo "$(date '+%F %T') [INFO] 已存在同一重置时间的任务: $reset_time" >> "$LOG_FILE"
  exit 0
fi

touch "$lock_file"

seconds_until_reset="$(python3 - "$reset_time" <<'PY'
import sys
from datetime import datetime

reset_time = sys.argv[1].strip()
now = datetime.now()
target = datetime.strptime(reset_time, "%Y-%m-%d %H:%M:%S")
delta = int((target - now).total_seconds())
print(delta)
PY
)"

# 已经过期太久则放弃；刚过期则立即进入 10 秒缓冲
if (( seconds_until_reset < -60 )); then
  echo "$(date '+%F %T') [WARN] 重置时间已过太久，放弃: $reset_time" >> "$LOG_FILE"
  rm -f "$lock_file"
  exit 0
fi

nohup python3 "$HOOK_HOME/rate_limit_continue_worker.py" \
  "$reset_time" \
  "$seconds_until_reset" \
  "$session_id" \
  "$lock_file" \
  "$LOG_FILE" \
  >/dev/null 2>&1 </dev/null &

exit 0
