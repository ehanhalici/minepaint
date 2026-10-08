// src/draw_engine/rectangle.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

typedef MinePaintRectangle = @{
  x= int,
  y= int,
  width= int,
  height= int
}

extern castfn ptr2rect(p: ptr): ref(MinePaintRectangle) = "mac#"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

// Eksen Genişletme Yardımcısı (Saf Fonksiyon, SRP, SLAP)
fn expand_axis(pos: int, span: int, pt: int): @(int, int) =
  if pt < pos then @(pt, span + (pos - pt))
  else if pt >= pos + span then @(pos, pt - pos + 1)
  else @(pos, span)

// Dikdörtgen Oluşturma
extern fun minepaint_rectangle_new(x: int, y: int, w: int, h: int): ptr = "ext#minepaint_rectangle_new"
implement minepaint_rectangle_new(x, y, w, h) = let
  val sz = sizeof<MinePaintRectangle>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val r = ptr2rect(p)
  val () = r->x := x
  val () = r->y := y
  val () = r->width := w
  val () = r->height := h
in
  p
end

// Dikdörtgen Kopyalama
extern fun minepaint_rectangle_copy(self: ptr): ptr = "ext#minepaint_rectangle_copy"
implement minepaint_rectangle_copy(self) =
  if self = the_null_ptr then the_null_ptr
  else let
    val sz = sizeof<MinePaintRectangle>
    val p = malloc(sz)
    val () = assertloc(p > the_null_ptr)
    val src = ptr2rect(self)
    val dst = ptr2rect(p)
    val () = dst->x := src->x
    val () = dst->y := src->y
    val () = dst->width := src->width
    val () = dst->height := src->height
  in
    p
  end

// Dikdörtgen Serbest Bırakma
extern fun minepaint_rectangle_free(self: ptr): void = "ext#minepaint_rectangle_free"
implement minepaint_rectangle_free(self) =
  if self != the_null_ptr then free(self) else ()

// Nokta Kapsayacak Şekilde Genişletme (Sıfır Unsafe, Guard Clause)
extern fun minepaint_rectangle_expand_to_include_point(
  r: ptr, x: int, y: int
): void = "ext#minepaint_rectangle_expand_to_include_point"
implement minepaint_rectangle_expand_to_include_point(r_p, x, y) =
  if r_p != the_null_ptr then let
    val r = ptr2rect(r_p)
  in
    if r->width = 0 then {
      val () = r->x := x
      val () = r->y := y
      val () = r->width := 1
      val () = r->height := 1
    } else {
      val @(nx, nw) = expand_axis(r->x, r->width, x)
      val @(ny, nh) = expand_axis(r->y, r->height, y)
      val () = r->x := nx
      val () = r->width := nw
      val () = r->y := ny
      val () = r->height := nh
    }
  end

// Başka Dikdörtgeni Kapsayacak Şekilde Genişletme
extern fun minepaint_rectangle_expand_to_include_rect(
  r: ptr, other: ptr
): void = "ext#minepaint_rectangle_expand_to_include_rect"
implement minepaint_rectangle_expand_to_include_rect(r_p, other_p) =
  if (r_p != the_null_ptr) && (other_p != the_null_ptr) then let
    val other = ptr2rect(other_p)
    val () = minepaint_rectangle_expand_to_include_point(r_p, other->x, other->y)
    val () = minepaint_rectangle_expand_to_include_point(
      r_p, other->x + other->width - 1, other->y + other->height - 1
    )
  in () end
