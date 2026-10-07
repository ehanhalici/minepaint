// src/MyCanvas.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "ui/color.dats"
staload "canvas/stroke_queue.dats"
staload "canvas/gl_surface.dats"
staload "canvas/layer.dats"
staload "draw_engine/settings.dats"
staload "draw_engine/draw_engine.dats"

typedef canvas_state_record = @{
  brush= ptr,
  surf= ptr,
  layer= ptr,
  cam_x= float,
  cam_y= float,
  zoom= float,
  last_mouse_x= float,
  last_mouse_y= float,
  last_time= double,
  q= ptr
}

// OpenGL ve Fırça Sabitleri
macdef GL_PROJECTION = $extval(int, "GL_PROJECTION")
macdef GL_MODELVIEW = $extval(int, "GL_MODELVIEW")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "GL_COLOR_BUFFER_BIT")

#define MINEPAINT_BRUSH_SETTING_COLOR_H 34
#define MINEPAINT_BRUSH_SETTING_COLOR_S 35
#define MINEPAINT_BRUSH_SETTING_COLOR_V 36

// C Fonksiyon İmzaları
extern fun malloc(n: size_t): ptr = "mac#"
extern fun free(p: ptr): void = "mac#"
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

extern fun minepaint_brush_reset(brush: ptr): void = "ext#minepaint_brush_reset"
extern fun minepaint_brush_set_base_value(brush: ptr, setting: int, value: float): void = "ext#minepaint_brush_set_base_value"
extern fun minepaint_brush_get_base_value(brush: ptr, setting: int): float = "ext#minepaint_brush_get_base_value"

extern fun get_time_seconds(): double = "ext#get_time_seconds"
fn i2f(i: int): float = g0int2float_int_float(i)
fn f_lt(a: float, b: float): bool = a < b
fn f_gt(a: float, b: float): bool = a > b
fn f_gte(a: float, b: float): bool = a >= b
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)

// --- Canvas API İmzaları (Pencere ve UI Tarafından Çağrılır) ---
extern fun canvas_render(p: ptr, canvas_w: int, canvas_h: int): void = "ext#canvas_render"
extern fun canvas_on_wheel(p: ptr, mx: int, my: int, dy: int): void = "ext#canvas_on_wheel"
extern fun canvas_on_mouse_down(p: ptr, mx: float, my: float, btn: int, is_pan: int, pressure: float): void = "ext#canvas_on_mouse_down"
extern fun canvas_on_mouse_move(p: ptr, mx: float, my: float, btn: int, is_pan: int, pressure: float): void = "ext#canvas_on_mouse_move"
extern fun canvas_on_mouse_up(p: ptr, mx: float, my: float, btn: int, is_pan: int): void = "ext#canvas_on_mouse_up"
extern fun canvas_set_brush_color(p: ptr, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
extern fun canvas_set_brush_setting(p: ptr, id: int, v: float): void = "ext#canvas_set_brush_setting"
extern fun canvas_state_create(brush: ptr): ptr = "ext#canvas_state_create"
extern fun canvas_apply_startup(p: ptr): void = "ext#canvas_apply_startup"
extern fun canvas_apply_catalog_brush(p: ptr, g: int, i: int): void = "ext#canvas_apply_catalog_brush"
extern fun canvas_get_brush_setting(p: ptr, id: int): float = "ext#canvas_get_brush_setting"

extern fun minepaint_brush_apply_startup(b: ptr): void = "ext#minepaint_brush_apply_startup"
extern fun catalog_apply_brush(b: ptr, g: int, i: int): void = "ext#catalog_apply_brush"

// --- Çizim Render Fonksiyonu ---
implement canvas_render(state_ptr, canvas_w, canvas_h) = let
  val s = $UN.cast{ref(canvas_state_record)}(state_ptr)

  val () = glViewport(0, 0, canvas_w, canvas_h)
  val () = glMatrixMode(GL_PROJECTION)
  val () = glLoadIdentity()
  val () = glOrtho(0.0, g0int2float(canvas_w), g0int2float(canvas_h), 0.0, ~1.0, 1.0)
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glLoadIdentity()

  // Kanvas arka plan rengi
  val () = glClearColor(0.07f, 0.07f, 0.07f, 1.0f)
  val () = glClear(GL_COLOR_BUFFER_BIT)

  val () = glPushMatrix()
  val () = glTranslatef(s->cam_x, s->cam_y, 0.0f)
  val () = glScalef(s->zoom, s->zoom, 1.0f)

  val () = if s->layer = the_null_ptr then s->layer := layer_create(0, 0)
  val () = if s->layer != the_null_ptr then let
    val cur_zoom = s->zoom
    val vl = f_div(f_sub(0.0f, s->cam_x), cur_zoom)
    val vt = f_div(f_sub(0.0f, s->cam_y), cur_zoom)
    val vr = f_div(f_sub(i2f(canvas_w), s->cam_x), cur_zoom)
    val vb = f_div(f_sub(i2f(canvas_h), s->cam_y), cur_zoom)
    val () = layer_draw_tiles(s->layer, vl, vt, vr, vb, cur_zoom)
  in () end

  val () = glPopMatrix()
in () end

// --- Fare Tekerleği Zoom ---
implement canvas_on_wheel(p, mx, my, dy) = let
  val s = $UN.cast{ref(canvas_state_record)}(p)
  val start_x = i2f(mx)
  val start_y = i2f(my)
  val cur_zoom = s->zoom
  val mb_x = f_div(f_sub(start_x, s->cam_x), cur_zoom)
  val mb_y = f_div(f_sub(start_y, s->cam_y), cur_zoom)

  val step_zoom = if dy < 0 then f_mul(cur_zoom, 1.15f) else f_mul(cur_zoom, 0.85f)
  val min_clamped = if f_lt(step_zoom, 0.02f) then 0.02f else step_zoom
  val new_zoom = if f_gt(min_clamped, 50.0f) then 50.0f else min_clamped

  val ma_x = f_div(f_sub(start_x, s->cam_x), new_zoom)
  val ma_y = f_div(f_sub(start_y, s->cam_y), new_zoom)

  val () = s->cam_x := f_add(s->cam_x, f_mul(f_sub(ma_x, mb_x), new_zoom))
  val () = s->cam_y := f_add(s->cam_y, f_mul(f_sub(ma_y, mb_y), new_zoom))
  val () = s->zoom := new_zoom
in () end

// --- Stroke Queue API İmzaları ---
extern fun stroke_queue_teleport(brush: ptr, surf: ptr, x: float, y: float): void = "ext#stroke_queue_teleport"
extern fun stroke_queue_start(wx: float, wy: float, pressure: float): ptr = "ext#stroke_queue_start"
extern fun stroke_queue_step(
  layer: ptr, brush: ptr, surf: ptr, zoom: float,
  q_ptr: ptr, wx: float, wy: float, pressure: float, elapsed: double
): ptr = "ext#stroke_queue_step"
extern fun stroke_queue_finish(
  layer: ptr, brush: ptr, surf: ptr, zoom: float, q_ptr: ptr
): void = "ext#stroke_queue_finish"
extern fun stroke_queue_free(q_ptr: ptr): void = "ext#stroke_queue_free"

// --- Fare / Kalem Basma ---
implement canvas_on_mouse_down(p, mx, my, btn, is_pan, pressure) = let
  val s = $UN.cast{ref(canvas_state_record)}(p)
in
  if (is_pan > 0) || (btn = 2) then let
    val () = s->last_mouse_x := mx
    val () = s->last_mouse_y := my
  in () end
  else let
    val start_x = mx
    val start_y = my
    val cur_zoom = s->zoom
    val wx = f_div(f_sub(start_x, s->cam_x), cur_zoom)
    val wy = f_div(f_sub(start_y, s->cam_y), cur_zoom)

    val () = stroke_queue_teleport(s->brush, s->surf, wx, wy)
    val () = stroke_queue_free(s->q)
    val () = s->last_time := get_time_seconds()

    val is_erasing = if btn = 3 then 1 else 0 // Sağ tık / silgi ucu
    val () = glsurface_set_erasing(s->surf, is_erasing)

    val eff_pressure = if pressure > 0.0f then pressure else 0.8f
    val () = s->q := stroke_queue_start(wx, wy, eff_pressure)
  in () end
end

// --- Fare / Kalem Sürükleme ---
implement canvas_on_mouse_move(p, mx, my, btn, is_pan, pressure) = let
  val s = $UN.cast{ref(canvas_state_record)}(p)
in
  if (is_pan > 0) || (btn = 2) then let
    val dx = f_sub(mx, s->last_mouse_x)
    val dy = f_sub(my, s->last_mouse_y)
    val () = s->cam_x := f_add(s->cam_x, dx)
    val () = s->cam_y := f_add(s->cam_y, dy)
    val () = s->last_mouse_x := mx
    val () = s->last_mouse_y := my
  in () end
  else if (btn = 1) || (btn = 3) then let
    val start_x = mx
    val start_y = my
    val cur_zoom = s->zoom
    val wx = f_div(f_sub(start_x, s->cam_x), cur_zoom)
    val wy = f_div(f_sub(start_y, s->cam_y), cur_zoom)
    val cur_time = get_time_seconds()
    val elapsed = cur_time - s->last_time

    val eff_pressure = if pressure > 0.0f then pressure else 0.8f
    val () = s->q := stroke_queue_step(s->layer, s->brush, s->surf, s->zoom, s->q, wx, wy, eff_pressure, elapsed)
  in () end
  else ()
end

// --- Fare / Kalem Bırakma ---
implement canvas_on_mouse_up(p, mx, my, btn, is_pan) = let
  val s = $UN.cast{ref(canvas_state_record)}(p)
in
  if (is_pan > 0) || (btn = 2) then ()
  else let
    val () = stroke_queue_finish(s->layer, s->brush, s->surf, s->zoom, s->q)
    val () = s->q := the_null_ptr
    val () = minepaint_brush_reset(s->brush)
    val () = glsurface_set_erasing(s->surf, 0)
  in () end
end

// --- Renk Ayarı ---
implement canvas_set_brush_color(p, r, g, b) = let
  val @(h, s, v) = rgb_to_hsv(r, g, b)
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then let
    val () = minepaint_brush_set_base_value(st->brush, MINEPAINT_BRUSH_SETTING_COLOR_H, h)
    val () = minepaint_brush_set_base_value(st->brush, MINEPAINT_BRUSH_SETTING_COLOR_S, s)
    val () = minepaint_brush_set_base_value(st->brush, MINEPAINT_BRUSH_SETTING_COLOR_V, v)
  in () end
in () end

// --- Fırça Ayarı ---
implement canvas_set_brush_setting(p, id, v) = let
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then
    minepaint_brush_set_base_value(st->brush, id, v)
  else ()
in () end

implement canvas_apply_startup(p) = let
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then minepaint_brush_apply_startup(st->brush) else ()
in () end

implement canvas_apply_catalog_brush(p, g, i) = let
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then catalog_apply_brush(st->brush, g, i) else ()
in () end

implement canvas_get_brush_setting(p, id) = let
  val st = $UN.cast{ref(canvas_state_record)}(p)
in
  if st->brush != the_null_ptr then minepaint_brush_get_base_value(st->brush, id) else 0.0f
end

// --- Canvas Durum Oluşturucu ---
implement canvas_state_create(brush) = let
  val surf_linear = glsurface_create()
  val surf_ptr = $UN.castvwtp0{ptr}(surf_linear)

  val state = $UN.cast{ref(canvas_state_record)}(malloc(sizeof<canvas_state_record>))
  val () = state->brush := brush
  val () = state->surf := surf_ptr
  val () = state->layer := the_null_ptr
  val () = state->cam_x := 0.0f
  val () = state->cam_y := 0.0f
  val () = state->zoom := 1.0f
  val () = state->last_mouse_x := 0.0f
  val () = state->last_mouse_y := 0.0f
  val () = state->last_time := 0.0
  val () = state->q := the_null_ptr
in
  $UN.cast{ptr}(state)
end
