// src/draw_engine/rectangle.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./rectangle_pure.hats"
staload "draw_engine/rect_box.sats"

// --- Sınır (C ABI pointer katmanı) ---
// Dış API ptr üzerinden çalışır; hesap rectangle_pure.hats içindedir.

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun rect_get_x(p: ptr): int = "mac#mp_rect_get_x"
extern fun rect_get_y(p: ptr): int = "mac#mp_rect_get_y"
extern fun rect_get_w(p: ptr): int = "mac#mp_rect_get_w"
extern fun rect_get_h(p: ptr): int = "mac#mp_rect_get_h"
extern fun rect_put(p: ptr, x: int, y: int, w: int, h: int): void = "mac#mp_rect_set"

fn rect_load(r: MpRect): MinePaintRectangle = let
  val p = rect_ptr(r)
in
  @{ x= rect_get_x(p), y= rect_get_y(p), width= rect_get_w(p), height= rect_get_h(p) }
end

fn rect_store(r: MpRect, v: MinePaintRectangle): void =
  rect_put(rect_ptr(r), v.x, v.y, v.width, v.height)

extern fun minepaint_rectangle_new(x: int, y: int, w: int, h: int): MpRect = "ext#minepaint_rectangle_new"
implement minepaint_rectangle_new(x, y, w, h) = let
  val p = malloc(sizeof<MinePaintRectangle>)
  val () = assertloc(p > the_null_ptr)
  val r = rect_of(p)
  val () = rect_store(r, @{ x= x, y= y, width= w, height= h })
in
  r
end

extern fun minepaint_rectangle_copy(self: MpRect): MpRect = "ext#minepaint_rectangle_copy"
implement minepaint_rectangle_copy(self) =
  if rect_is_null(self) != 0 then rect_none()
  else let
    val p = malloc(sizeof<MinePaintRectangle>)
    val () = assertloc(p > the_null_ptr)
    val r = rect_of(p)
    val () = rect_store(r, rect_load(self))
  in
    r
  end

extern fun minepaint_rectangle_free(self: MpRect): void = "ext#minepaint_rectangle_free"
implement minepaint_rectangle_free(self) =
  if rect_is_null(self) = 0 then free(rect_ptr(self)) else ()

extern fun minepaint_rectangle_expand_to_include_point(
  r: MpRect, x: int, y: int
): void = "ext#minepaint_rectangle_expand_to_include_point"
implement minepaint_rectangle_expand_to_include_point(r_p, x, y) =
  if rect_is_null(r_p) = 0 then
    rect_store(r_p, rect_expand_point(rect_load(r_p), x, y))
  else ()

extern fun minepaint_rectangle_expand_to_include_rect(
  r: MpRect, other: MpRect
): void = "ext#minepaint_rectangle_expand_to_include_rect"
implement minepaint_rectangle_expand_to_include_rect(r_p, other_p) =
  if (rect_is_null(r_p) = 0) && (rect_is_null(other_p) = 0) then
    rect_store(r_p, rect_expand_rect(rect_load(r_p), rect_load(other_p)))
  else ()

extern fun minepaint_rectangle_clear(r_p: MpRect): void = "ext#minepaint_rectangle_clear"
implement minepaint_rectangle_clear(r_p) =
  if rect_is_null(r_p) = 0 then
    rect_store(r_p, @{ x= 0, y= 0, width= 0, height= 0 })
  else ()

extern fun minepaint_rectangle_expand_to_include_value(
  r_p: MpRect, src: MinePaintRectangle
): void = "ext#minepaint_rectangle_expand_to_include_value"
implement minepaint_rectangle_expand_to_include_value(r_p, src) =
  if rect_is_null(r_p) = 0 then
    rect_store(r_p, rect_expand_rect(rect_load(r_p), src))
  else ()
