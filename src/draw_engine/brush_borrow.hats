// src/draw_engine/brush_borrow.hats
// Firca tutamaci: ham int, her islem icin tek islemlik claim -> islem -> stash ile kanita cevrilir.
// Kanit uretimi burada degil brush.dats'taki minepaint_brush_claim / minepaint_brush_new'dedir.
#ifndef BRUSH_BORROW_HATS
#define BRUSH_BORROW_HATS

staload "gl/gl_io.sats"
staload "sys/capability.sats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/surface_target.sats"
staload "draw_engine/brush_view.sats"

fn br_reset(raw: int): void = let
  val (pf | ok, b) = minepaint_brush_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_brush_reset(live | b)
    val _ = minepaint_brush_stash(live | b)
  in () end else let
    prval None_v() = pf
  in () end
end

fn br_new_stroke(raw: int): void = let
  val (pf | ok, b) = minepaint_brush_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_brush_new_stroke(live | b)
    val _ = minepaint_brush_stash(live | b)
  in () end else let
    prval None_v() = pf
  in () end
end

fn br_set_base_value(raw: int, id: SettingId, v: float): void = let
  val (pf | ok, b) = minepaint_brush_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_brush_set_base_value(live | b, id, v)
    val _ = minepaint_brush_stash(live | b)
  in () end else let
    prval None_v() = pf
  in () end
end

fn br_get_base_value(raw: int, id: SettingId): float = let
  val (pf | ok, b) = minepaint_brush_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val r = minepaint_brush_get_base_value(live | b, id)
    val _ = minepaint_brush_stash(live | b)
  in r end else let
    prval None_v() = pf
  in 0.0f end
end

fn br_apply_startup(raw: int): void = let
  val (pf | ok, b) = minepaint_brush_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = minepaint_brush_apply_startup(live | b)
    val _ = minepaint_brush_stash(live | b)
  in () end else let
    prval None_v() = pf
  in () end
end

fn br_stroke_to(gio: !GL_IO | raw: int, tgt: MpTarget, x: float, y: float, pressure: float, xtilt: float, ytilt: float, dtime: double, viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int): int = let
  val (pf | ok, b) = minepaint_brush_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val r = minepaint_brush_stroke_to(live, gio | b, tgt, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear)
    val _ = minepaint_brush_stash(live | b)
  in r end else let
    prval None_v() = pf
  in 0 end
end

#endif
