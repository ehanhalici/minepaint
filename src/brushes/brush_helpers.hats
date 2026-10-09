// Typed reads of brush preset tables. nsz is the array length, so the
// index check is the same fact the type system uses for the access.
#ifndef BRUSH_HELPERS_HATS
#define BRUSH_HELPERS_HATS

staload "draw_engine/setting_id.sats"

fn {n:int}
table_iget(a: &(@[int][n]), nsz: int(n), k: int): int = let
  val i = g1ofg0(k)
in
  if (i >= 0) * (i < nsz) then a[i] else 0
end

fn {n:int}
table_fget(a: &(@[float][n]), nsz: int(n), k: int): float = let
  val i = g1ofg0(k)
in
  if (i >= 0) * (i < nsz) then a[i] else 0.0f
end

fn {n:int}
table_sget(a: &(@[string][n]), nsz: int(n), k: int): string = let
  val i = g1ofg0(k)
in
  if (i >= 0) * (i < nsz) then a[i] else ""
end

extern fun draw_engine_brush_set_base_value(b: int, id: SettingId, v: float): void = "ext#draw_engine_brush_set_base_value"
extern fun draw_engine_brush_set_mapping_n(b: int, setting: SettingId, input: int, n: int): void = "ext#draw_engine_brush_set_mapping_n"
extern fun draw_engine_brush_set_mapping_point(b: int, setting: SettingId, input: int, index: int, x: float, y: float): void = "ext#draw_engine_brush_set_mapping_point"

fun {npt:int}
apply_points(
  b: int, sid: int, inp: int, p0: int, pi: int, n: int,
  xs: &(@[float][npt]), np: int(npt), ys: &(@[float][npt])
): void =
  if pi < n then let
    val () = draw_engine_brush_set_mapping_point(b, setting_of(sid), inp, pi, table_fget(xs, np, p0 + pi), table_fget(ys, np, p0 + pi))
  in
    apply_points(b, sid, inp, p0, pi + 1, n, xs, np, ys)
  end else ()

fun {ncurve,npt:int}
apply_curves(
  b: int, sid: int, c: int, c1: int,
  inps: &(@[int][ncurve]), nc: int(ncurve),
  p0s: &(@[int][ncurve]), pns: &(@[int][ncurve]),
  xs: &(@[float][npt]), np: int(npt), ys: &(@[float][npt])
): void =
  if c < c1 then let
    val inp = table_iget(inps, nc, c)
    val n = table_iget(pns, nc, c)
    val p0 = table_iget(p0s, nc, c)
    val () = draw_engine_brush_set_mapping_n(b, setting_of(sid), inp, n)
    val () = apply_points(b, sid, inp, p0, 0, n, xs, np, ys)
  in
    apply_curves(b, sid, c + 1, c1, inps, nc, p0s, pns, xs, np, ys)
  end else ()

fun {nset,ncurve,npt:int}
brush_apply_range(
  b: int, k: int, kend: int,
  sids: &(@[int][nset]), ns: int(nset),
  bases: &(@[float][nset]),
  c0s: &(@[int][nset]), c1s: &(@[int][nset]),
  inps: &(@[int][ncurve]), nc: int(ncurve),
  p0s: &(@[int][ncurve]), pns: &(@[int][ncurve]),
  xs: &(@[float][npt]), np: int(npt), ys: &(@[float][npt])
): void =
  if k < kend then let
    val sid = table_iget(sids, ns, k)
    val () = draw_engine_brush_set_base_value(b, setting_of(sid), table_fget(bases, ns, k))
    val c0 = table_iget(c0s, ns, k)
    val c1 = table_iget(c1s, ns, k)
    val () = apply_curves(b, sid, c0, c1, inps, nc, p0s, pns, xs, np, ys)
  in
    brush_apply_range(b, k + 1, kend, sids, ns, bases, c0s, c1s, inps, nc, p0s, pns, xs, np, ys)
  end else ()

#endif
