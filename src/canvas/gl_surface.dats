// src/MyGLSurface.dats
// Native ATS2 OpenGL Surface for MinePaint Engine (Tiled FBOs & Dab Rendering)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

// OpenGL Sabitleri
macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_DEPTH_TEST = $extval(int, "GL_DEPTH_TEST")
macdef GL_BLEND = $extval(int, "GL_BLEND")
macdef GL_ZERO = $extval(int, "GL_ZERO")
macdef GL_ONE = $extval(int, "GL_ONE")
macdef GL_SRC_ALPHA = $extval(int, "GL_SRC_ALPHA")
macdef GL_ONE_MINUS_SRC_ALPHA = $extval(int, "GL_ONE_MINUS_SRC_ALPHA")
macdef GL_TRIANGLE_FAN = $extval(int, "GL_TRIANGLE_FAN")

// OpenGL Fonksiyonları
extern fun glDisable(cap: int): void = "mac#"
extern fun glEnable(cap: int): void = "mac#"
extern fun glBlendFunc(sfactor: int, dfactor: int): void = "mac#"
extern fun glColor4f(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glTranslatef(x: float, y: float, z: float): void = "mac#"
extern fun glRotatef(angle: float, x: float, y: float, z: float): void = "mac#"
extern fun glScalef(x: float, y: float, z: float): void = "mac#"
extern fun glBegin(mode: int): void = "mac#"
extern fun glEnd(): void = "mac#"
extern fun glVertex2f(x: float, y: float): void = "mac#"

// Matematik ve Bellek Fonksiyonları
extern fun cosf(x: float): float = "mac#"
extern fun sinf(x: float): float = "mac#"
extern fun expf(x: float): float = "mac#"
extern fun floorf(x: float): float = "mac#"
fn f2i(x: float): int = g0float2int_float_int(x)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_gt(a: float, b: float): bool = g0float_gt_float(a, b)
fn f_lt(a: float, b: float): bool = g0float_lt_float(a, b)

extern fun malloc(size: size_t): ptr = "mac#"
extern fun free(p: ptr): void = "mac#"
extern fun memset(p: ptr, value: int, size: size_t): ptr = "mac#"

// Layer / Tile FFI Fonksiyonları
extern fun layer_find_tile(layer: ptr, tx: int, ty: int): ptr = "ext#layer_find_tile"
extern fun layer_get_or_create_tile(layer: ptr, tx: int, ty: int): ptr = "ext#layer_get_or_create_tile"
extern fun layer_bind_tile(tile: ptr): void = "ext#layer_bind_tile"
extern fun layer_unbind_tile(): void = "ext#layer_unbind_tile"

// LibMinePaint Tipleri
typedef MinePaintDrawDabFunc = (
  ptr, float, float, float, float, float, float, 
  float, float, float, float, float, float, 
  float, float, float, float, float
) -> int

typedef MinePaintSurface_Record = @{
  draw_dab= MinePaintDrawDabFunc,
  get_color= ptr,
  begin_atomic= ptr,
  end_atomic= ptr,
  destroy= ptr,
  save_png= ptr,
  refcount= int
}

typedef MyGLSurface_Record = @{
  parent= MinePaintSurface_Record,
  is_erasing= int,
  layer= ptr
}

// Surface API İmzaları
typedef glsurface_vtype = ptr

extern fun draw_dab_callback : MinePaintDrawDabFunc = "ext#draw_dab_callback"
extern fun glsurface_create(): glsurface_vtype = "ext#glsurface_create"
extern fun glsurface_destroy(s: glsurface_vtype): void = "ext#glsurface_destroy"
extern fun glsurface_set_erasing(s: glsurface_vtype, v: int): void = "ext#glsurface_set_erasing"
extern fun mygl_surface_set_layer(s: glsurface_vtype, layer: ptr): void = "ext#mygl_surface_set_layer"
extern fun mygl_surface_flush_batch(s: ptr): void = "ext#mygl_surface_flush_batch"

// Eski adlar ile de uyumluluk için C FFI sembolleri
extern fun mygl_surface_create_c(): ptr = "ext#mygl_surface_create_c"
extern fun mygl_surface_destroy_c(s: ptr): void = "ext#mygl_surface_destroy_c"
extern fun mygl_surface_set_erasing(s: ptr, v: int): void = "ext#mygl_surface_set_erasing"

implement mygl_surface_flush_batch(s) = ()

// --- Nokta Çizim Mantığı ---
fun print_dot(
  is_erasing: int, radius: float, color_r: float, color_g: float, color_b: float, opaque: float, hardness: float
): void = let
  val () = glEnable(GL_BLEND)
  val actual_radius = if is_erasing > 0 then f_mul(radius, 4.0f) else radius

  val () = if is_erasing > 0 then let
    val () = glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(0.0f, 0.0f, 0.0f, 1.0f)
  in () end else let
    val () = glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(f_mul(color_r, opaque), f_mul(color_g, opaque), f_mul(color_b, opaque), opaque)
  in () end

  val segs = 16
  val PI = 3.14159265358979323846f

  fun draw_segment(r_inner: float, r_outer: float, a_inner: float, a_outer: float): void = let
    val () = glBegin(GL_TRIANGLE_FAN)
    val () = if is_erasing > 0 then glColor4f(0.0f, 0.0f, 0.0f, a_inner)
             else glColor4f(f_mul(color_r, a_inner), f_mul(color_g, a_inner), f_mul(color_b, a_inner), a_inner)
    val () = glVertex2f(0.0f, 0.0f)

    val () = if is_erasing > 0 then glColor4f(0.0f, 0.0f, 0.0f, a_outer)
             else glColor4f(f_mul(color_r, a_outer), f_mul(color_g, a_outer), f_mul(color_b, a_outer), a_outer)

    fun loop(i: int): void =
      if i <= segs then let
        val theta = f_div(f_mul(f_mul(g0int2float(i), 2.0f), PI), g0int2float(segs))
        val () = glVertex2f(f_mul(r_outer, cosf(theta)), f_mul(r_outer, sinf(theta)))
      in loop(i + 1) end else ()

    val () = loop(0)
    val () = glEnd()
  in () end

  val r_hard = f_mul(actual_radius, hardness)
  val () = if f_gt(hardness, 0.001f) then draw_segment(0.0f, r_hard, opaque, opaque)
  val () = draw_segment(r_hard, actual_radius, opaque, 0.0f)
in () end

// --- Dab Çizim Callback'i (Tiled Infinite Canvas Entegrasyonu) ---
implement draw_dab_callback(self, x, y, radius, r, g, b, opaque, hardness, softness, alpha_eraser, aspect, angle, lock_alpha, colorize, posterize, posterize_num, paint): int = let
  val surf = $UN.cast{ref(MyGLSurface_Record)}(self)
  val layer = surf->layer
  val is_erasing = surf->is_erasing
in
  if (layer != the_null_ptr) && (radius > 0.00001f) then let
    val actual_radius = if is_erasing > 0 then f_mul(radius, 4.0f) else radius
    val min_tx: int = f2i(floorf(f_div(f_sub(x, actual_radius), 1024.0f)))
    val max_tx: int = f2i(floorf(f_div(f_add(x, actual_radius), 1024.0f)))
    val min_ty: int = f2i(floorf(f_div(f_sub(y, actual_radius), 1024.0f)))
    val max_ty: int = f2i(floorf(f_div(f_add(y, actual_radius), 1024.0f)))

    fun loop_y(tx: int, ty: int): void =
      if ty <= max_ty then let
        val tile =
          if is_erasing > 0 then layer_find_tile(layer, tx, ty)
          else layer_get_or_create_tile(layer, tx, ty)

        val tile_p = $UN.cast{ptr}(tile)
        val () = if tile_p > the_null_ptr then let
          val () = layer_bind_tile(tile)
          val () = glDisable(GL_TEXTURE_2D)
          val () = glDisable(GL_DEPTH_TEST)
          val () = glPushMatrix()
          val () = glTranslatef(x, y, 0.0f)

          val angle_deg = f_div(f_mul(angle, 180.0f), 3.14159265f)
          val () = if angle_deg != 0.0f then glRotatef(angle_deg, 0.0f, 0.0f, 1.0f)

          val () = if f_gt(aspect, 1.0f) then glScalef(1.0f, f_div(1.0f, aspect), 1.0f)
                   else if f_gt(aspect, 0.001f) && f_lt(aspect, 1.0f) then glScalef(aspect, 1.0f, 1.0f)
                   else ()

          val () = print_dot(is_erasing, radius, r, g, b, opaque, hardness)
          val () = glPopMatrix()
          val () = layer_unbind_tile()
        in () end
      in
        loop_y(tx, ty + 1)
      end else ()

    fun loop_x(tx: int): void =
      if tx <= max_tx then let
        val () = loop_y(tx, min_ty)
      in
        loop_x(tx + 1)
      end else ()

    val () = loop_x(min_tx)
  in () end else ();
  1
end

// --- Yaşam Döngüsü (Lifecycle) ---
implement glsurface_create() = let
  val sz = $UN.cast{size_t}(sizeof<MyGLSurface_Record>)
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val p1 = $UN.cast{ref(MyGLSurface_Record)}(p)
  val () = p1->parent.draw_dab := draw_dab_callback
  val () = p1->parent.refcount := 1
  val () = p1->is_erasing := 0
  val () = p1->layer := the_null_ptr
in
  $UN.cast{glsurface_vtype}(p)
end

implement glsurface_destroy(s) = let
  val () = free($UN.cast{ptr}(s))
in () end

implement glsurface_set_erasing(s, v) = let
  val surf = $UN.cast{ref(MyGLSurface_Record)}(s)
  val () = surf->is_erasing := v
in () end

implement mygl_surface_set_layer(s, layer) = let
  val surf = $UN.cast{ref(MyGLSurface_Record)}(s)
  val () = surf->layer := layer
in () end

// C Uyumluluk Wrapper'ları
implement mygl_surface_create_c() = glsurface_create()
implement mygl_surface_destroy_c(s) = glsurface_destroy(s)
implement mygl_surface_set_erasing(s, v) = glsurface_set_erasing(s, v)
