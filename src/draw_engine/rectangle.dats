// src/draw_engine/rectangle.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./rectangle_pure.hats"

// --- Sınır (C ABI pointer katmanı) ---
// Dış API ptr üzerinden çalışır; hesap rectangle_pure.hats içindedir.

extern castfn ptr2rect(p: ptr): ref(MinePaintRectangle) = "mac#"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

fn rect_load(p: ptr): MinePaintRectangle = let
  val r = ptr2rect(p)
in
  @{ x= r->x, y= r->y, width= r->width, height= r->height }
end

fn rect_store(p: ptr, v: MinePaintRectangle): void = let
  val r = ptr2rect(p)
  val () = r->x := v.x
  val () = r->y := v.y
  val () = r->width := v.width
  val () = r->height := v.height
in () end

// Dikdörtgen Oluşturma
extern fun minepaint_rectangle_new(x: int, y: int, w: int, h: int): ptr = "ext#minepaint_rectangle_new"
implement minepaint_rectangle_new(x, y, w, h) = let
  val p = malloc(sizeof<MinePaintRectangle>)
  val () = assertloc(p > the_null_ptr)
  val () = rect_store(p, @{ x= x, y= y, width= w, height= h })
in
  p
end

// Dikdörtgen Kopyalama
extern fun minepaint_rectangle_copy(self: ptr): ptr = "ext#minepaint_rectangle_copy"
implement minepaint_rectangle_copy(self) =
  if self = the_null_ptr then the_null_ptr
  else let
    val p = malloc(sizeof<MinePaintRectangle>)
    val () = assertloc(p > the_null_ptr)
    val () = rect_store(p, rect_load(self))
  in
    p
  end

// Dikdörtgen Serbest Bırakma
extern fun minepaint_rectangle_free(self: ptr): void = "ext#minepaint_rectangle_free"
implement minepaint_rectangle_free(self) =
  if self != the_null_ptr then free(self) else ()

// Nokta Kapsayacak Şekilde Genişletme (in-place)
extern fun minepaint_rectangle_expand_to_include_point(
  r: ptr, x: int, y: int
): void = "ext#minepaint_rectangle_expand_to_include_point"
implement minepaint_rectangle_expand_to_include_point(r_p, x, y) =
  if r_p != the_null_ptr then
    rect_store(r_p, rect_expand_point(rect_load(r_p), x, y))
  else ()

// Başka Dikdörtgeni Kapsayacak Şekilde Genişletme (in-place)
extern fun minepaint_rectangle_expand_to_include_rect(
  r: ptr, other: ptr
): void = "ext#minepaint_rectangle_expand_to_include_rect"
implement minepaint_rectangle_expand_to_include_rect(r_p, other_p) =
  if (r_p != the_null_ptr) && (other_p != the_null_ptr) then
    rect_store(r_p, rect_expand_rect(rect_load(r_p), rect_load(other_p)))
  else ()

extern fun minepaint_rectangle_clear(r_p: ptr): void = "ext#minepaint_rectangle_clear"
implement minepaint_rectangle_clear(r_p) =
  if r_p != the_null_ptr then
    rect_store(r_p, @{ x= 0, y= 0, width= 0, height= 0 })
  else ()

extern fun minepaint_rectangle_expand_to_include_value(
  r_p: ptr, src: MinePaintRectangle
): void = "ext#minepaint_rectangle_expand_to_include_value"
implement minepaint_rectangle_expand_to_include_value(r_p, src) =
  if r_p != the_null_ptr then
    rect_store(r_p, rect_expand_rect(rect_load(r_p), src))
  else ()
