#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify-video-workflow.log"
backend_port="$(require_target checks.backend_port)"
verify_user="${VIDEO_VERIFY_USERNAME:-admin}"
verify_password="${VIDEO_VERIFY_PASSWORD:-Admin@123}"
record_seconds="${VIDEO_VERIFY_RECORD_SECONDS:-8}"

if ! run_capture "${logfile}" ssh_test "
  VERIFY_USER='${verify_user}' \
  VERIFY_PASSWORD='${verify_password}' \
  RECORD_SECONDS='${record_seconds}' \
  BACKEND_PORT='${backend_port}' \
  python3 - <<'PY'
import json
import os
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

base = f\"http://127.0.0.1:{os.environ['BACKEND_PORT']}\"
username = os.environ['VERIFY_USER']
password = os.environ['VERIFY_PASSWORD']
record_seconds = int(os.environ['RECORD_SECONDS'])


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

ptz = request_json('/api/video/ptz/status', headers=auth_headers).get('data', {})
if not ptz.get('ready'):
    raise RuntimeError(f\"PTZ not ready: {ptz}\")

with request('/api/video/snapshot', headers=auth_headers) as response:
    snapshot_body = response.read()
    snapshot_type = response.headers.get('Content-Type', '')
if not snapshot_body or not snapshot_type.startswith('image/'):
    raise RuntimeError(f\"snapshot failed: type={snapshot_type!r} bytes={len(snapshot_body)}\")

start = request_json(
    '/api/video/recording/start',
    method='POST',
    headers=json_auth_headers,
    payload=b'{}',
).get('data', {})
if not start.get('recording'):
    raise RuntimeError(f\"recording did not start: {start}\")

time.sleep(record_seconds)

stop = request_json(
    '/api/video/recording/stop',
    method='POST',
    headers=json_auth_headers,
    payload=b'{}',
).get('data', {})
if not stop.get('stopped'):
    raise RuntimeError(f\"recording did not stop cleanly: {stop}\")

time.sleep(3)

status_after = request_json('/api/video/recording/status', headers=auth_headers).get('data', {})
if status_after.get('healthStatus') != 'healthy' or status_after.get('lastError'):
    raise RuntimeError(f\"recording status unhealthy after stop: {status_after}\")

records = request_json('/api/video-records?limit=1', headers=auth_headers)
items = records.get('data') or []
if not items:
    raise RuntimeError('video-records did not return latest item')

latest = items[0]
video_path = latest.get('filePath', '').strip()
stream_url = latest.get('streamUrl', '').strip()
if not video_path or not stream_url:
    raise RuntimeError(f\"latest record missing path/streamUrl: {latest}\")

expected_stem = Path(start.get('outputPath', '')).stem
latest_name = Path(video_path).name
recording_mode = latest.get('recordingMode', '')
if recording_mode.startswith('splitmuxsink'):
    if expected_stem and not latest_name.startswith(expected_stem + '-'):
        raise RuntimeError(f\"latest split segment does not match start path: start={expected_stem} latest={latest_name}\")
else:
    if expected_stem and latest_name != expected_stem + '.mp4':
        raise RuntimeError(f\"latest recording does not match start path: start={expected_stem} latest={latest_name}\")

ffprobe = subprocess.run(
    [
        'ffprobe', '-v', 'error',
        '-show_entries', 'format=duration,size,format_name:stream=codec_name,codec_type,width,height',
        '-of', 'json',
        video_path,
    ],
    check=True,
    capture_output=True,
    text=True,
)
ffprobe_json = json.loads(ffprobe.stdout)
streams = ffprobe_json.get('streams') or []
video_stream = next((stream for stream in streams if stream.get('codec_type') == 'video'), None)
if not video_stream:
    raise RuntimeError(f\"ffprobe did not report a video stream: {ffprobe_json}\")

with request(stream_url, headers={**auth_headers, 'Range': 'bytes=0-1023'}) as response:
    stream_body = response.read()
    stream_status = getattr(response, 'status', response.getcode())
if stream_status != 206 or not stream_body:
    raise RuntimeError(f\"stream endpoint returned status={stream_status} bytes={len(stream_body)}\")

download_query = urllib.parse.urlencode({'path': video_path})
with request(f'/api/video-files/download?{download_query}', headers=auth_headers) as response:
    download_body = response.read()
    download_status = getattr(response, 'status', response.getcode())
if download_status != 200 or not download_body:
    raise RuntimeError(f\"download endpoint returned status={download_status} bytes={len(download_body)}\")

codec = video_stream.get('codec_name', 'unknown')
width = video_stream.get('width', 0)
height = video_stream.get('height', 0)
duration = ffprobe_json.get('format', {}).get('duration', '')

print(f\"ptz=ready onvif={ptz.get('onvifConnected')} wssec={ptz.get('wsSecurityEnabled')}\")
print(f\"snapshot={snapshot_type}:{len(snapshot_body)}\")
print(f\"recording=healthy file={latest_name} mode={recording_mode}\")
print(f\"ffprobe={codec}:{width}x{height}:{duration}\")
print(f\"stream={stream_status}:{len(stream_body)}\")
print(f\"download={download_status}:{len(download_body)}\")
PY
"; then
  print_stage_fail "verify_video_workflow" "${logfile}" "video workflow verification failed"
  exit 1
fi

ptz_summary="$(sed -n 's/^ptz=//p' "${logfile}")"
snapshot_summary="$(sed -n 's/^snapshot=//p' "${logfile}")"
recording_summary="$(sed -n 's/^recording=//p' "${logfile}")"
ffprobe_summary="$(sed -n 's/^ffprobe=//p' "${logfile}")"
stream_summary="$(sed -n 's/^stream=//p' "${logfile}")"
download_summary="$(sed -n 's/^download=//p' "${logfile}")"

print_stage_ok \
  "verify_video_workflow" \
  "ptz='${ptz_summary}' snapshot='${snapshot_summary}' recording='${recording_summary}' ffprobe='${ffprobe_summary}' stream='${stream_summary}' download='${download_summary}'"
