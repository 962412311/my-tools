---
name: patch-context-hygiene
description: Always use before any file edit or patch. Trigger it proactively on the first sign of editing intent, and whenever you see `Failed to apply patch`, `Failed to find expected lines`, or a suspicious path error. Check the target path first, then refresh file context and retry with a smaller hunk if needed.
---

# Patch Context Hygiene

Use this skill before editing files, especially with `apply_patch`, or when a patch fails to apply cleanly. Treat path validation as the first check, not a fallback. Do not wait for a failed edit to decide whether to use this skill.

## Goal

Avoid patch failures caused by stale context, file drift, line-ending mismatches, BOM issues, or editing the wrong path. When a patch fails, distinguish path mistakes from content mismatches before taking any other action.

## Required workflow

1. Re-read the exact target block before every patch.
2. Prefer the smallest possible hunk that accomplishes the change.
3. If you are creating a new file, first confirm the path is exactly correct.
4. If a patch fails, stop and determine whether the target path was wrong before doing anything else.
5. If the path is correct, refresh the file content before retrying.
6. Use raw command output for verification when filtered output might hide relevant lines.
7. Check file format when a file is repeatedly hard to patch.

## Before editing

- Confirm the file path is correct and case-sensitive for the current platform.
- If a path looks suspicious, verify the exact spelling, separators, case, and workspace root before patching.
- Re-open the specific lines you intend to change.
- Prefer one-file, one-purpose edits instead of bundling unrelated changes.
- If the target file changed recently, re-read it even if you already looked at it earlier in the turn.

## When a patch fails

Treat the error as data, not as a generic tool failure.

- `Failed to find expected lines` usually means the patch context is stale, the file changed, or the target path was not what you thought it was.
- `No such file or directory` is often a path problem, so verify spelling, casing, separators, and workspace root before trying anything else.
- Re-open the file immediately and compare the live content to the patch hunk.
- Reduce the hunk size if the file has shifted or contains repeated patterns.
- If the file is generated or frequently reformatted, consider replacing a larger contiguous block instead of trying to match many small fragments.
- If the file is a Windows script or text file, check for BOM and line-ending differences before retrying.
- If the target path fails unexpectedly, verify you are editing the intended file and not a typo, casing mismatch, or wrong workspace path.

## Verification

- Use `rtk proxy` when you need the unfiltered command output for patch context.
- Re-run `git diff` or the equivalent after editing to confirm only the intended lines changed.
- If the same patch fails twice, reassess the target block instead of adding more hunk fragments.

## Fallbacks

- If `apply_patch` fails because the target path is wrong, stop and correct the path before retrying.
- Only if the path exists and the patch still fails repeatedly should you consider a non-patch fallback.
- Keep any fallback limited to the failing file; do not broaden the edit scope.

## WSL Codex Note

- If the built-in `apply_patch` tool returns `No such file or directory` in WSL, do not assume the repo path is wrong.
- First verify the WSL-side Codex wrapper at `~/.local/bin/codex` is syntactically valid.
- Then check whether a session-local executable exists under `~/.codex/tmp/arg0/codex-arg0*/apply_patch` or `applypatch`; that direct executable can still work even when the built-in tool wrapper is broken.
- If you need `apply_patch` to work persistently in Codex on WSL/Linux, also verify the Codex vendor `path` directory that `bin/codex.js` prepends to `PATH`, because that is the stable place to mirror the wrapper.
- Prefer a stable wrapper in `~/.local/bin` and a symlink in the vendor `path` directory over relying only on the session-local temp shim.
- Keep this diagnosis on the WSL home/config side, not the Windows side of the workspace.

## Practical triage

When a patch fails, follow this order:

1. Check whether the path itself is wrong.
2. Check whether the file changed since you read it.
3. Check whether the hunk is too large or too broad.
4. Check file format issues such as BOM or line endings.
5. Only then consider a fallback edit method.

## Good defaults

- Patch one file at a time.
- Keep hunks narrow and local.
- Re-read, patch, verify, then move on.

## Trigger examples

Use this skill when the conversation looks like any of these:

- "Why did `apply_patch` fail again?"
- "I think the file path is wrong, can you fix the patch?"
- "This file changed underneath me, retry with a smaller patch."
