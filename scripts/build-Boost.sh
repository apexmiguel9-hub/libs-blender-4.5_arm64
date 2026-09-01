#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch boost-1.84.0 https://github.com/boostorg/boost.git src
cd src
./bootstrap.sh 2>&1
TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
TARGET=aarch64-linux-android
cat > user-config.jam << JAM
using clang : android : $TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang++ ;
JAM
echo "user-config.jam created"
cat user-config.jam
./b2 install \
  --prefix="$OUTPUT_DIR" \
  --with-iostreams --with-locale --with-filesystem \
  --with-thread --with-system --with-regex --with-date_time \
  --with-log --with-serialization --with-program_options \
  link=shared variant=release threading=multi \
  toolset=clang --ignore-site-config \
  -sNO_BZIP2=1 -sNO_ZLIB=1 -sNO_LZMA=1 -sNO_ZSTD=1 -sNO_PYTHON=1 2>&1
echo "Boost built"
