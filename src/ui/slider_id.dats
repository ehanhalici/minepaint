#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "ui/slider_id.sats"

implement slider_id_try(i) =
  case+ i of
  | 0 => @(true, SliderSize())
  | 1 => @(true, SliderOpaque())
  | 2 => @(true, SliderSharp())
  | 3 => @(true, SliderGrain())
  | 4 => @(true, SliderPigment())
  | 5 => @(true, SliderSmooth())
  | 6 => @(true, SliderPressure())
  | 7 => @(true, SliderTwist())
  | _ => @(false, SliderSize())

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
