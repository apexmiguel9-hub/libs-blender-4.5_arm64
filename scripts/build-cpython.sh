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
  echo "=== Downloading Python ${PYTHON_VER} ==="
  wget -q "https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tar.xz"
  tar xf "Python-${PYTHON_VER}.tar.xz"
  mv "Python-${PYTHON_VER}" src
fi

# ── 2. Build HOST python (for pgen + build tools) ──────────
if [ ! -f host_python/bin/python3 ]; then
  echo "=== Building host Python ==="
  mkdir -p host_build && cd host_build
  ../src/configure --prefix="$PWD/../host_python" \
    --without-ensurepip --quiet 2>&1 | tail -5
  make -j$(nproc) 2>&1 | tail -10
  make install 2>&1 | tail -5
  cd "$BUILD_DIR"
  echo "Host Python installed"
  ls host_python/bin/python3
fi

HOST_PYTHON="$PWD/host_python/bin/python3"

# ── 3. Cross-compile for Android ARM64 ──────────────────────
echo "=== Cross-compiling for Android ARM64 ==="
cd src

TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
HOST_TAG="aarch64-linux-android"
BUILD_TAG="$(uname -m)-linux-gnu"

export CC="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"
export CXX="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export CFLAGS="-fPIC -O2 -DANDROID -D__ANDROID_API__=${API_LEVEL}"
export LDFLAGS=""

# Create config.site for cross-compilation
cat > config.site << 'ENDSITE'
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
ac_cv_have_long_long_format=yes
ac_cv_working_tzset=yes
ac_cv_little_endian_double=yes
ENDSITE

# Configure for cross-compilation
if [ ! -f Makefile ]; then
  ./configure \
    --host=$HOST_TAG \
    --build=$BUILD_TAG \
    --prefix="$OUTPUT_DIR" \
    --enable-shared \
    --with-build-python="$HOST_PYTHON" \
    --without-ensurepip \
    --disable-ipv6 \
    --with-system-ffi=no \
    --with-system-expat=no \
    --with-system-libmpdec=no \
    --disable-ssl \
    --disable-hashlib \
    --disable-bz2 \
    --disable-lzma \
    --disable-readline \
    --disable-curses \
    --disable-db4-db5 \
    --disable-gdbm \
    --disable-uuid \
    --disable-decimal \
    --disable-ctypes \
    --disable-tk \
    --disable-xmlparse \
    --disable-pyexpat \
    --disable-multiprocessing \
    ac_cv_buggy_getaddrinfo=no \
    2>&1 | tail -20
fi

# Build just the static library
echo "=== Building libpython${PYTHON_SHORT}.a ==="
make -j$(nproc) libpython${PYTHON_SHORT}.a 2>&1 | tail -20

# ── 4. Install headers + static lib ────────────────────────
echo "=== Installing ==="
mkdir -p "$OUTPUT_DIR/include/python${PYTHON_SHORT}"
mkdir -p "$OUTPUT_DIR/lib"

# Copy generated pyconfig.h
find . -name "pyconfig.h" -maxdepth 1 -exec cp {} "$OUTPUT_DIR/include/python${PYTHON_SHORT}/" \;

# Copy standard headers
cp -r Include/*.h "$OUTPUT_DIR/include/python${PYTHON_SHORT}/" 2>/dev/null || true

# Copy internal headers
for dir in Include/internal Include/cpython Include/internal/cpython; do
  if [ -d "$dir" ]; then
    mkdir -p "$OUTPUT_DIR/include/python${PYTHON_SHORT}/$(basename $dir)"
    cp -r "$dir"/* "$OUTPUT_DIR/include/python${PYTHON_SHORT}/$(basename $dir)/" 2>/dev/null || true
  fi
done

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
  PYTHON_A=$(find . -name "libpython*.a" -type f | head -1)
  if [ -n "$PYTHON_A" ]; then
    cp "$PYTHON_A" "$OUTPUT_DIR/lib/libpython${PYTHON_SHORT}.a"
    FOUND_LIB=1
    echo "Installed: $PYTHON_A"
  fi
fi

if [ "$FOUND_LIB" -eq 0 ]; then
  echo "ERROR: No static Python library found!"
  ls -la *.a 2>/dev/null || echo "No .a files"
  exit 1
fi

echo "=== CPython ${PYTHON_VER} for Android ARM64 DONE ==="
echo "  lib: $OUTPUT_DIR/lib/libpython${PYTHON_SHORT}.a"
ls -lh "$OUTPUT_DIR/lib/libpython${PYTHON_SHORT}.a"
echo "  headers: $OUTPUT_DIR/include/python${PYTHON_SHORT}/"
ls "$OUTPUT_DIR/include/python${PYTHON_SHORT}/" | wc -l
echo "  header files"
