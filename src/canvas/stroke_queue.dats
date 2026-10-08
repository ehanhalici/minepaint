// src/canvas/stroke_queue.dats
// The spline window is an integer handle into a node arena.
// main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "canvas/gl_surface.dats"

#define MINEPAINT_BRUSH_SETTING_SLOW_TRACKING 31

extern fun minepaint_brush_stroke_to(
  brush: int, surf: ptr,
  x: float, y: float, pressure: float,
  xtilt: float, ytilt: float, dtime: double,
  viewzoom: float, viewrotation: float, barrel_rotation: float, dir: int
): int = "ext#minepaint_brush_stroke_to"
extern fun minepaint_brush_reset(brush: int): void = "ext#minepaint_brush_reset"
extern fun minepaint_brush_new_stroke(brush: int): void = "ext#minepaint_brush_new_stroke"
extern fun minepaint_brush_set_base_value(brush: int, setting: int, value: float): void = "ext#minepaint_brush_set_base_value"
extern fun minepaint_brush_get_base_value(brush: int, setting: int): float = "ext#minepaint_brush_get_base_value"

extern fun sqrtf(x: float): float = "mac#"
extern fun powf(x: float, y: float): float = "mac#"

fn f2i(f: float): int = g0float2int_float_int(f)
fn i2f(i: int): float = g0int2float_int_float(i)
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)

#define STROKE_NONE (~1)
#define STROKE_CAP 2048

typedef input_point = @{ x= float, y= float, pressure= float, time= double }

val g_alive = arrayref_make_elt<bool>(i2sz(STROKE_CAP), false)
val g_x = arrayref_make_elt<float>(i2sz(STROKE_CAP), 0.0f)
val g_y = arrayref_make_elt<float>(i2sz(STROKE_CAP), 0.0f)
val g_p = arrayref_make_elt<float>(i2sz(STROKE_CAP), 0.0f)
val g_t = arrayref_make_elt<double>(i2sz(STROKE_CAP), 0.0)
val g_next = arrayref_make_elt<int>(i2sz(STROKE_CAP), STROKE_NONE)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(STROKE_CAP), 0)

fn in_cap(h: int): bool = (g1ofg0(h) >= 0) * (g1ofg0(h) < STROKE_CAP)

fn x_get(h: int): float = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_x[i] else 0.0f end
fn y_get(h: int): float = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_y[i] else 0.0f end
fn p_get(h: int): float = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_p[i] else 0.0f end
fn t_get(h: int): double = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_t[i] else 0.0 end
fn next_get(h: int): int = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_next[i] else STROKE_NONE end

fn x_set(h: int, v: float): void = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_x[i] := v else () end
fn y_set(h: int, v: float): void = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_y[i] := v else () end
fn p_set(h: int, v: float): void = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_p[i] := v else () end
fn t_set(h: int, v: double): void = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_t[i] := v else () end
fn next_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_next[i] := v else () end
fn alive_set(h: int, v: bool): void = let
  val i = g1ofg0(h)
in if (i >= 0) * (i < STROKE_CAP) then g_alive[i] := v else () end

fn alloc_node(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val i = g1ofg0(n)
  in if (i >= 0) * (i < STROKE_CAP) then g_free[i] else STROKE_NONE end
  else let
    val n = !g_fresh
  in if n < STROKE_CAP then (!g_fresh := n + 1; n) else STROKE_NONE end

fn recycle_node(h: int): void = let
  val n = !g_nfree
  val i = g1ofg0(n)
  val () = if (i >= 0) * (i < STROKE_CAP) then g_free[i] := h
  val () = alive_set(h, false)
  val () = next_set(h, STROKE_NONE)
  val () = if in_cap(h) then !g_nfree := n + 1
in () end

fn point_of(h: int): input_point =
  @{ x= x_get(h), y= y_get(h), pressure= p_get(h), time= t_get(h) }

fn make_node(pt: input_point, nxt: int): int = let
  val h = alloc_node()
  val () = assertloc(h >= 0)
  val () = x_set(h, pt.x)
  val () = y_set(h, pt.y)
  val () = p_set(h, pt.pressure)
  val () = t_set(h, pt.time)
  val () = next_set(h, nxt)
  val () = alive_set(h, true)
in h end

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

fun free_queue(h: int): void =
  if h >= 0 then let
    val nxt = next_get(h)
    val () = recycle_node(h)
  in
    free_queue(nxt)
  end else ()

fun push_queue(h: int, pt: input_point): int =
  if h < 0 then make_node(pt, STROKE_NONE)
  else if next_get(h) < 0 then let
    val () = next_set(h, make_node(pt, STROKE_NONE))
  in
    h
  end else let
    val _ = push_queue(next_get(h), pt)
  in
    h
  end

// --- Motora Çizim Gönderme ---
fun send_stroke_to_engine(
  layer: ptr, brush: int, surf: ptr, zoom: float,
  x: float, y: float, pressure: float, dtime: double
): void = let
  val () = if layer != the_null_ptr then let
    val () = mygl_surface_set_layer(surf, layer)
    val _ = minepaint_brush_stroke_to(brush, surf, x, y, pressure, 0.0f, 0.0f, dtime, zoom, 0.0f, 0.0f, 0)
  in () end
in () end

fn calc_step_count(dt_f: float, p1: input_point, p2: input_point): @(int, double) = let
  val dx = f_sub(p2.x, p1.x)
  val dy = f_sub(p2.y, p1.y)
  val dist = sqrtf(f_add(powf(dx, 2.0f), powf(dy, 2.0f)))
  val steps_t = f2i(f_div(dt_f, 0.01f))
  val steps_d = f2i(f_div(dist, 1.0f))
  val steps_candidate = max(steps_t, steps_d)
  val steps = max(1, min(100, steps_candidate))
  val sub_dtime_f = f_div(dt_f, i2f(steps))
in
  @(steps, g0float2float_float_double(sub_dtime_f))
end

fun emit_spline_steps(
  layer: ptr, brush: int, surf: ptr, zoom: float,
  p0: input_point, p1: input_point, p2: input_point, p3: input_point,
  steps: int, sub_dtime: double, i: int
): void =
  if i <= steps then let
    val t = f_div(i2f(i), i2f(steps))
    val p = interpolate_cubic(t, p0, p1, p2, p3)
    val () = send_stroke_to_engine(layer, brush, surf, zoom, p.x, p.y, p.pressure, sub_dtime)
  in
    emit_spline_steps(layer, brush, surf, zoom, p0, p1, p2, p3, steps, sub_dtime, i + 1)
  end else ()

// --- Spline Kuyruğunu İşleme ---
fun process_queue(
  layer: ptr, brush: int, surf: ptr, zoom: float,
  h: int, force_finish: bool
): int = let
  val p1 = next_get(h)
  val p2 = next_get(p1)
  val p3 = next_get(p2)
in
  if (h >= 0) * (p1 >= 0) * (p2 >= 0) * (p3 >= 0) then let
    val p0v = point_of(h)
    val p1v = point_of(p1)
    val p2v = point_of(p2)
    val p3v = point_of(p3)
    val total_dtime_raw = p2v.time - p1v.time
    val total_dtime = if total_dtime_raw <= 0.0001 then 0.0001 else total_dtime_raw
    val dt_f = g0float2float_double_float(total_dtime)
    val @(steps, sub_dtime) = calc_step_count(dt_f, p1v, p2v)
    val () = emit_spline_steps(layer, brush, surf, zoom, p0v, p1v, p2v, p3v, steps, sub_dtime, 1)
    val () = recycle_node(h)
  in
    process_queue(layer, brush, surf, zoom, p1, force_finish)
  end else if force_finish then (free_queue(h); STROKE_NONE) else h
end

// --- Dışa Aktarılan Stroke Queue API'si ---
extern fun stroke_queue_teleport(brush: int, surf: ptr, x: float, y: float): void = "ext#stroke_queue_teleport"
implement stroke_queue_teleport(brush, surf, x, y) = let
  val saved_tracking = minepaint_brush_get_base_value(brush, MINEPAINT_BRUSH_SETTING_SLOW_TRACKING)
  val () = minepaint_brush_set_base_value(brush, MINEPAINT_BRUSH_SETTING_SLOW_TRACKING, 0.0f)
  val () = minepaint_brush_reset(brush)
  val _ = minepaint_brush_stroke_to(brush, surf, x, y, 0.0f, 0.0f, 0.0f, 0.0, 1.0f, 0.0f, 0.0f, 0)
  val () = minepaint_brush_new_stroke(brush)
  val () = minepaint_brush_set_base_value(brush, MINEPAINT_BRUSH_SETTING_SLOW_TRACKING, saved_tracking)
in () end

extern fun stroke_queue_start(wx: float, wy: float, pressure: float): int = "ext#stroke_queue_start"
implement stroke_queue_start(wx, wy, pressure) =
  make_node(@{ x= wx, y= wy, pressure= pressure, time= 0.0 }, STROKE_NONE)

extern fun stroke_queue_step(
  layer: ptr, brush: int, surf: ptr, zoom: float,
  qh: int, wx: float, wy: float, pressure: float, elapsed: double
): int = "ext#stroke_queue_step"
implement stroke_queue_step(layer, brush, surf, zoom, qh, wx, wy, pressure, elapsed) = let
  val pt = @{ x= wx, y= wy, pressure= pressure, time= elapsed }
  val q1 = push_queue(qh, pt)
in
  process_queue(layer, brush, surf, zoom, q1, false)
end

extern fun stroke_queue_finish(
  layer: ptr, brush: int, surf: ptr, zoom: float, qh: int
): void = "ext#stroke_queue_finish"
implement stroke_queue_finish(layer, brush, surf, zoom, qh) = let
  val q1 = process_queue(layer, brush, surf, zoom, qh, true)
in
  free_queue(q1)
end

extern fun stroke_queue_free(qh: int): void = "ext#stroke_queue_free"
implement stroke_queue_free(qh) = free_queue(qh)
