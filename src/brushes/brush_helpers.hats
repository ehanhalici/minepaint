// Tipli firca tablolari: veri dosya duzeyinde `arrayref` sabitleridir (govdede degil); erisim `Ix(n)` ile.
// Aralik disi indeks tasarim ihlalidir (anth_die); sessiz varsayilan donulmez.
#ifndef BRUSH_HELPERS_HATS
#define BRUSH_HELPERS_HATS

staload "draw_engine/setting_id.sats"
staload "draw_engine/input_id.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

// Bir koleksiyonun ayar/egri/nokta tablolari (boyutlar tipte).
typedef BrushData(s:int, c:int, p:int) = @{
  ns= int(s), nc= int(c), np= int(p),
  sids= arrayref(int, s), bases= arrayref(float, s),
  c0s= arrayref(int, s), c1s= arrayref(int, s),
  inps= arrayref(int, c), p0s= arrayref(int, c), pns= arrayref(int, c),
  xs= arrayref(float, p), ys= arrayref(float, p)
}

fn table_iget {n:pos} (t: arrayref(int, n), n: int(n), k: int): int = let
  val @(ok, i) = ix_try(k, n)
in
  if ok then t[i] else anth_die_int(DieContractViolation())
end

fn table_fget {n:pos} (t: arrayref(float, n), n: int(n), k: int): float = let
  val @(ok, i) = ix_try(k, n)
in
  if ok then t[i] else g0float2float_double_float(anth_die_dbl(DieContractViolation()))
end

fn table_sget {n:pos} (t: arrayref(string, n), n: int(n), k: int): string = let
  val @(ok, i) = ix_try(k, n)
in
  if ok then t[i] else anth_die_box{string}(DieContractViolation())
end

extern fun draw_engine_brush_set_base_value(b: int, id: SettingId, v: float): void = "ext#draw_engine_brush_set_base_value"
extern fun draw_engine_brush_set_mapping_n(b: int, setting: SettingId, input: InputId, n: int): void = "ext#draw_engine_brush_set_mapping_n"
extern fun draw_engine_brush_set_mapping_point(b: int, setting: SettingId, input: InputId, index: int, x: float, y: float): void = "ext#draw_engine_brush_set_mapping_point"

fn apply_point_at {s,c,p:pos} (b: int, sid: int, inp: int, d: BrushData(s,c,p), idx: int, pi: int): void =
  draw_engine_brush_set_mapping_point(b, setting_of(sid), input_of(inp), pi,
    table_fget(d.xs, d.np, idx), table_fget(d.ys, d.np, idx))

fun apply_points {s,c,p:pos}{r:nat} .<r>.
  (b: int, sid: int, inp: int, d: BrushData(s,c,p), p0: int, pi: int, rem: int(r)): void =
  if rem > 0 then let
    val () = apply_point_at(b, sid, inp, d, p0 + pi, pi)
  in apply_points(b, sid, inp, d, p0, pi + 1, rem - 1) end
  else ()

fn apply_curve {s,c,p:pos} (b: int, sid: int, d: BrushData(s,c,p), c: int): void = let
  val inp = table_iget(d.inps, d.nc, c)
  val n = table_iget(d.pns, d.nc, c)
  val p0 = table_iget(d.p0s, d.nc, c)
  val () = draw_engine_brush_set_mapping_n(b, setting_of(sid), input_of(inp), n)
in apply_points(b, sid, inp, d, p0, 0, airlock_nat(n)) end

fun apply_curves {s,c,p:pos}{r:nat} .<r>.
  (b: int, sid: int, d: BrushData(s,c,p), cu: int, rem: int(r)): void =
  if rem > 0 then let
    val () = apply_curve(b, sid, d, cu)
  in apply_curves(b, sid, d, cu + 1, rem - 1) end
  else ()

fn apply_setting {s,c,p:pos} (b: int, d: BrushData(s,c,p), k: int): void = let
  val sid = table_iget(d.sids, d.ns, k)
  val c0 = table_iget(d.c0s, d.ns, k)
  val c1 = table_iget(d.c1s, d.ns, k)
  val () = draw_engine_brush_set_base_value(b, setting_of(sid), table_fget(d.bases, d.ns, k))
in apply_curves(b, sid, d, c0, airlock_nat(c1 - c0)) end

fun brush_apply_range {s,c,p:pos}{r:nat} .<r>.
  (b: int, d: BrushData(s,c,p), k: int, rem: int(r)): void =
  if rem > 0 then let
    val () = apply_setting(b, d, k)
  in brush_apply_range(b, d, k + 1, rem - 1) end
  else ()

// Koleksiyon girdisi i: [b0[i], b1[i]) araligindaki ayarlari uygular.
fn brush_apply_item {n,s,c,p:pos} (b: int, i: int, lo: arrayref(int, n), hi: arrayref(int, n), n: int(n), d: BrushData(s,c,p)): void = let
  val k0 = table_iget(lo, n, i)
  val k1 = table_iget(hi, n, i)
in brush_apply_range(b, d, k0, airlock_nat(k1 - k0)) end

fn brush_name_at {n:pos} (names: arrayref(string, n), n: int(n), i: int): string = table_sget(names, n, i)

#endif
