#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 https://github.com/OpenPathGuidingLibrary/openpgl.git src
cd src
# Find TBB cmake config - try multiple paths
TBB_CMAKE=$(find "$OUTPUT_DIR" -name "TBBConfig.cmake" -o -name "tbb-config.cmake" 2>/dev/null | head -1)
if [ -n "$TBB_CMAKE" ]; then
  TBB_CMAKE=$(dirname "$TBB_CMAKE")
fi
echo "TBB cmake dir: $TBB_CMAKE"
ls -la "$OUTPUT_DIR/lib/" 2>/dev/null || echo "no lib dir"
find "$OUTPUT_DIR" -name "*TBB*" -o -name "*tbb*" 2>/dev/null | head -20
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DOPENPGL_BUILD_TESTS=OFF -DOPENPGL_BUILD_EXAMPLES=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_TBB=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "Openpgl built"
