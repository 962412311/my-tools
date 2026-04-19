#!/usr/bin/env bash
set -euo pipefail

# Copy this file into a project and replace the placeholder values and commands.
# Goal:
# - one-line PASS/FAIL summaries
# - detailed logs written to files
# - strong machine-checkable verification at each stage

WORKFLOW_NAME="${WORKFLOW_NAME:-example}"
LOG_ROOT="${LOG_ROOT:-logs/${WORKFLOW_NAME}}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

ARTIFACT_PATH="${ARTIFACT_PATH:-/path/to/artifact}"
RUNTIME_PATH="${RUNTIME_PATH:-/path/to/runtime/artifact}"
SERVICE_NAME="${SERVICE_NAME:-example.service}"
VERIFY_URL="${VERIFY_URL:-http://127.0.0.1:8080/health}"

mkdir -p "${LOG_ROOT}"

CURRENT_STAGE=""
CURRENT_LOG=""

stage_log_path() {
  local stage="$1"
  printf '%s/%s-%s.log\n' "${LOG_ROOT}" "${TIMESTAMP}" "${stage}"
}

pass() {
  local stage="$1"
  local message="$2"
  printf '[PASS] %s: %s\n' "${stage}" "${message}"
}

fail() {
  local stage="$1"
  local message="$2"
  local log_path="${3:-}"
  if [[ -n "${log_path}" ]]; then
    printf '[FAIL] %s: %s log=%s\n' "${stage}" "${message}" "${log_path}" >&2
    if [[ -f "${log_path}" ]]; then
      tail -n 20 "${log_path}" >&2 || true
    fi
  else
    printf '[FAIL] %s: %s\n' "${stage}" "${message}" >&2
  fi
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || fail "${CURRENT_STAGE}" "missing file ${path}" "${CURRENT_LOG}"
}

require_active_service() {
  local service="$1"
  systemctl is-active --quiet "${service}" || fail "${CURRENT_STAGE}" "service not active: ${service}" "${CURRENT_LOG}"
}

run_stage() {
  local stage="$1"
  shift

  CURRENT_STAGE="${stage}"
  CURRENT_LOG="$(stage_log_path "${stage}")"

  if "$@" >"${CURRENT_LOG}" 2>&1; then
    return 0
  fi

  fail "${stage}" "stage command failed" "${CURRENT_LOG}"
}

preflight() {
  command -v sha256sum >/dev/null
  command -v curl >/dev/null
  require_file "./scripts/pipeline.sh"
}

build() {
  # Replace with the real build command.
  # Example:
  # rm -f "${ARTIFACT_PATH}"
  # ./scripts/build.sh
  require_file "${ARTIFACT_PATH}"
  sha256sum "${ARTIFACT_PATH}"
}

deploy() {
  # Replace with the real deploy command.
  # Example:
  # scp "${ARTIFACT_PATH}" target:/tmp/app.new
  # ssh target "systemctl stop ${SERVICE_NAME} && cp /tmp/app.new ${RUNTIME_PATH} && chmod +x ${RUNTIME_PATH} && systemctl start ${SERVICE_NAME}"
  require_file "${RUNTIME_PATH}"
  cmp -s "${ARTIFACT_PATH}" "${RUNTIME_PATH}"
  require_active_service "${SERVICE_NAME}"
}

verify() {
  require_active_service "${SERVICE_NAME}"
  curl -fsS "${VERIFY_URL}" >/dev/null
}

summarize_preflight() {
  pass "preflight" "tools=ok logs=${LOG_ROOT}"
}

summarize_build() {
  local sha
  sha="$(sha256sum "${ARTIFACT_PATH}" | awk '{print $1}')"
  pass "build" "artifact=${ARTIFACT_PATH} sha256=${sha}"
}

summarize_deploy() {
  local sha
  sha="$(sha256sum "${RUNTIME_PATH}" | awk '{print $1}')"
  pass "deploy" "runtime=${RUNTIME_PATH} service=${SERVICE_NAME} sha256=${sha}"
}

summarize_verify() {
  pass "verify" "service=${SERVICE_NAME} url=${VERIFY_URL}"
}

main() {
  run_stage "preflight" preflight
  summarize_preflight

  run_stage "build" build
  summarize_build

  run_stage "deploy" deploy
  summarize_deploy

  run_stage "verify" verify
  summarize_verify

  pass "pipeline" "workflow=${WORKFLOW_NAME} completed"
}

main "$@"
