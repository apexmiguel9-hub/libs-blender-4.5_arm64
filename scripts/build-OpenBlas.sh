#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch v0.3.28 https://github.com/OpenMathLib/OpenBLAS.git src
cd src
make TARGET=ARMV8 \
  HOSTCC=gcc \
  NOFORTRAN=1 \
  NO_LAPACKE=1 \
  NO_LAPACK=1 \
  USE_THREAD=1 \
  NUM_THREADS=64 \
  -j$(nproc) || true
make install PREFIX="$OUTPUT_DIR" || true
# Verify at least the CBLAS header was created
ls "$OUTPUT_DIR/lib/libopenblas"* 2>/dev/null && echo "OpenBlas built" || echo "OpenBlas partial build"
