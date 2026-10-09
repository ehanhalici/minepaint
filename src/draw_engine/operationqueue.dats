// Operation queue as an integer handle. The dirty-tile array is an IntBuf.
// The surface still receives that address through the out-parameter cell.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./engine_safe.hats"
#include "./minepaint_types.hats"
staload "draw_engine/intbuf.sats"
staload "sys/libc.dats"

#define OQ_CAP 8
#define TM_MAX 256

typedef TileIndex = @{
  x= int,
  y= int
}

val g_alive = air_arena(OQ_CAP, airlock_esz_int())
val g_tm = air_arena(OQ_CAP, airlock_esz_int())
val () = airlock_fill_int(g_tm, OQ_CAP, TILEMAP_NONE)
val g_dirty = air_arena(OQ_CAP, airlock_esz_ptr())
val g_n = air_arena(OQ_CAP, airlock_esz_int())
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = air_arena(OQ_CAP, airlock_esz_int())

extern fun tile_map_new(sz: int): int = "ext#tile_map_new"
extern fun tile_map_free(h: int, free_items: bool, user_free: (int) -> void): void = "ext#tile_map_free"
extern fun tile_map_contains(h: int, x: int, y: int): bool = "ext#tile_map_contains"
extern fun tile_map_size(h: int): int = "ext#tile_map_size"
extern fun tile_map_get_fifo(h: int, x: int, y: int): int = "ext#tile_map_get_fifo"
extern fun tile_map_set_fifo(h: int, x: int, y: int, fh: int): void = "ext#tile_map_set_fifo"
extern fun tile_map_copy_to(src: int, dst: int): void = "ext#tile_map_copy_to"

extern fun fifo_new(): int = "ext#fifo_new"
extern fun fifo_free(h: int, user_free: (int) -> void): void = "ext#fifo_free"
extern fun fifo_push(h: int, data: int): void = "ext#fifo_push"
extern fun fifo_pop(h: int): int = "ext#fifo_pop"
extern fun fifo_peek_first(h: int): int = "ext#fifo_peek_first"
extern fun fifo_peek_last(h: int): int = "ext#fifo_peek_last"
extern fun dab_release(h: int): void = "ext#dab_release"

fn oq_in(h: int): bool = airlock_span(h, 1, OQ_CAP) != 0
fn alive_get(h: int): bool = air_bget(g_alive, h, OQ_CAP)
fn alive_set(h: int, v: bool): void = air_bset(g_alive, h, OQ_CAP, v)
fn tm_get(h: int): int =
  if oq_in(h) then airlock_iget_n(g_tm, h, OQ_CAP) else TILEMAP_NONE
fn tm_set(h: int, v: int): void = airlock_iset_n(g_tm, h, OQ_CAP, v)
fn dirty_get(h: int): IntBuf =
  if oq_in(h) then intbuf_of(airlock_pget_n(g_dirty, h, OQ_CAP)) else intbuf_none()
fn dirty_set(h: int, v: IntBuf): void =
  if oq_in(h) then airlock_pset_n(g_dirty, h, OQ_CAP, intbuf_ptr(v))
fn n_get(h: int): int = airlock_iget_n(g_n, h, OQ_CAP)
fn n_set(h: int, v: int): void = airlock_iset_n(g_n, h, OQ_CAP, v)

fn alloc_oq(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
  in
    if oq_in(n) then airlock_iget_n(g_free, n, OQ_CAP) else OQ_NONE
  end else let
    val n = !g_fresh
  in
    if n < OQ_CAP then (!g_fresh := n + 1; n) else OQ_NONE
  end

fn recycle_oq(h: int): void = let
  val n = !g_nfree
  val () = if oq_in(n) then airlock_iset_n(g_free, n, OQ_CAP, h)
  val () = if oq_in(h) then !g_nfree := n + 1
in () end

fn free_op_func(item: int): void =
  if item >= 0 then dab_release(item)

fn get_dirty_tile(p: IntBuf, idx: int, nints: int): @(int, int) =
  @(airlock_iget_n(intbuf_ptr(p), idx * 2, nints), airlock_iget_n(intbuf_ptr(p), idx * 2 + 1, nints))

fn set_dirty_tile(p: IntBuf, idx: int, x: int, y: int, nints: int): void = let
  val () = airlock_iset_n(intbuf_ptr(p), idx * 2, nints, x)
in
  airlock_iset_n(intbuf_ptr(p), idx * 2 + 1, nints, y)
end

fn remove_duplicate_tiles(array_ptr: IntBuf, len: int): int =
  if len < 2 then len
  else let
    fun loop_i(i: int, new_len: int): int =
      if i < len then let
        val @(ix, iy) = get_dirty_tile(array_ptr, i, len * 2)
        fun loop_j(j: int): bool =
          if j < new_len then let
            val @(jx, jy) = get_dirty_tile(array_ptr, j, len * 2)
          in
            if (ix = jx) * (iy = jy) then true else loop_j(j + 1)
          end else false
        val found = loop_j(0)
      in
        if not(found) then let
          val () = set_dirty_tile(array_ptr, new_len, ix, iy, len * 2)
        in
          loop_i(i + 1, new_len + 1)
        end else loop_i(i + 1, new_len)
      end else new_len
  in
    loop_i(1, 1)
  end

fn copy_dirty_array(old_dirty: IntBuf, new_dirty: IntBuf, n: int): void = let
  fun loop(i: int): void =
    if i < n then let
      val @(x, y) = get_dirty_tile(old_dirty, i, n * 2)
      val () = set_dirty_tile(new_dirty, i, x, y, n * 2)
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
  val () = if intbuf_is_null(dt) = 0 then free(intbuf_ptr(dt))
  val () = dirty_set(h, intbuf_none())
in
  n_set(h, 0)
end

fn operation_queue_resize(h: int, new_size: int): bool =
  if new_size = 0 then (free_oq_data(h); true)
  else let
    val () = assertloc((new_size > 0) * (new_size <= TM_MAX))
    val new_tm = tile_map_new(new_size)
    val new_map_size = 4 * new_size * new_size
    val raw_dirty = malloc(g0int2uint_int_size(new_map_size) * sizeof<TileIndex>)
    val () = assertloc(raw_dirty > the_null_ptr)
    val new_dirty = intbuf_of(raw_dirty)
    val old_tm = tm_get(h)
    val () = if old_tm >= 0 then let
      val () = tile_map_copy_to(old_tm, new_tm)
      val () = copy_dirty_array(dirty_get(h), new_dirty, n_get(h))
      val () = tile_map_free(old_tm, false, free_op_func)
      val () = free(intbuf_ptr(dirty_get(h)))
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
  val () = dirty_set(h, intbuf_none())
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
    val () = if tiles_out != the_null_ptr then airlock_pset_n(tiles_out, 0, 1, intbuf_ptr(dirty))
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
  val () = set_dirty_tile(dt, n_pruned, ix, iy, cap * 2)
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

extern fun operation_queue_add(h: int, ix: int, iy: int, op_item: int): void = "ext#operation_queue_add"
implement operation_queue_add(h, ix, iy, op_item) =
  if alive_get(h) then let
    val tm = ensure_tilemap_bounds(h, ix, iy)
    val op_queue = get_or_create_fifo(tm, ix, iy)
    val is_first = fifo_peek_first(op_queue) < 0
    val () = if is_first then add_dirty_tile(h, tm, ix, iy)
  in
    fifo_push(op_queue, op_item)
  end else ()

extern fun operation_queue_pop(h: int, ix: int, iy: int): int = "ext#operation_queue_pop"
implement operation_queue_pop(h, ix, iy) =
  if not(alive_get(h)) then DAB_NONE
  else let
    val tm = tm_get(h)
  in
    if not(tile_map_contains(tm, ix, iy)) then DAB_NONE
    else let
      val op_queue = tile_map_get_fifo(tm, ix, iy)
    in
      if op_queue < 0 then DAB_NONE
      else let
        val op_res = fifo_pop(op_queue)
      in
        if op_res < 0 then let
          val () = fifo_free(op_queue, free_op_func)
          val () = tile_map_set_fifo(tm, ix, iy, FIFO_NONE)
        in
          DAB_NONE
        end else op_res
      end
    end
  end

extern fun operation_queue_peek_first(h: int, ix: int, iy: int): int = "ext#operation_queue_peek_first"
implement operation_queue_peek_first(h, ix, iy) =
  if not(alive_get(h)) then DAB_NONE
  else let
    val tm = tm_get(h)
  in
    if not(tile_map_contains(tm, ix, iy)) then DAB_NONE
    else let
      val op_queue = tile_map_get_fifo(tm, ix, iy)
    in
      if op_queue < 0 then DAB_NONE else fifo_peek_first(op_queue)
    end
  end

extern fun operation_queue_peek_last(h: int, ix: int, iy: int): int = "ext#operation_queue_peek_last"
implement operation_queue_peek_last(h, ix, iy) =
  if not(alive_get(h)) then DAB_NONE
  else let
    val tm = tm_get(h)
  in
    if not(tile_map_contains(tm, ix, iy)) then DAB_NONE
    else let
      val op_queue = tile_map_get_fifo(tm, ix, iy)
    in
      if op_queue < 0 then DAB_NONE else fifo_peek_last(op_queue)
    end
  end
