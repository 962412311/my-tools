#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-deploy-backend.log"
build_dir="$(require_target approved_script.build_dir)"
backend_bin="$(require_target runtime.backend_bin)"
backend_service="$(require_target runtime.backend_service)"
backend_logs_dir="$(require_target runtime.backend_logs_dir)"
backend_runtime_dir="$(dirname "${backend_bin}")"
backend_config_dir="${backend_runtime_dir}/config"
algo_table_src="${PROJECT_ROOT}/backend/SDK/LidarView/armlinux2026123/sdk/config/algo_table.json"
lidar_config_src="${PROJECT_ROOT}/backend/SDK/LidarView/armlinux2026123/sdk/config/lidar_config.json"

if ! run_capture "${logfile}" bash -lc "
  scp -o ConnectTimeout=5 '$(compile_user_host):${build_dir}/GrabSystem' '/tmp/GrabSystem.arm.new'
  local_sha=\$(sha256sum /tmp/GrabSystem.arm.new | awk '{print \$1}')
  scp -o ConnectTimeout=5 /tmp/GrabSystem.arm.new '$(test_user_host):/tmp/GrabSystem.arm.new'
  scp -o ConnectTimeout=5 '${algo_table_src}' '$(test_user_host):/tmp/algo_table.json'
  scp -o ConnectTimeout=5 '${lidar_config_src}' '$(test_user_host):/tmp/lidar_config.json'
  runtime_sha=\$(ssh -o ConnectTimeout=5 '$(test_user_host)' '
    set -e
    mkdir -p ${backend_config_dir}
    systemctl stop ${backend_service}
    cp ${backend_bin} ${backend_bin}.bak.\$(date +%Y%m%d%H%M%S)
    find ${backend_logs_dir} -mindepth 1 -maxdepth 1 -type f -delete || true
    cp /tmp/GrabSystem.arm.new ${backend_bin}
    chmod +x ${backend_bin}
    cp /tmp/algo_table.json ${backend_config_dir}/algo_table.json
    cp /tmp/lidar_config.json ${backend_config_dir}/lidar_config.json
    sha256sum ${backend_bin} | awk '\''{print \$1}'\''
    systemctl start ${backend_service}
    test \"\$(systemctl is-active ${backend_service})\" = active
  ')
  test \"\${runtime_sha}\" = \"\${local_sha}\"
  printf '%s\n' \"\${runtime_sha}\"
"; then
  print_stage_fail "deploy_backend" "${logfile}" "backend deployment failed"
  exit 1
fi

runtime_sha="$(tail -n 1 "${logfile}")"
print_stage_ok "deploy_backend" "service=active runtime_sha=${runtime_sha}"
