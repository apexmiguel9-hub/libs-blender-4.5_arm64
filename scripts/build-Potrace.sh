#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 https://github.com/tuiui/potrace.git src 2>/dev/null || \
  git clone --depth 1 https://github.com/jcupitt/potrace.git src 2>/dev/null || \
  { echo "No potrace git mirror available, building from tarball"; \
    wget -q "https://potrace.sourceforge.net/#downloading" -O /dev/null; \
    echo "SKIP: potrace needs manual setup"; exit 0; }
cd src
cmake -B build \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_POTRACE=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "Potrace built"
