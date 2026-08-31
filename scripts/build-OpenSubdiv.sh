#!/bin/bash
# Build OpenSubdiv for Android ARM64
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v3_6_0 https://github.com/PixarAnimationStudios/OpenSubdiv.git src
cd src
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DOSD_BUILD_TESTS=OFF -DOSD_BUILD_EXAMPLES=OFF -DOSD_BUILD_PYREGRESSION=OFF \
  -DOSD_BUILD_PYTHON=OFF -DOSD_CUDA_SUPPORT=OFF -DOSD_OPENCL_SUPPORT=OFF \
  -DOSD_METAL_SUPPORT=OFF -DOSD_VULKAN_SUPPORT=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "OpenSubdiv built"
