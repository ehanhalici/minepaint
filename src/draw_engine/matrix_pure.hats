// Value-level 3x3 affine transforms. Included by symmetry.dats and tiled_surface.dats.
// One definition of the arithmetic, no pointers.

extern fun cosf(x: float): float = "mac#cosf"
extern fun sinf(x: float): float = "mac#sinf"

typedef MinePaintTransform = @{
  r0= float, r1= float, r2= float,
  r3= float, r4= float, r5= float,
  r6= float, r7= float, r8= float
}

fn mat_unit(): MinePaintTransform =
  @{ r0= 1.0f, r1= 0.0f, r2= 0.0f,
     r3= 0.0f, r4= 1.0f, r5= 0.0f,
     r6= 0.0f, r7= 0.0f, r8= 1.0f }

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

fn mat_apply_x(t: MinePaintTransform, x: float, y: float): float =
  t.r0 * x + t.r1 * y + t.r2

fn mat_apply_y(t: MinePaintTransform, x: float, y: float): float =
  t.r3 * x + t.r4 * y + t.r5
