// src/draw_engine/brushmodes.dats
// Native ATS2 implementation of Brush Pixel Blending Modes
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "./engine_safe.hats"
staload "draw_engine/pixel_buf.sats"
staload "draw_engine/fcell.sats"
staload "sys/libc.dats"

fn pix(p: U16Buf): ptr = u16buf_ptr(p)
fn step(p: U16Buf, n: int): U16Buf = u16buf_add(p, n)

fn i_add(a: int, b: int): int = g0int_add(a, b)
fn i_sub(a: int, b: int): int = g0int_sub(a, b)
fn i_mul(a: int, b: int): int = g0int_mul(a, b)
fn i_div(a: int, b: int): int = g0int_div(a, b)
fn i_gt(a: int, b: int): bool = a > b
fn i_lt(a: int, b: int): bool = a < b

extern fun u2f(x: uint): float = "mac#mp_uint_to_float"
extern fun f2u(x: float): uint = "mac#mp_float_to_uint"

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)

extern fun rgb_to_spectral(r: float, g: float, b: float, spectral: ptr): void = "ext#rgb_to_spectral"
extern fun spectral_to_rgb(spectral: ptr, rgb: ptr): void = "ext#spectral_to_rgb"

// Helper inline getters/setters for 16-bit RGBA pixel components
fn get_r(p: U16Buf): uint = g0uint2uint_uint16_uint(airlock_u16get_n(pix(p), 0, 4))
fn get_g(p: U16Buf): uint = g0uint2uint_uint16_uint(airlock_u16get_n(pix(p), 1, 4))
fn get_b(p: U16Buf): uint = g0uint2uint_uint16_uint(airlock_u16get_n(pix(p), 2, 4))
fn get_a(p: U16Buf): uint = g0uint2uint_uint16_uint(airlock_u16get_n(pix(p), 3, 4))

fn set_r(p: U16Buf, v: uint): void = airlock_u16set_n(pix(p), 0, 4, u16(v))
fn set_g(p: U16Buf, v: uint): void = airlock_u16set_n(pix(p), 1, 4, u16(v))
fn set_b(p: U16Buf, v: uint): void = airlock_u16set_n(pix(p), 2, 4, u16(v))
fn set_a(p: U16Buf, v: uint): void = airlock_u16set_n(pix(p), 3, 4, u16(v))

fn get_mask_val(m: U16Buf): uint = g0uint2uint_uint16_uint(airlock_u16get_n(pix(m), 0, 1))

// --- 1. NORMAL BLEND MODE ---
extern fun draw_dab_pixels_BlendMode_Normal(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_Normal"
implement draw_dab_pixels_BlendMode_Normal(mask, rgba, color_r, color_g, color_b, opacity) = let
  val cr = g0uint2uint_uint16_uint(color_r)
  val cg = g0uint2uint_uint16_uint(color_g)
  val cb = g0uint2uint_uint16_uint(color_b)
  val opacity_u = g0uint2uint_uint16_uint(opacity)

  fun loop_outer(m: U16Buf, p: U16Buf): void = let
    fun loop_inner(m_cur: U16Buf, p_cur: U16Buf): @(U16Buf, U16Buf) = let
      val mval = get_mask_val(m_cur)
    in
      if mval != 0U then let
        val opa_a = (mval * opacity_u) / 32768U
        val opa_b = 32768U - opa_a
        val cur_a = get_a(p_cur)
        val cur_r = get_r(p_cur)
        val cur_g = get_g(p_cur)
        val cur_b = get_b(p_cur)

        val () = set_a(p_cur, opa_a + (opa_b * cur_a) / 32768U)
        val () = set_r(p_cur, (opa_a * cr + opa_b * cur_r) / 32768U)
        val () = set_g(p_cur, (opa_a * cg + opa_b * cur_g) / 32768U)
        val () = set_b(p_cur, (opa_a * cb + opa_b * cur_b) / 32768U)
      in
        loop_inner(step(m_cur, 1), step(p_cur, 4))
      end else
        @(m_cur, p_cur)
    end

    val @(m_end, p_end) = loop_inner(m, p)
    val skip = get_mask_val(step(m_end, 1))
  in
    if skip = 0U then ()
    else let
      val next_p = step(p_end, g0uint2int_uint_int(skip))
      val next_m = step(m_end, 2)
    in
      loop_outer(next_m, next_p)
    end
  end
in
  loop_outer(mask, rgba)
end

// --- 2. NORMAL AND ERASER (SMUDGE / ERASE) ---
extern fun draw_dab_pixels_BlendMode_Normal_and_Eraser(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, color_a: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_Normal_and_Eraser"
implement draw_dab_pixels_BlendMode_Normal_and_Eraser(mask, rgba, color_r, color_g, color_b, color_a, opacity) = let
  val cr = g0uint2uint_uint16_uint(color_r)
  val cg = g0uint2uint_uint16_uint(color_g)
  val cb = g0uint2uint_uint16_uint(color_b)
  val ca = g0uint2uint_uint16_uint(color_a)
  val opacity_u = g0uint2uint_uint16_uint(opacity)

  fun loop_outer(m: U16Buf, p: U16Buf): void = let
    fun loop_inner(m_cur: U16Buf, p_cur: U16Buf): @(U16Buf, U16Buf) = let
      val mval = get_mask_val(m_cur)
    in
      if mval != 0U then let
        val opa_a0 = (mval * opacity_u) / 32768U
        val opa_b = 32768U - opa_a0
        val opa_a = (opa_a0 * ca) / 32768U
        val cur_a = get_a(p_cur)
        val cur_r = get_r(p_cur)
        val cur_g = get_g(p_cur)
        val cur_b = get_b(p_cur)

        val () = set_a(p_cur, opa_a + (opa_b * cur_a) / 32768U)
        val () = set_r(p_cur, (opa_a * cr + opa_b * cur_r) / 32768U)
        val () = set_g(p_cur, (opa_a * cg + opa_b * cur_g) / 32768U)
        val () = set_b(p_cur, (opa_a * cb + opa_b * cur_b) / 32768U)
      in
        loop_inner(step(m_cur, 1), step(p_cur, 4))
      end else
        @(m_cur, p_cur)
    end

    val @(m_end, p_end) = loop_inner(m, p)
    val skip = get_mask_val(step(m_end, 1))
  in
    if skip = 0U then ()
    else let
      val next_p = step(p_end, g0uint2int_uint_int(skip))
      val next_m = step(m_end, 2)
    in
      loop_outer(next_m, next_p)
    end
  end
in
  loop_outer(mask, rgba)
end

// --- 3. LOCK ALPHA BLEND MODE ---
extern fun draw_dab_pixels_BlendMode_LockAlpha(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_LockAlpha"
implement draw_dab_pixels_BlendMode_LockAlpha(mask, rgba, color_r, color_g, color_b, opacity) = let
  val cr = g0uint2uint_uint16_uint(color_r)
  val cg = g0uint2uint_uint16_uint(color_g)
  val cb = g0uint2uint_uint16_uint(color_b)
  val opacity_u = g0uint2uint_uint16_uint(opacity)

  fun loop_outer(m: U16Buf, p: U16Buf): void = let
    fun loop_inner(m_cur: U16Buf, p_cur: U16Buf): @(U16Buf, U16Buf) = let
      val mval = get_mask_val(m_cur)
    in
      if mval != 0U then let
        val opa_a0 = (mval * opacity_u) / 32768U
        val opa_b = 32768U - opa_a0
        val cur_a = get_a(p_cur)
        val opa_a = (opa_a0 * cur_a) / 32768U
        val cur_r = get_r(p_cur)
        val cur_g = get_g(p_cur)
        val cur_b = get_b(p_cur)

        val () = set_r(p_cur, (opa_a * cr + opa_b * cur_r) / 32768U)
        val () = set_g(p_cur, (opa_a * cg + opa_b * cur_g) / 32768U)
        val () = set_b(p_cur, (opa_a * cb + opa_b * cur_b) / 32768U)
      in
        loop_inner(step(m_cur, 1), step(p_cur, 4))
      end else
        @(m_cur, p_cur)
    end

    val @(m_end, p_end) = loop_inner(m, p)
    val skip = get_mask_val(step(m_end, 1))
  in
    if skip = 0U then ()
    else let
      val next_p = step(p_end, g0uint2int_uint_int(skip))
      val next_m = step(m_end, 2)
    in
      loop_outer(next_m, next_p)
    end
  end
in
  loop_outer(mask, rgba)
end

// --- 4. POSTERIZE BLEND MODE ---
extern fun draw_dab_pixels_BlendMode_Posterize(
  mask: U16Buf, rgba: U16Buf, opacity: uint16, posterize_num: uint16
): void = "ext#draw_dab_pixels_BlendMode_Posterize"
implement draw_dab_pixels_BlendMode_Posterize(mask, rgba, opacity, posterize_num) = let
  val opacity_u = g0uint2uint_uint16_uint(opacity)
  val pnum_f = u2f(g0uint2uint_uint16_uint(posterize_num))

  fun loop_outer(m: U16Buf, p: U16Buf): void = let
    fun loop_inner(m_cur: U16Buf, p_cur: U16Buf): @(U16Buf, U16Buf) = let
      val mval = get_mask_val(m_cur)
    in
      if mval != 0U then let
        val cur_r = get_r(p_cur)
        val cur_g = get_g(p_cur)
        val cur_b = get_b(p_cur)

        val rf = u2f(cur_r) / 32768.0f
        val gf = u2f(cur_g) / 32768.0f
        val bf = u2f(cur_b) / 32768.0f

        val pr_f = f_div(f_mul(32768.0f, roundf(f_mul(rf, pnum_f))), pnum_f)
        val pg_f = f_div(f_mul(32768.0f, roundf(f_mul(gf, pnum_f))), pnum_f)
        val pb_f = f_div(f_mul(32768.0f, roundf(f_mul(bf, pnum_f))), pnum_f)

        val post_r = f2u(pr_f)
        val post_g = f2u(pg_f)
        val post_b = f2u(pb_f)

        val opa_a = (mval * opacity_u) / 32768U
        val opa_b = 32768U - opa_a

        val () = set_r(p_cur, (opa_a * post_r + opa_b * cur_r) / 32768U)
        val () = set_g(p_cur, (opa_a * post_g + opa_b * cur_g) / 32768U)
        val () = set_b(p_cur, (opa_a * post_b + opa_b * cur_b) / 32768U)
      in
        loop_inner(step(m_cur, 1), step(p_cur, 4))
      end else
        @(m_cur, p_cur)
    end

    val @(m_end, p_end) = loop_inner(m, p)
    val skip = get_mask_val(step(m_end, 1))
  in
    if skip = 0U then ()
    else let
      val next_p = step(p_end, g0uint2int_uint_int(skip))
      val next_m = step(m_end, 2)
    in
      loop_outer(next_m, next_p)
    end
  end
in
  loop_outer(mask, rgba)
end

// --- 5. COLORIZE BLEND MODE ---
fn set_rgb16_lum_from_rgb16(
  topr: uint, topg: uint, topb: uint, botr: &uint >> uint, botg: &uint >> uint, botb: &uint >> uint
): void = let
  val luma_r = 6966U // 0.2126 * 32768
  val luma_g = 23436U // 0.7152 * 32768
  val luma_b = 2366U // 0.0722 * 32768

  val botlum = (botr * luma_r + botg * luma_g + botb * luma_b) / 32768U
  val toplum = (topr * luma_r + topg * luma_g + topb * luma_b) / 32768U
  val diff: int = g0uint2int_uint_int(botlum) - g0uint2int_uint_int(toplum)

  var r: int = g0uint2int_uint_int(topr) + diff
  var g: int = g0uint2int_uint_int(topg) + diff
  var b: int = g0uint2int_uint_int(topb) + diff

  val lum_u = (g0int2uint_int_uint(if r > 0 then r else 0) * luma_r +
               g0int2uint_int_uint(if g > 0 then g else 0) * luma_g +
               g0int2uint_int_uint(if b > 0 then b else 0) * luma_b) / 32768U
  val lum: int = g0uint2int_uint_int(lum_u)

  val cmin = if i_lt(r, g) then (if i_lt(r, b) then r else b) else (if i_lt(g, b) then g else b)
  val cmax = if i_gt(r, g) then (if i_gt(r, b) then r else b) else (if i_gt(g, b) then g else b)

  val () =
    if i_lt(cmin, 0) then let
      val d = i_sub(lum, cmin)
      val () = if i_gt(d, 0) then (
        r := i_add(lum, i_div(i_mul(i_sub(r, lum), lum), d));
        g := i_add(lum, i_div(i_mul(i_sub(g, lum), lum), d));
        b := i_add(lum, i_div(i_mul(i_sub(b, lum), lum), d))
      )
    in () end

  val () =
    if i_gt(cmax, 32768) then let
      val d = i_sub(cmax, lum)
      val () = if i_gt(d, 0) then (
        r := i_add(lum, i_div(i_mul(i_sub(r, lum), i_sub(32768, lum)), d));
        g := i_add(lum, i_div(i_mul(i_sub(g, lum), i_sub(32768, lum)), d));
        b := i_add(lum, i_div(i_mul(i_sub(b, lum), i_sub(32768, lum)), d))
      )
    in () end

  val r_clamp = if i_lt(r, 0) then 0U else if i_gt(r, 32768) then 32768U else g0int2uint_int_uint(r)
  val g_clamp = if i_lt(g, 0) then 0U else if i_gt(g, 32768) then 32768U else g0int2uint_int_uint(g)
  val b_clamp = if i_lt(b, 0) then 0U else if i_gt(b, 32768) then 32768U else g0int2uint_int_uint(b)

  val () = botr := r_clamp
  val () = botg := g_clamp
  val () = botb := b_clamp
in () end

extern fun draw_dab_pixels_BlendMode_Color(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_Color"
implement draw_dab_pixels_BlendMode_Color(mask, rgba, color_r, color_g, color_b, opacity) = let
  val topr = g0uint2uint_uint16_uint(color_r)
  val topg = g0uint2uint_uint16_uint(color_g)
  val topb = g0uint2uint_uint16_uint(color_b)
  val opacity_u = g0uint2uint_uint16_uint(opacity)

  fun loop_outer(m: U16Buf, p: U16Buf): void = let
    fun loop_inner(m_cur: U16Buf, p_cur: U16Buf): @(U16Buf, U16Buf) = let
      val mval = get_mask_val(m_cur)
    in
      if mval != 0U then let
        val a = get_a(p_cur)
        var botr: uint = 0U
        var botg: uint = 0U
        var botb: uint = 0U
        val () =
          if a > 0U then (
            botr := (32768U * get_r(p_cur)) / a;
            botg := (32768U * get_g(p_cur)) / a;
            botb := (32768U * get_b(p_cur)) / a
          )

        val () = set_rgb16_lum_from_rgb16(topr, topg, topb, botr, botg, botb)

        val r_repre = (botr * a) / 32768U
        val g_repre = (botg * a) / 32768U
        val b_repre = (botb * a) / 32768U

        val opa_a = (mval * opacity_u) / 32768U
        val opa_b = 32768U - opa_a
        val cur_r = get_r(p_cur)
        val cur_g = get_g(p_cur)
        val cur_b = get_b(p_cur)

        val () = set_r(p_cur, (opa_a * r_repre + opa_b * cur_r) / 32768U)
        val () = set_g(p_cur, (opa_a * g_repre + opa_b * cur_g) / 32768U)
        val () = set_b(p_cur, (opa_a * b_repre + opa_b * cur_b) / 32768U)
      in
        loop_inner(step(m_cur, 1), step(p_cur, 4))
      end else
        @(m_cur, p_cur)
    end

    val @(m_end, p_end) = loop_inner(m, p)
    val skip = get_mask_val(step(m_end, 1))
  in
    if skip = 0U then ()
    else let
      val next_p = step(p_end, g0uint2int_uint_int(skip))
      val next_m = step(m_end, 2)
    in
      loop_outer(next_m, next_p)
    end
  end
in
  loop_outer(mask, rgba)
end

// --- 6. SPECTRAL PAINT BLEND MODES ---
extern fun draw_dab_pixels_BlendMode_Normal_Paint(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_Normal_Paint"
implement draw_dab_pixels_BlendMode_Normal_Paint(mask, rgba, color_r, color_g, color_b, opacity) =
  draw_dab_pixels_BlendMode_Normal(mask, rgba, color_r, color_g, color_b, opacity)

extern fun draw_dab_pixels_BlendMode_Normal_and_Eraser_Paint(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, color_a: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_Normal_and_Eraser_Paint"
implement draw_dab_pixels_BlendMode_Normal_and_Eraser_Paint(mask, rgba, color_r, color_g, color_b, color_a, opacity) =
  draw_dab_pixels_BlendMode_Normal_and_Eraser(mask, rgba, color_r, color_g, color_b, color_a, opacity)

extern fun draw_dab_pixels_BlendMode_LockAlpha_Paint(
  mask: U16Buf, rgba: U16Buf, color_r: uint16, color_g: uint16, color_b: uint16, opacity: uint16
): void = "ext#draw_dab_pixels_BlendMode_LockAlpha_Paint"
implement draw_dab_pixels_BlendMode_LockAlpha_Paint(mask, rgba, color_r, color_g, color_b, opacity) =
  draw_dab_pixels_BlendMode_LockAlpha(mask, rgba, color_r, color_g, color_b, opacity)


// --- 7. LEGACY AND ACCUMULATE COLOR SAMPLING ---
extern fun get_color_pixels_legacy(
  mask: U16Buf, rgba: U16Buf, sum_weight: FCell, sum_r: FCell, sum_g: FCell, sum_b: FCell, sum_a: FCell
): void = "ext#get_color_pixels_legacy"
implement get_color_pixels_legacy(mask, rgba, sum_weight, sum_r, sum_g, sum_b, sum_a) = let
  fun loop_outer(m: U16Buf, p: U16Buf, acc_w: uint, acc_r: uint, acc_g: uint, acc_b: uint, acc_a: uint): @(uint, uint, uint, uint, uint) = let
    fun loop_inner(m_cur: U16Buf, p_cur: U16Buf, w: uint, r: uint, g: uint, b: uint, a: uint): @(U16Buf, U16Buf, uint, uint, uint, uint, uint) = let
      val mval = get_mask_val(m_cur)
    in
      if mval != 0U then let
        val opa = mval
        val w_next = w + opa
        val r_next = r + (opa * get_r(p_cur)) / 32768U
        val g_next = g + (opa * get_g(p_cur)) / 32768U
        val b_next = b + (opa * get_b(p_cur)) / 32768U
        val a_next = a + (opa * get_a(p_cur)) / 32768U
      in
        loop_inner(step(m_cur, 1), step(p_cur, 4), w_next, r_next, g_next, b_next, a_next)
      end else
        @(m_cur, p_cur, w, r, g, b, a)
    end

    val @(m_end, p_end, w1, r1, g1, b1, a1) = loop_inner(m, p, acc_w, acc_r, acc_g, acc_b, acc_a)
    val skip = get_mask_val(step(m_end, 1))
  in
    if skip = 0U then @(w1, r1, g1, b1, a1)
    else let
      val next_p = step(p_end, g0uint2int_uint_int(skip))
      val next_m = step(m_end, 2)
    in
      loop_outer(next_m, next_p, w1, r1, g1, b1, a1)
    end
  end

  val @(w, r, g, b, a) = loop_outer(mask, rgba, 0U, 0U, 0U, 0U, 0U)
  fn add_accum(c: FCell, val_u: uint): void =
    if fcell_is_null(c) = 0 then let
      val p = fcell_ptr(c)
    in
      airlock_fset_n(p, 0, 1, f_add(airlock_fget_n(p, 0, 1), u2f(val_u)))
    end
  val () = add_accum(sum_weight, w)
  val () = add_accum(sum_r, r)
  val () = add_accum(sum_g, g)
  val () = add_accum(sum_b, b)
  val () = add_accum(sum_a, a)
in () end

extern fun get_color_pixels_accumulate(
  mask: U16Buf, rgba: U16Buf, sum_weight: FCell, sum_r: FCell, sum_g: FCell, sum_b: FCell, sum_a: FCell,
  paint: float, sample_interval: uint16, random_sample_rate: float
): void = "ext#get_color_pixels_accumulate"
implement get_color_pixels_accumulate(mask, rgba, sum_weight, sum_r, sum_g, sum_b, sum_a, paint, sample_interval, random_sample_rate) =
  get_color_pixels_legacy(mask, rgba, sum_weight, sum_r, sum_g, sum_b, sum_a)
