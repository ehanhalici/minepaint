// Bounding-box buffers as integer handles. Each buffer is a fixed
// run of rectangles. main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./rectangle_pure.hats"

#define BBOX_BUFS 32
#define BBOX_LEN 1024
#define BBOX_SLOTS 32768

val g_zero = @{ x= 0, y= 0, width= 0, height= 0 } : MinePaintRectangle
val g_alive = arrayref_make_elt<bool>(i2sz(BBOX_BUFS), false)
val g_len = arrayref_make_elt<int>(i2sz(BBOX_BUFS), 0)
val g_rect = arrayref_make_elt<MinePaintRectangle>(i2sz(BBOX_SLOTS), g_zero)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(BBOX_BUFS), 0)

fn slot_of(h: int, i: int): int = h * BBOX_LEN + i

fn alloc_buf(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < BBOX_BUFS) then g_free[i] else BBOX_NONE
  end else let
    val n = !g_fresh
  in
    if n < BBOX_BUFS then (!g_fresh := n + 1; n) else BBOX_NONE
  end

fn recycle_buf(h: int): void = let
  val n = !g_nfree
  val i = g1ofg0(n)
  val hi = g1ofg0(h)
  val () = if (i >= 0) * (i < BBOX_BUFS) then g_free[i] := h
  val () = if (hi >= 0) * (hi < BBOX_BUFS) then g_alive[hi] := false
  val () = if (hi >= 0) * (hi < BBOX_BUFS) then !g_nfree := n + 1
in () end

fn rect_at(h: int, i: int): MinePaintRectangle = let
  val s = g1ofg0(slot_of(h, i))
in
  if (s >= 0) * (s < BBOX_SLOTS) then g_rect[s] else g_zero
end

fn rect_put(h: int, i: int, v: MinePaintRectangle): void = let
  val s = g1ofg0(slot_of(h, i))
in
  if (s >= 0) * (s < BBOX_SLOTS) then g_rect[s] := v else ()
end

fun clear_slots(h: int, i: int, n: int): void =
  if i < n then let
    val () = rect_put(h, i, g_zero)
  in
    clear_slots(h, i + 1, n)
  end else ()

extern fun bbox_buf_new(n: int): int = "ext#bbox_buf_new"
implement bbox_buf_new(n) = let
  val () = assertloc((n > 0) * (n <= BBOX_LEN))
  val h = alloc_buf()
  val () = assertloc(h >= 0)
  val i = g1ofg0(h)
  val () = if (i >= 0) * (i < BBOX_BUFS) then g_len[i] := n
  val () = if (i >= 0) * (i < BBOX_BUFS) then g_alive[i] := true
  val () = clear_slots(h, 0, n)
in
  h
end

extern fun bbox_buf_release(h: int): void = "ext#bbox_buf_release"
implement bbox_buf_release(h) = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < BBOX_BUFS) then
    if g_alive[i] then recycle_buf(h) else ()
  else ()
end

extern fun bbox_clear(h: int, i: int): void = "ext#bbox_clear"
implement bbox_clear(h, i) = rect_put(h, i, g_zero)

extern fun bbox_get(h: int, i: int): MinePaintRectangle = "ext#bbox_get"
implement bbox_get(h, i) = rect_at(h, i)

extern fun bbox_expand_point(h: int, i: int, x: int, y: int): void = "ext#bbox_expand_point"
implement bbox_expand_point(h, i, x, y) =
  rect_put(h, i, rect_expand_point(rect_at(h, i), x, y))
