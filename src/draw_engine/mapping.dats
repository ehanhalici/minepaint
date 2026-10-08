// src/draw_engine/mapping.dats
// Piecewise-linear dynamics curves in a typed structure-of-arrays arena.
// A mapping is an integer handle. main.dats dynloads this file so the
// arena exists before the first call. No raw pointers and no casts.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"

#define MAPPING_CAPACITY 512
#define CURVE_CAPACITY (MAPPING_CAPACITY * MAPPING_INPUTS)
#define POINT_CAPACITY (CURVE_CAPACITY * MAPPING_CURVE_POINTS)

val g_alive = arrayref_make_elt<bool>(i2sz(MAPPING_CAPACITY), false)
val g_base = arrayref_make_elt<float>(i2sz(MAPPING_CAPACITY), 0.0f)
val g_inputs = arrayref_make_elt<int>(i2sz(MAPPING_CAPACITY), 0)
val g_used = arrayref_make_elt<int>(i2sz(MAPPING_CAPACITY), 0)
val g_n = arrayref_make_elt<int>(i2sz(CURVE_CAPACITY), 0)
val g_x = arrayref_make_elt<float>(i2sz(POINT_CAPACITY), 0.0f)
val g_y = arrayref_make_elt<float>(i2sz(POINT_CAPACITY), 0.0f)

fn curve_slot(h: int, j: int): int = h * MAPPING_INPUTS + j
fn point_slot(h: int, j: int, k: int): int =
  curve_slot(h, j) * MAPPING_CURVE_POINTS + k

fn alive_get(h: int): bool = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_alive[i] else false
end

fn alive_set(h: int, v: bool): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_alive[i] := v else ()
end

fn base_get(h: int): float = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_base[i] else 0.0f
end

fn base_set(h: int, v: float): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_base[i] := v else ()
end

fn inputs_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_inputs[i] else 0
end

fn inputs_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_inputs[i] := v else ()
end

fn used_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_used[i] else 0
end

fn used_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < MAPPING_CAPACITY) then g_used[i] := v else ()
end

fn n_get(h: int, j: int): int = let
  val i = g1ofg0(curve_slot(h, j))
in
  if (i >= 0) * (i < CURVE_CAPACITY) then g_n[i] else 0
end

fn n_set(h: int, j: int, v: int): void = let
  val i = g1ofg0(curve_slot(h, j))
in
  if (i >= 0) * (i < CURVE_CAPACITY) then g_n[i] := v else ()
end

fn x_get(h: int, j: int, k: int): float = let
  val i = g1ofg0(point_slot(h, j, k))
in
  if (i >= 0) * (i < POINT_CAPACITY) then g_x[i] else 0.0f
end

fn x_set(h: int, j: int, k: int, v: float): void = let
  val i = g1ofg0(point_slot(h, j, k))
in
  if (i >= 0) * (i < POINT_CAPACITY) then g_x[i] := v else ()
end

fn y_get(h: int, j: int, k: int): float = let
  val i = g1ofg0(point_slot(h, j, k))
in
  if (i >= 0) * (i < POINT_CAPACITY) then g_y[i] else 0.0f
end

fn y_set(h: int, j: int, k: int, v: float): void = let
  val i = g1ofg0(point_slot(h, j, k))
in
  if (i >= 0) * (i < POINT_CAPACITY) then g_y[i] := v else ()
end

fun find_free_slot(i: int): int =
  if i >= MAPPING_CAPACITY then MAPPING_NONE
  else if alive_get(i) then find_free_slot(i + 1)
  else i

// A fresh mapping matches malloc+memset: counts and coordinates start at 0.
// Tail recursion walks one curve, then the next, so a reused slot cannot
// expose the previous owner's control points.
fun clear_points(h: int, j: int, k: int): void =
  if j >= MAPPING_INPUTS then ()
  else if k >= MAPPING_CURVE_POINTS then clear_points(h, j + 1, 0)
  else let
    val () = x_set(h, j, k, 0.0f)
    val () = y_set(h, j, k, 0.0f)
  in
    clear_points(h, j, k + 1)
  end

fun clear_curves(h: int, j: int): void =
  if j < MAPPING_INPUTS then let
    val () = n_set(h, j, 0)
  in clear_curves(h, j + 1) end
  else clear_points(h, 0, 0)

extern fun minepaint_mapping_new(inputs: int): int = "ext#minepaint_mapping_new"
implement minepaint_mapping_new(inputs) = let
  val () = assertloc((inputs >= 0) && (inputs <= MAPPING_INPUTS))
  val h = find_free_slot(0)
  val () = assertloc(h >= 0)
  val () = alive_set(h, true)
  val () = base_set(h, 0.0f)
  val () = inputs_set(h, inputs)
  val () = used_set(h, 0)
  val () = clear_curves(h, 0)
in
  h
end

extern fun minepaint_mapping_free(h: int): void = "ext#minepaint_mapping_free"
implement minepaint_mapping_free(h) =
  if h >= 0 then alive_set(h, false)

extern fun minepaint_mapping_get_base_value(h: int): float = "ext#minepaint_mapping_get_base_value"
implement minepaint_mapping_get_base_value(h) = base_get(h)

extern fun minepaint_mapping_set_base_value(h: int, value: float): void = "ext#minepaint_mapping_set_base_value"
implement minepaint_mapping_set_base_value(h, value) = base_set(h, value)

fn update_used_count(h: int, old_n: int, new_n: int): void = let
  val cur_used = used_get(h)
  val updated =
    if (new_n != 0) && (old_n = 0) then cur_used + 1
    else if (new_n = 0) && (old_n != 0) then cur_used - 1
    else cur_used
in
  used_set(h, updated)
end

extern fun minepaint_mapping_set_n(h: int, input: int, n: int): void = "ext#minepaint_mapping_set_n"
implement minepaint_mapping_set_n(h, input, n) = let
  val () = assertloc((input >= 0) && (input < inputs_get(h)))
  val () = assertloc((n >= 0) && (n <= MAPPING_CURVE_POINTS) && (n != 1))
  val () = update_used_count(h, n_get(h, input), n)
in
  n_set(h, input, n)
end

extern fun minepaint_mapping_get_n(h: int, input: int): int = "ext#minepaint_mapping_get_n"
implement minepaint_mapping_get_n(h, input) = let
  val () = assertloc((input >= 0) && (input < inputs_get(h)))
in
  n_get(h, input)
end

extern fun minepaint_mapping_set_point(
  h: int, input: int, index: int, x: float, y: float
): void = "ext#minepaint_mapping_set_point"
implement minepaint_mapping_set_point(h, input, index, x, y) = let
  val () = assertloc((input >= 0) && (input < inputs_get(h)))
  val () = assertloc((index >= 0) && (index < n_get(h, input)))
  val () = x_set(h, input, index, x)
in
  y_set(h, input, index, y)
end

extern fun minepaint_mapping_get_point(
  h: int, input: int, index: int, x: &float? >> float, y: &float? >> float
): void = "ext#minepaint_mapping_get_point"
implement minepaint_mapping_get_point(h, input, index, x, y) = let
  val () = assertloc((input >= 0) && (input < inputs_get(h)))
  val () = assertloc((index >= 0) && (index < n_get(h, input)))
  val () = x := x_get(h, input, index)
in
  y := y_get(h, input, index)
end

extern fun minepaint_mapping_is_constant(h: int): bool = "ext#minepaint_mapping_is_constant"
implement minepaint_mapping_is_constant(h) = used_get(h) = 0

extern fun minepaint_mapping_get_inputs_used_n(h: int): int = "ext#minepaint_mapping_get_inputs_used_n"
implement minepaint_mapping_get_inputs_used_n(h) = used_get(h)

fn eval_segment(x: float, x0: float, y0: float, x1: float, y1: float): float =
  if (x0 = x1) || (y0 = y1) then y0
  else let
    val num = g0float_add(g0float_mul(y1, g0float_sub(x, x0)), g0float_mul(y0, g0float_sub(x1, x)))
    val den = g0float_sub(x1, x0)
  in
    g0float_div(num, den)
  end

fun find_seg(
  h: int, j: int, n: int, x: float, i: int,
  x0: float, y0: float, x1: float, y1: float
): @(float, float, float, float) =
  if (i < n) && (x > x1) then
    find_seg(h, j, n, x, i + 1, x1, y1, x_get(h, j, i), y_get(h, j, i))
  else
    @(x0, y0, x1, y1)

fn eval_curve(h: int, j: int, x: float): float = let
  val n = n_get(h, j)
in
  if n <= 0 then 0.0f
  else let
    val @(x0, y0, x1, y1) = find_seg(h, j, n, x, 2, x_get(h, j, 0), y_get(h, j, 0), x_get(h, j, 1), y_get(h, j, 1))
  in
    eval_segment(x, x0, y0, x1, y1)
  end
end

fn input_at(data: &(@[float][MAPPING_INPUTS]), j: int): float = let
  val idx = g1ofg0(j)
in
  if (idx >= 0) * (idx < MAPPING_INPUTS) then data[idx] else 0.0f
end

fun sum_inputs(
  h: int, data: &(@[float][MAPPING_INPUTS]), j: int, num_in: int, acc: float
): float =
  if j < num_in then let
    val y = eval_curve(h, j, input_at(data, j))
  in
    sum_inputs(h, data, j + 1, num_in, g0float_add(acc, y))
  end else acc

extern fun minepaint_mapping_calculate(
  h: int, data: &(@[float][MAPPING_INPUTS])
): float = "ext#minepaint_mapping_calculate"
implement minepaint_mapping_calculate(h, data) = let
  val base = base_get(h)
in
  if used_get(h) = 0 then base
  else sum_inputs(h, data, 0, inputs_get(h), base)
end

extern fun minepaint_mapping_calculate_single_input(h: int, input: float): float = "ext#minepaint_mapping_calculate_single_input"
implement minepaint_mapping_calculate_single_input(h, input) = let
  var buf: @[float][MAPPING_INPUTS] = @[float][MAPPING_INPUTS](0.0f)
  val () = buf[0] := input
in
  minepaint_mapping_calculate(h, buf)
end
