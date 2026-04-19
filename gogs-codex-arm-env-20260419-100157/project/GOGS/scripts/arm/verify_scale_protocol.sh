#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify-scale-protocol.log"
backend_port="$(require_target checks.backend_port)"
verify_user="${SCALE_VERIFY_USERNAME:-admin}"
verify_password="${SCALE_VERIFY_PASSWORD:-Admin@123}"
min_online="${SCALE_VERIFY_MIN_ONLINE:-1}"
sample_max_age_seconds="${SCALE_VERIFY_SAMPLE_MAX_AGE_SECONDS:-10}"
expected_spec_b64=""
if [[ -n "${SCALE_VERIFY_EXPECTED_SPEC:-}" ]]; then
  expected_spec_b64="$(printf '%s' "${SCALE_VERIFY_EXPECTED_SPEC}" | base64 | tr -d '\n')"
fi

if ! run_capture "${logfile}" ssh_test "
  VERIFY_USER='${verify_user}' \
  VERIFY_PASSWORD='${verify_password}' \
  BACKEND_PORT='${backend_port}' \
  MIN_ONLINE='${min_online}' \
  SAMPLE_MAX_AGE_SECONDS='${sample_max_age_seconds}' \
  EXPECTED_SPEC_B64='${expected_spec_b64}' \
  python3 - <<'PY'
import base64
import datetime as dt
import json
import math
import os
import time
import urllib.error
import urllib.request

base = f\"http://127.0.0.1:{os.environ['BACKEND_PORT']}\"
username = os.environ['VERIFY_USER']
password = os.environ['VERIFY_PASSWORD']
min_online = int(os.environ['MIN_ONLINE'])
sample_max_age_seconds = float(os.environ['SAMPLE_MAX_AGE_SECONDS'])
expected_spec_b64 = os.environ.get('EXPECTED_SPEC_B64', '').strip()


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


def parse_iso8601(value):
    text = str(value or '').strip()
    if not text:
        raise RuntimeError('sampleTime is empty')
    return dt.datetime.fromisoformat(text.replace('Z', '+00:00')).timestamp()


def ensure_numeric(value, label):
    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise RuntimeError(f\"{label} is not numeric: {value!r}\") from exc
    if not math.isfinite(number):
        raise RuntimeError(f\"{label} is not finite: {value!r}\")
    return number


def parse_expected_spec():
    if not expected_spec_b64:
        return []
    decoded = base64.b64decode(expected_spec_b64.encode('ascii')).decode('utf-8')
    document = json.loads(decoded)
    if isinstance(document, dict):
        devices = document.get('devices')
        if devices is None:
            raise RuntimeError('SCALE_VERIFY_EXPECTED_SPEC object must contain devices')
        document = devices
    if not isinstance(document, list):
        raise RuntimeError('SCALE_VERIFY_EXPECTED_SPEC must decode to a JSON array or {\"devices\": [...]}')
    return document


def compare_expected(actual, expected):
    compare_keys = [
        'name', 'type', 'protocol', 'registerAddress', 'registerCount',
        'registerArea', 'valueType', 'wordOrder', 'pollIntervalMs', 'slaveId'
    ]
    for key in compare_keys:
        if key not in expected:
            continue
        if str(actual.get(key)) != str(expected.get(key)):
            raise RuntimeError(f\"device {actual.get('id')} {key} mismatch: actual={actual.get(key)!r} expected={expected.get(key)!r}\")
    if 'scaleFactor' in expected:
        actual_factor = ensure_numeric(actual.get('scaleFactor'), 'scaleFactor')
        expected_factor = ensure_numeric(expected.get('scaleFactor'), 'expected scaleFactor')
        if abs(actual_factor - expected_factor) > 1e-6:
            raise RuntimeError(f\"device {actual.get('id')} scaleFactor mismatch: actual={actual_factor} expected={expected_factor}\")


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

status_before = request_json('/api/scales/status', headers=auth_headers).get('data', {})
time.sleep(1.2)
status_after = request_json('/api/scales/status', headers=auth_headers).get('data', {})

devices = status_after.get('devices') or []
if int(status_after.get('totalDeviceCount') or 0) <= 0:
    raise RuntimeError('scale devices are not configured on target host (ui/scale_devices is empty)')
if not isinstance(devices, list) or not devices:
    raise RuntimeError(f\"scale status did not return configured devices: {status_after}\")
if int(status_after.get('enabledDeviceCount') or 0) <= 0:
    raise RuntimeError('scale devices are configured but none are enabled for sampling')
if int(status_after.get('onlineDeviceCount') or 0) < min_online:
    raise RuntimeError(f\"configured scale devices are not online yet: {status_after}\")
if not status_after.get('driverAvailable'):
    raise RuntimeError(f\"scale driver unavailable: {status_after}\")

required_keys = [
    'id', 'name', 'type', 'protocol', 'connected', 'registerAddress',
    'registerCount', 'registerArea', 'valueType', 'wordOrder',
    'scaleFactor', 'pollIntervalMs'
]
expected_devices = parse_expected_spec()
devices_by_id = {}
device_summaries = []

for device in devices:
    if not isinstance(device, dict):
        raise RuntimeError(f\"scale device entry is not an object: {device!r}\")
    missing = [key for key in required_keys if key not in device]
    if missing:
        raise RuntimeError(f\"scale device missing required keys {missing}: {device}\")
    device_id = int(device.get('id') or 0)
    if device_id <= 0:
        raise RuntimeError(f\"scale device id must be positive: {device}\")
    devices_by_id[device_id] = device

    ensure_numeric(device.get('currentWeight', 0.0), f'device {device_id} currentWeight')
    ensure_numeric(device.get('scaleFactor'), f'device {device_id} scaleFactor')
    poll_interval_ms = max(200, min(60000, int(device.get('pollIntervalMs') or 1000)))
    sample_age = 'n/a'
    if bool(device.get('hardwareConnected')):
        source = str(device.get('currentWeightSource', '')).strip()
        if not source:
            raise RuntimeError(f\"device {device_id} missing currentWeightSource while online: {device}\")
        sample_timestamp = parse_iso8601(device.get('sampleTime'))
        age_seconds = max(0.0, time.time() - sample_timestamp)
        allowed_age = max(sample_max_age_seconds, poll_interval_ms * 3.0 / 1000.0)
        if age_seconds > allowed_age:
            raise RuntimeError(
                f\"device {device_id} sample age too old: age={age_seconds:.2f}s allowed={allowed_age:.2f}s device={device}\"
            )
        sample_age = f\"{age_seconds:.1f}s\"
    device_summaries.append(
        f\"{device_id}:{device.get('name')} online={int(bool(device.get('hardwareConnected')))} age={sample_age} \"
        f\"reg={device.get('registerArea')}@{device.get('registerAddress')}/{device.get('registerCount')} \"
        f\"{device.get('valueType')}/{device.get('wordOrder')} factor={device.get('scaleFactor')} \"
        f\"weight={ensure_numeric(device.get('currentWeight', 0.0), 'currentWeight'):.3f}\"
    )

for expected in expected_devices:
    if not isinstance(expected, dict):
        raise RuntimeError(f\"expected scale device must be object: {expected!r}\")
    expected_id = int(expected.get('id') or 0)
    if expected_id <= 0:
        raise RuntimeError(f\"expected scale device id must be positive: {expected}\")
    actual = devices_by_id.get(expected_id)
    if not actual:
        raise RuntimeError(f\"expected scale device {expected_id} not found in runtime status\")
    compare_expected(actual, expected)

driver_summary = (
    f\"status={status_after.get('driverStatus', 'unknown')} \"
    f\"online={int(status_after.get('onlineDeviceCount') or 0)}/\"
    f\"{int(status_after.get('enabledDeviceCount') or 0)}/\"
    f\"{int(status_after.get('totalDeviceCount') or 0)}\"
)
status_before_updated_at = str(status_before.get('lastUpdateAt', '')).strip() or 'unknown'
status_after_updated_at = str(status_after.get('lastUpdateAt', '')).strip() or 'unknown'

print(f\"driver={driver_summary}\")
print(f\"message={status_after.get('driverMessage', '').strip()}\")
print(f\"updates={status_before_updated_at}->{status_after_updated_at}\")
print(f\"expected={'matched' if expected_devices else 'skipped'}\")
for device_summary in device_summaries:
    print(f\"device={device_summary}\")
PY
"; then
  print_stage_fail "verify_scale_protocol" "${logfile}" "scale protocol verification failed"
  exit 1
fi

driver_summary="$(sed -n 's/^driver=//p' "${logfile}")"
message_summary="$(sed -n 's/^message=//p' "${logfile}")"
updates_summary="$(sed -n 's/^updates=//p' "${logfile}")"
expected_summary="$(sed -n 's/^expected=//p' "${logfile}")"
device_count="$(grep -c '^device=' "${logfile}" || true)"

print_stage_ok \
  "verify_scale_protocol" \
  "driver='${driver_summary}' expected='${expected_summary}' devices=${device_count} updates='${updates_summary}' message='${message_summary}'"
