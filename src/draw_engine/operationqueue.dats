// src/draw_engine/operationqueue.dats
// Native ATS2 implementation of Tile-based Operation Queue
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "./engine_safe.hats"

typedef TileIndex = @{
  x= int,
  y= int
}

typedef OperationQueue_struct = @{
  tile_map= ptr,
  dirty_tiles= ptr,
  dirty_tiles_n= int
}

typedef TileMap_struct = @{
  map= ptr,
  size= int,
  item_size= size_t,
  item_free_func= ptr
}

extern castfn ptr2oq(p: ptr): ref(OperationQueue_struct) = "mac#"
extern castfn ptr2tile_idx(p: ptr): ref(TileIndex) = "mac#"
extern castfn ptr2tilemap(p: ptr): ref(TileMap_struct) = "mac#"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

// External functions from tilemap.dats
extern fun tile_map_new(size: int, item_size: size_t, item_free_func: ptr): ptr = "ext#tile_map_new"
extern fun tile_map_free(self: ptr, free_items: bool): void = "ext#tile_map_free"
extern fun tile_map_contains(self: ptr, x: int, y: int): bool = "ext#tile_map_contains"
extern fun tile_map_get(self: ptr, x: int, y: int): ptr = "ext#tile_map_get"
extern fun tile_map_copy_to(self: ptr, other: ptr): void = "ext#tile_map_copy_to"

// External functions from fifo.dats
extern fun fifo_new(): ptr = "ext#fifo_new"
extern fun fifo_free(queue_ptr: ptr, user_free: (ptr) -> void): void = "ext#fifo_free"
extern fun fifo_push(queue_ptr: ptr, data: ptr): void = "ext#fifo_push"
extern fun fifo_pop(queue_ptr: ptr): ptr = "ext#fifo_pop"
extern fun fifo_peek_first(queue_ptr: ptr): ptr = "ext#fifo_peek_first"
extern fun fifo_peek_last(queue_ptr: ptr): ptr = "ext#fifo_peek_last"

fn free_op_func(item: ptr): void =
  if item != the_null_ptr then free(item)

fn free_fifo_wrapper(fifo_ptr: ptr): void =
  if fifo_ptr != the_null_ptr then fifo_free(fifo_ptr, free_op_func)

// Accessors for OperationQueue:
fn get_oq_tile_map(oq: ptr): ptr = let
  val r = ptr2oq(oq)
in r->tile_map end

fn set_oq_tile_map(oq: ptr, v: ptr): void = let
  val r = ptr2oq(oq)
in r->tile_map := v end

fn get_oq_dirty_tiles(oq: ptr): ptr = let
  val r = ptr2oq(oq)
in r->dirty_tiles end

fn set_oq_dirty_tiles(oq: ptr, v: ptr): void = let
  val r = ptr2oq(oq)
in r->dirty_tiles := v end

fn get_oq_dirty_tiles_n(oq: ptr): int = let
  val r = ptr2oq(oq)
in r->dirty_tiles_n end

fn set_oq_dirty_tiles_n(oq: ptr, v: int): void = let
  val r = ptr2oq(oq)
in r->dirty_tiles_n := v end

// TileIndex array helpers
fn get_dirty_tile(dirty_tiles: ptr, idx: int): @(int, int) = let
  val p = ptr_add<TileIndex>(dirty_tiles, idx)
  val r = ptr2tile_idx(p)
in
  @(r->x, r->y)
end

fn set_dirty_tile(dirty_tiles: ptr, idx: int, x: int, y: int): void = let
  val p = ptr_add<TileIndex>(dirty_tiles, idx)
  val r = ptr2tile_idx(p)
  val () = r->x := x
  val () = r->y := y
in () end

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
            if (ix = jx) * (iy = jy) then true
            else loop_j(j + 1)
          end else false
        val found = loop_j(0)
      in
        if not(found) then let
          val () = set_dirty_tile(array_ptr, new_len, ix, iy)
        in loop_i(i + 1, new_len + 1) end
        else loop_i(i + 1, new_len)
      end else new_len
  in
    loop_i(1, 1)
  end

fn copy_dirty_array(old_dirty: ptr, new_dirty: ptr, n: int): void = let
  fun loop(i: int): void =
    if i < n then let
      val @(x, y) = get_dirty_tile(old_dirty, i)
      val () = set_dirty_tile(new_dirty, i, x, y)
    in loop(i + 1) end else ()
in loop(0) end

fn free_oq_data(self: ptr): void = let
  val tm = get_oq_tile_map(self)
  val () = if tm != the_null_ptr then (tile_map_free(tm, true); set_oq_tile_map(self, the_null_ptr))
  val dt = get_oq_dirty_tiles(self)
  val () = if dt != the_null_ptr then free(dt)
  val () = set_oq_dirty_tiles(self, the_null_ptr)
  val () = set_oq_dirty_tiles_n(self, 0)
in () end

fn operation_queue_resize(self: ptr, new_size: int): bool =
  if new_size = 0 then (free_oq_data(self); true)
  else let
    val free_fifo_p = fn2ptr(free_fifo_wrapper)
    val new_tm = tile_map_new(new_size, sizeof<ptr>, free_fifo_p)
    val new_map_size = 4 * new_size * new_size
    val new_dirty = malloc(g0int2uint_int_size(new_map_size) * sizeof<TileIndex>)
    val () = assertloc(new_dirty > the_null_ptr)
    val old_tm = get_oq_tile_map(self)
    val () = if old_tm != the_null_ptr then let
      val () = tile_map_copy_to(old_tm, new_tm)
      val () = copy_dirty_array(get_oq_dirty_tiles(self), new_dirty, get_oq_dirty_tiles_n(self))
      val () = tile_map_free(old_tm, false)
      val () = free(get_oq_dirty_tiles(self))
    in () end
    val () = set_oq_tile_map(self, new_tm)
    val () = set_oq_dirty_tiles(self, new_dirty)
  in false end

extern fun operation_queue_new(): ptr = "ext#operation_queue_new"
implement operation_queue_new() = let
  val p = malloc(sizeof<OperationQueue_struct>)
  val () = assertloc(p > the_null_ptr)
  val () = set_oq_tile_map(p, the_null_ptr)
  val () = set_oq_dirty_tiles(p, the_null_ptr)
  val () = set_oq_dirty_tiles_n(p, 0)
  val _ = operation_queue_resize(p, 10)
in
  p
end

extern fun operation_queue_free(self_p: ptr): void = "ext#operation_queue_free"
implement operation_queue_free(self_p) =
  if self_p != the_null_ptr then let
    val _ = operation_queue_resize(self_p, 0)
    val () = free(self_p)
  in () end

extern fun operation_queue_get_dirty_tiles(self_p: ptr, tiles_out: ptr): int = "ext#operation_queue_get_dirty_tiles"
implement operation_queue_get_dirty_tiles(self_p, tiles_out) = let
  val dirty_tiles = get_oq_dirty_tiles(self_p)
  val dirty_n = get_oq_dirty_tiles_n(self_p)
  val n = remove_duplicate_tiles(dirty_tiles, dirty_n)
  val () = set_oq_dirty_tiles_n(self_p, n)
  val () = if tiles_out != the_null_ptr then mp_arr_pset(tiles_out, 0, dirty_tiles)
in
  n
end

extern fun operation_queue_clear_dirty_tiles(self_p: ptr): void = "ext#operation_queue_clear_dirty_tiles"
implement operation_queue_clear_dirty_tiles(self_p) =
  if self_p != the_null_ptr then set_oq_dirty_tiles_n(self_p, 0) else ()

fn get_tile_map_size(tm: ptr): int = let
  val r = ptr2tilemap(tm)
in r->size end

fun ensure_tilemap_bounds(self_p: ptr, ix: int, iy: int): ptr = let
  val tm = get_oq_tile_map(self_p)
in
  if not(tile_map_contains(tm, ix, iy)) then let
    val cur_sz = get_tile_map_size(tm)
    val _ = operation_queue_resize(self_p, cur_sz * 2)
  in ensure_tilemap_bounds(self_p, ix, iy) end
  else tm
end

fn get_or_create_fifo(q_slot: ptr): ptr = let
  val q_ptr = mp_arr_pget(q_slot, 0)
in
  if q_ptr = the_null_ptr then let
    val created = fifo_new()
    val () = mp_arr_pset(q_slot, 0, created)
  in created end
  else q_ptr
end

fn add_dirty_tile(self_p: ptr, tm: ptr, ix: int, iy: int): void = let
  val cur_sz = get_tile_map_size(tm)
  val cap = 4 * cur_sz * cur_sz
  val dt_ptr = get_oq_dirty_tiles(self_p)
  val cur_n = get_oq_dirty_tiles_n(self_p)
  val n_pruned: int =
    if cur_n >= cap then let
      val p_len = remove_duplicate_tiles(dt_ptr, cur_n)
      val () = set_oq_dirty_tiles_n(self_p, p_len)
    in p_len end
    else cur_n
  val () = set_dirty_tile(dt_ptr, n_pruned, ix, iy)
  val next_n: int = g0int_add_int(n_pruned, 1)
  val () = set_oq_dirty_tiles_n(self_p, next_n)
in () end

extern fun operation_queue_add(self_p: ptr, ix: int, iy: int, op_item: ptr): void = "ext#operation_queue_add"
implement operation_queue_add(self_p, ix, iy, op_item) =
  if self_p != the_null_ptr then let
    val tm = ensure_tilemap_bounds(self_p, ix, iy)
    val q_slot = tile_map_get(tm, ix, iy)
    val op_queue = get_or_create_fifo(q_slot)
    val is_first = fifo_peek_first(op_queue) = the_null_ptr
    val () = if is_first then add_dirty_tile(self_p, tm, ix, iy)
  in
    fifo_push(op_queue, op_item)
  end else ()

extern fun operation_queue_pop(self_p: ptr, ix: int, iy: int): ptr = "ext#operation_queue_pop"
implement operation_queue_pop(self_p, ix, iy) =
  if self_p = the_null_ptr then the_null_ptr
  else let
    val tm = get_oq_tile_map(self_p)
  in
    if not(tile_map_contains(tm, ix, iy)) then the_null_ptr
    else let
      val q_slot = tile_map_get(tm, ix, iy)
      val op_queue = mp_arr_pget(q_slot, 0)
    in
      if op_queue = the_null_ptr then the_null_ptr
      else let
        val op_res = fifo_pop(op_queue)
      in
        if op_res = the_null_ptr then let
          val () = fifo_free(op_queue, free_op_func)
          val () = mp_arr_pset(q_slot, 0, the_null_ptr)
        in the_null_ptr end
        else op_res
      end
    end
  end

extern fun operation_queue_peek_first(self_p: ptr, ix: int, iy: int): ptr = "ext#operation_queue_peek_first"
implement operation_queue_peek_first(self_p, ix, iy) =
  if self_p = the_null_ptr then the_null_ptr
  else let
    val tm = get_oq_tile_map(self_p)
  in
    if not(tile_map_contains(tm, ix, iy)) then the_null_ptr
    else let
      val q_slot = tile_map_get(tm, ix, iy)
      val op_queue = mp_arr_pget(q_slot, 0)
    in
      if op_queue = the_null_ptr then the_null_ptr
      else fifo_peek_first(op_queue)
    end
  end

extern fun operation_queue_peek_last(self_p: ptr, ix: int, iy: int): ptr = "ext#operation_queue_peek_last"
implement operation_queue_peek_last(self_p, ix, iy) =
  if self_p = the_null_ptr then the_null_ptr
  else let
    val tm = get_oq_tile_map(self_p)
  in
    if not(tile_map_contains(tm, ix, iy)) then the_null_ptr
    else let
      val q_slot = tile_map_get(tm, ix, iy)
      val op_queue = mp_arr_pget(q_slot, 0)
    in
      if op_queue = the_null_ptr then the_null_ptr
      else fifo_peek_last(op_queue)
    end
  end
