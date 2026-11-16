// src/draw_engine/helpers.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/libc.dats"

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)
fn f_lte(a: float, b: float): bool = a <= b
fn f_lt(a: float, b: float): bool = a < b
fn f_gt(a: float, b: float): bool = a > b
fn f_gte(a: float, b: float): bool = a >= b

extern fun engine_exp_decay(T_const: float, t: float): float = "ext#engine_exp_decay"
extern fun engine_mod_arith(a: float, N: float): float = "ext#engine_mod_arith"
extern fun engine_smallest_angular_difference(angleA: float, angleB: float): float = "ext#engine_smallest_angular_difference"
extern fun engine_hsv_to_rgb(h: float, s: float, v: float): @(float, float, float) = "ext#engine_hsv_to_rgb"

// Üstel Sönümleme (Exponential Decay) - Saf ATS2, Guard Clause
implement engine_exp_decay(T_const, t) =
  if f_lte(T_const, 0.001f) then 0.0f
  else expf(f_div(0.0f - t, T_const))

// Aritmetik Modülo - Saf ATS2
implement engine_mod_arith(a, N) =
  if N = 0.0f then 0.0f
  else f_sub(a, f_mul(N, floorf(f_div(a, N))))

// En Küçük Açısal Fark - Saf ATS2
implement engine_smallest_angular_difference(angleA, angleB) = let
  val a0 = f_sub(angleB, angleA)
  val a1 = f_sub(engine_mod_arith(f_add(a0, 180.0f), 360.0f), 180.0f)
in
  if a1 > 180.0f then f_sub(a1, 360.0f)
  else if a1 < ~180.0f then f_add(a1, 360.0f)
  else a1
end

extern fun hsv_to_rgb(h: float, s: float, v: float): @(float, float, float) = "ext#hsv_to_rgb"

fn unit_clamp(x: float): float = if f_lt(x, 0.0f) then 0.0f else if f_gt(x, 1.0f) then 1.0f else x

// HSV -> RGB (motor girdisi): ton [0,1) dilimine, doygunluk ve deger [0,1] araligina oturtulur, donusumu ui/color.dats yapar.
implement engine_hsv_to_rgb(h_in, s_in, v_in) = let
  val h0 = f_sub(h_in, floorf(h_in))
  val hue = if h0 = 1.0f then 0.0f else h0
in
  hsv_to_rgb(hue, unit_clamp(s_in), unit_clamp(v_in))
end

datatype SpecBand =
  | Band0 of ()
  | Band1 of ()
  | Band2 of ()
  | Band3 of ()
  | Band4 of ()
  | Band5 of ()
  | Band6 of ()
  | Band7 of ()
  | Band8 of ()
  | Band9 of ()

fn band_of {i:nat | i < 10} (i: int(i)): SpecBand =
  if i = 0 then Band0()
  else if i = 1 then Band1()
  else if i = 2 then Band2()
  else if i = 3 then Band3()
  else if i = 4 then Band4()
  else if i = 5 then Band5()
  else if i = 6 then Band6()
  else if i = 7 then Band7()
  else if i = 8 then Band8()
  else Band9()

fn get_spectral_r(b: SpecBand): float =
  case+ b of
  | Band0() => 0.009281362787953f
  | Band1() => 0.009732627042016f
  | Band2() => 0.011254252737167f
  | Band3() => 0.015105578649573f
  | Band4() => 0.024797924177217f
  | Band5() => 0.083622585502406f
  | Band6() => 0.977865045723212f
  | Band7() => 1.000000000000000f
  | Band8() => 0.999961046144372f
  | Band9() => 0.999999992756822f

fn get_spectral_g(b: SpecBand): float =
  case+ b of
  | Band0() => 0.002854127435775f
  | Band1() => 0.003917589679914f
  | Band2() => 0.012132151699187f
  | Band3() => 0.748259205918013f
  | Band4() => 1.000000000000000f
  | Band5() => 0.865695937531795f
  | Band6() => 0.037477469241101f
  | Band7() => 0.022816789725717f
  | Band8() => 0.021747419446456f
  | Band9() => 0.021384940572308f

fn get_spectral_b(b: SpecBand): float =
  case+ b of
  | Band0() => 0.537052150373386f
  | Band1() => 0.546646402401469f
  | Band2() => 0.575501819073983f
  | Band3() => 0.258778829633924f
  | Band4() => 0.041709923751716f
  | Band5() => 0.012662638828324f
  | Band6() => 0.007485593127390f
  | Band7() => 0.006766900622462f
  | Band8() => 0.006699764779016f
  | Band9() => 0.006676219883241f

fn get_t_row0(b: SpecBand): float =
  case+ b of
  | Band0() => 0.026595621243689f
  | Band1() => 0.049779426257903f
  | Band2() => 0.022449850859496f
  | Band3() => ~0.218453689278271f
  | Band4() => ~0.256894883201278f
  | Band5() => 0.445881722194840f
  | Band6() => 0.772365886289756f
  | Band7() => 0.194498761382537f
  | Band8() => 0.014038157587820f
  | Band9() => 0.007687264480513f

fn get_t_row1(b: SpecBand): float =
  case+ b of
  | Band0() => ~0.032601672674412f
  | Band1() => ~0.061021043498478f
  | Band2() => ~0.052490001018404f
  | Band3() => 0.206659098273522f
  | Band4() => 0.572496335158169f
  | Band5() => 0.317837248815438f
  | Band6() => ~0.021216624031211f
  | Band7() => ~0.019387668756117f
  | Band8() => ~0.001521339050858f
  | Band9() => ~0.000835181622534f

fn get_t_row2(b: SpecBand): float =
  case+ b of
  | Band0() => 0.339475473216284f
  | Band1() => 0.635401374177222f
  | Band2() => 0.771520797089589f
  | Band3() => 0.113222640692379f
  | Band4() => ~0.055251113343776f
  | Band5() => ~0.048222578468680f
  | Band6() => ~0.012966666339586f
  | Band7() => ~0.001523814504223f
  | Band8() => ~0.000094718948810f
  | Band9() => ~0.000051604594741f

fn get_t_matrix(r: int, b: SpecBand): float =
  if r = 0 then get_t_row0(b)
  else if r = 1 then get_t_row1(b)
  else get_t_row2(b)

fn spec_eps(): float = 0.0000001f

fn spec_offset(): float = f_sub(1.0f, spec_eps())

fn band_mix(b: SpecBand, r_adj: float, g_adj: float, b_adj: float): float =
  f_add(f_add(f_mul(get_spectral_r(b), r_adj), f_mul(get_spectral_g(b), g_adj)), f_mul(get_spectral_b(b), b_adj))

fun spectral_fill {i:nat | i <= 10} .<10 - i>. (
  spectral: &(@[float][10]), i: int(i), r_adj: float, g_adj: float, b_adj: float
): void =
  if i >= 10 then ()
  else let
    val () = spectral.[i] := band_mix(band_of(i), r_adj, g_adj, b_adj)
  in spectral_fill(spectral, i + 1, r_adj, g_adj, b_adj) end

// RGB -> Spektral Donusum (Sifir Unsafe, Bagimli Tipli Dizi)
extern fun rgb_to_spectral(r: float, g: float, b: float, spectral: &(@[float][10])): void = "ext#rgb_to_spectral"
implement rgb_to_spectral(r, g, b, spectral) = let
  val eps = spec_eps()
  val offset = spec_offset()
in
  spectral_fill(spectral, 0, f_add(f_mul(r, offset), eps), f_add(f_mul(g, offset), eps), f_add(f_mul(b, offset), eps))
end

fun spectral_row_sum {c:nat | c <= 10} .<10 - c>. (
  spectral: &(@[float][10]), r: int, c: int(c), acc: float
): float =
  if c >= 10 then acc
  else let
    val term = f_mul(get_t_matrix(r, band_of(c)), spectral.[c])
  in spectral_row_sum(spectral, r, c + 1, f_add(acc, term)) end

fn unit_of_row(spectral: &(@[float][10]), r: int): float = let
  val v = f_div(f_sub(spectral_row_sum(spectral, r, 0, 0.0f), spec_eps()), spec_offset())
in unit_clamp(v) end

fun spectral_rows_out {i:nat | i <= 3} .<3 - i>. (
  spectral: &(@[float][10]), rgb: &(@[float][3]), i: int(i)
): void =
  if i >= 3 then ()
  else let
    val () = rgb.[i] := unit_of_row(spectral, i)
  in spectral_rows_out(spectral, rgb, i + 1) end

// Spektral -> RGB Donusum (Sifir Unsafe, Bagimli Tipli Dizi)
extern fun spectral_to_rgb(spectral: &(@[float][10]), rgb: &(@[float][3])): void = "ext#spectral_to_rgb"
implement spectral_to_rgb(spectral, rgb) = spectral_rows_out(spectral, rgb, 0)
