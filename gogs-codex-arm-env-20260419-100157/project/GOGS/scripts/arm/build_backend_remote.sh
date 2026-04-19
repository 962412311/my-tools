#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-build-backend.log"
compile_root="$(require_target repository.compile_root)"
build_dir="$(require_target approved_script.build_dir)"
build_cmd="$(require_target repository.approved_build_command)"

if ! run_capture "${logfile}" bash -lc "
  set -euo pipefail
  retry_cmd() {
    local name=\"\$1\"
    shift
    local attempt rc
    for attempt in 1 2 3 4 5; do
      if \"\$@\"; then
        return 0
      fi
      rc=\$?
      echo \"[WARN] \${name} attempt=\${attempt} rc=\${rc}\" >&2
      if [[ \${attempt} -ge 5 ]]; then
        return \${rc}
      fi
      sleep \$((attempt * 3))
    done
  }

  retry_cmd rsync rsync -a --delete \
    -e \"ssh -o ConnectTimeout=10 -o ConnectionAttempts=1 -o ServerAliveInterval=5 -o ServerAliveCountMax=2\" \
    --exclude '.git' \
    --exclude 'frontend/node_modules' \
    --exclude 'frontend/dist' \
    --exclude 'frontend/test-results' \
    --exclude 'playwright-report' \
    --exclude 'logs' \
    '${PROJECT_ROOT}/' '$(compile_user_host):${compile_root}/'

  retry_cmd ssh ssh -o ConnectTimeout=10 -o ConnectionAttempts=1 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 '$(compile_user_host)' '
    set -e
    cd ${compile_root}
    rm -f ${build_dir}/GrabSystem
    ${build_cmd}
    test -x ${build_dir}/GrabSystem
    sha256sum ${build_dir}/GrabSystem
  '
"; then
  print_stage_fail "build_backend" "${logfile}" "remote build failed"
  exit 1
fi

artifact_sha="$(tail -n 1 "${logfile}" | awk '{print $1}')"
print_stage_ok "build_backend" "sha256=${artifact_sha} artifact=${build_dir}/GrabSystem"
