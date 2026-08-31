#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v0.3.28 https://github.com/OpenMathLib/OpenBLAS.git src
cd src
TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
make TARGET=ARMV8 \
  CC="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang" \
  HOSTCC=gcc \
  NOFORTRAN=1 \
  NO_LAPACKE=1 \
  USE_THREAD=1 \
  NUM_THREADS=64 \
  -j$(nproc)
make install PREFIX="$OUTPUT_DIR"
echo "OpenBlas built"
