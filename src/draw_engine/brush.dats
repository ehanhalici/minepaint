// src/draw_engine/brush.dats
// Brush records live in an arena. main.dats initialises this file at startup.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "sys/airlock.hats"
#include "sys/arena.hats"
staload "gl/gl_io.sats"
staload "sys/capability.sats"
staload "draw_engine/brush_view.sats"

staload "./settings.dats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/state_id.sats"
staload "draw_engine/input_id.sats"
staload "draw_engine/surface_target.sats"
staload "./helpers.dats"
staload "sys/libc.dats"
#include "./brushsettings_gen.hats"

#define BRUSH_NONE (~1)
#define RNG_NONE (~1)
#define ST_N 44
#define BV_N 65
#define ST_SLOTS 352
#define BV_SLOTS 520

// E.3: arenalar `arrayref`; fircaya ve ayar/durum numarasina ait ham int'ler `ix_try` ile tipli indekse
// cevrilir, slot hesabi (h * N + i) derleme zamaninda sinirli. Gecersiz/olu tutamac politikasi (eski davranis):
// okuma varsayilan deger, yazma etkisiz.
typedef BIx = Ix(BRUSH_CAP)

val g_alive = arrayref_make_elt<int>(i2sz(BRUSH_CAP), 0)
val g_reset = arrayref_make_elt<int>(i2sz(BRUSH_CAP), 0)
val g_claim = arrayref_make_elt<int>(i2sz(BRUSH_CAP), 0)
val g_rng = arrayref_make_elt<int>(i2sz(BRUSH_CAP), RNG_NONE)
val g_state = arrayref_make_elt<float>(i2sz(ST_SLOTS), 0.0f)
val g_base = arrayref_make_elt<float>(i2sz(BV_SLOTS), 0.0f)
val g_val = arrayref_make_elt<float>(i2sz(BV_SLOTS), 0.0f)
val g_map = arrayref_make_elt<int>(i2sz(BV_SLOTS), 0)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(BRUSH_CAP), 0)

fn st_slot {h:nat | h < BRUSH_CAP}{i:nat | i < ST_N} (h: int(h), i: int(i)): [s:nat | s < ST_SLOTS] int(s) =
  h * ST_N + i

fn bv_slot {h:nat | h < BRUSH_CAP}{i:nat | i < BV_N} (h: int(h), i: int(i)): [s:nat | s < BV_SLOTS] int(s) =
  h * BV_N + i

// Yasayan fircanin tipli indeksi: @(yasiyor_mu, indeks). Indeks her zaman aralik icindedir (kirpilmis).
fn live_brush(h: int): @(bool, BIx) = let
  val @(ok, b) = ix_try(h, BRUSH_CAP)
in
  @(ok * (g_alive[b] != 0), b)
end

fn alloc_brush(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val @(ok, i) = ix_try(n, BRUSH_CAP)
  in
    if ok then g_free[i] else BRUSH_NONE
  end else let
    val n = !g_fresh
  in
    if n < BRUSH_CAP then (!g_fresh := n + 1; n) else BRUSH_NONE
  end

fn recycle_brush(h: int): void = let
  val n = !g_nfree
  val @(ok_n, i) = ix_try(n, BRUSH_CAP)
  val @(ok_h, b) = ix_try(h, BRUSH_CAP)
  val () = if ok_n then g_free[i] := h
  val () = if ok_h then g_alive[b] := 0
  val () = if ok_h then !g_nfree := n + 1
in () end

fn st_get(h: int, i: int): float = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, ST_N)
in
  if ok_b * ok_k then g_state[st_slot(b, k)] else 0.0f
end
fn st_set(h: int, i: int, v: float): void = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, ST_N)
in
  if ok_b * ok_k then g_state[st_slot(b, k)] := v
end
fn base_get(h: int, i: int): float = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, BV_N)
in
  if ok_b * ok_k then g_base[bv_slot(b, k)] else 0.0f
end
fn base_set(h: int, i: int, v: float): void = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, BV_N)
in
  if ok_b * ok_k then g_base[bv_slot(b, k)] := v
end
fn val_get(h: int, i: int): float = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, BV_N)
in
  if ok_b * ok_k then g_val[bv_slot(b, k)] else 0.0f
end
fn val_set(h: int, i: int, v: float): void = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, BV_N)
in
  if ok_b * ok_k then g_val[bv_slot(b, k)] := v
end
fn map_get(h: int, i: int): int = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, BV_N)
in
  if ok_b * ok_k then g_map[bv_slot(b, k)] else MAPPING_NONE
end
fn map_set(h: int, i: int, m: int): void = let
  val @(ok_b, b) = live_brush(h)
  val @(ok_k, k) = ix_try(i, BV_N)
in
  if ok_b * ok_k then g_map[bv_slot(b, k)] := m
end
fn reset_get(h: int): int = let val @(ok, b) = live_brush(h) in if ok then g_reset[b] else 0 end
fn reset_set(h: int, v: int): void = let val @(ok, b) = live_brush(h) in if ok then g_reset[b] := v end
fn rng_get(h: int): int = let val @(ok, b) = live_brush(h) in if ok then g_rng[b] else RNG_NONE end
fn rng_set(h: int, r: int): void = let val @(ok, b) = live_brush(h) in if ok then g_rng[b] := r end

fun zero_state {i:nat | i <= ST_N} .<ST_N - i>. (h: int, i: int(i)): void =
  if i < ST_N then let
    val () = st_set(h, i, 0.0f)
  in zero_state(h, i + 1) end else ()
fun zero_base {i:nat | i <= BV_N} .<BV_N - i>. (h: int, i: int(i)): void =
  if i < BV_N then let
    val () = base_set(h, i, 0.0f)
    val () = val_set(h, i, 0.0f)
    val () = map_set(h, i, 0)
  in zero_base(h, i + 1) end else ()
fn mp_brush_alloc(): int = let
  val h = alloc_brush()
  val () = anth_require(h >= 0)
  val @(ok_a, ba) = ix_try(h, BRUSH_CAP)
  val () = if ok_a then g_alive[ba] := 1
  val () = reset_set(h, 0)
  val () = rng_set(h, RNG_NONE)
  val () = zero_state(h, 0)
  val () = zero_base(h, 0)
  val () = st_set(h, state_ix(StFlip()), ~1.0f)
in
  h
end

fn mp_brush_destroy(b: int): void = recycle_brush(b)

fn mp_brush_get_state(b: int, id: BrushState): float = st_get(b, state_ix(id))

fn mp_brush_set_state(b: int, id: BrushState, v: float): void = st_set(b, state_ix(id), v)
fn mp_brush_get_base(b: int, i: int): float = base_get(b, i)
fn mp_brush_set_base(b: int, i: int, v: float): void = base_set(b, i, v)
fn mp_brush_get_val(b: int, i: int): float = val_get(b, i)
fn mp_brush_set_val(b: int, i: int, v: float): void = val_set(b, i, v)
fn mp_brush_get_reset(b: int): int = reset_get(b)
fn mp_brush_set_reset(b: int, v: int): void = reset_set(b, v)
fn mp_brush_get_mapping(b: int, i: int): int = map_get(b, i)
fn mp_brush_set_mapping(b: int, i: int, m: int): void = map_set(b, i, m)
fn mp_brush_get_rng(b: int): int = rng_get(b)
fn mp_brush_set_rng(b: int, r: int): void = rng_set(b, r)

fn mp_brush_clear_states(b: int): void = let
  val () = zero_state(b, 0)
in
  mp_brush_set_state(b, StFlip(), ~1.0f)
end

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)

extern fun rng_double_new(seed: lint): int = "ext#rng_double_new"
extern fun rng_double_next(rng: int): double = "ext#rng_double_next"
extern fun rng_double_free(rng: int): void = "ext#rng_double_free"
extern fun rand_gauss(rng: int): float = "ext#rand_gauss"

staload "sys/capability.sats"
staload "draw_engine/mapping_view.sats"

// --- Dinamik egriler: ham tutamac claim/stash ile tek islemlik kanita cevrilir ---
fn m_new(inputs: int): int = let
  val (pf | h) = minepaint_mapping_new(inputs)
in
  minepaint_mapping_stash(pf | h)
end

fn m_free(raw: int): void = let
  val (pf | ok, h) = minepaint_mapping_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
  in minepaint_mapping_free(live | h) end else let
    prval None_v() = pf
  in () end
end

fn m_set_base(raw: int, v: float): void = let
  val (pf | ok, h) = minepaint_mapping_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_mapping_set_base_value(live | h, v)
    val _ = minepaint_mapping_stash(live | h)
  in () end else let
    prval None_v() = pf
  in () end
end

fn m_set_n(raw: int, input: int, n: int): void = let
  val (pf | ok, h) = minepaint_mapping_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_mapping_set_n(live | h, input, n)
    val _ = minepaint_mapping_stash(live | h)
  in () end else let
    prval None_v() = pf
  in () end
end

fn m_set_point(raw: int, input: int, index: int, x: float, y: float): void = let
  val (pf | ok, h) = minepaint_mapping_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_mapping_set_point(live | h, input, index, x, y)
    val _ = minepaint_mapping_stash(live | h)
  in () end else let
    prval None_v() = pf
  in () end
end

// Egri hesaplanamazsa (gecersiz tutamac) verilen varsayilan donulur.
fn m_calc(raw: int, data: &(@[float][MAPPING_INPUTS]), dflt: float): float = let
  val (pf | ok, h) = minepaint_mapping_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val r = minepaint_mapping_calculate(live | h, data)
    val _ = minepaint_mapping_stash(live | h)
  in r end else let
    prval None_v() = pf
  in dflt end
end
extern fun minepaint_brush_setting_def(id: int): float = "ext#minepaint_brush_setting_def"

fn clear_mapping_curves(m: int): void = let
  fun loop {j:nat | j <= MAPPING_INPUTS} .<MAPPING_INPUTS - j>. (j: int(j)): void =
    if j < MAPPING_INPUTS then let
      val () = m_set_n(m, j, 0)
    in loop(j + 1) end else ()
in
  loop(0)
end

fn is_color_setting(i: int): bool =
  (i = 34) || (i = 35) || (i = 36)

fn reset_setting_default(b: int, i: int): void = let
  val d = minepaint_brush_setting_def(i)
  val m = mp_brush_get_mapping(b, i)
  val () = mp_brush_set_base(b, i, d)
  val () = mp_brush_set_val(b, i, d)
  val () = if m != MAPPING_NONE then m_set_base(m, d)
in
  if m != MAPPING_NONE then clear_mapping_curves(m)
end

fn reset_settings(b: int, keep_color: int): void = let
  fun loop {i:nat | i <= MINEPAINT_BRUSH_SETTINGS_COUNT} .<MINEPAINT_BRUSH_SETTINGS_COUNT - i>. (i: int(i)): void =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val skip = (keep_color > 0) && is_color_setting(i)
      val () = if skip then () else reset_setting_default(b, i)
    in loop(i + 1) end else ()
in
  loop(0)
end

fn alloc_mappings(b: int): void = let
  fun loop {i:nat | i <= MINEPAINT_BRUSH_SETTINGS_COUNT} .<MINEPAINT_BRUSH_SETTINGS_COUNT - i>. (i: int(i)): void =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val m = m_new(MAPPING_INPUTS)
      val () = mp_brush_set_mapping(b, i, m)
    in loop(i + 1) end else ()
in
  loop(0)
end

fn free_mappings(b: int): void = let
  fun loop {i:nat | i <= MINEPAINT_BRUSH_SETTINGS_COUNT} .<MINEPAINT_BRUSH_SETTINGS_COUNT - i>. (i: int(i)): void =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val m = mp_brush_get_mapping(b, i)
      val () = if m != MAPPING_NONE then m_free(m)
      val () = mp_brush_set_mapping(b, i, MAPPING_NONE)
    in loop(i + 1) end else ()
in
  loop(0)
end

extern fun draw_engine_brush_new(): int = "ext#draw_engine_brush_new"
implement draw_engine_brush_new() = let
  val p = mp_brush_alloc()
  val () = anth_require(p >= 0)
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
    val () = if rng >= 0 then rng_double_free(rng)
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
  if b >= 0 then let
    val m = mp_brush_get_mapping(b, ix)
    val () = mp_brush_set_base(b, ix, v)
    val () = mp_brush_set_val(b, ix, v)
  in
    if m != MAPPING_NONE then m_set_base(m, v)
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
    if (n >= 0) * (n <= 64) * (n != 1) then
      m_set_n(mp_brush_get_mapping(b, ix), iin, n)
end

extern fun draw_engine_brush_set_mapping_point(
  b: int, setting: SettingId, input: InputId, index: int, x: float, y: float
): void = "ext#draw_engine_brush_set_mapping_point"
implement draw_engine_brush_set_mapping_point(b, setting, input, index, x, y) = let
  val ix = setting_ix(setting)
  val iin = input_ix(input)
in
  if b >= 0 then m_set_point(mp_brush_get_mapping(b, ix), iin, index, x, y)
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
  if b >= 0 then mp_brush_get_base(b, ix) else 0.0f
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

fn jitter_rng(b: int): int = let
  val p = mp_brush_get_rng(b)
in
  if p < 0 then let
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
  val j = input_ix(id)
in
  arr[j] := v
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

fun eval_mapping_slot {i:nat | i <= MINEPAINT_BRUSH_SETTINGS_COUNT} .<MINEPAINT_BRUSH_SETTINGS_COUNT - i>. (b: int, in_p: &(@[float][MAPPING_INPUTS]), i: int(i)
): void =
  if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
    val m = mp_brush_get_mapping(b, i)
    val v = if m != MAPPING_NONE then m_calc(m, in_p, mp_brush_get_base(b, i)) else mp_brush_get_base(b, i)
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

fn advance_pose(b: int, step_dx: float, step_dy: float, step_dpress: float, viewzoom: float): @(float, float, float) = let
  val cur_x = f_add(mp_brush_get_state(b, StX()), step_dx)
  val cur_y = f_add(mp_brush_get_state(b, StY()), step_dy)
  val cur_p_raw = f_add(mp_brush_get_state(b, StPressure()), step_dpress)
  val cur_p = if cur_p_raw < 0.0f then 0.0f else cur_p_raw
  val () = mp_brush_set_state(b, StX(), cur_x)
  val () = mp_brush_set_state(b, StY(), cur_y)
  val () = mp_brush_set_state(b, StPressure(), cur_p)
  val () = mp_brush_set_state(b, StViewzoom(), viewzoom)
in @(cur_x, cur_y, cur_p) end

fn eval_step_inputs(b: int, cur_p: float, viewzoom: float): void = let
  val base_radius_log = mp_brush_get_base(b, setting_ix(SetRadiusLogarithmic()))
  var inbuf = @[float][MAPPING_INPUTS](0.0f)
  val () = populate_input_buffer(b, inbuf, cur_p, viewzoom, base_radius_log)
in eval_mappings(b, inbuf) end

fn mirror_dab_rates(b: int): void = let
  val () = mp_brush_set_state(b, StDabsPerBasicRadius(), mp_brush_get_val(b, setting_ix(SetDabsPerBasicRadius())))
  val () = mp_brush_set_state(b, StDabsPerActualRadius(), mp_brush_get_val(b, setting_ix(SetDabsPerActualRadius())))
in mp_brush_set_state(b, StDabsPerSecond(), mp_brush_get_val(b, setting_ix(SetDabsPerSecond()))) end

fn update_states(
  b: int,
  step_ddab: float, step_dx: float, step_dy: float,
  step_dpress: float, step_dtime: float, viewzoom: float
): void = let
  val dt = if step_dtime <= 0.0f then 0.001f else step_dtime
  val @(cur_x, cur_y, cur_p) = advance_pose(b, step_dx, step_dy, step_dpress, viewzoom)
  val norm_speed = hypotf(f_mul(f_div(step_dx, dt), viewzoom), f_mul(f_div(step_dy, dt), viewzoom))
  val () = eval_step_inputs(b, cur_p, viewzoom)
  val () = mirror_dab_rates(b)
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

fn dab_jitter(b: int): @(float, float) = let
  val jitter = mp_brush_get_val(b, setting_ix(SetOffsetByRandom()))
  val amp = if g0float_gt(jitter, 0.0f) then jitter else 0.0f
  val spread = f_mul(amp, expf(mp_brush_get_base(b, setting_ix(SetRadiusLogarithmic()))))
in
  if g0float_gt(amp, 0.0f) then let
    val jx = f_mul(rand_gauss(jitter_rng(b)), spread)
    val jy = f_mul(rand_gauss(jitter_rng(b)), spread)
  in @(jx, jy) end
  else @(0.0f, 0.0f)
end

fn dab_color(b: int): @(float, float, float) =
  engine_hsv_to_rgb(
    mp_brush_get_base(b, setting_ix(SetColorH())),
    mp_brush_get_base(b, setting_ix(SetColorS())),
    mp_brush_get_base(b, setting_ix(SetColorV()))
  )

fn dab_shape(b: int): @(float, float) = let
  val hardness_raw = mp_brush_get_val(b, setting_ix(SetHardness()))
  val hardness = if hardness_raw < 0.0f then 0.0f else if hardness_raw > 1.0f then 1.0f else hardness_raw
in
  compute_anti_aliased_dab(mp_brush_get_state(b, StActualRadius()), hardness, mp_brush_get_val(b, setting_ix(SetAntiAliasing())))
end

fn prepare_and_draw_dab(gio: !GL_IO | b: int, tgt: MpTarget): int = let
  val opaque_final = compute_opaque_final(b)
  val @(jx, jy) = dab_jitter(b)
  val x = f_add(mp_brush_get_state(b, StActualX()), jx)
  val y = f_add(mp_brush_get_state(b, StActualY()), jy)
  val @(color_r, color_g, color_b) = dab_color(b)
  val @(final_radius, final_hardness) = dab_shape(b)
  val dab_ratio = mp_brush_get_state(b, StActualEllipticalDabRatio())
  val aspect = if dab_ratio < 1.0f then 1.0f else dab_ratio
  val angle = mp_brush_get_state(b, StActualEllipticalDabAngle())
in
  draw_dab_on(gio |
    tgt, x, y, final_radius, color_r, color_g, color_b,
    opaque_final, final_hardness, aspect, angle
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

fn step_deltas(b: int, frac: float, target_x: float, target_y: float, p_clean: float): @(float, float, float) =
  @(f_mul(frac, f_sub(target_x, mp_brush_get_state(b, StX()))),
    f_mul(frac, f_sub(target_y, mp_brush_get_state(b, StY()))),
    f_mul(frac, f_sub(p_clean, mp_brush_get_state(b, StPressure()))))

// Bir dab adimi: durumlari ilerletir, dab cizer; kalan sure ve sonraki dab sayisini dondurur.
fn dab_step(gio: !GL_IO | b: int, tgt: MpTarget, target_x: float, target_y: float, p_clean: float,
  dtime_left: double, dabs_moved: float, dabs_todo: float, viewzoom: float
): @(double, float) = let
  val step_ddab = if dabs_moved > 0.0f then f_sub(1.0f, dabs_moved) else 1.0f
  val frac = if dabs_todo > 0.00001f then f_div(step_ddab, dabs_todo) else 1.0f
  val @(step_dx, step_dy, step_dpress) = step_deltas(b, frac, target_x, target_y, p_clean)
  val step_dt_float = f_mul(frac, g0float2float_double_float(dtime_left))
  val () = update_states(b, step_ddab, step_dx, step_dy, step_dpress, step_dt_float, viewzoom)
  val () = mp_brush_set_state(b, StFlip(), f_mul(mp_brush_get_state(b, StFlip()), ~1.0f))
  val _ = prepare_and_draw_dab(gio | b, tgt)
  val rem_dt = dtime_left - g0float2float_float_double(step_dt_float)
in @(rem_dt, count_dabs_to(b, target_x, target_y, g0float2float_double_float(rem_dt))) end

fun dab_loop {k:nat} .<k>. (gio: !GL_IO | k: int(k),
  b: int, tgt: MpTarget, target_x: float, target_y: float, p_clean: float,
  dtime_left: double, dabs_moved: float, dabs_todo: float, viewzoom: float
): @(double, float, float) =
  if k > 0 then
    if f_add(dabs_moved, dabs_todo) >= 1.0f then let
      val @(rem_dt, next_todo) = dab_step(gio | b, tgt, target_x, target_y, p_clean, dtime_left, dabs_moved, dabs_todo, viewzoom)
    in
      dab_loop(gio | k - 1, b, tgt, target_x, target_y, p_clean, rem_dt, 0.0f, next_todo, viewzoom)
    end
    else @(dtime_left, dabs_moved, dabs_todo)
  else anth_die_any(DieFuelDab())

fn smoothed_target(b: int, x: float, y: float, dt_float: float): @(float, float) = let
  val tracking = mp_brush_get_val(b, setting_ix(SetSlowTracking()))
  val fac = f_sub(1.0f, engine_exp_decay(tracking, f_mul(100.0f, dt_float)))
  val old_x = mp_brush_get_state(b, StX())
  val old_y = mp_brush_get_state(b, StY())
in @(f_add(old_x, f_mul(f_sub(x, old_x), fac)), f_add(old_y, f_mul(f_sub(y, old_y), fac))) end

// Hareketin kalan kismini isler: kalan dab/sure durumlarini yazar.
fn finish_motion(b: int, target_x: float, target_y: float, p_clean: float, viewzoom: float,
  rem_dt: double, rem_moved: float, rem_todo: float
): void = let
  val end_dx = f_sub(target_x, mp_brush_get_state(b, StX()))
  val end_dy = f_sub(target_y, mp_brush_get_state(b, StY()))
  val end_dpress = f_sub(p_clean, mp_brush_get_state(b, StPressure()))
  val () = update_states(b, rem_todo, end_dx, end_dy, end_dpress, g0float2float_double_float(rem_dt), viewzoom)
in mp_brush_set_state(b, StPartialDabs(), f_add(rem_moved, rem_todo)) end

fn run_motion(gio: !GL_IO | b: int, tgt: MpTarget, x: float, y: float, p_clean: float, dt_clean: double, viewzoom: float): void = let
  val @(target_x, target_y) = smoothed_target(b, x, y, g0float2float_double_float(dt_clean))
  val init_todo = count_dabs_to(b, target_x, target_y, g0float2float_double_float(dt_clean))
  val init_moved = mp_brush_get_state(b, StPartialDabs())
  // Olcu yok: dab sayisi float durumuna (dabs_moved + dabs_todo >= 1) bagli; hareket basina ust sinir.
  val @(rem_dt, rem_moved, rem_todo) = dab_loop(gio | FUEL_DABS_PER_MOTION,
    b, tgt, target_x, target_y, p_clean, dt_clean, init_moved, init_todo, viewzoom)
in finish_motion(b, target_x, target_y, p_clean, viewzoom, rem_dt, rem_moved, rem_todo) end

extern fun draw_engine_brush_stroke_to(gio: !GL_IO | 
    b: int, tgt: MpTarget,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#draw_engine_brush_stroke_to"
implement draw_engine_brush_stroke_to(gio | 
  b, tgt, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear
) =
  if b < 0 then 1
  else let
    val p_clean = if pressure < 0.0f then 0.0f else pressure
    val dt_clean = if dtime <= 0.0 then 0.0001 else dtime
  in
    if (dtime > 5.0) || (mp_brush_get_reset(b) > 0) then reset_stroke_state(b, x, y, p_clean)
    else (run_motion(gio | b, tgt, x, y, p_clean, dt_clean, viewzoom); 0)
  end

// --- Yetenek kaniti: sahip ham tutamaci stash/claim ile birakir/geri alir (sys/capability.sats aksiyomlari;
// yalniz minepaint_brush_new ve minepaint_brush_claim uretir). ---
fn brush_claimed(b: BIx): bool = g_claim[b] != 0

implement minepaint_brush_stash(pf | b) = let
  prval () = cap_burn(pf)
  val () = g_claim[b] := 0
in
  b
end

fn claim_live_brush(b: BIx): [ok:bool][b2:nat | b2 < BRUSH_CAP] (option_v(BRUSH_LIVE(b2), ok) | bool(ok), int(b2)) =
  // Cift claim engeli: firca zaten odunc alinmissa kanit bir daha uretilmez.
  if (g_alive[b] != 0) * not(brush_claimed(b)) then let
    val () = g_claim[b] := 1
  in (Some_v(cap_mint()) | true, b) end
  else (None_v() | false, b)

implement minepaint_brush_claim(raw) = let
  val @(ok, b) = ix_try(raw, BRUSH_CAP)
in
  if ok then claim_live_brush(b) else (None_v() | false, b)
end

implement minepaint_brush_new() = let
  val raw = draw_engine_brush_new()
  val @(ok, b) = ix_try(raw, BRUSH_CAP)
in
  if ok then (cap_mint() | b) else anth_die_any(DieContractViolation())
end
