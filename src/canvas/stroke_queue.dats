#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "canvas/gl_surface.dats"
staload "draw_engine/settings.dats"
staload "draw_engine/draw_engine.dats"

#define MINEPAINT_BRUSH_SETTING_SLOW_TRACKING 31

extern fun minepaint_brush_stroke_to(
  brush: ptr, surf: ptr,
  x: float, y: float, pressure: float,
  xtilt: float, ytilt: float, dtime: double,
  viewzoom: float, viewrotation: float, barrel_rotation: float, dir: int
): int = "ext#minepaint_brush_stroke_to"
extern fun minepaint_brush_reset(brush: ptr): void = "ext#minepaint_brush_reset"
extern fun minepaint_brush_new_stroke(brush: ptr): void = "ext#minepaint_brush_new_stroke"
extern fun minepaint_brush_set_base_value(brush: ptr, setting: int, value: float): void = "ext#minepaint_brush_set_base_value"
extern fun minepaint_brush_get_base_value(brush: ptr, setting: int): float = "ext#minepaint_brush_get_base_value"

extern fun sqrtf(x: float): float = "mac#"
extern fun powf(x: float, y: float): float = "mac#"

fn f2i(f: float): int = g0float2int_float_int(f)
fn i2f(i: int): float = g0int2float_int_float(i)
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)

// --- Nokta ve Kuyruk Veri Yapıları ---
vtypedef input_point = @{ x= float, y= float, pressure= float, time= double }

datavtype point_queue =
  | QueueNil of ()
  | QueueCons of (input_point, point_queue)

// --- Pür ATS2 ile Kübik Enterpolasyon ---
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

// --- Motora Çizim Gönderme ---
fun send_stroke_to_engine(
  layer: ptr, brush: ptr, surf: ptr, zoom: float,
  x: float, y: float, pressure: float, dtime: double
): void = let
  val () = if layer != the_null_ptr then let
    val () = mygl_surface_set_layer(surf, layer)
    val _ = minepaint_brush_stroke_to(brush, surf, x, y, pressure, 0.0f, 0.0f, dtime, zoom, 0.0f, 0.0f, 0)
  in () end
in () end

// --- Spline Kuyruğunu İşleme ---
fun process_queue(
  layer: ptr, brush: ptr, surf: ptr, zoom: float,
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
          val () = send_stroke_to_engine(layer, brush, surf, zoom, p.x, p.y, p.pressure, sub_dtime)
        in stroke_loop(i + 1) end else ()

      val () = stroke_loop(1)
      val nq = QueueCons(p1, QueueCons(p2, QueueCons(p3, tail)))
    in
      process_queue(layer, brush, surf, zoom, nq, force_finish)
    end
  | _ =>
    if force_finish then let
      val () = free_queue(queue)
    in QueueNil() end
    else queue

// --- Dışa Aktarılan Stroke Queue API'si ---

// Fırçayı çizgisiz ışınlama
extern fun stroke_queue_teleport(brush: ptr, surf: ptr, x: float, y: float): void = "ext#stroke_queue_teleport"
implement stroke_queue_teleport(brush, surf, x, y) = let
  val saved_tracking = minepaint_brush_get_base_value(brush, MINEPAINT_BRUSH_SETTING_SLOW_TRACKING)
  val () = minepaint_brush_set_base_value(brush, MINEPAINT_BRUSH_SETTING_SLOW_TRACKING, 0.0f)
  val () = minepaint_brush_reset(brush)
  val _ = minepaint_brush_stroke_to(brush, surf, x, y, 0.0f, 0.0f, 0.0f, 0.0, 1.0f, 0.0f, 0.0f, 0)
  val () = minepaint_brush_new_stroke(brush)
  val () = minepaint_brush_set_base_value(brush, MINEPAINT_BRUSH_SETTING_SLOW_TRACKING, saved_tracking)
in () end

// Yeni bir çizgi başlatma
extern fun stroke_queue_start(wx: float, wy: float, pressure: float): ptr = "ext#stroke_queue_start"
implement stroke_queue_start(wx, wy, pressure) = let
  val p0 = @{ x= wx, y= wy, pressure= pressure, time= 0.0 }
  val nq = QueueCons(p0, QueueNil())
in
  $UN.castvwtp0{ptr}(nq)
end

// Çizgiyi uzatma ve enterpole ederek motora gönderme
extern fun stroke_queue_step(
  layer: ptr, brush: ptr, surf: ptr, zoom: float,
  q_ptr: ptr, wx: float, wy: float, pressure: float, elapsed: double
): ptr = "ext#stroke_queue_step"
implement stroke_queue_step(layer, brush, surf, zoom, q_ptr, wx, wy, pressure, elapsed) = let
  val q = $UN.castvwtp0{point_queue}(q_ptr)
  val pt = @{ x= wx, y= wy, pressure= pressure, time= elapsed }
  val q1 = push_queue(q, pt)
  val q2 = process_queue(layer, brush, surf, zoom, q1, false)
in
  $UN.castvwtp0{ptr}(q2)
end

// Çizgiyi sonlandırma
extern fun stroke_queue_finish(
  layer: ptr, brush: ptr, surf: ptr, zoom: float, q_ptr: ptr
): void = "ext#stroke_queue_finish"
implement stroke_queue_finish(layer, brush, surf, zoom, q_ptr) = let
  val q = $UN.castvwtp0{point_queue}(q_ptr)
  val q1 = process_queue(layer, brush, surf, zoom, q, true)
  val () = free_queue(q1)
in () end

// Kuyruk belleğini serbest bırakma
extern fun stroke_queue_free(q_ptr: ptr): void = "ext#stroke_queue_free"
implement stroke_queue_free(q_ptr) = let
  val q = $UN.castvwtp0{point_queue}(q_ptr)
in
  free_queue(q)
end
