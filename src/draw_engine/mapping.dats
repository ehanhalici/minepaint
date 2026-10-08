// src/draw_engine/mapping.dats
// Native ATS2 implementation of MinePaint Dynamics Mapping (Piecewise Linear Curves)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./engine_safe.hats"

#define MAX_CONTROL_POINTS 64
#define CONTROL_POINTS_SIZE 520

typedef mp_mapping = @{
  base_value= float,
  inputs= int,
  points= ptr,
  inputs_used= int
}

extern castfn ptr2mapping(p: ptr): ref(mp_mapping) = "mac#"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun memset(p: ptr, v: int, sz: size_t): ptr = "mac#memset"

fn mp_mapping_get_base(m: ptr): float = (ptr2mapping(m))->base_value
fn mp_mapping_set_base(m: ptr, v: float): void = (ptr2mapping(m))->base_value := v
fn mp_mapping_get_inputs(m: ptr): int = (ptr2mapping(m))->inputs
fn mp_mapping_get_used(m: ptr): int = (ptr2mapping(m))->inputs_used
fn mp_mapping_set_used(m: ptr, u: int): void = (ptr2mapping(m))->inputs_used := u

fn mp_mapping_get_cp(m: ptr, idx: int): ptr = let
  val pts = (ptr2mapping(m))->points
in
  ptr_add<byte>(pts, idx * CONTROL_POINTS_SIZE)
end

fn mp_cp_get_n(cp: ptr): int = let
  val a = ptr2iarr{1}(ptr_add<int>(cp, 128))
in
  a[0]
end

fn mp_cp_set_n(cp: ptr, n: int): void = let
  val a = ptr2iarr{1}(ptr_add<int>(cp, 128))
in
  a[0] := n
end

fn mp_cp_get_x(cp: ptr, i: int): float = let
  val a = ptr2farr{64}(cp)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 64) then a[idx] else 0.0f
end

fn mp_cp_set_x(cp: ptr, i: int, v: float): void = let
  val a = ptr2farr{64}(cp)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 64) then a[idx] := v else ()
end

fn mp_cp_get_y(cp: ptr, i: int): float = let
  val a = ptr2farr{64}(ptr_add<float>(cp, 64))
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 64) then a[idx] else 0.0f
end

fn mp_cp_set_y(cp: ptr, i: int, v: float): void = let
  val a = ptr2farr{64}(ptr_add<float>(cp, 64))
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 64) then a[idx] := v else ()
end

extern fun minepaint_mapping_new(inputs: int): ptr = "ext#minepaint_mapping_new"
implement minepaint_mapping_new(inputs) = let
  val p = malloc(sizeof<mp_mapping>)
  val () = assertloc(p > the_null_ptr)
  val m = ptr2mapping(p)
  val n_inputs = if inputs > 0 then inputs else 1
  val cp_sz = g0int2uint_int_size(n_inputs) * g0int2uint_int_size(CONTROL_POINTS_SIZE)
  val pts = malloc(cp_sz)
  val () = assertloc(pts > the_null_ptr)
  val _ = memset(pts, 0, cp_sz)
  val () = m->base_value := 0.0f
  val () = m->inputs := inputs
  val () = m->points := pts
  val () = m->inputs_used := 0
in
  p
end

extern fun minepaint_mapping_free(self_p: ptr): void = "ext#minepaint_mapping_free"
implement minepaint_mapping_free(self_p) =
  if self_p != the_null_ptr then let
    val m = ptr2mapping(self_p)
    val pts = m->points
    val () = if pts != the_null_ptr then free(pts)
  in
    free(self_p)
  end

extern fun minepaint_mapping_get_base_value(self_p: ptr): float = "ext#minepaint_mapping_get_base_value"
implement minepaint_mapping_get_base_value(self_p) =
  mp_mapping_get_base(self_p)

extern fun minepaint_mapping_set_base_value(self_p: ptr, value: float): void = "ext#minepaint_mapping_set_base_value"
implement minepaint_mapping_set_base_value(self_p, value) =
  mp_mapping_set_base(self_p, value)

fn update_used_count(self_p: ptr, old_n: int, new_n: int): void = let
  val cur_used = mp_mapping_get_used(self_p)
  val updated =
    if (new_n != 0) && (old_n = 0) then cur_used + 1
    else if (new_n = 0) && (old_n != 0) then cur_used - 1
    else cur_used
in
  mp_mapping_set_used(self_p, updated)
end

extern fun minepaint_mapping_set_n(self_p: ptr, input: int, n: int): void = "ext#minepaint_mapping_set_n"
implement minepaint_mapping_set_n(self_p, input, n) = let
  val num_inputs = mp_mapping_get_inputs(self_p)
  val () = assertloc(input >= 0 && input < num_inputs)
  val () = assertloc(n >= 0 && n <= MAX_CONTROL_POINTS && n != 1)
  val cp = mp_mapping_get_cp(self_p, input)
  val old_n = mp_cp_get_n(cp)
  val () = update_used_count(self_p, old_n, n)
in
  mp_cp_set_n(cp, n)
end

extern fun minepaint_mapping_get_n(self_p: ptr, input: int): int = "ext#minepaint_mapping_get_n"
implement minepaint_mapping_get_n(self_p, input) = let
  val () = assertloc(input >= 0 && input < mp_mapping_get_inputs(self_p))
  val cp = mp_mapping_get_cp(self_p, input)
in
  mp_cp_get_n(cp)
end

extern fun minepaint_mapping_set_point(
  self_p: ptr, input: int, index: int, x: float, y: float
): void = "ext#minepaint_mapping_set_point"
implement minepaint_mapping_set_point(self_p, input, index, x, y) = let
  val () = assertloc(input >= 0 && input < mp_mapping_get_inputs(self_p))
  val () = assertloc(index >= 0 && index < MAX_CONTROL_POINTS)
  val cp = mp_mapping_get_cp(self_p, input)
  val () = assertloc(index < mp_cp_get_n(cp))
  val () = mp_cp_set_x(cp, index, x)
in
  mp_cp_set_y(cp, index, y)
end

extern fun minepaint_mapping_get_point(
  self_p: ptr, input: int, index: int, x: &float? >> float, y: &float? >> float
): void = "ext#minepaint_mapping_get_point"
implement minepaint_mapping_get_point(self_p, input, index, x, y) = let
  val () = assertloc(input >= 0 && input < mp_mapping_get_inputs(self_p))
  val () = assertloc(index >= 0 && index < MAX_CONTROL_POINTS)
  val cp = mp_mapping_get_cp(self_p, input)
  val () = assertloc(index < mp_cp_get_n(cp))
  val () = x := mp_cp_get_x(cp, index)
in
  y := mp_cp_get_y(cp, index)
end

extern fun minepaint_mapping_is_constant(self_p: ptr): bool = "ext#minepaint_mapping_is_constant"
implement minepaint_mapping_is_constant(self_p) =
  mp_mapping_get_used(self_p) = 0

extern fun minepaint_mapping_get_inputs_used_n(self_p: ptr): int = "ext#minepaint_mapping_get_inputs_used_n"
implement minepaint_mapping_get_inputs_used_n(self_p) =
  mp_mapping_get_used(self_p)

fn eval_segment(x: float, x0: float, y0: float, x1: float, y1: float): float =
  if (x0 = x1) || (y0 = y1) then y0
  else let
    val num = g0float_add(g0float_mul(y1, g0float_sub(x, x0)), g0float_mul(y0, g0float_sub(x1, x)))
    val den = g0float_sub(x1, x0)
  in
    g0float_div(num, den)
  end

fun find_seg(
  cp: ptr, n: int, x: float, i: int,
  x0: float, y0: float, x1: float, y1: float
): @(float, float, float, float) =
  if (i < n) && (x > x1) then
    find_seg(cp, n, x, i + 1, x1, y1, mp_cp_get_x(cp, i), mp_cp_get_y(cp, i))
  else
    @(x0, y0, x1, y1)

fn eval_input_curve(cp: ptr, x: float): float = let
  val n = mp_cp_get_n(cp)
in
  if n <= 0 then 0.0f
  else let
    val x0_init = mp_cp_get_x(cp, 0)
    val y0_init = mp_cp_get_y(cp, 0)
    val x1_init = mp_cp_get_x(cp, 1)
    val y1_init = mp_cp_get_y(cp, 1)
    val @(x0, y0, x1, y1) = find_seg(cp, n, x, 2, x0_init, y0_init, x1_init, y1_init)
  in
    eval_segment(x, x0, y0, x1, y1)
  end
end

fun loop_mapping_inputs(
  self_p: ptr, data: ptr, j: int, num_in: int, acc: float
): float =
  if j < num_in then let
    val cp = mp_mapping_get_cp(self_p, j)
    val x = mp_arr_fget(data, j)
    val y = eval_input_curve(cp, x)
  in
    loop_mapping_inputs(self_p, data, j + 1, num_in, g0float_add(acc, y))
  end else acc

extern fun minepaint_mapping_calculate(self_p: ptr, data: ptr): float = "ext#minepaint_mapping_calculate"
implement minepaint_mapping_calculate(self_p, data) = let
  val base = mp_mapping_get_base(self_p)
in
  if mp_mapping_get_used(self_p) = 0 then base
  else loop_mapping_inputs(self_p, data, 0, mp_mapping_get_inputs(self_p), base)
end

extern fun minepaint_mapping_calculate_single_input(self_p: ptr, input: float): float = "ext#minepaint_mapping_calculate_single_input"
implement minepaint_mapping_calculate_single_input(self_p, input) = let
  var v: float = input
in
  minepaint_mapping_calculate(self_p, addr@(v))
end
