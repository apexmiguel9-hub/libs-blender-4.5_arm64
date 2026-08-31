#!/bin/bash
# Build OpenVDB for Android ARM64
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v11.0.0 https://github.com/AcademySoftwareFoundation/openvdb.git src
cd src
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DOPENVDB_BUILD_BINARIES=OFF -DOPENVDB_BUILD_UNITTESTS=OFF \
  -DOPENVDB_BUILD_DOCS=OFF -DOPENVDB_BUILD_EXAMPLES=OFF \
  -DOPENVDB_BUILD_PYTHON=OFF -DOPENVDB_BUILD_HOUDINI=OFF
cmake --build build -j$(nproc)
cmake --install build
echo "OpenVDB built"
