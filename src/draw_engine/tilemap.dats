// src/draw_engine/tilemap.dats
// Native ATS2 implementation of TileMap for infinite 2D canvas tiling
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

typedef TileIndex_struct = @{
  x= int,
  y= int
}

typedef TileMap_struct = @{
  map= ptr,
  size= int,
  item_size= size_t,
  item_free_func= ptr
}

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

extern fun tile_map_new(size: int, item_size: size_t, item_free_func: ptr): ptr = "ext#tile_map_new"
implement tile_map_new(size, item_size, item_free_func) = let
  val sz = sizeof<TileMap_struct>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val self = $UN.cast{ref(TileMap_struct)}(p)

  val map_entries = 4 * size * size
  val map_bytes = g0int2uint_int_size(map_entries) * item_size
  val map_mem = malloc(map_bytes)
  val () = assertloc(map_mem > the_null_ptr)

  fun init_map(i: int): void =
    if i < map_entries then let
      val slot = ptr_add<ptr>(map_mem, i * g0uint2int_size_int(item_size))
      val () = $UN.ptr0_set<ptr>(slot, the_null_ptr)
    in
      init_map(i + 1)
    end else ()
  val () = init_map(0)

  val () = self->size := size
  val () = self->item_size := item_size
  val () = self->item_free_func := item_free_func
  val () = self->map := map_mem
in
  p
end

extern fun tile_map_free(self_p: ptr, free_items: bool): void = "ext#tile_map_free"
implement tile_map_free(self_p, free_items) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(TileMap_struct)}(self_p)
    val map_mem = self->map
    val sz = self->size
    val map_entries = 4 * sz * sz
    val free_fn = self->item_free_func

    val () =
      if free_items * (free_fn != the_null_ptr) then let
        fun loop_free(i: int): void =
          if i < map_entries then let
            val slot = ptr_add<ptr>(map_mem, i * g0uint2int_size_int(self->item_size))
            val it = $UN.ptr0_get<ptr>(slot)
            val () =
              if it != the_null_ptr then let
                val c_free = $UN.cast{(ptr) -> void}(free_fn)
                val () = c_free(it)
              in () end
          in
            loop_free(i + 1)
          end else ()
        val () = loop_free(0)
      in () end

    val () = if map_mem != the_null_ptr then free(map_mem)
    val () = free(self_p)
  in () end

extern fun tile_map_contains(self_p: ptr, x: int, y: int): bool = "ext#tile_map_contains"
implement tile_map_contains(self_p, x, y) =
  if self_p = the_null_ptr then false
  else let
    val self = $UN.cast{ref(TileMap_struct)}(self_p)
    val sz = self->size
  in
    (x >= ~sz) && (x < sz) && (y >= ~sz) && (y < sz)
  end

extern fun tile_map_get(self_p: ptr, x: int, y: int): ptr = "ext#tile_map_get"
implement tile_map_get(self_p, x, y) = let
  val self = $UN.cast{ref(TileMap_struct)}(self_p)
  val sz = self->size
  val rowstride = sz * 2
  val offset = (sz + y) * rowstride + (sz + x)
  val () = assertloc(offset >= 0 && offset < 4 * sz * sz)
  val item_sz = g0uint2int_size_int(self->item_size)
in
  ptr_add<byte>(self->map, offset * item_sz)
end

extern fun tile_map_copy_to(self_p: ptr, other_p: ptr): void = "ext#tile_map_copy_to"
implement tile_map_copy_to(self_p, other_p) =
  if (self_p != the_null_ptr) * (other_p != the_null_ptr) then let
    val self = $UN.cast{ref(TileMap_struct)}(self_p)
    val sz = self->size

    fun loop_y(y: int): void =
      if y < sz then let
        fun loop_x(x: int): void =
          if x < sz then let
            val src_slot = tile_map_get(self_p, x, y)
            val dst_slot = tile_map_get(other_p, x, y)
            val v = $UN.ptr0_get<ptr>(src_slot)
            val () = $UN.ptr0_set<ptr>(dst_slot, v)
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
