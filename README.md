# libs-blender-4.5_arm64

Precompiled third-party libraries for Blender 4.5 LTS Android ARM64.

Built with NDK r26d (C++20, Clang 17).

## Libraries

| Library | Version | Type |
|---------|---------|------|
| zlib | 1.3.1 | .so |
| zstd | 1.5.6 | .so |
| BZip2 | 1.0.8 | .so |
| Expat | 2.6.4 | .so |
| libjpeg-turbo | 3.1.0 | .a |
| libpng | 1.6.44 | .so |
| libtiff | 4.6.0 | .so |
| sqlite | 3.45.1 | .so |
| libzip | 1.11.1 | .so |
| FreeType | 2.13.3 | .so |
| Harfbuzz | 8.5.0 | .so |
| Brotli | 1.1.0 | .so |
| OpenColorIO | 2.3.2 | .so |
| OpenEXR | 3.2.4 | .so |
| OpenImageIO | 2.5.16 | .so |
| WebP | 1.4.0 | .so |
| OpenAL | 1.23.1 | .so |
| FFmpeg | 7.0.2 | .so |
| libsndfile | 1.2.2 | .so |
| GMP | 6.3.0 | .so |
| FFTW | 3.3.10 | .so |
| OpenBLAS | 0.3.28 | .a |
| OpenSubdiv | 3.6.0 | .so |
| oneTBB | 2021.13.0 | .so |
| Embree | 4.3.3 | .so |
| OpenVDB | 11.0.0 | .so |
| Alembic | 1.8.5 | .so |
| OpenCOLLADA | latest | .so |
| PugiXML | 1.14 | .a |
| libxml2 | 2.13.5 | .so |
| yaml-cpp | 0.8.0 | .a |
| Potrace | 1.16.2 | .so |
| Python | 3.12.7 | .so |
| SDL2 | 2.30.10 | .so |
| libepoxy | 1.5.10 | .so |
| OpenPGL | 0.6.0 | .so |
| OIDN | 2.3.1 | .so |
| Manifold | 3.0.1 | .so |
| MaterialX | 1.39.0 | .so |
| libharu | 2.4.4 | .so |
| OpenJPEG | 2.5.3 | .so |
| Fribidi | 1.0.15 | .so |
| jemalloc | 5.3.0 | .so |
| ICU | 75.1 | .so |
| Boost | 1.84.0 | .so |
| ShaderC | latest | .so |
| c-blosc | 1.21.6 | .so |
| Imath | 3.1.12 | .so |

## Structure

Each library follows this layout:
```
LibName/
├── include/    (headers)
└── lib/        (.so or .a files)
```

## Build

Each library is compiled individually via GitHub Actions:
```bash
gh workflow run build-libs.yml --ref main
```

Or build locally:
```bash
./scripts/build-zlib.sh /path/to/ndk /path/to/output /path/to/build 24
```
