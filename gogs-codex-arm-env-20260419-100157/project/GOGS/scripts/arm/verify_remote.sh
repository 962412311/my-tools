#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify.log"
backend_service="$(require_target runtime.backend_service)"
backend_bin="$(require_target runtime.backend_bin)"

if ! run_capture "${logfile}" ssh_test "
  set -e
  service_state=\$(systemctl is-active ${backend_service})
  runtime_sha=\$(sha256sum ${backend_bin} | awk '{print \$1}')
  index_asset=\$(curl -s http://127.0.0.1/ | grep -o 'assets/index-[^\\\"]*\\.js' | head -n 1)
  hls_header=\$(curl -s http://127.0.0.1/media/hls/camera/index.m3u8 | head -n 1)
  ptz_line=\$(journalctl -u ${backend_service} --since '5 minutes ago' --no-pager | grep 'VideoManager: ONVIF connection state changed to connected' | tail -n 1 || true)
  radar_line=\$(journalctl -u ${backend_service} --since '1 minute ago' --no-pager | grep 'Tanway SDK point cloud callback' | tail -n 1 || true)
  if [ -z \"\${ptz_line}\" ]; then
    ptz_line='not-observed-in-recent-journal-window'
  fi
  test -n \"\${service_state}\"
  test -n \"\${runtime_sha}\"
  test -n \"\${index_asset}\"
  test -n \"\${hls_header}\"
  test -n \"\${radar_line}\"
  printf 'service=%s\n' \"\${service_state}\"
  printf 'sha=%s\n' \"\${runtime_sha}\"
  printf 'index=%s\n' \"\${index_asset}\"
  printf 'hls=%s\n' \"\${hls_header}\"
  printf 'ptz=%s\n' \"\${ptz_line}\"
  printf 'radar=%s\n' \"\${radar_line}\"
"; then
  print_stage_fail "verify" "${logfile}" "runtime verification failed"
  exit 1
fi

service_state="$(sed -n 's/^service=//p' "${logfile}")"
runtime_sha="$(sed -n 's/^sha=//p' "${logfile}")"
index_asset="$(sed -n 's/^index=//p' "${logfile}")"
hls_header="$(sed -n 's/^hls=//p' "${logfile}")"
ptz_line="$(sed -n 's/^ptz=//p' "${logfile}")"
radar_line="$(sed -n 's/^radar=//p' "${logfile}")"
print_stage_ok "verify" "service=${service_state} sha=${runtime_sha} index=${index_asset} hls=${hls_header} ptz='${ptz_line}' radar='${radar_line}'"
