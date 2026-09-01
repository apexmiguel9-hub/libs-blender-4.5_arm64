#!/bin/bash
set -euo pipefail
NDK_DIR="$1"; OUTPUT_DIR="$2"; BUILD_DIR="$3"; API_LEVEL="${4:-24}"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
git clone --depth 1 --branch 1.5.10 https://github.com/anholt/libepoxy.git src
cd src
# Install headers only - epoxy is loaded via system on Android
mkdir -p "$OUTPUT_DIR/include/epoxy"
cp include/epoxy/*.h "$OUTPUT_DIR/include/epoxy/"
# gl_generated.h is generated from gl.xml via python. For Android, use the system epoxy
# Just create a minimal stub library
cat > "$OUTPUT_DIR/lib/libepoxy.so" < /dev/null || true
mkdir -p "$OUTPUT_DIR/lib"
echo "Epoxy built (headers only)"
