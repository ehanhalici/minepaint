// src/MyCanvas.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "./MyGLSurface.dats"
staload "./Layer.dats"

// --- Harici C Kütüphaneleri ve Tipler (Sadece bağımlılık bağlantısı) ---
%{^
#include <GL/gl.h>
#include <mypaint-brush.h>
#include <mypaint-surface.h>
#include <math.h>
#include <stdlib.h>

typedef struct {
  void* win;
  void* brush;
  void* surf;
  void* layer;
  float cam_x;
  float cam_y;
  float zoom;
  int last_mouse_x;
  int last_mouse_y;
  double last_time;
  void* q;
} canvas_state_record;

extern int fltk_event_x(void);
extern int fltk_event_y(void);
extern int fltk_event_button(void);
extern int fltk_event_dy(void);
extern int fltk_event_dx(void);
extern int fltk_window_pixel_w(void* win);
extern int fltk_window_pixel_h(void* win);
extern int fltk_event_mousewheel(void);
extern int fltk_event_push(void);
extern int fltk_event_release(void);
extern int fltk_event_drag(void);
extern int fltk_event_is_panning(void);
extern double ats_get_current_time(void);
extern void fltk_make_current(void* win);
extern void fltk_canvas_redraw(void* win);

#define my_f2i(x) ((int)(x))
#define my_i2f(x) ((float)(x))
#define my_flt(a, b) ((a) < (b))
#define my_fgt(a, b) ((a) > (b))
#define my_fgte(a, b) ((a) >= (b))
#define my_fadd(a, b) ((a) + (b))
#define my_fsub(a, b) ((a) - (b))
#define my_fmul(a, b) ((a) * (b))
#define my_fdiv(a, b) ((a) / (b))
%}

typedef canvas_state_record = $extype_struct"canvas_state_record" of {
  win= ptr,
  brush= ptr,
  surf= ptr,
  layer= ptr,
  cam_x= float,
  cam_y= float,
  zoom= float,
  last_mouse_x= int,
  last_mouse_y= int,
  last_time= double,
  q= ptr
}

// OpenGL ve Fırça Sabitleri
macdef GL_PROJECTION = $extval(int, "GL_PROJECTION")
macdef GL_MODELVIEW = $extval(int, "GL_MODELVIEW")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "GL_COLOR_BUFFER_BIT")

macdef MYPAINT_BRUSH_SETTING_OPAQUE = $extval(int, "MYPAINT_BRUSH_SETTING_OPAQUE")
macdef MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC = $extval(int, "MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC")
macdef MYPAINT_BRUSH_SETTING_HARDNESS = $extval(int, "MYPAINT_BRUSH_SETTING_HARDNESS")
macdef MYPAINT_BRUSH_SETTING_SLOW_TRACKING = $extval(int, "MYPAINT_BRUSH_SETTING_SLOW_TRACKING")
macdef MYPAINT_BRUSH_SETTING_COLOR_H = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_H")
macdef MYPAINT_BRUSH_SETTING_COLOR_S = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_S")
macdef MYPAINT_BRUSH_SETTING_COLOR_V = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_V")

// C Bağımlılık Fonksiyon İmzaları
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

extern fun mypaint_brush_stroke_to(
  brush: ptr, surf: ptr, 
  x: float, y: float, pressure: float, 
  xtilt: float, ytilt: float, dtime: double, 
  viewzoom: float, viewrotation: float, barrel_rotation: float, dir: int
): int = "mac#"
extern fun mypaint_brush_reset(brush: ptr): void = "mac#"
extern fun mypaint_brush_new_stroke(brush: ptr): void = "mac#"
extern fun mypaint_brush_set_base_value(brush: ptr, setting: int, value: float): void = "mac#"
extern fun mypaint_brush_get_base_value(brush: ptr, setting: int): float = "mac#"

extern fun fltk_canvas_redraw(win: ptr): void = "mac#"
extern fun fltk_make_current(win: ptr): void = "mac#"
extern fun fltk_event_x(): int = "mac#"
extern fun fltk_event_y(): int = "mac#"
extern fun fltk_event_button(): int = "mac#"
extern fun fltk_event_dy(): int = "mac#"
extern fun fltk_event_dx(): int = "mac#"
extern fun fltk_window_pixel_w(win: ptr): int = "mac#"
extern fun fltk_window_pixel_h(win: ptr): int = "mac#"
extern fun fltk_event_mousewheel(): int = "mac#"
extern fun fltk_event_push(): int = "mac#"
extern fun fltk_event_release(): int = "mac#"
extern fun fltk_event_drag(): int = "mac#"
extern fun fltk_event_is_panning(): int = "mac#"
extern fun ats_get_current_time(): double = "mac#"

extern fun sqrtf(x: float): float = "mac#"
extern fun powf(x: float, y: float): float = "mac#"

extern fun f2i(f: float): int = "mac#my_f2i"
extern fun i2f(i: int): float = "mac#my_i2f"
extern fun f_lt(a: float, b: float): bool = "mac#my_flt"
extern fun f_gt(a: float, b: float): bool = "mac#my_fgt"
extern fun f_gte(a: float, b: float): bool = "mac#my_fgte"
extern fun f_add(a: float, b: float): float = "mac#my_fadd"
extern fun f_sub(a: float, b: float): float = "mac#my_fsub"
extern fun f_mul(a: float, b: float): float = "mac#my_fmul"
extern fun f_div(a: float, b: float): float = "mac#my_fdiv"

// --- Nokta ve Kuyruk Veri Yapıları ---
vtypedef input_point = @{ x= float, y= float, pressure= float, time= double }

datavtype point_queue =
  | QueueNil of ()
  | QueueCons of (input_point, point_queue)

// --- Pür ATS2 ile RGB -> HSV Dönüşümü ---
fun rgb_to_hsv(r: float, g: float, b: float): @(float, float, float) = let
  val max_rg = if f_gt(r, g) then r else g
  val max_val = if f_gt(max_rg, b) then max_rg else b
  val min_rg = if f_lt(r, g) then r else g
  val min_val = if f_lt(min_rg, b) then min_rg else b
  val delta = f_sub(max_val, min_val)
  val v = max_val
in
  if f_lt(delta, 0.00001f) then
    @(0.0f, 0.0f, v)
  else let
    val s = if f_gt(max_val, 0.0f) then f_div(delta, max_val) else 0.0f
    val h_val =
      if f_gte(r, max_val) then f_div(f_sub(g, b), delta)
      else if f_gte(g, max_val) then f_add(2.0f, f_div(f_sub(b, r), delta))
      else f_add(4.0f, f_div(f_sub(r, g), delta))
    val h_deg = f_mul(h_val, 60.0f)
    val h_norm = if f_lt(h_deg, 0.0f) then f_add(h_deg, 360.0f) else h_deg
    val h = f_div(h_norm, 360.0f)
  in
    @(h, s, v)
  end
end

// --- Pür ATS2 ile Kübik Enterpolasyon (MyCanvas.cpp :: interpolate_cubic) ---
fun interpolate_cubic(t: float, p0: input_point, p1: input_point, p2: input_point, p3: input_point): input_point = let
  val t2 = f_mul(t, t)
  val t3 = f_mul(t2, t)
  fun solve(v0: float, v1: float, v2: float, v3: float): float =
    f_mul(
      0.5f,
      f_add(
        f_mul(2.0f, v1),
        f_add(
          f_mul(f_add(f_sub(0.0f, v0), v2), t),
          f_add(
            f_mul(f_add(f_sub(f_mul(2.0f, v0), f_mul(5.0f, v1)), f_sub(f_mul(4.0f, v2), v3)), t2),
            f_mul(f_add(f_sub(0.0f, v0), f_sub(f_mul(3.0f, v1), f_sub(f_mul(3.0f, v2), v3))), t3)
          )
        )
      )
    )
  val res_x = solve(p0.x, p1.x, p2.x, p3.x)
  val res_y = solve(p0.y, p1.y, p2.y, p3.y)
  val res_p = f_add(p1.pressure, f_mul(f_sub(p2.pressure, p1.pressure), t))
  val res_t = p1.time + (p2.time - p1.time) * g0float2float_float_double(t)
in
  @{ x= res_x, y= res_y, pressure= res_p, time= res_t }
end

// Kuyruk Bellek Yönetimi
fun free_queue(q: point_queue): void =
  case+ q of
  | ~QueueNil() => ()
  | ~QueueCons(_, tail) => free_queue(tail)

fun push_queue(q: point_queue, pt: input_point): point_queue =
  case+ q of
  | ~QueueNil() => QueueCons(pt, QueueNil())
  | ~QueueCons(p, tail) => QueueCons(p, push_queue(tail, pt))

// --- Fırçayı Çizgisiz Işınlama (MyCanvas.cpp :: teleport_brush) ---
fun teleport_brush(brush: ptr, surf: ptr, x: float, y: float): void = let
  val saved_tracking = mypaint_brush_get_base_value(brush, MYPAINT_BRUSH_SETTING_SLOW_TRACKING)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 0.0f)
  val () = mypaint_brush_reset(brush)
  val _ = mypaint_brush_stroke_to(brush, surf, x, y, 0.0f, 0.0f, 0.0f, 0.0, 1.0f, 0.0f, 0.0f, 0)
  val () = mypaint_brush_new_stroke(brush)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_SLOW_TRACKING, saved_tracking)
in () end

// --- Motora Çizim Gönderme (Sonsuz Tiled Canvas'a Doğrudan Çizim) ---
fun send_stroke_to_engine(
  win: ptr, layer: ptr, brush: ptr, surf: ptr, zoom: float,
  x: float, y: float, pressure: float, dtime: double
): void = let
  val () = if layer != the_null_ptr then let
    val () = fltk_make_current(win)
    val () = mygl_surface_set_layer(surf, layer)
    val _ = mypaint_brush_stroke_to(brush, surf, x, y, pressure, 0.0f, 0.0f, dtime, zoom, 0.0f, 0.0f, 0)
  in () end
in () end

// --- Spline Kuyruğunu İşleme ---
fun process_queue(
  win: ptr, layer: ptr, brush: ptr, surf: ptr, zoom: float,
  queue: point_queue, force_finish: bool
): point_queue =
  case+ queue of
  | ~QueueCons(p0, ~QueueCons(p1, ~QueueCons(p2, ~QueueCons(p3, tail)))) => let
      val total_dtime_raw = p2.time - p1.time
      val total_dtime: double = if total_dtime_raw <= 0.0001 then 0.0001 else total_dtime_raw
      val dx = f_sub(p2.x, p1.x)
      val dy = f_sub(p2.y, p1.y)
      val dist = sqrtf(f_add(powf(dx, 2.0f), powf(dy, 2.0f)))

      val dt_f = g0float2float_double_float(total_dtime)
      val steps_t: int = f2i(f_div(dt_f, 0.01f))
      val steps_d: int = f2i(f_div(dist, 1.0f))

      val steps_candidate = max(steps_t, steps_d)
      val steps_clamped = max(1, min(100, steps_candidate))

      val sub_dtime_f = f_div(dt_f, i2f(steps_clamped))
      val sub_dtime = g0float2float_float_double(sub_dtime_f)

      fun stroke_loop(i: int): void =
        if i <= steps_clamped then let
          val t = f_div(i2f(i), i2f(steps_clamped))
          val p = interpolate_cubic(t, p0, p1, p2, p3)
          val () = send_stroke_to_engine(win, layer, brush, surf, zoom, p.x, p.y, p.pressure, sub_dtime)
        in stroke_loop(i + 1) end else ()

      val () = stroke_loop(1)
      val nq = QueueCons(p1, QueueCons(p2, QueueCons(p3, tail)))
    in
      process_queue(win, layer, brush, surf, zoom, nq, force_finish)
    end
  | _ =>
    if force_finish then let
      val () = free_queue(queue)
    in QueueNil() end
    else queue

// --- Çizim Callback'i (Sonsuz Kanvas - Sınır Çizgisi Kaldırıldı) ---
extern fun canvas_draw_callback(state_ptr: ptr): void = "mac#"
implement canvas_draw_callback(state_ptr) = let
  val s = $UN.cast{ref(canvas_state_record)}(state_ptr)
  val win_w = fltk_window_pixel_w(s->win)
  val win_h = fltk_window_pixel_h(s->win)

  val () = glViewport(0, 0, win_w, win_h)
  val () = glMatrixMode(GL_PROJECTION)
  val () = glLoadIdentity()
  val () = glOrtho(0.0, g0int2float(win_w), g0int2float(win_h), 0.0, ~1.0, 1.0)
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glLoadIdentity()

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
    val vr = f_div(f_sub(i2f(win_w), s->cam_x), cur_zoom)
    val vb = f_div(f_sub(i2f(win_h), s->cam_y), cur_zoom)
    val () = layer_draw_tiles(s->layer, vl, vt, vr, vb)
  in () end

  val () = glPopMatrix()
in () end

// --- Olay İşleme Callback'i (Fare Tekerleği Zoom + Sonsuz Pan) ---
extern fun canvas_handle_callback(p: ptr, ev: int): int = "mac#"
implement canvas_handle_callback(p, ev) = let
  val s = $UN.cast{ref(canvas_state_record)}(p)
  val start_x = i2f(fltk_event_x())
  val start_y = i2f(fltk_event_y())
  val q = $UN.castvwtp0{point_queue}(s->q)

  val ev_wheel = fltk_event_mousewheel()
  val ev_push = fltk_event_push()
  val ev_drag = fltk_event_drag()
  val ev_rel = fltk_event_release()
in
  // 1. FARE TEKERLEĞİ İLE ZOOM (Cursor merkezli kesintisiz yakınlaşma)
  if ev = ev_wheel then let
    val dy = fltk_event_dy()
    val cur_zoom = s->zoom
    val mb_x = f_div(f_sub(start_x, s->cam_x), cur_zoom)
    val mb_y = f_div(f_sub(start_y, s->cam_y), cur_zoom)

    // dy < 0 yukarı kaydırma = Yakınlaş, dy > 0 aşağı kaydırma = Uzaklaş
    val step_zoom = if dy < 0 then f_mul(cur_zoom, 1.15f) else f_mul(cur_zoom, 0.85f)
    val min_clamped = if f_lt(step_zoom, 0.02f) then 0.02f else step_zoom
    val new_zoom = if f_gt(min_clamped, 50.0f) then 50.0f else min_clamped

    val ma_x = f_div(f_sub(start_x, s->cam_x), new_zoom)
    val ma_y = f_div(f_sub(start_y, s->cam_y), new_zoom)

    // İmleç altındaki dünya noktasını sabit tutacak şekilde kamerayı güncelle
    val () = s->cam_x := f_add(s->cam_x, f_mul(f_sub(ma_x, mb_x), new_zoom))
    val () = s->cam_y := f_add(s->cam_y, f_mul(f_sub(ma_y, mb_y), new_zoom))
    val () = s->zoom := new_zoom
    val () = s->q := $UN.castvwtp0{ptr}(q)
    val () = fltk_canvas_redraw(s->win)
  in 1 end

  // 2. FARE BASMA (FL_PUSH)
  else if ev = ev_push then let
    val is_pan = (fltk_event_is_panning() > 0)
  in
    if is_pan then let // Orta tuş veya Boşluk tuşu ile Pan başlat
      val () = s->last_mouse_x := fltk_event_x()
      val () = s->last_mouse_y := fltk_event_y()
      val () = s->q := $UN.castvwtp0{ptr}(q)
    in 1 end
    else let
      val cur_zoom = s->zoom
      val wx = f_div(f_sub(start_x, s->cam_x), cur_zoom)
      val wy = f_div(f_sub(start_y, s->cam_y), cur_zoom)

      val () = teleport_brush(s->brush, s->surf, wx, wy)
      val () = free_queue(q)
      val () = s->last_time := ats_get_current_time()

      val btn = fltk_event_button()
      val is_erasing = if btn = 3 then 1 else 0 // Sağ Tuş: Silgi
      val () = glsurface_set_erasing(s->surf, is_erasing)

      val p0 = @{ x= wx, y= wy, pressure= 0.8f, time= 0.0 }
      val nq = QueueCons(p0, QueueNil())
      val () = s->q := $UN.castvwtp0{ptr}(nq)
    in 1 end
  end

  // 3. FARE SÜRÜKLEME (FL_DRAG)
  else if ev = ev_drag then let
    val is_pan = (fltk_event_is_panning() > 0)
  in
    if is_pan then let // Tuvali Sonsuz Kaydırma (Pan)
      val cur_x = fltk_event_x()
      val cur_y = fltk_event_y()
      val dx = cur_x - s->last_mouse_x
      val dy = cur_y - s->last_mouse_y
      val () = s->cam_x := f_add(s->cam_x, i2f(dx))
      val () = s->cam_y := f_add(s->cam_y, i2f(dy))
      val () = s->last_mouse_x := cur_x
      val () = s->last_mouse_y := cur_y
      val () = s->q := $UN.castvwtp0{ptr}(q)
      val () = fltk_canvas_redraw(s->win)
    in 1 end
    else let
      val cur_zoom = s->zoom
      val wx = f_div(f_sub(start_x, s->cam_x), cur_zoom)
      val wy = f_div(f_sub(start_y, s->cam_y), cur_zoom)
      val cur_time = ats_get_current_time()
      val elapsed = cur_time - s->last_time

      val pt = @{ x= wx, y= wy, pressure= 0.8f, time= elapsed }
      val q1 = push_queue(q, pt)
      val q2 = process_queue(s->win, s->layer, s->brush, s->surf, s->zoom, q1, false)
      val () = s->q := $UN.castvwtp0{ptr}(q2)
      val () = fltk_canvas_redraw(s->win)
    in 1 end
  end

  // 4. FARE BIRAKMA (FL_RELEASE)
  else if ev = ev_rel then let
    val is_pan = (fltk_event_is_panning() > 0)
  in
    if is_pan then let
      val () = s->q := $UN.castvwtp0{ptr}(q)
    in 1 end
    else let
      val q1 = process_queue(s->win, s->layer, s->brush, s->surf, s->zoom, q, true)
      val () = free_queue(q1)
      val () = s->q := $UN.castvwtp0{ptr}(QueueNil())
      val () = mypaint_brush_reset(s->brush)
      val () = glsurface_set_erasing(s->surf, 0)
      val () = fltk_canvas_redraw(s->win)
    in 1 end
  end
  else let
    val () = s->q := $UN.castvwtp0{ptr}(q)
  in 0 end
end

// --- UI ile İletişim Fonksiyonları ---
extern fun canvas_set_brush_color(p: ptr, r: float, g: float, b: float): void = "ext#"
implement canvas_set_brush_color(p, r, g, b) = let
  val @(h, s, v) = rgb_to_hsv(r, g, b)
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then let
    val () = mypaint_brush_set_base_value(st->brush, MYPAINT_BRUSH_SETTING_COLOR_H, h)
    val () = mypaint_brush_set_base_value(st->brush, MYPAINT_BRUSH_SETTING_COLOR_S, s)
    val () = mypaint_brush_set_base_value(st->brush, MYPAINT_BRUSH_SETTING_COLOR_V, v)
  in () end
in () end

extern fun canvas_set_brush_setting(p: ptr, id: int, v: float): void = "ext#"
implement canvas_set_brush_setting(p, id, v) = let
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then
    mypaint_brush_set_base_value(st->brush, id, v)
  else ()
in () end

// --- Canvas Durum Oluşturucu ---
extern fun canvas_state_create(win: ptr, brush: ptr): ptr = "ext#"
implement canvas_state_create(win, brush) = let
  val surf_linear = glsurface_create()
  val surf_ptr = $UN.castvwtp0{ptr}(surf_linear)

  val state = $UN.cast{ref(canvas_state_record)}(malloc($extval(size_t, "sizeof(canvas_state_record)")))
  val () = state->win := win
  val () = state->brush := brush
  val () = state->surf := surf_ptr
  val () = state->layer := the_null_ptr
  val () = state->cam_x := 0.0f
  val () = state->cam_y := 0.0f
  val () = state->zoom := 1.0f
  val () = state->last_mouse_x := 0
  val () = state->last_mouse_y := 0
  val () = state->last_time := 0.0
  val () = state->q := $UN.castvwtp0{ptr}(QueueNil())
in
  $UN.cast{ptr}(state)
end
