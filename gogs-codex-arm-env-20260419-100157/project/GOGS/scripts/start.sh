#!/bin/bash
set -euo pipefail

APP_BASE_DIR="/userdata"
APP_FOLDER_NAME="GOGS/backend"
APP_NAME="抓斗作业引导及盘存系统-后端子系统"
APP_EXEC_NAME="GrabSystem"
QT_LIB_DIR="/opt/qt6.2.4-aarch64/lib"

APP_DIR="${APP_BASE_DIR%/}/${APP_FOLDER_NAME#/}"
APP_EXEC="$APP_DIR/$APP_EXEC_NAME"

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: App directory not found: $APP_DIR"
    exit 1
fi

if [ -d "$QT_LIB_DIR" ]; then
    export LD_LIBRARY_PATH="$QT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
else
    echo "WARN: Qt library directory not found: $QT_LIB_DIR"
fi

if [ ! -x "$APP_EXEC" ]; then
    echo "ERROR: App executable not found or not executable: $APP_EXEC"
    exit 1
fi

cd "$APP_DIR"

echo "INFO: Starting application: $APP_NAME"
exec "$APP_EXEC"