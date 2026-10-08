// src/draw_engine/matrix.dats
// Native ATS2 implementation of 3x3 Affine Transformation Matrix
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

typedef MinePaintTransform = @{
  r0= float, r1= float, r2= float,
  r3= float, r4= float, r5= float,
  r6= float, r7= float, r8= float
}

extern castfn ptr2transform(p: ptr): ref(MinePaintTransform) = "mac#"

extern fun cosf(x: float): float = "mac#cosf"
extern fun sinf(x: float): float = "mac#sinf"
extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

// Birim Matris (Identity Transform)
extern fun minepaint_transform_unit(out: ptr): void = "ext#minepaint_transform_unit"
implement minepaint_transform_unit(out_p) =
  if out_p != the_null_ptr then let
    val out = ptr2transform(out_p)
    val () = out->r0 := 1.0f
    val () = out->r1 := 0.0f
    val () = out->r2 := 0.0f
    val () = out->r3 := 0.0f
    val () = out->r4 := 1.0f
    val () = out->r5 := 0.0f
    val () = out->r6 := 0.0f
    val () = out->r7 := 0.0f
    val () = out->r8 := 1.0f
  in () end

// Matris Çarpımı: out = m1 * m2
extern fun minepaint_transform_multiply(
  m1: ptr, m2: ptr, out: ptr
): void = "ext#minepaint_transform_multiply"
implement minepaint_transform_multiply(m1_p, m2_p, out_p) =
  if (m1_p != the_null_ptr) && (m2_p != the_null_ptr) && (out_p != the_null_ptr) then let
    val m1 = ptr2transform(m1_p)
    val m2 = ptr2transform(m2_p)
    val out = ptr2transform(out_p)
    val r0 = m1->r0 * m2->r0 + m1->r1 * m2->r3 + m1->r2 * m2->r6
    val r1 = m1->r0 * m2->r1 + m1->r1 * m2->r4 + m1->r2 * m2->r7
    val r2 = m1->r0 * m2->r2 + m1->r1 * m2->r5 + m1->r2 * m2->r8

    val r3 = m1->r3 * m2->r0 + m1->r4 * m2->r3 + m1->r5 * m2->r6
    val r4 = m1->r3 * m2->r1 + m1->r4 * m2->r4 + m1->r5 * m2->r7
    val r5 = m1->r3 * m2->r2 + m1->r4 * m2->r5 + m1->r5 * m2->r8

    val r6 = m1->r6 * m2->r0 + m1->r7 * m2->r3 + m1->r8 * m2->r6
    val r7 = m1->r6 * m2->r1 + m1->r7 * m2->r4 + m1->r8 * m2->r7
    val r8 = m1->r6 * m2->r2 + m1->r7 * m2->r5 + m1->r8 * m2->r8

    val () = out->r0 := r0
    val () = out->r1 := r1
    val () = out->r2 := r2
    val () = out->r3 := r3
    val () = out->r4 := r4
    val () = out->r5 := r5
    val () = out->r6 := r6
    val () = out->r7 := r7
    val () = out->r8 := r8
  in () end

// Nokta Dönüşümü
extern fun minepaint_transform_point(
  t: ptr, x: float, y: float,
  xout: &float? >> float, yout: &float? >> float
): void = "ext#minepaint_transform_point"
implement minepaint_transform_point(t_p, x, y, xout, yout) =
  if t_p != the_null_ptr then let
    val t = ptr2transform(t_p)
    val () = xout := t->r0 * x + t->r1 * y + t->r2
    val () = yout := t->r3 * x + t->r4 * y + t->r5
  in () end
  else {
    val () = xout := x
    val () = yout := y
  }

// Saat Yönünde Döndürme
extern fun minepaint_transform_rotate_cw(
  transform: ptr, angle_rad: float, out: ptr
): void = "ext#minepaint_transform_rotate_cw"
implement minepaint_transform_rotate_cw(transform, angle_rad, out) = let
  val c = cosf(angle_rad)
  val s = sinf(angle_rad)
  var factor: MinePaintTransform
  val () = factor.r0 := c
  val () = factor.r1 := s
  val () = factor.r2 := 0.0f
  val () = factor.r3 := 0.0f - s
  val () = factor.r4 := c
  val () = factor.r5 := 0.0f
  val () = factor.r6 := 0.0f
  val () = factor.r7 := 0.0f
  val () = factor.r8 := 1.0f
in
  minepaint_transform_multiply(addr@factor, transform, out)
end

// Saat Yönünün Tersine Döndürme
extern fun minepaint_transform_rotate_ccw(
  transform: ptr, angle_rad: float, out: ptr
): void = "ext#minepaint_transform_rotate_ccw"
implement minepaint_transform_rotate_ccw(transform, angle_rad, out) = let
  val c = cosf(angle_rad)
  val s = sinf(angle_rad)
  var factor: MinePaintTransform
  val () = factor.r0 := c
  val () = factor.r1 := 0.0f - s
  val () = factor.r2 := 0.0f
  val () = factor.r3 := s
  val () = factor.r4 := c
  val () = factor.r5 := 0.0f
  val () = factor.r6 := 0.0f
  val () = factor.r7 := 0.0f
  val () = factor.r8 := 1.0f
in
  minepaint_transform_multiply(addr@factor, transform, out)
end

// Yansıma (Reflect)
extern fun minepaint_transform_reflect(
  transform: ptr, angle_rad: float, out: ptr
): void = "ext#minepaint_transform_reflect"
implement minepaint_transform_reflect(transform, angle_rad, out) = let
  val x = cosf(angle_rad)
  val y = sinf(angle_rad)
  var factor: MinePaintTransform
  val () = factor.r0 := x * x - y * y
  val () = factor.r1 := 2.0f * x * y
  val () = factor.r2 := 0.0f
  val () = factor.r3 := 2.0f * x * y
  val () = factor.r4 := y * y - x * x
  val () = factor.r5 := 0.0f
  val () = factor.r6 := 0.0f
  val () = factor.r7 := 0.0f
  val () = factor.r8 := 1.0f
in
  minepaint_transform_multiply(addr@factor, transform, out)
end

// Öteleme (Translate)
extern fun minepaint_transform_translate(
  transform: ptr, x: float, y: float, out: ptr
): void = "ext#minepaint_transform_translate"
implement minepaint_transform_translate(transform, x, y, out) = let
  var factor: MinePaintTransform
  val () = factor.r0 := 1.0f
  val () = factor.r1 := 0.0f
  val () = factor.r2 := x
  val () = factor.r3 := 0.0f
  val () = factor.r4 := 1.0f
  val () = factor.r5 := y
  val () = factor.r6 := 0.0f
  val () = factor.r7 := 0.0f
  val () = factor.r8 := 1.0f
in
  minepaint_transform_multiply(addr@factor, transform, out)
end

// Tahsisat ve Yaşam Döngüsü
extern fun minepaint_transform_new(): ptr = "ext#minepaint_transform_new"
implement minepaint_transform_new() = let
  val sz = sizeof<MinePaintTransform>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val () = minepaint_transform_unit(p)
in
  p
end

extern fun minepaint_transform_free(p: ptr): void = "ext#minepaint_transform_free"
implement minepaint_transform_free(p) =
  if p != the_null_ptr then free(p) else ()
