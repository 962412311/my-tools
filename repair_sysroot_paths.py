#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import shutil
from pathlib import Path

TEXT_EXTS = {
    ".cmake", ".pc", ".la", ".pri", ".prl", ".txt", ".conf"
}

SEARCH_SUBDIRS = [
    "usr/lib/cmake",
    "usr/lib/aarch64-linux-gnu/cmake",
    "usr/lib64/cmake",
    "usr/lib64/aarch64-linux-gnu/cmake",
    "lib/cmake",
    "lib/aarch64-linux-gnu/cmake",
    "usr/lib/pkgconfig",
    "usr/lib/aarch64-linux-gnu/pkgconfig",
    "usr/lib64/pkgconfig",
    "usr/share/pkgconfig",
    "lib/pkgconfig",
]

SYMLINK_SCAN_DIRS = [
    "usr/lib",
    "usr/lib64",
    "lib",
]

ABS_PREFIXES = [
    "/usr/lib/aarch64-linux-gnu/",
    "/lib/aarch64-linux-gnu/",
    "/usr/include/",
    "/usr/share/",
    "/usr/lib64/",
    "/lib64/",
]

def is_probably_text(path: Path) -> bool:
    if path.suffix in TEXT_EXTS:
        return True
    try:
        data = path.read_bytes()[:4096]
    except Exception:
        return False
    return b"\x00" not in data

def backup_once(path: Path) -> None:
    bak = path.with_suffix(path.suffix + ".bak_before_py_fix")
    if not bak.exists():
        shutil.copy2(path, bak)

def collapse_sysroot_prefixes(text: str, sysroot: str) -> str:
    """
    压平以下异常：
      /opt/sysroot/binary/opt/sysroot/binary/...
      /opt/sysroot/binary/usr/opt/sysroot/binary/lib/...
      /opt/sysroot/binary/lib/opt/sysroot/binary/usr/...
    """
    s = text
    prev = None
    esc = re.escape(sysroot.rstrip("/"))

    while prev != s:
        prev = s

        # 先压纯重复
        s = re.sub(rf"(?:{esc}/)+", sysroot.rstrip("/") + "/", s)

        # 再压混合重复
        s = s.replace(f"{sysroot}/usr/{sysroot.lstrip('/')}/lib/", f"{sysroot}/lib/")
        s = s.replace(f"{sysroot}/usr/{sysroot.lstrip('/')}/usr/", f"{sysroot}/usr/")
        s = s.replace(f"{sysroot}/lib/{sysroot.lstrip('/')}/lib/", f"{sysroot}/lib/")
        s = s.replace(f"{sysroot}/lib/{sysroot.lstrip('/')}/usr/", f"{sysroot}/usr/")

        # 保险再压一次
        s = re.sub(rf"(?:{esc}/)+", sysroot.rstrip("/") + "/", s)

    return s

def remap_absolute_tokens(text: str, sysroot: str) -> str:
    """
    只改“独立路径 token”，避免在已经替换后的路径内部再次命中。
    """
    s = text

    def sub_prefix(prefix: str, src: str) -> str:
        escaped = re.escape(prefix)
        # 前面不能已经是 sysroot
        pattern = rf"(?<!{re.escape(sysroot)})(?<![A-Za-z0-9_]){escaped}([^;\"'\s]+)"
        return re.sub(pattern, lambda m: sysroot + prefix + m.group(1), src)

    for prefix in ABS_PREFIXES:
        s = sub_prefix(prefix, s)

    return s

def rewrite_text(text: str, sysroot: str) -> str:
    s = collapse_sysroot_prefixes(text, sysroot)
    s = remap_absolute_tokens(s, sysroot)
    s = collapse_sysroot_prefixes(s, sysroot)
    return s

def fix_text_file(path: Path, sysroot: str, dry_run: bool) -> bool:
    try:
        old = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return False

    new = rewrite_text(old, sysroot)
    if new == old:
        return False

    print(f"[FIX] {path}")
    if not dry_run:
        backup_once(path)
        path.write_text(new, encoding="utf-8")
    return True

def fix_symlink(path: Path, sysroot: str, dry_run: bool) -> bool:
    if not path.is_symlink():
        return False
    try:
        target = os.readlink(path)
    except OSError:
        return False

    if not target.startswith("/"):
        return False

    # 只处理常见系统绝对链接
    if not (
        target.startswith("/usr/lib")
        or target.startswith("/lib")
        or target.startswith("/usr/include")
        or target.startswith("/usr/share")
        or target.startswith("/usr/lib64")
        or target.startswith("/lib64")
    ):
        return False

    mapped = Path(sysroot) / target.lstrip("/")
    if not mapped.exists():
        return False

    rel = os.path.relpath(mapped, start=path.parent)
    print(f"[LINK] {path} -> {rel}")
    if not dry_run:
        path.unlink()
        path.symlink_to(rel)
    return True

def iter_files(base: Path):
    if not base.exists():
        return
    for p in base.rglob("*"):
        yield p

def main() -> int:
    parser = argparse.ArgumentParser(description="Repair sysroot path leakage and repeated prefixes.")
    parser.add_argument("--sysroot", required=True, help="例如 /opt/sysroot/binary")
    parser.add_argument("--dry-run", action="store_true", help="只打印，不落盘")
    parser.add_argument("--clean-build", help="可选：修复后删除这个 build 目录")
    args = parser.parse_args()

    sysroot = str(Path(args.sysroot).resolve())
    root = Path(sysroot)

    fixed_files = 0
    fixed_links = 0

    for sub in SEARCH_SUBDIRS:
        base = root / sub
        if not base.exists():
            continue
        for p in iter_files(base):
            if not p.is_file():
                continue
            if not is_probably_text(p):
                continue
            try:
                if fix_text_file(p, sysroot, args.dry_run):
                    fixed_files += 1
            except Exception as e:
                print(f"[WARN] text {p}: {e}")

    for sub in SYMLINK_SCAN_DIRS:
        base = root / sub
        if not base.exists():
            continue
        for p in iter_files(base):
            try:
                if fix_symlink(p, sysroot, args.dry_run):
                    fixed_links += 1
            except Exception as e:
                print(f"[WARN] symlink {p}: {e}")

    if args.clean_build:
        build_dir = Path(args.clean_build)
        if build_dir.exists():
            print(f"[CLEAN] {build_dir}")
            if not args.dry_run:
                shutil.rmtree(build_dir)

    print(f"[DONE] fixed_files={fixed_files}, fixed_links={fixed_links}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
