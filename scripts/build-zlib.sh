#!/bin/bash
# Build zlib for Android ARM64
# Args: NDK_DIR OUTPUT_DIR BUILD_DIR API_LEVEL
set -euo pipefail

NDK_DIR="$1"
OUTPUT_DIR="$2"
BUILD_DIR="$3"
API_LEVEL="${4:-24}"

mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib.git src
cd src

cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON

cmake --build build -j$(nproc)
cmake --install build

echo "zlib built successfully"
