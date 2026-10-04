// src/draw_engine/mapping.dats
// Native ATS2 implementation of MinePaint Dynamics Mapping (Piecewise Linear Curves)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

#define CONTROL_POINTS_SIZE 520

typedef MinePaintMapping = @{
  base_value= float,
  inputs= int,
  pointsList= ptr,
  inputs_used= int
}

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

fn get_control_point_ptr(pointsList: ptr, input: int): ptr =
  ptr_add<byte>(pointsList, input * CONTROL_POINTS_SIZE)

fn get_cp_n(cp: ptr): int =
  $UN.ptr0_get<int>(ptr_add<int>(cp, 128))

fn set_cp_n(cp: ptr, n: int): void =
  $UN.ptr0_set<int>(ptr_add<int>(cp, 128), n)

fn get_cp_x(cp: ptr, idx: int): float = let
  val p = ptr_add<float>(cp, idx)
in
  $UN.ptr0_get<float>(p)
end

fn set_cp_x(cp: ptr, idx: int, x: float): void = let
  val p = ptr_add<float>(cp, idx)
in
  $UN.ptr0_set<float>(p, x)
end

fn get_cp_y(cp: ptr, idx: int): float = let
  val p = ptr_add<float>(cp, 64 + idx)
in
  $UN.ptr0_get<float>(p)
end

fn set_cp_y(cp: ptr, idx: int, y: float): void = let
  val p = ptr_add<float>(cp, 64 + idx)
in
  $UN.ptr0_set<float>(p, y)
end

extern fun minepaint_mapping_new(inputs: int): ptr = "ext#minepaint_mapping_new"
implement minepaint_mapping_new(inputs) = let
  val sz_map = sizeof<MinePaintMapping>
  val p_map = malloc(sz_map)
  val () = assertloc(p_map > the_null_ptr)
  val self = $UN.cast{ref(MinePaintMapping)}(p_map)

  val cp_sz = g0int2uint_int_size(CONTROL_POINTS_SIZE)
  val total_cp_sz = g0int2uint_int_size(inputs) * cp_sz
  val pts = malloc(total_cp_sz)
  val () = assertloc(pts > the_null_ptr)

  fun init_pts(i: int): void =
    if i < inputs then let
      val cp = get_control_point_ptr(pts, i)
      val () = set_cp_n(cp, 0)
    in
      init_pts(i + 1)
    end else ()
  val () = init_pts(0)

  val () = self->base_value := 0.0f
  val () = self->inputs := inputs
  val () = self->pointsList := pts
  val () = self->inputs_used := 0
in
  p_map
end

extern fun minepaint_mapping_free(self_p: ptr): void = "ext#minepaint_mapping_free"
implement minepaint_mapping_free(self_p) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintMapping)}(self_p)
    val pts = self->pointsList
    val () = if pts != the_null_ptr then free(pts)
    val () = free(self_p)
  in () end

extern fun minepaint_mapping_get_base_value(self_p: ptr): float = "ext#minepaint_mapping_get_base_value"
implement minepaint_mapping_get_base_value(self_p) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
in
  self->base_value
end

extern fun minepaint_mapping_set_base_value(self_p: ptr, value: float): void = "ext#minepaint_mapping_set_base_value"
implement minepaint_mapping_set_base_value(self_p, value) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
in
  self->base_value := value
end

extern fun minepaint_mapping_set_n(self_p: ptr, input: int, n: int): void = "ext#minepaint_mapping_set_n"
implement minepaint_mapping_set_n(self_p, input, n) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
  val num_inputs = self->inputs
  val () = assertloc(input >= 0 && input < num_inputs)
  val () = assertloc(n >= 0 && n <= 64)
  val () = assertloc(n != 1)

  val cp = get_control_point_ptr(self->pointsList, input)
  val old_n = get_cp_n(cp)
  val () =
    if (n != 0) && (old_n = 0) then self->inputs_used := self->inputs_used + 1
    else if (n = 0) && (old_n != 0) then self->inputs_used := self->inputs_used - 1
    else ()
  val () = set_cp_n(cp, n)
in
  ()
end

extern fun minepaint_mapping_get_n(self_p: ptr, input: int): int = "ext#minepaint_mapping_get_n"
implement minepaint_mapping_get_n(self_p, input) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
  val () = assertloc(input >= 0 && input < self->inputs)
  val cp = get_control_point_ptr(self->pointsList, input)
in
  get_cp_n(cp)
end

extern fun minepaint_mapping_set_point(self_p: ptr, input: int, index: int, x: float, y: float): void = "ext#minepaint_mapping_set_point"
implement minepaint_mapping_set_point(self_p, input, index, x, y) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
  val () = assertloc(input >= 0 && input < self->inputs)
  val () = assertloc(index >= 0 && index < 64)
  val cp = get_control_point_ptr(self->pointsList, input)
  val () = assertloc(index < get_cp_n(cp))
  val () = set_cp_x(cp, index, x)
  val () = set_cp_y(cp, index, y)
in
  ()
end

extern fun minepaint_mapping_get_point(self_p: ptr, input: int, index: int, x: &float? >> float, y: &float? >> float): void = "ext#minepaint_mapping_get_point"
implement minepaint_mapping_get_point(self_p, input, index, x, y) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
  val () = assertloc(input >= 0 && input < self->inputs)
  val () = assertloc(index >= 0 && index < 64)
  val cp = get_control_point_ptr(self->pointsList, input)
  val () = assertloc(index < get_cp_n(cp))
  val () = x := get_cp_x(cp, index)
  val () = y := get_cp_y(cp, index)
in
  ()
end

extern fun minepaint_mapping_is_constant(self_p: ptr): bool = "ext#minepaint_mapping_is_constant"
implement minepaint_mapping_is_constant(self_p) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
in
  self->inputs_used = 0
end

extern fun minepaint_mapping_get_inputs_used_n(self_p: ptr): int = "ext#minepaint_mapping_get_inputs_used_n"
implement minepaint_mapping_get_inputs_used_n(self_p) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
in
  self->inputs_used
end

extern fun minepaint_mapping_calculate(self_p: ptr, data: ptr): float = "ext#minepaint_mapping_calculate"
implement minepaint_mapping_calculate(self_p, data) = let
  val self = $UN.cast{ref(MinePaintMapping)}(self_p)
  val base = self->base_value
in
  if self->inputs_used = 0 then base
  else let
    val num_in = self->inputs
    val pts = self->pointsList
    fun loop_inputs(j: int, acc: float): float =
      if j < num_in then let
        val cp = get_control_point_ptr(pts, j)
        val n = get_cp_n(cp)
      in
        if n > 0 then let
          val x = $UN.ptr0_get<float>(ptr_add<float>(data, j))
          val x0_init = get_cp_x(cp, 0)
          val y0_init = get_cp_y(cp, 0)
          val x1_init = get_cp_x(cp, 1)
          val y1_init = get_cp_y(cp, 1)

          // find segment with slope
          fun find_seg(i: int, x0: float, y0: float, x1: float, y1: float): @(float, float, float, float) =
            if (i < n) && (x > x1) then
              find_seg(i + 1, x1, y1, get_cp_x(cp, i), get_cp_y(cp, i))
            else
              @(x0, y0, x1, y1)

          val @(x0, y0, x1, y1) = find_seg(2, x0_init, y0_init, x1_init, y1_init)
          val y =
            if (x0 = x1) || (y0 = y1) then y0
            else let
              val num = g0float_add(g0float_mul(y1, g0float_sub(x, x0)), g0float_mul(y0, g0float_sub(x1, x)))
              val den = g0float_sub(x1, x0)
            in
              g0float_div(num, den)
            end
        in
          loop_inputs(j + 1, g0float_add(acc, y))
        end else
          loop_inputs(j + 1, acc)
      end else acc
  in
    loop_inputs(0, base)
  end
end

extern fun minepaint_mapping_calculate_single_input(self_p: ptr, input: float): float = "ext#minepaint_mapping_calculate_single_input"
implement minepaint_mapping_calculate_single_input(self_p, input) = let
  var v: float = input
in
  minepaint_mapping_calculate(self_p, addr@(v))
end
