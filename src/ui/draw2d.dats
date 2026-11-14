#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "gl/gl_io.sats"
#include "sys/airlock.hats"

staload "gl/gl.dats"
staload "sys/libc.dats"

// --- Float Aritmetik Yardımcıları ---
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)

// --- 2D OpenGL Geometri Çizim Primitifleri (Pür ATS2) ---

extern fun gl_draw_rect(gio: !GL_IO | x: float, y: float, w: float, h: float, r: float, g: float, b: float, a: float): void = "ext#gl_draw_rect"
implement gl_draw_rect(gio | x, y, w, h, r, g, b, a) = let
  val () = glColor4f(gio | r, g, b, a)
  val () = glBegin(gio | GL_QUADS)
  val () = glVertex2f(gio | x, y)
  val () = glVertex2f(gio | f_add(x, w), y)
  val () = glVertex2f(gio | f_add(x, w), f_add(y, h))
  val () = glVertex2f(gio | x, f_add(y, h))
  val () = glEnd(gio | )
in () end

extern fun gl_draw_rect_outline(gio: !GL_IO | x: float, y: float, w: float, h: float, r: float, g: float, b: float, a: float): void = "ext#gl_draw_rect_outline"
implement gl_draw_rect_outline(gio | x, y, w, h, r, g, b, a) = let
  val () = glColor4f(gio | r, g, b, a)
  val () = glBegin(gio | GL_LINE_LOOP)
  val () = glVertex2f(gio | x, y)
  val () = glVertex2f(gio | f_add(x, w), y)
  val () = glVertex2f(gio | f_add(x, w), f_add(y, h))
  val () = glVertex2f(gio | x, f_add(y, h))
  val () = glEnd(gio | )
in () end

extern fun gl_draw_circle(gio: !GL_IO | cx: float, cy: float, radius: float, r: float, g: float, b: float, a: float): void = "ext#gl_draw_circle"
implement gl_draw_circle(gio | cx, cy, radius, r, g, b, a) = let
  val () = glColor4f(gio | r, g, b, a)
  val () = glBegin(gio | GL_TRIANGLE_FAN)
  val () = glVertex2f(gio | cx, cy)
  val segs = 20
  val PI = 3.14159265f
  val [m_seg:int] seg_ix = airlock_nat(segs)
  fun loop {i:nat | i <= m_seg + 1} .<m_seg + 1 - i>. (gio: !GL_IO | i: int(i)): void =
    if i <= seg_ix then let
      val theta = f_div(f_mul(f_mul(2.0f, PI), g0int2float(i)), g0int2float(segs))
      val vx = f_add(cx, f_mul(radius, cosf(theta)))
      val vy = f_add(cy, f_mul(radius, sinf(theta)))
      val () = glVertex2f(gio | vx, vy)
    in loop(gio | i + 1) end else ()
  val () = loop(gio | 0)
  val () = glEnd(gio | )
in () end
