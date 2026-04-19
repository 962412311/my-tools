#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-run-backend-regression.log"
build_dir="$(require_target approved_script.build_dir)"
regression_bin="${build_dir}/GrabSystemRegressionTests"
test_source_root="/tmp/GOGS-backend-source-${timestamp}"
test_binary="/tmp/GrabSystemRegressionTests-${timestamp}.arm"
local_stage_dir="/tmp/gogs-backend-regression"
local_binary="${local_stage_dir}/GrabSystemRegressionTests.arm"
regression_timeout_seconds="${REGRESSION_TIMEOUT_SECONDS:-180}"

if ! run_capture "${logfile}" bash -lc "
  set -euo pipefail
  rm -rf '${local_stage_dir}'
  mkdir -p '${local_stage_dir}'
  scp -o ConnectTimeout=5 '$(compile_user_host):${regression_bin}' '${local_binary}'
  local_sha=\$(sha256sum '${local_binary}' | awk '{print \$1}')
  ssh -o ConnectTimeout=5 '$(test_user_host)' 'rm -rf ${test_source_root} && mkdir -p ${test_source_root}/include/service ${test_source_root}/src/core ${test_source_root}/src/service'
  scp -o ConnectTimeout=5 '${PROJECT_ROOT}/backend/src/core/Application.cpp' '$(test_user_host):${test_source_root}/src/core/Application.cpp'
  scp -o ConnectTimeout=5 '${PROJECT_ROOT}/backend/src/core/ConfigManager.cpp' '$(test_user_host):${test_source_root}/src/core/ConfigManager.cpp'
  scp -o ConnectTimeout=5 '${PROJECT_ROOT}/backend/include/service/WebSocketServer.h' '$(test_user_host):${test_source_root}/include/service/WebSocketServer.h'
  scp -o ConnectTimeout=5 '${PROJECT_ROOT}/backend/src/service/HttpServer.cpp' '$(test_user_host):${test_source_root}/src/service/HttpServer.cpp'
  scp -o ConnectTimeout=5 '${PROJECT_ROOT}/backend/src/service/WebSocketServer.cpp' '$(test_user_host):${test_source_root}/src/service/WebSocketServer.cpp'
  scp -o ConnectTimeout=5 '${local_binary}' '$(test_user_host):${test_binary}'
  remote_output=\$(ssh -o ConnectTimeout=5 '$(test_user_host)' '
    set -euo pipefail
    cleanup() {
      rm -f ${test_binary}
      rm -rf ${test_source_root}
    }
    trap cleanup EXIT
    chmod +x ${test_binary}
    timeout ${regression_timeout_seconds}s env GOGS_REPO_ROOT=${test_source_root} ${test_binary}
  ')
  printf \"%s\n\" \"\${remote_output}\"
  printf \"%s\n\" \"sha=\${local_sha}\"
  printf \"%s\n\" \"result=\$(printf \"%s\n\" \"\${remote_output}\" | tail -n 1)\"
"; then
  print_stage_fail "backend_regression" "${logfile}" "ARM backend regression failed"
  exit 1
fi

binary_sha="$(sed -n 's/^sha=//p' "${logfile}")"
result_line="$(sed -n 's/^result=//p' "${logfile}")"
print_stage_ok "backend_regression" "sha256=${binary_sha} result='${result_line}'"
