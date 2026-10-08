// Operation queue as an integer handle. The dirty-tile buffer stays a
// malloc'd pair array because the surface reads it back through a pointer.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./engine_safe.hats"
#include "./minepaint_types.hats"

#define OQ_CAP 8
#define TM_MAX 256

typedef TileIndex = @{
  x= int,
  y= int
}

val g_alive = arrayref_make_elt<bool>(i2sz(OQ_CAP), false)
val g_tm = arrayref_make_elt<int>(i2sz(OQ_CAP), TILEMAP_NONE)
val g_dirty = arrayref_make_elt<ptr>(i2sz(OQ_CAP), the_null_ptr)
val g_n = arrayref_make_elt<int>(i2sz(OQ_CAP), 0)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(OQ_CAP), 0)

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

extern fun tile_map_new(sz: int): int = "ext#tile_map_new"
extern fun tile_map_free(h: int, free_items: bool, user_free: (ptr) -> void): void = "ext#tile_map_free"
extern fun tile_map_contains(h: int, x: int, y: int): bool = "ext#tile_map_contains"
extern fun tile_map_size(h: int): int = "ext#tile_map_size"
extern fun tile_map_get_fifo(h: int, x: int, y: int): int = "ext#tile_map_get_fifo"
extern fun tile_map_set_fifo(h: int, x: int, y: int, fh: int): void = "ext#tile_map_set_fifo"
extern fun tile_map_copy_to(src: int, dst: int): void = "ext#tile_map_copy_to"

extern fun fifo_new(): int = "ext#fifo_new"
extern fun fifo_free(h: int, user_free: (ptr) -> void): void = "ext#fifo_free"
extern fun fifo_push(h: int, data: ptr): void = "ext#fifo_push"
extern fun fifo_pop(h: int): ptr = "ext#fifo_pop"
extern fun fifo_peek_first(h: int): ptr = "ext#fifo_peek_first"
extern fun fifo_peek_last(h: int): ptr = "ext#fifo_peek_last"

fn alive_get(h: int): bool = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_alive[i] else false
end

fn alive_set(h: int, v: bool): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_alive[i] := v else ()
end

fn tm_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_tm[i] else TILEMAP_NONE
end

fn tm_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_tm[i] := v else ()
end

fn dirty_get(h: int): ptr = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_dirty[i] else the_null_ptr
end

fn dirty_set(h: int, v: ptr): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_dirty[i] := v else ()
end

fn n_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_n[i] else 0
end

fn n_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < OQ_CAP) then g_n[i] := v else ()
end

fn alloc_oq(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < OQ_CAP) then g_free[i] else OQ_NONE
  end else let
    val n = !g_fresh
  in
    if n < OQ_CAP then (!g_fresh := n + 1; n) else OQ_NONE
  end

fn recycle_oq(h: int): void = let
  val n = !g_nfree
  val i = g1ofg0(n)
  val () = if (i >= 0) * (i < OQ_CAP) then g_free[i] := h
  val () = if (g1ofg0(h) >= 0) * (g1ofg0(h) < OQ_CAP) then !g_nfree := n + 1
in () end

fn free_op_func(item: ptr): void =
  if item != the_null_ptr then free(item)

fn get_dirty_tile(p: ptr, idx: int): @(int, int) =
  @(mp_arr_iget(p, idx * 2), mp_arr_iget(p, idx * 2 + 1))

fn set_dirty_tile(p: ptr, idx: int, x: int, y: int): void = let
  val () = mp_arr_iset(p, idx * 2, x)
in
  mp_arr_iset(p, idx * 2 + 1, y)
end

fn remove_duplicate_tiles(array_ptr: ptr, len: int): int =
  if len < 2 then len
  else let
    fun loop_i(i: int, new_len: int): int =
      if i < len then let
        val @(ix, iy) = get_dirty_tile(array_ptr, i)
        fun loop_j(j: int): bool =
          if j < new_len then let
            val @(jx, jy) = get_dirty_tile(array_ptr, j)
          in
            if (ix = jx) * (iy = jy) then true else loop_j(j + 1)
          end else false
        val found = loop_j(0)
      in
        if not(found) then let
          val () = set_dirty_tile(array_ptr, new_len, ix, iy)
        in
          loop_i(i + 1, new_len + 1)
        end else loop_i(i + 1, new_len)
      end else new_len
  in
    loop_i(1, 1)
  end

fn copy_dirty_array(old_dirty: ptr, new_dirty: ptr, n: int): void = let
  fun loop(i: int): void =
    if i < n then let
      val @(x, y) = get_dirty_tile(old_dirty, i)
      val () = set_dirty_tile(new_dirty, i, x, y)
    in
      loop(i + 1)
    end else ()
in
  loop(0)
end

fn free_oq_data(h: int): void = let
  val tm = tm_get(h)
  val () = if tm >= 0 then tile_map_free(tm, true, free_op_func)
  val () = tm_set(h, TILEMAP_NONE)
  val dt = dirty_get(h)
  val () = if dt != the_null_ptr then free(dt)
  val () = dirty_set(h, the_null_ptr)
in
  n_set(h, 0)
end

fn operation_queue_resize(h: int, new_size: int): bool =
  if new_size = 0 then (free_oq_data(h); true)
  else let
    val () = assertloc((new_size > 0) * (new_size <= TM_MAX))
    val new_tm = tile_map_new(new_size)
    val new_map_size = 4 * new_size * new_size
    val new_dirty = malloc(g0int2uint_int_size(new_map_size) * sizeof<TileIndex>)
    val () = assertloc(new_dirty > the_null_ptr)
    val old_tm = tm_get(h)
    val () = if old_tm >= 0 then let
      val () = tile_map_copy_to(old_tm, new_tm)
      val () = copy_dirty_array(dirty_get(h), new_dirty, n_get(h))
      val () = tile_map_free(old_tm, false, free_op_func)
      val () = free(dirty_get(h))
    in () end
    val () = tm_set(h, new_tm)
    val () = dirty_set(h, new_dirty)
  in
    false
  end

extern fun operation_queue_new(): int = "ext#operation_queue_new"
implement operation_queue_new() = let
  val h = alloc_oq()
  val () = assertloc(h >= 0)
  val () = alive_set(h, true)
  val () = tm_set(h, TILEMAP_NONE)
  val () = dirty_set(h, the_null_ptr)
  val () = n_set(h, 0)
  val _ = operation_queue_resize(h, 10)
in
  h
end

extern fun operation_queue_free(h: int): void = "ext#operation_queue_free"
implement operation_queue_free(h) =
  if alive_get(h) then let
    val _ = operation_queue_resize(h, 0)
    val () = alive_set(h, false)
  in
    recycle_oq(h)
  end else ()

extern fun operation_queue_get_dirty_tiles(h: int, tiles_out: ptr): int = "ext#operation_queue_get_dirty_tiles"
implement operation_queue_get_dirty_tiles(h, tiles_out) =
  if not(alive_get(h)) then 0
  else let
    val dirty = dirty_get(h)
    val n0 = remove_duplicate_tiles(dirty, n_get(h))
    val () = n_set(h, n0)
    val () = if tiles_out != the_null_ptr then mp_arr_pset(tiles_out, 0, dirty)
  in
    n0
  end

extern fun operation_queue_clear_dirty_tiles(h: int): void = "ext#operation_queue_clear_dirty_tiles"
implement operation_queue_clear_dirty_tiles(h) =
  if alive_get(h) then n_set(h, 0) else ()

fun ensure_tilemap_bounds(h: int, ix: int, iy: int): int = let
  val tm = tm_get(h)
in
  if not(tile_map_contains(tm, ix, iy)) then let
    val nxt = tile_map_size(tm) * 2
    val () = assertloc(nxt <= TM_MAX)
    val _ = operation_queue_resize(h, nxt)
  in
    ensure_tilemap_bounds(h, ix, iy)
  end else tm
end

fn add_dirty_tile(h: int, tm: int, ix: int, iy: int): void = let
  val cap = 4 * tile_map_size(tm) * tile_map_size(tm)
  val dt = dirty_get(h)
  val cur_n = n_get(h)
  val n_pruned =
    if cur_n >= cap then let
      val p_len = remove_duplicate_tiles(dt, cur_n)
      val () = n_set(h, p_len)
    in
      p_len
    end else cur_n
  val () = set_dirty_tile(dt, n_pruned, ix, iy)
in
  n_set(h, g0int_add_int(n_pruned, 1))
end

fn get_or_create_fifo(tm: int, ix: int, iy: int): int = let
  val cur = tile_map_get_fifo(tm, ix, iy)
in
  if cur < 0 then let
    val created = fifo_new()
    val () = tile_map_set_fifo(tm, ix, iy, created)
  in
    created
  end else cur
end

extern fun operation_queue_add(h: int, ix: int, iy: int, op_item: ptr): void = "ext#operation_queue_add"
implement operation_queue_add(h, ix, iy, op_item) =
  if alive_get(h) then let
    val tm = ensure_tilemap_bounds(h, ix, iy)
    val op_queue = get_or_create_fifo(tm, ix, iy)
    val is_first = fifo_peek_first(op_queue) = the_null_ptr
    val () = if is_first then add_dirty_tile(h, tm, ix, iy)
  in
    fifo_push(op_queue, op_item)
  end else ()

extern fun operation_queue_pop(h: int, ix: int, iy: int): ptr = "ext#operation_queue_pop"
implement operation_queue_pop(h, ix, iy) =
  if not(alive_get(h)) then the_null_ptr
  else let
    val tm = tm_get(h)
  in
    if not(tile_map_contains(tm, ix, iy)) then the_null_ptr
    else let
      val op_queue = tile_map_get_fifo(tm, ix, iy)
    in
      if op_queue < 0 then the_null_ptr
      else let
        val op_res = fifo_pop(op_queue)
      in
        if op_res = the_null_ptr then let
          val () = fifo_free(op_queue, free_op_func)
          val () = tile_map_set_fifo(tm, ix, iy, FIFO_NONE)
        in
          the_null_ptr
        end else op_res
      end
    end
  end

extern fun operation_queue_peek_first(h: int, ix: int, iy: int): ptr = "ext#operation_queue_peek_first"
implement operation_queue_peek_first(h, ix, iy) =
  if not(alive_get(h)) then the_null_ptr
  else let
    val tm = tm_get(h)
  in
    if not(tile_map_contains(tm, ix, iy)) then the_null_ptr
    else let
      val op_queue = tile_map_get_fifo(tm, ix, iy)
    in
      if op_queue < 0 then the_null_ptr else fifo_peek_first(op_queue)
    end
  end

extern fun operation_queue_peek_last(h: int, ix: int, iy: int): ptr = "ext#operation_queue_peek_last"
implement operation_queue_peek_last(h, ix, iy) =
  if not(alive_get(h)) then the_null_ptr
  else let
    val tm = tm_get(h)
  in
    if not(tile_map_contains(tm, ix, iy)) then the_null_ptr
    else let
      val op_queue = tile_map_get_fifo(tm, ix, iy)
    in
      if op_queue < 0 then the_null_ptr else fifo_peek_last(op_queue)
    end
  end
