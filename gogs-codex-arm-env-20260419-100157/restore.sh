#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME_TARGET=""
PROJECT_ROOT_TARGET=""

copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src"/ "$dst"/
  else
    cp -a "$src"/. "$dst"/
  fi
}

usage() {
  cat <<'EOF'
Usage:
  bash restore.sh [--codex-home PATH] [--project-root PATH]

Examples:
  bash restore.sh --codex-home "$HOME/.codex"
  bash restore.sh --project-root "/path/to/GOGS"
  bash restore.sh --codex-home "$HOME/.codex" --project-root "/path/to/GOGS"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex-home)
      CODEX_HOME_TARGET="${2:-}"
      shift 2
      ;;
    --project-root)
      PROJECT_ROOT_TARGET="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$CODEX_HOME_TARGET" && -z "$PROJECT_ROOT_TARGET" ]]; then
  usage >&2
  exit 1
fi

if [[ -n "$CODEX_HOME_TARGET" ]]; then
  echo "[restore] codex-home -> $CODEX_HOME_TARGET"
  copy_tree "$ARCHIVE_ROOT/codex-home" "$CODEX_HOME_TARGET"
fi

if [[ -n "$PROJECT_ROOT_TARGET" ]]; then
  echo "[restore] project overlay -> $PROJECT_ROOT_TARGET"
  copy_tree "$ARCHIVE_ROOT/project/GOGS" "$PROJECT_ROOT_TARGET"
fi

echo "[restore] done"
