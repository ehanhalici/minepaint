// src/draw_engine/symmetry.dats
// Symmetry matrices live in a typed arena addressed by an integer handle.
// main.dats dynloads this file. The arithmetic is the value-level matrix core.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./matrix_pure.hats"

#define SYMM_CAP 8
#define SYMM_MAX_MATRICES 128
#define SYMM_FLOATS (SYMM_CAP * SYMM_MAX_MATRICES * 9)
#define DEFAULT_NUM_MATRICES 16

#define SYM_VERTICAL 0
#define SYM_HORIZONTAL 1
#define SYM_VERTHORZ 2
#define SYM_ROTATIONAL 3
#define SYM_SNOWFLAKE 4

datatype SymmetryKind =
  | SymVertical of ()
  | SymHorizontal of ()
  | SymVertHorz of ()
  | SymRotational of ()
  | SymSnowflake of ()
  | SymOther of ()

fn kind_of(t: int): SymmetryKind =
  if t = SYM_VERTICAL then SymVertical()
  else if t = SYM_HORIZONTAL then SymHorizontal()
  else if t = SYM_VERTHORZ then SymVertHorz()
  else if t = SYM_ROTATIONAL then SymRotational()
  else if t = SYM_SNOWFLAKE then SymSnowflake()
  else SymOther()

val g_alive = arrayref_make_elt<bool>(i2sz(SYMM_CAP), false)
val g_active = arrayref_make_elt<int>(i2sz(SYMM_CAP), 0)
val g_changes = arrayref_make_elt<int>(i2sz(SYMM_CAP), 0)
val g_nmat = arrayref_make_elt<int>(i2sz(SYMM_CAP), 0)
val g_cur_type = arrayref_make_elt<int>(i2sz(SYMM_CAP), 0)
val g_cur_x = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_cur_y = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_cur_ang = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_cur_lines = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_pen_type = arrayref_make_elt<int>(i2sz(SYMM_CAP), 0)
val g_pen_x = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_pen_y = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_pen_ang = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_pen_lines = arrayref_make_elt<float>(i2sz(SYMM_CAP), 0.0f)
val g_mat = arrayref_make_elt<float>(i2sz(SYMM_FLOATS), 0.0f)

fn alive_get(h: int): bool = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < SYMM_CAP) then g_alive[i] else false
end

fn alive_set(h: int, v: bool): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < SYMM_CAP) then g_alive[i] := v else ()
end

fn i_get(a: arrayref(int, SYMM_CAP), h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < SYMM_CAP) then a[i] else 0
end

fn i_set(a: arrayref(int, SYMM_CAP), h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < SYMM_CAP) then a[i] := v else ()
end

fn f_get(a: arrayref(float, SYMM_CAP), h: int): float = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < SYMM_CAP) then a[i] else 0.0f
end

fn f_set(a: arrayref(float, SYMM_CAP), h: int, v: float): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < SYMM_CAP) then a[i] := v else ()
end

fn mat_index(h: int, idx: int, k: int): int =
  (h * SYMM_MAX_MATRICES + idx) * 9 + k

fn mat_get(h: int, idx: int, k: int): float = let
  val i = g1ofg0(mat_index(h, idx, k))
in
  if (i >= 0) * (i < SYMM_FLOATS) then g_mat[i] else 0.0f
end

fn mat_set(h: int, idx: int, k: int, v: float): void = let
  val i = g1ofg0(mat_index(h, idx, k))
in
  if (i >= 0) * (i < SYMM_FLOATS) then g_mat[i] := v else ()
end

fn load_mat(h: int, idx: int): MinePaintTransform =
  @{ r0= mat_get(h, idx, 0), r1= mat_get(h, idx, 1), r2= mat_get(h, idx, 2),
     r3= mat_get(h, idx, 3), r4= mat_get(h, idx, 4), r5= mat_get(h, idx, 5),
     r6= mat_get(h, idx, 6), r7= mat_get(h, idx, 7), r8= mat_get(h, idx, 8) }

fn store_mat(h: int, idx: int, t: MinePaintTransform): void = let
  val () = mat_set(h, idx, 0, t.r0)
  val () = mat_set(h, idx, 1, t.r1)
  val () = mat_set(h, idx, 2, t.r2)
  val () = mat_set(h, idx, 3, t.r3)
  val () = mat_set(h, idx, 4, t.r4)
  val () = mat_set(h, idx, 5, t.r5)
  val () = mat_set(h, idx, 6, t.r6)
  val () = mat_set(h, idx, 7, t.r7)
in
  mat_set(h, idx, 8, t.r8)
end

fun find_free(i: int): int =
  if i >= SYMM_CAP then SYMMETRY_NONE
  else if alive_get(i) then find_free(i + 1)
  else i

fn lines_of(num_lines: float): int = g0float2int(num_lines)

fn matrices_required(t: int, num_lines: float): int = let
  val n = lines_of(num_lines)
in
  case+ kind_of(t) of
  | SymVertical() => 1
  | SymHorizontal() => 1
  | SymVertHorz() => 3
  | SymRotational() => n - 1
  | SymSnowflake() => 2 * n - 1
  | SymOther() => 0
end

fn grow_matrices(h: int, need: int): bool =
  if need <= i_get(g_nmat, h) then true
  else if (need > 0) * (need <= SYMM_MAX_MATRICES) then let
    val () = i_set(g_nmat, h, need)
  in true end
  else let
    val () = i_set(g_nmat, h, 0)
  in false end

fn f_add(a: float, b: float): float = g0float_add(a, b)
fn f_sub(a: float, b: float): float = g0float_sub(a, b)
fn f_mul(a: float, b: float): float = g0float_mul(a, b)
fn f_div(a: float, b: float): float = g0float_div(a, b)

fn reflect_into(h: int, idx: int, m: MinePaintTransform, angle: float): void =
  store_mat(h, idx, mat_mul(mat_reflect_factor(angle), m))

fn rotate_into(h: int, idx: int, m: MinePaintTransform, angle: float): void =
  store_mat(h, idx, mat_mul(mat_rot_cw_factor(angle), m))

fn apply_line(h: int, m: MinePaintTransform, t: int, angle_rad: float, pi: float): void = let
  val a = if t = SYM_VERTICAL then f_add(angle_rad, f_div(pi, 2.0f)) else angle_rad
in
  reflect_into(h, 0, m, f_sub(0.0f, a))
end

fn apply_verthorz(h: int, m: MinePaintTransform, angle_rad: float, pi: float): void = let
  val v_angle = f_add(angle_rad, f_div(pi, 2.0f))
  val () = reflect_into(h, 0, m, f_sub(0.0f, angle_rad))
  val m0 = load_mat(h, 0)
  val () = reflect_into(h, 1, m0, f_sub(0.0f, v_angle))
  val m1 = load_mat(h, 1)
in
  reflect_into(h, 2, m1, f_sub(0.0f, angle_rad))
end

fun snow_branch(h: int, m: MinePaintTransform, num_l: int, rot: float, ang: float, i: int): void =
  if i < num_l then let
    val cur = f_mul(rot, g0int2float_int_float(i))
    val turned = mat_mul(mat_rot_cw_factor(cur), m)
    val ref_angle = f_sub(f_sub(0.0f, cur), ang)
    val () = reflect_into(h, (num_l - 1) + i, turned, ref_angle)
  in snow_branch(h, m, num_l, rot, ang, i + 1) end
  else ()

fun rot_branch(h: int, m: MinePaintTransform, num_l: int, rot: float, i: int): void =
  if i < num_l then let
    val cur = f_mul(rot, g0int2float_int_float(i))
    val () = rotate_into(h, i - 1, m, cur)
  in rot_branch(h, m, num_l, rot, i + 1) end
  else ()

fn apply_snow(h: int, m: MinePaintTransform, num_l: int, rot: float, ang: float): void = let
  val () = snow_branch(h, m, num_l, rot, ang, 0)
in
  rot_branch(h, m, num_l, rot, 1)
end

fn apply_rot(h: int, m: MinePaintTransform, num_l: int, rot: float): void =
  rot_branch(h, m, num_l, rot, 1)

fun translate_back(h: int, n: int, cx: float, cy: float, i: int): void =
  if i < n then let
    val shifted = mat_mul(mat_translate_factor(cx, cy), load_mat(h, i))
    val () = store_mat(h, i, shifted)
  in translate_back(h, n, cx, cy, i + 1) end
  else ()

fn dispatch_kind(h: int, m: MinePaintTransform, t: int, ang: float, rot: float, num_l: int, pi: float): void =
  case+ kind_of(t) of
  | SymVertical() => apply_line(h, m, t, ang, pi)
  | SymHorizontal() => apply_line(h, m, t, ang, pi)
  | SymVertHorz() => apply_verthorz(h, m, ang, pi)
  | SymSnowflake() => apply_snow(h, m, num_l, rot, ang)
  | SymRotational() => apply_rot(h, m, num_l, rot)
  | SymOther() => ()

fn publish_current(h: int, pend_t: int, pend_nl: float): void = let
  val () = i_set(g_cur_type, h, pend_t)
  val () = f_set(g_cur_x, h, f_get(g_pen_x, h))
  val () = f_set(g_cur_y, h, f_get(g_pen_y, h))
  val () = f_set(g_cur_ang, h, f_get(g_pen_ang, h))
in
  f_set(g_cur_lines, h, pend_nl)
end

fn rebuild(h: int, pend_t: int, pend_nl: float): void = let
  val required = matrices_required(pend_t, pend_nl)
in
  if grow_matrices(h, required) then let
    val cx = f_get(g_pen_x, h)
    val cy = f_get(g_pen_y, h)
    val pi = 3.141592653589793f
    val angle_rad = f_mul(f_get(g_pen_ang, h), f_div(pi, 180.0f))
    val rot_angle = f_div(f_mul(2.0f, pi), pend_nl)
    val origin = mat_translate_factor(f_sub(0.0f, cx), f_sub(0.0f, cy))
    val () = publish_current(h, pend_t, pend_nl)
    val () = dispatch_kind(h, origin, pend_t, angle_rad, rot_angle, lines_of(pend_nl), pi)
    val () = translate_back(h, required, cx, cy, 0)
  in
    i_set(g_changes, h, 0)
  end else ()
end

fn pending_matches(h: int): bool =
  (i_get(g_cur_type, h) = i_get(g_pen_type, h)) &&
  (f_get(g_cur_x, h) = f_get(g_pen_x, h)) &&
  (f_get(g_cur_y, h) = f_get(g_pen_y, h)) &&
  (f_get(g_cur_ang, h) = f_get(g_pen_ang, h)) &&
  (f_get(g_cur_lines, h) = f_get(g_pen_lines, h))

extern fun minepaint_update_symmetry_state(h: int): void = "ext#minepaint_update_symmetry_state"
implement minepaint_update_symmetry_state(h) =
  if alive_get(h) then
    if (i_get(g_changes, h) != 0) * not(pending_matches(h)) then
      rebuild(h, i_get(g_pen_type, h), f_get(g_pen_lines, h))

fn init_slot(h: int): void = let
  val () = alive_set(h, true)
  val () = i_set(g_cur_type, h, ~1)
  val () = f_set(g_cur_x, h, 0.0f)
  val () = f_set(g_cur_y, h, 0.0f)
  val () = f_set(g_cur_ang, h, 0.0f)
  val () = f_set(g_cur_lines, h, 2.0f)
  val () = i_set(g_pen_type, h, SYM_VERTICAL)
  val () = f_set(g_pen_x, h, 0.0f)
  val () = f_set(g_pen_y, h, 0.0f)
  val () = f_set(g_pen_ang, h, 0.0f)
  val () = f_set(g_pen_lines, h, 2.0f)
  val () = i_set(g_changes, h, 1)
  val () = i_set(g_active, h, 0)
  val () = i_set(g_nmat, h, 0)
  val _ = grow_matrices(h, DEFAULT_NUM_MATRICES)
in
  minepaint_update_symmetry_state(h)
end

extern fun minepaint_symmetry_data_new(): int = "ext#minepaint_symmetry_data_new"
implement minepaint_symmetry_data_new() = let
  val h = find_free(0)
  val () = assertloc(h >= 0)
  val () = init_slot(h)
in
  h
end

extern fun minepaint_symmetry_data_destroy(h: int): void = "ext#minepaint_symmetry_data_destroy"
implement minepaint_symmetry_data_destroy(h) =
  if h >= 0 then alive_set(h, false)

extern fun minepaint_symmetry_set_pending(
  h: int, active: bool, center_x: float, center_y: float,
  symmetry_angle: float, symmetry_type: int, rot_symmetry_lines: int
): void = "ext#minepaint_symmetry_set_pending"
implement minepaint_symmetry_set_pending(
  h, active, center_x, center_y, symmetry_angle, symmetry_type, rot_symmetry_lines
) =
  if alive_get(h) then let
    val num_l = if rot_symmetry_lines < 2 then 2 else rot_symmetry_lines
    val () = i_set(g_active, h, if active then 1 else 0)
    val () = f_set(g_pen_x, h, center_x)
    val () = f_set(g_pen_y, h, center_y)
    val () = i_set(g_pen_type, h, symmetry_type)
    val () = f_set(g_pen_lines, h, g0int2float_int_float(num_l))
    val () = f_set(g_pen_ang, h, symmetry_angle)
  in
    i_set(g_changes, h, 1)
  end

extern fun minepaint_symmetry_active(h: int): int = "ext#minepaint_symmetry_active"
implement minepaint_symmetry_active(h) = i_get(g_active, h)

extern fun minepaint_symmetry_matrix_count(h: int): int = "ext#minepaint_symmetry_matrix_count"
implement minepaint_symmetry_matrix_count(h) = i_get(g_nmat, h)

extern fun minepaint_symmetry_current_type(h: int): int = "ext#minepaint_symmetry_current_type"
implement minepaint_symmetry_current_type(h) = i_get(g_cur_type, h)

extern fun minepaint_symmetry_current_x(h: int): float = "ext#minepaint_symmetry_current_x"
implement minepaint_symmetry_current_x(h) = f_get(g_cur_x, h)

extern fun minepaint_symmetry_current_y(h: int): float = "ext#minepaint_symmetry_current_y"
implement minepaint_symmetry_current_y(h) = f_get(g_cur_y, h)

extern fun minepaint_symmetry_current_angle(h: int): float = "ext#minepaint_symmetry_current_angle"
implement minepaint_symmetry_current_angle(h) = f_get(g_cur_ang, h)

extern fun minepaint_symmetry_current_lines(h: int): float = "ext#minepaint_symmetry_current_lines"
implement minepaint_symmetry_current_lines(h) = f_get(g_cur_lines, h)

fn write_out(out: &(@[float][9]), t: MinePaintTransform): void = let
  val () = out[0] := t.r0
  val () = out[1] := t.r1
  val () = out[2] := t.r2
  val () = out[3] := t.r3
  val () = out[4] := t.r4
  val () = out[5] := t.r5
  val () = out[6] := t.r6
  val () = out[7] := t.r7
in
  out[8] := t.r8
end

extern fun minepaint_symmetry_matrix_load(
  h: int, idx: int, out: &(@[float][9])
): void = "ext#minepaint_symmetry_matrix_load"
implement minepaint_symmetry_matrix_load(h, idx, out) =
  write_out(out, load_mat(h, idx))
