#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/state_id.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

// Ters tablo (veri): indeks -> varyant. Sira state_ix ile ayni.
val g_state_tab = arrayref_make_arrpsz($arrpsz{BrushState}(
  StX(),
  StY(),
  StPressure(),
  StPartialDabs(),
  StActualRadius(),
  StN5(),
  StN6(),
  StN7(),
  StN8(),
  StN9(),
  StN10(),
  StN11(),
  StN12(),
  StN13(),
  StActualX(),
  StActualY(),
  StNormDxSlow(),
  StNormDySlow(),
  StNormSpeed1Slow(),
  StNormSpeed2Slow(),
  StStroke(),
  StStrokeStarted(),
  StN22(),
  StN23(),
  StActualEllipticalDabRatio(),
  StActualEllipticalDabAngle(),
  StN26(),
  StN27(),
  StN28(),
  StN29(),
  StViewzoom(),
  StViewrotation(),
  StN32(),
  StN33(),
  StN34(),
  StFlip(),
  StN36(),
  StN37(),
  StN38(),
  StN39(),
  StDabsPerBasicRadius(),
  StDabsPerActualRadius(),
  StDabsPerSecond(),
  StN43()
))

implement state_try(i) = let
  val @(ok, k) = ix_try(i, 44)
in @(ok, g_state_tab[k]) end

// Tam kapsamli tablo: varyant basina bir kol (veri tablosu; R17 istisnasi).
implement state_ix(s) =
  case+ s of
  | StX() => 0
  | StY() => 1
  | StPressure() => 2
  | StPartialDabs() => 3
  | StActualRadius() => 4
  | StN5() => 5
  | StN6() => 6
  | StN7() => 7
  | StN8() => 8
  | StN9() => 9
  | StN10() => 10
  | StN11() => 11
  | StN12() => 12
  | StN13() => 13
  | StActualX() => 14
  | StActualY() => 15
  | StNormDxSlow() => 16
  | StNormDySlow() => 17
  | StNormSpeed1Slow() => 18
  | StNormSpeed2Slow() => 19
  | StStroke() => 20
  | StStrokeStarted() => 21
  | StN22() => 22
  | StN23() => 23
  | StActualEllipticalDabRatio() => 24
  | StActualEllipticalDabAngle() => 25
  | StN26() => 26
  | StN27() => 27
  | StN28() => 28
  | StN29() => 29
  | StViewzoom() => 30
  | StViewrotation() => 31
  | StN32() => 32
  | StN33() => 33
  | StN34() => 34
  | StFlip() => 35
  | StN36() => 36
  | StN37() => 37
  | StN38() => 38
  | StN39() => 39
  | StDabsPerBasicRadius() => 40
  | StDabsPerActualRadius() => 41
  | StDabsPerSecond() => 42
  | StN43() => 43
