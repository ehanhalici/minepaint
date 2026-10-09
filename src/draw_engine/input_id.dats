#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/input_id.sats"

fn input_of_0(i: int): InputId =
  if i = 0 then InPressure()
  else if i = 1 then InRandom()
  else if i = 2 then InStroke()
  else if i = 3 then InDirection()
  else if i = 4 then InTiltDeclination()
  else if i = 5 then InTiltAscension()
  else if i = 6 then InSpeed1()
  else if i = 7 then InSpeed2()
  else if i = 8 then InCustom()
  else if i = 9 then InDirectionAngle()
  else if i = 10 then InAttackAngle()
  else if i = 11 then InTiltDeclinationX()
  else if i = 12 then InTiltDeclinationY()
  else if i = 13 then InGridmapX()
  else if i = 14 then InGridmapY()
  else if i = 15 then InViewzoom()
  else if i = 16 then InBrushRadius()
  else if i = 17 then InBarrelRotation()
  else InNone()

implement input_of(i) =
  if i < 18 then input_of_0(i) else InNone()

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
  | InNone() => ~1
