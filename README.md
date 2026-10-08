# MinePaint

A lightweight, minimal painting application and MyPaint engine clone written in **pure ATS2 (Applied Type System / Postiats)**.

MinePaint features a native ATS2 reimplementation of the MyPaint brush drawing engine, custom OpenGL hardware-accelerated canvas, and an ultra-minimal, dependency-free GUI system running directly on X11 and OpenGL.

## Features

- **Pure ATS2 Brush Engine**: Complete native ATS2 implementation of the MyPaint drawing engine (`src/draw_engine/`), including tiled surfaces, dab blenders, stroke dynamics, symmetry, color conversion, and brush settings metadata.
- **Hardware-Accelerated Canvas**: OpenGL tile-based rendering with $O(1)$ 2D spatial hash-table tile lookup, and smooth pan/zoom.
- **4 Built-in Brush Profiles**: Instant preset selection in the sidebar (`PEN` - Pencil, `INK` - Ink/Pen, `AIR` - Airbrush, `MRK` - Marker).
- **Collapsible Sidebar UI**: Top `>>` arrow collapses the sidebar to expand the drawing canvas to full screen. Hovering the cursor at the far right edge reveals a sleek floating `<<` toggle with a 1-second auto-fade timeout to restore the menu.
- **Zero Heavy GUI Dependencies**: No GTK, Qt, or FLTK required. The UI (sliders, color picker, vector stroke font rasterizer, collapsible controls) and X11 event loop are written in native ATS2 directly over X11 and OpenGL.
- **Ultra Lightweight**: Minimal binary footprint (~1.4 MB) with minimal dynamic library dependencies (`libX11`, `libGL`, `libm`, `libpthread`).

## Demo

![example](https://github.com/ehanhalici/minepaint/blob/master/minePaint.png)

## Architecture

- **`src/draw_engine/`**: Pure ATS2 drawing and brush engine:
  - `brush.dats` & `brushmodes.dats`: Brush state dynamics, dab calculation, and blending modes.
  - `surface.dats` & `tiled_surface.dats`: Tiled surface management and tile request caching.
  - `brush_settings.dats` & `brushsettings_gen.hats`: Brush parameter and input metadata tables.
  - `minepaint_types.hats`: Core type definitions and data structures.
  - `matrix.dats`, `symmetry.dats`, `helpers.dats`, `rng.dats`: Linear algebra, symmetry reflection, PRNG, and color spaces.
- **`src/ui/`**: Pure ATS2 user interface and window management:
  - `widgets.dats`: Sliders, HSV color wheel, palette swatches, 4 brush presets (`PEN`, `INK`, `AIR`, `MRK`), collapsible sidebar controls, and vector font rasterizer.
  - `window.dats`: Native ATS2 X11 window lifecycle, event dispatching, and dynamic canvas resizing.
  - `ui.dats`: UI layout and initialization.
- **`src/MyCanvas.dats` & `src/MyGLSurface.dats`**: Canvas controller and OpenGL texture-backed surface.
- **`src/Layer.dats`**: Layer management with $O(1)$ 2D hash table tile storage.

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
sh compile.sh -r
```

The resulting executable will be created at:
```bash
./build/minepaint
```

### Verification

Before committing, run the static type check and build gate:

```bash
bash scripts/verify.sh            # patsopt -tc on every .sats/.dats, then CMake build
bash scripts/verify.sh --no-build # type check only
```
