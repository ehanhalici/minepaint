// src/draw_engine/surface.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "./rectangle.dats"
#include "./minepaint_types.hats"
#include "./engine_safe.hats"

typedef MinePaintSurface_struct = MinePaintSurface

extern castfn ptr2surface(p: ptr): ref(MinePaintSurface_struct) = "mac#"
extern castfn addr2ptr(p: ptr): ptr = "mac#"

fn call_surface_destroy(f: ptr, self: ptr): void =
  ptr2fn{MinePaintSurfaceDestroyFunction}(f)(self)

fn call_surface_draw_dab(
  f: ptr, self: ptr,
  x: float, y: float, radius: float, r: float, g: float, b: float,
  opaque: float, hardness: float, softness: float, alpha_eraser: float,
  aspect_ratio: float, angle: float, lock_alpha: float,
  colorize: float, posterize: float, posterize_num: float, paint: float
): int =
  ptr2fn{MinePaintSurfaceDrawDabFunction}(f)(
    self, x, y, radius, r, g, b,
    opaque, hardness, softness, alpha_eraser,
    aspect_ratio, angle, lock_alpha,
    colorize, posterize, posterize_num, paint
  )

fn call_surface_get_color(
  f: ptr, self: ptr,
  x: float, y: float, radius: float,
  r: ptr, g: ptr, b: ptr, a: ptr, paint: float
): void =
  ptr2fn{MinePaintSurfaceGetColorFunction}(f)(self, x, y, radius, r, g, b, a, paint)

fn call_surface_begin_atomic(f: ptr, self: ptr): void =
  ptr2fn{MinePaintSurfaceBeginAtomicFunction}(f)(self)

fn call_surface_end_atomic(f: ptr, self: ptr, roi: ptr): void =
  ptr2fn{MinePaintSurfaceEndAtomicFunction}(f)(self, roi)

fn call_surface_save_png(f: ptr, self: ptr, path: string, x: int, y: int, w: int, h: int): void =
  ptr2fn{MinePaintSurfaceSavePngFunction}(f)(self, path, x, y, w, h)

extern fun minepaint_surface_init(self: ptr): void = "ext#minepaint_surface_init"
implement minepaint_surface_init(self) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val () = s->refcount := 1
  in () end

extern fun minepaint_surface_ref(self: ptr): void = "ext#minepaint_surface_ref"
implement minepaint_surface_ref(self) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val () = s->refcount := s->refcount + 1
  in () end

extern fun minepaint_surface_unref(self: ptr): void = "ext#minepaint_surface_unref"
implement minepaint_surface_unref(self) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val rc = s->refcount - 1
    val () = s->refcount := rc
    val () =
      if rc <= 0 then let
        val d = s->destroy
        val () = if d != the_null_ptr then call_surface_destroy(d, self)
      in () end
  in () end

extern fun minepaint_surface_draw_dab(
    self: ptr,
    x: float, y: float,
    radius: float,
    r: float, g: float, b: float,
    opaque: float, hardness: float, softness: float,
    alpha_eraser: float,
    aspect_ratio: float, angle: float,
    lock_alpha: float,
    colorize: float,
    posterize: float,
    posterize_num: float,
    paint: float
): int = "ext#minepaint_surface_draw_dab"

implement minepaint_surface_draw_dab(
    self, x, y, radius, r, g, b,
    opaque, hardness, softness, alpha_eraser,
    aspect_ratio, angle, lock_alpha,
    colorize, posterize, posterize_num, paint
) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val f = s->draw_dab
  in
    if f != the_null_ptr then
      call_surface_draw_dab(
        f, self, x, y, radius, r, g, b,
        opaque, hardness, softness, alpha_eraser,
        aspect_ratio, angle, lock_alpha,
        colorize, posterize, posterize_num, paint
      )
    else 0
  end
  else 0

extern fun draw_engine_surface_draw_dab(
    self: ptr,
    x: float, y: float,
    radius: float,
    r: float, g: float, b: float,
    opaque: float, hardness: float, softness: float,
    alpha_eraser: float,
    aspect_ratio: float, angle: float,
    lock_alpha: float,
    colorize: float,
    posterize: float,
    posterize_num: float,
    paint: float
): int = "ext#draw_engine_surface_draw_dab"

implement draw_engine_surface_draw_dab(
    self, x, y, radius, r, g, b,
    opaque, hardness, softness, alpha_eraser,
    aspect_ratio, angle, lock_alpha,
    colorize, posterize, posterize_num, paint
) =
  minepaint_surface_draw_dab(
    self, x, y, radius, r, g, b,
    opaque, hardness, softness, alpha_eraser,
    aspect_ratio, angle, lock_alpha,
    colorize, posterize, posterize_num, paint
  )

extern fun minepaint_surface_get_color(
    self: ptr,
    x: float, y: float,
    radius: float,
    color_r: &float? >> float,
    color_g: &float? >> float,
    color_b: &float? >> float,
    color_a: &float? >> float,
    paint: float
): void = "ext#minepaint_surface_get_color"

implement minepaint_surface_get_color(self, x, y, radius, color_r, color_g, color_b, color_a, paint) = let
  val () = color_r := 0.0f
  val () = color_g := 0.0f
  val () = color_b := 0.0f
  val () = color_a := 0.0f
in
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val f = s->get_color
  in
    if f != the_null_ptr then
      call_surface_get_color(
        f, self, x, y, radius,
        addr2ptr(addr@(color_r)),
        addr2ptr(addr@(color_g)),
        addr2ptr(addr@(color_b)),
        addr2ptr(addr@(color_a)),
        paint
      )
    else ()
  end
  else ()
end

extern fun minepaint_surface_get_alpha(self: ptr, x: float, y: float, radius: float): float = "ext#minepaint_surface_get_alpha"
implement minepaint_surface_get_alpha(self, x, y, radius) = let
  var r: float
  var g: float
  var b: float
  var a: float
  val () = minepaint_surface_get_color(self, x, y, radius, r, g, b, a, 1.0f)
in
  a
end

extern fun minepaint_surface_begin_atomic(self: ptr): void = "ext#minepaint_surface_begin_atomic"
implement minepaint_surface_begin_atomic(self) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val f = s->begin_atomic
  in
    if f != the_null_ptr then call_surface_begin_atomic(f, self)
  end

extern fun minepaint_surface_end_atomic(self: ptr, roi: ptr): void = "ext#minepaint_surface_end_atomic"
implement minepaint_surface_end_atomic(self, roi) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val f = s->end_atomic
  in
    if f != the_null_ptr then call_surface_end_atomic(f, self, roi)
  end

extern fun minepaint_surface_save_png(self: ptr, path: string, x: int, y: int, w: int, h: int): void = "ext#minepaint_surface_save_png"
implement minepaint_surface_save_png(self, path, x, y, w, h) =
  if self != the_null_ptr then let
    val s = ptr2surface(self)
    val f = s->save_png
  in
    if f != the_null_ptr then call_surface_save_png(f, self, path, x, y, w, h)
  end
