#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path


WHITELISTED_SUFFIXES = {
    ".py",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".mjs",
    ".cjs",
    ".java",
    ".go",
    ".rs",
    ".c",
    ".cc",
    ".cpp",
    ".h",
    ".hpp",
    ".cs",
    ".php",
    ".rb",
    ".sh",
    ".bash",
    ".zsh",
    ".yml",
    ".yaml",
    ".json",
    ".jsonc",
    ".toml",
    ".ini",
    ".cfg",
    ".conf",
    ".xml",
    ".html",
    ".css",
    ".scss",
    ".less",
    ".sql",
    ".md",
    ".vue",
}

WHITELISTED_BASENAMES = {
    "CMakeLists.txt",
    "Dockerfile",
}

WHITELISTED_PREFIXES = (
    "Dockerfile.",
)


@dataclass
class Report:
    checked: list[str] = field(default_factory=list)
    fixed: list[str] = field(default_factory=list)
    skipped: list[tuple[str, str]] = field(default_factory=list)


def run_git(repo_root: Path, args: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd or repo_root),
        capture_output=True,
        text=True,
        check=check,
    )


def find_repo_root(cwd: Path) -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=str(cwd),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise ValueError("current directory is not inside a git repository")
    return Path(result.stdout.strip()).resolve()


def resolve_target_path(raw_target: str, cwd: Path, repo_root: Path) -> Path:
    target = Path(raw_target)
    if not target.is_absolute():
        target = (cwd / target).resolve()
    else:
        target = target.resolve()

    if not target.exists():
        raise ValueError(f"target path does not exist: {target}")
    ensure_within_repo(target, repo_root, "target path")
    return target


def ensure_within_repo(path: Path, repo_root: Path, label: str) -> None:
    try:
        path.relative_to(repo_root)
    except ValueError as exc:
        raise ValueError(f"{label} is outside the git repository: {path}") from exc


def is_within_target(path: Path, target: Path) -> bool:
    if path == target:
        return True
    if target.is_dir():
        try:
            path.relative_to(target)
            return True
        except ValueError:
            return False
    return False


def pathspec_for_target(target: Path, repo_root: Path) -> str:
    if target == repo_root:
        return "."
    return target.relative_to(repo_root).as_posix()


def list_bulk_candidates(repo_root: Path, target: Path) -> list[Path]:
    result = run_git(
        repo_root,
        [
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            pathspec_for_target(target, repo_root),
        ],
    )
    raw_paths = [entry for entry in result.stdout.split("\0") if entry]
    return [(repo_root / entry).resolve() for entry in raw_paths]


def list_git_warned_paths(repo_root: Path, target: Path) -> set[Path]:
    warned_paths: set[Path] = set()
    pathspec = pathspec_for_target(target, repo_root)
    commands = (
        ["diff", "--check", "--", pathspec],
        ["diff", "--check", "--cached", "--", pathspec],
    )
    for args in commands:
        result = run_git(repo_root, args, check=False)
        for line in result.stdout.splitlines():
            if not line or line.startswith("+"):
                continue
            parts = line.split(":", 2)
            if len(parts) < 3:
                continue
            relative = parts[0]
            warned_paths.add((repo_root / relative).resolve())
    return warned_paths


def resolve_warned_path(raw_path: str, cwd: Path, repo_root: Path) -> Path:
    candidate = Path(raw_path)
    if candidate.is_absolute():
        resolved = candidate.resolve()
        ensure_within_repo(resolved, repo_root, "warned file")
        return resolved

    preferred = (cwd / candidate).resolve()
    fallback = (repo_root / candidate).resolve()
    existing_candidates = []
    for resolved in (preferred, fallback):
        try:
            resolved.relative_to(repo_root)
        except ValueError:
            continue
        if resolved.exists():
            existing_candidates.append(resolved)

    if existing_candidates:
        return existing_candidates[0]

    for resolved in (preferred, fallback):
        try:
            resolved.relative_to(repo_root)
            return resolved
        except ValueError:
            continue

    raise ValueError(f"warned file is outside the git repository: {raw_path}")


def is_ignored(repo_root: Path, path: Path) -> bool:
    relative = path.relative_to(repo_root).as_posix()
    result = run_git(
        repo_root,
        ["check-ignore", "-q", "--no-index", "--", relative],
        check=False,
    )
    return result.returncode == 0


def is_whitelisted_code_text(path: Path) -> bool:
    name = path.name
    if path.suffix.lower() in WHITELISTED_SUFFIXES:
        return True
    if name in WHITELISTED_BASENAMES:
        return True
    return any(name.startswith(prefix) for prefix in WHITELISTED_PREFIXES)


def should_process(path: Path, warned_paths: set[Path]) -> bool:
    return path in warned_paths or is_whitelisted_code_text(path)


def process_file(repo_root: Path, path: Path, warned_paths: set[Path], report: Report) -> None:
    relative = path.relative_to(repo_root).as_posix()

    if not path.exists():
        report.skipped.append((relative, "missing"))
        return
    if path.is_symlink() or not path.is_file():
        report.skipped.append((relative, "not a regular file"))
        return
    if is_ignored(repo_root, path):
        report.skipped.append((relative, "ignored by git"))
        return
    if not should_process(path, warned_paths):
        report.skipped.append((relative, "not in code-text whitelist"))
        return

    data = path.read_bytes()
    if b"\x00" in data:
        report.skipped.append((relative, "binary file"))
        return

    report.checked.append(relative)
    normalized = data.replace(b"\r\n", b"\n")
    if normalized == data:
        return

    path.write_bytes(normalized)
    report.fixed.append(relative)


def run(target_path: str, warned_files: list[str], cwd: Path | None = None) -> Report:
    current_dir = (cwd or Path.cwd()).resolve()
    repo_root = find_repo_root(current_dir)
    target = resolve_target_path(target_path, current_dir, repo_root)

    report = Report()
    warned_paths: set[Path] = set()
    warned_paths.update(list_git_warned_paths(repo_root, target))
    for raw_path in warned_files:
        try:
            warned_path = resolve_warned_path(raw_path, current_dir, repo_root)
        except ValueError as exc:
            report.skipped.append((raw_path, str(exc)))
            continue
        warned_paths.add(warned_path)

    candidates = set(list_bulk_candidates(repo_root, target))
    for warned_path in warned_paths:
        if not is_within_target(warned_path, target):
            relative = warned_path.relative_to(repo_root).as_posix()
            report.skipped.append((relative, "outside target path"))
            continue
        candidates.add(warned_path)

    for path in sorted(candidates):
        process_file(repo_root, path, warned_paths, report)
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Repair CRLF line endings for code-text files in the current git path.",
    )
    parser.add_argument(
        "target_path",
        nargs="?",
        default=".",
        help="Path to scan, relative to the current working directory.",
    )
    parser.add_argument(
        "--warned-file",
        action="append",
        default=[],
        help="Specific file flagged by git output; bypasses the extension whitelist for that file only.",
    )
    return parser


def print_report(report: Report) -> None:
    print(f"checked: {len(report.checked)}")
    print(f"fixed: {len(report.fixed)}")
    print(f"skipped: {len(report.skipped)}")
    if report.fixed:
        print("fixed files:")
        for relative in report.fixed:
            print(relative)
    if report.skipped:
        print("skipped files:")
        for relative, reason in report.skipped:
            print(f"{relative}: {reason}")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        report = run(args.target_path, args.warned_file)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    print_report(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
