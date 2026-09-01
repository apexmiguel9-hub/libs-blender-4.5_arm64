#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v3_6_0 https://github.com/PixarAnimationStudios/OpenSubdiv.git src
cd src
# Remove glLoader — but don't use sed /glLoader/d as it breaks CMakeLists parsing
# (removes lines mid-set() calls, losing closing parentheses)
rm -rf glLoader
# Just disable OpenGL entirely — Android uses GLES, not desktop GL
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DNO_OPENGL=TRUE \
  -DCMAKE_SKIP_INSTALL_RULES=TRUE \
  -DOSD_BUILD_TESTS=OFF -DOSD_BUILD_EXAMPLES=OFF \
  -DOSD_BUILD_PYREGRESSION=OFF -DOSD_BUILD_PYTHON=OFF \
  -DOSD_CUDA_SUPPORT=OFF -DOSD_OPENCL_SUPPORT=OFF \
  -DOSD_METAL_SUPPORT=OFF -DOSD_VULKAN_SUPPORT=OFF \
  -DOSD_CLEW_SUPPORT=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_OpenGL=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_GLEW=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_CLEW=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_OpenCL=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_CUDA=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_PTex=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Docutils=TRUE
cmake --build build -j$(nproc)

# Manual install since we skipped install rules
mkdir -p "$OUTPUT_DIR/lib" "$OUTPUT_DIR/include/opensubdiv"

# Copy static/shared libs
find build -name "*.a" -o -name "*.so" | while read f; do
  cp -v "$f" "$OUTPUT_DIR/lib/" 2>/dev/null || true
done

# Copy headers
cp -r src/opensubdiv/osd "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
cp -r src/opensubdiv/hbr "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
cp -r src/opensubdiv/vtr "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
cp -r src/opensubdiv/sdc "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
cp -r src/opensubdiv/far "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
cp -r src/opensubdiv/bfr "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
find src/opensubdiv -maxdepth 1 -name "*.h" -exec cp {} "$OUTPUT_DIR/include/opensubdiv/" \; 2>/dev/null || true

echo "OpenSubdiv built and installed to $OUTPUT_DIR"
