#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/setting_id.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

// Ters tablo (veri): indeks -> varyant. Sira setting_ix ile ayni.
val g_setting_tab = arrayref_make_arrpsz($arrpsz{SettingId}(
  SetOpaque(),
  SetOpaqueMultiply(),
  SetOpaqueLinearize(),
  SetRadiusLogarithmic(),
  SetHardness(),
  SetSoftness(),
  SetAntiAliasing(),
  SetDabsPerBasicRadius(),
  SetDabsPerActualRadius(),
  SetDabsPerSecond(),
  SetGridmapScale(),
  SetGridmapScaleX(),
  SetGridmapScaleY(),
  SetRadiusByRandom(),
  SetSpeed1Slowness(),
  SetSpeed2Slowness(),
  SetSpeed1Gamma(),
  SetSpeed2Gamma(),
  SetOffsetByRandom(),
  SetOffsetY(),
  SetOffsetX(),
  SetN21(),
  SetN22(),
  SetN23(),
  SetN24(),
  SetN25(),
  SetN26(),
  SetN27(),
  SetN28(),
  SetN29(),
  SetN30(),
  SetSlowTracking(),
  SetSlowTrackingPerDab(),
  SetTrackingNoise(),
  SetColorH(),
  SetColorS(),
  SetColorV(),
  SetN37(),
  SetChangeColorH(),
  SetChangeColorL(),
  SetN40(),
  SetChangeColorV(),
  SetN42(),
  SetN43(),
  SetPaintMode(),
  SetN45(),
  SetN46(),
  SetN47(),
  SetN48(),
  SetN49(),
  SetEraser(),
  SetStrokeThreshold(),
  SetStrokeDurationLog(),
  SetStrokeHoldtime(),
  SetN54(),
  SetN55(),
  SetEllipticalDabRatio(),
  SetEllipticalDabAngle(),
  SetDirectionFilter(),
  SetLockAlpha(),
  SetColorize(),
  SetPosterize(),
  SetPosterizeNum(),
  SetSnapToPixel(),
  SetPressureGainLog()
))

implement setting_try(i) = let
  val @(ok, k) = ix_try(i, 65)
in @(ok, g_setting_tab[k]) end

implement setting_of(i) = let
  val @(ok, v) = setting_try(i)
in
  if ok then v else anth_die_box{SettingId}(DieContractViolation())
end

// Tam kapsamli tablo: varyant basina bir kol (veri tablosu; R17 istisnasi).
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
