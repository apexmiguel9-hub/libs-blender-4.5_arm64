#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 https://github.com/KhronosGroup/OpenCOLLADA.git src
cd src
# Patch CMakeLists to remove BZip2/Readline/Editline deps
sed -i 's/find_package(BZip2/#find_package(BZip2/' CMakeLists.txt 2>/dev/null || true
sed -i 's/find_package(Readline/#find_package(Readline/' CMakeLists.txt 2>/dev/null || true
sed -i 's/find_package(Editline/#find_package(Editline/' CMakeLists.txt 2>/dev/null || true
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DOPENCOLLADA_BUILD_TESTS=OFF -DOPENCOLLADA_BUILD_TOOLS=OFF \
  -DOPENCOLLADA_BUILD_VIEWER=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "OpenCOLLADA built"
