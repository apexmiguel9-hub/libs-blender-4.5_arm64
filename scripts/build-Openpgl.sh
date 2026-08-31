#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 https://github.com/OpenPathGuidingLibrary/openpgl.git src
cd src
# Find the TBB cmake config directory
TBB_CMAKE=$(find "$OUTPUT_DIR" -path "*/cmake/TBB/TBBConfig.cmake" -exec dirname {} \; 2>/dev/null | head -1)
echo "TBB cmake dir: $TBB_CMAKE"
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DTBB_DIR="$TBB_CMAKE" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DOPENPGL_BUILD_TESTS=OFF -DOPENPGL_BUILD_EXAMPLES=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "Openpgl built"
