// src/draw_engine/draw_engine.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "./settings.dats"
staload "./helpers.dats"
staload "./surface.dats"
staload "./brush.dats"

// --- Fırça Motoru Fonksiyon Bildirimleri ---
extern fun draw_engine_brush_new(): int = "ext#draw_engine_brush_new"
extern fun draw_engine_brush_free(b: int): void = "ext#draw_engine_brush_free"
extern fun draw_engine_brush_reset(b: int): void = "ext#draw_engine_brush_reset"
extern fun draw_engine_brush_new_stroke(b: int): void = "ext#draw_engine_brush_new_stroke"
extern fun draw_engine_brush_set_base_value(b: int, id: int, v: float): void = "ext#draw_engine_brush_set_base_value"
extern fun draw_engine_brush_get_base_value(b: int, id: int): float = "ext#draw_engine_brush_get_base_value"
extern fun draw_engine_brush_apply_startup(b: int): void = "ext#draw_engine_brush_apply_startup"
extern fun draw_engine_brush_stroke_to(
    b: int, surf: ptr,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#draw_engine_brush_stroke_to"

// --- Dışa Aktarılan Çizim Motoru (Draw Engine) API ---
extern fun draw_engine_init(): void = "ext#draw_engine_init"
implement draw_engine_init() = ()

extern fun minepaint_brush_new(): int = "ext#minepaint_brush_new"
implement minepaint_brush_new() = draw_engine_brush_new()

extern fun minepaint_brush_unref(b: int): void = "ext#minepaint_brush_unref"
implement minepaint_brush_unref(b) = draw_engine_brush_free(b)

extern fun minepaint_brush_reset(b: int): void = "ext#minepaint_brush_reset"
implement minepaint_brush_reset(b) = draw_engine_brush_reset(b)

extern fun minepaint_brush_new_stroke(b: int): void = "ext#minepaint_brush_new_stroke"
implement minepaint_brush_new_stroke(b) = draw_engine_brush_new_stroke(b)

extern fun minepaint_brush_set_base_value(b: int, id: int, v: float): void = "ext#minepaint_brush_set_base_value"
implement minepaint_brush_set_base_value(b, id, v) = draw_engine_brush_set_base_value(b, id, v)

extern fun minepaint_brush_get_base_value(b: int, id: int): float = "ext#minepaint_brush_get_base_value"
implement minepaint_brush_get_base_value(b, id) = draw_engine_brush_get_base_value(b, id)

extern fun minepaint_brush_apply_startup(b: int): void = "ext#minepaint_brush_apply_startup"
implement minepaint_brush_apply_startup(b) = draw_engine_brush_apply_startup(b)

extern fun minepaint_brush_stroke_to(
    b: int, surf: ptr,
    x: float, y: float, pressure: float,
    xtilt: float, ytilt: float, dtime: double,
    viewzoom: float, viewrotation: float, barrel_rotation: float, linear: int
): int = "ext#minepaint_brush_stroke_to"
implement minepaint_brush_stroke_to(b, surf, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear) =
    draw_engine_brush_stroke_to(b, surf, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear)

extern fun minepaint_init(): void = "ext#minepaint_init"
implement minepaint_init() = ()

extern fun minepaint_brush_ref(b: int): void = "ext#minepaint_brush_ref"
implement minepaint_brush_ref(b) = ()

extern fun minepaint_brush_get_state(b: int, i: int): float = "ext#minepaint_brush_get_state"
implement minepaint_brush_get_state(b, i) = draw_engine_brush_get_state(b, i)

extern fun minepaint_brush_set_state(b: int, i: int, v: float): void = "ext#minepaint_brush_set_state"
implement minepaint_brush_set_state(b, i, v) = draw_engine_brush_set_state(b, i, v)

extern fun minepaint_brush_is_constant(b: int, id: int): int = "ext#minepaint_brush_is_constant"
implement minepaint_brush_is_constant(b, id) = 1

extern fun minepaint_brush_get_inputs_used_n(b: int, id: int): int = "ext#minepaint_brush_get_inputs_used_n"
implement minepaint_brush_get_inputs_used_n(b, id) = 0

extern fun minepaint_brush_get_total_stroke_painting_time(b: int): double = "ext#minepaint_brush_get_total_stroke_painting_time"
implement minepaint_brush_get_total_stroke_painting_time(b) = 0.0


