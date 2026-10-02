// src/draw_engine/draw_engine.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "./settings.dats"
staload "./helpers.dats"
staload "./surface.dats"
staload "./brush.dats"

// --- Fırça Motoru Fonksiyon Bildirimleri ---
extern fun draw_engine_brush_new(): ptr = "ext#draw_engine_brush_new"
extern fun draw_engine_brush_free(b: ptr): void = "ext#draw_engine_brush_free"
extern fun draw_engine_brush_reset(b: ptr): void = "ext#draw_engine_brush_reset"
extern fun draw_engine_brush_new_stroke(b: ptr): void = "ext#draw_engine_brush_new_stroke"
extern fun draw_engine_brush_set_base_value(b: ptr, id: int, v: float): void = "ext#draw_engine_brush_set_base_value"
extern fun draw_engine_brush_get_base_value(b: ptr, id: int): float = "ext#draw_engine_brush_get_base_value"
extern fun draw_engine_brush_stroke_to(
    b: ptr, surf: ptr,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#draw_engine_brush_stroke_to"

// --- Dışa Aktarılan Çizim Motoru (Draw Engine) API ---
extern fun draw_engine_init(): void = "ext#draw_engine_init"
implement draw_engine_init() = ()

extern fun mypaint_brush_new(): ptr = "ext#mypaint_brush_new"
implement mypaint_brush_new() = draw_engine_brush_new()

extern fun mypaint_brush_unref(b: ptr): void = "ext#mypaint_brush_unref"
implement mypaint_brush_unref(b) = draw_engine_brush_free(b)

extern fun mypaint_brush_reset(b: ptr): void = "ext#mypaint_brush_reset"
implement mypaint_brush_reset(b) = draw_engine_brush_reset(b)

extern fun mypaint_brush_new_stroke(b: ptr): void = "ext#mypaint_brush_new_stroke"
implement mypaint_brush_new_stroke(b) = draw_engine_brush_new_stroke(b)

extern fun mypaint_brush_set_base_value(b: ptr, id: int, v: float): void = "ext#mypaint_brush_set_base_value"
implement mypaint_brush_set_base_value(b, id, v) = draw_engine_brush_set_base_value(b, id, v)

extern fun mypaint_brush_get_base_value(b: ptr, id: int): float = "ext#mypaint_brush_get_base_value"
implement mypaint_brush_get_base_value(b, id) = draw_engine_brush_get_base_value(b, id)

extern fun mypaint_brush_stroke_to(
    b: ptr, surf: ptr,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#mypaint_brush_stroke_to"
implement mypaint_brush_stroke_to(b, surf, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear) =
    draw_engine_brush_stroke_to(b, surf, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear)

extern fun mypaint_init(): void = "ext#mypaint_init"
implement mypaint_init() = ()

extern fun mypaint_brush_ref(b: ptr): void = "ext#mypaint_brush_ref"
implement mypaint_brush_ref(b) = ()

extern fun mypaint_brush_get_state(b: ptr, i: int): float = "ext#mypaint_brush_get_state"
implement mypaint_brush_get_state(b, i) = draw_engine_brush_get_state(b, i)

extern fun mypaint_brush_set_state(b: ptr, i: int, v: float): void = "ext#mypaint_brush_set_state"
implement mypaint_brush_set_state(b, i, v) = draw_engine_brush_set_state(b, i, v)

extern fun mypaint_brush_is_constant(b: ptr, id: int): int = "ext#mypaint_brush_is_constant"
implement mypaint_brush_is_constant(b, id) = 1

extern fun mypaint_brush_get_inputs_used_n(b: ptr, id: int): int = "ext#mypaint_brush_get_inputs_used_n"
implement mypaint_brush_get_inputs_used_n(b, id) = 0

extern fun mypaint_brush_get_total_stroke_painting_time(b: ptr): double = "ext#mypaint_brush_get_total_stroke_painting_time"
implement mypaint_brush_get_total_stroke_painting_time(b) = 0.0


