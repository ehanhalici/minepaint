#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "draw_engine/engine_safe.hats"
staload "ui/state.dats"

fn pal_clampf(v: float): float =
  if g0float_lt(v, 0.0f) then 0.0f
  else if g0float_gt(v, 1.0f) then 1.0f
  else v

extern fun pal_get(i: int, c: int): float = "ext#pal_get"
implement pal_get(i, c) =
  if (i < 0) || (i >= 12) || (c < 0) || (c > 2) then 0.0f
  else let
    val u = ui_get()
  in
    airlock_fget_n(u->pal, i * 3 + c, 36)
  end

extern fun pal_get_color(i: int): @(float, float, float) = "ext#pal_get_color"
implement pal_get_color(i) =
  @(pal_get(i, 0), pal_get(i, 1), pal_get(i, 2))

extern fun pal_set(i: int, c: int, v: float): void = "ext#pal_set"
implement pal_set(i, c, v) =
  if (i < 0) || (i >= 12) || (c < 0) || (c > 2) then ()
  else let
    val u = ui_get()
  in
    airlock_fset_n(u->pal, i * 3 + c, 36, pal_clampf(v))
  end
