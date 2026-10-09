// src/draw_engine/fixed_tiled_surface.dats
// Native ATS2 implementation of MinePaint Fixed Tiled Surface
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./engine_safe.hats"

staload "./surface.dats"
staload "./tiled_surface.dats"
staload "draw_engine/surface_box.sats"
staload "draw_engine/req_box.sats"
staload "draw_engine/bytebuf.sats"
#include "./minepaint_types.hats"
staload "sys/libc.dats"

typedef MinePaintFixedTiledSurface_struct = @{
  parent= MinePaintTiledSurface,
  tile_size= size_t,
  tile_buffer= ByteBuf,
  null_tile= ByteBuf,
  tiles_width= int,
  tiles_height= int,
  width= int,
  height= int
}

extern fun view_fixed(p: ptr): ref(MinePaintFixedTiledSurface_struct) = "mac#mp_id_ptr"
extern fun view_tile_req(p: ptr): ref(MinePaintTileRequest) = "mac#mp_id_ptr"
extern fun req_fn2ptr(f: (MpSurface, MpReq) -> void): ptr = "mac#mp_id_ptr"
extern fun destroy_fn2ptr(f: (MpSurface) -> void): ptr = "mac#mp_id_ptr"


fn f_div(a: float, b: float): float = g0float_div(a, b)
fn int2size(x: int): size_t = g0int2uint_int_size(x)
fn mul_size_size(a: size_t, b: size_t): size_t = g0uint_mul_size(a, b)
fn add_size_size(a: size_t, b: size_t): size_t = g0uint_add_size(a, b)

extern fun fixed_tile_request_start(tiled_surface: MpSurface, request: MpReq): void = "ext#fixed_tile_request_start"
extern fun fixed_tile_request_end(tiled_surface: MpSurface, request: MpReq): void = "ext#fixed_tile_request_end"
extern fun free_simple_tiledsurf(surface: MpSurface): void = "ext#free_simple_tiledsurf"

extern fun minepaint_fixed_tiled_surface_new(width: int, height: int): MpSurface = "ext#minepaint_fixed_tiled_surface_new"
extern fun minepaint_fixed_tiled_surface_get_width(self: MpSurface): int = "ext#minepaint_fixed_tiled_surface_get_width"
extern fun minepaint_fixed_tiled_surface_get_height(self: MpSurface): int = "ext#minepaint_fixed_tiled_surface_get_height"
extern fun minepaint_fixed_tiled_surface_interface(self: MpSurface): MpSurface = "ext#minepaint_fixed_tiled_surface_interface"

fn is_out_of_bounds(tx: int, ty: int, w: int, h: int): bool =
  (tx < 0) || (ty < 0) || (tx >= w) || (ty >= h)

fn reset_null_tile(self_p: MpSurface): void = let
  val self = view_fixed(mp_surface_to_ptr(self_p))
  val _ = memset(byte_ptr(self->null_tile), 0, self->tile_size)
in () end

fn compute_tile_offset(self: ref(MinePaintFixedTiledSurface_struct), tx: int, ty: int): size_t = let
  val rowstride = mul_size_size(int2size(self->tiles_width), self->tile_size)
  val x_offset = mul_size_size(int2size(tx), self->tile_size)
in
  add_size_size(mul_size_size(rowstride, int2size(ty)), x_offset)
end

implement fixed_tile_request_start(tiled_surface, request) = let
  val self = view_fixed(mp_surface_to_ptr(tiled_surface))
  val req = view_tile_req(req_ptr(request))
  val tx = req->tx
  val ty = req->ty
in
  if is_out_of_bounds(tx, ty, self->tiles_width, self->tiles_height) then
    req->buffer := byte_ptr(self->null_tile)
  else let
    val offset = compute_tile_offset(self, tx, ty)
  in
    req->buffer := ptr_add<byte>(byte_ptr(self->tile_buffer), offset)
  end
end

implement fixed_tile_request_end(tiled_surface, request) = let
  val self = view_fixed(mp_surface_to_ptr(tiled_surface))
  val req = view_tile_req(req_ptr(request))
in
  if is_out_of_bounds(req->tx, req->ty, self->tiles_width, self->tiles_height) then
    reset_null_tile(tiled_surface)
end

implement minepaint_fixed_tiled_surface_interface(self) = self

implement minepaint_fixed_tiled_surface_get_width(self) =
  if mp_surface_is_null(self) != 0 then 0 else (view_fixed(mp_surface_to_ptr(self)))->width

implement minepaint_fixed_tiled_surface_get_height(self) =
  if mp_surface_is_null(self) != 0 then 0 else (view_fixed(mp_surface_to_ptr(self)))->height

implement free_simple_tiledsurf(surface) =
  if mp_surface_is_null(surface) = 0 then let
    val self = view_fixed(mp_surface_to_ptr(surface))
    val () = minepaint_tiled_surface_destroy(surface)
    val () = if byte_is_null(self->tile_buffer) = 0 then free(byte_ptr(self->tile_buffer))
    val () = if byte_is_null(self->null_tile) = 0 then free(byte_ptr(self->null_tile))
  in
    free(mp_surface_to_ptr(surface))
  end

fn calc_tiles_dim(dim: int, tile_size: int): int =
  g0float2int_float_int(ceilf(f_div(g0int2float_int_float(dim), g0int2float_int_float(tile_size))))

fn setup_fixed_surface(
  self: ref(MinePaintFixedTiledSurface_struct),
  w: int, h: int, tw: int, th: int, single_bytes: size_t, buf: ByteBuf, null_t: ByteBuf
): void = let
  val () = self->tile_buffer := buf
  val () = self->tile_size := single_bytes
  val () = self->null_tile := null_t
  val () = self->tiles_width := tw
  val () = self->tiles_height := th
  val () = self->width := w
  val () = self->height := h
in () end

implement minepaint_fixed_tiled_surface_new(width, height) = let
  val () = assertloc(width > 0 && height > 0)
  val self_p = malloc(sizeof<MinePaintFixedTiledSurface_struct>)
in
  if self_p = the_null_ptr then mp_surface_none()
  else let
    val self = view_fixed(self_p)
    val () = minepaint_tiled_surface_init(
      mp_surface_of_ptr(self_p),
      fn_of(req_fn2ptr(fixed_tile_request_start)),
      fn_of(req_fn2ptr(fixed_tile_request_end))
    )
    val ts = self->parent.tile_size
    val () = self->parent.parent.destroy := fn_of(destroy_fn2ptr(free_simple_tiledsurf))
    val tw = calc_tiles_dim(width, ts)
    val th = calc_tiles_dim(height, ts)
    val single_bytes = mul_size_size(int2size(g0int_mul(ts, ts)), int2size(8))
    val total_bytes = mul_size_size(mul_size_size(int2size(tw), int2size(th)), single_bytes)
    val buf_raw = malloc(total_bytes)
  in
    if buf_raw = the_null_ptr then let
      val () = free(self_p)
    in mp_surface_none() end
    else let
      val _ = memset(buf_raw, 255, total_bytes)
      val null_raw = malloc(single_bytes)
      val () = assertloc(null_raw > the_null_ptr)
      val () = setup_fixed_surface(self, width, height, tw, th, single_bytes, byte_of(buf_raw), byte_of(null_raw))
      val () = reset_null_tile(mp_surface_of_ptr(self_p))
    in
      mp_surface_of_ptr(self_p)
    end
  end
end
