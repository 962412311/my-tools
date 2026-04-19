#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

timestamp="$(arm_now)"
logfile="${ARM_LOG_DIR}/${timestamp}-verify-browser-matrix-readiness.log"
backend_port="$(require_target checks.backend_port)"
backend_config="$(require_target runtime.backend_config)"
verify_user="${BROWSER_VERIFY_USERNAME:-admin}"
verify_password="${BROWSER_VERIFY_PASSWORD:-Admin@123}"
browser_scheme="${BROWSER_VERIFY_SCHEME:-http}"
browser_host="${BROWSER_VERIFY_HOST:-$(require_target test_host.host)}"
browser_base_url="${browser_scheme}://${browser_host}"

if ! run_capture "${logfile}" ssh_test "
  VERIFY_USER='${verify_user}' \
  VERIFY_PASSWORD='${verify_password}' \
  BACKEND_PORT='${backend_port}' \
  BACKEND_CONFIG_PATH='${backend_config}' \
  BROWSER_BASE_URL='${browser_base_url}' \
  python3 - <<'PY'
import configparser
import json
import os
import urllib.error
import urllib.request

base = f\"http://127.0.0.1:{os.environ['BACKEND_PORT']}\"
config_path = os.environ['BACKEND_CONFIG_PATH']
browser_base = os.environ['BROWSER_BASE_URL'].rstrip('/')
username = os.environ['VERIFY_USER']
password = os.environ['VERIFY_PASSWORD']


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


def cfg(parser, section, key, default=''):
    return parser.get(section, key, fallback=default).strip()


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

stream_info = request_json('/api/video/stream-info', headers=auth_headers).get('data', {})
self_check = request_json('/api/video/self-check', headers=auth_headers).get('data', {})
recording_status = request_json('/api/video/recording/status', headers=auth_headers).get('data', {})

if not stream_info.get('configured') or not stream_info.get('rtspConfigured'):
    raise RuntimeError(f\"video stream is not configured: {stream_info}\")
if not stream_info.get('configSynchronized'):
    raise RuntimeError(f\"mediamtx config is not synchronized: {stream_info}\")
if not stream_info.get('apiReachable'):
    raise RuntimeError(f\"mediamtx api port is not reachable: {stream_info}\")
if not stream_info.get('hlsReachable'):
    raise RuntimeError(f\"mediamtx hls port is not reachable: {stream_info}\")
if not stream_info.get('webrtcReachable'):
    raise RuntimeError(f\"mediamtx webrtc port is not reachable: {stream_info}\")
if self_check.get('overallStatus') == 'error':
    raise RuntimeError(f\"video self-check reported blocking issues: {self_check}\")
if recording_status.get('healthStatus') == 'error':
    raise RuntimeError(f\"recording status is unhealthy: {recording_status}\")

parser = configparser.ConfigParser(strict=False)
if not parser.read(config_path, encoding='utf-8'):
    raise RuntimeError(f\"failed to read backend config: {config_path}\")

main_resolution_key = 'camera/main_stream_resolution'
main_fps_key = 'camera/main_stream_fps'
main_codec_key = 'camera/main_stream_codec'
sub_resolution_key = 'camera/sub_stream_resolution'
sub_fps_key = 'camera/sub_stream_fps'
sub_codec_key = 'camera/sub_stream_codec'
recording_input_codec_key = 'recording/input_codec'

main_resolution = cfg(parser, 'camera', 'main_stream_resolution', '2k')
main_fps = cfg(parser, 'camera', 'main_stream_fps', '20')
main_codec = cfg(parser, 'camera', 'main_stream_codec', 'auto')
sub_resolution = cfg(parser, 'camera', 'sub_stream_resolution', '720p')
sub_fps = cfg(parser, 'camera', 'sub_stream_fps', '15')
sub_codec = cfg(parser, 'camera', 'sub_stream_codec', 'h264')
recording_input_codec = cfg(parser, 'recording', 'input_codec', str(recording_status.get('inputCodec') or 'auto'))

stream_path = str(stream_info.get('streamPath') or 'camera').strip().strip('/')
if not stream_path:
    raise RuntimeError(f\"stream path is empty: {stream_info}\")

check_items = self_check.get('checkItems') or []
check_item_summary = ','.join(
    f\"{item.get('key')}:{item.get('status')}\" for item in check_items if isinstance(item, dict)
)
if not check_item_summary:
    check_item_summary = 'none'

last_error = str(stream_info.get('lastError') or '').strip() or 'none'
recording_message = str(recording_status.get('healthMessage') or '').strip() or 'none'
summary_message = str(self_check.get('summaryMessage') or '').strip() or 'none'

browser_monitor_url = f\"{browser_base}/monitor\"
browser_hls_url = f\"{browser_base}/media/hls/{stream_path}/index.m3u8\"
browser_webrtc_player_url = f\"{browser_base}/media/webrtc/{stream_path}/\"
browser_webrtc_whep_url = f\"{browser_base}/media/webrtc/{stream_path}/whep\"

print(
    'stream='
    f\"path={stream_path} api={int(bool(stream_info.get('apiReachable')))} \"
    f\"hls={int(bool(stream_info.get('hlsReachable')))} \"
    f\"webrtc={int(bool(stream_info.get('webrtcReachable')))} \"
    f\"sync={int(bool(stream_info.get('configSynchronized')))} lastError={last_error}\"
)
print(
    'self_check='
    f\"{self_check.get('overallStatus', 'unknown')}:{summary_message} items={check_item_summary}\"
)
print(
    'recording='
    f\"{recording_status.get('healthStatus', 'unknown')}:{recording_message} input={recording_input_codec}\"
)
print(
    'baseline='
    f\"main={main_resolution}/{main_fps}/{main_codec} \"
    f\"sub={sub_resolution}/{sub_fps}/{sub_codec} record={recording_input_codec}\"
)
print(
    'baseline_keys='
    f\"{main_resolution_key},{main_fps_key},{main_codec_key},\"
    f\"{sub_resolution_key},{sub_fps_key},{sub_codec_key},{recording_input_codec_key}\"
)
print(f\"browser_monitor_url={browser_monitor_url}\")
print(f\"browser_hls_url={browser_hls_url}\")
print(f\"browser_webrtc_player_url={browser_webrtc_player_url}\")
print(f\"browser_webrtc_whep_url={browser_webrtc_whep_url}\")
print('matrix_template=DOC/视频实机验收矩阵模板.md')
print('checklist=DOC/V1.1视频链路版本化验收清单.md')
PY
"; then
  print_stage_fail "verify_browser_matrix_readiness" "${logfile}" "browser matrix readiness verification failed"
  exit 1
fi

stream_summary="$(sed -n 's/^stream=//p' "${logfile}")"
self_check_summary="$(sed -n 's/^self_check=//p' "${logfile}")"
recording_summary="$(sed -n 's/^recording=//p' "${logfile}")"
baseline_summary="$(sed -n 's/^baseline=//p' "${logfile}")"
monitor_url="$(sed -n 's/^browser_monitor_url=//p' "${logfile}")"
hls_url="$(sed -n 's/^browser_hls_url=//p' "${logfile}")"
webrtc_player_url="$(sed -n 's/^browser_webrtc_player_url=//p' "${logfile}")"

print_stage_ok \
  "verify_browser_matrix_readiness" \
  "stream='${stream_summary}' self_check='${self_check_summary}' recording='${recording_summary}' baseline='${baseline_summary}' urls='monitor=${monitor_url} hls=${hls_url} webrtc=${webrtc_player_url}'"
