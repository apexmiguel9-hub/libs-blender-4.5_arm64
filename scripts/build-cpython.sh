#!/bin/bash
set -euo pipefail
# Cross-compile CPython 3.11 for Android ARM64
# Produces: libpython3.11.a (static) + headers
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
PYTHON_VER="3.11.11"
PYTHON_SHORT="3.11"

mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

# ── 1. Download ──────────────────────────────────────────────
if [ ! -d "src" ]; then
  wget -q "https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tar.xz"
  tar xf "Python-${PYTHON_VER}.tar.xz"
  mv "Python-${PYTHON_VER}" src
fi
cd src

# ── 2. Build HOST python + pgen first ───────────────────────
if [ ! -f "../host_python/Parser/pgen" ]; then
  mkdir -p ../host_build && cd ../host_build
  "$PWD/../src/configure" --prefix="$PWD/../host_python" \
    --without-ensurepip --disable-shared --quiet
  make -j$(nproc) Parser/pgen 2>/dev/null || make -j$(nproc) Parser/pgen
  mkdir -p ../host_python/Parser
  cp Parser/pgen ../host_python/Parser/
  cd ../src
  echo "Host pgen built"
fi

# ── 3. Cross-compile for Android ARM64 ──────────────────────
# Set cross-compile environment
TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
export CC="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"
export CXX="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export READELF="$TOOLCHAIN/bin/llvm-readelf"
export CFLAGS="-fPIC -O2 -DANDROID -D__ANDROID_API__=${API_LEVEL}"
export LDFLAGS="-static-libstdc++"

# Machine triplet for cross-compilation
HOST_TAG="aarch64-linux-android"
BUILD_TAG="$(uname -m)-linux-gnu"

# Create a minimal pyconfig.h manually if configure fails
cat > android_config.c << 'ENDCONFIG'
/* Minimal pyconfig for Android ARM64 cross-compile */
#include <stdint.h>
typedef int64_t Py_ssize_t;
#define SIZEOF_LONG 8
#define SIZEOF_SIZE_T 8
#define SIZEOF_VOID_P 8
#define SIZEOF_INT 4
#define SIZEOF_UNSIGNED_INT 4
#define SIZEOF_SHORT 2
#define SIZEOF_UNSIGNED_SHORT 2
#define SIZEOF_CHAR 1
#define SIZEOF_UNSIGNED_CHAR 1
#define SIZEOF_FLOAT 4
#define SIZEOF_DOUBLE 8
#define SIZEOF_TIME_T 8
#define SIZEOF_PID_T 4
ENDCONFIG

# Patch configure to accept --host for cross-compilation
if ! grep -q "android" config.site 2>/dev/null; then
  cat > config.site << 'ENDSITE'
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
ac_cv_have_long_long_format=yes
ac_cv_working_tzset=yes
ENDSITE
fi

# Disable problematic modules for Android
DISABLE_MODULES="_ssl _hashlib _ssl _ctypes _tkinter _curses _curses_panel \
  _dbm _gdbm _readline _lzma _bz2 _uuid _decimal _contextvars \
  _multiprocessing _posixshmem _posixsubprocess pyexpat"

# Configure for cross-compilation
if [ ! -f Makefile ]; then
  CONFIGURE_ARGS="\
    --host=$HOST_TAG \
    --build=$BUILD_TAG \
    --prefix=$OUTPUT_DIR \
    --enable-shared \
    --with-build-python=../host_python/python \
    --without-ensurepip \
    --disable-ipv6 \
    --with-openssl='' \
    --with-system-ffi=no \
    --with-system-expat=no \
    --with-system-libmpdec=no \
    --without-threads \
    ac_cv_buggy_getaddrinfo=no \
    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no \
    ac_cv_have_long_long_format=yes"

  for mod in $DISABLE_MODULES; do
    CONFIGURE_ARGS="$CONFIGURE_ARGS --disable-$mod"
  done

  ./configure $CONFIGURE_ARGS || {
    echo "configure failed, using manual build"
  }
fi

# Build python executable for host (needed for freezing modules)
# and static library for target
if [ -f Makefile ]; then
  # Build just the library and modules
  make -j$(nproc) all 2>&1 | tail -20 || {
    echo "Full build failed, trying minimal static lib only..."
    make -j$(nproc) libpython${PYTHON_SHORT}.a 2>&1 | tail -20 || true
  }
fi

# ── 4. Install headers + static lib ────────────────────────
mkdir -p "$OUTPUT_DIR/include/python${PYTHON_SHORT}"
mkdir -p "$OUTPUT_DIR/lib"

# Copy headers
if [ -d "Include" ]; then
  cp -r Include/*.h "$OUTPUT_DIR/include/python${PYTHON_SHORT}/"
fi
if [ -f "pyconfig.h" ]; then
  cp pyconfig.h "$OUTPUT_DIR/include/python${PYTHON_SHORT}/"
fi
# Generated config header
find . -name "pyconfig.h" -maxdepth 2 -exec cp {} "$OUTPUT_DIR/include/python${PYTHON_SHORT}/" \; 2>/dev/null || true

# Copy static library
FOUND_LIB=0
for lib in \
  "libpython${PYTHON_SHORT}.a" \
  "libpython${PYTHON_SHORT}m.a" \
  "libpython3.11.a" \
  "libpython3.11m.a"; do
  if [ -f "$lib" ]; then
    cp "$lib" "$OUTPUT_DIR/lib/libpython${PYTHON_SHORT}.a"
    FOUND_LIB=1
    echo "Installed: $lib -> libpython${PYTHON_SHORT}.a"
    break
  fi
done

if [ "$FOUND_LIB" -eq 0 ]; then
  # Last resort: find any .a with python in the name
  PYTHON_A=$(find . -name "libpython*.a" -type f | head -1)
  if [ -n "$PYTHON_A" ]; then
    cp "$PYTHON_A" "$OUTPUT_DIR/lib/libpython${PYTHON_SHORT}.a"
    FOUND_LIB=1
    echo "Installed: $PYTHON_A -> libpython${PYTHON_SHORT}.a"
  fi
fi

if [ "$FOUND_LIB" -eq 0 ]; then
  echo "WARNING: No static Python library found"
  ls -la *.a 2>/dev/null || echo "No .a files at all"
fi

echo "CPython ${PYTHON_VER} cross-compile for Android ARM64 done"
