#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

# Install PCRE to sysroot
git clone --depth 1 https://github.com/PCRE2Project/pcre2.git /tmp/pcre2
cd /tmp/pcre2
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DPCRE2_BUILD_TESTS=OFF -DPCRE2_SUPPORT_JIT=OFF
cmake --build build -j$(nproc)
cmake --install build

cd "$BUILD_DIR"
git clone --depth 1 https://github.com/KhronosGroup/OpenCOLLADA.git src
cd src
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DOPENCOLLADA_BUILD_TESTS=OFF -DOPENCOLLADA_BUILD_VIEWER=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "OpenCOLLADA built"
