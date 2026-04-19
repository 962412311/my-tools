#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-preflight.log"

if ! run_capture "${logfile}" bash -lc "
  cd '${PROJECT_ROOT}'
  git rev-parse --is-inside-work-tree >/dev/null
  git diff --quiet
  git diff --cached --quiet
  git rev-parse --abbrev-ref HEAD
  ssh -o ConnectTimeout=5 '$(compile_user_host)' 'echo ok-compile'
  ssh -o ConnectTimeout=5 '$(test_user_host)' 'echo ok-test'
"; then
  print_stage_fail "preflight" "${logfile}" "workspace dirty or host unreachable"
  exit 1
fi

branch="$(git -C "${PROJECT_ROOT}" branch --show-current)"
commit="$(git -C "${PROJECT_ROOT}" rev-parse --short HEAD)"
print_stage_ok "preflight" "branch=${branch} commit=${commit} hosts=reachable"
