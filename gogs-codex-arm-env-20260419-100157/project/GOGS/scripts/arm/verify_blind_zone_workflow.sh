#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify-blind-zone-workflow.log"
backend_port="$(require_target checks.backend_port)"
backend_config_path="$(require_target runtime.backend_config)"
verify_user="${BLIND_ZONE_VERIFY_USERNAME:-admin}"
verify_password="${BLIND_ZONE_VERIFY_PASSWORD:-Admin@123}"
sample_count="${BLIND_ZONE_VERIFY_SAMPLE_COUNT:-4}"
sample_interval_seconds="${BLIND_ZONE_VERIFY_SAMPLE_INTERVAL_SECONDS:-1}"
min_support_ratio="${BLIND_ZONE_VERIFY_MIN_SUPPORT_RATIO:-0.35}"
fail_on_low_support="${BLIND_ZONE_VERIFY_FAIL_ON_LOW_SUPPORT:-0}"

if ! run_capture "${logfile}" ssh_test "
  VERIFY_USER='${verify_user}' \
  VERIFY_PASSWORD='${verify_password}' \
  BACKEND_PORT='${backend_port}' \
  BACKEND_CONFIG_PATH='${backend_config_path}' \
  SAMPLE_COUNT='${sample_count}' \
  SAMPLE_INTERVAL_SECONDS='${sample_interval_seconds}' \
  MIN_SUPPORT_RATIO='${min_support_ratio}' \
  FAIL_ON_LOW_SUPPORT='${fail_on_low_support}' \
  python3 - <<'PY'
import configparser
import json
import math
import os
from pathlib import Path
import statistics
import time
import urllib.error
import urllib.request

base = f\"http://127.0.0.1:{os.environ['BACKEND_PORT']}\"
username = os.environ['VERIFY_USER']
password = os.environ['VERIFY_PASSWORD']
backend_config_path = Path(os.environ['BACKEND_CONFIG_PATH'])
sample_count = max(1, int(os.environ['SAMPLE_COUNT']))
sample_interval_seconds = max(0.2, float(os.environ['SAMPLE_INTERVAL_SECONDS']))
min_support_ratio = float(os.environ['MIN_SUPPORT_RATIO'])
fail_on_low_support = os.environ['FAIL_ON_LOW_SUPPORT'] == '1'


def request(path, *, method='GET', headers=None, payload=None):
    req = urllib.request.Request(base + path, data=payload, method=method)
    for key, value in (headers or {}).items():
        req.add_header(key, value)
    try:
        return urllib.request.urlopen(req, timeout=30)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode('utf-8', errors='replace')
        raise RuntimeError(f\"HTTP {exc.code} {path}: {body}\") from exc


def request_json(path, *, method='GET', headers=None, payload=None):
    with request(path, method=method, headers=headers, payload=payload) as response:
        return json.loads(response.read().decode('utf-8'))


def ensure_ratio(value, label):
    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise RuntimeError(f\"{label} is not numeric: {value!r}\") from exc
    if not math.isfinite(number):
        raise RuntimeError(f\"{label} is not finite: {value!r}\")
    if number < 0.0 or number > 1.0:
        raise RuntimeError(f\"{label} out of range [0, 1]: {number}\")
    return number


def ensure_number(value, label, *, minimum=None):
    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise RuntimeError(f\"{label} is not numeric: {value!r}\") from exc
    if not math.isfinite(number):
        raise RuntimeError(f\"{label} is not finite: {value!r}\")
    if minimum is not None and number < minimum:
        raise RuntimeError(f\"{label} below minimum {minimum}: {number}\")
    return number


def summarize(values):
    return f\"min={min(values):.3f},avg={statistics.fmean(values):.3f},max={max(values):.3f}\"


def get_runtime_config_value(key):
    if '/' not in key:
        raise RuntimeError(f\"invalid runtime config key: {key}\")
    if not backend_config_path.exists():
        raise RuntimeError(f\"runtime config not found: {backend_config_path}\")
    section, option = key.split('/', 1)
    parser = configparser.ConfigParser()
    parser.read(backend_config_path, encoding='utf-8')
    if section not in parser:
        raise RuntimeError(f\"config section missing: {section}\")
    if option not in parser[section]:
        raise RuntimeError(f\"config option missing: {key}\")
    return parser[section][option]


login_payload = json.dumps({'username': username, 'password': password}).encode('utf-8')
login = request_json(
    '/api/auth/login',
    method='POST',
    headers={'Content-Type': 'application/json'},
    payload=login_payload,
)
token = login.get('token', '').strip()
if not token:
    raise RuntimeError('login did not return token')

auth_headers = {'Authorization': f'Bearer {token}'}
json_auth_headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json',
}

annulus_config = ensure_number(
    get_runtime_config_value('processing/blind_zone_annulus_thickness_factor'),
    'processing/blind_zone_annulus_thickness_factor',
    minimum=0.0,
)
quantile_config = ensure_number(
    get_runtime_config_value('processing/blind_zone_height_quantile'),
    'processing/blind_zone_height_quantile',
    minimum=0.0,
)

status = request_json('/api/rescan/status', headers=auth_headers).get('data', {})
analyze = request_json(
    '/api/rescan/analyze',
    method='POST',
    headers=json_auth_headers,
    payload=b'{}',
).get('data', {})

required_analysis_keys = [
    'executeSupported', 'cancelSupported', 'controlPhase', 'coordinatorState',
    'executionState', 'analysisRevision', 'updatedAt', 'operationMode',
    'jobStage', 'blindZoneRadius', 'blindZoneAnnulusThicknessFactor',
    'blindZoneHeightQuantile', 'volumeBlindZoneCoverageRatio',
    'volumeBlindZoneDensityRatio', 'volumeBlindZoneSupportRatio',
    'rescanSuggested', 'rescanSuggestedReason', 'blockedReason'
]
missing_analysis_keys = [key for key in required_analysis_keys if key not in analyze]
if missing_analysis_keys:
    if int(analyze.get('analysisRevision') or 0) <= 0 and not str(analyze.get('updatedAt', '')).strip():
        raise RuntimeError(
            'processing diagnostics are not ready: blind-zone metrics are unavailable, confirm live point-cloud processing first'
        )
    raise RuntimeError(f\"rescan analyze response missing keys {missing_analysis_keys}: {analyze}\")

analysis_revision = int(analyze.get('analysisRevision') or 0)
if analysis_revision <= 0:
    raise RuntimeError(f\"analysisRevision did not advance: {analyze}\")
if not str(analyze.get('updatedAt', '')).strip():
    raise RuntimeError(f\"updatedAt missing from rescan analysis: {analyze}\")

annulus_runtime = ensure_number(analyze.get('blindZoneAnnulusThicknessFactor'),
                                'blindZoneAnnulusThicknessFactor',
                                minimum=0.0)
quantile_runtime = ensure_number(analyze.get('blindZoneHeightQuantile'),
                                 'blindZoneHeightQuantile',
                                 minimum=0.0)
if abs(annulus_runtime - annulus_config) > 1e-6:
    raise RuntimeError(f\"runtime annulus factor mismatch: config={annulus_config} analysis={annulus_runtime}\")
if abs(quantile_runtime - quantile_config) > 1e-6:
    raise RuntimeError(f\"runtime height quantile mismatch: config={quantile_config} analysis={quantile_runtime}\")

support_values = []
coverage_values = []
density_values = []
radius_values = []
reasons = []
volume_sources = []

for index in range(sample_count):
    sample = request_json(
        '/api/rescan/analyze',
        method='POST',
        headers=json_auth_headers,
        payload=b'{}',
    ).get('data', {})
    support_values.append(ensure_ratio(sample.get('volumeBlindZoneSupportRatio'),
                                       'volumeBlindZoneSupportRatio'))
    coverage_values.append(ensure_ratio(sample.get('volumeBlindZoneCoverageRatio'),
                                        'volumeBlindZoneCoverageRatio'))
    density_values.append(ensure_ratio(sample.get('volumeBlindZoneDensityRatio'),
                                       'volumeBlindZoneDensityRatio'))
    radius_values.append(ensure_number(sample.get('blindZoneRadius'),
                                       'blindZoneRadius',
                                       minimum=0.0))
    reasons.append(str(sample.get('rescanSuggestedReason', 'none')))
    volume_sources.append(str(sample.get('volumeSource', 'unknown')))
    if index + 1 < sample_count:
        time.sleep(sample_interval_seconds)

low_support_observed = any(0.0 < value < min_support_ratio for value in support_values)
if fail_on_low_support and low_support_observed:
    raise RuntimeError(
        f\"blind-zone support ratio dropped below threshold {min_support_ratio}: {support_values}\"
    )

print(
    f\"config=annulus={annulus_config:.2f} quantile={quantile_config:.2f} \"
    f\"phase={analyze.get('controlPhase')} state={analyze.get('coordinatorState')}/{analyze.get('executionState')}\"
)
print(
    f\"metrics=support[{summarize(support_values)}] coverage[{summarize(coverage_values)}] \"
    f\"density[{summarize(density_values)}] radius[{summarize(radius_values)}]\"
)
print(
    f\"rescan=status_reason={status.get('rescanSuggestedReason', 'none')} \"
    f\"analyze_reason={analyze.get('rescanSuggestedReason', 'none')} \"
    f\"suggested={int(bool(analyze.get('rescanSuggested')))} \"
    f\"controlEligible={int(bool(analyze.get('controlEligible')))} \"
    f\"blocked={analyze.get('blockedReason', 'none')} guard={'warn' if low_support_observed else 'ok'}\"
)
print(
    f\"sources=volume={','.join(sorted(set(volume_sources)))} \"
    f\"reasons={','.join(sorted(set(reasons)))} revision={analysis_revision}\"
)
PY
"; then
  print_stage_fail "verify_blind_zone_workflow" "${logfile}" "blind-zone workflow verification failed"
  exit 1
fi

config_summary="$(sed -n 's/^config=//p' "${logfile}")"
metrics_summary="$(sed -n 's/^metrics=//p' "${logfile}")"
rescan_summary="$(sed -n 's/^rescan=//p' "${logfile}")"
sources_summary="$(sed -n 's/^sources=//p' "${logfile}")"

print_stage_ok \
  "verify_blind_zone_workflow" \
  "config='${config_summary}' metrics='${metrics_summary}' rescan='${rescan_summary}' sources='${sources_summary}'"
