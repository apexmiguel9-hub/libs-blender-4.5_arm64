#!/bin/bash
# Build cpython (Python) for Android ARM64
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v3.12.7 https://github.com/python/cpython.git src
cd src
TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
TARGET=aarch64-linux-android

# Python cross-compilation for Android requires special handling
./configure \
  --host="$TARGET" \
  --build=$(uname -m)-linux-gnu \
  --prefix="$OUTPUT_DIR" \
  --enable-shared --disable-static \
  --disable-test-modules \
  --with-build-python=python3 \
  CC="$TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang" \
  CXX="$TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang++" \
  CFLAGS="--sysroot=$TOOLCHAIN/sysroot -O2 -fPIC" \
  CXXFLAGS="--sysroot=$TOOLCHAIN/sysroot -O2 -fPIC" \
  LDFLAGS="--sysroot=$TOOLCHAIN/sysroot" \
  --disable-ipv6 \
  --without-ensurepip
make -j$(nproc)
make install
echo "cpython built"
