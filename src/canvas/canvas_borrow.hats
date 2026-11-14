// src/canvas/canvas_borrow.hats
// Canvas tutamaci: ham int, her islem icin tek islemlik claim -> islem -> stash ile kanita cevrilir.
// Tuketici modullerin (events, widgets, sidebar_state) ortak sarmalayicilari; kanit uretimi burada degil
// canvas.dats'taki canvas_claim'dedir.
#ifndef CANVAS_BORROW_HATS
#define CANVAS_BORROW_HATS

staload "gl/gl_io.sats"
staload "sys/capability.sats"
staload "brushes/brush_group.sats"
staload "canvas/canvas_view.sats"

fn cv_render(gio: !GL_IO | raw: int, canvas_w: int, canvas_h: int): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_render(live, gio | c, canvas_w, canvas_h)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_on_wheel(raw: int, mx: int, my: int, dy: int): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_on_wheel(live | c, mx, my, dy)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_on_mouse_down(gio: !GL_IO | raw: int, mx: float, my: float, btn: int, is_pan: int, pressure: float): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_on_mouse_down(live, gio | c, mx, my, btn, is_pan, pressure)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_on_mouse_move(gio: !GL_IO | raw: int, mx: float, my: float, btn: int, is_pan: int, pressure: float): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_on_mouse_move(live, gio | c, mx, my, btn, is_pan, pressure)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_on_mouse_up(gio: !GL_IO | raw: int, mx: float, my: float, btn: int, is_pan: int): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_on_mouse_up(live, gio | c, mx, my, btn, is_pan)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_set_brush_color(raw: int, r: float, g: float, b: float): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_set_brush_color(live | c, r, g, b)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_set_brush_setting(raw: int, id: int, v: float): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_set_brush_setting(live | c, id, v)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_apply_startup(raw: int): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_apply_startup(live | c)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_apply_catalog_brush(raw: int, g: BrushGroup, i: int): void = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val () = canvas_apply_catalog_brush(live | c, g, i)
    val _ = canvas_stash(live | c)
  in () end else let
    prval None_v() = pf
  in () end
end

fn cv_get_brush_setting(raw: int, id: int): float = let
  val (pf | ok, c) = canvas_claim(raw)
in
  if ok then let
    prval Some_v(live) = pf
    val r = canvas_get_brush_setting(live | c, id)
    val _ = canvas_stash(live | c)
  in r end else let
    prval None_v() = pf
  in 0.0f end
end

#endif
