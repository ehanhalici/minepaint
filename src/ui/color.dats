#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

// --- Renk Uzayı Dönüşümleri (RGB <-> HSV) (Pür ATS2) ---

fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_lt(a: float, b: float): bool = g0float_lt_float(a, b)
fn f_gt(a: float, b: float): bool = g0float_gt_float(a, b)
fn f_gte(a: float, b: float): bool = g0float_gte_float(a, b)

// HSV sektoru (renk carki 6 dilim); i = floor(6h) tipli indeksle bu tabloya cevrilir.
datatype Sector = Sec0 | Sec1 | Sec2 | Sec3 | Sec4 | Sec5

val g_sector_tab = arrayref_make_arrpsz($arrpsz{Sector}(Sec0(), Sec1(), Sec2(), Sec3(), Sec4(), Sec5()))

fn sector_of(i: int): Sector = let
  val @(ok, k) = ix_try(i, 6)
in
  if ok then g_sector_tab[k] else anth_die_box{Sector}(DieContractViolation())
end

fn sector_rgb(k: Sector, v: float, p: float, q: float, t: float): @(float, float, float) =
  case+ k of
  | Sec0() => @(v, t, p)
  | Sec1() => @(q, v, p)
  | Sec2() => @(p, v, t)
  | Sec3() => @(p, q, v)
  | Sec4() => @(t, p, v)
  | Sec5() => @(v, p, q)

// HSV -> RGB Donusumu (h, s, v in [0,1])
extern fun hsv_to_rgb(h: float, s: float, v: float): @(float, float, float) = "ext#hsv_to_rgb"
implement hsv_to_rgb(h, s, v) =
  if s <= 0.0f then @(v, v, v)
  else let
    val hh_raw = f_mul(h, 6.0f)
    val hh = if hh_raw >= 6.0f then 0.0f else hh_raw
    val i = g0float2int_float_int(hh)
    val ff = f_sub(hh, g0int2float(i))
    val p = f_mul(v, f_sub(1.0f, s))
    val q = f_mul(v, f_sub(1.0f, f_mul(s, ff)))
    val t = f_mul(v, f_sub(1.0f, f_mul(s, f_sub(1.0f, ff))))
  in
    sector_rgb(sector_of(i), v, p, q, t)
  end

// RGB -> HSV Dönüşümü
extern fun rgb_to_hsv(r: float, g: float, b: float): @(float, float, float) = "ext#rgb_to_hsv"
fn hue_sextant(r: float, g: float, b: float, max_val: float, delta: float): float =
  if f_gte(r, max_val) then f_div(f_sub(g, b), delta)
  else if f_gte(g, max_val) then f_add(2.0f, f_div(f_sub(b, r), delta))
  else f_add(4.0f, f_div(f_sub(r, g), delta))

fn hue_unit(r: float, g: float, b: float, max_val: float, delta: float): float = let
  val h_deg = f_mul(hue_sextant(r, g, b, max_val, delta), 60.0f)
  val h_norm = if f_lt(h_deg, 0.0f) then f_add(h_deg, 360.0f) else h_deg
in f_div(h_norm, 360.0f) end

implement rgb_to_hsv(r, g, b) = let
  val max_rg = if f_gt(r, g) then r else g
  val max_val = if f_gt(max_rg, b) then max_rg else b
  val min_rg = if f_lt(r, g) then r else g
  val min_val = if f_lt(min_rg, b) then min_rg else b
  val delta = f_sub(max_val, min_val)
  val v = max_val
in
  if f_lt(delta, 0.00001f) then
    @(0.0f, 0.0f, v)
  else let
    val s = if f_gt(max_val, 0.0f) then f_div(delta, max_val) else 0.0f
    val h = hue_unit(r, g, b, max_val, delta)
  in
    @(h, s, v)
  end
end
