// src/draw_engine/tiled_surface.dats
// Native ATS2 implementation of MinePaint Tiled Surface
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "./rectangle.dats"
staload "./matrix.dats"
staload "./symmetry.dats"
staload "./operationqueue.dats"
staload "./brushmodes.dats"
staload "./surface.dats"
staload "./helpers.dats"

#include "./minepaint_types.hats"
#define M_PI 3.14159265358979323846f

typedef MinePaintTileRequest_struct = MinePaintTileRequest
typedef MinePaintTiledSurface_struct = MinePaintTiledSurface
typedef OperationDataDrawDab_struct = OperationDataDrawDab

typedef MinePaintTileRequestFunc = (ptr, ptr) -> void

fn call_tile_request_start(f: ptr, self: ptr, req: ptr): void =
  if f != the_null_ptr then $UN.cast{MinePaintTileRequestFunc}(f)(self, req)

fn call_tile_request_end(f: ptr, self: ptr, req: ptr): void =
  if f != the_null_ptr then $UN.cast{MinePaintTileRequestFunc}(f)(self, req)

fn get_tiled_surface_default_bboxes(self: ptr): ptr = let
  val r = $UN.cast{ref(MinePaintTiledSurface_struct)}(self)
in
  r->default_bboxes
end

fn get_tiled_surface_symmetry_data(self: ptr): ptr = let
  val r = $UN.cast{ref(MinePaintTiledSurface_struct)}(self)
in
  r->symmetry_data
end

fn u16(x: uint): uint16 = $UN.cast{uint16}(x)
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
extern fun memcpy(dest: ptr, src: ptr, sz: size_t): ptr = "mac#memcpy"
extern fun cosf(x: float): float = "mac#cosf"
extern fun sinf(x: float): float = "mac#sinf"
extern fun sqrtf(x: float): float = "mac#sqrtf"
extern fun floorf(x: float): float = "mac#floorf"
extern fun roundf(x: float): float = "mac#roundf"

fn f_clamp(x: float, min_v: float, max_v: float): float =
  if f_lt(x, min_v) then min_v else if f_gt(x, max_v) then max_v else x

fn i_min(a: int, b: int): int = if a < b then a else b
fn i_max(a: int, b: int): int = if a > b then a else b

fn get_matrix_ptr(m: ptr, idx: int): ptr =
  ptr_add<float>(m, int2size(g0int_mul(idx, 9)))

fn get_dirty_tile(dirty_tiles: ptr, idx: int): @(int, int) = let
  val p = ptr_add<int>(dirty_tiles, int2size(g0int_mul(idx, 2)))
  val x = $UN.ptr0_get<int>(p)
  val y = $UN.ptr0_get<int>(ptr_add<int>(p, int2size(1)))
in
  @(x, y)
end

// minepaint_tile_request_init
extern fun minepaint_tile_request_init(
  data_p: ptr, level: int, tx: int, ty: int, readonly: bool
): void = "ext#minepaint_tile_request_init"
implement minepaint_tile_request_init(data_p, level, tx, ty, readonly) =
  if data_p != the_null_ptr then let
    val r = $UN.cast{ref(MinePaintTileRequest_struct)}(data_p)
    val () = r->tx := tx
    val () = r->ty := ty
    val () = r->readonly := (if readonly then 1 else 0)
    val () = r->buffer := the_null_ptr
    val () = r->context := the_null_ptr
    val () = r->thread_id := ~1
    val () = r->mipmap_level := level
  in () end

// minepaint_tiled_surface_tile_request_start
extern fun minepaint_tiled_surface_tile_request_start(self_p: ptr, req_p: ptr): void = "ext#minepaint_tiled_surface_tile_request_start"
implement minepaint_tiled_surface_tile_request_start(self_p, req_p) =
  if (self_p != the_null_ptr) * (req_p != the_null_ptr) then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val f = self->tile_request_start
  in
    if f != the_null_ptr then call_tile_request_start(f, self_p, req_p)
  end

// minepaint_tiled_surface_tile_request_end
extern fun minepaint_tiled_surface_tile_request_end(self_p: ptr, req_p: ptr): void = "ext#minepaint_tiled_surface_tile_request_end"
implement minepaint_tiled_surface_tile_request_end(self_p, req_p) =
  if (self_p != the_null_ptr) * (req_p != the_null_ptr) then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val f = self->tile_request_end
  in
    if f != the_null_ptr then call_tile_request_end(f, self_p, req_p)
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

fn calculate_rr_antialiased(xp: int, yp: int, x: float, y: float, aspect_ratio: float,
                            sn: float, cs: float, one_over_radius2: float,
                            r_aa_start: float): float = let
  val px_f = g0int2float_int_float(xp)
  val py_f = g0int2float_int_float(yp)
  val pixel_right = f_sub(x, px_f)
  val pixel_bottom = f_sub(y, py_f)
  val pixel_center_x = f_sub(pixel_right, 0.5f)
  val pixel_center_y = f_sub(pixel_bottom, 0.5f)
  val pixel_left = f_sub(pixel_right, 1.0f)
  val pixel_top = f_sub(pixel_bottom, 1.0f)

  var nearest_x: float = 0.0f
  var nearest_y: float = 0.0f
  var r_near: float = 0.0f
  var rr_near: float = 0.0f

  val () =
    if f_lt(pixel_left, 0.0f) && f_gt(pixel_right, 0.0f) && f_lt(pixel_top, 0.0f) && f_gt(pixel_bottom, 0.0f) then ()
    else let
      var nx: float
      var ny: float
      val () = closest_point_to_line(cs, sn, pixel_center_x, pixel_center_y, nx, ny)
      val cl_x = f_clamp(nx, pixel_left, pixel_right)
      val cl_y = f_clamp(ny, pixel_top, pixel_bottom)
      val rn = calculate_r_sample(cl_x, cl_y, aspect_ratio, sn, cs)
      val () = nearest_x := cl_x
      val () = nearest_y := cl_y
      val () = r_near := rn
      val () = rr_near := f_mul(rn, one_over_radius2)
    in () end
in
  if f_gt(rr_near, 1.0f) then rr_near
  else let
    val center_sign = sign_point_in_line(pixel_center_x, pixel_center_y, cs, f_sub(0.0f, sn))
    val rad_area_1 = 0.5641895835477563f
    val farthest_x = if f_lt(center_sign, 0.0f) then f_sub(nearest_x, f_mul(sn, rad_area_1)) else f_add(nearest_x, f_mul(sn, rad_area_1))
    val farthest_y = if f_lt(center_sign, 0.0f) then f_add(nearest_y, f_mul(cs, rad_area_1)) else f_sub(nearest_y, f_mul(cs, rad_area_1))
    val r_far = calculate_r_sample(farthest_x, farthest_y, aspect_ratio, sn, cs)
    val rr_far = f_mul(r_far, one_over_radius2)
  in
    if f_lt(r_far, r_aa_start) then f_mul(f_add(rr_far, rr_near), 0.5f)
    else let
      val vis_near = f_sub(1.0f, rr_near)
      val delta = f_sub(rr_far, rr_near)
      val delta2 = f_add(1.0f, delta)
      val vis_near_norm = f_div(vis_near, delta2)
    in
      f_sub(1.0f, vis_near_norm)
    end
  end
end

fn calculate_opa(rr: float, hardness: float,
                 seg1_off: float, seg1_slope: float,
                 seg2_off: float, seg2_slope: float): float = let
  val fac = if f_lte(rr, hardness) then seg1_slope else seg2_slope
  val base_off = if f_lte(rr, hardness) then seg1_off else seg2_off
  val opa = f_add(base_off, f_mul(rr, fac))
in
  if f_gt(rr, 1.0f) then 0.0f
  else if f_lt(opa, 0.0f) then 0.0f
  else if f_gt(opa, 1.0f) then 1.0f
  else opa
end

// render_dab_mask: fills RLE-encoded dab mask
extern fun render_dab_mask(
  mask: ptr, x: float, y: float, radius: float,
  hardness: float, softness: float, aspect_ratio: float, angle: float
): void = "ext#render_dab_mask"
implement render_dab_mask(mask, x, y, radius, hardness, softness, aspect_ratio, angle) = let
  val h = f_clamp(hardness, 0.0001f, 1.0f)
  val ar = if f_lt(aspect_ratio, 1.0f) then 1.0f else aspect_ratio
  val s = f_clamp(softness, 0.0f, 0.9999f)

  val seg1_off = f_mul(1.0f, f_sub(1.0f, s))
  val seg1_slope = f_mul(f_sub(0.0f, f_sub(f_div(1.0f, h), 1.0f)), f_sub(1.0f, s))
  val seg2_off = f_mul(f_div(h, f_sub(1.0f, h)), f_sub(1.0f, s))
  val seg2_slope = f_mul(f_sub(0.0f, f_div(h, f_sub(1.0f, h))), f_sub(1.0f, s))

  val angle_rad = f_mul(f_div(angle, 360.0f), 6.283185307179586f)
  val cs = cosf(angle_rad)
  val sn = sinf(angle_rad)

  val r_fringe = f_add(radius, 1.0f)
  val x0_f = floorf(f_sub(x, r_fringe))
  val y0_f = floorf(f_sub(y, r_fringe))
  val x1_f = floorf(f_add(x, r_fringe))
  val y1_f = floorf(f_add(y, r_fringe))

  val x0 = i_max(0, g0float2int_float_int(x0_f))
  val y0 = i_max(0, g0float2int_float_int(y0_f))
  val x1 = i_min(MINEPAINT_TILE_SIZE - 1, g0float2int_float_int(x1_f))
  val y1 = i_min(MINEPAINT_TILE_SIZE - 1, g0float2int_float_int(y1_f))

  val one_over_radius2 = f_div(1.0f, f_mul(radius, radius))
  val sz_rr_mask = (MINEPAINT_TILE_SIZE * MINEPAINT_TILE_SIZE + 2 * MINEPAINT_TILE_SIZE) * 4
  val rr_mask = malloc(int2size(sz_rr_mask))
  val () = assertloc(rr_mask > the_null_ptr)

  // Compute rr_mask grid
  val () =
    if f_lt(radius, 3.0f) then let
      val aa_border = 1.0f
      val r_base = if f_gt(radius, aa_border) then f_sub(radius, aa_border) else 0.0f
      val r_aa_start = f_div(f_mul(r_base, r_base), ar)
      fun loop_y(yp: int): void =
        if yp <= y1 then let
          fun loop_x(xp: int): void =
            if xp <= x1 then let
              val rr = calculate_rr_antialiased(xp, yp, x, y, ar, sn, cs, one_over_radius2, r_aa_start)
              val idx = yp * MINEPAINT_TILE_SIZE + xp
              val () = $UN.ptr0_set<float>(ptr_add<float>(rr_mask, int2size(idx)), rr)
            in loop_x(xp + 1) end
            else ()
          val () = loop_x(x0)
        in loop_y(yp + 1) end
        else ()
    in loop_y(y0) end
    else let
      fun loop_y(yp: int): void =
        if yp <= y1 then let
          fun loop_x(xp: int): void =
            if xp <= x1 then let
              val rr = calculate_rr(xp, yp, x, y, ar, sn, cs, one_over_radius2)
              val idx = yp * MINEPAINT_TILE_SIZE + xp
              val () = $UN.ptr0_set<float>(ptr_add<float>(rr_mask, int2size(idx)), rr)
            in loop_x(xp + 1) end
            else ()
          val () = loop_x(x0)
        in loop_y(yp + 1) end
        else ()
    in loop_y(y0) end

  // RLE encode into mask
  val skip0 = y0 * MINEPAINT_TILE_SIZE

  fun loop_rle_y(yp: int, cur_skip: int, out_idx: int): @(int, int) =
    if yp <= y1 then let
      val s_with_x0 = cur_skip + x0
      fun loop_rle_x(xp: int, s_acc: int, o_idx: int): @(int, int) =
        if xp <= x1 then let
          val idx = yp * MINEPAINT_TILE_SIZE + xp
          val rr = $UN.ptr0_get<float>(ptr_add<float>(rr_mask, int2size(idx)))
          val opa = calculate_opa(rr, h, seg1_off, seg1_slope, seg2_off, seg2_slope)
          val opa_i = g0float2int_float_int(f_mul(opa, 32768.0f))
        in
          if opa_i <= 0 then loop_rle_x(xp + 1, s_acc + 1, o_idx)
          else let
            val next_o_idx: int =
              if s_acc > 0 then let
                val () = $UN.ptr0_set<uint16>(ptr_add<uint16>(mask, int2size(o_idx)), u16(0U))
                val () = $UN.ptr0_set<uint16>(ptr_add<uint16>(mask, int2size(o_idx + 1)), u16(g0int2uint_int_uint(s_acc * 4)))
              in
                o_idx + 2
              end
              else o_idx
            val () = $UN.ptr0_set<uint16>(ptr_add<uint16>(mask, int2size(next_o_idx)), u16(g0int2uint_int_uint(opa_i)))
          in
            loop_rle_x(xp + 1, 0, g0int_add(next_o_idx, 1))
          end
        end
        else @(s_acc, o_idx)

      val res_x = loop_rle_x(x0, s_with_x0, out_idx)
      val s_after_row = res_x.0
      val out_idx_after = res_x.1
      val s_next = s_after_row + (MINEPAINT_TILE_SIZE - (x1 + 1))
    in
      loop_rle_y(yp + 1, s_next, out_idx_after)
    end
    else @(cur_skip, out_idx)

  val res_y = loop_rle_y(y0, skip0, 0)
  val final_out = res_y.1
  val () = $UN.ptr0_set<uint16>(ptr_add<uint16>(mask, int2size(final_out)), u16(0U))
  val () = $UN.ptr0_set<uint16>(ptr_add<uint16>(mask, int2size(final_out + 1)), u16(0U))
  val () = free(rr_mask)
in () end

// process_op: dispatches operations to blending modes
extern fun process_op(rgba_p: ptr, mask: ptr, tx: int, ty: int, op_ptr: ptr): void = "ext#process_op"
implement process_op(rgba_p, mask, tx, ty, op_ptr) =
  if (rgba_p != the_null_ptr) * (op_ptr != the_null_ptr) then let
    val op_rec = $UN.cast{ref(OperationDataDrawDab_struct)}(op_ptr)
    val ox = f_sub(op_rec->x, g0int2float_int_float(tx * MINEPAINT_TILE_SIZE))
    val oy = f_sub(op_rec->y, g0int2float_int_float(ty * MINEPAINT_TILE_SIZE))

    val () = render_dab_mask(
      mask, ox, oy, op_rec->radius,
      op_rec->hardness, op_rec->softness,
      op_rec->aspect_ratio, op_rec->angle
    )

    val paint = op_rec->paint
    val normal = op_rec->normal
    val color_r = op_rec->color_r
    val color_g = op_rec->color_g
    val color_b = op_rec->color_b
    val color_a = op_rec->color_a
    val opaque = op_rec->opaque

    // 1. Non-paint pass
    val () =
      if f_lt(paint, 1.0f) then let
        val () =
          if f_gt(normal, 0.0f) then let
            val opaq_norm = f_mul(f_mul(normal, opaque), f_mul(f_sub(1.0f, paint), 32768.0f))
            val opaq_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(opaq_norm)))
            val () =
              if f_gte(color_a, 1.0f) then
                draw_dab_pixels_BlendMode_Normal(mask, rgba_p, color_r, color_g, color_b, opaq_u16)
              else let
                val ca_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(f_mul(color_a, 32768.0f))))
              in
                draw_dab_pixels_BlendMode_Normal_and_Eraser(mask, rgba_p, color_r, color_g, color_b, ca_u16, opaq_u16)
              end
          in () end

        val () =
          if (f_gt(op_rec->lock_alpha, 0.0f)) * (color_a != 0.0f) then let
            val la_fac = f_mul(f_mul(op_rec->lock_alpha, opaque), f_mul(f_sub(1.0f, op_rec->colorize), f_sub(1.0f, op_rec->posterize)))
            val la_norm = f_mul(f_mul(la_fac, f_sub(1.0f, paint)), 32768.0f)
            val la_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(la_norm)))
          in
            draw_dab_pixels_BlendMode_LockAlpha(mask, rgba_p, color_r, color_g, color_b, la_u16)
          end
      in () end

    // 2. Paint pass
    val () =
      if f_gt(paint, 0.0f) then let
        val () =
          if f_gt(normal, 0.0f) then let
            val opaq_norm = f_mul(f_mul(normal, opaque), f_mul(paint, 32768.0f))
            val opaq_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(opaq_norm)))
            val () =
              if f_gte(color_a, 1.0f) then
                draw_dab_pixels_BlendMode_Normal_Paint(mask, rgba_p, color_r, color_g, color_b, opaq_u16)
              else let
                val ca_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(f_mul(color_a, 32768.0f))))
              in
                draw_dab_pixels_BlendMode_Normal_and_Eraser_Paint(mask, rgba_p, color_r, color_g, color_b, ca_u16, opaq_u16)
              end
          in () end

        val () =
          if (f_gt(op_rec->lock_alpha, 0.0f)) * (color_a != 0.0f) then let
            val la_fac = f_mul(f_mul(op_rec->lock_alpha, opaque), f_mul(f_sub(1.0f, op_rec->colorize), f_sub(1.0f, op_rec->posterize)))
            val la_norm = f_mul(f_mul(la_fac, paint), 32768.0f)
            val la_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(la_norm)))
          in
            draw_dab_pixels_BlendMode_LockAlpha_Paint(mask, rgba_p, color_r, color_g, color_b, la_u16)
          end
      in () end

    // 3. Colorize
    val () =
      if f_gt(op_rec->colorize, 0.0f) then let
        val c_norm = f_mul(f_mul(op_rec->colorize, opaque), 32768.0f)
        val c_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(c_norm)))
      in
        draw_dab_pixels_BlendMode_Color(mask, rgba_p, color_r, color_g, color_b, c_u16)
      end

    // 4. Posterize
    val () =
      if f_gt(op_rec->posterize, 0.0f) then let
        val p_norm = f_mul(f_mul(op_rec->posterize, opaque), 32768.0f)
        val p_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(p_norm)))
        val pnum_u16 = u16(g0int2uint_int_uint(g0float2int_float_int(op_rec->posterize_num)))
      in
        draw_dab_pixels_BlendMode_Posterize(mask, rgba_p, p_u16, pnum_u16)
      end
  in () end

// process_tile: processes all operations queued for tile (tx, ty)
extern fun process_tile(self_p: ptr, tx: int, ty: int): void = "ext#process_tile"
implement process_tile(self_p, tx, ty) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val op_first = operation_queue_pop(self->operation_queue, tx, ty)
  in
    if op_first != the_null_ptr then let
      val req_sz = sizeof<MinePaintTileRequest_struct>
      val req_mem = malloc(req_sz)
      val () = assertloc(req_mem > the_null_ptr)
      val () = minepaint_tile_request_init(req_mem, 0, tx, ty, false)
      val () = minepaint_tiled_surface_tile_request_start(self_p, req_mem)
      val req_rec = $UN.cast{ref(MinePaintTileRequest_struct)}(req_mem)
      val rgba_p = req_rec->buffer
    in
      if rgba_p = the_null_ptr then let
        val () = free(op_first)
        val () = free(req_mem)
      in () end
      else let
        val mask_sz = (MINEPAINT_TILE_SIZE * MINEPAINT_TILE_SIZE + 2 * MINEPAINT_TILE_SIZE) * 2
        val mask = malloc(int2size(mask_sz))
        val () = assertloc(mask > the_null_ptr)

        fun loop_ops(cur_op: ptr): void =
          if cur_op != the_null_ptr then let
            val () = process_op(rgba_p, mask, tx, ty, cur_op)
            val () = free(cur_op)
            val next_op = operation_queue_pop(self->operation_queue, tx, ty)
          in
            loop_ops(next_op)
          end
          else ()

        val () = loop_ops(op_first)
        val () = free(mask)
        val () = minepaint_tiled_surface_tile_request_end(self_p, req_mem)
        val () = free(req_mem)
      in () end
    end
    else ()
  end

// prepare_bounding_boxes
fn prepare_bounding_boxes(self_p: ptr): void =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val symm = $UN.cast{ref(MinePaintSymmetryData_struct)}(self->symmetry_data)
    val cur_state = symm->state_current
    val snowflake = (cur_state.type = 4)
    val lines_i = g0float2int_float_int(cur_state.num_lines)
    val mult = (if snowflake then 2 else 1): int
    val num_desired = g0int_mul(lines_i, mult)

    val () =
      if g0int_gt(num_desired, self->num_bboxes) then let
        val margin = 10
        val num_to_alloc = g0int_add(num_desired, margin)
        val sz = sizeof<MinePaintRectangle_struct>
        val bytes = mul_size_size(int2size(num_to_alloc), sz)
        val new_boxes = malloc(bytes)
      in
        if new_boxes > the_null_ptr then let
          val def_boxes = get_tiled_surface_default_bboxes(self_p)
          val () = if self->bboxes != def_boxes then free(self->bboxes)
          val _ = memset(new_boxes, 0, bytes)
          val () = self->bboxes := new_boxes
          val () = self->num_bboxes := num_to_alloc
          val () = self->num_bboxes_dirtied := 0
        in () end
      end

    val n_clean = i_min(self->num_bboxes, self->num_bboxes_dirtied)
    fun loop_clean(i: int): void =
      if i < n_clean then let
        val r_p = ptr_add<byte>(self->bboxes, int2size(g0int_mul(i, 16)))
        val r = $UN.cast{ref(MinePaintRectangle_struct)}(r_p)
        val () = r->x := 0
        val () = r->y := 0
        val () = r->width := 0
        val () = r->height := 0
      in loop_clean(i + 1) end
      else ()
    val () = loop_clean(0)
    val () = self->num_bboxes_dirtied := 0
  in () end

// minepaint_tiled_surface_begin_atomic
extern fun minepaint_tiled_surface_begin_atomic(self_p: ptr): void = "ext#minepaint_tiled_surface_begin_atomic"
implement minepaint_tiled_surface_begin_atomic(self_p) =
  if self_p != the_null_ptr then let
    val symm_ptr = get_tiled_surface_symmetry_data(self_p)
    val () = minepaint_update_symmetry_state(symm_ptr)
    val () = prepare_bounding_boxes(self_p)
  in () end

// minepaint_tiled_surface_end_atomic
extern fun minepaint_tiled_surface_end_atomic(self_p: ptr, roi_p: ptr): void = "ext#minepaint_tiled_surface_end_atomic"
implement minepaint_tiled_surface_end_atomic(self_p, roi_p) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    var tiles_ptr: ptr
    val tiles_n = operation_queue_get_dirty_tiles(self->operation_queue, tiles_ptr)
    val t_ptr = tiles_ptr

    fun loop_tiles(i: int): void =
      if i < tiles_n then let
        val t = get_dirty_tile(t_ptr, i)
        val () = process_tile(self_p, t.0, t.1)
      in loop_tiles(i + 1) end
      else ()
    val () = loop_tiles(0)
    val () = operation_queue_clear_dirty_tiles(self->operation_queue)

    val () =
      if roi_p != the_null_ptr then let
        val roi = $UN.cast{ref(MinePaintRectangles_struct)}(roi_p)
        val roi_rects = roi->num_rectangles
        val num_dirty = self->num_bboxes_dirtied
        val n_clean = i_min(roi_rects, num_dirty)

        fun loop_clean(i: int): void =
          if i < n_clean then let
            val rp = ptr_add<byte>(roi->rectangles, int2size(g0int_mul(i, 16)))
            val r = $UN.cast{ref(MinePaintRectangle_struct)}(rp)
            val () = r->x := 0
            val () = r->y := 0
            val () = r->width := 0
            val () = r->height := 0
          in loop_clean(i + 1) end
          else ()
        val () = loop_clean(0)

        val bboxes_per_out = if roi_rects > 0 then f_div(g0int2float_int_float(num_dirty), g0int2float_int_float(roi_rects)) else 1.0f
        val factor = if f_lt(bboxes_per_out, 1.0f) then 1.0f else bboxes_per_out

        fun loop_out(i: int): void =
          if i < num_dirty then let
            val out_idx: int =
              if num_dirty > roi_rects then
                i_min(roi_rects - 1, g0float2int_float_int(roundf(f_div(g0int2float_int_float(i), factor))))
              else i
            val dest_p = ptr_add<byte>(roi->rectangles, int2size(g0int_mul(out_idx, 16)))
            val src_p = ptr_add<byte>(self->bboxes, int2size(g0int_mul(i, 16)))
            val () = minepaint_rectangle_expand_to_include_rect(dest_p, src_p)
          in loop_out(i + 1) end
          else ()
        val () = loop_out(0)
        val () = roi->num_rectangles := i_min(roi_rects, num_dirty)
      in () end
  in () end

// draw_dab_internal
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
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val op_sz = sizeof<OperationDataDrawDab_struct>
    val op_p = malloc(op_sz)
    val () = assertloc(op_p > the_null_ptr)
    val op_data = $UN.cast{ref(OperationDataDrawDab_struct)}(op_p)

    val () = op_data->x := x
    val () = op_data->y := y
    val () = op_data->radius := radius
    val ar = if f_lt(aspect_ratio, 1.0f) then 1.0f else aspect_ratio
    val () = op_data->aspect_ratio := ar
    val () = op_data->angle := angle
    val () = op_data->opaque := f_clamp(opaque, 0.0f, 1.0f)
    val () = op_data->hardness := f_clamp(hardness, 0.0f, 1.0f)
    val () = op_data->softness := f_clamp(softness, 0.0f, 1.0f)
    val () = op_data->lock_alpha := f_clamp(lock_alpha, 0.0f, 1.0f)
    val () = op_data->colorize := f_clamp(colorize, 0.0f, 1.0f)
    val () = op_data->posterize := f_clamp(posterize, 0.0f, 1.0f)
    val p_num = f_clamp(roundf(f_mul(posterize_num, 100.0f)), 1.0f, 128.0f)
    val () = op_data->posterize_num := p_num
    val () = op_data->paint := f_clamp(paint, 0.0f, 1.0f)

    val cr = f_mul(f_clamp(color_r, 0.0f, 1.0f), 32768.0f)
    val cg = f_mul(f_clamp(color_g, 0.0f, 1.0f), 32768.0f)
    val cb = f_mul(f_clamp(color_b, 0.0f, 1.0f), 32768.0f)
    val ca = f_clamp(color_a, 0.0f, 1.0f)

    val () = op_data->color_r := u16(g0int2uint_int_uint(g0float2int_float_int(cr)))
    val () = op_data->color_g := u16(g0int2uint_int_uint(g0float2int_float_int(cg)))
    val () = op_data->color_b := u16(g0int2uint_int_uint(g0float2int_float_int(cb)))
    val () = op_data->color_a := ca

    val norm = f_mul(f_mul(f_sub(1.0f, op_data->lock_alpha), f_sub(1.0f, op_data->colorize)), f_sub(1.0f, op_data->posterize))
    val () = op_data->normal := norm

    val r_fringe = f_add(radius, 1.0f)
    val tx1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(x, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val tx2 = g0float2int_float_int(floorf(f_div(floorf(f_add(x, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val ty1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(y, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
    val ty2 = g0float2int_float_int(floorf(f_div(floorf(f_add(y, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))

    fun loop_ty(ty: int): void =
      if ty <= ty2 then let
        fun loop_tx(tx: int): void =
          if tx <= tx2 then let
            val copy_p = malloc(op_sz)
            val () = assertloc(copy_p > the_null_ptr)
            val _ = $extfcall(ptr, "memcpy", copy_p, op_p, op_sz)
            val () = operation_queue_add(self->operation_queue, tx, ty, copy_p)
          in loop_tx(tx + 1) end
          else ()
        val () = loop_tx(tx1)
      in loop_ty(ty + 1) end
      else ()
    val () = loop_ty(ty1)

    // Update bbox
    val bb_x = g0float2int_float_int(floorf(f_sub(x, r_fringe)))
    val bb_y = g0float2int_float_int(floorf(f_sub(y, r_fringe)))
    val bb_w = g0float2int_float_int(floorf(f_add(x, r_fringe))) - bb_x + 1
    val bb_h = g0float2int_float_int(floorf(f_add(y, r_fringe))) - bb_y + 1

    val bbox_p = ptr_add<byte>(self->bboxes, int2size(g0int_mul(bbox_index, 16)))
    val () = minepaint_rectangle_expand_to_include_point(bbox_p, bb_x, bb_y)
    val () = minepaint_rectangle_expand_to_include_point(bbox_p, bb_x + bb_w - 1, bb_y + bb_h - 1)
    val () = free(op_p)
  in true end

fn transform_and_draw(
  surface: ptr, m: ptr, x: float, y: float, radius: float,
  color_r: float, color_g: float, color_b: float,
  opaque: float, hardness: float, softness: float,
  color_a: float, aspect_ratio: float, dab_angle: float,
  lock_alpha: float, colorize: float, posterize: float,
  posterize_num: float, paint: float, bbox_index: int
): void = let
  var tx: float
  var ty: float
  val () = minepaint_transform_point(m, x, y, tx, ty)
  val _ = draw_dab_internal(
    surface, tx, ty, radius, color_r, color_g, color_b,
    opaque, hardness, softness, color_a, aspect_ratio, dab_angle,
    lock_alpha, colorize, posterize, posterize_num, paint, bbox_index
  )
in () end

// draw_dab (implements surface draw_dab)
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
  val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(surface)
  val () =
    if modified then let
      val symm = $UN.cast{ref(MinePaintSymmetryData_struct)}(self->symmetry_data)
      val symm_active = symm->active
      val symm_num = symm->num_symmetry_matrices
    in
      if (symm_active > 0) * (symm_num > 0) then let
        val symm_state = symm->state_current
        val matrices = symm->symmetry_matrices
        val num_lines_i = g0float2int_float_int(symm_state.num_lines)
        val rot_angle = f_div(360.0f, symm_state.num_lines)

        val () =
          case+ symm_state.type of
          | 0 => let // VERTICAL
              val () = transform_and_draw(
                surface, matrices, x, y, radius, color_r, color_g, color_b,
                opaque, hardness, softness, color_a, aspect_ratio,
                f_sub(f_mul(~2.0f, f_add(90.0f, symm_state.angle)), angle),
                lock_alpha, colorize, posterize, posterize_num, paint, 1
              )
              val () = self->num_bboxes_dirtied := i_min(self->num_bboxes, 2)
            in () end
          | 1 => let // HORIZONTAL
              val () = transform_and_draw(
                surface, matrices, x, y, radius, color_r, color_g, color_b,
                opaque, hardness, softness, color_a, aspect_ratio,
                f_sub(f_mul(~2.0f, symm_state.angle), angle),
                lock_alpha, colorize, posterize, posterize_num, paint, 1
              )
              val () = self->num_bboxes_dirtied := i_min(self->num_bboxes, 2)
            in () end
          | 2 => let // VERTHORZ
              val m0 = get_matrix_ptr(matrices, 0)
              val m1 = get_matrix_ptr(matrices, 1)
              val m2 = get_matrix_ptr(matrices, 2)
              val () = transform_and_draw(
                surface, m0, x, y, radius, color_r, color_g, color_b,
                opaque, hardness, softness, color_a, aspect_ratio,
                f_sub(f_mul(~2.0f, symm_state.angle), angle),
                lock_alpha, colorize, posterize, posterize_num, paint, 1
              )
              val () = transform_and_draw(
                surface, m1, x, y, radius, color_r, color_g, color_b,
                opaque, hardness, softness, color_a, aspect_ratio, angle,
                lock_alpha, colorize, posterize, posterize_num, paint, 2
              )
              val () = transform_and_draw(
                surface, m2, x, y, radius, color_r, color_g, color_b,
                opaque, hardness, softness, color_a, aspect_ratio,
                f_sub(f_mul(~2.0f, symm_state.angle), angle),
                lock_alpha, colorize, posterize, posterize_num, paint, 3
              )
              val () = self->num_bboxes_dirtied := i_min(self->num_bboxes, 4)
            in () end
          | 3 => let // ROTATIONAL
              fun loop_rot(c: int): void =
                if c < num_lines_i then let
                  val m = get_matrix_ptr(matrices, c - 1)
                  val () = transform_and_draw(
                    surface, m, x, y, radius, color_r, color_g, color_b,
                    opaque, hardness, softness, color_a, aspect_ratio,
                    f_sub(angle, f_mul(g0int2float_int_float(c), rot_angle)),
                    lock_alpha, colorize, posterize, posterize_num, paint, c
                  )
                in loop_rot(c + 1) end
                else ()
              val () = loop_rot(1)
              val () = self->num_bboxes_dirtied := i_min(self->num_bboxes, num_lines_i)
            in () end
          | 4 => let // SNOWFLAKE
              val base_idx = num_lines_i - 1
              val base_angle = f_sub(f_mul(~2.0f, symm_state.angle), angle)
              fun loop_snow(c: int): void =
                if c < num_lines_i then let
                  val m = get_matrix_ptr(matrices, base_idx + c)
                  val () = transform_and_draw(
                    surface, m, x, y, radius, color_r, color_g, color_b,
                    opaque, hardness, softness, color_a, aspect_ratio,
                    f_sub(base_angle, f_mul(g0int2float_int_float(c), rot_angle)),
                    lock_alpha, colorize, posterize, posterize_num, paint, num_lines_i + c
                  )
                in loop_snow(c + 1) end
                else ()
              val () = loop_snow(0)
              fun loop_rot(c: int): void =
                if c < num_lines_i then let
                  val m = get_matrix_ptr(matrices, c - 1)
                  val () = transform_and_draw(
                    surface, m, x, y, radius, color_r, color_g, color_b,
                    opaque, hardness, softness, color_a, aspect_ratio,
                    f_sub(angle, f_mul(g0int2float_int_float(c), rot_angle)),
                    lock_alpha, colorize, posterize, posterize_num, paint, c
                  )
                in loop_rot(c + 1) end
                else ()
              val () = loop_rot(1)
              val () = self->num_bboxes_dirtied := i_min(self->num_bboxes, num_lines_i * 2)
            in () end
          | _ => ()
      in () end
      else let
        val () = self->num_bboxes_dirtied := 1
      in () end
    end
    else ()
in
  if modified then 1 else 0
end

// get_color (implements surface get_color)
extern fun tiled_surface_get_color(
  surface: ptr, x: float, y: float, radius: float,
  color_r: &float? >> float, color_g: &float? >> float,
  color_b: &float? >> float, color_a: &float? >> float,
  paint: float
): void = "ext#tiled_surface_get_color"
implement tiled_surface_get_color(surface, x, y, radius, color_r, color_g, color_b, color_a, paint) = let
  val rad = if f_lt(radius, 1.0f) then 1.0f else radius
  val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(surface)

  val acc_mem = malloc(int2size(20))
  val () = assertloc(acc_mem > the_null_ptr)
  val _ = memset(acc_mem, 0, int2size(20))
  val p_weight = acc_mem
  val p_r = ptr_add<float>(acc_mem, int2size(1))
  val p_g = ptr_add<float>(acc_mem, int2size(2))
  val p_b = ptr_add<float>(acc_mem, int2size(3))
  val p_a = ptr_add<float>(acc_mem, int2size(4))

  val sample_interval = if f_lte(rad, 2.0f) then 1 else g0float2int_float_int(f_mul(rad, 7.0f))
  val sample_interval_u16 = u16(g0int2uint_int_uint(sample_interval))
  val random_sample_rate = f_div(1.0f, f_mul(7.0f, rad))

  val r_fringe = f_add(rad, 1.0f)
  val tx1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(x, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
  val tx2 = g0float2int_float_int(floorf(f_div(floorf(f_add(x, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
  val ty1 = g0float2int_float_int(floorf(f_div(floorf(f_sub(y, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))
  val ty2 = g0float2int_float_int(floorf(f_div(floorf(f_add(y, r_fringe)), g0int2float_int_float(MINEPAINT_TILE_SIZE))))

  val req_sz = sizeof<MinePaintTileRequest_struct>
  val mask_sz = (MINEPAINT_TILE_SIZE * MINEPAINT_TILE_SIZE + 2 * MINEPAINT_TILE_SIZE) * 2
  val mask = malloc(int2size(mask_sz))
  val () = assertloc(mask > the_null_ptr)

  fun loop_ty(ty: int): void =
    if ty <= ty2 then let
      fun loop_tx(tx: int): void =
        if tx <= tx2 then let
          val () = process_tile(surface, tx, ty)
          val req_mem = malloc(req_sz)
          val () = assertloc(req_mem > the_null_ptr)
          val () = minepaint_tile_request_init(req_mem, 0, tx, ty, true)
          val () = minepaint_tiled_surface_tile_request_start(surface, req_mem)
          val req_rec = $UN.cast{ref(MinePaintTileRequest_struct)}(req_mem)
          val rgba_p = req_rec->buffer
        in
          if rgba_p != the_null_ptr then let
            val ox = f_sub(x, g0int2float_int_float(tx * MINEPAINT_TILE_SIZE))
            val oy = f_sub(y, g0int2float_int_float(ty * MINEPAINT_TILE_SIZE))
            val () = render_dab_mask(mask, ox, oy, rad, 0.5f, 0.5f, 1.0f, 0.0f)
            val () = get_color_pixels_accumulate(
              mask, rgba_p, p_weight, p_r, p_g, p_b, p_a, paint,
              sample_interval_u16, random_sample_rate
            )
            val () = minepaint_tiled_surface_tile_request_end(surface, req_mem)
            val () = free(req_mem)
          in loop_tx(tx + 1) end
          else let
            val () = free(req_mem)
          in loop_tx(tx + 1) end
        end
        else ()
      val () = loop_tx(tx1)
    in loop_ty(ty + 1) end
    else ()

  val () = loop_ty(ty1)
  val () = free(mask)

  val sum_weight = $UN.ptr0_get<float>(p_weight)
  val sum_r = $UN.ptr0_get<float>(p_r)
  val sum_g = $UN.ptr0_get<float>(p_g)
  val sum_b = $UN.ptr0_get<float>(p_b)
  val sum_a = $UN.ptr0_get<float>(p_a)
  val () = free(acc_mem)

  var cr_res: float = 0.0f
  var cg_res: float = 1.0f
  var cb_res: float = 0.0f
  var ca_res: float = 0.0f

  val () =
    if f_gt(sum_weight, 0.0f) then let
      val sa = f_div(sum_a, sum_weight)
      val sr = if f_lt(paint, 0.0f) then f_div(sum_r, sum_weight) else sum_r
      val sg = if f_lt(paint, 0.0f) then f_div(sum_g, sum_weight) else sum_g
      val sb = if f_lt(paint, 0.0f) then f_div(sum_b, sum_weight) else sum_b
      val ca = f_clamp(sa, 0.0f, 1.0f)
      val () = ca_res := ca
      val () =
        if f_gt(ca, 0.0f) then let
          val demul = if f_lt(paint, 0.0f) then ca else 1.0f
          val () = cr_res := f_clamp(f_div(sr, demul), 0.0f, 1.0f)
          val () = cg_res := f_clamp(f_div(sg, demul), 0.0f, 1.0f)
          val () = cb_res := f_clamp(f_div(sb, demul), 0.0f, 1.0f)
        in () end
    in () end

  val () = color_r := cr_res
  val () = color_g := cg_res
  val () = color_b := cb_res
  val () = color_a := ca_res
in () end

// minepaint_tiled_surface_init
extern fun minepaint_tiled_surface_init(
  self_p: ptr, tile_request_start: ptr, tile_request_end: ptr
): void = "ext#minepaint_tiled_surface_init"
implement minepaint_tiled_surface_init(self_p, tile_request_start, tile_request_end) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val () = minepaint_surface_init(self_p)
    val () = self->parent.draw_dab := $UN.cast{ptr}(tiled_surface_draw_dab)
    val () = self->parent.get_color := $UN.cast{ptr}(tiled_surface_get_color)
    val () = self->parent.begin_atomic := $UN.cast{ptr}(minepaint_tiled_surface_begin_atomic)
    val () = self->parent.end_atomic := $UN.cast{ptr}(minepaint_tiled_surface_end_atomic)
    val () = self->tile_request_start := tile_request_start
    val () = self->tile_request_end := tile_request_end
    val () = self->tile_size := MINEPAINT_TILE_SIZE
    val () = self->threadsafe_tile_requests := 0
    val () = self->num_bboxes := NUM_BBOXES_DEFAULT
    val () = self->num_bboxes_dirtied := 0
    val sz_boxes = mul_size_size(int2size(NUM_BBOXES_DEFAULT), sizeof<MinePaintRectangle_struct>)
    val def_boxes = malloc(sz_boxes)
    val _ = memset(def_boxes, 0, sz_boxes)
    val () = self->default_bboxes := def_boxes
    val () = self->bboxes := def_boxes
    val () = self->symmetry_data := minepaint_symmetry_data_new()
    val () = self->operation_queue := operation_queue_new()
  in () end

// minepaint_tiled_surface_destroy
extern fun minepaint_tiled_surface_destroy(self_p: ptr): void = "ext#minepaint_tiled_surface_destroy"
implement minepaint_tiled_surface_destroy(self_p) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintTiledSurface_struct)}(self_p)
    val () = operation_queue_free(self->operation_queue)
    val def_boxes = get_tiled_surface_default_bboxes(self_p)
    val () = if self->bboxes != def_boxes then free(self->bboxes)
    val () = if def_boxes != the_null_ptr then free(def_boxes)
    val symm_ptr = self->symmetry_data
    val () = if symm_ptr != the_null_ptr then let
      val () = minepaint_symmetry_data_destroy(symm_ptr)
      val () = free(symm_ptr)
    in () end
  in () end

// minepaint_tiled_surface_set_symmetry_state
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
      symm_ptr, active, center_x, center_y,
      symmetry_angle, symmetry_type, rot_symmetry_lines
    )
  end

// minepaint_tiled_surface_get_alpha
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
