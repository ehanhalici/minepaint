// src/canvas/canvas_view.sats
// Canvas durumu icin dogrusal yetenek: CANVAS_LIVE(c) olmadan canvas islemi yapilamaz.
// Kanit canvas_state_create ile uretilir; kullanan modul canvas_claim ile odunc alir, canvas_stash ile verir.

#include "draw_engine/minepaint_types.hats"
staload "gl/gl_io.sats"
staload "sys/capability.sats"
staload "brushes/brush_group.sats"

#define CANVAS_CAP 4

stadef CANVAS_LIVE (c: int) = CAP(KIND_CANVAS, c)

fun canvas_state_create (brush: int): [c:nat | c < CANVAS_CAP] (CANVAS_LIVE(c) | int(c)) = "ext#canvas_state_create"

fun canvas_render {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c), gio: !GL_IO | h: int(c), canvas_w: int, canvas_h: int): void = "ext#canvas_render"
fun canvas_on_wheel {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c) | h: int(c), mx: int, my: int, dy: int): void = "ext#canvas_on_wheel"
fun canvas_on_mouse_down {c:nat | c < CANVAS_CAP} (
  pf: !CANVAS_LIVE(c), gio: !GL_IO | h: int(c), mx: float, my: float, btn: int, is_pan: int, pressure: float, now: double
): void = "ext#canvas_on_mouse_down"
fun canvas_on_mouse_move {c:nat | c < CANVAS_CAP} (
  pf: !CANVAS_LIVE(c), gio: !GL_IO | h: int(c), mx: float, my: float, btn: int, is_pan: int, pressure: float, now: double
): void = "ext#canvas_on_mouse_move"
fun canvas_on_mouse_up {c:nat | c < CANVAS_CAP} (
  pf: !CANVAS_LIVE(c), gio: !GL_IO | h: int(c), mx: float, my: float, btn: int, is_pan: int
): void = "ext#canvas_on_mouse_up"
fun canvas_set_brush_color {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c) | h: int(c), r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
fun canvas_set_brush_setting {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c) | h: int(c), id: int, v: float): void = "ext#canvas_set_brush_setting"
fun canvas_apply_startup {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c) | h: int(c)): void = "ext#canvas_apply_startup"
fun canvas_apply_catalog_brush {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c) | h: int(c), g: BrushGroup, i: int): void = "ext#canvas_apply_catalog_brush"
fun canvas_get_brush_setting {c:nat | c < CANVAS_CAP} (pf: !CANVAS_LIVE(c) | h: int(c), id: int): float = "ext#canvas_get_brush_setting"

fun canvas_stash {c:nat | c < CANVAS_CAP} (pf: CANVAS_LIVE(c) | h: int(c)): int = "ext#canvas_stash"
fun canvas_claim (raw: int): [ok:bool][c:nat | c < CANVAS_CAP] (option_v(CANVAS_LIVE(c), ok) | bool(ok), int(c)) = "ext#canvas_claim"
