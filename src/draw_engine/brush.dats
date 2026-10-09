// src/draw_engine/brush.dats
// Brush records live in a dynloaded arena. main.dats loads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"

staload "./settings.dats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/state_id.sats"
staload "draw_engine/input_id.sats"
staload "draw_engine/rng_box.sats"
staload "draw_engine/surface_box.sats"
staload "./helpers.dats"
staload "./surface.dats"
#include "./brushsettings_gen.hats"

#define BRUSH_CAP 8
#define BRUSH_NONE (~1)
#define ST_N 44
#define BV_N 65
#define ST_SLOTS 352
#define BV_SLOTS 520

val g_alive = arrayref_make_elt<bool>(i2sz(BRUSH_CAP), false)
val g_reset = arrayref_make_elt<int>(i2sz(BRUSH_CAP), 0)
val g_rng = arrayref_make_elt<MpRng>(i2sz(BRUSH_CAP), rng_none())
val g_state = arrayref_make_elt<float>(i2sz(ST_SLOTS), 0.0f)
val g_base = arrayref_make_elt<float>(i2sz(BV_SLOTS), 0.0f)
val g_val = arrayref_make_elt<float>(i2sz(BV_SLOTS), 0.0f)
val g_map = arrayref_make_elt<int>(i2sz(BV_SLOTS), 0)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(BRUSH_CAP), 0)

fn brush_alive(h: int): bool = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < BRUSH_CAP) then g_alive[i] else false
end

fn alloc_brush(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < BRUSH_CAP) then g_free[i] else BRUSH_NONE
  end else let
    val n = !g_fresh
  in
    if n < BRUSH_CAP then (!g_fresh := n + 1; n) else BRUSH_NONE
  end

fn recycle_brush(h: int): void = let
  val n = !g_nfree
  val i = g1ofg0(n)
  val hi = g1ofg0(h)
  val () = if (i >= 0) * (i < BRUSH_CAP) then g_free[i] := h
  val () = if (hi >= 0) * (hi < BRUSH_CAP) then g_alive[hi] := false
  val () = if (hi >= 0) * (hi < BRUSH_CAP) then !g_nfree := n + 1
in () end

fn st_get(h: int, i: int): float = let
  val s = g1ofg0(h * ST_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < ST_SLOTS) then g_state[s] else 0.0f
end

fn st_set(h: int, i: int, v: float): void = let
  val s = g1ofg0(h * ST_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < ST_SLOTS) then g_state[s] := v else ()
end

fn base_get(h: int, i: int): float = let
  val s = g1ofg0(h * BV_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < BV_SLOTS) then g_base[s] else 0.0f
end

fn base_set(h: int, i: int, v: float): void = let
  val s = g1ofg0(h * BV_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < BV_SLOTS) then g_base[s] := v else ()
end

fn val_get(h: int, i: int): float = let
  val s = g1ofg0(h * BV_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < BV_SLOTS) then g_val[s] else 0.0f
end

fn val_set(h: int, i: int, v: float): void = let
  val s = g1ofg0(h * BV_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < BV_SLOTS) then g_val[s] := v else ()
end

fn map_get(h: int, i: int): int = let
  val s = g1ofg0(h * BV_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < BV_SLOTS) then g_map[s] else MAPPING_NONE
end

fn map_set(h: int, i: int, m: int): void = let
  val s = g1ofg0(h * BV_N + i)
in
  if brush_alive(h) * (s >= 0) * (s < BV_SLOTS) then g_map[s] := m else ()
end

fn reset_get(h: int): int = let
  val i = g1ofg0(h)
in
  if brush_alive(h) * (i >= 0) * (i < BRUSH_CAP) then g_reset[i] else 0
end

fn reset_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if brush_alive(h) * (i >= 0) * (i < BRUSH_CAP) then g_reset[i] := v else ()
end

fn rng_get(h: int): MpRng = let
  val i = g1ofg0(h)
in
  if brush_alive(h) * (i >= 0) * (i < BRUSH_CAP) then g_rng[i] else rng_none()
end

fn rng_set(h: int, r: MpRng): void = let
  val i = g1ofg0(h)
in
  if brush_alive(h) * (i >= 0) * (i < BRUSH_CAP) then g_rng[i] := r else ()
end

fun zero_state(h: int, i: int): void =
  if i < ST_N then let
    val () = st_set(h, i, 0.0f)
  in zero_state(h, i + 1) end else ()

fun zero_base(h: int, i: int): void =
  if i < BV_N then let
    val () = base_set(h, i, 0.0f)
    val () = val_set(h, i, 0.0f)
    val () = map_set(h, i, 0)
  in zero_base(h, i + 1) end else ()

fn mp_brush_alloc(): int = let
  val h = alloc_brush()
  val () = assertloc(h >= 0)
  val i = g1ofg0(h)
  val () = if (i >= 0) * (i < BRUSH_CAP) then g_alive[i] := true
  val () = reset_set(h, 0)
  val () = rng_set(h, rng_none())
  val () = zero_state(h, 0)
  val () = zero_base(h, 0)
  val () = st_set(h, state_ix(StFlip()), ~1.0f)
in
  h
end

fn mp_brush_destroy(b: int): void = recycle_brush(b)

fn state_slot(id: BrushState): int = let
  val i = state_ix(id)
in
  if (i >= 0) * (i < ST_N) then i else ~1
end

fn mp_brush_get_state(b: int, id: BrushState): float = let
  val i = state_slot(id)
in
  if i >= 0 then st_get(b, i) else 0.0f
end

fn mp_brush_set_state(b: int, id: BrushState, v: float): void = let
  val i = state_slot(id)
in
  if i >= 0 then st_set(b, i, v)
end
fn mp_brush_get_base(b: int, i: int): float = base_get(b, i)
fn mp_brush_set_base(b: int, i: int, v: float): void = base_set(b, i, v)
fn mp_brush_get_val(b: int, i: int): float = val_get(b, i)
fn mp_brush_set_val(b: int, i: int, v: float): void = val_set(b, i, v)
fn mp_brush_get_reset(b: int): int = reset_get(b)
fn mp_brush_set_reset(b: int, v: int): void = reset_set(b, v)
fn mp_brush_get_mapping(b: int, i: int): int = map_get(b, i)
fn mp_brush_set_mapping(b: int, i: int, m: int): void = map_set(b, i, m)
fn mp_brush_get_rng(b: int): MpRng = rng_get(b)
fn mp_brush_set_rng(b: int, r: MpRng): void = rng_set(b, r)

fn mp_brush_clear_states(b: int): void = let
  val () = zero_state(b, 0)
in
  mp_brush_set_state(b, StFlip(), ~1.0f)
end

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)

extern fun expf(x: float): float = "mac#expf"
extern fun logf(x: float): float = "mac#logf"
extern fun fabsf(x: float): float = "mac#fabsf"
extern fun fmodf(x: float, y: float): float = "mac#fmodf"
extern fun powf(x: float, y: float): float = "mac#powf"
extern fun hypotf(x: float, y: float): float = "mac#hypotf"
extern fun rng_double_new(seed: lint): MpRng = "ext#rng_double_new"
extern fun rng_double_next(rng: MpRng): double = "ext#rng_double_next"
extern fun rng_double_free(rng: MpRng): void = "ext#rng_double_free"
extern fun rand_gauss(rng: MpRng): float = "ext#rand_gauss"

extern fun minepaint_mapping_new(inputs: int): int = "ext#minepaint_mapping_new"
extern fun minepaint_mapping_free(h: int): void = "ext#minepaint_mapping_free"
extern fun minepaint_mapping_set_base_value(h: int, value: float): void = "ext#minepaint_mapping_set_base_value"
extern fun minepaint_mapping_set_n(h: int, input: int, n: int): void = "ext#minepaint_mapping_set_n"
extern fun minepaint_mapping_get_n(h: int, input: int): int = "ext#minepaint_mapping_get_n"
extern fun minepaint_mapping_set_point(h: int, input: int, index: int, x: float, y: float): void = "ext#minepaint_mapping_set_point"
extern fun minepaint_mapping_calculate(h: int, data: &(@[float][MAPPING_INPUTS])): float = "ext#minepaint_mapping_calculate"
extern fun minepaint_brush_setting_info(id: int): MinePaintBrushSettingInfo = "ext#minepaint_brush_setting_info"

fn clear_mapping_curves(m: int): void = let
  fun loop(j: int): void =
    if j < MAPPING_INPUTS then let
      val () = minepaint_mapping_set_n(m, j, 0)
    in loop(j + 1) end else ()
in
  loop(0)
end

fn is_color_setting(i: int): bool =
  (i = 34) || (i = 35) || (i = 36)

fn reset_setting_default(b: int, i: int): void = let
  val s = minepaint_brush_setting_info(i)
  val m = mp_brush_get_mapping(b, i)
  val () = mp_brush_set_base(b, i, s.def)
  val () = mp_brush_set_val(b, i, s.def)
  val () = if m != MAPPING_NONE then minepaint_mapping_set_base_value(m, s.def)
in
  if m != MAPPING_NONE then clear_mapping_curves(m)
end

fn reset_settings(b: int, keep_color: int): void = let
  fun loop(i: int): void =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val skip = (keep_color > 0) && is_color_setting(i)
      val () = if skip then () else reset_setting_default(b, i)
    in loop(i + 1) end else ()
in
  loop(0)
end

fn alloc_mappings(b: int): void = let
  fun loop(i: int): void =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val m = minepaint_mapping_new(MAPPING_INPUTS)
      val () = mp_brush_set_mapping(b, i, m)
    in loop(i + 1) end else ()
in
  loop(0)
end

fn free_mappings(b: int): void = let
  fun loop(i: int): void =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val m = mp_brush_get_mapping(b, i)
      val () = if m != MAPPING_NONE then minepaint_mapping_free(m)
      val () = mp_brush_set_mapping(b, i, MAPPING_NONE)
    in loop(i + 1) end else ()
in
  loop(0)
end

extern fun draw_engine_brush_new(): int = "ext#draw_engine_brush_new"
implement draw_engine_brush_new() = let
  val p = mp_brush_alloc()
  val () = assertloc(p >= 0)
  val () = mp_brush_set_reset(p, 1)
  val () = alloc_mappings(p)
  val () = reset_settings(p, 0)
in
  p
end

extern fun draw_engine_brush_free(b: int): void = "ext#draw_engine_brush_free"
implement draw_engine_brush_free(b) =
  if b >= 0 then let
    val rng = mp_brush_get_rng(b)
    val () = if rng_is_null(rng) = 0 then rng_double_free(rng)
    val () = free_mappings(b)
  in
    mp_brush_destroy(b)
  end

extern fun draw_engine_brush_reset(b: int): void = "ext#draw_engine_brush_reset"
implement draw_engine_brush_reset(b) =
  if b >= 0 then mp_brush_set_reset(b, 1)

extern fun draw_engine_brush_new_stroke(b: int): void = "ext#draw_engine_brush_new_stroke"
implement draw_engine_brush_new_stroke(b) = ()

extern fun draw_engine_brush_set_base_value(b: int, id: SettingId, v: float): void = "ext#draw_engine_brush_set_base_value"
implement draw_engine_brush_set_base_value(b, id, v) = let
  val ix = setting_ix(id)
in
  if b >= 0 then
    if (ix >= 0) * (ix < 65) then let
      val m = mp_brush_get_mapping(b, ix)
      val () = mp_brush_set_base(b, ix, v)
      val () = mp_brush_set_val(b, ix, v)
    in
      if m != MAPPING_NONE then minepaint_mapping_set_base_value(m, v)
    end
end

extern fun draw_engine_brush_set_mapping_n(
  b: int, setting: SettingId, input: InputId, n: int
): void = "ext#draw_engine_brush_set_mapping_n"
implement draw_engine_brush_set_mapping_n(b, setting, input, n) = let
  val ix = setting_ix(setting)
  val iin = input_ix(input)
in
  if b >= 0 then
    if (ix >= 0) * (ix < 65) * (iin >= 0) * (iin < 18) * (n >= 0) * (n <= 64) * (n != 1) then
      minepaint_mapping_set_n(mp_brush_get_mapping(b, ix), iin, n)
end

extern fun draw_engine_brush_set_mapping_point(
  b: int, setting: SettingId, input: InputId, index: int, x: float, y: float
): void = "ext#draw_engine_brush_set_mapping_point"
implement draw_engine_brush_set_mapping_point(b, setting, input, index, x, y) = let
  val ix = setting_ix(setting)
  val iin = input_ix(input)
in
  if b >= 0 then
    if (ix >= 0) * (ix < 65) * (iin >= 0) * (iin < 18) then
      minepaint_mapping_set_point(mp_brush_get_mapping(b, ix), iin, index, x, y)
end

extern fun draw_engine_brush_prepare_load(b: int): void = "ext#draw_engine_brush_prepare_load"
implement draw_engine_brush_prepare_load(b) =
  if b >= 0 then let
    val () = reset_settings(b, 1)
  in
    mp_brush_set_reset(b, 1)
  end

fn apply_startup_base_values(b: int): void = let
  val () = reset_settings(b, 0)
  val () = draw_engine_brush_set_base_value(b, SetOpaque(), 1.0f)
  val () = draw_engine_brush_set_base_value(b, SetOpaqueLinearize(), 1.0f)
  val () = draw_engine_brush_set_base_value(b, SetOpaqueMultiply(), 1.0f)
  val () = draw_engine_brush_set_base_value(b, SetRadiusLogarithmic(), 1.2f)
  val () = draw_engine_brush_set_base_value(b, SetHardness(), 0.1f)
  val () = draw_engine_brush_set_base_value(b, SetDabsPerActualRadius(), 5.0f)
  val () = draw_engine_brush_set_base_value(b, SetDabsPerSecond(), 40.0f)
  val () = draw_engine_brush_set_base_value(b, SetSlowTracking(), 3.0f)
  val () = draw_engine_brush_set_base_value(b, SetTrackingNoise(), 0.0f)
  val () = draw_engine_brush_set_base_value(b, SetAntiAliasing(), 1.0f)
  val () = draw_engine_brush_set_base_value(b, SetColorH(), 1.0f)
  val () = draw_engine_brush_set_base_value(b, SetColorS(), 0.0f)
  val () = draw_engine_brush_set_base_value(b, SetColorV(), 0.729f)
in
  draw_engine_brush_set_base_value(b, SetPaintMode(), 0.0f)
end

fn apply_startup_dynamics(b: int): void = let
  val () = draw_engine_brush_set_mapping_n(b, SetRadiusLogarithmic(), InPressure(), 4)
  val () = draw_engine_brush_set_mapping_point(b, SetRadiusLogarithmic(), InPressure(), 0, 0.0f, ~1.4f)
  val () = draw_engine_brush_set_mapping_point(b, SetRadiusLogarithmic(), InPressure(), 1, 0.8f, 0.0f)
  val () = draw_engine_brush_set_mapping_point(b, SetRadiusLogarithmic(), InPressure(), 2, 1.0f, 0.35f)
  val () = draw_engine_brush_set_mapping_point(b, SetRadiusLogarithmic(), InPressure(), 3, 2.0f, 0.7f)

  val () = draw_engine_brush_set_mapping_n(b, SetOpaqueMultiply(), InPressure(), 4)
  val () = draw_engine_brush_set_mapping_point(b, SetOpaqueMultiply(), InPressure(), 0, 0.0f, ~1.0f)
  val () = draw_engine_brush_set_mapping_point(b, SetOpaqueMultiply(), InPressure(), 1, 0.8f, 0.0f)
  val () = draw_engine_brush_set_mapping_point(b, SetOpaqueMultiply(), InPressure(), 2, 1.0f, 0.0f)
  val () = draw_engine_brush_set_mapping_point(b, SetOpaqueMultiply(), InPressure(), 3, 2.0f, 0.0f)
in
  mp_brush_set_reset(b, 1)
end

extern fun draw_engine_brush_apply_startup(b: int): void = "ext#draw_engine_brush_apply_startup"
implement draw_engine_brush_apply_startup(b) =
  if b >= 0 then let
    val () = apply_startup_base_values(b)
  in
    apply_startup_dynamics(b)
  end

extern fun draw_engine_brush_get_base_value(b: int, id: SettingId): float = "ext#draw_engine_brush_get_base_value"
implement draw_engine_brush_get_base_value(b, id) = let
  val ix = setting_ix(id)
in
  if b >= 0 then
    if (ix >= 0) * (ix < 65) then mp_brush_get_base(b, ix) else 0.0f
  else 0.0f
end

extern fun draw_engine_brush_get_state(b: int, id: BrushState): float = "ext#draw_engine_brush_get_state"
implement draw_engine_brush_get_state(b, id) =
  if b >= 0 then mp_brush_get_state(b, id) else 0.0f

extern fun draw_engine_brush_set_state(b: int, id: BrushState, v: float): void = "ext#draw_engine_brush_set_state"
implement draw_engine_brush_set_state(b, id, v) =
  if b >= 0 then mp_brush_set_state(b, id, v)

fn clamp_radius(r_exp: float): float =
  if r_exp < 0.2f then 0.2f
  else if r_exp > 1000.0f then 1000.0f
  else r_exp

fn calc_actual_rad(b: int, base_radius: float): float = let
  val cur_rad = mp_brush_get_state(b, StActualRadius())
in
  if cur_rad <= 0.001f then let
    val () = mp_brush_set_state(b, StActualRadius(), base_radius)
  in base_radius end
  else cur_rad
end

fn calc_dab_rates(b: int): @(float, float, float) = let
  val dabs_act_st = mp_brush_get_state(b, StDabsPerActualRadius())
  val dabs_bas_st = mp_brush_get_state(b, StDabsPerBasicRadius())
  val dabs_sec_st = mp_brush_get_state(b, StDabsPerSecond())
  val is_zero = (dabs_act_st = 0.0f) * (dabs_bas_st = 0.0f) * (dabs_sec_st = 0.0f)
  val dabs_actual = if is_zero then mp_brush_get_val(b, setting_ix(SetDabsPerActualRadius())) else dabs_act_st
  val dabs_basic = if is_zero then mp_brush_get_val(b, setting_ix(SetDabsPerBasicRadius())) else dabs_bas_st
  val dabs_sec = if is_zero then mp_brush_get_val(b, setting_ix(SetDabsPerSecond())) else dabs_sec_st
in
  @(dabs_actual, dabs_basic, dabs_sec)
end

fun count_dabs_to(b: int, x: float, y: float, dt: float): float = let
  val base_radius = clamp_radius(expf(mp_brush_get_base(b, setting_ix(SetRadiusLogarithmic()))))
  val actual_rad = calc_actual_rad(b, base_radius)
  val dx = f_sub(x, mp_brush_get_state(b, StX()))
  val dy = f_sub(y, mp_brush_get_state(b, StY()))
  val dist = hypotf(dx, dy)
  val @(dabs_actual, dabs_basic, dabs_sec) = calc_dab_rates(b)
  val res1 = f_mul(f_div(dist, actual_rad), dabs_actual)
  val res2 = f_mul(f_div(dist, base_radius), dabs_basic)
  val res3 = f_mul(dt, dabs_sec)
  val total = f_add(res1, f_add(res2, res3))
in
  if total < 0.0f then 0.0f else total
end

fn jitter_rng(b: int): MpRng = let
  val p = mp_brush_get_rng(b)
in
  if rng_is_null(p) != 0 then let
    val n = rng_double_new(1L)
    val () = mp_brush_set_rng(b, n)
  in n end else p
end

fn speed_input(gamma_log: float, speed: float): float = let
  val gamma = expf(gamma_log)
  val c1 = logf(f_add(45.0f, gamma))
  val m = f_mul(0.015f, f_add(45.0f, gamma))
  val q = f_sub(0.5f, f_mul(m, c1))
  val x = if speed < 0.0f then 0.0f else speed
  val arg0 = f_add(gamma, x)
  val arg = if arg0 < 0.000001f then 0.000001f else arg0
in
  f_add(f_mul(logf(arg), m), q)
end

fn viewzoom_input(base_log: float, zoom: float): float = let
  val z = if zoom < 0.01f then 0.01f else zoom
  val base_r0 = expf(base_log)
  val base_r = if base_r0 < 0.000001f then 0.000001f else base_r0
in
  f_sub(base_log, logf(f_div(base_r, z)))
end

fn grid_coord(pos: float, scale: float, axis_scale: float): float = let
  val scaled0 = f_mul(scale, 256.0f)
  val scaled = if scaled0 < 0.0001f then 0.0001f else scaled0
  val mag = fabsf(f_mul(pos, axis_scale))
  val wrapped = fmodf(mag, scaled)
  val v = f_mul(f_div(wrapped, scaled), 256.0f)
in
  if pos < 0.0f then f_sub(256.0f, v) else v
end

fn in_set(arr: &(@[float][MAPPING_INPUTS]), id: InputId, v: float): void = let
  val idx = g1ofg0(input_ix(id))
in
  if (idx >= 0) * (idx < MAPPING_INPUTS) then arr[idx] := v else ()
end

fn populate_input_buffer(
  b: int, in_p: &(@[float][MAPPING_INPUTS]), cur_p: float, viewzoom: float, base_radius_log: float
): void = let
  val gain = expf(mp_brush_get_base(b, setting_ix(SetPressureGainLog())))
  val zoom_lin = if viewzoom < 0.01f then 0.01f else viewzoom
  val gscale = expf(mp_brush_get_val(b, setting_ix(SetGridmapScale())))
  val () = in_set(in_p, InPressure(), f_mul(cur_p, gain))
  val () = in_set(in_p, InRandom(), g0float2float_double_float(rng_double_next(jitter_rng(b))))
  val () = in_set(in_p, InStroke(), mp_brush_get_state(b, StStroke()))
  val () = in_set(in_p, InSpeed1(), speed_input(mp_brush_get_base(b, setting_ix(SetSpeed1Gamma())), mp_brush_get_state(b, StNormSpeed1Slow())))
  val () = in_set(in_p, InSpeed2(), speed_input(mp_brush_get_base(b, setting_ix(SetSpeed2Gamma())), mp_brush_get_state(b, StNormSpeed2Slow())))
  val () = in_set(in_p, InGridmapX(), grid_coord(mp_brush_get_state(b, StActualX()), gscale, mp_brush_get_val(b, setting_ix(SetGridmapScaleX()))))
  val () = in_set(in_p, InGridmapY(), grid_coord(mp_brush_get_state(b, StActualY()), gscale, mp_brush_get_val(b, setting_ix(SetGridmapScaleY()))))
  val () = in_set(in_p, InViewzoom(), viewzoom_input(base_radius_log, zoom_lin))
in
  in_set(in_p, InBrushRadius(), base_radius_log)
end

fun eval_mapping_slot(
  b: int, in_p: &(@[float][MAPPING_INPUTS]), i: int
): void =
  if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
    val m = mp_brush_get_mapping(b, i)
    val v = if m != MAPPING_NONE then minepaint_mapping_calculate(m, in_p) else mp_brush_get_base(b, i)
    val () = mp_brush_set_val(b, i, v)
  in eval_mapping_slot(b, in_p, i + 1) end
  else ()

fn eval_mappings(b: int, in_p: &(@[float][MAPPING_INPUTS])): void =
  eval_mapping_slot(b, in_p, 0)

fn update_tracking_speed(
  b: int, cur_x: float, cur_y: float, norm_speed: float, step_ddab: float, dt: float
): void = let
  val slow_tracking_per_dab = mp_brush_get_val(b, setting_ix(SetSlowTrackingPerDab()))
  val fac = f_sub(1.0f, engine_exp_decay(slow_tracking_per_dab, step_ddab))
  val old_act_x = mp_brush_get_state(b, StActualX())
  val old_act_y = mp_brush_get_state(b, StActualY())
  val () = mp_brush_set_state(b, StActualX(), f_add(old_act_x, f_mul(f_sub(cur_x, old_act_x), fac)))
  val () = mp_brush_set_state(b, StActualY(), f_add(old_act_y, f_mul(f_sub(cur_y, old_act_y), fac)))

  val s1_slowness = mp_brush_get_val(b, setting_ix(SetSpeed1Slowness()))
  val fac1 = f_sub(1.0f, engine_exp_decay(s1_slowness, dt))
  val old_s1 = mp_brush_get_state(b, StNormSpeed1Slow())
  val () = mp_brush_set_state(b, StNormSpeed1Slow(), f_add(old_s1, f_mul(f_sub(norm_speed, old_s1), fac1)))

  val s2_slowness = mp_brush_get_val(b, setting_ix(SetSpeed2Slowness()))
  val fac2 = f_sub(1.0f, engine_exp_decay(s2_slowness, dt))
  val old_s2 = mp_brush_get_state(b, StNormSpeed2Slow())
in
  mp_brush_set_state(b, StNormSpeed2Slow(), f_add(old_s2, f_mul(f_sub(norm_speed, old_s2), fac2)))
end

fn update_actual_geometry(b: int): void = let
  val rad_log = mp_brush_get_val(b, setting_ix(SetRadiusLogarithmic()))
  val rad_clamped = clamp_radius(expf(rad_log))
  val () = mp_brush_set_state(b, StActualRadius(), rad_clamped)
  val () = mp_brush_set_state(b, StActualEllipticalDabRatio(), mp_brush_get_val(b, setting_ix(SetEllipticalDabRatio())))
in
  mp_brush_set_state(b, StActualEllipticalDabAngle(), mp_brush_get_val(b, setting_ix(SetEllipticalDabAngle())))
end

fun update_states(
  b: int,
  step_ddab: float, step_dx: float, step_dy: float,
  step_dpress: float, step_dtime: float, viewzoom: float
): void = let
  val dt = if step_dtime <= 0.0f then 0.001f else step_dtime
  val cur_x = f_add(mp_brush_get_state(b, StX()), step_dx)
  val cur_y = f_add(mp_brush_get_state(b, StY()), step_dy)
  val cur_p_raw = f_add(mp_brush_get_state(b, StPressure()), step_dpress)
  val cur_p = if cur_p_raw < 0.0f then 0.0f else cur_p_raw

  val () = mp_brush_set_state(b, StX(), cur_x)
  val () = mp_brush_set_state(b, StY(), cur_y)
  val () = mp_brush_set_state(b, StPressure(), cur_p)
  val () = mp_brush_set_state(b, StViewzoom(), viewzoom)

  val base_radius_log = mp_brush_get_base(b, setting_ix(SetRadiusLogarithmic()))
  val norm_dx = f_mul(f_div(step_dx, dt), viewzoom)
  val norm_dy = f_mul(f_div(step_dy, dt), viewzoom)
  val norm_speed = hypotf(norm_dx, norm_dy)

  var inbuf = @[float][MAPPING_INPUTS](0.0f)
  val () = populate_input_buffer(b, inbuf, cur_p, viewzoom, base_radius_log)
  val () = eval_mappings(b, inbuf)

  val () = mp_brush_set_state(b, StDabsPerBasicRadius(), mp_brush_get_val(b, setting_ix(SetDabsPerBasicRadius())))
  val () = mp_brush_set_state(b, StDabsPerActualRadius(), mp_brush_get_val(b, setting_ix(SetDabsPerActualRadius())))
  val () = mp_brush_set_state(b, StDabsPerSecond(), mp_brush_get_val(b, setting_ix(SetDabsPerSecond())))

  val () = update_tracking_speed(b, cur_x, cur_y, norm_speed, step_ddab, dt)
in
  update_actual_geometry(b)
end

fn compute_opaque_final(b: int): float = let
  val opaque_fac = mp_brush_get_val(b, setting_ix(SetOpaqueMultiply()))
  val opaque_raw0 = mp_brush_get_val(b, setting_ix(SetOpaque()))
  val opaque_pos = if opaque_raw0 < 0.0f then 0.0f else opaque_raw0
  val opaque_mult = f_mul(opaque_pos, if opaque_fac > 0.0f then opaque_fac else 1.0f)
  val opaque_clamped = if opaque_mult > 1.0f then 1.0f else if opaque_mult < 0.0f then 0.0f else opaque_mult
  val opaque_linearize = mp_brush_get_base(b, setting_ix(SetOpaqueLinearize()))
in
  if opaque_linearize > 0.001f then let
    val sum_dabs = f_add(mp_brush_get_state(b, StDabsPerActualRadius()), mp_brush_get_state(b, StDabsPerBasicRadius()))
    val dabs_per_pixel0 = f_mul(sum_dabs, 2.0f)
    val dabs_per_pixel = if dabs_per_pixel0 < 1.0f then 1.0f else dabs_per_pixel0
    val dpp = f_add(1.0f, f_mul(opaque_linearize, f_sub(dabs_per_pixel, 1.0f)))
    val beta = f_sub(1.0f, opaque_clamped)
    val beta_dab = powf(beta, f_div(1.0f, dpp))
  in
    f_sub(1.0f, beta_dab)
  end
  else opaque_clamped
end

fn compute_anti_aliased_dab(radius_raw: float, hardness: float, min_fadeout: float): @(float, float) = let
  val current_fadeout = f_mul(radius_raw, f_sub(1.0f, hardness))
in
  if (min_fadeout > 0.0f) * (current_fadeout < min_fadeout) then let
    val opt_rad = f_sub(radius_raw, f_div(f_mul(f_sub(1.0f, hardness), radius_raw), 2.0f))
    val half_min = f_div(min_fadeout, 2.0f)
    val h_calc = f_div(f_sub(opt_rad, half_min), f_add(opt_rad, half_min))
    val final_h = if h_calc < 0.0f then 0.0f else h_calc
    val final_r = f_div(min_fadeout, f_sub(1.0f, final_h))
  in
    @(final_r, final_h)
  end
  else @(radius_raw, hardness)
end

fun prepare_and_draw_dab(b: int, surf: MpSurface): int = let
  val opaque_final = compute_opaque_final(b)
  val jitter = mp_brush_get_val(b, setting_ix(SetOffsetByRandom()))
  val amp = if g0float_gt(jitter, 0.0f) then jitter else 0.0f
  val base_r = expf(mp_brush_get_base(b, setting_ix(SetRadiusLogarithmic())))
  val spread = f_mul(amp, base_r)
  val use_jitter = g0float_gt(amp, 0.0f)
  val jx = if use_jitter then f_mul(rand_gauss(jitter_rng(b)), spread) else 0.0f
  val jy = if use_jitter then f_mul(rand_gauss(jitter_rng(b)), spread) else 0.0f
  val x = f_add(mp_brush_get_state(b, StActualX()), jx)
  val y = f_add(mp_brush_get_state(b, StActualY()), jy)
  val radius_raw = mp_brush_get_state(b, StActualRadius())

  val @(color_r, color_g, color_b) = engine_hsv_to_rgb(
    mp_brush_get_base(b, setting_ix(SetColorH())),
    mp_brush_get_base(b, setting_ix(SetColorS())),
    mp_brush_get_base(b, setting_ix(SetColorV()))
  )

  val hardness_raw = mp_brush_get_val(b, setting_ix(SetHardness()))
  val hardness = if hardness_raw < 0.0f then 0.0f else if hardness_raw > 1.0f then 1.0f else hardness_raw
  val softness = mp_brush_get_val(b, setting_ix(SetSoftness()))
  val min_fadeout = mp_brush_get_val(b, setting_ix(SetAntiAliasing()))
  val @(final_radius, final_hardness) = compute_anti_aliased_dab(radius_raw, hardness, min_fadeout)

  val eraser_val = mp_brush_get_val(b, setting_ix(SetEraser()))
  val eraser_target_alpha = if eraser_val > 0.0f then f_sub(1.0f, eraser_val) else 1.0f
  val dab_ratio = mp_brush_get_state(b, StActualEllipticalDabRatio())
  val aspect = if dab_ratio < 1.0f then 1.0f else dab_ratio
  val angle = mp_brush_get_state(b, StActualEllipticalDabAngle())
  val paint_raw = mp_brush_get_val(b, setting_ix(SetPaintMode()))
  val paint_mode = if paint_raw < 0.0f then 0.0f else if paint_raw > 1.0f then 1.0f else paint_raw
in
  draw_engine_surface_draw_dab(
    surf, x, y, final_radius, color_r, color_g, color_b,
    opaque_final, final_hardness, softness, eraser_target_alpha,
    aspect, angle, mp_brush_get_val(b, setting_ix(SetLockAlpha())),
    mp_brush_get_val(b, setting_ix(SetColorize())),
    mp_brush_get_val(b, setting_ix(SetPosterize())),
    mp_brush_get_val(b, setting_ix(SetPosterizeNum())),
    paint_mode
  )
end

fn reset_stroke_state(b: int, x: float, y: float, p_clean: float): int = let
  val () = mp_brush_set_reset(b, 0)
  val () = mp_brush_clear_states(b)
  val () = mp_brush_set_state(b, StX(), x)
  val () = mp_brush_set_state(b, StY(), y)
  val () = mp_brush_set_state(b, StActualX(), x)
  val () = mp_brush_set_state(b, StActualY(), y)
  val () = mp_brush_set_state(b, StPressure(), p_clean)
  val () = mp_brush_set_state(b, StStroke(), 1.0f)
  val base_rad = clamp_radius(expf(mp_brush_get_base(b, setting_ix(SetRadiusLogarithmic()))))
  val () = mp_brush_set_state(b, StActualRadius(), base_rad)
  val () = mp_brush_set_state(b, StDabsPerBasicRadius(), mp_brush_get_base(b, setting_ix(SetDabsPerBasicRadius())))
  val () = mp_brush_set_state(b, StDabsPerActualRadius(), mp_brush_get_base(b, setting_ix(SetDabsPerActualRadius())))
  val () = mp_brush_set_state(b, StDabsPerSecond(), mp_brush_get_base(b, setting_ix(SetDabsPerSecond())))
in
  1
end

fun dab_loop(
  b: int, surf: MpSurface, target_x: float, target_y: float, p_clean: float,
  dtime_left: double, dabs_moved: float, dabs_todo: float, viewzoom: float
): @(double, float, float) =
  if f_add(dabs_moved, dabs_todo) >= 1.0f then let
    val step_ddab = if dabs_moved > 0.0f then f_sub(1.0f, dabs_moved) else 1.0f
    val frac = if dabs_todo > 0.00001f then f_div(step_ddab, dabs_todo) else 1.0f

    val cur_st_x = mp_brush_get_state(b, StX())
    val cur_st_y = mp_brush_get_state(b, StY())
    val cur_st_p = mp_brush_get_state(b, StPressure())

    val step_dx = f_mul(frac, f_sub(target_x, cur_st_x))
    val step_dy = f_mul(frac, f_sub(target_y, cur_st_y))
    val step_dpress = f_mul(frac, f_sub(p_clean, cur_st_p))
    val step_dt_float = f_mul(frac, g0float2float_double_float(dtime_left))
    val step_dt = g0float2float_float_double(step_dt_float)

    val () = update_states(b, step_ddab, step_dx, step_dy, step_dpress, step_dt_float, viewzoom)
    val () = mp_brush_set_state(b, StFlip(), f_mul(mp_brush_get_state(b, StFlip()), ~1.0f))
    val _ = prepare_and_draw_dab(b, surf)

    val rem_dt = dtime_left - step_dt
    val next_todo = count_dabs_to(b, target_x, target_y, g0float2float_double_float(rem_dt))
  in
    dab_loop(b, surf, target_x, target_y, p_clean, rem_dt, 0.0f, next_todo, viewzoom)
  end
  else @(dtime_left, dabs_moved, dabs_todo)

extern fun draw_engine_brush_stroke_to(
    b: int, surf: MpSurface,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#draw_engine_brush_stroke_to"
implement draw_engine_brush_stroke_to(
  b, surf, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear
) =
  if b < 0 then 1
  else let
    val p_clean = if pressure < 0.0f then 0.0f else pressure
    val dt_clean = if dtime <= 0.0 then 0.0001 else dtime
    val dt_float = g0float2float_double_float(dt_clean)
    val is_reset = mp_brush_get_reset(b)
  in
    if (dtime > 5.0) || (is_reset > 0) then reset_stroke_state(b, x, y, p_clean)
    else let
      val tracking = mp_brush_get_val(b, setting_ix(SetSlowTracking()))
      val fac = f_sub(1.0f, engine_exp_decay(tracking, f_mul(100.0f, dt_float)))
      val old_x = mp_brush_get_state(b, StX())
      val old_y = mp_brush_get_state(b, StY())
      val target_x = f_add(old_x, f_mul(f_sub(x, old_x), fac))
      val target_y = f_add(old_y, f_mul(f_sub(y, old_y), fac))

      val init_todo = count_dabs_to(b, target_x, target_y, dt_float)
      val init_moved = mp_brush_get_state(b, StPartialDabs())
      val @(rem_dt, rem_moved, rem_todo) = dab_loop(
        b, surf, target_x, target_y, p_clean, dt_clean, init_moved, init_todo, viewzoom
      )

      val end_dx = f_sub(target_x, mp_brush_get_state(b, StX()))
      val end_dy = f_sub(target_y, mp_brush_get_state(b, StY()))
      val end_dpress = f_sub(p_clean, mp_brush_get_state(b, StPressure()))
      val end_dt = g0float2float_double_float(rem_dt)

      val () = update_states(b, rem_todo, end_dx, end_dy, end_dpress, end_dt, viewzoom)
      val () = mp_brush_set_state(b, StPartialDabs(), f_add(rem_moved, rem_todo))
    in
      0
    end
  end
