#!/bin/bash
set -euo pipefail

# 配置区：只改这里即可复用到其他应用
APP_BASE_DIR="/userdata"
APP_FOLDER_NAME="GOGS/backend"
APP_NAME="抓斗作业引导及盘存系统-后端子系统"
APP_EXEC_NAME="GrabSystem"
QT_LIB_DIR="/opt/qt6.2.4-aarch64/lib"
ENABLE_FULLSCREEN=false

APP_DIR="${APP_BASE_DIR%/}/${APP_FOLDER_NAME#/}"
APP_TITLE="$APP_NAME"
APP_EXEC="./$APP_EXEC_NAME"

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: App directory not found: $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

if [ -d "$QT_LIB_DIR" ]; then
    export LD_LIBRARY_PATH="$QT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
else
    echo "WARN: Qt library directory not found: $QT_LIB_DIR"
fi

if [ ! -e "$APP_EXEC" ]; then
    echo "ERROR: App executable not found: $APP_DIR/$APP_EXEC_NAME"
    exit 1
fi

echo "INFO: Starting application: $APP_NAME"
"$APP_EXEC" &

if [ "$ENABLE_FULLSCREEN" != "true" ]; then
    echo "INFO: Fullscreen disabled by config. Script finished."
    exit 0
fi

echo "INFO: Waiting for window with title '$APP_TITLE'..."
WINDOW_ID=""
for i in {1..100}; do
    WINDOW_ID=$(xdotool search --onlyvisible --name "$APP_TITLE" 2>/dev/null | head -n1 || true)
    if [ -n "$WINDOW_ID" ]; then
        echo "SUCCESS: Window found with ID: $WINDOW_ID"
        break
    fi
    sleep 0.1
done

if [ -z "$WINDOW_ID" ]; then
    echo "ERROR: Window '$APP_TITLE' not found after 10 seconds. Exiting."
    pkill -f "$APP_EXEC_NAME" || true
    exit 1
fi

echo "INFO: Activating window ID: $WINDOW_ID"
xdotool windowactivate "$WINDOW_ID"
sleep 0.3

echo "INFO: Sending F11 key to toggle fullscreen..."
xdotool key --window "$WINDOW_ID" F11

echo "INFO: Script finished."
