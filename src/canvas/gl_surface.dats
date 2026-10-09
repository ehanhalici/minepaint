// src/MyGLSurface.dats
// Native ATS2 OpenGL Surface for MinePaint Engine (Tiled FBOs & Dab Rendering)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "draw_engine/surface_box.sats"
staload "canvas/layer_box.sats"

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

// Layer / Tile FFI Fonksiyonları
extern fun layer_find_tile(layer: MpLayer, tx: int, ty: int): MpTile = "ext#layer_find_tile"
extern fun layer_get_or_create_tile(layer: MpLayer, tx: int, ty: int): MpTile = "ext#layer_get_or_create_tile"
extern fun layer_bind_tile(tile: MpTile): void = "ext#layer_bind_tile"
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
  layer= MpLayer
}

extern fun view_glsurf(p: ptr): ref(MyGLSurface_Record) = "mac#mp_id_ptr"

typedef glsurface_vtype = MpSurface

extern fun draw_dab_callback : MinePaintDrawDabFunc = "ext#draw_dab_callback"
extern fun glsurface_create(): glsurface_vtype = "ext#glsurface_create"
extern fun glsurface_destroy(s: glsurface_vtype): void = "ext#glsurface_destroy"
extern fun glsurface_set_erasing(s: glsurface_vtype, v: int): void = "ext#glsurface_set_erasing"
extern fun mygl_surface_set_layer(s: glsurface_vtype, layer: MpLayer): void = "ext#mygl_surface_set_layer"
extern fun mygl_surface_flush_batch(s: ptr): void = "ext#mygl_surface_flush_batch"
implement mygl_surface_flush_batch(s) = ()

// --- Nokta Cizim Mantigi ---
fn setup_blend_and_color(
  is_erasing: int, color_r: float, color_g: float, color_b: float, opaque: float
): void = let
  val () = glEnable(GL_BLEND)
in
  if is_erasing > 0 then (glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA); glColor4f(0.0f, 0.0f, 0.0f, 1.0f))
  else (glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); glColor4f(f_mul(color_r, opaque), f_mul(color_g, opaque), f_mul(color_b, opaque), opaque))
end

fn draw_dab_fan(
  is_erasing: int, color_r: float, color_g: float, color_b: float,
  r_outer: float, a_inner: float, a_outer: float
): void = let
  val () = glBegin(GL_TRIANGLE_FAN)
  val () = if is_erasing > 0 then glColor4f(0.0f, 0.0f, 0.0f, a_inner)
           else glColor4f(f_mul(color_r, a_inner), f_mul(color_g, a_inner), f_mul(color_b, a_inner), a_inner)
  val () = glVertex2f(0.0f, 0.0f)
  val () = if is_erasing > 0 then glColor4f(0.0f, 0.0f, 0.0f, a_outer)
           else glColor4f(f_mul(color_r, a_outer), f_mul(color_g, a_outer), f_mul(color_b, a_outer), a_outer)
  val PI = 3.14159265358979323846f
  fun loop(i: int): void =
    if i <= 16 then let
      val theta = f_div(f_mul(f_mul(g0int2float(i), 2.0f), PI), 16.0f)
      val () = glVertex2f(f_mul(r_outer, cosf(theta)), f_mul(r_outer, sinf(theta)))
    in loop(i + 1) end else ()
  val () = loop(0)
  val () = glEnd()
in () end

fun print_dot(
  is_erasing: int, radius: float, color_r: float, color_g: float, color_b: float, opaque: float, hardness: float
): void = let
  val () = setup_blend_and_color(is_erasing, color_r, color_g, color_b, opaque)
  val actual_radius = if is_erasing > 0 then f_mul(radius, 4.0f) else radius
  val r_hard = f_mul(actual_radius, hardness)
  val () = if f_gt(hardness, 0.001f) then draw_dab_fan(is_erasing, color_r, color_g, color_b, r_hard, opaque, opaque)
  val () = draw_dab_fan(is_erasing, color_r, color_g, color_b, actual_radius, opaque, 0.0f)
in () end

fn apply_dab_transform(x: float, y: float, angle: float, aspect: float): void = let
  val () = glTranslatef(x, y, 0.0f)
  val angle_deg = f_div(f_mul(angle, 180.0f), 3.14159265f)
  val () = if angle_deg != 0.0f then glRotatef(angle_deg, 0.0f, 0.0f, 1.0f)
  val () = if f_gt(aspect, 1.0f) then glScalef(1.0f, f_div(1.0f, aspect), 1.0f)
           else if f_gt(aspect, 0.001f) && f_lt(aspect, 1.0f) then glScalef(aspect, 1.0f, 1.0f)
           else ()
in () end

fn render_tile_dab(
  tile: MpTile, is_erasing: int, x: float, y: float,
  radius: float, r: float, g: float, b: float,
  opaque: float, hardness: float, aspect: float, angle: float
): void =
  if tile_is_null(tile) = 0 then let
    val () = layer_bind_tile(tile)
    val () = glDisable(GL_TEXTURE_2D)
    val () = glDisable(GL_DEPTH_TEST)
    val () = glPushMatrix()
    val () = apply_dab_transform(x, y, angle, aspect)
    val () = print_dot(is_erasing, radius, r, g, b, opaque, hardness)
    val () = glPopMatrix()
    val () = layer_unbind_tile()
  in () end else ()

fn calc_tile_bounds(x: float, y: float, actual_radius: float): @(int, int, int, int) = let
  val min_tx: int = f2i(floorf(f_div(f_sub(x, actual_radius), 1024.0f)))
  val max_tx: int = f2i(floorf(f_div(f_add(x, actual_radius), 1024.0f)))
  val min_ty: int = f2i(floorf(f_div(f_sub(y, actual_radius), 1024.0f)))
  val max_ty: int = f2i(floorf(f_div(f_add(y, actual_radius), 1024.0f)))
in
  @(min_tx, max_tx, min_ty, max_ty)
end

// --- Dab Çizim Callback'i ---
implement draw_dab_callback(self, x, y, radius, r, g, b, opaque, hardness, softness, alpha_eraser, aspect, angle, lock_alpha, colorize, posterize, posterize_num, paint): int = let
  val surf = view_glsurf(self)
  val layer = surf->layer
  val is_erasing = surf->is_erasing
in
  if (layer_is_null(layer) = 0) && (radius > 0.00001f) then let
    val actual_radius = if is_erasing > 0 then f_mul(radius, 4.0f) else radius
    val @(min_tx, max_tx, min_ty, max_ty) = calc_tile_bounds(x, y, actual_radius)
    fun loop_y(tx: int, ty: int): void =
      if ty <= max_ty then let
        val tile = if is_erasing > 0 then layer_find_tile(layer, tx, ty)
                   else layer_get_or_create_tile(layer, tx, ty)
        val () = render_tile_dab(tile, is_erasing, x, y, radius, r, g, b, opaque, hardness, aspect, angle)
      in loop_y(tx, ty + 1) end else ()

    fun loop_x(tx: int): void =
      if tx <= max_tx then (loop_y(tx, min_ty); loop_x(tx + 1)) else ()
    val () = loop_x(min_tx)
  in 1 end
  else 1
end

// --- Yasam Dongusu (Lifecycle) ---
implement glsurface_create() = let
  val p = malloc(sizeof<MyGLSurface_Record>)
  val () = assertloc(p > the_null_ptr)
  val p1 = view_glsurf(p)
  val () = p1->parent.draw_dab := draw_dab_callback
  val () = p1->parent.refcount := 1
  val () = p1->is_erasing := 0
  val () = p1->layer := layer_none()
in
  mp_surface_of_ptr(p)
end

implement glsurface_destroy(s) = free(mp_surface_to_ptr(s))

implement glsurface_set_erasing(s, v) = let
  val surf = view_glsurf(mp_surface_to_ptr(s))
in
  surf->is_erasing := v
end

implement mygl_surface_set_layer(s, layer) = let
  val surf = view_glsurf(mp_surface_to_ptr(s))
in
  surf->layer := layer
end
