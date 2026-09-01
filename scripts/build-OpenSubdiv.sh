#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v3_6_0 https://github.com/PixarAnimationStudios/OpenSubdiv.git src
cd src

# Remove glLoader entirely — it requires desktop GL headers we don't have
rm -rf glLoader

# Patch out the glLoader subdirectory from the top-level CMakeLists.txt
# and remove the install() block that errors with cmake 3.31 (empty file list)
python3 -c "
import re
txt = open('CMakeLists.txt').read()
# Remove glLoader from add_subdirectory
txt = txt.replace('add_subdirectory(glLoader)', '# add_subdirectory(glLoader) # removed for Android')
# Remove OPENGL_LOADER_OBJS references
txt = re.sub(r'\\\$\{OPENGL_LOADER_OBJS\}', '', txt)
open('CMakeLists.txt','w').write(txt)
print('Patched top-level CMakeLists.txt')
"

# Patch osd/CMakeLists.txt — remove install blocks and the osd_gpu_obj references
python3 -c "
import re
txt = open('opensubdiv/osd/CMakeLists.txt').read()
# Remove all install() blocks (they fail with empty file lists on cmake 3.31)
txt = re.sub(r'install\([^)]*\)', '# install removed for Android', txt, flags=re.DOTALL)
# Remove osd_gpu_obj references (causes 'target not found' when GPU is disabled)
txt = re.sub(r'\\\$\<TARGET_OBJECTS:osd_gpu_obj\>', '', txt)
txt = re.sub(r'add_library\(osd_gpu_obj[^)]*\)', '# osd_gpu_obj removed', txt, flags=re.DOTALL)
txt = re.sub(r'set_target_properties\(osd_gpu_obj[^)]*\)', '# osd_gpu_obj removed', txt, flags=re.DOTALL)
open('opensubdiv/osd/CMakeLists.txt','w').write(txt)
print('Patched opensubdiv/osd/CMakeLists.txt')
"

# Also patch the inner CMakeLists.txt for osd regression tests
if [ -f regression/common/CMakeLists.txt ]; then
  sed -i 's/add_library(regression_common_obj/# add_library(regression_common_obj/' regression/common/CMakeLists.txt 2>/dev/null || true
fi

cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_PREFIX_PATH="$OUTPUT_DIR" \
  -DCMAKE_FIND_ROOT_PATH="$OUTPUT_DIR" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
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

# Build ONLY the CPU static lib targets
cmake --build build -j$(nproc) --target osd_static_cpu 2>/dev/null || \
cmake --build build -j$(nproc) --target osdCPU 2>/dev/null || \
cmake --build build -j$(nproc)

# Manual install
mkdir -p "$OUTPUT_DIR/lib" "$OUTPUT_DIR/include/opensubdiv"

find build -name "*.a" | while read f; do
  cp -v "$f" "$OUTPUT_DIR/lib/" 2>/dev/null || true
done
find build -name "*.so" | while read f; do
  cp -v "$f" "$OUTPUT_DIR/lib/" 2>/dev/null || true
done

for dir in osd far hbr sdc vtr bfr; do
  if [ -d "opensubdiv/$dir" ]; then
    cp -r "opensubdiv/$dir" "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
  fi
done
find opensubdiv -maxdepth 1 -name "*.h" -exec cp {} "$OUTPUT_DIR/include/opensubdiv/" \; 2>/dev/null || true

echo "OpenSubdiv built and installed to $OUTPUT_DIR"
find "$OUTPUT_DIR/lib" -name "*.a" -o -name "*.so" | sort
