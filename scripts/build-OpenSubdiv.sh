#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v3_6_0 https://github.com/PixarAnimationStudios/OpenSubdiv.git src
cd src

# Remove glLoader directory (requires desktop GL headers we don't have)
rm -rf glLoader

# Patch ALL CMakeLists.txt files to remove GPU/install references
python3 << 'PATCH'
import re

# === 1. Top-level CMakeLists.txt ===
txt = open('CMakeLists.txt').read()
txt = txt.replace('add_subdirectory(glLoader)', '# add_subdirectory(glLoader) # removed for Android')
txt = re.sub(r'\$\{OPENGL_LOADER_OBJS\}', '', txt)
open('CMakeLists.txt', 'w').write(txt)
print('Patched: CMakeLists.txt (top-level)')

# === 2. opensubdiv/CMakeLists.txt ===
# This has $<TARGET_OBJECTS:osd_gpu_obj> at lines 159, 231, 313, 362
txt = open('opensubdiv/CMakeLists.txt').read()

# Remove osd_gpu_obj references (they cause "target not found" when GPU is disabled)
txt = re.sub(r'\$<TARGET_OBJECTS:osd_gpu_obj>', '', txt)

# Remove install() blocks — cmake 3.31 errors when file list is empty
txt = re.sub(r'install\([^)]*\)', '# install removed for Android', txt, flags=re.DOTALL)

open('opensubdiv/CMakeLists.txt', 'w').write(txt)
print('Patched: opensubdiv/CMakeLists.txt')

# === 3. opensubdiv/osd/CMakeLists.txt ===
txt = open('opensubdiv/osd/CMakeLists.txt').read()
txt = re.sub(r'install\([^)]*\)', '# install removed for Android', txt, flags=re.DOTALL)
txt = re.sub(r'add_library\(osd_gpu_obj[^)]*\)', '# osd_gpu_obj removed', txt, flags=re.DOTALL)
txt = re.sub(r'set_target_properties\(osd_gpu_obj[^)]*\)', '# osd_gpu_obj removed', txt, flags=re.DOTALL)
open('opensubdiv/osd/CMakeLists.txt', 'w').write(txt)
print('Patched: opensubdiv/osd/CMakeLists.txt')

# === 4. regression/common/CMakeLists.txt ===
try:
    txt = open('regression/common/CMakeLists.txt').read()
    txt = re.sub(r'add_library\(regression_common_obj[^)]*\)', '# regression_common_obj removed', txt, flags=re.DOTALL)
    open('regression/common/CMakeLists.txt', 'w').write(txt)
    print('Patched: regression/common/CMakeLists.txt')
except FileNotFoundError:
    pass

print('All patches applied')
PATCH

cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DNO_EXAMPLES=ON -DNO_TUTORIALS=ON -DNO_DOC=ON \
  -DOSD_BUILD_TESTS=OFF -DOSD_BUILD_EXAMPLES=OFF \
  -DOSD_BUILD_PYREGRESSION=OFF -DOSD_BUILD_PYTHON=OFF \
  -DOSD_CUDA_SUPPORT=OFF -DOSD_OPENCL_SUPPORT=OFF \
  -DOSD_METAL_SUPPORT=OFF -DOSD_VULKAN_SUPPORT=OFF \
  -DOSD_CLEW_SUPPORT=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_OpenGL=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_GLEW=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_CLEW=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_OpenCL=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_CUDA=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_PTex=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_Docutils=TRUE

cmake --build build -j$(nproc) --target osd_static_cpu

# Manual install
mkdir -p "$OUTPUT_DIR/lib" "$OUTPUT_DIR/include/opensubdiv"

find build -name "*.a" | while read f; do
  cp -v "$f" "$OUTPUT_DIR/lib/" 2>/dev/null || true
done

for dir in osd far hbr sdc vtr bfr; do
  if [ -d "opensubdiv/$dir" ]; then
    cp -r "opensubdiv/$dir" "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
  fi
done
find opensubdiv -maxdepth 1 -name "*.h" -exec cp {} "$OUTPUT_DIR/include/opensubdiv/" \; 2>/dev/null || true

echo "OpenSubdiv built and installed to $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR/lib/"*.a 2>/dev/null
