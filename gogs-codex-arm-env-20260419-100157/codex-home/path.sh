#!/usr/bin/env sh

codex_local_bin="$HOME/.local/bin"
codex_npm_bin="$HOME/.codex/npm-global/bin"
get_codex_target_triple() {
  case "$(uname -m)" in
    x86_64|amd64)
      printf '%s\n' 'x86_64-unknown-linux-musl'
      ;;
    aarch64|arm64)
      printf '%s\n' 'aarch64-unknown-linux-musl'
      ;;
    *)
      return 1
      ;;
  esac
}

get_codex_vendor_path_dir() {
  local target_triple
  local package_name
  target_triple="$(get_codex_target_triple)" || return 1

  case "$target_triple" in
    x86_64-unknown-linux-musl)
      package_name='@openai/codex-linux-x64'
      ;;
    aarch64-unknown-linux-musl)
      package_name='@openai/codex-linux-arm64'
      ;;
    *)
      return 1
      ;;
  esac

  printf '%s\n' "$HOME/.codex/npm-global/lib/node_modules/@openai/codex/node_modules/$package_name/vendor/$target_triple/path"
}

codex_vendor_path="$(get_codex_vendor_path_dir)"
path_entries=""

append_path() {
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

# Prefer the stable apply_patch wrapper, while still allowing direct calls
# to the session-local shim when it exists.
apply_patch() {
  "$HOME/.local/bin/apply_patch" "$@"
}

applypatch() {
  apply_patch "$@"
}
