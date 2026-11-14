// src/MyGLSurface.dats
// Native ATS2 OpenGL Surface for MinePaint Engine (Tiled FBOs & Dab Rendering)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "gl/gl_io.sats"
staload "sys/cast_box.sats"
#include "sys/airlock.hats"
staload "draw_engine/surface_target.sats"
staload "canvas/layer_box.sats"
staload "sys/libc.dats"
staload "gl/gl.dats"

// OpenGL Sabitleri
macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_DEPTH_TEST = $extval(int, "GL_DEPTH_TEST")
macdef GL_BLEND = $extval(int, "GL_BLEND")
macdef GL_ZERO = $extval(int, "GL_ZERO")
macdef GL_ONE = $extval(int, "GL_ONE")
macdef GL_SRC_ALPHA = $extval(int, "GL_SRC_ALPHA")
macdef GL_ONE_MINUS_SRC_ALPHA = $extval(int, "GL_ONE_MINUS_SRC_ALPHA")
macdef GL_TRIANGLE_FAN = $extval(int, "GL_TRIANGLE_FAN")

fn f2i(x: float): int = g0float2int_float_int(x)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_gt(a: float, b: float): bool = g0float_gt_float(a, b)
fn f_lt(a: float, b: float): bool = g0float_lt_float(a, b)

// Layer / Tile FFI Fonksiyonları
staload "canvas/layer_view.sats"

// --- Nokta Cizim Mantigi ---
fn setup_blend_and_color(gio: !GL_IO | 
  is_erasing: int, color_r: float, color_g: float, color_b: float, opaque: float
): void = let
  val () = glEnable(gio | GL_BLEND)
in
  if is_erasing > 0 then (glBlendFunc(gio | GL_ZERO, GL_ONE_MINUS_SRC_ALPHA); glColor4f(gio | 0.0f, 0.0f, 0.0f, 1.0f))
  else (glBlendFunc(gio | GL_ONE, GL_ONE_MINUS_SRC_ALPHA); glColor4f(gio | f_mul(color_r, opaque), f_mul(color_g, opaque), f_mul(color_b, opaque), opaque))
end

fn draw_dab_fan(gio: !GL_IO | 
  is_erasing: int, color_r: float, color_g: float, color_b: float,
  r_outer: float, a_inner: float, a_outer: float
): void = let
  val () = glBegin(gio | GL_TRIANGLE_FAN)
  val () = if is_erasing > 0 then glColor4f(gio | 0.0f, 0.0f, 0.0f, a_inner)
           else glColor4f(gio | f_mul(color_r, a_inner), f_mul(color_g, a_inner), f_mul(color_b, a_inner), a_inner)
  val () = glVertex2f(gio | 0.0f, 0.0f)
  val () = if is_erasing > 0 then glColor4f(gio | 0.0f, 0.0f, 0.0f, a_outer)
           else glColor4f(gio | f_mul(color_r, a_outer), f_mul(color_g, a_outer), f_mul(color_b, a_outer), a_outer)
  val PI = 3.14159265358979323846f
  fun loop {i:nat | i <= 17} .<17 - i>. (gio: !GL_IO | i: int(i)): void =
    if i <= 16 then let
      val theta = f_div(f_mul(f_mul(g0int2float(i), 2.0f), PI), 16.0f)
      val () = glVertex2f(gio | f_mul(r_outer, cosf(theta)), f_mul(r_outer, sinf(theta)))
    in loop(gio | i + 1) end else ()
  val () = loop(gio | 0)
  val () = glEnd(gio | )
in () end

fun print_dot(gio: !GL_IO | 
  is_erasing: int, radius: float, color_r: float, color_g: float, color_b: float, opaque: float, hardness: float
): void = let
  val () = setup_blend_and_color(gio | is_erasing, color_r, color_g, color_b, opaque)
  val actual_radius = if is_erasing > 0 then f_mul(radius, 4.0f) else radius
  val r_hard = f_mul(actual_radius, hardness)
  val () = if f_gt(hardness, 0.001f) then draw_dab_fan(gio | is_erasing, color_r, color_g, color_b, r_hard, opaque, opaque)
  val () = draw_dab_fan(gio | is_erasing, color_r, color_g, color_b, actual_radius, opaque, 0.0f)
in () end

fn apply_dab_transform(gio: !GL_IO | x: float, y: float, angle: float, aspect: float): void = let
  val () = glTranslatef(gio | x, y, 0.0f)
  val angle_deg = f_div(f_mul(angle, 180.0f), 3.14159265f)
  val () = if angle_deg != 0.0f then glRotatef(gio | angle_deg, 0.0f, 0.0f, 1.0f)
  val () = if f_gt(aspect, 1.0f) then glScalef(gio | 1.0f, f_div(1.0f, aspect), 1.0f)
           else if f_gt(aspect, 0.001f) && f_lt(aspect, 1.0f) then glScalef(gio | aspect, 1.0f, 1.0f)
           else ()
in () end

fn render_tile_dab(gio: !GL_IO | 
  tile: MpTile, is_erasing: int, x: float, y: float,
  radius: float, r: float, g: float, b: float,
  opaque: float, hardness: float, aspect: float, angle: float
): void =
  if tile_is_null(tile) = 0 then let
    val () = layer_bind_tile(gio | tile)
    val () = glDisable(gio | GL_TEXTURE_2D)
    val () = glDisable(gio | GL_DEPTH_TEST)
    val () = glPushMatrix(gio | )
    val () = apply_dab_transform(gio | x, y, angle, aspect)
    val () = print_dot(gio | is_erasing, radius, r, g, b, opaque, hardness)
    val () = glPopMatrix(gio | )
    val () = layer_unbind_tile(gio | )
  in () end else ()

fn calc_tile_bounds(x: float, y: float, actual_radius: float): @(int, int, int, int) = let
  val min_tx: int = f2i(floorf(f_div(f_sub(x, actual_radius), 1024.0f)))
  val max_tx: int = f2i(floorf(f_div(f_add(x, actual_radius), 1024.0f)))
  val min_ty: int = f2i(floorf(f_div(f_sub(y, actual_radius), 1024.0f)))
  val max_ty: int = f2i(floorf(f_div(f_add(y, actual_radius), 1024.0f)))
in
  @(min_tx, max_tx, min_ty, max_ty)
end

// Tile araligindaki her tile'a dab cizer. Katman kaniti disaridan odunc gelir (!LAYER_LIVE).
fun dab_on_tiles {lh:int} (
  pf: !LAYER_LIVE(lh), gio: !GL_IO | l: int(lh), is_erasing: int, x: float, y: float,
  radius: float, r: float, g: float, b: float,
  opaque: float, hardness: float, aspect: float, angle: float,
  min_tx: int, max_tx: int, min_ty: int, max_ty: int
): void = let
  val [lo_x:int] lx = airlock_int(min_tx)
  val [hi_x:int] hxv = airlock_int(max_tx)
  val [lo_y:int] ly = airlock_int(min_ty)
  val [hi_y:int] hyv = airlock_int(max_ty)
  fun loop_y {lh:int}{hy:int}{ty:int | ty <= hy + 1} .<hy + 1 - ty>. (
    pf: !LAYER_LIVE(lh), gio: !GL_IO | l: int(lh), hy: int(hy), tx: int, ty: int(ty)
  ): void =
    if ty <= hy then let
      val tile = if is_erasing > 0 then layer_find_tile(pf | l, tx, ty)
                 else layer_get_or_create_tile(pf, gio | l, tx, ty)
      val () = render_tile_dab(gio | tile, is_erasing, x, y, radius, r, g, b, opaque, hardness, aspect, angle)
    in loop_y(pf, gio | l, hy, tx, ty + 1) end else ()
  fun loop_x {lh:int}{hx:int}{tx:int | tx <= hx + 1} .<hx + 1 - tx>. (
    pf: !LAYER_LIVE(lh), gio: !GL_IO | l: int(lh), hx: int(hx), tx: int(tx)
  ): void =
    if tx <= hx then let
      val () = if ly <= hyv + 1 then loop_y(pf, gio | l, hyv, tx, ly) else ()
    in loop_x(pf, gio | l, hx, tx + 1) end else ()
in
  if lx <= hxv + 1 then loop_x(pf, gio | l, hxv, lx) else ()
end

// --- Dab cizimi: dogrudan tipli cagri (geri cagri/vtable yok) ---
implement draw_dab_on(gio | tgt, x, y, radius, r, g, b, opaque, hardness, aspect, angle): int = let
  val layer = tgt.layer
  val is_erasing = (case+ tgt.mode of | DrawErase() => 1 | DrawPaint() => 0): int
in
  if (layer_is_null(layer) = 0) && (radius > 0.00001f) then let
    val actual_radius = if is_erasing > 0 then f_mul(radius, 4.0f) else radius
    val @(min_tx, max_tx, min_ty, max_ty) = calc_tile_bounds(x, y, actual_radius)
    val (pf | ok, l) = layer_claim(layer)
  in
    if ok then let
      prval Some_v(live) = pf
      val () = dab_on_tiles(live, gio | l, is_erasing, x, y, radius, r, g, b, opaque, hardness, aspect, angle, min_tx, max_tx, min_ty, max_ty)
      val _ = layer_stash(live | l)
    in 1 end else let
      prval None_v() = pf
    in 1 end
  end
  else 1
end
