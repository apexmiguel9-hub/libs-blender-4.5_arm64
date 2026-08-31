#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch bzip2-1.0.8 https://gitlab.com/bzip2/bzip2.git src 2>/dev/null || \
wget -q https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz -O bzip2.tar.gz && \
tar xzf bzip2.tar.gz && mv bzip2-1.0.8 src
cd src
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON
cmake --build build -j$(nproc)
cmake --install build
echo "BZip2 built"
