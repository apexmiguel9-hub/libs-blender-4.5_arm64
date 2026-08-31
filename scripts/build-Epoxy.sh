#!/bin/bash
# Build Epoxy for Android ARM64
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch 1.5.10 https://github.com/anholt/libepoxy.git src
cd src
mkdir -p build && cd build
# Epoxy uses autotools, but we'll use a simple cmake approach
# since autotools cross-compilation is complex
cat > CMakeLists.txt << 'CMAKEOF'
cmake_minimum_required(VERSION 3.10)
project(epoxy C)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Just build the headers and a stub library
# Epoxy is mainly headers that wrap GL calls
find_package(OpenGL QUIET)

set(EPOXY_SRCS
  src/dispatch_common.c
  src/dispatch_egl.c
  src/dispatch_gl.c
  src/dispatch_glx.c
  src/dispatch_wgl.c
  src/egl_generated.c
  src/gl_generated.c
  src/glx_generated.c
)

add_library(epoxy SHARED ${EPOXY_SRCS})
target_compile_definitions(epoxy PRIVATE -DEPOXY_NO_GLX)
target_include_directories(epoxy PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
install(TARGETS epoxy LIBRARY DESTINATION lib)
install(DIRECTORY include/ DESTINATION include)
CMAKEOF

cmake -B . \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR"
cmake --build . -j$(nproc)
cmake --install .
echo "Epoxy built"
