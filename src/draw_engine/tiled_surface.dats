// src/draw_engine/tiled_surface.dats
// Native ATS2 implementation of MinePaint Tiled Surface
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./engine_safe.hats"
staload "draw_engine/intbuf.sats"

staload "./rectangle.dats"
staload "draw_engine/rect_box.sats"
staload "./bbox.dats"
staload "./symmetry.dats"
staload "./operationqueue.dats"
staload "./dab.dats"
staload "./brushmodes.dats"
staload "draw_engine/pixel_buf.sats"
staload "draw_engine/fltbuf.sats"
staload "draw_engine/fcell.sats"
staload "./surface.dats"
staload "draw_engine/surface_box.sats"
staload "./helpers.dats"

#include "./minepaint_types.hats"
#include "./matrix_pure.hats"
#define M_PI 3.14159265358979323846f

extern fun view_tiled(p: ptr): ref(MinePaintTiledSurface) = "mac#mp_id_ptr"
extern fun view_tile_req(p: ptr): ref(MinePaintTileRequest) = "mac#mp_id_ptr"
extern fun view_rects(p: ptr): ref(MinePaintRectangles) = "mac#mp_id_ptr"
extern fun store_draw_dab(f: MinePaintSurfaceDrawDabFunction): ptr = "mac#mp_id_ptr"
typedef TiledGetColorFn = (
  ptr, float, float, float,
  &float? >> float, &float? >> float, &float? >> float, &float? >> float,
  float
) -> void
extern fun store_get_color(f: TiledGetColorFn): ptr = "mac#mp_id_ptr"
extern fun store_begin(f: MinePaintSurfaceBeginAtomicFunction): ptr = "mac#mp_id_ptr"
extern fun store_end(f: MinePaintSurfaceEndAtomicFunction): ptr = "mac#mp_id_ptr"

fn i2u16(x: int): uint16 = u16(g0int2uint_int_uint(x))

typedef MinePaintTileRequestFunc = (ptr, ptr) -> void
extern fun load_tile_req(p: ptr): MinePaintTileRequestFunc = "mac#mp_id_ptr"

fn call_tile_request_start(f: ptr, self: ptr, req: ptr): void =
  if f != the_null_ptr then load_tile_req(f)(self, req)

fn call_tile_request_end(f: ptr, self: ptr, req: ptr): void =
  if f != the_null_ptr then load_tile_req(f)(self, req)

fn get_tiled_surface_symmetry_data(self: ptr): int =
  (view_tiled(self))->symmetry_data

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)
fn f_lte(a: float, b: float): bool = a <= b
fn f_gte(a: float, b: float): bool = a >= b
fn f_lt(a: float, b: float): bool = a < b
fn f_gt(a: float, b: float): bool = a > b
fn mul_size_size(a: size_t, b: size_t): size_t = g0uint_mul_size(a, b)
fn int2size(x: int): size_t = g0int2uint_int_size(x)

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun memset(p: ptr, v: int, sz: size_t): ptr = "mac#memset"
extern fun cosf(x: float): float = "mac#cosf"
extern fun sinf(x: float): float = "mac#sinf"
extern fun sqrtf(x: float): float = "mac#sqrtf"
extern fun floorf(x: float): float = "mac#floorf"
extern fun roundf(x: float): float = "mac#roundf"

fn f_clamp(x: float, min_v: float, max_v: float): float =
  if f_lt(x, min_v) then min_v else if f_gt(x, max_v) then max_v else x

fn i_min(a: int, b: int): int = if a < b then a else b
fn i_max(a: int, b: int): int = if a > b then a else b

fn get_dirty_tile(dirty_tiles: IntBuf, idx: int): @(int, int) = let
  val p = intbuf_ptr(dirty_tiles)
  val x = mp_arr_iget(p, idx * 2)
  val y = mp_arr_iget(p, idx * 2 + 1)
in
  @(x, y)
end

// minepaint_tile_request_init
extern fun minepaint_tile_request_init(
  data_p: ptr, level: int, tx: int, ty: int, readonly: bool
): void = "ext#minepaint_tile_request_init"
implement minepaint_tile_request_init(data_p, level, tx, ty, readonly) =
  if data_p != the_null_ptr then let
    val r = view_tile_req(data_p)
    val () = r->tx := tx
    val () = r->ty := ty
    val () = r->readonly := (if readonly then 1 else 0)
    val () = r->buffer := the_null_ptr
    val () = r->context := the_null_ptr
    val () = r->thread_id := ~1
    val () = r->mipmap_level := level
  in () end

extern fun minepaint_tiled_surface_tile_request_start(self_p: ptr, req_p: ptr): void = "ext#minepaint_tiled_surface_tile_request_start"
implement minepaint_tiled_surface_tile_request_start(self_p, req_p) =
  if (self_p != the_null_ptr) * (req_p != the_null_ptr) then let
    val self = view_tiled(self_p)
  in
    call_tile_request_start(self->tile_request_start, self_p, req_p)
  end

extern fun minepaint_tiled_surface_tile_request_end(self_p: ptr, req_p: ptr): void = "ext#minepaint_tiled_surface_tile_request_end"
implement minepaint_tiled_surface_tile_request_end(self_p, req_p) =
  if (self_p != the_null_ptr) * (req_p != the_null_ptr) then let
    val self = view_tiled(self_p)
  in
    call_tile_request_end(self->tile_request_end, self_p, req_p)
  end

// Geometry & antialiasing calculations
fn calculate_r_sample(x: float, y: float, aspect_ratio: float, sn: float, cs: float): float = let
  val yyr = f_mul(f_sub(f_mul(y, cs), f_mul(x, sn)), aspect_ratio)
  val xxr = f_add(f_mul(y, sn), f_mul(x, cs))
in
  f_add(f_mul(yyr, yyr), f_mul(xxr, xxr))
end

fn calculate_rr(xp: int, yp: int, x: float, y: float, aspect_ratio: float,
                sn: float, cs: float, one_over_radius2: float): float = let
  val yy = f_sub(f_add(g0int2float_int_float(yp), 0.5f), y)
  val xx = f_sub(f_add(g0int2float_int_float(xp), 0.5f), x)
  val yyr = f_mul(f_sub(f_mul(yy, cs), f_mul(xx, sn)), aspect_ratio)
  val xxr = f_add(f_mul(yy, sn), f_mul(xx, cs))
  val dist2 = f_add(f_mul(yyr, yyr), f_mul(xxr, xxr))
in
  f_mul(dist2, one_over_radius2)
end

fn sign_point_in_line(px: float, py: float, vx: float, vy: float): float =
  f_sub(f_mul(f_sub(px, vx), f_sub(0.0f, vy)), f_mul(vx, f_sub(py, vy)))

fn closest_point_to_line(lx: float, ly: float, px: float, py: float,
                         ox: &float? >> float, oy: &float? >> float): void = let
  val l2 = f_add(f_mul(lx, lx), f_mul(ly, ly))
  val ltp_dot = f_add(f_mul(px, lx), f_mul(py, ly))
  val t = f_div(ltp_dot, l2)
  val () = ox := f_mul(lx, t)
  val () = oy := f_mul(ly, t)
in () end

fn compute_nearest_sample(
  cs: float, sn: float, pl: float, pr: float, pt: float, pb: float,
  pcx: float, pcy: float, ar: float, inv_r2: float
): @(float, float, float, float) =
  if f_lt(pl, 0.0f) && f_gt(pr, 0.0f) && f_lt(pt, 0.0f) && f_gt(pb, 0.0f) then
    @(0.0f, 0.0f, 0.0f, 0.0f)
  else let
    var nx: float
    var ny: float
    val () = closest_point_to_line(cs, sn, pcx, pcy, nx, ny)
    val cl_x = f_clamp(nx, pl, pr)
    val cl_y = f_clamp(ny, pt, pb)
    val rn = calculate_r_sample(cl_x, cl_y, ar, sn, cs)
  in
    @(cl_x, cl_y, rn, f_mul(rn, inv_r2))
  end

fn calculate_rr_antialiased(
  xp: int, yp: int, x: float, y: float, ar: float,
  sn: float, cs: float, inv_r2: float, r_aa_start: float
): float = let
  val pr = f_sub(x, g0int2float_int_float(xp))
  val pb = f_sub(y, g0int2float_int_float(yp))
  val pcx = f_sub(pr, 0.5f)
  val pcy = f_sub(pb, 0.5f)
  val @(near_x, near_y, r_near, rr_near) = compute_nearest_sample(
    cs, sn, f_sub(pr, 1.0f), pr, f_sub(pb, 1.0f), pb, pcx, pcy, ar, inv_r2
  )
in
  if f_gt(rr_near, 1.0f) then rr_near
  else let
    val c_sign = sign_point_in_line(pcx, pcy, cs, f_sub(0.0f, sn))
    val rad_a1 = 0.5641895835477563f
    val fx = if f_lt(c_sign, 0.0f) then f_sub(near_x, f_mul(sn, rad_a1)) else f_add(near_x, f_mul(sn, rad_a1))
    val fy = if f_lt(c_sign, 0.0f) then f_add(near_y, f_mul(cs, rad_a1)) else f_sub(near_y, f_mul(cs, rad_a1))
    val r_far = calculate_r_sample(fx, fy, ar, sn, cs)
    val rr_far = f_mul(r_far, inv_r2)
  in
    if f_lt(r_far, r_aa_start) then f_mul(f_add(rr_far, rr_near), 0.5f)
    else f_sub(1.0f, f_div(f_sub(1.0f, rr_near), f_add(1.0f, f_sub(rr_far, rr_near))))
  end
end

fn calculate_opa(
  rr: float, hardness: float,
  s1_off: float, s1_slope: float, s2_off: float, s2_slope: float
): float = let
  val fac = if f_lte(rr, hardness) then s1_slope else s2_slope
  val base_off = if f_lte(rr, hardness) then s1_off else s2_off
  val opa = f_add(base_off, f_mul(rr, fac))
in
  if f_gt(rr, 1.0f) then 0.0f
  else if f_lt(opa, 0.0f) then 0.0f
  else if f_gt(opa, 1.0f) then 1.0f
  else opa
end

fn compute_dab_segments(h: float, s: float): @(float, float, float, float) = let
  val s1_off = f_mul(1.0f, f_sub(1.0f, s))
  val s1_slope = f_mul(f_sub(0.0f, f_sub(f_div(1.0f, h), 1.0f)), f_sub(1.0f, s))
  val s2_off = f_mul(f_div(h, f_sub(1.0f, h)), f_sub(1.0f, s))
  val s2_slope = f_mul(f_sub(0.0f, f_div(h, f_sub(1.0f, h))), f_sub(1.0f, s))
in
  @(s1_off, s1_slope, s2_off, s2_slope)
end

fn compute_dab_bounds(x: float, y: float, radius: float): @(int, int, int, int) = let
  val r_fringe = f_add(radius, 1.0f)
  val x0 = i_max(0, g0float2int_float_int(floorf(f_sub(x, r_fringe))))
  val y0 = i_max(0, g0float2int_float_int(floorf(f_sub(y, r_fringe))))
  val x1 = i_min(MINEPAINT_TILE_SIZE - 1, g0float2int_float_int(floorf(f_add(x, r_fringe))))
  val y1 = i_min(MINEPAINT_TILE_SIZE - 1, g0float2int_float_int(floorf(f_add(y, r_fringe))))
in
  @(x0, y0, x1, y1)
end

fn u16s(m: U16Buf, i: int, v: uint16): void = mp_arr_u16set(u16buf_ptr(m), i, v)
fn fsetm(m: FltBuf, i: int, v: float): void = mp_arr_fset(flt_ptr(m), i, v)
fn fgetm(m: FltBuf, i: int): float = mp_arr_fget(flt_ptr(m), i)

fun fill_rr_aa(
  rr_mask: FltBuf, x0: int, y0: int, x1: int, y1: int,
  x: float, y: float, ar: float, sn: float, cs: float,
  inv_r2: float, r_aa_start: float
): void = let
  fun loop_y(yp: int): void =
    if yp <= y1 then let
      fun loop_x(xp: int): void =
        if xp <= x1 then let
          val rr = calculate_rr_antialiased(xp, yp, x, y, ar, sn, cs, inv_r2, r_aa_start)
          val () = fsetm(rr_mask, yp * MINEPAINT_TILE_SIZE + xp, rr)
        in loop_x(xp + 1) end
      val () = loop_x(x0)
    in loop_y(yp + 1) end
in
  loop_y(y0)
end

fun fill_rr_std(
  rr_mask: FltBuf, x0: int, y0: int, x1: int, y1: int,
  x: float, y: float, ar: float, sn: float, cs: float, inv_r2: float
): void = let
  fun loop_y(yp: int): void =
    if yp <= y1 then let
      fun loop_x(xp: int): void =
        if xp <= x1 then let
          val rr = calculate_rr(xp, yp, x, y, ar, sn, cs, inv_r2)
          val () = fsetm(rr_mask, yp * MINEPAINT_TILE_SIZE + xp, rr)
        in loop_x(xp + 1) end
      val () = loop_x(x0)
    in loop_y(yp + 1) end
in
  loop_y(y0)
end

fn write_rle_skip(mask: U16Buf, o_idx: int, s_acc: int): int =
  if s_acc > 0 then let
    val () = u16s(mask, o_idx, u16(0U))
    val () = u16s(mask, o_idx + 1, u16(g0int2uint_int_uint(s_acc * 4)))
  in
    o_idx + 2
  end
  else o_idx

fun encode_rle_row(
  mask: U16Buf, rr_mask: FltBuf, yp: int, xp: int, x1: int,
  h: float, s1_off: float, s1_sl: float, s2_off: float, s2_sl: float,
  s_acc: int, o_idx: int
): @(int, int) =
  if xp <= x1 then let
    val rr = fgetm(rr_mask, yp * MINEPAINT_TILE_SIZE + xp)
    val opa = calculate_opa(rr, h, s1_off, s1_sl, s2_off, s2_sl)
    val opa_i = g0float2int_float_int(f_mul(opa, 32768.0f))
  in
    if opa_i <= 0 then
      encode_rle_row(mask, rr_mask, yp, xp + 1, x1, h, s1_off, s1_sl, s2_off, s2_sl, s_acc + 1, o_idx)
    else let
      val next_o = write_rle_skip(mask, o_idx, s_acc)
      val () = u16s(mask, next_o, u16(g0int2uint_int_uint(opa_i)))
    in
      encode_rle_row(mask, rr_mask, yp, xp + 1, x1, h, s1_off, s1_sl, s2_off, s2_sl, 0, next_o + 1)
    end
  end
  else @(s_acc, o_idx)

fun encode_rle_mask(
  mask: U16Buf, rr_mask: FltBuf, yp: int, y1: int, x0: int, x1: int,
  h: float, s1_off: float, s1_sl: float, s2_off: float, s2_sl: float,
  cur_skip: int, out_idx: int
): int =
  if yp <= y1 then let
    val @(s_row, next_out) = encode_rle_row(
      mask, rr_mask, yp, x0, x1, h, s1_off, s1_sl, s2_off, s2_sl, cur_skip + x0, out_idx
    )
    val s_next = s_row + (MINEPAINT_TILE_SIZE - (x1 + 1))
  in
    encode_rle_mask(mask, rr_mask, yp + 1, y1, x0, x1, h, s1_off, s1_sl, s2_off, s2_sl, s_next, next_out)
  end
  else out_idx

extern fun render_dab_mask(
  mask: U16Buf, x: float, y: float, radius: float,
  hardness: float, softness: float, aspect_ratio: float, angle: float
): void = "ext#render_dab_mask"
implement render_dab_mask(mask, x, y, radius, hardness, softness, aspect_ratio, angle) = let
  val h = f_clamp(hardness, 0.0001f, 1.0f)
  val ar = if f_lt(aspect_ratio, 1.0f) then 1.0f else aspect_ratio
  val s = f_clamp(softness, 0.0f, 0.9999f)
  val @(s1_off, s1_slope, s2_off, s2_slope) = compute_dab_segments(h, s)
  val angle_rad = f_mul(f_div(angle, 360.0f), 6.283185307179586f)
  val cs = cosf(angle_rad)
  val sn = sinf(angle_rad)
  val @(x0, y0, x1, y1) = compute_dab_bounds(x, y, radius)
  val inv_r2 = f_div(1.0f, f_mul(radius, radius))
  val sz_rr = (MINEPAINT_TILE_SIZE * MINEPAINT_TILE_SIZE + 2 * MINEPAINT_TILE_SIZE) * 4
  val rr_raw = malloc(int2size(sz_rr))
  val () = assertloc(rr_raw > the_null_ptr)
  val rr_mask = flt_of(rr_raw)
  val () =
    if f_lt(radius, 3.0f) then let
      val r_base = if f_gt(radius, 1.0f) then f_sub(radius, 1.0f) else 0.0f
      val r_aa_start = f_div(f_mul(r_base, r_base), ar)
    in
      fill_rr_aa(rr_mask, x0, y0, x1, y1, x, y, ar, sn, cs, inv_r2, r_aa_start)
    end
    else fill_rr_std(rr_mask, x0, y0, x1, y1, x, y, ar, sn, cs, inv_r2)
  val final_out = encode_rle_mask(
    mask, rr_mask, y0, y1, x0, x1, h, s1_off, s1_slope, s2_off, s2_slope, y0 * MINEPAINT_TILE_SIZE, 0
  )
  val () = u16s(mask, final_out, u16(0U))
  val () = u16s(mask, final_out + 1, u16(0U))
in
  free(rr_raw)
end

fn apply_non_paint_normal(
  mask: U16Buf, rgba_p: U16Buf, op_rec: OperationDataDrawDab, paint: float
): void =
  if f_gt(op_rec.normal, 0.0f) then let
    val opaq_norm = f_mul(f_mul(op_rec.normal, op_rec.opaque), f_mul(f_sub(1.0f, paint), 32768.0f))
    val opaq_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(opaq_norm)))
    val cr = i2u16(op_rec.color_r)
    val cg = i2u16(op_rec.color_g)
    val cb = i2u16(op_rec.color_b)
  in
    if f_gte(op_rec.color_a, 1.0f) then
      draw_dab_pixels_BlendMode_Normal(mask, rgba_p, cr, cg, cb, opaq_u16)
    else let
      val ca_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(f_mul(op_rec.color_a, 32768.0f))))
    in
      draw_dab_pixels_BlendMode_Normal_and_Eraser(mask, rgba_p, cr, cg, cb, ca_u16, opaq_u16)
    end
  end

fn apply_non_paint_lock_alpha(
  mask: U16Buf, rgba_p: U16Buf, op_rec: OperationDataDrawDab, paint: float
): void =
  if (f_gt(op_rec.lock_alpha, 0.0f)) * (op_rec.color_a != 0.0f) then let
    val la_fac = f_mul(f_mul(op_rec.lock_alpha, op_rec.opaque), f_mul(f_sub(1.0f, op_rec.colorize), f_sub(1.0f, op_rec.posterize)))
    val la_norm = f_mul(f_mul(la_fac, f_sub(1.0f, paint)), 32768.0f)
    val la_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(la_norm)))
  in
    draw_dab_pixels_BlendMode_LockAlpha(mask, rgba_p, i2u16(op_rec.color_r), i2u16(op_rec.color_g), i2u16(op_rec.color_b), la_u16)
  end

fn apply_paint_normal(
  mask: U16Buf, rgba_p: U16Buf, op_rec: OperationDataDrawDab, paint: float
): void =
  if f_gt(op_rec.normal, 0.0f) then let
    val opaq_norm = f_mul(f_mul(op_rec.normal, op_rec.opaque), f_mul(paint, 32768.0f))
    val opaq_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(opaq_norm)))
    val cr = i2u16(op_rec.color_r)
    val cg = i2u16(op_rec.color_g)
    val cb = i2u16(op_rec.color_b)
  in
    if f_gte(op_rec.color_a, 1.0f) then
      draw_dab_pixels_BlendMode_Normal_Paint(mask, rgba_p, cr, cg, cb, opaq_u16)
    else let
      val ca_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(f_mul(op_rec.color_a, 32768.0f))))
    in
      draw_dab_pixels_BlendMode_Normal_and_Eraser_Paint(mask, rgba_p, cr, cg, cb, ca_u16, opaq_u16)
    end
  end

fn apply_paint_lock_alpha(
  mask: U16Buf, rgba_p: U16Buf, op_rec: OperationDataDrawDab, paint: float
): void =
  if (f_gt(op_rec.lock_alpha, 0.0f)) * (op_rec.color_a != 0.0f) then let
    val la_fac = f_mul(f_mul(op_rec.lock_alpha, op_rec.opaque), f_mul(f_sub(1.0f, op_rec.colorize), f_sub(1.0f, op_rec.posterize)))
    val la_norm = f_mul(f_mul(la_fac, paint), 32768.0f)
    val la_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(la_norm)))
  in
    draw_dab_pixels_BlendMode_LockAlpha_Paint(mask, rgba_p, i2u16(op_rec.color_r), i2u16(op_rec.color_g), i2u16(op_rec.color_b), la_u16)
  end

fn apply_colorize_posterize(mask: U16Buf, rgba_p: U16Buf, op_rec: OperationDataDrawDab): void = let
  val () =
    if f_gt(op_rec.colorize, 0.0f) then let
      val c_norm = f_mul(f_mul(op_rec.colorize, op_rec.opaque), 32768.0f)
      val c_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(c_norm)))
    in
      draw_dab_pixels_BlendMode_Color(mask, rgba_p, i2u16(op_rec.color_r), i2u16(op_rec.color_g), i2u16(op_rec.color_b), c_u16)
    end
  val () =
    if f_gt(op_rec.posterize, 0.0f) then let
      val p_norm = f_mul(f_mul(op_rec.posterize, op_rec.opaque), 32768.0f)
      val p_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(p_norm)))
      val pnum_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(op_rec.posterize_num)))
    in
      draw_dab_pixels_BlendMode_Posterize(mask, rgba_p, p_u16, pnum_u16)
    end
in () end

extern fun process_op(rgba_p: U16Buf, mask: U16Buf, tx: int, ty: int, op_h: int): void = "ext#process_op"
implement process_op(rgba_p, mask, tx, ty, op_h) =
  if (u16buf_is_null(rgba_p) = 0) * (op_h >= 0) then let
    val op_rec = dab_get(op_h)
    val ox = f_sub(op_rec.x, g0int2float_int_float(tx * MINEPAINT_TILE_SIZE))
    val oy = f_sub(op_rec.y, g0int2float_int_float(ty * MINEPAINT_TILE_SIZE))
    val () = render_dab_mask(
      mask, ox, oy, op_rec.radius, op_rec.hardness, op_rec.softness,
      op_rec.aspect_ratio, op_rec.angle
    )
    val paint = op_rec.paint
    val () = if f_lt(paint, 1.0f) then {
      val () = apply_non_paint_normal(mask, rgba_p, op_rec, paint)
      val () = apply_non_paint_lock_alpha(mask, rgba_p, op_rec, paint)
    }
    val () = if f_gt(paint, 0.0f) then {
      val () = apply_paint_normal(mask, rgba_p, op_rec, paint)
      val () = apply_paint_lock_alpha(mask, rgba_p, op_rec, paint)
    }
  in
    apply_colorize_posterize(mask, rgba_p, op_rec)
  end

fun drain_op_queue(q: int, rgba_p: U16Buf, mask: U16Buf, tx: int, ty: int, cur_op: int): void =
  if cur_op >= 0 then let
    val () = process_op(rgba_p, mask, tx, ty, cur_op)
    val () = dab_release(cur_op)
    val next_op = operation_queue_pop(q, tx, ty)
  in
    drain_op_queue(q, rgba_p, mask, tx, ty, next_op)
  end

extern fun process_tile(self_p: ptr, tx: int, ty: int): void = "ext#process_tile"
implement process_tile(self_p, tx, ty) =
  if self_p != the_null_ptr then let
    val self = view_tiled(self_p)
    val op_first = operation_queue_pop(self->operation_queue, tx, ty)
  in
    if op_first >= 0 then let
      val req_mem = malloc(sizeof<MinePaintTileRequest>)
      val () = assertloc(req_mem > the_null_ptr)
      val () = minepaint_tile_request_init(req_mem, 0, tx, ty, false)
      val () = minepaint_tiled_surface_tile_request_start(self_p, req_mem)
      val rgba_raw = (view_tile_req(req_mem))->buffer
    in
      if rgba_raw = the_null_ptr then {
        val () = dab_release(op_first)
        val () = free(req_mem)
      } else let
        val mask_sz = (MINEPAINT_TILE_SIZE * MINEPAINT_TILE_SIZE + 2 * MINEPAINT_TILE_SIZE) * 2
        val mask_raw = malloc(int2size(mask_sz))
        val () = assertloc(mask_raw > the_null_ptr)
        val () = drain_op_queue(self->operation_queue, u16buf_of(rgba_raw), u16buf_of(mask_raw), tx, ty, op_first)
        val () = free(mask_raw)
        val () = minepaint_tiled_surface_tile_request_end(self_p, req_mem)
      in
        free(req_mem)
      end
    end
  end

fn realloc_bounding_boxes(self: ref(MinePaintTiledSurface), num_desired: int): void =
  if g0int_gt(num_desired, self->num_bboxes) then let
    val num_to_alloc = g0int_add(num_desired, 10)
    val new_boxes = bbox_buf_new(num_to_alloc)
    val () = if self->bboxes != self->default_bboxes then bbox_buf_release(self->bboxes)
    val () = self->bboxes := new_boxes
    val () = self->num_bboxes := num_to_alloc
  in
    self->num_bboxes_dirtied := 0
  end

fun clean_bounding_boxes(bboxes: int, i: int, n: int): void =
  if i < n then let
    val () = bbox_clear(bboxes, i)
  in
    clean_bounding_boxes(bboxes, i + 1, n)
  end

fun clean_roi_rects(rects: RectRun, i: int, n: int): void =
  if i < n then let
    val dest = rectrun_add(rects, g0int_mul(i, 16))
    val () = minepaint_rectangle_clear(rect_of(rectrun_ptr(dest)))
  in
    clean_roi_rects(rects, i + 1, n)
  end

fn prepare_bounding_boxes(self_p: ptr): void =
  if self_p != the_null_ptr then let
    val self = view_tiled(self_p)
    val h = self->symmetry_data
    val ty = minepaint_symmetry_current_type(h)
    val nl = minepaint_symmetry_current_lines(h)
    val mult = (if ty = 4 then 2 else 1): int
    val num_desired = g0int_mul(g0float2int_float_int(nl), mult)
    val () = realloc_bounding_boxes(self, num_desired)
    val n_clean = i_min(self->num_bboxes, self->num_bboxes_dirtied)
    val () = clean_bounding_boxes(self->bboxes, 0, n_clean)
  in
    self->num_bboxes_dirtied := 0
  end

extern fun minepaint_tiled_surface_begin_atomic(self_p: ptr): void = "ext#minepaint_tiled_surface_begin_atomic"
implement minepaint_tiled_surface_begin_atomic(self_p) =
  if self_p != the_null_ptr then let
    val symm_ptr = get_tiled_surface_symmetry_data(self_p)
    val () = minepaint_update_symmetry_state(symm_ptr)
  in
    prepare_bounding_boxes(self_p)
  end

fun process_dirty_tile_list(self_p: ptr, t_ptr: IntBuf, i: int, n: int): void =
  if i < n then let
    val t = get_dirty_tile(t_ptr, i)
    val () = process_tile(self_p, t.0, t.1)
  in
    process_dirty_tile_list(self_p, t_ptr, i + 1, n)
  end

fun export_roi_rects(
  roi: ref(MinePaintRectangles), bboxes: int, i: int, num_dirty: int,
  roi_rects: int, factor: float
): void =
  if i < num_dirty then let
    val out_idx =
      if num_dirty > roi_rects then
        i_min(roi_rects - 1, g0float2int_float_int(roundf(f_div(g0int2float_int_float(i), factor))))
      else i
    val dest = rectrun_add(rectrun_of(roi->rectangles), g0int_mul(out_idx, 16))
    val () = minepaint_rectangle_expand_to_include_value(rect_of(rectrun_ptr(dest)), bbox_get(bboxes, i))
  in
    export_roi_rects(roi, bboxes, i + 1, num_dirty, roi_rects, factor)
  end

extern fun minepaint_tiled_surface_end_atomic(self_p: ptr, roi_p: ptr): void = "ext#minepaint_tiled_surface_end_atomic"
implement minepaint_tiled_surface_end_atomic(self_p, roi_p) =
  if self_p != the_null_ptr then let
    val self = view_tiled(self_p)
    var tiles_ptr: ptr
    val tiles_n = operation_queue_get_dirty_tiles(self->operation_queue, tiles_ptr)
    val () = process_dirty_tile_list(self_p, intbuf_of(tiles_ptr), 0, tiles_n)
    val () = operation_queue_clear_dirty_tiles(self->operation_queue)
    val () =
      if roi_p != the_null_ptr then let
        val roi = view_rects(roi_p)
        val num_dirty = self->num_bboxes_dirtied
        val () = clean_roi_rects(rectrun_of(roi->rectangles), 0, i_min(roi->num_rectangles, num_dirty))
        val bpo = if roi->num_rectangles > 0 then f_div(g0int2float_int_float(num_dirty), g0int2float_int_float(roi->num_rectangles)) else 1.0f
        val factor = if f_lt(bpo, 1.0f) then 1.0f else bpo
        val () = export_roi_rects(roi, self->bboxes, 0, num_dirty, roi->num_rectangles, factor)
      in
        roi->num_rectangles := i_min(roi->num_rectangles, num_dirty)
      end
  in () end

fn make_dab(
  x: float, y: float, radius: float,
  ar: float, angle: float, opaque: float, hardness: float, softness: float,
  lock_alpha: float, colorize: float, posterize: float, p_num: float, paint: float,
  color_r: float, color_g: float, color_b: float, color_a: float
): OperationDataDrawDab = let
  val lock_a = f_clamp(lock_alpha, 0.0f, 1.0f)
  val col = f_clamp(colorize, 0.0f, 1.0f)
  val post = f_clamp(posterize, 0.0f, 1.0f)
in @{
  x= x, y= y, radius= radius,
  color_r= g0float2int_float_int(f_mul(f_clamp(color_r, 0.0f, 1.0f), 32768.0f)),
  color_g= g0float2int_float_int(f_mul(f_clamp(color_g, 0.0f, 1.0f), 32768.0f)),
  color_b= g0float2int_float_int(f_mul(f_clamp(color_b, 0.0f, 1.0f), 32768.0f)),
  color_a= f_clamp(color_a, 0.0f, 1.0f),
  opaque= f_clamp(opaque, 0.0f, 1.0f),
  hardness= f_clamp(hardness, 0.0f, 1.0f),
  softness= f_clamp(softness, 0.0f, 1.0f),
  aspect_ratio= (if f_lt(ar, 1.0f) then 1.0f else ar),
  angle= angle,
  normal= f_mul(f_mul(f_sub(1.0f, lock_a), f_sub(1.0f, col)), f_sub(1.0f, post)),
  lock_alpha= lock_a,
  colorize= col,
  posterize= post,
  posterize_num= f_clamp(roundf(f_mul(p_num, 100.0f)), 1.0f, 128.0f),
  paint= f_clamp(paint, 0.0f, 1.0f)
} end

fun queue_dab_tiles(
  q: int, src: int, ty: int, ty2: int, tx1: int, tx2: int
): void =
  if ty <= ty2 then let
    fun loop_tx(tx: int): void =
      if tx <= tx2 then let
        val () = operation_queue_add(q, tx, ty, dab_clone(src))
      in loop_tx(tx + 1) end
    val () = loop_tx(tx1)
  in
    queue_dab_tiles(q, src, ty + 1, ty2, tx1, tx2)
  end

fn update_dab_bbox(self: ref(MinePaintTiledSurface), bbox_index: int, x: float, y: float, rf: float): void = let
  val bb_x = g0float2int_float_int(floorf(f_sub(x, rf)))
  val bb_y = g0float2int_float_int(floorf(f_sub(y, rf)))
  val bb_w = g0float2int_float_int(floorf(f_add(x, rf))) - bb_x + 1
  val bb_h = g0float2int_float_int(floorf(f_add(y, rf))) - bb_y + 1
  val () = bbox_expand_point(self->bboxes, bbox_index, bb_x, bb_y)
in
  bbox_expand_point(self->bboxes, bbox_index, bb_x + bb_w - 1, bb_y + bb_h - 1)
end

fn draw_dab_internal(
  self_p: ptr, x: float, y: float, radius: float,
  color_r: float, color_g: float, color_b: float,
  opaque: float, hardness: float, softness: float,
  color_a: float, aspect_ratio: float, angle: float,
  lock_alpha: float, colorize: float, posterize: float,
  posterize_num: float, paint: float, bbox_index: int
): bool =
  if f_lt(radius, 0.1f) || f_lte(hardness, 0.0f) || f_gte(softness, 1.0f) || f_lte(opaque, 0.0f) then false
  else let
    val self = view_tiled(self_p)
    val src = dab_new(make_dab(
      x, y, radius, aspect_ratio, angle, opaque, hardness, softness,
      lock_alpha, colorize, posterize, posterize_num, paint,
      color_r, color_g, color_b, color_a
    ))
    val rf = f_add(radius, 1.0f)
    val tx1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(x, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val tx2 = g0float2int_float_int(floorf(f_div(floorf(f_add(x, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val ty1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(y, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val ty2 = g0float2int_float_int(floorf(f_div(floorf(f_add(y, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val () = queue_dab_tiles(self->operation_queue, src, ty1, ty2, tx1, tx2)
    val () = update_dab_bbox(self, bbox_index, x, y, rf)
    val () = dab_release(src)
  in
    true
  end

fn transform_and_draw(
  surface: ptr, sym: int, midx: int, x: float, y: float, radius: float,
  color_r: float, color_g: float, color_b: float,
  opaque: float, hardness: float, softness: float,
  color_a: float, aspect_ratio: float, dab_angle: float,
  lock_alpha: float, colorize: float, posterize: float,
  posterize_num: float, paint: float, bbox_index: int
): void = let
  val t = minepaint_symmetry_matrix_get(sym, midx)
  val tx = mat_apply_x(t, x, y)
  val ty = mat_apply_y(t, x, y)
  val _ = draw_dab_internal(
    surface, tx, ty, radius, color_r, color_g, color_b,
    opaque, hardness, softness, color_a, aspect_ratio, dab_angle,
    lock_alpha, colorize, posterize, posterize_num, paint, bbox_index
  )
in () end

fn draw_verthorz_symmetry(
  surface: ptr, sym: int, x: float, y: float, radius: float,
  cr: float, cg: float, cb: float, opaq: float, h: float, s: float,
  ca: float, ar: float, angle: float, symm_angle: float,
  la: float, col: float, post: float, pnum: float, paint: float
): void = let
  val a_sub = f_sub(f_mul(~2.0f, symm_angle), angle)
  val () = transform_and_draw(surface, sym, 0, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, a_sub, la, col, post, pnum, paint, 1)
  val () = transform_and_draw(surface, sym, 1, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, angle, la, col, post, pnum, paint, 2)
in
  transform_and_draw(surface, sym, 2, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, a_sub, la, col, post, pnum, paint, 3)
end

fun draw_rot_symmetry(
  surface: ptr, sym: int, c: int, n: int, x: float, y: float, radius: float,
  cr: float, cg: float, cb: float, opaq: float, h: float, s: float,
  ca: float, ar: float, angle: float, rot_a: float,
  la: float, col: float, post: float, pnum: float, paint: float
): void =
  if c < n then let
    val da = f_sub(angle, f_mul(g0int2float_int_float(c), rot_a))
    val () = transform_and_draw(surface, sym, c - 1, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, da, la, col, post, pnum, paint, c)
  in
    draw_rot_symmetry(surface, sym, c + 1, n, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, angle, rot_a, la, col, post, pnum, paint)
  end

fun draw_snow_symmetry(
  surface: ptr, sym: int, c: int, n: int, base_idx: int, x: float, y: float, radius: float,
  cr: float, cg: float, cb: float, opaq: float, h: float, s: float,
  ca: float, ar: float, base_a: float, rot_a: float,
  la: float, col: float, post: float, pnum: float, paint: float
): void =
  if c < n then let
    val da = f_sub(base_a, f_mul(g0int2float_int_float(c), rot_a))
    val () = transform_and_draw(surface, sym, base_idx + c, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, da, la, col, post, pnum, paint, n + c)
  in
    draw_snow_symmetry(surface, sym, c + 1, n, base_idx, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, base_a, rot_a, la, col, post, pnum, paint)
  end

fn dispatch_symmetry_dab(
  surface: ptr, self: ref(MinePaintTiledSurface), sym: int,
  x: float, y: float, radius: float, cr: float, cg: float, cb: float,
  opaq: float, h: float, s: float, ca: float, ar: float, angle: float,
  la: float, col: float, post: float, pnum: float, paint: float
): void =
  if (minepaint_symmetry_active(sym) > 0) * (minepaint_symmetry_matrix_count(sym) > 0) then let
    val ty = minepaint_symmetry_current_type(sym)
    val lines_f = minepaint_symmetry_current_lines(sym)
    val ang = minepaint_symmetry_current_angle(sym)
    val lines = g0float2int_float_int(lines_f)
    val rot_a = f_div(360.0f, lines_f)
  in
    case+ ty of
    | 0 => let
        val a_vert = f_sub(f_mul(~2.0f, f_add(90.0f, ang)), angle)
        val () = transform_and_draw(surface, sym, 0, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, a_vert, la, col, post, pnum, paint, 1)
      in
        self->num_bboxes_dirtied := i_min(self->num_bboxes, 2)
      end
    | 1 => let
        val a_horz = f_sub(f_mul(~2.0f, ang), angle)
        val () = transform_and_draw(surface, sym, 0, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, a_horz, la, col, post, pnum, paint, 1)
      in
        self->num_bboxes_dirtied := i_min(self->num_bboxes, 2)
      end
    | 2 => let
        val () = draw_verthorz_symmetry(surface, sym, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, angle, ang, la, col, post, pnum, paint)
      in
        self->num_bboxes_dirtied := i_min(self->num_bboxes, 4)
      end
    | 3 => let
        val () = draw_rot_symmetry(surface, sym, 1, lines, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, angle, rot_a, la, col, post, pnum, paint)
      in
        self->num_bboxes_dirtied := i_min(self->num_bboxes, lines)
      end
    | 4 => let
        val mirrored = f_sub(f_mul(~2.0f, ang), angle)
        val () = draw_snow_symmetry(surface, sym, 0, lines, lines - 1, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, mirrored, rot_a, la, col, post, pnum, paint)
        val () = draw_rot_symmetry(surface, sym, 1, lines, x, y, radius, cr, cg, cb, opaq, h, s, ca, ar, angle, rot_a, la, col, post, pnum, paint)
      in
        self->num_bboxes_dirtied := i_min(self->num_bboxes, lines * 2)
      end
    | _ => ()
  end
  else self->num_bboxes_dirtied := 1

extern fun tiled_surface_draw_dab(
  surface: ptr, x: float, y: float, radius: float,
  color_r: float, color_g: float, color_b: float,
  opaque: float, hardness: float, softness: float,
  color_a: float, aspect_ratio: float, angle: float,
  lock_alpha: float, colorize: float, posterize: float,
  posterize_num: float, paint: float
): int = "ext#tiled_surface_draw_dab"
implement tiled_surface_draw_dab(
  surface, x, y, radius, color_r, color_g, color_b,
  opaque, hardness, softness, color_a, aspect_ratio, angle,
  lock_alpha, colorize, posterize, posterize_num, paint
) = let
  val modified = draw_dab_internal(
    surface, x, y, radius, color_r, color_g, color_b,
    opaque, hardness, softness, color_a, aspect_ratio, angle,
    lock_alpha, colorize, posterize, posterize_num, paint, 0
  )
in
  if modified then let
    val self = view_tiled(surface)
    val () = dispatch_symmetry_dab(
      surface, self, self->symmetry_data, x, y, radius, color_r, color_g, color_b,
      opaque, hardness, softness, color_a, aspect_ratio, angle,
      lock_alpha, colorize, posterize, posterize_num, paint
    )
  in 1 end
  else 0
end

fn sample_tile_color(
  surface: ptr, tx: int, ty: int, x: float, y: float, rad: float,
  mask: U16Buf, pw: FCell, pr: FCell, pg: FCell, pb: FCell, pa: FCell,
  paint: float, s_u16: uint16, rate: float
): void = let
  val () = process_tile(surface, tx, ty)
  val req_mem = malloc(sizeof<MinePaintTileRequest>)
  val () = assertloc(req_mem > the_null_ptr)
  val () = minepaint_tile_request_init(req_mem, 0, tx, ty, true)
  val () = minepaint_tiled_surface_tile_request_start(surface, req_mem)
  val rgba_raw = (view_tile_req(req_mem))->buffer
in
  if rgba_raw != the_null_ptr then let
    val ox = f_sub(x, g0int2float_int_float(tx * MINEPAINT_TILE_SIZE))
    val oy = f_sub(y, g0int2float_int_float(ty * MINEPAINT_TILE_SIZE))
    val () = render_dab_mask(mask, ox, oy, rad, 0.5f, 0.5f, 1.0f, 0.0f)
    val () = get_color_pixels_accumulate(mask, u16buf_of(rgba_raw), pw, pr, pg, pb, pa, paint, s_u16, rate)
    val () = minepaint_tiled_surface_tile_request_end(surface, req_mem)
  in free(req_mem) end
  else free(req_mem)
end

fun collect_color_samples(
  surface: ptr, ty: int, ty2: int, tx1: int, tx2: int,
  x: float, y: float, rad: float, mask: U16Buf,
  pw: FCell, pr: FCell, pg: FCell, pb: FCell, pa: FCell,
  paint: float, s_u16: uint16, rate: float
): void =
  if ty <= ty2 then let
    fun loop_tx(tx: int): void =
      if tx <= tx2 then let
        val () = sample_tile_color(surface, tx, ty, x, y, rad, mask, pw, pr, pg, pb, pa, paint, s_u16, rate)
      in loop_tx(tx + 1) end
    val () = loop_tx(tx1)
  in
    collect_color_samples(surface, ty + 1, ty2, tx1, tx2, x, y, rad, mask, pw, pr, pg, pb, pa, paint, s_u16, rate)
  end

fn finalize_sampled_color(
  pw: FCell, pr: FCell, pg: FCell, pb: FCell, pa: FCell, paint: float,
  cr: &float? >> float, cg: &float? >> float, cb: &float? >> float, ca: &float? >> float
): void = let
  val sum_w = mp_arr_fget(fcell_ptr(pw), 0)
  val sum_r = mp_arr_fget(fcell_ptr(pr), 0)
  val sum_g = mp_arr_fget(fcell_ptr(pg), 0)
  val sum_b = mp_arr_fget(fcell_ptr(pb), 0)
  val sum_a = mp_arr_fget(fcell_ptr(pa), 0)
in
  if f_gt(sum_w, 0.0f) then let
    val sa = f_clamp(f_div(sum_a, sum_w), 0.0f, 1.0f)
    val sr = if f_lt(paint, 0.0f) then f_div(sum_r, sum_w) else sum_r
    val sg = if f_lt(paint, 0.0f) then f_div(sum_g, sum_w) else sum_g
    val sb = if f_lt(paint, 0.0f) then f_div(sum_b, sum_w) else sum_b
    val demul = if f_lt(paint, 0.0f) then (if f_gt(sa, 0.0f) then sa else 1.0f) else 1.0f
    val () = cr := f_clamp(f_div(sr, demul), 0.0f, 1.0f)
    val () = cg := f_clamp(f_div(sg, demul), 0.0f, 1.0f)
    val () = cb := f_clamp(f_div(sb, demul), 0.0f, 1.0f)
  in ca := sa end
  else {
    val () = cr := 0.0f
    val () = cg := 1.0f
    val () = cb := 0.0f
    val () = ca := 0.0f
  }
end

extern fun tiled_surface_get_color(
  surface: ptr, x: float, y: float, radius: float,
  color_r: &float? >> float, color_g: &float? >> float,
  color_b: &float? >> float, color_a: &float? >> float,
  paint: float
): void = "ext#tiled_surface_get_color"
implement tiled_surface_get_color(surface, x, y, radius, color_r, color_g, color_b, color_a, paint) = let
  val rad = if f_lt(radius, 1.0f) then 1.0f else radius
  val acc_mem = malloc(int2size(20))
  val () = assertloc(acc_mem > the_null_ptr)
  val _ = memset(acc_mem, 0, int2size(20))
  val pw = fcell_of(acc_mem)
  val pr = fcell_add(pw, 1)
  val pg = fcell_add(pw, 2)
  val pb = fcell_add(pw, 3)
  val pa = fcell_add(pw, 4)

  val s_int = if f_lte(rad, 2.0f) then 1 else g0float2int_float_int(f_mul(rad, 7.0f))
  val s_u16 = u16(g0int2uint_int_uint(s_int))
  val rate = f_div(1.0f, f_mul(7.0f, rad))
  val rf = f_add(rad, 1.0f)
  val tx1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(x, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
  val tx2 = g0float2int_float_int(floorf(f_div(floorf(f_add(x, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
  val ty1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(y, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
  val ty2 = g0float2int_float_int(floorf(f_div(floorf(f_add(y, rf)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))

  val mask_sz = (MINEPAINT_TILE_SIZE * MINEPAINT_TILE_SIZE + 2 * MINEPAINT_TILE_SIZE) * 2
  val mask_raw = malloc(int2size(mask_sz))
  val () = assertloc(mask_raw > the_null_ptr)
  val mask = u16buf_of(mask_raw)
  val () = collect_color_samples(surface, ty1, ty2, tx1, tx2, x, y, rad, mask, pw, pr, pg, pb, pa, paint, s_u16, rate)
  val () = free(mask_raw)
  val () = finalize_sampled_color(pw, pr, pg, pb, pa, paint, color_r, color_g, color_b, color_a)
in
  free(acc_mem)
end

extern fun minepaint_tiled_surface_init(
  self_p: ptr, tile_request_start: ptr, tile_request_end: ptr
): void = "ext#minepaint_tiled_surface_init"
implement minepaint_tiled_surface_init(self_p, tile_request_start, tile_request_end) =
  if self_p != the_null_ptr then let
    val self = view_tiled(self_p)
    val () = minepaint_surface_init(mp_surface_of_ptr(self_p))
    val () = self->parent.draw_dab := store_draw_dab(tiled_surface_draw_dab)
    val () = self->parent.get_color := store_get_color(tiled_surface_get_color)
    val () = self->parent.begin_atomic := store_begin(minepaint_tiled_surface_begin_atomic)
    val () = self->parent.end_atomic := store_end(minepaint_tiled_surface_end_atomic)
    val () = self->tile_request_start := tile_request_start
    val () = self->tile_request_end := tile_request_end
    val () = self->tile_size := MINEPAINT_TILE_SIZE
    val () = self->threadsafe_tile_requests := 0
    val () = self->num_bboxes := NUM_BBOXES_DEFAULT
    val () = self->num_bboxes_dirtied := 0
    val def_boxes = bbox_buf_new(NUM_BBOXES_DEFAULT)
    val () = self->default_bboxes := def_boxes
    val () = self->bboxes := def_boxes
    val () = self->symmetry_data := minepaint_symmetry_data_new()
    val () = self->operation_queue := operation_queue_new()
  in () end

extern fun minepaint_tiled_surface_destroy(self_p: ptr): void = "ext#minepaint_tiled_surface_destroy"
implement minepaint_tiled_surface_destroy(self_p) =
  if self_p != the_null_ptr then let
    val self = view_tiled(self_p)
    val () = operation_queue_free(self->operation_queue)
    val def_boxes = self->default_bboxes
    val () = if self->bboxes != def_boxes then bbox_buf_release(self->bboxes)
    val () = if def_boxes >= 0 then bbox_buf_release(def_boxes)
    val symm_h = self->symmetry_data
  in
    if symm_h >= 0 then minepaint_symmetry_data_destroy(symm_h)
  end

extern fun minepaint_tiled_surface_set_symmetry_state(
  self_p: ptr, active: bool, center_x: float, center_y: float,
  symmetry_angle: float, symmetry_type: int, rot_symmetry_lines: int
): void = "ext#minepaint_tiled_surface_set_symmetry_state"
implement minepaint_tiled_surface_set_symmetry_state(
  self_p, active, center_x, center_y, symmetry_angle, symmetry_type, rot_symmetry_lines
) =
  if self_p != the_null_ptr then let
    val symm_ptr = get_tiled_surface_symmetry_data(self_p)
  in
    minepaint_symmetry_set_pending(
      symm_ptr, active, center_x, center_y, symmetry_angle, symmetry_type, rot_symmetry_lines
    )
  end

extern fun minepaint_tiled_surface_get_alpha(self_p: ptr, x: float, y: float, radius: float): float = "ext#minepaint_tiled_surface_get_alpha"
implement minepaint_tiled_surface_get_alpha(self_p, x, y, radius) = let
  var r: float
  var g: float
  var b: float
  var a: float
  val () = tiled_surface_get_color(self_p, x, y, radius, r, g, b, a, 1.0f)
in
  a
end
