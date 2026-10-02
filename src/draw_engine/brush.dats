// src/draw_engine/brush.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "./settings.dats"
staload "./helpers.dats"
staload "./surface.dats"
#include "./brushsettings_gen.hats"

extern fun mypaint_brush_setting_info(id: int): ptr = "ext#mypaint_brush_setting_info"

%{^
#include <math.h>
#include <stdlib.h>
#include <string.h>
%}

#define BRUSH_STRUCT_SIZE 704

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)

fn get_state(b: ptr, i: int): float =
  $UN.ptr0_get<float>(ptr_add<float>(b, i))

fn set_state(b: ptr, i: int, v: float): void =
  $UN.ptr0_set<float>(ptr_add<float>(b, i), v)

fn get_base(b: ptr, i: int): float =
  $UN.ptr0_get<float>(ptr_add<float>(b, 44 + i))

fn set_base(b: ptr, i: int, v: float): void =
  $UN.ptr0_set<float>(ptr_add<float>(b, 44 + i), v)

fn get_val(b: ptr, i: int): float =
  $UN.ptr0_get<float>(ptr_add<float>(b, 109 + i))

fn set_val(b: ptr, i: int, v: float): void =
  $UN.ptr0_set<float>(ptr_add<float>(b, 109 + i), v)

fn get_reset(b: ptr): int =
  $UN.ptr0_get<int>(ptr_add<int>(b, 174))

fn set_reset(b: ptr, v: int): void =
  $UN.ptr0_set<int>(ptr_add<int>(b, 174), v)

extern fun memset(p: ptr, v: int, sz: size_t): ptr = "mac#memset"

fn clear_states(b: ptr): void = let
  val _ = memset(b, 0, g0int2uint_int_size(44) * sizeof<float>)
  val () = set_state(b, 35, ~1.0f) // BRUSH_STATE_FLIP = -1
in () end

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun expf(x: float): float = "mac#expf"
extern fun powf(x: float, y: float): float = "mac#powf"
extern fun hypotf(x: float, y: float): float = "mac#hypotf"

// Fırça Oluşturma
extern fun draw_engine_brush_new(): ptr = "ext#draw_engine_brush_new"
implement draw_engine_brush_new() = let
  val sz = g0int2uint_int_size(BRUSH_STRUCT_SIZE)
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val _ = memset(p, 0, sz)
  val () = clear_states(p)
  val () = set_reset(p, 1)

  fun init_defaults(b: ptr, i: int): void =
    if i < MYPAINT_BRUSH_SETTINGS_COUNT then let
      val info_p = mypaint_brush_setting_info(i)
      val () = if info_p != the_null_ptr then let
        val s = $UN.cast{ref(MyPaintBrushSettingInfo)}(info_p)
        val () = set_base(b, i, s->def)
        val () = set_val(b, i, s->def)
      in () end
    in init_defaults(b, i + 1) end else ()

  val () = init_defaults(p, 0)
in
  p
end

// Fırça Serbest Bırakma
extern fun draw_engine_brush_free(b: ptr): void = "ext#draw_engine_brush_free"
implement draw_engine_brush_free(b) =
  if b != the_null_ptr then free(b) else ()

// Fırça Sıfırlama İsteği
extern fun draw_engine_brush_reset(b: ptr): void = "ext#draw_engine_brush_reset"
implement draw_engine_brush_reset(b) =
  if b != the_null_ptr then set_reset(b, 1) else ()

// Yeni Çizgi Başlatma
extern fun draw_engine_brush_new_stroke(b: ptr): void = "ext#draw_engine_brush_new_stroke"
implement draw_engine_brush_new_stroke(b) = ()

// Fırça Temel Ayar Atama
extern fun draw_engine_brush_set_base_value(b: ptr, id: int, v: float): void = "ext#draw_engine_brush_set_base_value"
implement draw_engine_brush_set_base_value(b, id, v) =
  if b != the_null_ptr then
    if (id >= 0) * (id < 65) then let
      val () = set_base(b, id, v)
      val () = set_val(b, id, v)
    in () end else ()
  else ()

// Fırça Temel Ayar Okuma
extern fun draw_engine_brush_get_base_value(b: ptr, id: int): float = "ext#draw_engine_brush_get_base_value"
implement draw_engine_brush_get_base_value(b, id) =
  if b != the_null_ptr then
    if (id >= 0) * (id < 65) then get_base(b, id) else 0.0f
  else 0.0f

// Fırça Durum Değeri Okuma
extern fun draw_engine_brush_get_state(b: ptr, i: int): float = "ext#draw_engine_brush_get_state"
implement draw_engine_brush_get_state(b, i) =
  if b != the_null_ptr then
    if (i >= 0) * (i < 44) then get_state(b, i) else 0.0f
  else 0.0f

// Fırça Durum Değeri Atama
extern fun draw_engine_brush_set_state(b: ptr, i: int, v: float): void = "ext#draw_engine_brush_set_state"
implement draw_engine_brush_set_state(b, i, v) =
  if b != the_null_ptr then
    if (i >= 0) * (i < 44) then set_state(b, i, v) else ()
  else ()

// Yapılacak Dab Sayısını Hesaplama - Saf ATS2
fun count_dabs_to(b: ptr, x: float, y: float, dt: float): float = let
  val base_radius_log = get_base(b, BRUSH_SETTING_RADIUS_LOGARITHMIC)
  val base_radius_exp = expf(base_radius_log)
  val base_radius =
    if base_radius_exp < 0.2f then 0.2f
    else if base_radius_exp > 1000.0f then 1000.0f
    else base_radius_exp

  val cur_rad = get_state(b, BRUSH_STATE_ACTUAL_RADIUS)
  val actual_rad =
    if cur_rad <= 0.001f then let
      val () = set_state(b, BRUSH_STATE_ACTUAL_RADIUS, base_radius)
    in base_radius end
    else cur_rad

  val dx = f_sub(x, get_state(b, BRUSH_STATE_X))
  val dy = f_sub(y, get_state(b, BRUSH_STATE_Y))
  val dist = hypotf(dx, dy)

  val dabs_act_st = get_state(b, BRUSH_STATE_DABS_PER_ACTUAL_RADIUS)
  val dabs_bas_st = get_state(b, BRUSH_STATE_DABS_PER_BASIC_RADIUS)
  val dabs_sec_st = get_state(b, BRUSH_STATE_DABS_PER_SECOND)

  val is_zero = (dabs_act_st = 0.0f) * (dabs_bas_st = 0.0f) * (dabs_sec_st = 0.0f)
  val dabs_actual = if is_zero then get_val(b, BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS) else dabs_act_st
  val dabs_basic = if is_zero then get_val(b, BRUSH_SETTING_DABS_PER_BASIC_RADIUS) else dabs_bas_st
  val dabs_sec = if is_zero then get_val(b, BRUSH_SETTING_DABS_PER_SECOND) else dabs_sec_st

  val res1 = f_mul(f_div(dist, actual_rad), dabs_actual)
  val res2 = f_mul(f_div(dist, base_radius), dabs_basic)
  val res3 = f_mul(dt, dabs_sec)
  val total = f_add(res1, f_add(res2, res3))
in
  if total < 0.0f then 0.0f else total
end

// Durumları ve Dinamik Değerleri Güncelleme - Saf ATS2
fun update_states(
  b: ptr,
  step_ddab: float, step_dx: float, step_dy: float,
  step_dpress: float, step_dtime: float, viewzoom: float
): void = let
  val dt = if step_dtime <= 0.0f then 0.001f else step_dtime

  val cur_x = f_add(get_state(b, BRUSH_STATE_X), step_dx)
  val cur_y = f_add(get_state(b, BRUSH_STATE_Y), step_dy)
  val cur_p_raw = f_add(get_state(b, BRUSH_STATE_PRESSURE), step_dpress)
  val cur_p = if cur_p_raw < 0.0f then 0.0f else cur_p_raw

  val () = set_state(b, BRUSH_STATE_X, cur_x)
  val () = set_state(b, BRUSH_STATE_Y, cur_y)
  val () = set_state(b, BRUSH_STATE_PRESSURE, cur_p)
  val () = set_state(b, BRUSH_STATE_VIEWZOOM, viewzoom)

  val base_radius_log = get_base(b, BRUSH_SETTING_RADIUS_LOGARITHMIC)
  val base_radius_exp = expf(base_radius_log)
  val base_radius =
    if base_radius_exp < 0.2f then 0.2f
    else if base_radius_exp > 1000.0f then 1000.0f
    else base_radius_exp

  val norm_dx = f_mul(f_div(step_dx, dt), viewzoom)
  val norm_dy = f_mul(f_div(step_dy, dt), viewzoom)
  val norm_speed = hypotf(norm_dx, norm_dy)

  // Temel ayarları değerlere kopyala
  fun copy_settings(i: int): void =
    if i < 65 then let
      val () = set_val(b, i, get_base(b, i))
    in copy_settings(i + 1) end else ()
  val () = copy_settings(0)

  val () = set_state(b, BRUSH_STATE_DABS_PER_BASIC_RADIUS, get_val(b, BRUSH_SETTING_DABS_PER_BASIC_RADIUS))
  val () = set_state(b, BRUSH_STATE_DABS_PER_ACTUAL_RADIUS, get_val(b, BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS))
  val () = set_state(b, BRUSH_STATE_DABS_PER_SECOND, get_val(b, BRUSH_SETTING_DABS_PER_SECOND))

  // Dab başına yavaş takip (Slow tracking per dab)
  val slow_tracking_per_dab = get_val(b, BRUSH_SETTING_SLOW_TRACKING_PER_DAB)
  val fac = f_sub(1.0f, engine_exp_decay(slow_tracking_per_dab, step_ddab))
  val old_act_x = get_state(b, BRUSH_STATE_ACTUAL_X)
  val old_act_y = get_state(b, BRUSH_STATE_ACTUAL_Y)
  val () = set_state(b, BRUSH_STATE_ACTUAL_X, f_add(old_act_x, f_mul(f_sub(cur_x, old_act_x), fac)))
  val () = set_state(b, BRUSH_STATE_ACTUAL_Y, f_add(old_act_y, f_mul(f_sub(cur_y, old_act_y), fac)))

  // Yavaş hız (Slow speed)
  val s1_slowness = get_val(b, BRUSH_SETTING_SPEED1_SLOWNESS)
  val fac1 = f_sub(1.0f, engine_exp_decay(s1_slowness, dt))
  val old_s1 = get_state(b, BRUSH_STATE_NORM_SPEED1_SLOW)
  val () = set_state(b, BRUSH_STATE_NORM_SPEED1_SLOW, f_add(old_s1, f_mul(f_sub(norm_speed, old_s1), fac1)))

  val s2_slowness = get_val(b, BRUSH_SETTING_SPEED2_SLOWNESS)
  val fac2 = f_sub(1.0f, engine_exp_decay(s2_slowness, dt))
  val old_s2 = get_state(b, BRUSH_STATE_NORM_SPEED2_SLOW)
  val () = set_state(b, BRUSH_STATE_NORM_SPEED2_SLOW, f_add(old_s2, f_mul(f_sub(norm_speed, old_s2), fac2)))

  // Gerçek Yarıçap (Actual radius)
  val rad_log = get_val(b, BRUSH_SETTING_RADIUS_LOGARITHMIC)
  val rad_exp = expf(rad_log)
  val rad_clamped =
    if rad_exp < 0.2f then 0.2f
    else if rad_exp > 1000.0f then 1000.0f
    else rad_exp
  val () = set_state(b, BRUSH_STATE_ACTUAL_RADIUS, rad_clamped)

  val () = set_state(b, BRUSH_STATE_ACTUAL_ELLIPTICAL_DAB_RATIO, get_val(b, BRUSH_SETTING_ELLIPTICAL_DAB_RATIO))
  val () = set_state(b, BRUSH_STATE_ACTUAL_ELLIPTICAL_DAB_ANGLE, get_val(b, BRUSH_SETTING_ELLIPTICAL_DAB_ANGLE))
in () end

// Dab Hazırlama ve Çizme - Saf ATS2
fun prepare_and_draw_dab(b: ptr, surf: ptr): int = let
  val opaque_fac = get_val(b, BRUSH_SETTING_OPAQUE_MULTIPLY)
  val opaque_raw0 = get_val(b, BRUSH_SETTING_OPAQUE)
  val opaque_pos = if opaque_raw0 < 0.0f then 0.0f else opaque_raw0
  val opaque_mult = f_mul(opaque_pos, if opaque_fac > 0.0f then opaque_fac else 1.0f)
  val opaque_clamped = if opaque_mult > 1.0f then 1.0f else if opaque_mult < 0.0f then 0.0f else opaque_mult

  val opaque_linearize = get_base(b, BRUSH_SETTING_OPAQUE_LINEARIZE)
  val opaque_final =
    if opaque_linearize > 0.001f then let
      val sum_dabs = f_add(get_state(b, BRUSH_STATE_DABS_PER_ACTUAL_RADIUS), get_state(b, BRUSH_STATE_DABS_PER_BASIC_RADIUS))
      val dabs_per_pixel0 = f_mul(sum_dabs, 2.0f)
      val dabs_per_pixel = if dabs_per_pixel0 < 1.0f then 1.0f else dabs_per_pixel0
      val dpp = f_add(1.0f, f_mul(opaque_linearize, f_sub(dabs_per_pixel, 1.0f)))
      val beta = f_sub(1.0f, opaque_clamped)
      val beta_dab = powf(beta, f_div(1.0f, dpp))
    in
      f_sub(1.0f, beta_dab)
    end
    else opaque_clamped

  val x = get_state(b, BRUSH_STATE_ACTUAL_X)
  val y = get_state(b, BRUSH_STATE_ACTUAL_Y)
  val radius_raw = get_state(b, BRUSH_STATE_ACTUAL_RADIUS)

  val color_h = get_base(b, BRUSH_SETTING_COLOR_H)
  val color_s = get_base(b, BRUSH_SETTING_COLOR_S)
  val color_v = get_base(b, BRUSH_SETTING_COLOR_V)
  val @(color_r, color_g, color_b) = engine_hsv_to_rgb(color_h, color_s, color_v)

  val hardness_raw = get_val(b, BRUSH_SETTING_HARDNESS)
  val hardness = if hardness_raw < 0.0f then 0.0f else if hardness_raw > 1.0f then 1.0f else hardness_raw
  val softness = get_val(b, BRUSH_SETTING_SOFTNESS)

  // Kenar Yumuşatma (Anti-Aliasing)
  val current_fadeout = f_mul(radius_raw, f_sub(1.0f, hardness))
  val min_fadeout = get_val(b, BRUSH_SETTING_ANTI_ALIASING)

  val final_hardness =
    if (min_fadeout > 0.0f) * (current_fadeout < min_fadeout) then let
      val opt_rad = f_sub(radius_raw, f_div(f_mul(f_sub(1.0f, hardness), radius_raw), 2.0f))
      val half_min = f_div(min_fadeout, 2.0f)
      val h_calc = f_div(f_sub(opt_rad, half_min), f_add(opt_rad, half_min))
    in
      if h_calc < 0.0f then 0.0f else h_calc
    end else hardness

  val final_radius =
    if (min_fadeout > 0.0f) * (current_fadeout < min_fadeout) then
      f_div(min_fadeout, f_sub(1.0f, final_hardness))
    else radius_raw

  val eraser_val = get_val(b, BRUSH_SETTING_ERASER)
  val eraser_target_alpha = if eraser_val > 0.0f then f_sub(1.0f, eraser_val) else 1.0f

  val dab_ratio = get_state(b, BRUSH_STATE_ACTUAL_ELLIPTICAL_DAB_RATIO)
  val aspect = if dab_ratio < 1.0f then 1.0f else dab_ratio
  val angle = get_state(b, BRUSH_STATE_ACTUAL_ELLIPTICAL_DAB_ANGLE)
  val lock_alpha = get_val(b, BRUSH_SETTING_LOCK_ALPHA)
  val colorize = get_val(b, BRUSH_SETTING_COLORIZE)
  val posterize = get_val(b, BRUSH_SETTING_POSTERIZE)
  val posterize_num = get_val(b, BRUSH_SETTING_POSTERIZE_NUM)
  val paint_mode = 0.0f
in
  draw_engine_surface_draw_dab(
    surf, x, y, final_radius, color_r, color_g, color_b,
    opaque_final, final_hardness, softness, eraser_target_alpha,
    aspect, angle, lock_alpha, colorize, posterize, posterize_num, paint_mode
  )
end

// Çizgi İlerleme (Stroke To) - Saf ATS2
extern fun draw_engine_brush_stroke_to(
    b: ptr, surf: ptr,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#draw_engine_brush_stroke_to"

implement draw_engine_brush_stroke_to(b, surf, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear) =
  if b = the_null_ptr then 1
  else let
    val p_clean = if pressure < 0.0f then 0.0f else pressure
    val dt_clean = if dtime <= 0.0 then 0.0001 else dtime
    val dt_float = g0float2float_double_float(dt_clean)

    val is_reset = get_reset(b)
  in
    if (dtime > 5.0) || (is_reset > 0) then let
      val () = set_reset(b, 0)
      val () = clear_states(b)
      val () = set_state(b, BRUSH_STATE_X, x)
      val () = set_state(b, BRUSH_STATE_Y, y)
      val () = set_state(b, BRUSH_STATE_ACTUAL_X, x)
      val () = set_state(b, BRUSH_STATE_ACTUAL_Y, y)
      val () = set_state(b, BRUSH_STATE_PRESSURE, p_clean)
      val () = set_state(b, BRUSH_STATE_STROKE, 1.0f)

      val base_rad_log = get_base(b, BRUSH_SETTING_RADIUS_LOGARITHMIC)
      val base_rad_exp = expf(base_rad_log)
      val base_rad = if base_rad_exp < 0.2f then 0.2f else if base_rad_exp > 1000.0f then 1000.0f else base_rad_exp
      val () = set_state(b, BRUSH_STATE_ACTUAL_RADIUS, base_rad)
      val () = set_state(b, BRUSH_STATE_DABS_PER_BASIC_RADIUS, get_base(b, BRUSH_SETTING_DABS_PER_BASIC_RADIUS))
      val () = set_state(b, BRUSH_STATE_DABS_PER_ACTUAL_RADIUS, get_base(b, BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS))
      val () = set_state(b, BRUSH_STATE_DABS_PER_SECOND, get_base(b, BRUSH_SETTING_DABS_PER_SECOND))
    in 1 end
    else let
      // Yavaş takip filtresi (Slow tracking filter)
      val tracking = get_base(b, BRUSH_SETTING_SLOW_TRACKING)
      val fac = f_sub(1.0f, engine_exp_decay(tracking, f_mul(100.0f, dt_float)))
      val old_x = get_state(b, BRUSH_STATE_X)
      val old_y = get_state(b, BRUSH_STATE_Y)
      val target_x = f_add(old_x, f_mul(f_sub(x, old_x), fac))
      val target_y = f_add(old_y, f_mul(f_sub(y, old_y), fac))

      // Dab İterasyon Döngüsü
      fun dab_loop(dtime_left: double, dabs_moved: float, dabs_todo: float): @(double, float, float) =
        if f_add(dabs_moved, dabs_todo) >= 1.0f then let
          val step_ddab = if dabs_moved > 0.0f then f_sub(1.0f, dabs_moved) else 1.0f
          val frac = if dabs_todo > 0.00001f then f_div(step_ddab, dabs_todo) else 1.0f

          val cur_st_x = get_state(b, BRUSH_STATE_X)
          val cur_st_y = get_state(b, BRUSH_STATE_Y)
          val cur_st_p = get_state(b, BRUSH_STATE_PRESSURE)

          val step_dx = f_mul(frac, f_sub(target_x, cur_st_x))
          val step_dy = f_mul(frac, f_sub(target_y, cur_st_y))
          val step_dpress = f_mul(frac, f_sub(p_clean, cur_st_p))
          val step_dt_float = f_mul(frac, g0float2float_double_float(dtime_left))
          val step_dt = g0float2float_float_double(step_dt_float)

          val () = update_states(b, step_ddab, step_dx, step_dy, step_dpress, step_dt_float, viewzoom)
          val () = set_state(b, BRUSH_STATE_FLIP, f_mul(get_state(b, BRUSH_STATE_FLIP), ~1.0f))
          val _ = prepare_and_draw_dab(b, surf)

          val rem_dt = dtime_left - step_dt
          val next_todo = count_dabs_to(b, target_x, target_y, g0float2float_double_float(rem_dt))
        in
          dab_loop(rem_dt, 0.0f, next_todo)
        end
        else @(dtime_left, dabs_moved, dabs_todo)

      val init_todo = count_dabs_to(b, target_x, target_y, dt_float)
      val init_moved = get_state(b, BRUSH_STATE_PARTIAL_DABS)
      val @(rem_dt, rem_moved, rem_todo) = dab_loop(dt_clean, init_moved, init_todo)

      // Fırçayı güncel son konuma taşı
      val cur_st_x = get_state(b, BRUSH_STATE_X)
      val cur_st_y = get_state(b, BRUSH_STATE_Y)
      val cur_st_p = get_state(b, BRUSH_STATE_PRESSURE)
      val end_dx = f_sub(target_x, cur_st_x)
      val end_dy = f_sub(target_y, cur_st_y)
      val end_dpress = f_sub(p_clean, cur_st_p)
      val end_dt = g0float2float_double_float(rem_dt)

      val () = update_states(b, rem_todo, end_dx, end_dy, end_dpress, end_dt, viewzoom)
      val () = set_state(b, BRUSH_STATE_PARTIAL_DABS, f_add(rem_moved, rem_todo))
    in 0 end
  end
