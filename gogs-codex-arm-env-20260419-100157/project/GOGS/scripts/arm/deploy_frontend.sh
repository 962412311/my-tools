#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
build_log="${ARM_LOG_DIR}/${timestamp}-build-frontend.log"
sync_log="${ARM_LOG_DIR}/${timestamp}-sync-frontend.log"
deploy_log="${ARM_LOG_DIR}/${timestamp}-deploy-frontend.log"
frontend_dist="$(require_target runtime.frontend_dist)"
backend_web="$(require_target runtime.backend_web)"
frontend_service="$(require_target runtime.frontend_service)"
skip_build="${SKIP_BUILD_FRONTEND:-0}"

if [[ "${skip_build}" != "1" ]]; then
  if ! run_capture "${build_log}" bash -lc "
    cd '${PROJECT_ROOT}/frontend'
    npm run build
  "; then
    print_stage_fail "build_frontend" "${build_log}" "frontend build failed"
    exit 1
  fi
fi

if ! run_capture "${sync_log}" bash -lc "
  rsync -a --delete '${PROJECT_ROOT}/frontend/dist/' '$(test_user_host):${frontend_dist}/'
  rsync -a --delete '${PROJECT_ROOT}/frontend/dist/' '$(test_user_host):${backend_web}/'
"; then
  print_stage_fail "deploy_frontend" "${sync_log}" "frontend sync failed"
  exit 1
fi

if ! run_capture "${deploy_log}" ssh -o ConnectTimeout=5 "$(test_user_host)" "
  set -e
  systemctl reload ${frontend_service}
  curl -s http://127.0.0.1/ | grep -o 'assets/index-[^\\\"]*\\.js' | head -n 1
"; then
  print_stage_fail "deploy_frontend" "${deploy_log}" "frontend reload/verify failed"
  exit 1
fi

index_asset="$(tail -n 1 "${deploy_log}")"
if [[ "${skip_build}" == "1" ]]; then
  print_stage_ok "deploy_frontend" "skip_build=1 index=${index_asset}"
else
  print_stage_ok "deploy_frontend" "index=${index_asset}"
fi
