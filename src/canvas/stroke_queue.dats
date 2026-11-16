// src/canvas/stroke_queue.dats
// The spline window is an integer handle into a node arena.
// main.dats initialises this file at startup.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "sys/airlock.hats"
#include "sys/arena.hats"
staload "gl/gl_io.sats"
staload "draw_engine/setting_id.sats"
staload "draw_engine/surface_target.sats"
staload "canvas/layer_box.sats"
staload "sys/libc.dats"
#include "draw_engine/brush_borrow.hats"


fn f2i(f: float): int = g0float2int_float_int(f)
fn i2f(i: int): float = g0int2float_int_float(i)
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)

#define STROKE_NONE (~1)
#define STROKE_CAP 2048

typedef input_point = @{ x= float, y= float, pressure= float, time= double }

// E.3: arenalar `arrayref(a, STROKE_CAP)`; ham dugum numaralari `ix_try` ile tipli indekse cevrilir.
// Gecersiz numara politikasi (eski airlock davranisi): okuma varsayilan deger, yazma etkisiz.
val g_alive = arrayref_make_elt<int>(i2sz(STROKE_CAP), 0)
val g_x = arrayref_make_elt<float>(i2sz(STROKE_CAP), 0.0f)
val g_y = arrayref_make_elt<float>(i2sz(STROKE_CAP), 0.0f)
val g_p = arrayref_make_elt<float>(i2sz(STROKE_CAP), 0.0f)
val g_t = arrayref_make_elt<double>(i2sz(STROKE_CAP), 0.0)
val g_next = arrayref_make_elt<int>(i2sz(STROKE_CAP), STROKE_NONE)
// Bas dugumde: kendisinden kuyruk sonuna dugum sayisi (bagli liste gezintilerinin olcusu).
val g_len = arrayref_make_elt<int>(i2sz(STROKE_CAP), 0)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(STROKE_CAP), 0)

fn node_of(h: int): @(bool, Ix(STROKE_CAP)) = ix_try(h, STROKE_CAP)

fn x_get(h: int): float = let val @(ok_, i) = node_of(h) in if ok_ then g_x[i] else 0.0f end
fn y_get(h: int): float = let val @(ok_, i) = node_of(h) in if ok_ then g_y[i] else 0.0f end
fn p_get(h: int): float = let val @(ok_, i) = node_of(h) in if ok_ then g_p[i] else 0.0f end
fn t_get(h: int): double = let val @(ok_, i) = node_of(h) in if ok_ then g_t[i] else 0.0 end
fn next_get(h: int): int = let val @(ok_, i) = node_of(h) in if ok_ then g_next[i] else STROKE_NONE end
fn len_get(h: int): int = let val @(ok_, i) = node_of(h) in if ok_ then g_len[i] else 0 end

fn x_set(h: int, v: float): void = let val @(ok_, i) = node_of(h) in if ok_ then g_x[i] := v else () end
fn y_set(h: int, v: float): void = let val @(ok_, i) = node_of(h) in if ok_ then g_y[i] := v else () end
fn p_set(h: int, v: float): void = let val @(ok_, i) = node_of(h) in if ok_ then g_p[i] := v else () end
fn t_set(h: int, v: double): void = let val @(ok_, i) = node_of(h) in if ok_ then g_t[i] := v else () end
fn len_set(h: int, v: int): void = let val @(ok_, i) = node_of(h) in if ok_ then g_len[i] := v else () end
fn next_set(h: int, v: int): void = let val @(ok_, i) = node_of(h) in if ok_ then g_next[i] := v else () end
fn alive_mark(h: int): void = let val @(ok_, i) = node_of(h) in if ok_ then g_alive[i] := 1 else () end
fn alive_clear(h: int): void = let val @(ok_, i) = node_of(h) in if ok_ then g_alive[i] := 0 else () end

fn alloc_node(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
  in
    let val @(ok_, i) = node_of(n) in if ok_ then g_free[i] else STROKE_NONE end
  end else let
    val n = !g_fresh
  in if n < STROKE_CAP then (!g_fresh := n + 1; n) else STROKE_NONE end

fn recycle_node(h: int): void = let
  val n = !g_nfree
  val () = let val @(ok_, i) = node_of(n) in if ok_ then g_free[i] := h else () end
  val () = alive_clear(h)
  val () = next_set(h, STROKE_NONE)
  val () = len_set(h, 0)
  val () = let val @(ok_, _) = node_of(h) in if ok_ then !g_nfree := n + 1 else () end
in () end

fn point_of(h: int): input_point =
  @{ x= x_get(h), y= y_get(h), pressure= p_get(h), time= t_get(h) }

fn make_node(pt: input_point, nxt: int): int = let
  val h = alloc_node()
  val () = anth_require(h >= 0)
  val () = x_set(h, pt.x)
  val () = y_set(h, pt.y)
  val () = p_set(h, pt.pressure)
  val () = t_set(h, pt.time)
  val () = next_set(h, nxt)
  val () = len_set(h, 1)
  val () = alive_mark(h)
in h end

// --- Pür ATS2 ile Kübik Enterpolasyon ---
// Catmull-Rom bir eksen: t, t^2, t^3 onceden hesaplanir.
fn catmull(t: float, t2: float, t3: float, v0: float, v1: float, v2: float, v3: float): float = let
  val c1 = f_mul(2.0f, v1)
  val c2 = f_mul(f_add(f_sub(0.0f, v0), v2), t)
  val c3 = f_mul(f_add(f_sub(f_mul(2.0f, v0), f_mul(5.0f, v1)), f_sub(f_mul(4.0f, v2), v3)), t2)
  val c4 = f_mul(f_add(f_sub(0.0f, v0), f_sub(f_mul(3.0f, v1), f_sub(f_mul(3.0f, v2), v3))), t3)
in f_mul(0.5f, f_add(c1, f_add(c2, f_add(c3, c4)))) end

fun interpolate_cubic(t: float, p0: input_point, p1: input_point, p2: input_point, p3: input_point): input_point = let
  val t2 = f_mul(t, t)
  val t3 = f_mul(t2, t)
  val res_x = catmull(t, t2, t3, p0.x, p1.x, p2.x, p3.x)
  val res_y = catmull(t, t2, t3, p0.y, p1.y, p2.y, p3.y)
  val res_p = f_add(p1.pressure, f_mul(f_sub(p2.pressure, p1.pressure), t))
  val res_t = p1.time + (p2.time - p1.time) * g0float2float_float_double(t)
in
  @{ x= res_x, y= res_y, pressure= res_p, time= res_t }
end

// Olcu n: n = bas dugumdeki uzunluk sayaci (len_get), her adim bir dugum birakilir.
fun free_nodes {n:nat} .<n>. (n: int(n), h: int): void =
  if n > 0 then let
    val nxt = next_get(h)
    val () = recycle_node(h)
  in
    free_nodes(n - 1, nxt)
  end else ()

fn free_queue_from(h: int): void =
  if h >= 0 then free_nodes(airlock_nat(len_get(h)), h) else ()

// n adim ilerleyince kuyrugun sonundaki dugume varir (olcu n).
fun walk_to_tail {n:nat} .<n>. (n: int(n), h: int): int =
  if n > 0 then walk_to_tail(n - 1, next_get(h)) else h

fn push_queue(h: int, pt: input_point): int =
  if h < 0 then make_node(pt, STROKE_NONE)
  else let
    val len = len_get(h)
    val tail = walk_to_tail(airlock_nat(len - 1), h)
    val () = next_set(tail, make_node(pt, STROKE_NONE))
    val () = len_set(h, len + 1)
  in
    h
  end
// --- Motora Çizim Gönderme ---
fun send_stroke_to_engine(gio: !GL_IO | 
  tgt: MpTarget, brush: int, zoom: float,
  x: float, y: float, pressure: float, dtime: double
): void = let
  val () = if tgt.layer >= 0 then let
    val _ = br_stroke_to(gio | brush, tgt, x, y, pressure, 0.0f, 0.0f, dtime, zoom, 0.0f, 0.0f, 0)
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

fun emit_spline_steps {st:nat}{i:nat | i <= st + 1} .<st + 1 - i>. (gio: !GL_IO | 
  tgt: MpTarget, brush: int, zoom: float,
  p0: input_point, p1: input_point, p2: input_point, p3: input_point,
  steps: int(st), sub_dtime: double, i: int(i)
): void =
  if i <= steps then let
    val t = f_div(i2f(i), i2f(steps))
    val p = interpolate_cubic(t, p0, p1, p2, p3)
    val () = send_stroke_to_engine(gio | tgt, brush, zoom, p.x, p.y, p.pressure, sub_dtime)
  in
    emit_spline_steps(gio | tgt, brush, zoom, p0, p1, p2, p3, steps, sub_dtime, i + 1)
  end else ()
// --- Spline Kuyruğunu İşleme ---
// Bir dugum cifti icin spline adimlarini cizer, basi siler.
fn process_node(gio: !GL_IO | tgt: MpTarget, brush: int, zoom: float, h: int, p1: int, p2: int, p3: int): void = let
  val p1v = point_of(p1)
  val p2v = point_of(p2)
  val total_dtime_raw = p2v.time - p1v.time
  val total_dtime = if total_dtime_raw <= 0.0001 then 0.0001 else total_dtime_raw
  val @(steps, sub_dtime) = calc_step_count(g0float2float_double_float(total_dtime), p1v, p2v)
  val () = emit_spline_steps(gio | tgt, brush, zoom, point_of(h), p1v, p2v, point_of(p3), airlock_nat(steps), sub_dtime, 1)
  val () = len_set(p1, len_get(h) - 1)
in recycle_node(h) end

// Olcu n: bas dugumun uzunluk sayaci; her adim basi bir ilerletir (uzunluk bir azalir).
fun process_queue {n:nat} .<n>. (gio: !GL_IO |
  n: int(n), tgt: MpTarget, brush: int, zoom: float,
  h: int, force_finish: bool
): int = let
  val p1 = next_get(h)
  val p2 = next_get(p1)
  val p3 = next_get(p2)
in
  if (n > 0) * (h >= 0) * (p1 >= 0) * (p2 >= 0) * (p3 >= 0) then let
    val () = process_node(gio | tgt, brush, zoom, h, p1, p2, p3)
  in
    process_queue(gio | n - 1, tgt, brush, zoom, p1, force_finish)
  end else if force_finish then (free_queue_from(h); STROKE_NONE) else h
end

fn process_from(gio: !GL_IO | tgt: MpTarget, brush: int, zoom: float, h: int, force_finish: bool): int =
  process_queue(gio | airlock_nat(len_get(h)), tgt, brush, zoom, h, force_finish)

// --- Dışa Aktarılan Stroke Queue API'si ---
extern fun stroke_queue_teleport(gio: !GL_IO | tgt: MpTarget, brush: int, x: float, y: float): void = "ext#stroke_queue_teleport"
implement stroke_queue_teleport(gio | tgt, brush, x, y) = let
  val saved_tracking = br_get_base_value(brush, SetSlowTracking())
  val () = br_set_base_value(brush, SetSlowTracking(), 0.0f)
  val () = br_reset(brush)
  val _ = br_stroke_to(gio | brush, tgt, x, y, 0.0f, 0.0f, 0.0f, 0.0, 1.0f, 0.0f, 0.0f, 0)
  val () = br_new_stroke(brush)
  val () = br_set_base_value(brush, SetSlowTracking(), saved_tracking)
in () end

extern fun stroke_queue_start(wx: float, wy: float, pressure: float): int = "ext#stroke_queue_start"
implement stroke_queue_start(wx, wy, pressure) =
  make_node(@{ x= wx, y= wy, pressure= pressure, time= 0.0 }, STROKE_NONE)

extern fun stroke_queue_step(gio: !GL_IO | 
  tgt: MpTarget, brush: int, zoom: float,
  qh: int, wx: float, wy: float, pressure: float, elapsed: double
): int = "ext#stroke_queue_step"
implement stroke_queue_step(gio | tgt, brush, zoom, qh, wx, wy, pressure, elapsed) = let
  val pt = @{ x= wx, y= wy, pressure= pressure, time= elapsed }
  val q1 = push_queue(qh, pt)
in
  process_from(gio | tgt, brush, zoom, q1, false)
end

extern fun stroke_queue_finish(gio: !GL_IO | 
  tgt: MpTarget, brush: int, zoom: float, qh: int
): void = "ext#stroke_queue_finish"
implement stroke_queue_finish(gio | tgt, brush, zoom, qh) = let
  val q1 = process_from(gio | tgt, brush, zoom, qh, true)
in
  free_queue_from(q1)
end

extern fun stroke_queue_free(qh: int): void = "ext#stroke_queue_free"
implement stroke_queue_free(qh) = free_queue_from(qh)
