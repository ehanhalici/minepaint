#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "ui/state.dats"

fn pal_clampf(v: float): float =
  if g0float_lt(v, 0.0f) then 0.0f
  else if g0float_gt(v, 1.0f) then 1.0f
  else v

extern fun pal_get(i: int, c: int): float = "ext#pal_get"
implement pal_get(i, c) =
  if (i < 0) || (i >= 12) || (c < 0) || (c > 2) then 0.0f
  else let
    val base = ui_pal_ptr()
  in
    $UN.ptr0_get<float>(ptr_add<float>(base, i * 3 + c))
  end

extern fun pal_set(i: int, c: int, v: float): void = "ext#pal_set"
implement pal_set(i, c, v) =
  if (i < 0) || (i >= 12) || (c < 0) || (c > 2) then ()
  else let
    val base = ui_pal_ptr()
  in
    $UN.ptr0_set<float>(ptr_add<float>(base, i * 3 + c), pal_clampf(v))
  end
