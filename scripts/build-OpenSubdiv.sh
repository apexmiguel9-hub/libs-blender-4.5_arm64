#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v3_6_0 https://github.com/PixarAnimationStudios/OpenSubdiv.git src
cd src

rm -rf glLoader

# Nuclear patch: remove ALL install/export rules, all GPU targets, all example/tutorial targets
python3 << 'PATCH'
import os, re

for root, dirs, files in os.walk('.'):
    for fname in files:
        if fname == 'CMakeLists.txt':
            fpath = os.path.join(root, fname)
            txt = open(fpath).read()
            original = txt
            
            # Remove ALL install() blocks (handles nested parens)
            result = []
            i = 0
            while i < len(txt):
                if txt[i:i+8].lower() == 'install(' or txt[i:i+9].lower() == 'install (':
                    # Find matching closing paren
                    depth = 0
                    j = i
                    while j < len(txt):
                        if txt[j] == '(':
                            depth += 1
                        elif txt[j] == ')':
                            depth -= 1
                            if depth == 0:
                                result.append('# install removed for Android')
                                i = j + 1
                                break
                        j += 1
                    else:
                        result.append(txt[i])
                        i += 1
                else:
                    result.append(txt[i])
                    i += 1
            txt = ''.join(result)
            
            # Remove install(EXPORT ...) blocks specifically
            txt = re.sub(r'install\s*\(\s*EXPORT[^)]*\)', '# export install removed', txt, flags=re.DOTALL)
            
            # Remove osd_gpu_obj references
            txt = txt.replace('${OPENGL_LOADER_OBJS}', '')
            txt = re.sub(r'\$<TARGET_OBJECTS:osd_gpu_obj>', '', txt)
            
            # Remove regression_common_obj references
            txt = re.sub(r'\$<TARGET_OBJECTS:regression_common_obj>', '', txt)
            
            if txt != original:
                open(fpath, 'w').write(txt)
                print(f'Patched: {fpath}')

print('All patches applied')
PATCH

cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM="android-$API_LEVEL" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_SKIP_INSTALL_RULES=TRUE \
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

mkdir -p "$OUTPUT_DIR/lib" "$OUTPUT_DIR/include/opensubdiv"
find build -name "*.a" -exec cp {} "$OUTPUT_DIR/lib/" \;

for dir in osd far hbr sdc vtr bfr; do
  [ -d "opensubdiv/$dir" ] && cp -r "opensubdiv/$dir" "$OUTPUT_DIR/include/opensubdiv/" 2>/dev/null || true
done
find opensubdiv -maxdepth 1 -name "*.h" -exec cp {} "$OUTPUT_DIR/include/opensubdiv/" \; 2>/dev/null || true

echo "OpenSubdiv built"
ls -lh "$OUTPUT_DIR/lib/"*.a 2>/dev/null
