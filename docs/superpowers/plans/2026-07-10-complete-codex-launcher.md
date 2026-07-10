# Complete Codex Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Archive and deploy the verified `$HOME/.local/bin/codex` wrapper together with the existing `$HOME/.codex` Agent tree.

**Architecture:** Keep the wrapper in a new top-level `codex-launcher/` source directory so `codex-home/` remains a faithful `.codex` mirror. Extend the existing archive with `codex-launcher/codex`, then make the deploy script install that file to an independently selectable launcher target.

**Tech Stack:** POSIX `/bin/sh` for package/deploy helpers, Bash for the Codex wrapper, BSD/GNU `tar`, `rsync`, `shasum` or `sha256sum`, Git.

## Global Constraints

- `codex-launcher/codex` must be byte-for-byte identical to the verified live wrapper before repository edits.
- Do not refactor the imported 1278-line wrapper.
- Packaging and deployment helpers must remain compatible with macOS `/bin/sh`, BSD `tar`, BSD `mktemp`, system `rsync`, and `shasum`.
- The `/mnt/i` DrvFS workspace exposes executable files as mode `777`; Git must record the launcher as `100755`, while packaging normalizes the archive member to `0755` in a Linux temporary directory.
- Do not archive credentials, sessions, memories, caches, plugins, logs, databases, or mutable runtime state.
- Temporary deployment tests must not overwrite `$HOME/.local/bin/codex` or the real `$HOME/.codex` tree.

---

### Task 1: Add the controlled wrapper and archive it

**Files:**
- Create: `codex-launcher/codex`
- Modify: `scripts/codex-agent-tree/package.sh`
- Modify: `dist/codex-global-agent-tree.files`
- Modify: `dist/codex-global-agent-tree.tar.gz`
- Modify: `dist/codex-global-agent-tree.tar.gz.sha256`

**Interfaces:**
- Consumes: verified live wrapper `/home/chenziliang/.local/bin/codex`.
- Produces: executable source `codex-launcher/codex` and archive member `codex-launcher/codex`.

- [x] **Step 1: Record the live wrapper identity and confirm it is safe to archive**

Run:

```bash
stat -c '%a %s %n' /home/chenziliang/.local/bin/codex
sha256sum /home/chenziliang/.local/bin/codex
bash -n /home/chenziliang/.local/bin/codex
rg -n -i '(api[_-]?key|secret|password)[[:space:]]*=' /home/chenziliang/.local/bin/codex
```

Expected: mode `755`, Bash syntax exit `0`, and no embedded credential assignment.

- [x] **Step 2: Import the wrapper without modifying its contents**

Run a mechanical copy that preserves the executable mode:

```bash
mkdir -p codex-launcher
cp -p /home/chenziliang/.local/bin/codex codex-launcher/codex
chmod 0755 codex-launcher/codex
cmp -s /home/chenziliang/.local/bin/codex codex-launcher/codex
```

Expected: `cmp` exits `0`.

- [x] **Step 3: Extend package input validation and manifest generation**

Add beside `source_dir`:

```sh
launcher_source="$repo_root/codex-launcher/codex"
```

Add before creating the output directory:

```sh
if [ ! -f "$launcher_source" ]; then
  printf 'ERROR: launcher not found: %s\n' "$launcher_source" >&2
  exit 1
fi
```

Replace the manifest pipeline with:

```sh
{
  find "$source_dir" \
    \( -name '.git' \
      -o -name '.DS_Store' \
      -o -name '._*' \
      -o -name '__MACOSX' \
      -o -name 'auth.json' \
      -o -name 'config.toml' \
      -o -name 'state*.sqlite*' \
      -o -name 'sessions' \
      -o -name 'memories' \
      -o -name 'cache' \
      -o -name 'plugins' \
      -o -name 'log' \
      -o -name 'shell-snapshots' \) -prune \
    -o -type f -print \
    | sed "s|^$source_dir/||"
  printf '%s\n' 'codex-launcher/codex'
} | sort > "$manifest"
```

- [x] **Step 4: Normalize and include the launcher as a second archive input**

Copy the launcher to a Linux temporary directory so DrvFS permissions do not
leak into the archive:

```sh
tmp_dir=$(make_tmp_dir)
mkdir -p "$tmp_dir/codex-launcher"
cp "$launcher_source" "$tmp_dir/codex-launcher/codex"
chmod 0755 "$tmp_dir/codex-launcher/codex"

  -czf "$archive" \
  -C "$source_dir" . \
  -C "$tmp_dir" codex-launcher/codex
```

Expected: existing `.codex` archive paths remain unchanged and one new member appears at `codex-launcher/codex`.

- [x] **Step 5: Package and verify the archive**

Run:

```bash
sh -n scripts/codex-agent-tree/package.sh
scripts/codex-agent-tree/package.sh
sha256sum -c dist/codex-global-agent-tree.tar.gz.sha256
tar -tzvf dist/codex-global-agent-tree.tar.gz | rg 'codex-launcher/codex$'
cmp -s codex-launcher/codex <(tar -xOf dist/codex-global-agent-tree.tar.gz codex-launcher/codex)
```

Expected: checksum reports `OK`, archive mode is executable, and `cmp` exits `0`.

### Task 2: Deploy the wrapper from source and archive

**Files:**
- Modify: `scripts/codex-agent-tree/deploy.sh`

**Interfaces:**
- Consumes: source-tree or extracted archive member `codex-launcher/codex`.
- Produces: `--launcher-target PATH`, defaulting to `$HOME/.local/bin/codex`, installed with mode `0755`.

- [x] **Step 1: Add launcher source and destination state**

Add to the initial variables:

```sh
launcher_source="$repo_root/codex-launcher/codex"
launcher_target="$HOME/.local/bin/codex"
```

Extend usage text to:

```text
Usage:
  scripts/codex-agent-tree/deploy.sh [--target PATH] [--launcher-target PATH]
  scripts/codex-agent-tree/deploy.sh --archive PATH [--target PATH] [--launcher-target PATH]

Deploys the global Codex Agent file tree and Codex launcher wrapper.
```

- [x] **Step 2: Parse `--launcher-target` without changing `--target`**

Add this argument branch before `--archive`:

```sh
    --launcher-target)
      [ "$#" -ge 2 ] || { printf 'ERROR: --launcher-target requires a path\n' >&2; exit 1; }
      launcher_target="$2"
      shift 2
      ;;
```

- [x] **Step 3: Resolve the archive launcher and validate all inputs before writes**

After archive extraction add:

```sh
  launcher_source="$tmp_dir/codex-launcher/codex"
```

After the existing required-path loop add:

```sh
if [ ! -f "$launcher_source" ]; then
  printf 'ERROR: missing archived path: codex-launcher/codex\n' >&2
  exit 1
fi
```

- [x] **Step 4: Install and validate the wrapper**

Require `chmod` and `dirname` in addition to current commands, then add before final output:

```sh
launcher_dir=$(dirname "$launcher_target")
mkdir -p "$launcher_dir"
cp "$launcher_source" "$launcher_target"
chmod 0755 "$launcher_target"

if command -v bash >/dev/null 2>&1; then
  bash -n "$launcher_target"
fi
```

Report both destinations:

```sh
printf 'deployed=%s\n' "$target_dir"
printf 'launcher=%s\n' "$launcher_target"
```

- [x] **Step 5: Verify source-tree and archive deployment in isolated directories**

Run:

```bash
tmp_dir=$(mktemp -d)
scripts/codex-agent-tree/deploy.sh \
  --target "$tmp_dir/source/.codex" \
  --launcher-target "$tmp_dir/source/.local/bin/codex"
scripts/codex-agent-tree/deploy.sh \
  --archive dist/codex-global-agent-tree.tar.gz \
  --target "$tmp_dir/archive/.codex" \
  --launcher-target "$tmp_dir/archive/.local/bin/codex"
cmp -s codex-launcher/codex "$tmp_dir/source/.local/bin/codex"
cmp -s codex-launcher/codex "$tmp_dir/archive/.local/bin/codex"
test "$(stat -c '%a' "$tmp_dir/source/.local/bin/codex")" = 755
test "$(stat -c '%a' "$tmp_dir/archive/.local/bin/codex")" = 755
diff -qr "$tmp_dir/source/.codex" "$tmp_dir/archive/.codex"
rm -rf "$tmp_dir"
```

Expected: both deployments report their two targets, both `cmp` and mode checks pass, and `.codex` trees are identical.

### Task 3: Document, verify, commit, and push

**Files:**
- Modify: `README.md`
- Modify: `dist/codex-global-agent-tree.files`
- Modify: `dist/codex-global-agent-tree.tar.gz`
- Modify: `dist/codex-global-agent-tree.tar.gz.sha256`

**Interfaces:**
- Consumes: completed package and deploy behavior from Tasks 1 and 2.
- Produces: reproducible user instructions and pushed `origin/main` commits.

- [x] **Step 1: Document source layout and deployment behavior**

Update README content so it explicitly states:

```markdown
- `codex-launcher/codex`：安装到 `$HOME/.local/bin/codex` 的完整启动 wrapper
- `scripts/codex-agent-tree/deploy.sh`：部署 `.codex` 文件树和启动 wrapper
```

Add an isolated deployment example:

```bash
scripts/codex-agent-tree/deploy.sh \
  --archive dist/codex-global-agent-tree.tar.gz \
  --target /path/to/.codex \
  --launcher-target /path/to/.local/bin/codex
```

List `$HOME/.local/bin/codex` in the overwritten deployment boundary and keep all runtime exclusions unchanged.

- [x] **Step 2: Run complete verification**

Run:

```bash
bash -n codex-launcher/codex
sh -n codex-home/path.sh
sh -n scripts/codex-agent-tree/package.sh
sh -n scripts/codex-agent-tree/deploy.sh
cmp -s /home/chenziliang/.local/bin/codex codex-launcher/codex
sha256sum -c dist/codex-global-agent-tree.tar.gz.sha256
rg -n 'gpt-5.6-sol|default_codex_reasoning_effort="high"' codex-launcher/codex
git diff --check
git status --short --untracked-files=all
```

Expected: all syntax and identity checks pass, checksum reports `OK`, defaults are found, and only planned files are changed.

- [x] **Step 3: Commit implementation**

Run:

```bash
git add README.md scripts/codex-agent-tree/package.sh scripts/codex-agent-tree/deploy.sh dist/codex-global-agent-tree.files dist/codex-global-agent-tree.tar.gz dist/codex-global-agent-tree.tar.gz.sha256 docs/superpowers/plans/2026-07-10-complete-codex-launcher.md
git add --chmod=+x codex-launcher/codex
git commit -m "归档并部署 Codex 完整启动脚本"
```

- [x] **Step 4: Push and verify the remote branch**

Run:

```bash
git fetch origin
git rev-list --left-right --count origin/main...HEAD
git push origin main
git ls-remote --heads origin refs/heads/main
git status --short --branch
```

Expected: remote `main`, local `HEAD`, and `origin/main` resolve to the same commit and the worktree is clean.

### Task 4: Harden the imported launcher for macOS and WSL/Linux

**Files:**
- Modify: `codex-launcher/codex`
- Modify: `codex-home/path.sh`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-07-10-complete-codex-launcher-design.md`

- [x] **Step 1: Keep one launcher with platform-specific HOME lookup**

Use `getent passwd` on WSL/Linux, `dscl` on macOS, and `$HOME` as the final
fallback. Do not maintain separate launcher copies per platform.

- [x] **Step 2: Preserve macOS Bash 3.2 and zsh compatibility**

Avoid expanding an empty Bash array under `set -u`. Keep `path.sh` sourceable
from zsh without changing the caller's shell emulation mode, so nvm completion
continues to initialize normally.

- [x] **Step 3: Verify both platform branches**

Run the real launcher from a fresh macOS login shell and assert that it resolves
to `$HOME/.local/bin/codex`, reports the subscription/update status, and starts
the CLI without completion errors. Exercise the WSL/Linux HOME lookup with a
controlled `getent` fixture and confirm the same launcher reaches the real CLI.
