#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "ui/slider_id.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

val g_slider_tab = arrayref_make_arrpsz($arrpsz{SliderId}(
  SliderSize(), SliderOpaque(), SliderSharp(), SliderGrain(),
  SliderPigment(), SliderSmooth(), SliderPressure(), SliderTwist()
))

implement slider_id_try(i) = let
  val @(ok, k) = ix_try(i, 8)
in @(ok, g_slider_tab[k]) end

implement slider_id_to_int(s) =
  case+ s of
  | SliderSize() => 0
  | SliderOpaque() => 1
  | SliderSharp() => 2
  | SliderGrain() => 3
  | SliderPigment() => 4
  | SliderSmooth() => 5
  | SliderPressure() => 6
  | SliderTwist() => 7
