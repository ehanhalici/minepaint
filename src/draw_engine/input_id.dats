#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/input_id.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

// Ters tablo (veri): indeks -> varyant. Sira input_ix ile ayni.
val g_input_tab = arrayref_make_arrpsz($arrpsz{InputId}(
  InPressure(),
  InRandom(),
  InStroke(),
  InDirection(),
  InTiltDeclination(),
  InTiltAscension(),
  InSpeed1(),
  InSpeed2(),
  InCustom(),
  InDirectionAngle(),
  InAttackAngle(),
  InTiltDeclinationX(),
  InTiltDeclinationY(),
  InGridmapX(),
  InGridmapY(),
  InViewzoom(),
  InBrushRadius(),
  InBarrelRotation()
))

implement input_try(i) = let
  val @(ok, k) = ix_try(i, 18)
in @(ok, g_input_tab[k]) end

implement input_of(i) = let
  val @(ok, v) = input_try(i)
in
  if ok then v else anth_die_box{InputId}(DieContractViolation())
end

// Tam kapsamli tablo: varyant basina bir kol (veri tablosu; R17 istisnasi).
implement input_ix(s) =
  case+ s of
  | InPressure() => 0
  | InRandom() => 1
  | InStroke() => 2
  | InDirection() => 3
  | InTiltDeclination() => 4
  | InTiltAscension() => 5
  | InSpeed1() => 6
  | InSpeed2() => 7
  | InCustom() => 8
  | InDirectionAngle() => 9
  | InAttackAngle() => 10
  | InTiltDeclinationX() => 11
  | InTiltDeclinationY() => 12
  | InGridmapX() => 13
  | InGridmapY() => 14
  | InViewzoom() => 15
  | InBrushRadius() => 16
  | InBarrelRotation() => 17
