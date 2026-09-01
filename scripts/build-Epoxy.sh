#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
# Use autotools approach for epoxy on Android
git clone --depth 1 --branch 1.5.10 https://github.com/anholt/libepoxy.git src
cd src
# Create a minimal CMakeLists.txt for cross-compilation
cat > CMakeLists.txt << 'CMAKEOF'
cmake_minimum_required(VERSION 3.10)
project(epoxy C)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
add_library(epoxy SHARED src/dispatch_common.c src/dispatch_egl.c src/dispatch_gl.c)
target_compile_definitions(epoxy PRIVATE EPOXY_NO_GLX EPOXY_IS_ANDROID)
target_include_directories(epoxy PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
install(TARGETS epoxy LIBRARY DESTINATION lib)
install(DIRECTORY include/ DESTINATION include)
CMAKEOF
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON
cmake --build build -j$(nproc)
cmake --install build
echo "Epoxy built"
