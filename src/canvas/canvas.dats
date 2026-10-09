// src/canvas/canvas.dats
// Canvas records live in a dynloaded arena. main.dats loads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "draw_engine/engine_safe.hats"
staload "ui/color.dats"
staload "canvas/stroke_queue.dats"
staload "canvas/gl_surface.dats"
staload "canvas/layer.dats"
staload "canvas/layer_box.sats"
staload "brushes/brush_group.sats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/surface_box.sats"

typedef canvas_state_record = @{
  brush= int,
  surf= MpSurface,
  layer= MpLayer,
  cam_x= float,
  cam_y= float,
  zoom= float,
  last_mouse_x= float,
  last_mouse_y= float,
  last_time= double,
  q= int
}

#define CANVAS_CAP 4

val g_blank = @{
  brush= ~1, surf= mp_surface_none(), layer= layer_none(),
  cam_x= 0.0f, cam_y= 0.0f, zoom= 1.0f,
  last_mouse_x= 0.0f, last_mouse_y= 0.0f,
  last_time= 0.0, q= ~1
} : canvas_state_record
val g_alive = air_arena(CANVAS_CAP, airlock_esz_int())
val g_canvas = arrayref_make_elt<canvas_state_record>(i2sz(CANVAS_CAP), g_blank)
val g_fresh = ref<int>(0)

fn cget(h: int): canvas_state_record = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < CANVAS_CAP) then
    if air_bget(g_alive, h, CANVAS_CAP) then g_canvas[i] else g_blank
  else g_blank
end

fn cput(h: int, v: canvas_state_record): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < CANVAS_CAP) then
    if air_bget(g_alive, h, CANVAS_CAP) then g_canvas[i] := v else ()
  else ()
end

fn canvas_alloc(v: canvas_state_record): int = let
  val n = !g_fresh
  val () = assertloc(n < CANVAS_CAP)
  val () = !g_fresh := n + 1
  val i = g1ofg0(n)
  val () = air_bset(g_alive, n, CANVAS_CAP, true)
  val () = if (i >= 0) * (i < CANVAS_CAP) then g_canvas[i] := v
in
  n
end

// OpenGL ve Fırça Sabitleri
macdef GL_PROJECTION = $extval(int, "GL_PROJECTION")
macdef GL_MODELVIEW = $extval(int, "GL_MODELVIEW")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "GL_COLOR_BUFFER_BIT")

#define MINEPAINT_BRUSH_SETTING_COLOR_H 34
#define MINEPAINT_BRUSH_SETTING_COLOR_S 35
#define MINEPAINT_BRUSH_SETTING_COLOR_V 36

extern fun glMatrixMode(m: int): void = "mac#"
extern fun glLoadIdentity(): void = "mac#"
extern fun glOrtho(l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glViewport(x: int, y: int, w: int, h: int): void = "mac#"
extern fun glClearColor(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glClear(mask: int): void = "mac#"
extern fun glTranslatef(x: float, y: float, z: float): void = "mac#"
extern fun glScalef(x: float, y: float, z: float): void = "mac#"

extern fun minepaint_brush_reset(brush: int): void = "ext#minepaint_brush_reset"
extern fun minepaint_brush_set_base_value(brush: int, setting: SettingId, value: float): void = "ext#minepaint_brush_set_base_value"
extern fun minepaint_brush_get_base_value(brush: int, setting: SettingId): float = "ext#minepaint_brush_get_base_value"

extern fun get_time_seconds(): double = "ext#get_time_seconds"
fn i2f(i: int): float = g0int2float_int_float(i)
fn f_lt(a: float, b: float): bool = a < b
fn f_gt(a: float, b: float): bool = a > b
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)

// Stroke Queue API
extern fun stroke_queue_teleport(brush: int, surf: MpSurface, x: float, y: float): void = "ext#stroke_queue_teleport"
extern fun stroke_queue_start(wx: float, wy: float, pressure: float): int = "ext#stroke_queue_start"
extern fun stroke_queue_step(
  layer: MpLayer, brush: int, surf: MpSurface, zoom: float,
  qh: int, wx: float, wy: float, pressure: float, elapsed: double
): int = "ext#stroke_queue_step"
extern fun stroke_queue_finish(
  layer: MpLayer, brush: int, surf: MpSurface, zoom: float, qh: int
): void = "ext#stroke_queue_finish"
extern fun stroke_queue_free(qh: int): void = "ext#stroke_queue_free"

extern fun minepaint_brush_apply_startup(b: int): void = "ext#minepaint_brush_apply_startup"
extern fun catalog_apply_brush(b: int, g: BrushGroup, i: int): void = "ext#catalog_apply_brush"

// --- Render Yardımcıları (SLAP, SRP) ---
fn setup_canvas_viewport(w: int, h: int): void = {
  val () = glViewport(0, 0, w, h)
  val () = glMatrixMode(GL_PROJECTION)
  val () = glLoadIdentity()
  val () = glOrtho(0.0, g0int2float(w), g0int2float(h), 0.0, ~1.0, 1.0)
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glLoadIdentity()
  val () = glClearColor(0.07f, 0.07f, 0.07f, 1.0f)
  val () = glClear(GL_COLOR_BUFFER_BIT)
}

fn put_layer(h: int, layer: MpLayer): void = let
  val s = cget(h)
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= layer,
    cam_x= s.cam_x, cam_y= s.cam_y, zoom= s.zoom,
    last_mouse_x= s.last_mouse_x, last_mouse_y= s.last_mouse_y,
    last_time= s.last_time, q= s.q
  })
end

fn draw_layer_content(h: int, canvas_w: int, canvas_h: int): void = let
  val s0 = cget(h)
  val () = if layer_is_null(s0.layer) != 0 then put_layer(h, layer_create(0, 0))
  val s = cget(h)
in
  if layer_is_null(s.layer) = 0 then let
    val cur_zoom = s.zoom
    val vl = f_div(f_sub(0.0f, s.cam_x), cur_zoom)
    val vt = f_div(f_sub(0.0f, s.cam_y), cur_zoom)
    val vr = f_div(f_sub(i2f(canvas_w), s.cam_x), cur_zoom)
    val vb = f_div(f_sub(i2f(canvas_h), s.cam_y), cur_zoom)
  in
    layer_draw_tiles(s.layer, vl, vt, vr, vb, cur_zoom)
  end else ()
end

// --- Çizim Render Fonksiyonu ---
extern fun canvas_render(h: int, canvas_w: int, canvas_h: int): void = "ext#canvas_render"
implement canvas_render(h, canvas_w, canvas_h) = let
  val s = cget(h)
  val () = setup_canvas_viewport(canvas_w, canvas_h)
  val () = glPushMatrix()
  val () = glTranslatef(s.cam_x, s.cam_y, 0.0f)
  val () = glScalef(s.zoom, s.zoom, 1.0f)
  val () = draw_layer_content(h, canvas_w, canvas_h)
  val () = glPopMatrix()
in () end

// --- Fare Tekerleği Zoom ---
extern fun canvas_on_wheel(h: int, mx: int, my: int, dy: int): void = "ext#canvas_on_wheel"
implement canvas_on_wheel(h, mx, my, dy) = let
  val s = cget(h)
  val start_x = i2f(mx)
  val start_y = i2f(my)
  val cur_zoom = s.zoom
  val mb_x = f_div(f_sub(start_x, s.cam_x), cur_zoom)
  val mb_y = f_div(f_sub(start_y, s.cam_y), cur_zoom)
  val step_zoom = if dy < 0 then f_mul(cur_zoom, 1.15f) else f_mul(cur_zoom, 0.85f)
  val min_clamped = if f_lt(step_zoom, 0.02f) then 0.02f else step_zoom
  val new_zoom = if f_gt(min_clamped, 50.0f) then 50.0f else min_clamped
  val ma_x = f_div(f_sub(start_x, s.cam_x), new_zoom)
  val ma_y = f_div(f_sub(start_y, s.cam_y), new_zoom)
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= s.layer,
    cam_x= f_add(s.cam_x, f_mul(f_sub(ma_x, mb_x), new_zoom)),
    cam_y= f_add(s.cam_y, f_mul(f_sub(ma_y, mb_y), new_zoom)),
    zoom= new_zoom,
    last_mouse_x= s.last_mouse_x, last_mouse_y= s.last_mouse_y,
    last_time= s.last_time, q= s.q
  })
end

// --- Pan ve Çizim Ayrımı (Flag Arguments Yasağı Çözümü) ---
fn canvas_start_pan(h: int, mx: float, my: float): void = let
  val s = cget(h)
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= s.layer,
    cam_x= s.cam_x, cam_y= s.cam_y, zoom= s.zoom,
    last_mouse_x= mx, last_mouse_y= my,
    last_time= s.last_time, q= s.q
  })
end

fn canvas_start_stroke(h: int, mx: float, my: float, btn: int, pressure: float): void = let
  val s = cget(h)
  val cur_zoom = s.zoom
  val wx = f_div(f_sub(mx, s.cam_x), cur_zoom)
  val wy = f_div(f_sub(my, s.cam_y), cur_zoom)
  val () = stroke_queue_teleport(s.brush, s.surf, wx, wy)
  val () = stroke_queue_free(s.q)
  val () = glsurface_set_erasing(s.surf, if btn = 3 then 1 else 0)
  val eff_pressure = if pressure > 0.0f then pressure else 0.8f
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= s.layer,
    cam_x= s.cam_x, cam_y= s.cam_y, zoom= s.zoom,
    last_mouse_x= s.last_mouse_x, last_mouse_y= s.last_mouse_y,
    last_time= get_time_seconds(), q= stroke_queue_start(wx, wy, eff_pressure)
  })
end

extern fun canvas_on_mouse_down(
  h: int, mx: float, my: float, btn: int, is_pan: int, pressure: float
): void = "ext#canvas_on_mouse_down"
implement canvas_on_mouse_down(h, mx, my, btn, is_pan, pressure) =
  if is_pan > 0 || btn = 2 then canvas_start_pan(h, mx, my)
  else canvas_start_stroke(h, mx, my, btn, pressure)

fn canvas_drag_pan(h: int, mx: float, my: float): void = let
  val s = cget(h)
  val dx = f_sub(mx, s.last_mouse_x)
  val dy = f_sub(my, s.last_mouse_y)
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= s.layer,
    cam_x= f_add(s.cam_x, dx), cam_y= f_add(s.cam_y, dy), zoom= s.zoom,
    last_mouse_x= mx, last_mouse_y= my,
    last_time= s.last_time, q= s.q
  })
end

fn canvas_drag_stroke(h: int, mx: float, my: float, pressure: float): void = let
  val s = cget(h)
  val cur_zoom = s.zoom
  val wx = f_div(f_sub(mx, s.cam_x), cur_zoom)
  val wy = f_div(f_sub(my, s.cam_y), cur_zoom)
  val cur_time = get_time_seconds()
  val elapsed = cur_time - s.last_time
  val eff_pressure = if pressure > 0.0f then pressure else 0.8f
  val nq = stroke_queue_step(
    s.layer, s.brush, s.surf, s.zoom, s.q, wx, wy, eff_pressure, elapsed
  )
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= s.layer,
    cam_x= s.cam_x, cam_y= s.cam_y, zoom= s.zoom,
    last_mouse_x= s.last_mouse_x, last_mouse_y= s.last_mouse_y,
    last_time= s.last_time, q= nq
  })
end

extern fun canvas_on_mouse_move(
  h: int, mx: float, my: float, btn: int, is_pan: int, pressure: float
): void = "ext#canvas_on_mouse_move"
implement canvas_on_mouse_move(h, mx, my, btn, is_pan, pressure) =
  if is_pan > 0 || btn = 2 then canvas_drag_pan(h, mx, my)
  else if btn = 1 || btn = 3 then canvas_drag_stroke(h, mx, my, pressure)
  else ()

fn canvas_finish_stroke(h: int): void = let
  val s = cget(h)
  val () = stroke_queue_finish(s.layer, s.brush, s.surf, s.zoom, s.q)
  val () = minepaint_brush_reset(s.brush)
  val () = glsurface_set_erasing(s.surf, 0)
in
  cput(h, @{
    brush= s.brush, surf= s.surf, layer= s.layer,
    cam_x= s.cam_x, cam_y= s.cam_y, zoom= s.zoom,
    last_mouse_x= s.last_mouse_x, last_mouse_y= s.last_mouse_y,
    last_time= s.last_time, q= ~1
  })
end

extern fun canvas_on_mouse_up(h: int, mx: float, my: float, btn: int, is_pan: int): void = "ext#canvas_on_mouse_up"
implement canvas_on_mouse_up(h, mx, my, btn, is_pan) =
  if is_pan > 0 || btn = 2 then ()
  else canvas_finish_stroke(h)

// --- Renk ve Fırça Ayarları ---
extern fun canvas_set_brush_color(h: int, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
implement canvas_set_brush_color(ch, r, g, b) = let
  val @(hue, sat, vv) = rgb_to_hsv(r, g, b)
  val st = cget(ch)
in
  if st.brush >= 0 then {
    val () = minepaint_brush_set_base_value(st.brush, SetColorH(), hue)
    val () = minepaint_brush_set_base_value(st.brush, SetColorS(), sat)
    val () = minepaint_brush_set_base_value(st.brush, SetColorV(), vv)
  } else ()
end

extern fun canvas_set_brush_setting(h: int, id: int, v: float): void = "ext#canvas_set_brush_setting"
implement canvas_set_brush_setting(h, id, v) = let
  val st = cget(h)
in
  if st.brush >= 0 then minepaint_brush_set_base_value(st.brush, setting_of(id), v) else ()
end

extern fun canvas_apply_startup(h: int): void = "ext#canvas_apply_startup"
implement canvas_apply_startup(h) = let
  val st = cget(h)
in
  if st.brush >= 0 then minepaint_brush_apply_startup(st.brush) else ()
end

extern fun canvas_apply_catalog_brush(h: int, g: BrushGroup, i: int): void = "ext#canvas_apply_catalog_brush"
implement canvas_apply_catalog_brush(h, g, i) = let
  val st = cget(h)
in
  if st.brush >= 0 then catalog_apply_brush(st.brush, g, i) else ()
end

extern fun canvas_get_brush_setting(h: int, id: int): float = "ext#canvas_get_brush_setting"
implement canvas_get_brush_setting(h, id) = let
  val st = cget(h)
in
  if st.brush >= 0 then minepaint_brush_get_base_value(st.brush, setting_of(id)) else 0.0f
end

extern fun canvas_state_create(brush: int): int = "ext#canvas_state_create"
implement canvas_state_create(brush) = let
  val surf = glsurface_create()
in
  canvas_alloc(@{
    brush= brush, surf= surf, layer= layer_none(),
    cam_x= 0.0f, cam_y= 0.0f, zoom= 1.0f,
    last_mouse_x= 0.0f, last_mouse_y= 0.0f,
    last_time= 0.0, q= ~1
  })
end
