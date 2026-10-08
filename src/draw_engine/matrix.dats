// src/draw_engine/matrix.dats
// 3x3 Affine dönüşüm matrisi: saf değer çekirdeği + C ABI pointer sınırı.
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

typedef MinePaintTransform = @{
  r0= float, r1= float, r2= float,
  r3= float, r4= float, r5= float,
  r6= float, r7= float, r8= float
}

extern fun cosf(x: float): float = "mac#cosf"
extern fun sinf(x: float): float = "mac#sinf"

// --- Saf Çekirdek (pointer yok, yan etki yok) ---

fn mat_unit(): MinePaintTransform =
  @{ r0= 1.0f, r1= 0.0f, r2= 0.0f,
     r3= 0.0f, r4= 1.0f, r5= 0.0f,
     r6= 0.0f, r7= 0.0f, r8= 1.0f }

// out = m1 * m2
fn mat_mul(m1: MinePaintTransform, m2: MinePaintTransform): MinePaintTransform =
  @{ r0= m1.r0 * m2.r0 + m1.r1 * m2.r3 + m1.r2 * m2.r6,
     r1= m1.r0 * m2.r1 + m1.r1 * m2.r4 + m1.r2 * m2.r7,
     r2= m1.r0 * m2.r2 + m1.r1 * m2.r5 + m1.r2 * m2.r8,
     r3= m1.r3 * m2.r0 + m1.r4 * m2.r3 + m1.r5 * m2.r6,
     r4= m1.r3 * m2.r1 + m1.r4 * m2.r4 + m1.r5 * m2.r7,
     r5= m1.r3 * m2.r2 + m1.r4 * m2.r5 + m1.r5 * m2.r8,
     r6= m1.r6 * m2.r0 + m1.r7 * m2.r3 + m1.r8 * m2.r6,
     r7= m1.r6 * m2.r1 + m1.r7 * m2.r4 + m1.r8 * m2.r7,
     r8= m1.r6 * m2.r2 + m1.r7 * m2.r5 + m1.r8 * m2.r8 }

// Dönüşüm fabrikaları: her biri bir "çarpan" matrisi üretir (sonra mat_mul ile uygulanır).
fn mat_rot_cw_factor(angle: float): MinePaintTransform = let
  val c = cosf(angle)
  val s = sinf(angle)
in
  @{ r0= c, r1= s, r2= 0.0f,
     r3= 0.0f - s, r4= c, r5= 0.0f,
     r6= 0.0f, r7= 0.0f, r8= 1.0f }
end

fn mat_rot_ccw_factor(angle: float): MinePaintTransform = let
  val c = cosf(angle)
  val s = sinf(angle)
in
  @{ r0= c, r1= 0.0f - s, r2= 0.0f,
     r3= s, r4= c, r5= 0.0f,
     r6= 0.0f, r7= 0.0f, r8= 1.0f }
end

fn mat_reflect_factor(angle: float): MinePaintTransform = let
  val x = cosf(angle)
  val y = sinf(angle)
in
  @{ r0= x * x - y * y, r1= 2.0f * x * y, r2= 0.0f,
     r3= 2.0f * x * y, r4= y * y - x * x, r5= 0.0f,
     r6= 0.0f, r7= 0.0f, r8= 1.0f }
end

fn mat_translate_factor(x: float, y: float): MinePaintTransform =
  @{ r0= 1.0f, r1= 0.0f, r2= x,
     r3= 0.0f, r4= 1.0f, r5= y,
     r6= 0.0f, r7= 0.0f, r8= 1.0f }

// Nokta dönüşümü: (x', y') değerini döndürür.
fn mat_apply_x(t: MinePaintTransform, x: float, y: float): float =
  t.r0 * x + t.r1 * y + t.r2

fn mat_apply_y(t: MinePaintTransform, x: float, y: float): float =
  t.r3 * x + t.r4 * y + t.r5

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
