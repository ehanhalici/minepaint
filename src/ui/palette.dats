#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "sys/airlock.hats"
#include "sys/arena.hats"
staload "ui/state.dats"

fn pal_clampf(v: float): float =
  if g0float_lt(v, 0.0f) then 0.0f
  else if g0float_gt(v, 1.0f) then 1.0f
  else v

// Girdi disi (satir/kanal) politikasi: okuma 0, yazma etkisiz. Erisim 3*i + c < 36 statik kanitli.
extern fun pal_get(i: int, c: int): float = "ext#pal_get"
implement pal_get(i, c) = let
  val @(ok_i, ri) = ix_try(i, 12)
  val @(ok_c, rc) = ix_try(c, 3)
  val u = ui_get()
  val p = u->pal
in
  if ok_i * ok_c then p[3 * ri + rc] else 0.0f
end

extern fun pal_get_color(i: int): @(float, float, float) = "ext#pal_get_color"
implement pal_get_color(i) =
  @(pal_get(i, 0), pal_get(i, 1), pal_get(i, 2))

extern fun pal_set(i: int, c: int, v: float): void = "ext#pal_set"
implement pal_set(i, c, v) = let
  val @(ok_i, ri) = ix_try(i, 12)
  val @(ok_c, rc) = ix_try(c, 3)
  val u = ui_get()
  val p = u->pal
in
  if ok_i * ok_c then p[3 * ri + rc] := pal_clampf(v) else ()
end
