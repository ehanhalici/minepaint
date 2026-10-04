// src/draw_engine/fixed_tiled_surface.dats
// Native ATS2 implementation of MinePaint Fixed Tiled Surface
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "./surface.dats"
staload "./tiled_surface.dats"

typedef MinePaintFixedTiledSurface_struct = @{
  parent= MinePaintTiledSurface_struct,
  tile_size= size_t,
  tile_buffer= ptr,
  null_tile= ptr,
  tiles_width= int,
  tiles_height= int,
  width= int,
  height= int
}

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun memset(p: ptr, v: int, sz: size_t): ptr = "mac#memset"
extern fun ceilf(x: float): float = "mac#ceilf"

fn f_div(a: float, b: float): float = g0float_div(a, b)
fn int2size(x: int): size_t = g0int2uint_int_size(x)
fn mul_size_size(a: size_t, b: size_t): size_t = g0uint_mul_size(a, b)
fn add_size_size(a: size_t, b: size_t): size_t = g0uint_add_size(a, b)

extern fun fixed_tile_request_start(tiled_surface: ptr, request: ptr): void = "ext#fixed_tile_request_start"
extern fun fixed_tile_request_end(tiled_surface: ptr, request: ptr): void = "ext#fixed_tile_request_end"
extern fun free_simple_tiledsurf(surface: ptr): void = "ext#free_simple_tiledsurf"

extern fun minepaint_fixed_tiled_surface_new(width: int, height: int): ptr = "ext#minepaint_fixed_tiled_surface_new"
extern fun minepaint_fixed_tiled_surface_get_width(self: ptr): int = "ext#minepaint_fixed_tiled_surface_get_width"
extern fun minepaint_fixed_tiled_surface_get_height(self: ptr): int = "ext#minepaint_fixed_tiled_surface_get_height"
extern fun minepaint_fixed_tiled_surface_interface(self: ptr): ptr = "ext#minepaint_fixed_tiled_surface_interface"

fn reset_null_tile(self_p: ptr): void = let
  val self = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(self_p)
  val _ = memset(self->null_tile, 0, self->tile_size)
in () end

implement fixed_tile_request_start(tiled_surface, request) = let
  val self = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(tiled_surface)
  val req = $UN.cast{ref(MinePaintTileRequest_struct)}(request)
  val tx = req->tx
  val ty = req->ty
in
  if (tx >= self->tiles_width) || (ty >= self->tiles_height) || (tx < 0) || (ty < 0) then let
    val () = req->buffer := self->null_tile
  in () end
  else let
    val rowstride = mul_size_size(int2size(self->tiles_width), self->tile_size)
    val x_offset = mul_size_size(int2size(tx), self->tile_size)
    val tile_offset = add_size_size(mul_size_size(rowstride, int2size(ty)), x_offset)
    val tile_pointer = ptr_add<byte>(self->tile_buffer, tile_offset)
    val () = req->buffer := tile_pointer
  in () end
end

implement fixed_tile_request_end(tiled_surface, request) = let
  val self = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(tiled_surface)
  val req = $UN.cast{ref(MinePaintTileRequest_struct)}(request)
  val tx = req->tx
  val ty = req->ty
in
  if (tx >= self->tiles_width) || (ty >= self->tiles_height) || (tx < 0) || (ty < 0) then
    reset_null_tile(tiled_surface)
  else ()
end

implement minepaint_fixed_tiled_surface_interface(self) = self

implement minepaint_fixed_tiled_surface_get_width(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(self)
  in s->width end
  else 0

implement minepaint_fixed_tiled_surface_get_height(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(self)
  in s->height end
  else 0

implement free_simple_tiledsurf(surface) =
  if surface != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(surface)
    val () = minepaint_tiled_surface_destroy(surface)
    val () = if self->tile_buffer != the_null_ptr then free(self->tile_buffer)
    val () = if self->null_tile != the_null_ptr then free(self->null_tile)
    val () = free(surface)
  in () end

implement minepaint_fixed_tiled_surface_new(width, height) = let
  val () = assertloc(width > 0)
  val () = assertloc(height > 0)
  val sz_self = sizeof<MinePaintFixedTiledSurface_struct>
  val self_p = malloc(sz_self)
in
  if self_p = the_null_ptr then the_null_ptr
  else let
    val self = $UN.cast{ref(MinePaintFixedTiledSurface_struct)}(self_p)
    val () = minepaint_tiled_surface_init(
      self_p,
      $UN.cast{ptr}(fixed_tile_request_start),
      $UN.cast{ptr}(fixed_tile_request_end)
    )
    val tile_size_pixels = self->parent.tile_size
    val () = self->parent.parent.destroy := $UN.cast{ptr}(free_simple_tiledsurf)

    val tiles_w = g0float2int_float_int(ceilf(f_div(g0int2float_int_float(width), g0int2float_int_float(tile_size_pixels))))
    val tiles_h = g0float2int_float_int(ceilf(f_div(g0int2float_int_float(height), g0int2float_int_float(tile_size_pixels))))

    val single_tile_bytes = mul_size_size(int2size(g0int_mul(tile_size_pixels, tile_size_pixels)), int2size(8))
    val buffer_bytes = mul_size_size(mul_size_size(int2size(tiles_w), int2size(tiles_h)), single_tile_bytes)

    val buffer = malloc(buffer_bytes)
  in
    if buffer = the_null_ptr then let
      val () = free(self_p)
    in the_null_ptr end
    else let
      val _ = memset(buffer, 255, buffer_bytes)
      val null_t = malloc(single_tile_bytes)
      val () = assertloc(null_t > the_null_ptr)
      val () = self->tile_buffer := buffer
      val () = self->tile_size := single_tile_bytes
      val () = self->null_tile := null_t
      val () = self->tiles_width := tiles_w
      val () = self->tiles_height := tiles_h
      val () = self->width := width
      val () = self->height := height
      val () = reset_null_tile(self_p)
    in
      self_p
    end
  end
end
