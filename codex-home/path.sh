#!/usr/bin/env sh

codex_local_bin="$HOME/.local/bin"
codex_npm_bin="$HOME/.codex/npm-global/bin"
case "${CODEX_DEFAULT_MODEL:-}" in
  ""|gpt-5.5) CODEX_DEFAULT_MODEL="gpt-5.6-sol" ;;
esac
case "${CODEX_DEFAULT_REASONING_EFFORT:-}" in
  ""|medium) CODEX_DEFAULT_REASONING_EFFORT="high" ;;
esac
CODEX_STARTUP_HTTP_ATTEMPTS="${CODEX_STARTUP_HTTP_ATTEMPTS:-3}"
CODEX_TOKEN_REFRESH_MIN_SECONDS="${CODEX_TOKEN_REFRESH_MIN_SECONDS:-86400}"
export CODEX_DEFAULT_MODEL CODEX_DEFAULT_REASONING_EFFORT
export CODEX_STARTUP_HTTP_ATTEMPTS CODEX_TOKEN_REFRESH_MIN_SECONDS

get_codex_target_triple() {
  local os_name
  local machine
  os_name="$(uname -s 2>/dev/null)" || return 1
  machine="$(uname -m 2>/dev/null)" || return 1

  case "$os_name:$machine" in
    Linux:x86_64|Linux:amd64|Android:x86_64|Android:amd64)
      printf '%s\n' 'x86_64-unknown-linux-musl'
      ;;
    Linux:aarch64|Linux:arm64|Android:aarch64|Android:arm64)
      printf '%s\n' 'aarch64-unknown-linux-musl'
      ;;
    Darwin:x86_64|Darwin:amd64)
      printf '%s\n' 'x86_64-apple-darwin'
      ;;
    Darwin:aarch64|Darwin:arm64)
      printf '%s\n' 'aarch64-apple-darwin'
      ;;
    *)
      return 1
      ;;
  esac
}

get_codex_vendor_path_dir() {
  local target_triple
  local package_name
  local vendor_path
  target_triple="$(get_codex_target_triple)" || return 1

  case "$target_triple" in
    x86_64-unknown-linux-musl)
      package_name='@openai/codex-linux-x64'
      ;;
    aarch64-unknown-linux-musl)
      package_name='@openai/codex-linux-arm64'
      ;;
    x86_64-apple-darwin)
      package_name='@openai/codex-darwin-x64'
      ;;
    aarch64-apple-darwin)
      package_name='@openai/codex-darwin-arm64'
      ;;
    *)
      return 1
      ;;
  esac

  vendor_path="$HOME/.codex/npm-global/lib/node_modules/@openai/codex/node_modules/$package_name/vendor/$target_triple/path"
  [ -d "$vendor_path" ] || return 1
  printf '%s\n' "$vendor_path"
}

codex_vendor_path="$(get_codex_vendor_path_dir)"
path_entries=""

append_path() {
  [ -n "${1:-}" ] || return 0

  case ":$path_entries:" in
    *":$1:"*)
      return 0
      ;;
  esac

  if [ -z "$path_entries" ]; then
    path_entries="$1"
  else
    path_entries="$path_entries:$1"
  fi
}

append_path "$codex_local_bin"
append_path "$codex_npm_bin"
append_path "$codex_vendor_path"

IFS=:
for segment in $PATH; do
  [ -n "$segment" ] || continue
  case "$segment" in
    "$codex_local_bin"|"$codex_npm_bin"|/mnt/c/Users/*/AppData/Roaming/npm)
      continue
      ;;
  esac
  append_path "$segment"
done
unset IFS

PATH="$path_entries"
export PATH
