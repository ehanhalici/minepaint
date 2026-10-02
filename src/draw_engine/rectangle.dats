// src/draw_engine/rectangle.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

typedef MyPaintRectangle_struct = @{
  x= int,
  y= int,
  width= int,
  height= int
}

typedef MyPaintRectangles_struct = @{
  num_rectangles= int,
  rectangles= ptr
}

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun memcpy(dest: ptr, src: ptr, n: size_t): ptr = "mac#memcpy"

extern fun mypaint_rectangle_new(x: int, y: int, w: int, h: int): ptr = "ext#mypaint_rectangle_new"
implement mypaint_rectangle_new(x, y, w, h) = let
  val sz = sizeof<MyPaintRectangle_struct>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val r = $UN.cast{ref(MyPaintRectangle_struct)}(p)
  val () = r->x := x
  val () = r->y := y
  val () = r->width := w
  val () = r->height := h
in
  p
end

extern fun mypaint_rectangle_copy(self: ptr): ptr = "ext#mypaint_rectangle_copy"
implement mypaint_rectangle_copy(self) =
  if self = the_null_ptr then the_null_ptr
  else let
    val sz = sizeof<MyPaintRectangle_struct>
    val p = malloc(sz)
    val () = assertloc(p > the_null_ptr)
    val _ = memcpy(p, self, sz)
  in
    p
  end

extern fun mypaint_rectangle_free(self: ptr): void = "ext#mypaint_rectangle_free"
implement mypaint_rectangle_free(self) =
  if self != the_null_ptr then free(self) else ()

extern fun mypaint_rectangle_expand_to_include_point(r_ptr: ptr, x: int, y: int): void = "ext#mypaint_rectangle_expand_to_include_point"
implement mypaint_rectangle_expand_to_include_point(r_ptr, x, y) =
  if r_ptr != the_null_ptr then let
    val r = $UN.cast{ref(MyPaintRectangle_struct)}(r_ptr)
    val w = r->width
  in
    if w = 0 then let
      val () = r->width := 1
      val () = r->height := 1
      val () = r->x := x
      val () = r->y := y
    in () end
    else let
      val rx = r->x
      val () =
        if x < rx then let
          val () = r->width := r->width + (rx - x)
          val () = r->x := x
        in () end
        else if x >= rx + r->width then let
          val () = r->width := x - rx + 1
        in () end

      val ry = r->y
      val () =
        if y < ry then let
          val () = r->height := r->height + (ry - y)
          val () = r->y := y
        in () end
        else if y >= ry + r->height then let
          val () = r->height := y - ry + 1
        in () end
    in () end
  end

extern fun mypaint_rectangle_expand_to_include_rect(r_ptr: ptr, other_ptr: ptr): void = "ext#mypaint_rectangle_expand_to_include_rect"
implement mypaint_rectangle_expand_to_include_rect(r_ptr, other_ptr) =
  if (r_ptr != the_null_ptr) * (other_ptr != the_null_ptr) then let
    val other = $UN.cast{ref(MyPaintRectangle_struct)}(other_ptr)
    val () = mypaint_rectangle_expand_to_include_point(r_ptr, other->x, other->y)
    val () = mypaint_rectangle_expand_to_include_point(r_ptr, other->x + other->width - 1, other->y + other->height - 1)
  in () end
