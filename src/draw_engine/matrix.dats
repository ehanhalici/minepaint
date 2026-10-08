// src/draw_engine/matrix.dats
// 3x3 Affine dönüşüm matrisi: saf değer çekirdeği + C ABI pointer sınırı.
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "./matrix_pure.hats"

// --- Sınır (C ABI pointer katmanı) ---

extern castfn ptr2transform(p: ptr): ref(MinePaintTransform) = "mac#"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

fn mat_load(p: ptr): MinePaintTransform = let
  val t = ptr2transform(p)
in
  @{ r0= t->r0, r1= t->r1, r2= t->r2,
     r3= t->r3, r4= t->r4, r5= t->r5,
     r6= t->r6, r7= t->r7, r8= t->r8 }
end

fn mat_store(p: ptr, v: MinePaintTransform): void = let
  val t = ptr2transform(p)
  val () = t->r0 := v.r0
  val () = t->r1 := v.r1
  val () = t->r2 := v.r2
  val () = t->r3 := v.r3
  val () = t->r4 := v.r4
  val () = t->r5 := v.r5
  val () = t->r6 := v.r6
  val () = t->r7 := v.r7
  val () = t->r8 := v.r8
in () end

// Birim Matris
extern fun minepaint_transform_unit(out: ptr): void = "ext#minepaint_transform_unit"
implement minepaint_transform_unit(out_p) =
  if out_p != the_null_ptr then mat_store(out_p, mat_unit())

// Matris Çarpımı: out = m1 * m2
extern fun minepaint_transform_multiply(
  m1: ptr, m2: ptr, out: ptr
): void = "ext#minepaint_transform_multiply"
implement minepaint_transform_multiply(m1_p, m2_p, out_p) =
  if (m1_p != the_null_ptr) && (m2_p != the_null_ptr) && (out_p != the_null_ptr) then
    mat_store(out_p, mat_mul(mat_load(m1_p), mat_load(m2_p)))

// Nokta Dönüşümü
extern fun minepaint_transform_point(
  t: ptr, x: float, y: float,
  xout: &float? >> float, yout: &float? >> float
): void = "ext#minepaint_transform_point"
implement minepaint_transform_point(t_p, x, y, xout, yout) =
  if t_p != the_null_ptr then let
    val t = mat_load(t_p)
    val () = xout := mat_apply_x(t, x, y)
    val () = yout := mat_apply_y(t, x, y)
  in () end
  else {
    val () = xout := x
    val () = yout := y
  }

// Saat Yönünde Döndürme
extern fun minepaint_transform_rotate_cw(
  transform: ptr, angle_rad: float, out: ptr
): void = "ext#minepaint_transform_rotate_cw"
implement minepaint_transform_rotate_cw(transform, angle_rad, out) =
  if (transform != the_null_ptr) && (out != the_null_ptr) then
    mat_store(out, mat_mul(mat_rot_cw_factor(angle_rad), mat_load(transform)))

// Saat Yönünün Tersine Döndürme
extern fun minepaint_transform_rotate_ccw(
  transform: ptr, angle_rad: float, out: ptr
): void = "ext#minepaint_transform_rotate_ccw"
implement minepaint_transform_rotate_ccw(transform, angle_rad, out) =
  if (transform != the_null_ptr) && (out != the_null_ptr) then
    mat_store(out, mat_mul(mat_rot_ccw_factor(angle_rad), mat_load(transform)))

// Yansıma (Reflect)
extern fun minepaint_transform_reflect(
  transform: ptr, angle_rad: float, out: ptr
): void = "ext#minepaint_transform_reflect"
implement minepaint_transform_reflect(transform, angle_rad, out) =
  if (transform != the_null_ptr) && (out != the_null_ptr) then
    mat_store(out, mat_mul(mat_reflect_factor(angle_rad), mat_load(transform)))

// Öteleme (Translate)
extern fun minepaint_transform_translate(
  transform: ptr, x: float, y: float, out: ptr
): void = "ext#minepaint_transform_translate"
implement minepaint_transform_translate(transform, x, y, out) =
  if (transform != the_null_ptr) && (out != the_null_ptr) then
    mat_store(out, mat_mul(mat_translate_factor(x, y), mat_load(transform)))

// Tahsisat ve Yaşam Döngüsü
extern fun minepaint_transform_new(): ptr = "ext#minepaint_transform_new"
implement minepaint_transform_new() = let
  val p = malloc(sizeof<MinePaintTransform>)
  val () = assertloc(p > the_null_ptr)
  val () = minepaint_transform_unit(p)
in
  p
end

extern fun minepaint_transform_free(p: ptr): void = "ext#minepaint_transform_free"
implement minepaint_transform_free(p) =
  if p != the_null_ptr then free(p)
