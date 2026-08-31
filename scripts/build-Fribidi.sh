#!/bin/bash
# Build Fribidi for Android ARM64
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch 1.0.15 https://github.com/fribidi/fribidi.git src
cd src
meson setup build \
  --cross-file "$NDK_DIR/build/cmake/android.toolchain.cmake" \
  --prefix="$OUTPUT_DIR" \
  --default-library=shared \
  -Dtests=false -Ddocs=false -Dfribidi-config=false
ninja -C build
ninja -C build install
echo "Fribidi built"
