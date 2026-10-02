// src/draw_engine/matrix.dats
// Native ATS2 implementation of 3x3 Affine Transformation Matrix
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

typedef MyPaintTransform = @{
  r0= float, r1= float, r2= float,
  r3= float, r4= float, r5= float,
  r6= float, r7= float, r8= float
}

extern fun cosf(x: float): float = "mac#cosf"
extern fun sinf(x: float): float = "mac#sinf"
extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

fn get_cell(t: ptr, r: int, c: int): float = let
  val off = r * 3 + c
in
  $UN.ptr0_get<float>(ptr_add<float>(t, off))
end

fn set_cell(t: ptr, r: int, c: int, v: float): void = let
  val off = r * 3 + c
in
  $UN.ptr0_set<float>(ptr_add<float>(t, off), v)
end

extern fun mypaint_transform_unit(out: ptr): void = "ext#mypaint_transform_unit"
implement mypaint_transform_unit(out) = let
  fun loop_r(r: int): void =
    if r < 3 then let
      fun loop_c(c: int): void =
        if c < 3 then let
          val v = (if r = c then 1.0f else 0.0f)
          val () = set_cell(out, r, c, v)
        in
          loop_c(c + 1)
        end else ()
      val () = loop_c(0)
    in
      loop_r(r + 1)
    end else ()
in
  loop_r(0)
end

extern fun mypaint_transform_multiply(m1: ptr, m2: ptr, out: ptr): void = "ext#mypaint_transform_multiply"
implement mypaint_transform_multiply(m1, m2, out) = let
  var temp_buf: @[float][9]
  val temp_ptr = addr@(temp_buf)

  fun loop_r(r: int): void =
    if r < 3 then let
      fun loop_c(c: int): void =
        if c < 3 then let
          val v0 = get_cell(m1, 0, c) * get_cell(m2, r, 0)
          val v1 = get_cell(m1, 1, c) * get_cell(m2, r, 1)
          val v2 = get_cell(m1, 2, c) * get_cell(m2, r, 2)
          val sum = v0 + v1 + v2
          val () = set_cell(temp_ptr, r, c, sum)
        in
          loop_c(c + 1)
        end else ()
      val () = loop_c(0)
    in
      loop_r(r + 1)
    end else ()
  val () = loop_r(0)

  // Copy temp_buf into out
  fun loop_copy(i: int): void =
    if i < 9 then let
      val v = $UN.ptr0_get<float>(ptr_add<float>(temp_ptr, i))
      val () = $UN.ptr0_set<float>(ptr_add<float>(out, i), v)
    in
      loop_copy(i + 1)
    end else ()
in
  loop_copy(0)
end

extern fun mypaint_transform_point(t: ptr, x: float, y: float, xout: &float? >> float, yout: &float? >> float): void = "ext#mypaint_transform_point"
implement mypaint_transform_point(t, x, y, xout, yout) = let
  val r00 = get_cell(t, 0, 0)
  val r01 = get_cell(t, 0, 1)
  val r02 = get_cell(t, 0, 2)
  val r10 = get_cell(t, 1, 0)
  val r11 = get_cell(t, 1, 1)
  val r12 = get_cell(t, 1, 2)
  val () = xout := r00 * x + r01 * y + r02
  val () = yout := r10 * x + r11 * y + r12
in
  ()
end

extern fun mypaint_transform_rotate_cw(transform: ptr, angle_rad: float, out: ptr): void = "ext#mypaint_transform_rotate_cw"
implement mypaint_transform_rotate_cw(transform, angle_rad, out) = let
  var factor: @[float][9]
  val factor_ptr = addr@(factor)
  val () = mypaint_transform_unit(factor_ptr)
  val c = cosf(angle_rad)
  val s = sinf(angle_rad)
  val () = set_cell(factor_ptr, 0, 0, c)
  val () = set_cell(factor_ptr, 0, 1, s)
  val () = set_cell(factor_ptr, 1, 0, 0.0f - s)
  val () = set_cell(factor_ptr, 1, 1, c)
in
  mypaint_transform_multiply(transform, factor_ptr, out)
end

extern fun mypaint_transform_rotate_ccw(transform: ptr, angle_rad: float, out: ptr): void = "ext#mypaint_transform_rotate_ccw"
implement mypaint_transform_rotate_ccw(transform, angle_rad, out) = let
  var factor: @[float][9]
  val factor_ptr = addr@(factor)
  val () = mypaint_transform_unit(factor_ptr)
  val c = cosf(angle_rad)
  val s = sinf(angle_rad)
  val () = set_cell(factor_ptr, 0, 0, c)
  val () = set_cell(factor_ptr, 0, 1, 0.0f - s)
  val () = set_cell(factor_ptr, 1, 0, s)
  val () = set_cell(factor_ptr, 1, 1, c)
in
  mypaint_transform_multiply(transform, factor_ptr, out)
end

extern fun mypaint_transform_reflect(transform: ptr, angle_rad: float, out: ptr): void = "ext#mypaint_transform_reflect"
implement mypaint_transform_reflect(transform, angle_rad, out) = let
  var factor: @[float][9]
  val factor_ptr = addr@(factor)
  val () = mypaint_transform_unit(factor_ptr)
  val x = cosf(angle_rad)
  val y = sinf(angle_rad)
  val () = set_cell(factor_ptr, 0, 0, x * x - y * y)
  val () = set_cell(factor_ptr, 0, 1, 2.0f * x * y)
  val () = set_cell(factor_ptr, 1, 0, 2.0f * x * y)
  val () = set_cell(factor_ptr, 1, 1, y * y - x * x)
in
  mypaint_transform_multiply(transform, factor_ptr, out)
end

extern fun mypaint_transform_translate(transform: ptr, x: float, y: float, out: ptr): void = "ext#mypaint_transform_translate"
implement mypaint_transform_translate(transform, x, y, out) = let
  var factor: @[float][9]
  val factor_ptr = addr@(factor)
  val () = mypaint_transform_unit(factor_ptr)
  val () = set_cell(factor_ptr, 0, 2, x)
  val () = set_cell(factor_ptr, 1, 2, y)
in
  mypaint_transform_multiply(transform, factor_ptr, out)
end

extern fun mypaint_transform_new(): ptr = "ext#mypaint_transform_new"
implement mypaint_transform_new() = let
  val sz = sizeof<MyPaintTransform>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val () = mypaint_transform_unit(p)
in
  p
end

extern fun mypaint_transform_free(p: ptr): void = "ext#mypaint_transform_free"
implement mypaint_transform_free(p) =
  if p != the_null_ptr then free(p) else ()
