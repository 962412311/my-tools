#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${0:A}")" && pwd)"
TARGET_DIR="$HOME/.claude/hooks"

mkdir -p "$TARGET_DIR"
cp "$ROOT_DIR/rate_limit_continue.sh" "$TARGET_DIR/rate_limit_continue.sh"
cp "$ROOT_DIR/rate_limit_continue_worker.py" "$TARGET_DIR/rate_limit_continue_worker.py"
chmod +x "$TARGET_DIR/rate_limit_continue.sh" "$TARGET_DIR/rate_limit_continue_worker.py"

cat <<'EOF'
已安装到 ~/.claude/hooks/

推荐的 ~/.claude/settings.json 片段：
{
  "hooks": {
    "StopFailure": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/rate_limit_continue.sh",
            "async": true
          }
        ]
      }
    ]
  }
}

安装后请重启 Claude 会话。
EOF
