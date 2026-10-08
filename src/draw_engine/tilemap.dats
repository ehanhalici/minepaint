// Tile map as an integer handle. Each slot holds a FIFO handle.
// main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"

#define TM_CAP 8
#define TM_MAX 256
#define TM_ENTRIES 262144
#define TM_SLOTS 2097152

val g_alive = arrayref_make_elt<bool>(i2sz(TM_CAP), false)
val g_size = arrayref_make_elt<int>(i2sz(TM_CAP), 0)
val g_slot = arrayref_make_elt<int>(i2sz(TM_SLOTS), FIFO_NONE)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(TM_CAP), 0)

extern fun fifo_free(h: int, user_free: (ptr) -> void): void = "ext#fifo_free"

fn alive_get(h: int): bool = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < TM_CAP) then g_alive[i] else false
end

fn alive_set(h: int, v: bool): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < TM_CAP) then g_alive[i] := v else ()
end

fn size_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < TM_CAP) then g_size[i] else 0
end

fn size_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < TM_CAP) then g_size[i] := v else ()
end

fn slot_get(idx: int): int = let
  val i = g1ofg0(idx)
in
  if (i >= 0) * (i < TM_SLOTS) then g_slot[i] else FIFO_NONE
end

fn slot_set(idx: int, v: int): void = let
  val i = g1ofg0(idx)
in
  if (i >= 0) * (i < TM_SLOTS) then g_slot[i] := v else ()
end

fn entries_of(sz: int): int = 4 * sz * sz

fn offset_of(sz: int, x: int, y: int): int =
  (sz + y) * (sz * 2) + (sz + x)

fn slot_index(h: int, linear: int): int = h * TM_ENTRIES + linear

fn alloc_tm(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < TM_CAP) then g_free[i] else TILEMAP_NONE
  end else let
    val n = !g_fresh
  in
    if n < TM_CAP then (!g_fresh := n + 1; n) else TILEMAP_NONE
  end

fn recycle_tm(h: int): void = let
  val n = !g_nfree
  val i = g1ofg0(n)
  val () = if (i >= 0) * (i < TM_CAP) then g_free[i] := h
  val () = if (g1ofg0(h) >= 0) * (g1ofg0(h) < TM_CAP) then !g_nfree := n + 1
in () end

fn clear_slots(h: int, n: int): void = let
  fun loop(i: int): void =
    if i < n then let
      val () = slot_set(slot_index(h, i), FIFO_NONE)
    in
      loop(i + 1)
    end else ()
in
  loop(0)
end

extern fun tile_map_new(sz: int): int = "ext#tile_map_new"
implement tile_map_new(sz) = let
  val h = alloc_tm()
  val () = assertloc(h >= 0)
  val () = assertloc((sz > 0) * (sz <= TM_MAX))
  val () = size_set(h, sz)
  val () = alive_set(h, true)
  val () = clear_slots(h, entries_of(sz))
in
  h
end

extern fun tile_map_size(h: int): int = "ext#tile_map_size"
implement tile_map_size(h) = if alive_get(h) then size_get(h) else 0

extern fun tile_map_contains(h: int, x: int, y: int): bool = "ext#tile_map_contains"
implement tile_map_contains(h, x, y) =
  if not(alive_get(h)) then false
  else let
    val sz = size_get(h)
  in
    (x >= ~sz) && (x < sz) && (y >= ~sz) && (y < sz)
  end

extern fun tile_map_get_fifo(h: int, x: int, y: int): int = "ext#tile_map_get_fifo"
implement tile_map_get_fifo(h, x, y) = let
  val sz = size_get(h)
  val off = offset_of(sz, x, y)
  val () = assertloc((off >= 0) * (off < entries_of(sz)))
in
  slot_get(slot_index(h, off))
end

extern fun tile_map_set_fifo(h: int, x: int, y: int, fh: int): void = "ext#tile_map_set_fifo"
implement tile_map_set_fifo(h, x, y, fh) = let
  val sz = size_get(h)
  val off = offset_of(sz, x, y)
  val () = assertloc((off >= 0) * (off < entries_of(sz)))
in
  slot_set(slot_index(h, off), fh)
end

extern fun tile_map_free(h: int, free_items: bool, user_free: (ptr) -> void): void = "ext#tile_map_free"
implement tile_map_free(h, free_items, user_free) =
  if alive_get(h) then let
    val n = entries_of(size_get(h))
    fun loop(i: int): void =
      if i < n then let
        val fh = slot_get(slot_index(h, i))
        val () = if free_items * (fh >= 0) then fifo_free(fh, user_free)
        val () = slot_set(slot_index(h, i), FIFO_NONE)
      in
        loop(i + 1)
      end else ()
    val () = loop(0)
    val () = alive_set(h, false)
  in
    recycle_tm(h)
  end else ()

extern fun tile_map_copy_to(src: int, dst: int): void = "ext#tile_map_copy_to"
implement tile_map_copy_to(src, dst) =
  if alive_get(src) * alive_get(dst) then let
    val sz = size_get(src)
    fun loop_y(y: int): void =
      if y < sz then let
        fun loop_x(x: int): void =
          if x < sz then let
            val () = tile_map_set_fifo(dst, x, y, tile_map_get_fifo(src, x, y))
          in
            loop_x(x + 1)
          end else ()
        val () = loop_x(~sz)
      in
        loop_y(y + 1)
      end else ()
  in
    loop_y(~sz)
  end else ()
