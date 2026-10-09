// Bounding-box buffers as integer handles. Each buffer is a fixed
// run of rectangles. main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./engine_safe.hats"
#include "./rectangle_pure.hats"

#define BBOX_BUFS 32
#define BBOX_LEN 1024
#define BBOX_SLOTS 32768

val g_zero = @{ x= 0, y= 0, width= 0, height= 0 } : MinePaintRectangle
val g_alive = air_arena(BBOX_BUFS, airlock_esz_int())
val g_len = air_arena(BBOX_BUFS, airlock_esz_int())
val g_rect = arrayref_make_elt<MinePaintRectangle>(i2sz(BBOX_SLOTS), g_zero)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = air_arena(BBOX_BUFS, airlock_esz_int())

fn buf_in(h: int): bool = airlock_below(h, BBOX_BUFS) != 0

fn slot_of(h: int, i: int): int = h * BBOX_LEN + i

fn alloc_buf(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
  in
    if buf_in(n) then airlock_iget_n(g_free, n, BBOX_BUFS) else BBOX_NONE
  end else let
    val n = !g_fresh
  in
    if n < BBOX_BUFS then (!g_fresh := n + 1; n) else BBOX_NONE
  end

fn recycle_buf(h: int): void = let
  val n = !g_nfree
  val () = if buf_in(n) then airlock_iset_n(g_free, n, BBOX_BUFS, h)
  val () = air_bset(g_alive, h, BBOX_BUFS, false)
  val () = if buf_in(h) then !g_nfree := n + 1
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
  val () = airlock_iset_n(g_len, h, BBOX_BUFS, n)
  val () = air_bset(g_alive, h, BBOX_BUFS, true)
  val () = clear_slots(h, 0, n)
in
  h
end

extern fun bbox_buf_release(h: int): void = "ext#bbox_buf_release"
implement bbox_buf_release(h) =
  if buf_in(h) then
    if air_bget(g_alive, h, BBOX_BUFS) then recycle_buf(h) else ()
  else ()

extern fun bbox_clear(h: int, i: int): void = "ext#bbox_clear"
implement bbox_clear(h, i) = rect_put(h, i, g_zero)

extern fun bbox_get(h: int, i: int): MinePaintRectangle = "ext#bbox_get"
implement bbox_get(h, i) = rect_at(h, i)

extern fun bbox_expand_point(h: int, i: int, x: int, y: int): void = "ext#bbox_expand_point"
implement bbox_expand_point(h, i, x, y) =
  rect_put(h, i, rect_expand_point(rect_at(h, i), x, y))
