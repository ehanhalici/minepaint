// src/draw_engine/symmetry.dats
// Native ATS2 implementation of Brush Symmetry Calculations
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

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
  val data = $UN.cast{ref(MinePaintSymmetryData_struct)}(self)
  val bytes = g0int2uint_int_size(num_matrices) * sizeof<MinePaintTransform>
  val allocated = realloc(data->symmetry_matrices, bytes)
in
  if allocated = the_null_ptr then let
    val () = data->num_symmetry_matrices := 0
  in
    false
  end else let
    val () = data->symmetry_matrices := allocated
    val () = data->num_symmetry_matrices := num_matrices
  in
    true
  end
end

extern fun minepaint_update_symmetry_state(self_p: ptr): void = "ext#minepaint_update_symmetry_state"
implement minepaint_update_symmetry_state(self_p) =
  if self_p != the_null_ptr then let
    val self = $UN.cast{ref(MinePaintSymmetryData_struct)}(self_p)
    val cur_t = self->state_current.type
    val cur_cx = self->state_current.center_x
    val cur_cy = self->state_current.center_y
    val cur_ang = self->state_current.angle
    val cur_nl = self->state_current.num_lines

    val pend_t = self->state_pending.type
    val pend_cx = self->state_pending.center_x
    val pend_cy = self->state_pending.center_y
    val pend_ang = self->state_pending.angle
    val pend_nl = self->state_pending.num_lines

    val states_equal =
      (cur_t = pend_t) && (cur_cx = pend_cx) && (cur_cy = pend_cy) &&
      (cur_ang = pend_ang) && (cur_nl = pend_nl)
  in
    if self->pending_changes = 0 then ()
    else (
      case+ states_equal of
      | true => ()
      | false => let
          val required = num_matrices_required(pend_t, pend_nl)
          val can_proceed =
            if self->num_symmetry_matrices < required then
              allocate_symmetry_matrices(self_p, required)
            else true
        in
          case+ can_proceed of
          | false => ()
          | true => let
              val () = self->state_current.type := pend_t
              val () = self->state_current.center_x := pend_cx
              val () = self->state_current.center_y := pend_cy
              val () = self->state_current.angle := pend_ang
              val () = self->state_current.num_lines := pend_nl

        val cx = pend_cx
        val cy = pend_cy
        val pi = 3.141592653589793f
        val angle_rad = f_mul(pend_ang, f_div(pi, 180.0f))
        val rot_angle = f_div(f_mul(2.0f, pi), pend_nl)
        val matrices = self->symmetry_matrices

        var m_buf: @[float][9]
        val m_ptr = addr@(m_buf)
        val () = minepaint_transform_unit(m_ptr)
        // Merkezleme: m = T(-cx,-cy). Helper'lar pre-multiply
        // (out = Factor * transform) olduğu için zincir
        // Final = T(cx,cy) * R * T(-cx,-cy) verir (multiply artık standart).
        val () = minepaint_transform_translate(m_ptr, f_sub(0.0f, cx), f_sub(0.0f, cy), m_ptr)

        val st_type = pend_t
        val num_l: int = g0float2int(pend_nl)

        val () =
          if (st_type = MINEPAINT_SYMMETRY_TYPE_HORIZONTAL) || (st_type = MINEPAINT_SYMMETRY_TYPE_VERTICAL) then let
            val a = if st_type = MINEPAINT_SYMMETRY_TYPE_VERTICAL then f_add(angle_rad, f_div(pi, 2.0f)) else angle_rad
            val target = get_matrix_ptr(matrices, 0)
            val () = minepaint_transform_reflect(m_ptr, f_sub(0.0f, a), target)
          in () end
          else if st_type = MINEPAINT_SYMMETRY_TYPE_VERTHORZ then let
            val v_angle = f_add(angle_rad, f_div(pi, 2.0f))
            val m0 = get_matrix_ptr(matrices, 0)
            val m1 = get_matrix_ptr(matrices, 1)
            val m2 = get_matrix_ptr(matrices, 2)
            val () = minepaint_transform_reflect(m_ptr, f_sub(0.0f, angle_rad), m0)
            val () = minepaint_transform_reflect(m0, f_sub(0.0f, v_angle), m1)
            val () = minepaint_transform_reflect(m1, f_sub(0.0f, angle_rad), m2)
          in () end
          else if st_type = MINEPAINT_SYMMETRY_TYPE_SNOWFLAKE then let
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
              in
                loop_snow(i + 1)
              end else ()
            val () = loop_snow(0)
            fun loop_rot(i: int): void =
              if i < num_l then let
                val () =
                  if i > 0 then let
                    val cur_rot = f_mul(rot_angle, g0int2float_int_float(i))
                    val target = get_matrix_ptr(matrices, i - 1)
                    val () = minepaint_transform_rotate_cw(m_ptr, cur_rot, target)
                  in () end
              in
                loop_rot(i + 1)
              end else ()
            val () = loop_rot(1)
          in () end
          else if st_type = MINEPAINT_SYMMETRY_TYPE_ROTATIONAL then let
            fun loop_rot_only(i: int): void =
              if i < num_l then let
                val cur_rot = f_mul(rot_angle, g0int2float_int_float(i))
                val target = get_matrix_ptr(matrices, i - 1)
                val () = minepaint_transform_rotate_cw(m_ptr, cur_rot, target)
              in
                loop_rot_only(i + 1)
              end else ()
            val () = loop_rot_only(1)
          in () end
          else ()

        // Translate each matrix back by (cx, cy):
        // target = T(cx,cy) * target -> Final = T(c) * R * T(-c)
        fun loop_trans_back(i: int): void =
          if i < required then let
            val target = get_matrix_ptr(matrices, i)
            val () = minepaint_transform_translate(target, cx, cy, target)
          in
            loop_trans_back(i + 1)
          end else ()
        val () = loop_trans_back(0)
        val () = self->pending_changes := 0
      in () end
    end
  ) end else ()

extern fun minepaint_symmetry_data_new(): ptr = "ext#minepaint_symmetry_data_new"
implement minepaint_symmetry_data_new() = let
  val sz = sizeof<MinePaintSymmetryData_struct>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val self = $UN.cast{ref(MinePaintSymmetryData_struct)}(p)

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
    val self = $UN.cast{ref(MinePaintSymmetryData_struct)}(data_p)
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
    val self = $UN.cast{ref(MinePaintSymmetryData_struct)}(data_p)
    val () = self->active := (if active then 1 else 0)
    val () = self->state_pending.center_x := center_x
    val () = self->state_pending.center_y := center_y
    val () = self->state_pending.type := symmetry_type
    val num_l = if rot_symmetry_lines < 2 then 2 else rot_symmetry_lines
    val () = self->state_pending.num_lines := g0int2float_int_float(num_l)
    val () = self->state_pending.angle := symmetry_angle
    val () = self->pending_changes := 1
  in () end
