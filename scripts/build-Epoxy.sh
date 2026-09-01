#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch 1.5.10 https://github.com/anholt/libepoxy.git src
cd src
# For Android, just build the header - epoxy is typically loaded at runtime via the system
# Install headers only
mkdir -p "$OUTPUT_DIR/include"
cp -r include/* "$OUTPUT_DIR/include/"
# Create a stub library
cat > stub.c << 'STUB'
#include "epoxy/gl.h"
void epoxy_gl_stub(void) {}
STUB
cat > CMakeLists.txt << 'CMAKEOF'
cmake_minimum_required(VERSION 3.10)
project(epoxy C)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
add_library(epoxy SHARED stub.c)
target_include_directories(epoxy PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
install(TARGETS epoxy LIBRARY DESTINATION lib)
install(DIRECTORY include/epoxy DESTINATION include)
CMAKEOF
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR"
cmake --build build -j$(nproc)
cmake --install build
echo "Epoxy built"
