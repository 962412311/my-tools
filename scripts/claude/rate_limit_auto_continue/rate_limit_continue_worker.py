#!/usr/bin/env python3
import os
import subprocess
import sys
import time
from datetime import datetime


def main() -> int:
    if len(sys.argv) < 6:
        return 0

    reset_time = sys.argv[1].strip()
    try:
        seconds_until_reset = int(sys.argv[2])
    except ValueError:
        seconds_until_reset = 0
    session_id = sys.argv[3].strip()
    lock_file = sys.argv[4].strip()
    log_file = sys.argv[5].strip()

    if not reset_time or not session_id or not lock_file:
        return 0

    try:
        os.setsid()
    except Exception:
        pass

    def log(message: str) -> None:
        with open(log_file, "a", encoding="utf-8") as fh:
            fh.write(f"{datetime.now():%F %T} {message}\n")

    log(f"[INFO] 检测到 rate limit，重置时间: {reset_time}，等待秒数: {seconds_until_reset}")

    if seconds_until_reset > 10:
        time.sleep(seconds_until_reset - 10)
        subprocess.run(
            [
                "osascript",
                "-e",
                'display notification "Claude 即将自动输入 继续 并回车" with title "Claude Code 限额恢复提醒"',
            ],
            check=False,
        )
        time.sleep(10)
    elif seconds_until_reset > 0:
        time.sleep(seconds_until_reset)
        time.sleep(10)
    else:
        time.sleep(10)

    script = """set the clipboard to "继续"
tell application "System Events"
    delay 0.2
    keystroke "v" using command down
    delay 0.6
    keystroke return
end tell
"""
    subprocess.run(["osascript"], input=script.encode("utf-8"), check=False)

    log("[INFO] 已自动输入“继续”并回车")
    try:
        os.remove(lock_file)
    except FileNotFoundError:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
