---
name: fix-git-crlf
description: Repair CRLF line-ending problems inside Git repositories. Use when the user explicitly asks to fix CRLF or normalize line endings, or when Git output such as git diff, git status, or git add shows CRLF warnings. Repair only the current path. Batch-scan only Git-visible code-text files in the built-in whitelist, but automatically widen the current run to include files named by git diff --check or git diff --check --cached warnings while still skipping ignored files and binary files.
---

# Fix Git CRLF

## Overview

Use `scripts/fix_crlf.py` to convert `CRLF` to `LF` safely inside the current Git path. Keep bulk repair conservative: honor Git ignore rules, scan only code-text files in the whitelist, and automatically widen the current run to files that the repository currently exposes through `git diff --check` or `git diff --check --cached`. The default whitelist covers common code-text suffixes plus `.vue`, `CMakeLists.txt`, `Dockerfile`, and `Dockerfile.*`.

## Workflow

1. Confirm that the current working directory is inside a Git repository. If not, stop and report that the skill cannot evaluate Git ignore rules outside a repository.
2. Resolve the current path scope. Repair only files under that path.
3. For an explicit user request to fix CRLF or normalize line endings, run:

```bash
python3 /home/parsifal/.codex/skills/fix-git-crlf/scripts/fix_crlf.py .
```

4. The script automatically inspects the current repository state with `git diff --check` and `git diff --check --cached` under the target path. Any warned file found there is treated as temporarily whitelisted for the current run.

5. If you already have concrete warned file paths from external Git output, pass them with `--warned-file` to widen the current run further:

```bash
python3 /home/parsifal/.codex/skills/fix-git-crlf/scripts/fix_crlf.py . \
  --warned-file path/from/git/output
```

6. If Git output lacks a concrete file path and the repository state does not reproduce a warning, fall back to the normal bulk scan and report that no specific warned file could be mapped.

## Safety Rules

- Respect Git ignore handling at all times. Do not modify files ignored by `.gitignore`, `.git/info/exclude`, or global Git ignore settings.
- Treat the built-in extension whitelist as the default boundary for bulk scans.
- Automatically widen the current run to files surfaced by `git diff --check` or `git diff --check --cached` under the target path.
- Allow additional widening for files explicitly named by `--warned-file`.
- Skip binary files even if they are warned files.
- Do not claim full repair if skipped files remain. Report the fixed file list and every skip reason.

## Output Expectations

- Report `checked`, `fixed`, and `skipped` counts.
- List each fixed file.
- List skipped files with reasons such as `ignored by git`, `binary file`, `outside target path`, or `not in code-text whitelist`.
