#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/setting_id.sats"

fn setting_of_0(i: int): SettingId =
  if i = 0 then SetOpaque()
  else if i = 1 then SetOpaqueMultiply()
  else if i = 2 then SetOpaqueLinearize()
  else if i = 3 then SetRadiusLogarithmic()
  else if i = 4 then SetHardness()
  else if i = 5 then SetSoftness()
  else if i = 6 then SetAntiAliasing()
  else if i = 7 then SetDabsPerBasicRadius()
  else if i = 8 then SetDabsPerActualRadius()
  else if i = 9 then SetDabsPerSecond()
  else if i = 10 then SetGridmapScale()
  else if i = 11 then SetGridmapScaleX()
  else if i = 12 then SetGridmapScaleY()
  else if i = 13 then SetRadiusByRandom()
  else if i = 14 then SetSpeed1Slowness()
  else if i = 15 then SetSpeed2Slowness()
  else if i = 16 then SetSpeed1Gamma()
  else if i = 17 then SetSpeed2Gamma()
  else if i = 18 then SetOffsetByRandom()
  else if i = 19 then SetOffsetY()
  else if i = 20 then SetOffsetX()
  else if i = 21 then SetN21()
  else SetNone()

fn setting_of_22(i: int): SettingId =
  if i = 22 then SetN22()
  else if i = 23 then SetN23()
  else if i = 24 then SetN24()
  else if i = 25 then SetN25()
  else if i = 26 then SetN26()
  else if i = 27 then SetN27()
  else if i = 28 then SetN28()
  else if i = 29 then SetN29()
  else if i = 30 then SetN30()
  else if i = 31 then SetSlowTracking()
  else if i = 32 then SetSlowTrackingPerDab()
  else if i = 33 then SetTrackingNoise()
  else if i = 34 then SetColorH()
  else if i = 35 then SetColorS()
  else if i = 36 then SetColorV()
  else if i = 37 then SetN37()
  else if i = 38 then SetChangeColorH()
  else if i = 39 then SetChangeColorL()
  else if i = 40 then SetN40()
  else if i = 41 then SetChangeColorV()
  else if i = 42 then SetN42()
  else if i = 43 then SetN43()
  else SetNone()

fn setting_of_44(i: int): SettingId =
  if i = 44 then SetPaintMode()
  else if i = 45 then SetN45()
  else if i = 46 then SetN46()
  else if i = 47 then SetN47()
  else if i = 48 then SetN48()
  else if i = 49 then SetN49()
  else if i = 50 then SetEraser()
  else if i = 51 then SetStrokeThreshold()
  else if i = 52 then SetStrokeDurationLog()
  else if i = 53 then SetStrokeHoldtime()
  else if i = 54 then SetN54()
  else if i = 55 then SetN55()
  else if i = 56 then SetEllipticalDabRatio()
  else if i = 57 then SetEllipticalDabAngle()
  else if i = 58 then SetDirectionFilter()
  else if i = 59 then SetLockAlpha()
  else if i = 60 then SetColorize()
  else if i = 61 then SetPosterize()
  else if i = 62 then SetPosterizeNum()
  else if i = 63 then SetSnapToPixel()
  else if i = 64 then SetPressureGainLog()
  else SetNone()

implement setting_of(i) =
  if i < 22 then setting_of_0(i)
  else if i < 44 then setting_of_22(i)
  else if i < 65 then setting_of_44(i)
  else SetNone()

implement setting_ix(s) =
  case+ s of
  | SetOpaque() => 0
  | SetOpaqueMultiply() => 1
  | SetOpaqueLinearize() => 2
  | SetRadiusLogarithmic() => 3
  | SetHardness() => 4
  | SetSoftness() => 5
  | SetAntiAliasing() => 6
  | SetDabsPerBasicRadius() => 7
  | SetDabsPerActualRadius() => 8
  | SetDabsPerSecond() => 9
  | SetGridmapScale() => 10
  | SetGridmapScaleX() => 11
  | SetGridmapScaleY() => 12
  | SetRadiusByRandom() => 13
  | SetSpeed1Slowness() => 14
  | SetSpeed2Slowness() => 15
  | SetSpeed1Gamma() => 16
  | SetSpeed2Gamma() => 17
  | SetOffsetByRandom() => 18
  | SetOffsetY() => 19
  | SetOffsetX() => 20
  | SetN21() => 21
  | SetN22() => 22
  | SetN23() => 23
  | SetN24() => 24
  | SetN25() => 25
  | SetN26() => 26
  | SetN27() => 27
  | SetN28() => 28
  | SetN29() => 29
  | SetN30() => 30
  | SetSlowTracking() => 31
  | SetSlowTrackingPerDab() => 32
  | SetTrackingNoise() => 33
  | SetColorH() => 34
  | SetColorS() => 35
  | SetColorV() => 36
  | SetN37() => 37
  | SetChangeColorH() => 38
  | SetChangeColorL() => 39
  | SetN40() => 40
  | SetChangeColorV() => 41
  | SetN42() => 42
  | SetN43() => 43
  | SetPaintMode() => 44
  | SetN45() => 45
  | SetN46() => 46
  | SetN47() => 47
  | SetN48() => 48
  | SetN49() => 49
  | SetEraser() => 50
  | SetStrokeThreshold() => 51
  | SetStrokeDurationLog() => 52
  | SetStrokeHoldtime() => 53
  | SetN54() => 54
  | SetN55() => 55
  | SetEllipticalDabRatio() => 56
  | SetEllipticalDabAngle() => 57
  | SetDirectionFilter() => 58
  | SetLockAlpha() => 59
  | SetColorize() => 60
  | SetPosterize() => 61
  | SetPosterizeNum() => 62
  | SetSnapToPixel() => 63
  | SetPressureGainLog() => 64
  | SetNone() => ~1

