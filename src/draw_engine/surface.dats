// src/draw_engine/surface.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "./rectangle.dats"
staload "draw_engine/surface_box.sats"
#include "./minepaint_types.hats"
#include "./engine_safe.hats"

typedef MinePaintSurface_struct = MinePaintSurface

extern fun view_mpsurf(s: MpSurface): ref(MinePaintSurface_struct) = "mac#mp_id_ptr"
extern fun load_destroy(p: ptr): MinePaintSurfaceDestroyFunction = "mac#mp_id_ptr"
extern fun load_draw_dab(p: ptr): MinePaintSurfaceDrawDabFunction = "mac#mp_id_ptr"
extern fun load_get_color(p: ptr): MinePaintSurfaceGetColorFunction = "mac#mp_id_ptr"
extern fun load_begin(p: ptr): MinePaintSurfaceBeginAtomicFunction = "mac#mp_id_ptr"
extern fun load_end(p: ptr): MinePaintSurfaceEndAtomicFunction = "mac#mp_id_ptr"
extern fun load_png(p: ptr): MinePaintSurfaceSavePngFunction = "mac#mp_id_ptr"

fn call_surface_destroy(f: ptr, self: MpSurface): void =
  load_destroy(f)(self)

fn call_surface_draw_dab(
  f: ptr, self: MpSurface,
  x: float, y: float, radius: float, r: float, g: float, b: float,
  opaque: float, hardness: float, softness: float, alpha_eraser: float,
  aspect_ratio: float, angle: float, lock_alpha: float,
  colorize: float, posterize: float, posterize_num: float, paint: float
): int =
  load_draw_dab(f)(
    self, x, y, radius, r, g, b,
    opaque, hardness, softness, alpha_eraser,
    aspect_ratio, angle, lock_alpha,
    colorize, posterize, posterize_num, paint
  )

fn call_surface_get_color(
  f: ptr, self: MpSurface,
  x: float, y: float, radius: float,
  r: ptr, g: ptr, b: ptr, a: ptr, paint: float
): void =
  load_get_color(f)(self, x, y, radius, r, g, b, a, paint)

fn call_surface_begin_atomic(f: ptr, self: MpSurface): void =
  load_begin(f)(self)

fn call_surface_end_atomic(f: ptr, self: MpSurface, roi: ptr): void =
  load_end(f)(self, roi)

fn call_surface_save_png(f: ptr, self: MpSurface, path: string, x: int, y: int, w: int, h: int): void =
  load_png(f)(self, path, x, y, w, h)

extern fun minepaint_surface_init(self: MpSurface): void = "ext#minepaint_surface_init"
implement minepaint_surface_init(self) =
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val () = s->refcount := 1
  in () end

extern fun minepaint_surface_ref(self: MpSurface): void = "ext#minepaint_surface_ref"
implement minepaint_surface_ref(self) =
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val () = s->refcount := s->refcount + 1
  in () end

extern fun minepaint_surface_unref(self: MpSurface): void = "ext#minepaint_surface_unref"
implement minepaint_surface_unref(self) =
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val rc = s->refcount - 1
    val () = s->refcount := rc
    val () =
      if rc <= 0 then let
        val d = s->destroy
        val () = if d != the_null_ptr then call_surface_destroy(d, self)
      in () end
  in () end

extern fun minepaint_surface_draw_dab(
    self: MpSurface,
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
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
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
    self: MpSurface,
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
    self: MpSurface,
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
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val f = s->get_color
  in
    if f != the_null_ptr then
      call_surface_get_color(
        f, self, x, y, radius,
        addr@(color_r),
        addr@(color_g),
        addr@(color_b),
        addr@(color_a),
        paint
      )
    else ()
  end
  else ()
end

extern fun minepaint_surface_get_alpha(self: MpSurface, x: float, y: float, radius: float): float = "ext#minepaint_surface_get_alpha"
implement minepaint_surface_get_alpha(self, x, y, radius) = let
  var r: float
  var g: float
  var b: float
  var a: float
  val () = minepaint_surface_get_color(self, x, y, radius, r, g, b, a, 1.0f)
in
  a
end

extern fun minepaint_surface_begin_atomic(self: MpSurface): void = "ext#minepaint_surface_begin_atomic"
implement minepaint_surface_begin_atomic(self) =
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val f = s->begin_atomic
  in
    if f != the_null_ptr then call_surface_begin_atomic(f, self)
  end

extern fun minepaint_surface_end_atomic(self: MpSurface, roi: ptr): void = "ext#minepaint_surface_end_atomic"
implement minepaint_surface_end_atomic(self, roi) =
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val f = s->end_atomic
  in
    if f != the_null_ptr then call_surface_end_atomic(f, self, roi)
  end

extern fun minepaint_surface_save_png(self: MpSurface, path: string, x: int, y: int, w: int, h: int): void = "ext#minepaint_surface_save_png"
implement minepaint_surface_save_png(self, path, x, y, w, h) =
  if mp_surface_is_null(self) = 0 then let
    val s = view_mpsurf(self)
    val f = s->save_png
  in
    if f != the_null_ptr then call_surface_save_png(f, self, path, x, y, w, h)
  end
