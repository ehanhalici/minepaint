// src/draw_engine/draw_engine.dats
// Disa aktarilan firca API'si: tipli (BRUSH_LIVE kanitli) sarmalayicilar ham motor islevlerine iletilir.
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "gl/gl_io.sats"
staload "./settings.dats"
staload "./helpers.dats"
staload "./brush.dats"
staload "sys/capability.sats"
staload "draw_engine/brush_view.sats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/state_id.sats"
staload "draw_engine/surface_target.sats"

implement minepaint_brush_reset(pf | b) = draw_engine_brush_reset(b)

implement minepaint_brush_new_stroke(pf | b) = draw_engine_brush_new_stroke(b)

implement minepaint_brush_set_base_value(pf | b, id, v) = draw_engine_brush_set_base_value(b, id, v)

implement minepaint_brush_get_base_value(pf | b, id) = draw_engine_brush_get_base_value(b, id)

implement minepaint_brush_apply_startup(pf | b) = draw_engine_brush_apply_startup(b)

implement minepaint_brush_stroke_to(pf, gio | b, tgt, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear) =
  draw_engine_brush_stroke_to(gio | b, tgt, x, y, pressure, xtilt, ytilt, dtime, viewzoom, viewrotation, barrel_rotation, linear)
