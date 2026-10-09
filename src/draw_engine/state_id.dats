#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/state_id.sats"

fn state_of_0(i: int): BrushState =
  if i = 0 then StX()
  else if i = 1 then StY()
  else if i = 2 then StPressure()
  else if i = 3 then StPartialDabs()
  else if i = 4 then StActualRadius()
  else if i = 5 then StN5()
  else if i = 6 then StN6()
  else if i = 7 then StN7()
  else if i = 8 then StN8()
  else if i = 9 then StN9()
  else if i = 10 then StN10()
  else if i = 11 then StN11()
  else if i = 12 then StN12()
  else if i = 13 then StN13()
  else if i = 14 then StActualX()
  else if i = 15 then StActualY()
  else if i = 16 then StNormDxSlow()
  else if i = 17 then StNormDySlow()
  else if i = 18 then StNormSpeed1Slow()
  else if i = 19 then StNormSpeed2Slow()
  else if i = 20 then StStroke()
  else if i = 21 then StStrokeStarted()
  else StNone()

fn state_of_22(i: int): BrushState =
  if i = 22 then StN22()
  else if i = 23 then StN23()
  else if i = 24 then StActualEllipticalDabRatio()
  else if i = 25 then StActualEllipticalDabAngle()
  else if i = 26 then StN26()
  else if i = 27 then StN27()
  else if i = 28 then StN28()
  else if i = 29 then StN29()
  else if i = 30 then StViewzoom()
  else if i = 31 then StViewrotation()
  else if i = 32 then StN32()
  else if i = 33 then StN33()
  else if i = 34 then StN34()
  else if i = 35 then StFlip()
  else if i = 36 then StN36()
  else if i = 37 then StN37()
  else if i = 38 then StN38()
  else if i = 39 then StN39()
  else if i = 40 then StDabsPerBasicRadius()
  else if i = 41 then StDabsPerActualRadius()
  else if i = 42 then StDabsPerSecond()
  else if i = 43 then StN43()
  else StNone()

implement state_of(i) =
  if i < 22 then state_of_0(i)
  else if i < 44 then state_of_22(i)
  else StNone()

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
  | StNone() => ~1
