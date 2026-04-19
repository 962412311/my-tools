#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_preflight=1
run_backend=1
run_frontend=1
skip_build_frontend=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-preflight)
      run_preflight=0
      ;;
    --backend-only)
      run_frontend=0
      ;;
    --frontend-only)
      run_backend=0
      ;;
    --skip-build-frontend)
      skip_build_frontend=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: bash scripts/arm/pipeline.sh [options]

Options:
  --skip-preflight   Skip workspace/host preflight checks
  --backend-only     Only build/deploy/verify backend
  --frontend-only    Only deploy/verify frontend
  --skip-build-frontend  Reuse existing frontend/dist and only sync/reload
  -h, --help         Show help
EOF
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "${run_backend}" -eq 0 && "${run_frontend}" -eq 0 ]]; then
  echo "nothing to do: both backend and frontend are disabled" >&2
  exit 1
fi

if [[ "${run_preflight}" -eq 1 ]]; then
  "${SCRIPT_DIR}/preflight.sh"
fi

if [[ "${run_backend}" -eq 1 ]]; then
  "${SCRIPT_DIR}/build_backend_remote.sh"
  "${SCRIPT_DIR}/deploy_backend.sh"
fi

if [[ "${run_frontend}" -eq 1 ]]; then
  if [[ "${skip_build_frontend}" -eq 1 ]]; then
    SKIP_BUILD_FRONTEND=1 "${SCRIPT_DIR}/deploy_frontend.sh"
  else
    "${SCRIPT_DIR}/deploy_frontend.sh"
  fi
fi

"${SCRIPT_DIR}/verify_remote.sh"

echo "[PASS] pipeline: arm build/deploy/verify completed"
