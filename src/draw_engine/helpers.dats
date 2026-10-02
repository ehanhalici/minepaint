// src/draw_engine/helpers.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

%{^
#include <math.h>
%}

// Standart Matematik FFI
extern fun expf(x: float): float = "mac#expf"
extern fun floorf(x: float): float = "mac#floorf"
extern fun hypotf(x: float, y: float): float = "mac#hypotf"

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

// Üstel Sönümleme (Exponential Decay) - Saf ATS2
implement engine_exp_decay(T_const, t) =
  if f_lte(T_const, 0.001f) then 0.0f
  else expf(f_div(0.0f - t, T_const))

// Aritmetik Modülo - Saf ATS2
implement engine_mod_arith(a, N) =
  f_sub(a, f_mul(N, floorf(f_div(a, N))))

// En Küçük Açısal Fark - Saf ATS2
implement engine_smallest_angular_difference(angleA, angleB) = let
  val a0 = f_sub(angleB, angleA)
  val a1 = f_sub(engine_mod_arith(f_add(a0, 180.0f), 360.0f), 180.0f)
in
  if a1 > 180.0f then f_sub(a1, 360.0f)
  else if a1 < ~180.0f then f_add(a1, 360.0f)
  else a1
end

// HSV -> RGB Dönüşümü - Saf ATS2
implement engine_hsv_to_rgb(h_in, s_in, v_in) = let
  val h0 = f_sub(h_in, floorf(h_in))
  val s = if f_lt(s_in, 0.0f) then 0.0f else if f_gt(s_in, 1.0f) then 1.0f else s_in
  val v = if f_lt(v_in, 0.0f) then 0.0f else if f_gt(v_in, 1.0f) then 1.0f else v_in
in
  if f_lte(s, 0.0f) then @(v, v, v)
  else let
    val hue = if h0 = 1.0f then 0.0f else h0
    val hue6 = f_mul(hue, 6.0f)
    val i: int = g0float2int(hue6)
    val f = f_sub(hue6, g0int2float(i))
    val w = f_mul(v, f_sub(1.0f, s))
    val q = f_mul(v, f_sub(1.0f, f_mul(s, f)))
    val t = f_mul(v, f_sub(1.0f, f_mul(s, f_sub(1.0f, f))))
  in
    if i = 0 then @(v, t, w)
    else if i = 1 then @(q, v, w)
    else if i = 2 then @(w, v, t)
    else if i = 3 then @(w, q, v)
    else if i = 4 then @(t, w, v)
    else @(v, w, q)
  end
end

// 32-bit XorShift Rastgele Sayı Üreticisi (PRNG) - Saf ATS2
typedef rng_state = ref(uint)

fun rng_create(seed: uint): rng_state =
  ref(if g0uint_eq_uint(seed, 0U) then 2463534242U else seed)

fun rng_next_double(r: rng_state): double = let
  val x = !r
  val x1 = g0uint_lxor_uint(x, g0uint_lsl_uint(x, 13))
  val x2 = g0uint_lxor_uint(x1, g0uint_lsr_uint(x1, 17))
  val x3 = g0uint_lxor_uint(x2, g0uint_lsl_uint(x2, 5))
  val () = !r := x3
  val pos = g0uint_lsr_uint(x3, 1)
  val pos_int: int = g0uint2int_uint_int(pos)
in
  g0int2float_int_double(pos_int) / 2147483648.0
end

// Gauss Dağılımı (Merkezi Limit Teoremi) - Saf ATS2
fun rng_rand_gauss(r: rng_state): float = let
  val s1 = rng_next_double(r)
  val s2 = rng_next_double(r)
  val s3 = rng_next_double(r)
  val s4 = rng_next_double(r)
  val sum = s1 + s2 + s3 + s4
  val gauss = sum * 1.73205080757 - 3.46410161514
in
  g0float2float_double_float(gauss)
end

fn get_spectral_r(i: int): float =
  if i = 0 then 0.009281362787953f
  else if i = 1 then 0.009732627042016f
  else if i = 2 then 0.011254252737167f
  else if i = 3 then 0.015105578649573f
  else if i = 4 then 0.024797924177217f
  else if i = 5 then 0.083622585502406f
  else if i = 6 then 0.977865045723212f
  else if i = 7 then 1.000000000000000f
  else if i = 8 then 0.999961046144372f
  else 0.999999992756822f

fn get_spectral_g(i: int): float =
  if i = 0 then 0.002854127435775f
  else if i = 1 then 0.003917589679914f
  else if i = 2 then 0.012132151699187f
  else if i = 3 then 0.748259205918013f
  else if i = 4 then 1.000000000000000f
  else if i = 5 then 0.865695937531795f
  else if i = 6 then 0.037477469241101f
  else if i = 7 then 0.022816789725717f
  else if i = 8 then 0.021747419446456f
  else 0.021384940572308f

fn get_spectral_b(i: int): float =
  if i = 0 then 0.537052150373386f
  else if i = 1 then 0.546646402401469f
  else if i = 2 then 0.575501819073983f
  else if i = 3 then 0.258778829633924f
  else if i = 4 then 0.041709923751716f
  else if i = 5 then 0.012662638828324f
  else if i = 6 then 0.007485593127390f
  else if i = 7 then 0.006766900622462f
  else if i = 8 then 0.006699764779016f
  else 0.006676219883241f

fn get_t_matrix(r: int, c: int): float =
  if r = 0 then (
    if c = 0 then 0.026595621243689f
    else if c = 1 then 0.049779426257903f
    else if c = 2 then 0.022449850859496f
    else if c = 3 then ~0.218453689278271f
    else if c = 4 then ~0.256894883201278f
    else if c = 5 then 0.445881722194840f
    else if c = 6 then 0.772365886289756f
    else if c = 7 then 0.194498761382537f
    else if c = 8 then 0.014038157587820f
    else 0.007687264480513f
  ) else if r = 1 then (
    if c = 0 then ~0.032601672674412f
    else if c = 1 then ~0.061021043498478f
    else if c = 2 then ~0.052490001018404f
    else if c = 3 then 0.206659098273522f
    else if c = 4 then 0.572496335158169f
    else if c = 5 then 0.317837248815438f
    else if c = 6 then ~0.021216624031211f
    else if c = 7 then ~0.019387668756117f
    else if c = 8 then ~0.001521339050858f
    else ~0.000835181622534f
  ) else (
    if c = 0 then 0.339475473216284f
    else if c = 1 then 0.635401374177222f
    else if c = 2 then 0.771520797089589f
    else if c = 3 then 0.113222640692379f
    else if c = 4 then ~0.055251113343776f
    else if c = 5 then ~0.048222578468680f
    else if c = 6 then ~0.012966666339586f
    else if c = 7 then ~0.001523814504223f
    else if c = 8 then ~0.000094718948810f
    else ~0.000051604594741f
  )

extern fun rgb_to_spectral(r: float, g: float, b: float, spectral: ptr): void = "ext#rgb_to_spectral"
implement rgb_to_spectral(r, g, b, spectral) = let
  val eps = 0.0000001f
  val offset = f_sub(1.0f, eps)
  val r_adj = f_add(f_mul(r, offset), eps)
  val g_adj = f_add(f_mul(g, offset), eps)
  val b_adj = f_add(f_mul(b, offset), eps)

  fun loop(i: int): void =
    if i < 10 then let
      val sr = get_spectral_r(i)
      val sg = get_spectral_g(i)
      val sb = get_spectral_b(i)
      val cur = $UN.ptr0_get<float>(ptr_add<float>(spectral, i))
      val added = f_add(f_add(f_mul(sr, r_adj), f_mul(sg, g_adj)), f_mul(sb, b_adj))
      val () = $UN.ptr0_set<float>(ptr_add<float>(spectral, i), f_add(cur, added))
    in
      loop(i + 1)
    end else ()
in
  loop(0)
end

extern fun spectral_to_rgb(spectral: ptr, rgb: ptr): void = "ext#spectral_to_rgb"
implement spectral_to_rgb(spectral, rgb) = let
  val eps = 0.0000001f
  val offset = f_sub(1.0f, eps)

  fun loop_row(r: int): float = let
    fun loop_col(c: int, acc: float): float =
      if c < 10 then let
        val coeff = get_t_matrix(r, c)
        val spec_v = $UN.ptr0_get<float>(ptr_add<float>(spectral, c))
        val term = f_mul(coeff, spec_v)
      in
        loop_col(c + 1, f_add(acc, term))
      end else acc
  in
    loop_col(0, 0.0f)
  end

  fun loop_out(i: int): void =
    if i < 3 then let
      val tmp = loop_row(i)
      val v = f_div(f_sub(tmp, eps), offset)
      val clamped = if f_lt(v, 0.0f) then 0.0f else if f_gt(v, 1.0f) then 1.0f else v
      val () = $UN.ptr0_set<float>(ptr_add<float>(rgb, i), clamped)
    in
      loop_out(i + 1)
    end else ()
in
  loop_out(0)
end
