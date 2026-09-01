#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch n7.0.2 https://github.com/FFmpeg/FFmpeg.git src
cd src
TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
TARGET=aarch64-linux-android
./configure \
  --prefix="$OUTPUT_DIR" \
  --target-os=android --arch=aarch64 --cpu=armv8-a \
  --cc="$TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang" \
  --sysroot="$TOOLCHAIN/sysroot" \
  --enable-shared --disable-static \
  --enable-cross-compile --enable-small \
  --disable-programs --disable-doc \
  --disable-everything \
  --enable-decoder=pcm_s16le --enable-decoder=pcm_f32le \
  --enable-demuxer=wav \
  --enable-protocol=file \
  --disable-avdevice --disable-swresample --disable-swscale \
  --disable-avfilter --disable-postproc \
  --extra-cflags="-O2 -fPIC" --extra-ldflags="-fPIC"
make -j$(nproc)
make install-libs install-headers
echo "ffmpeg built"
