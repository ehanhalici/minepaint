# MinePaint

A lightweight, minimal painting application and MyPaint engine clone written in **pure ATS2 (Applied Type System / Postiats)**.

MinePaint features a native ATS2 reimplementation of the MyPaint brush drawing engine, custom OpenGL hardware-accelerated canvas, and an ultra-minimal, dependency-free GUI system running directly on X11 and OpenGL.

## Features

- **Pure ATS2 Brush Engine**: Complete native ATS2 implementation of the MyPaint drawing engine (`src/draw_engine/`), including tiled surfaces, dab blenders, stroke dynamics, symmetry, color conversion, and brush settings metadata.
- **Hardware-Accelerated Canvas**: OpenGL tile-based rendering with smooth panning, zooming, and brush dabbing.
- **Zero Heavy GUI Dependencies**: No GTK, Qt, or FLTK required. The UI (sliders, color picker, vector stroke font rasterizer) is written in native ATS2 directly over X11 and OpenGL.
- **Ultra Lightweight**: Minimal binary footprint (~1.4 MB) with minimal dynamic library dependencies (`libX11`, `libGL`, `libm`, `libpthread`).

## Demo

![example](https://github.com/ehanhalici/minepaint/blob/master/minePaint.png)

## Architecture

- **`src/draw_engine/`**: Pure ATS2 drawing and brush engine:
  - `brush.dats` & `brushmodes.dats`: Brush state dynamics, dab calculation, and blending modes.
  - `surface.dats` & `tiled_surface.dats`: Tiled surface management and tile request caching.
  - `brush_settings.dats` & `brushsettings_gen.hats`: Brush parameter and input metadata tables.
  - `mypaint_types.hats`: Core type definitions and data structures.
  - `matrix.dats`, `symmetry.dats`, `helpers.dats`, `rng.dats`: Linear algebra, symmetry reflection, PRNG, and color spaces.
- **`src/ui/`**: Pure ATS2 user interface:
  - `widgets.dats`: Sliders, HSV color wheel, palette swatches, and custom vector font renderer.
  - `window.dats`: X11 window lifecycle and input event dispatching.
  - `ui.dats`: UI layout and interaction wiring.
- **`src/MyCanvas.dats` & `src/MyGLSurface.dats`**: Canvas controller and OpenGL texture-backed surface.
- **`src/Layer.dats`**: Layer management and tile storage.

## Building

### Using Nix (Recommended)

To enter the reproducible build environment:

```bash
nix-shell --pure
```

Inside the shell, build with CMake:

```bash
cmake -B build -S .
cmake --build build
```

### Manual Build

Prerequisites:
- [ATS2 (Postiats)](http://www.ats-lang.org/) (`patsopt`)
- CMake (>= 3.16)
- C Compiler (GCC or Clang)
- X11 development headers (`libX11`, `libXext`)
- OpenGL development headers (`libGL`)

Ensure `PATSHOME` points to your ATS2 installation directory, then run:

```bash
cmake -B build -S .
cmake --build build
```

The resulting executable will be created at:
```bash
./build/minepaint
```
