// src/draw_engine/brush_view.sats
// Firca motoru icin dogrusal yetenek: BRUSH_LIVE(b) olmadan firca islemi yapilamaz.
// Kanit minepaint_brush_new ile uretilir; kullanan modul minepaint_brush_claim ile odunc alir,
// minepaint_brush_stash ile geri verir. Katalog `_apply(b: int, i: int)` imzalari ham int kalir.

staload "gl/gl_io.sats"
staload "sys/capability.sats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/surface_target.sats"

#define BRUSH_CAP 8

stadef BRUSH_LIVE (b: int) = CAP(KIND_BRUSH, b)

fun minepaint_brush_new (): [b:nat | b < BRUSH_CAP] (BRUSH_LIVE(b) | int(b)) = "ext#minepaint_brush_new"

fun minepaint_brush_reset {b:nat | b < BRUSH_CAP} (pf: !BRUSH_LIVE(b) | b: int(b)): void = "ext#minepaint_brush_reset"
fun minepaint_brush_new_stroke {b:nat | b < BRUSH_CAP} (pf: !BRUSH_LIVE(b) | b: int(b)): void = "ext#minepaint_brush_new_stroke"
fun minepaint_brush_set_base_value {b:nat | b < BRUSH_CAP} (pf: !BRUSH_LIVE(b) | b: int(b), id: SettingId, v: float): void = "ext#minepaint_brush_set_base_value"
fun minepaint_brush_get_base_value {b:nat | b < BRUSH_CAP} (pf: !BRUSH_LIVE(b) | b: int(b), id: SettingId): float = "ext#minepaint_brush_get_base_value"
fun minepaint_brush_apply_startup {b:nat | b < BRUSH_CAP} (pf: !BRUSH_LIVE(b) | b: int(b)): void = "ext#minepaint_brush_apply_startup"
fun minepaint_brush_stroke_to {b:nat | b < BRUSH_CAP} (
  pf: !BRUSH_LIVE(b), gio: !GL_IO | b: int(b), tgt: MpTarget,
  x: float, y: float, pressure: float,
  xtilt: float, ytilt: float, dtime: double,
  viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#minepaint_brush_stroke_to"

fun minepaint_brush_stash {b:nat | b < BRUSH_CAP} (pf: BRUSH_LIVE(b) | b: int(b)): int = "ext#minepaint_brush_stash"
fun minepaint_brush_claim (raw: int): [ok:bool][b:nat | b < BRUSH_CAP] (option_v(BRUSH_LIVE(b), ok) | bool(ok), int(b)) = "ext#minepaint_brush_claim"
