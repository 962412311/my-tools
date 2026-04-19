#!/bin/bash
set -e

APP_NAME="GOGS_backend"
SRC_PATH="/mnt/hgfs/QtWorkData/GOGS/backend"
BUILD_ROOT="/home/jamin/qt"
BUILD_PATH="$BUILD_ROOT/$APP_NAME/build/arm-gcc"
SYSROOT="/opt/sysroot/binary"

export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/aarch64-linux-gnu/pkgconfig:$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
unset PKG_CONFIG_PATH

rm -rf "$BUILD_PATH"
mkdir -p "$BUILD_PATH"
cd "$BUILD_PATH"

/opt/qt6.2.4-aarch64/bin/qt-cmake "$SRC_PATH" \
  -GNinja \
  -DCMAKE_SYSROOT="$SYSROOT" \
  -DCMAKE_FIND_ROOT_PATH="$SYSROOT" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
  -DCMAKE_IGNORE_PATH="/usr/lib/aarch64-linux-gnu;/lib/aarch64-linux-gnu;/usr/include" \
  -DPCL_DIR="$SYSROOT/usr/lib/aarch64-linux-gnu/cmake/pcl" \
  -DEIGEN_INCLUDE_DIR="$SYSROOT/usr/include/eigen3" \
  -DBOOST_ROOT="$SYSROOT/usr" \
  -DBOOST_INCLUDEDIR="$SYSROOT/usr/include" \
  -DBOOST_LIBRARYDIR="$SYSROOT/usr/lib/aarch64-linux-gnu" \
  -DFLANN_INCLUDE_DIR="$SYSROOT/usr/include" \
  -DFLANN_LIBRARY="$SYSROOT/usr/lib/aarch64-linux-gnu/libflann.so" \
  -Wno-dev

cmake --build .

mv ./app* "$SRC_PATH"