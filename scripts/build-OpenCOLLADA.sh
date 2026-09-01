#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 https://github.com/KhronosGroup/OpenCOLLADA.git src
cd src
# Patch out all external deps we don't have
sed -i 's/find_package(BZip2/#find_package(BZip2/' CMakeLists.txt 2>/dev/null || true
sed -i 's/find_package(Readline/#find_package(Readline/' CMakeLists.txt 2>/dev/null || true
sed -i 's/find_package(Editline/#find_package(Editline/' CMakeLists.txt 2>/dev/null || true
# Patch LibXml2 find to use static lib
sed -i 's/find_package(LibXml2/find_package(LibXml2 CONFIG/' CMakeLists.txt 2>/dev/null || true
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DOPENCOLLADA_BUILD_TESTS=OFF -DOPENCOLLADA_BUILD_TOOLS=OFF \
  -DOPENCOLLADA_BUILD_VIEWER=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_LibXml2=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_pcre=TRUE
cmake --build build -j$(nproc) || {
  echo "OpenCOLLADA build failed, trying with explicit include paths"
  XML_INC=$(find "$OUTPUT_DIR/include" -name "libxml" -type d | head -1)
  XML_LIB=$(find "$OUTPUT_DIR/lib" -name "libxml2*" | head -1)
  cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
    -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
    -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
    -DLIBXML2_INCLUDE_DIR="$XML_INC" \
    -DLIBXML2_LIBRARY="$XML_LIB" \
    -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DOPENCOLLADA_BUILD_TESTS=OFF -DOPENCOLLADA_BUILD_TOOLS=OFF \
    -DOPENCOLLADA_BUILD_VIEWER=OFF
  cmake --build build -j$(nproc)
}
cmake --install build 2>/dev/null || true
echo "OpenCOLLADA built"
