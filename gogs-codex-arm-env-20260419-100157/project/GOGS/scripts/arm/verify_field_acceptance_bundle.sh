#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify-field-acceptance-bundle.log"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_stage() {
  local stage_key="$1"
  local script_path="$2"
  local stage_log="${ARM_LOG_DIR}/${timestamp}-${stage_key}.bundle-stage.log"

  if "${script_path}" >"${stage_log}" 2>&1; then
    local summary
    summary="$(tail -n 1 "${stage_log}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
    printf 'result=%s status=pass summary=%s log=%s\n' "${stage_key}" "${summary}" "${stage_log}" >>"${logfile}"
    return 0
  fi

  local summary
  summary="$(tail -n 5 "${stage_log}" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  printf 'result=%s status=fail summary=%s log=%s\n' "${stage_key}" "${summary}" "${stage_log}" >>"${logfile}"
  return 1
}

classify_optional_failure() {
  local stage_key="$1"
  local stage_log="$2"

  case "${stage_key}" in
    scale)
      if grep -Fq 'ui/scale_devices is empty' "${stage_log}"; then
        printf 'blocked: ui/scale_devices empty'
        return 0
      fi
      if grep -Fq 'none are enabled for sampling' "${stage_log}"; then
        printf 'blocked: no enabled scale devices'
        return 0
      fi
      if grep -Fq 'configured scale devices are not online yet' "${stage_log}"; then
        printf 'blocked: scale devices not online'
        return 0
      fi
      ;;
    blind)
      if grep -Fq 'processing diagnostics are not ready' "${stage_log}"; then
        printf 'blocked: processing diagnostics not ready'
        return 0
      fi
      if grep -Fq 'blind-zone support ratio dropped below threshold' "${stage_log}"; then
        printf 'blocked: support ratio below threshold'
        return 0
      fi
      ;;
  esac

  return 1
}

extract_stage_value() {
  local stage_key="$1"
  local field="$2"
  sed -n "s/^result=${stage_key} ${field}=\\([^ ]*\\).*$/\\1/p" "${logfile}" | tail -n 1
}

extract_stage_log() {
  local stage_key="$1"
  sed -n "s/^result=${stage_key} .*log=\\(.*\\)$/\\1/p" "${logfile}" | tail -n 1
}

: >"${logfile}"

if ! run_stage core "${script_dir}/verify_remote.sh"; then
  print_stage_fail "verify_field_acceptance_bundle" "${logfile}" "core remote verification failed"
  exit 1
fi

if ! run_stage video "${script_dir}/verify_video_workflow.sh"; then
  print_stage_fail "verify_field_acceptance_bundle" "${logfile}" "video workflow verification failed"
  exit 1
fi

scale_status="ready"
if ! run_stage scale "${script_dir}/verify_scale_protocol.sh"; then
  scale_log="$(extract_stage_log scale)"
  if ! scale_status="$(classify_optional_failure scale "${scale_log}")"; then
    print_stage_fail "verify_field_acceptance_bundle" "${logfile}" "scale protocol verification failed"
    exit 1
  fi
fi

blind_status="ready"
if ! run_stage blind "${script_dir}/verify_blind_zone_workflow.sh"; then
  blind_log="$(extract_stage_log blind)"
  if ! blind_status="$(classify_optional_failure blind "${blind_log}")"; then
    print_stage_fail "verify_field_acceptance_bundle" "${logfile}" "blind-zone workflow verification failed"
    exit 1
  fi
fi

core_summary="$(sed -n 's/^result=core status=pass summary=\(.*\) log=.*/\1/p' "${logfile}" | tail -n 1)"
video_summary="$(sed -n 's/^result=video status=pass summary=\(.*\) log=.*/\1/p' "${logfile}" | tail -n 1)"

print_stage_ok \
  "verify_field_acceptance_bundle" \
  "core='${core_summary}' video='${video_summary}' scale='${scale_status}' blind='${blind_status}'"
