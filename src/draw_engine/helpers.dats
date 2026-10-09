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

// HSV Sektör Renk Eşlemesi (Atomik Helper, SRP)
fn hsv_sector_rgb(i: int, v: float, t: float, w: float, q: float): @(float, float, float) =
  case+ i of
  | 0 => @(v, t, w)
  | 1 => @(q, v, w)
  | 2 => @(w, v, t)
  | 3 => @(w, q, v)
  | 4 => @(t, w, v)
  | _ => @(v, w, q)

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
    hsv_sector_rgb(i, v, t, w, q)
  end
end

// Spektral Katsayı Tabloları (Pattern Matching, < 15 satır)
fn get_spectral_r(i: int): float =
  case+ i of
  | 0 => 0.009281362787953f
  | 1 => 0.009732627042016f
  | 2 => 0.011254252737167f
  | 3 => 0.015105578649573f
  | 4 => 0.024797924177217f
  | 5 => 0.083622585502406f
  | 6 => 0.977865045723212f
  | 7 => 1.000000000000000f
  | 8 => 0.999961046144372f
  | _ => 0.999999992756822f

fn get_spectral_g(i: int): float =
  case+ i of
  | 0 => 0.002854127435775f
  | 1 => 0.003917589679914f
  | 2 => 0.012132151699187f
  | 3 => 0.748259205918013f
  | 4 => 1.000000000000000f
  | 5 => 0.865695937531795f
  | 6 => 0.037477469241101f
  | 7 => 0.022816789725717f
  | 8 => 0.021747419446456f
  | _ => 0.021384940572308f

fn get_spectral_b(i: int): float =
  case+ i of
  | 0 => 0.537052150373386f
  | 1 => 0.546646402401469f
  | 2 => 0.575501819073983f
  | 3 => 0.258778829633924f
  | 4 => 0.041709923751716f
  | 5 => 0.012662638828324f
  | 6 => 0.007485593127390f
  | 7 => 0.006766900622462f
  | 8 => 0.006699764779016f
  | _ => 0.006676219883241f

// Dönüşüm Matrisi Satır Fonksiyonları (SLAP, SRP, < 15 satır)
fn get_t_row0(c: int): float =
  case+ c of
  | 0 => 0.026595621243689f
  | 1 => 0.049779426257903f
  | 2 => 0.022449850859496f
  | 3 => ~0.218453689278271f
  | 4 => ~0.256894883201278f
  | 5 => 0.445881722194840f
  | 6 => 0.772365886289756f
  | 7 => 0.194498761382537f
  | 8 => 0.014038157587820f
  | _ => 0.007687264480513f

fn get_t_row1(c: int): float =
  case+ c of
  | 0 => ~0.032601672674412f
  | 1 => ~0.061021043498478f
  | 2 => ~0.052490001018404f
  | 3 => 0.206659098273522f
  | 4 => 0.572496335158169f
  | 5 => 0.317837248815438f
  | 6 => ~0.021216624031211f
  | 7 => ~0.019387668756117f
  | 8 => ~0.001521339050858f
  | _ => ~0.000835181622534f

fn get_t_row2(c: int): float =
  case+ c of
  | 0 => 0.339475473216284f
  | 1 => 0.635401374177222f
  | 2 => 0.771520797089589f
  | 3 => 0.113222640692379f
  | 4 => ~0.055251113343776f
  | 5 => ~0.048222578468680f
  | 6 => ~0.012966666339586f
  | 7 => ~0.001523814504223f
  | 8 => ~0.000094718948810f
  | _ => ~0.000051604594741f

fn get_t_matrix(r: int, c: int): float =
  if r = 0 then get_t_row0(c)
  else if r = 1 then get_t_row1(c)
  else get_t_row2(c)

// RGB -> Spektral Dönüşüm (Sıfır Unsafe, Bağımlı Tipli Dizi)
extern fun rgb_to_spectral(r: float, g: float, b: float, spectral: &(@[float][10])): void = "ext#rgb_to_spectral"
implement rgb_to_spectral(r, g, b, spectral) = let
  val eps = 0.0000001f
  val offset = f_sub(1.0f, eps)
  val r_adj = f_add(f_mul(r, offset), eps)
  val g_adj = f_add(f_mul(g, offset), eps)
  val b_adj = f_add(f_mul(b, offset), eps)

  fun loop{i:nat | i <= 10}(spectral: &(@[float][10]), i: int(i)): void =
    if i < 10 then let
      val sr = get_spectral_r(i)
      val sg = get_spectral_g(i)
      val sb = get_spectral_b(i)
      val cur = spectral.[i]
      val added = f_add(f_add(f_mul(sr, r_adj), f_mul(sg, g_adj)), f_mul(sb, b_adj))
      val () = spectral.[i] := f_add(cur, added)
    in
      loop(spectral, i + 1)
    end else ()
in
  loop(spectral, 0)
end

// Spektral -> RGB Dönüşüm (Sıfır Unsafe, Bağımlı Tipli Dizi)
extern fun spectral_to_rgb(spectral: &(@[float][10]), rgb: &(@[float][3])): void = "ext#spectral_to_rgb"
implement spectral_to_rgb(spectral, rgb) = let
  val eps = 0.0000001f
  val offset = f_sub(1.0f, eps)

  fun loop_row(spectral: &(@[float][10]), r: int): float = let
    fun loop_col{c:nat | c <= 10}(spectral: &(@[float][10]), c: int(c), acc: float): float =
      if c < 10 then let
        val coeff = get_t_matrix(r, c)
        val term = f_mul(coeff, spectral.[c])
      in
        loop_col(spectral, c + 1, f_add(acc, term))
      end else acc
  in
    loop_col(spectral, 0, 0.0f)
  end

  fun loop_out{i:nat | i <= 3}(spectral: &(@[float][10]), rgb: &(@[float][3]), i: int(i)): void =
    if i < 3 then let
      val tmp = loop_row(spectral, i)
      val v = f_div(f_sub(tmp, eps), offset)
      val clamped = if f_lt(v, 0.0f) then 0.0f else if f_gt(v, 1.0f) then 1.0f else v
      val () = rgb.[i] := clamped
    in
      loop_out(spectral, rgb, i + 1)
    end else ()
in
  loop_out(spectral, rgb, 0)
end
