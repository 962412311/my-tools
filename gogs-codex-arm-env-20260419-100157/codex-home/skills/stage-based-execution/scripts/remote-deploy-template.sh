#!/usr/bin/env bash
set -euo pipefail

# Copy this file into a project and replace the placeholder values and commands.
# Goal:
# - one-line PASS/FAIL summaries
# - stage logs written to files
# - strong verification for remote artifact replacement and service recovery

WORKFLOW_NAME="${WORKFLOW_NAME:-remote-deploy}"
LOG_ROOT="${LOG_ROOT:-logs/${WORKFLOW_NAME}}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

BUILD_HOST="${BUILD_HOST:-builder@example.com}"
TARGET_HOST="${TARGET_HOST:-root@example.com}"

LOCAL_ARTIFACT="${LOCAL_ARTIFACT:-/path/to/local/artifact}"
REMOTE_STAGING_PATH="${REMOTE_STAGING_PATH:-/tmp/app.new}"
REMOTE_RUNTIME_PATH="${REMOTE_RUNTIME_PATH:-/opt/app/app}"
REMOTE_SERVICE_NAME="${REMOTE_SERVICE_NAME:-example.service}"
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

require_local_file() {
  local path="$1"
  [[ -f "${path}" ]] || fail "${CURRENT_STAGE}" "missing local file ${path}" "${CURRENT_LOG}"
}

remote_sha256() {
  local host="$1"
  local path="$2"
  ssh "${host}" "sha256sum '${path}' | awk '{print \$1}'"
}

preflight() {
  command -v ssh >/dev/null
  command -v scp >/dev/null
  command -v sha256sum >/dev/null
  command -v curl >/dev/null
  require_local_file "${LOCAL_ARTIFACT}"
  ssh "${TARGET_HOST}" "true"
}

build() {
  # Replace with the real build or sync-to-build-host command.
  # Example:
  # rsync -a ./ "${BUILD_HOST}:/path/to/src/"
  # ssh "${BUILD_HOST}" "cd /path/to/src && ./scripts/build.sh"
  require_local_file "${LOCAL_ARTIFACT}"
  sha256sum "${LOCAL_ARTIFACT}"
}

deploy() {
  local local_sha remote_sha

  local_sha="$(sha256sum "${LOCAL_ARTIFACT}" | awk '{print $1}')"

  scp "${LOCAL_ARTIFACT}" "${TARGET_HOST}:${REMOTE_STAGING_PATH}"
  ssh "${TARGET_HOST}" "\
    systemctl stop '${REMOTE_SERVICE_NAME}' && \
    cp '${REMOTE_STAGING_PATH}' '${REMOTE_RUNTIME_PATH}' && \
    chmod +x '${REMOTE_RUNTIME_PATH}' && \
    systemctl start '${REMOTE_SERVICE_NAME}' && \
    systemctl is-active --quiet '${REMOTE_SERVICE_NAME}'"

  remote_sha="$(remote_sha256 "${TARGET_HOST}" "${REMOTE_RUNTIME_PATH}")"
  [[ "${local_sha}" == "${remote_sha}" ]] || fail "${CURRENT_STAGE}" "runtime sha mismatch" "${CURRENT_LOG}"
}

verify() {
  ssh "${TARGET_HOST}" "systemctl is-active --quiet '${REMOTE_SERVICE_NAME}'"
  curl -fsS "${VERIFY_URL}" >/dev/null
}

summarize_preflight() {
  pass "preflight" "target=${TARGET_HOST} logs=${LOG_ROOT}"
}

summarize_build() {
  local sha
  sha="$(sha256sum "${LOCAL_ARTIFACT}" | awk '{print $1}')"
  pass "build" "artifact=${LOCAL_ARTIFACT} sha256=${sha}"
}

summarize_deploy() {
  local sha
  sha="$(remote_sha256 "${TARGET_HOST}" "${REMOTE_RUNTIME_PATH}")"
  pass "deploy" "target=${TARGET_HOST} service=${REMOTE_SERVICE_NAME} sha256=${sha}"
}

summarize_verify() {
  pass "verify" "service=${REMOTE_SERVICE_NAME} url=${VERIFY_URL}"
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
