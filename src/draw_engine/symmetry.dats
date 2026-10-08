// src/draw_engine/symmetry.dats
// Native ATS2 implementation of Brush Symmetry Calculations
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "./engine_safe.hats"

#define MINEPAINT_SYMMETRY_TYPE_VERTICAL 0
#define MINEPAINT_SYMMETRY_TYPE_HORIZONTAL 1
#define MINEPAINT_SYMMETRY_TYPE_VERTHORZ 2
#define MINEPAINT_SYMMETRY_TYPE_ROTATIONAL 3
#define MINEPAINT_SYMMETRY_TYPE_SNOWFLAKE 4

#define DEFAULT_NUM_MATRICES 16

typedef MinePaintTransform = @{
  r0= float, r1= float, r2= float,
  r3= float, r4= float, r5= float,
  r6= float, r7= float, r8= float
}

typedef MinePaintSymmetryState_struct = @{
  type= int,
  center_x= float,
  center_y= float,
  angle= float,
  num_lines= float
}

typedef MinePaintSymmetryData_struct = @{
  state_current= MinePaintSymmetryState_struct,
  state_pending= MinePaintSymmetryState_struct,
  pending_changes= int,
  active= int,
  num_symmetry_matrices= int,
  symmetry_matrices= ptr
}

extern castfn ptr2sym_data(p: ptr): ref(MinePaintSymmetryData_struct) = "mac#"

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"
extern fun realloc(p: ptr, sz: size_t): ptr = "mac#realloc"

// External functions from matrix.dats
extern fun minepaint_transform_unit(out: ptr): void = "ext#minepaint_transform_unit"
extern fun minepaint_transform_translate(transform: ptr, x: float, y: float, out: ptr): void = "ext#minepaint_transform_translate"
extern fun minepaint_transform_rotate_cw(transform: ptr, angle_rad: float, out: ptr): void = "ext#minepaint_transform_rotate_cw"
extern fun minepaint_transform_reflect(transform: ptr, angle_rad: float, out: ptr): void = "ext#minepaint_transform_reflect"

fn get_matrix_ptr(matrices: ptr, idx: int): ptr =
  ptr_add<MinePaintTransform>(matrices, idx)

fn num_matrices_required(t: int, num_lines: float): int = let
  val n_lines: int = g0float2int(num_lines)
in
  if t = MINEPAINT_SYMMETRY_TYPE_VERTICAL then 1
  else if t = MINEPAINT_SYMMETRY_TYPE_HORIZONTAL then 1
  else if t = MINEPAINT_SYMMETRY_TYPE_VERTHORZ then 3
  else if t = MINEPAINT_SYMMETRY_TYPE_ROTATIONAL then n_lines - 1
  else if t = MINEPAINT_SYMMETRY_TYPE_SNOWFLAKE then 2 * n_lines - 1
  else 0
end

fn allocate_symmetry_matrices(self: ptr, num_matrices: int): bool = let
  val data = ptr2sym_data(self)
  val bytes = g0int2uint_int_size(num_matrices) * sizeof<MinePaintTransform>
  val allocated = realloc(data->symmetry_matrices, bytes)
in
  if allocated = the_null_ptr then (data->num_symmetry_matrices := 0; false)
  else (data->symmetry_matrices := allocated; data->num_symmetry_matrices := num_matrices; true)
end

// --- Symmetry Generation Helpers (Atomic & Shallow Depth) ---
fn apply_line_reflection(matrices: ptr, m_ptr: ptr, st_type: int, angle_rad: float, pi: float): void = let
  val a = if st_type = MINEPAINT_SYMMETRY_TYPE_VERTICAL then f_add(angle_rad, f_div(pi, 2.0f)) else angle_rad
  val target = get_matrix_ptr(matrices, 0)
in
  minepaint_transform_reflect(m_ptr, f_sub(0.0f, a), target)
end

fn apply_verthorz_reflection(matrices: ptr, m_ptr: ptr, angle_rad: float, pi: float): void = let
  val v_angle = f_add(angle_rad, f_div(pi, 2.0f))
  val m0 = get_matrix_ptr(matrices, 0)
  val m1 = get_matrix_ptr(matrices, 1)
  val m2 = get_matrix_ptr(matrices, 2)
  val () = minepaint_transform_reflect(m_ptr, f_sub(0.0f, angle_rad), m0)
  val () = minepaint_transform_reflect(m0, f_sub(0.0f, v_angle), m1)
  val () = minepaint_transform_reflect(m1, f_sub(0.0f, angle_rad), m2)
in () end

fn apply_snowflake_branches(matrices: ptr, m_ptr: ptr, num_l: int, rot_angle: float, angle_rad: float): void = let
  val base_idx = num_l - 1
  fun loop_snow(i: int): void =
    if i < num_l then let
      var rot_m: @[float][9]
      val rot_m_ptr = addr@(rot_m)
      val cur_rot = f_mul(rot_angle, g0int2float_int_float(i))
      val () = minepaint_transform_rotate_cw(m_ptr, cur_rot, rot_m_ptr)
      val ref_angle = f_sub(f_sub(0.0f, cur_rot), angle_rad)
      val target = get_matrix_ptr(matrices, base_idx + i)
      val () = minepaint_transform_reflect(rot_m_ptr, ref_angle, target)
    in loop_snow(i + 1) end else ()
  fun loop_rot(i: int): void =
    if i < num_l then let
      val cur_rot = f_mul(rot_angle, g0int2float_int_float(i))
      val target = get_matrix_ptr(matrices, i - 1)
      val () = minepaint_transform_rotate_cw(m_ptr, cur_rot, target)
    in loop_rot(i + 1) end else ()
  val () = loop_snow(0)
in
  loop_rot(1)
end

fn apply_rotational_branches(matrices: ptr, m_ptr: ptr, num_l: int, rot_angle: float): void = let
  fun loop_rot(i: int): void =
    if i < num_l then let
      val cur_rot = f_mul(rot_angle, g0int2float_int_float(i))
      val target = get_matrix_ptr(matrices, i - 1)
      val () = minepaint_transform_rotate_cw(m_ptr, cur_rot, target)
    in loop_rot(i + 1) end else ()
in
  loop_rot(1)
end

fn translate_matrices_back(matrices: ptr, required: int, cx: float, cy: float): void = let
  fun loop(i: int): void =
    if i < required then let
      val target = get_matrix_ptr(matrices, i)
      val () = minepaint_transform_translate(target, cx, cy, target)
    in loop(i + 1) end else ()
in
  loop(0)
end

fn compute_symmetry_transforms(
  matrices: ptr, m_ptr: ptr, st_type: int,
  angle_rad: float, rot_angle: float, num_l: int, pi: float
): void =
  if (st_type = MINEPAINT_SYMMETRY_TYPE_HORIZONTAL) || (st_type = MINEPAINT_SYMMETRY_TYPE_VERTICAL) then
    apply_line_reflection(matrices, m_ptr, st_type, angle_rad, pi)
  else if st_type = MINEPAINT_SYMMETRY_TYPE_VERTHORZ then
    apply_verthorz_reflection(matrices, m_ptr, angle_rad, pi)
  else if st_type = MINEPAINT_SYMMETRY_TYPE_SNOWFLAKE then
    apply_snowflake_branches(matrices, m_ptr, num_l, rot_angle, angle_rad)
  else if st_type = MINEPAINT_SYMMETRY_TYPE_ROTATIONAL then
    apply_rotational_branches(matrices, m_ptr, num_l, rot_angle)
  else ()

fn update_symmetry_matrices_all(self: ref(MinePaintSymmetryData_struct), self_p: ptr, pend_t: int, pend_nl: float): void = let
  val required = num_matrices_required(pend_t, pend_nl)
  val can_proceed = if self->num_symmetry_matrices < required then allocate_symmetry_matrices(self_p, required) else true
in
  if can_proceed then let
    val () = self->state_current.type := pend_t
    val () = self->state_current.center_x := self->state_pending.center_x
    val () = self->state_current.center_y := self->state_pending.center_y
    val () = self->state_current.angle := self->state_pending.angle
    val () = self->state_current.num_lines := pend_nl

    val cx = self->state_pending.center_x
    val cy = self->state_pending.center_y
    val pi = 3.141592653589793f
    val angle_rad = f_mul(self->state_pending.angle, f_div(pi, 180.0f))
    val rot_angle = f_div(f_mul(2.0f, pi), pend_nl)
    val matrices = self->symmetry_matrices

    var m_buf: @[float][9]
    val m_ptr = addr@(m_buf)
    val () = minepaint_transform_unit(m_ptr)
    val () = minepaint_transform_translate(m_ptr, f_sub(0.0f, cx), f_sub(0.0f, cy), m_ptr)
    val () = compute_symmetry_transforms(matrices, m_ptr, pend_t, angle_rad, rot_angle, g0float2int(pend_nl), pi)
    val () = translate_matrices_back(matrices, required, cx, cy)
    val () = self->pending_changes := 0
  in () end
end

extern fun minepaint_update_symmetry_state(self_p: ptr): void = "ext#minepaint_update_symmetry_state"
implement minepaint_update_symmetry_state(self_p) =
  if self_p != the_null_ptr then let
    val self = ptr2sym_data(self_p)
    val eq = (self->state_current.type = self->state_pending.type) &&
             (self->state_current.center_x = self->state_pending.center_x) &&
             (self->state_current.center_y = self->state_pending.center_y) &&
             (self->state_current.angle = self->state_pending.angle) &&
             (self->state_current.num_lines = self->state_pending.num_lines)
  in
    if (self->pending_changes != 0) * not(eq) then
      update_symmetry_matrices_all(self, self_p, self->state_pending.type, self->state_pending.num_lines)
  end

extern fun minepaint_symmetry_data_new(): ptr = "ext#minepaint_symmetry_data_new"
implement minepaint_symmetry_data_new() = let
  val p = malloc(sizeof<MinePaintSymmetryData_struct>)
  val () = assertloc(p > the_null_ptr)
  val self = ptr2sym_data(p)

  val () = self->state_current.type := ~1
  val () = self->state_current.center_x := 0.0f
  val () = self->state_current.center_y := 0.0f
  val () = self->state_current.angle := 0.0f
  val () = self->state_current.num_lines := 2.0f

  val () = self->state_pending.type := MINEPAINT_SYMMETRY_TYPE_VERTICAL
  val () = self->state_pending.center_x := 0.0f
  val () = self->state_pending.center_y := 0.0f
  val () = self->state_pending.angle := 0.0f
  val () = self->state_pending.num_lines := 2.0f

  val () = self->pending_changes := 1
  val () = self->active := 0
  val () = self->num_symmetry_matrices := 0
  val () = self->symmetry_matrices := the_null_ptr

  val ok = allocate_symmetry_matrices(p, DEFAULT_NUM_MATRICES)
  val () = if ok then minepaint_update_symmetry_state(p)
in
  p
end

extern fun minepaint_symmetry_data_destroy(data_p: ptr): void = "ext#minepaint_symmetry_data_destroy"
implement minepaint_symmetry_data_destroy(data_p) =
  if data_p != the_null_ptr then let
    val self = ptr2sym_data(data_p)
    val () = if self->symmetry_matrices != the_null_ptr then free(self->symmetry_matrices)
    val () = free(data_p)
  in () end

extern fun minepaint_symmetry_set_pending(
  data_p: ptr,
  active: bool,
  center_x: float,
  center_y: float,
  symmetry_angle: float,
  symmetry_type: int,
  rot_symmetry_lines: int
): void = "ext#minepaint_symmetry_set_pending"
implement minepaint_symmetry_set_pending(data_p, active, center_x, center_y, symmetry_angle, symmetry_type, rot_symmetry_lines) =
  if data_p != the_null_ptr then let
    val self = ptr2sym_data(data_p)
    val () = self->active := (if active then 1 else 0)
    val () = self->state_pending.center_x := center_x
    val () = self->state_pending.center_y := center_y
    val () = self->state_pending.type := symmetry_type
    val num_l = if rot_symmetry_lines < 2 then 2 else rot_symmetry_lines
    val () = self->state_pending.num_lines := g0int2float_int_float(num_l)
    val () = self->state_pending.angle := symmetry_angle
    val () = self->pending_changes := 1
  in () end
