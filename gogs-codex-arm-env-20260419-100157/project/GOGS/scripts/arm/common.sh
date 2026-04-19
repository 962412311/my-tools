#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_TARGETS_FILE="${RUNTIME_TARGETS_FILE:-${PROJECT_ROOT}/.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml}"
ARM_LOG_DIR="${ARM_LOG_DIR:-${PROJECT_ROOT}/logs/arm}"

mkdir -p "${ARM_LOG_DIR}"

arm_now() {
  date '+%Y%m%d-%H%M%S'
}

yaml_get() {
  local path="$1"
  local section="${path%%.*}"
  local key="${path#*.}"
  awk -F': *' -v section="${section}" -v key="${key}" '
    BEGIN { in_section = 0 }
    /^[^[:space:]].*:/ {
      current = $1
      sub(/:$/, "", current)
      in_section = (current == section)
      next
    }
    in_section && $1 ~ "^[[:space:]]*" key "$" {
      value = $2
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "${RUNTIME_TARGETS_FILE}"
}

require_target() {
  local path="$1"
  local value
  value="$(yaml_get "${path}")"
  if [[ -z "${value}" ]]; then
    echo "missing runtime target: ${path}" >&2
    exit 1
  fi
  printf '%s\n' "${value}"
}

compile_user_host() {
  printf '%s@%s\n' \
    "$(require_target compile_host.user)" \
    "$(require_target compile_host.host)"
}

test_user_host() {
  printf '%s@%s\n' \
    "$(require_target test_host.user)" \
    "$(require_target test_host.host)"
}

run_capture() {
  local logfile="$1"
  shift
  mkdir -p "$(dirname "${logfile}")"
  "$@" >"${logfile}" 2>&1
}

print_stage_ok() {
  local stage="$1"
  shift
  printf '[PASS] %s: %s\n' "${stage}" "$*"
}

print_stage_fail() {
  local stage="$1"
  local logfile="$2"
  shift 2
  printf '[FAIL] %s: %s\n' "${stage}" "$*" >&2
  printf '  log: %s\n' "${logfile}" >&2
  if [[ -f "${logfile}" ]]; then
    tail -n 20 "${logfile}" >&2 || true
  fi
}

ssh_compile() {
  ssh -o ConnectTimeout=5 "$(compile_user_host)" "$@"
}

ssh_test() {
  ssh -o ConnectTimeout=5 "$(test_user_host)" "$@"
}
