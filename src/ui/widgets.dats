// src/ui/widgets.dats
// Native ATS2 Implementation of GUI Widgets (Sliders, Color Pickers, Vector Font)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

// --- Harici Kütüphane Başlıkları (Sadece OpenGL ve libc snprintf) ---
%{^
#include <GL/gl.h>
#include <math.h>
#include <stdio.h>

static inline void format_slider_val(char* buf, int sz, float v) {
    snprintf(buf, sz, "%.2f", v);
}

static struct {
    float cur_r, cur_g, cur_b;
    float cur_h, cur_s, cur_v;
    int active_drag;
    float val0, val1, val2, val3;
} g_ui_state = { 0.73f, 0.73f, 0.73f, 0.0f, 0.0f, 0.73f, -1, 1.2f, 0.1f, 0.9f, 3.0f };

static inline void* get_g_ui_ptr(void) { return &g_ui_state; }
%}

extern fun format_slider_val(buf: ptr, sz: int, v: float): void = "mac#"
extern fun get_g_ui_ptr(): ptr = "mac#"

// OpenGL Sabitleri
macdef GL_QUADS = $extval(int, "GL_QUADS")
macdef GL_QUAD_STRIP = $extval(int, "GL_QUAD_STRIP")
macdef GL_LINE_LOOP = $extval(int, "GL_LINE_LOOP")
macdef GL_TRIANGLE_FAN = $extval(int, "GL_TRIANGLE_FAN")
macdef GL_POINTS = $extval(int, "GL_POINTS")
macdef GL_DEPTH_TEST = $extval(int, "GL_DEPTH_TEST")
macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_BLEND = $extval(int, "GL_BLEND")
macdef GL_SRC_ALPHA = $extval(int, "GL_SRC_ALPHA")
macdef GL_ONE_MINUS_SRC_ALPHA = $extval(int, "GL_ONE_MINUS_SRC_ALPHA")

// OpenGL Fonksiyonları
extern fun glDisable(cap: int): void = "mac#"
extern fun glEnable(cap: int): void = "mac#"
extern fun glBlendFunc(sfactor: int, dfactor: int): void = "mac#"
extern fun glColor3f(r: float, g: float, b: float): void = "mac#"
extern fun glColor4f(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glPointSize(sz: float): void = "mac#"
extern fun glBegin(mode: int): void = "mac#"
extern fun glEnd(): void = "mac#"
extern fun glVertex2f(x: float, y: float): void = "mac#"
extern fun cosf(x: float): float = "mac#"
extern fun sinf(x: float): float = "mac#"

extern fun canvas_set_brush_setting(p: ptr, id: int, v: float): void = "ext#canvas_set_brush_setting"
extern fun canvas_set_brush_color(p: ptr, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"

// Float Aritmetik Yardımcıları
fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_min(a: float, b: float): float = if g0float_lt(a, b) then a else b
fn f_max(a: float, b: float): float = if g0float_gt(a, b) then a else b
fn f_clamp(x: float, lo: float, hi: float): float = f_max(lo, f_min(hi, x))
fn f_lt(a: float, b: float): bool = g0float_lt(a, b)
fn f_gt(a: float, b: float): bool = g0float_gt(a, b)
fn f_lte(a: float, b: float): bool = g0float_lte(a, b)
fn f_gte(a: float, b: float): bool = g0float_gte(a, b)

// --- 2D Çizim Yardımcıları (Pür ATS2) ---
fun gl_draw_rect(x: float, y: float, w: float, h: float, r: float, g: float, b: float, a: float): void = let
  val () = glColor4f(r, g, b, a)
  val () = glBegin(GL_QUADS)
  val () = glVertex2f(x, y)
  val () = glVertex2f(f_add(x, w), y)
  val () = glVertex2f(f_add(x, w), f_add(y, h))
  val () = glVertex2f(x, f_add(y, h))
  val () = glEnd()
in () end

fun gl_draw_rect_outline(x: float, y: float, w: float, h: float, r: float, g: float, b: float, a: float): void = let
  val () = glColor4f(r, g, b, a)
  val () = glBegin(GL_LINE_LOOP)
  val () = glVertex2f(x, y)
  val () = glVertex2f(f_add(x, w), y)
  val () = glVertex2f(f_add(x, w), f_add(y, h))
  val () = glVertex2f(x, f_add(y, h))
  val () = glEnd()
in () end

fun gl_draw_circle(cx: float, cy: float, radius: float, r: float, g: float, b: float, a: float): void = let
  val () = glColor4f(r, g, b, a)
  val () = glBegin(GL_TRIANGLE_FAN)
  val () = glVertex2f(cx, cy)
  val segs = 20
  val PI = 3.14159265f
  fun loop(i: int): void =
    if i <= segs then let
      val theta = f_div(f_mul(f_mul(2.0f, PI), g0int2float(i)), g0int2float(segs))
      val vx = f_add(cx, f_mul(radius, cosf(theta)))
      val vy = f_add(cy, f_mul(radius, sinf(theta)))
      val () = glVertex2f(vx, vy)
    in loop(i + 1) end else ()
  val () = loop(0)
  val () = glEnd()
in () end

// --- 5x7 Vektör Font Tablosu (Pür ATS2) ---
fun font_get_col(c: int, col: int): int =
  case+ c of
  | 32 => 0 // ' '
  | 46 => if col = 1 || col = 2 then 0x60 else 0 // '.'
  | 58 => if col = 1 || col = 2 then 0x36 else 0 // ':'
  | 45 => 0x08 // '-'
  | 37 => // '%'
    if col = 0 then 0x63 else if col = 1 then 0x33 else if col = 2 then 0x18 else if col = 3 then 0x0c else 0x66
  | 48 => // '0'
    if col = 0 then 0x3e else if col = 1 then 0x51 else if col = 2 then 0x49 else if col = 3 then 0x45 else 0x3e
  | 49 => // '1'
    if col = 1 then 0x42 else if col = 2 then 0x7f else if col = 3 then 0x40 else 0x00
  | 50 => // '2'
    if col = 0 then 0x42 else if col = 1 then 0x61 else if col = 2 then 0x51 else if col = 3 then 0x49 else 0x46
  | 51 => // '3'
    if col = 0 then 0x21 else if col = 1 then 0x41 else if col = 2 then 0x45 else if col = 3 then 0x4b else 0x31
  | 52 => // '4'
    if col = 0 then 0x18 else if col = 1 then 0x14 else if col = 2 then 0x12 else if col = 3 then 0x7f else 0x10
  | 53 => // '5'
    if col = 0 then 0x27 else if col = 1 then 0x45 else if col = 2 then 0x45 else if col = 3 then 0x45 else 0x39
  | 54 => // '6'
    if col = 0 then 0x3c else if col = 1 then 0x4a else if col = 2 then 0x49 else if col = 3 then 0x49 else 0x30
  | 55 => // '7'
    if col = 0 then 0x01 else if col = 1 then 0x71 else if col = 2 then 0x09 else if col = 3 then 0x05 else 0x03
  | 56 => // '8'
    if col = 0 then 0x36 else if col = 1 then 0x49 else if col = 2 then 0x49 else if col = 3 then 0x49 else 0x36
  | 57 => // '9'
    if col = 0 then 0x06 else if col = 1 then 0x49 else if col = 2 then 0x49 else if col = 3 then 0x29 else 0x1e
  | 65 => // 'A'
    if col = 0 then 0x7c else if col = 1 then 0x12 else if col = 2 then 0x11 else if col = 3 then 0x12 else 0x7c
  | 66 => // 'B'
    if col = 0 then 0x7f else if col = 1 then 0x49 else if col = 2 then 0x49 else if col = 3 then 0x49 else 0x36
  | 67 => // 'C'
    if col = 0 then 0x3e else if col = 1 then 0x41 else if col = 2 then 0x41 else if col = 3 then 0x41 else 0x22
  | 68 => // 'D'
    if col = 0 then 0x7f else if col = 1 then 0x41 else if col = 2 then 0x41 else if col = 3 then 0x22 else 0x1c
  | 69 => // 'E'
    if col = 0 then 0x7f else if col = 1 then 0x49 else if col = 2 then 0x49 else if col = 3 then 0x49 else 0x41
  | 70 => // 'F'
    if col = 0 then 0x7f else if col = 1 then 0x09 else if col = 2 then 0x09 else if col = 3 then 0x09 else 0x01
  | 71 => // 'G'
    if col = 0 then 0x3e else if col = 1 then 0x41 else if col = 2 then 0x49 else if col = 3 then 0x49 else 0x7a
  | 72 => // 'H'
    if col = 0 then 0x7f else if col = 1 then 0x08 else if col = 2 then 0x08 else if col = 3 then 0x08 else 0x7f
  | 73 => // 'I'
    if col = 1 then 0x41 else if col = 2 then 0x7f else if col = 3 then 0x41 else 0x00
  | 74 => // 'J'
    if col = 0 then 0x20 else if col = 1 then 0x40 else if col = 2 then 0x41 else if col = 3 then 0x3f else 0x01
  | 75 => // 'K'
    if col = 0 then 0x7f else if col = 1 then 0x08 else if col = 2 then 0x14 else if col = 3 then 0x22 else 0x41
  | 76 => // 'L'
    if col = 0 then 0x7f else 0x40
  | 77 => // 'M'
    if col = 0 then 0x7f else if col = 1 then 0x02 else if col = 2 then 0x0c else if col = 3 then 0x02 else 0x7f
  | 78 => // 'N'
    if col = 0 then 0x7f else if col = 1 then 0x04 else if col = 2 then 0x08 else if col = 3 then 0x10 else 0x7f
  | 79 => // 'O'
    if col = 0 then 0x3e else if col = 1 then 0x41 else if col = 2 then 0x41 else if col = 3 then 0x41 else 0x3e
  | 80 => // 'P'
    if col = 0 then 0x7f else if col = 1 then 0x09 else if col = 2 then 0x09 else if col = 3 then 0x09 else 0x06
  | 82 => // 'R'
    if col = 0 then 0x7f else if col = 1 then 0x09 else if col = 2 then 0x19 else if col = 3 then 0x29 else 0x46
  | 83 => // 'S'
    if col = 0 then 0x46 else if col = 1 then 0x49 else if col = 2 then 0x49 else if col = 3 then 0x49 else 0x31
  | 84 => // 'T'
    if col = 2 then 0x7f else 0x01
  | 85 => // 'U'
    if col = 0 || col = 4 then 0x3f else 0x40
  | 86 => // 'V'
    if col = 0 || col = 4 then 0x1f else if col = 1 || col = 3 then 0x20 else 0x40
  | 89 => // 'Y'
    if col = 0 || col = 4 then 0x07 else if col = 1 || col = 3 then 0x08 else 0x70
  | _ => 0

fun gl_draw_string(x: float, y: float, scale: float, str: string, r: float, g: float, b: float): void = let
  val () = glColor3f(r, g, b)
  val () = glBegin(GL_POINTS)
  val p_str = $UN.cast{ptr}(str)
  fun loop(p: ptr, cur_x: float): void = let
    val ch = $UN.ptr0_get<char>(p)
    val code = char2int0(ch)
  in
    if code != 0 then let
      val upper = if code >= 97 && code <= 122 then code - 32 else code
      fun col_loop(col: int): void =
        if col < 5 then let
          val bits = font_get_col(upper, col)
          fun row_loop(row: int, p2: int): void =
            if row < 7 then let
              val bit_set = (bits / p2) mod 2 != 0
              val () = if bit_set then
                glVertex2f(f_add(cur_x, f_mul(g0int2float(col), scale)), f_add(y, f_mul(g0int2float(row), scale)))
            in row_loop(row + 1, p2 * 2) end else ()
          val () = row_loop(0, 1)
        in col_loop(col + 1) end else ()
      val () = col_loop(0)
    in
      loop(ptr_add<char>(p, 1), f_add(cur_x, f_mul(7.0f, scale)))
    end else ()
  end
  val () = loop(p_str, x)
  val () = glEnd()
in () end

// --- Renk Dönüşümü: HSV -> RGB (Pür ATS2) ---
fun hsv_to_rgb(h: float, s: float, v: float): @(float, float, float) =
  if s <= 0.0f then @(v, v, v)
  else let
    val hh_raw = f_mul(h, 6.0f)
    val hh = if hh_raw >= 6.0f then 0.0f else hh_raw
    val i = g0float2int_float_int(hh)
    val ff = f_sub(hh, g0int2float(i))
    val p = f_mul(v, f_sub(1.0f, s))
    val q = f_mul(v, f_sub(1.0f, f_mul(s, ff)))
    val t = f_mul(v, f_sub(1.0f, f_mul(s, f_sub(1.0f, ff))))
  in
    case+ i of
    | 0 => @(v, t, p)
    | 1 => @(q, v, p)
    | 2 => @(p, v, t)
    | 3 => @(p, q, v)
    | 4 => @(t, p, v)
    | _ => @(v, p, q)
  end

// --- Renk Dönüşümü: RGB -> HSV (Pür ATS2) ---
fun rgb_to_hsv(r: float, g: float, b: float): @(float, float, float) = let
  val max_rg = if f_gt(r, g) then r else g
  val max_val = if f_gt(max_rg, b) then max_rg else b
  val min_rg = if f_lt(r, g) then r else g
  val min_val = if f_lt(min_rg, b) then min_rg else b
  val delta = f_sub(max_val, min_val)
  val v = max_val
in
  if f_lt(delta, 0.00001f) then
    @(0.0f, 0.0f, v)
  else let
    val s = if f_gt(max_val, 0.0f) then f_div(delta, max_val) else 0.0f
    val h_val =
      if f_gte(r, max_val) then f_div(f_sub(g, b), delta)
      else if f_gte(g, max_val) then f_add(2.0f, f_div(f_sub(b, r), delta))
      else f_add(4.0f, f_div(f_sub(r, g), delta))
    val h_deg = f_mul(h_val, 60.0f)
    val h_norm = if f_lt(h_deg, 0.0f) then f_add(h_deg, 360.0f) else h_deg
    val h = f_div(h_norm, 360.0f)
  in
    @(h, s, v)
  end
end

// --- Renk Paleti (Pür ATS2) ---
fun get_palette_color(i: int): @(float, float, float) =
  case+ i of
  | 0  => @(1.00f, 1.00f, 1.00f) // Beyaz
  | 1  => @(0.73f, 0.73f, 0.73f) // Gri
  | 2  => @(0.30f, 0.30f, 0.30f) // Koyu Gri
  | 3  => @(0.00f, 0.00f, 0.00f) // Siyah
  | 4  => @(0.95f, 0.20f, 0.20f) // Kırmızı
  | 5  => @(1.00f, 0.55f, 0.00f) // Turuncu
  | 6  => @(1.00f, 0.90f, 0.10f) // Sarı
  | 7  => @(0.20f, 0.85f, 0.30f) // Yeşil
  | 8  => @(0.10f, 0.85f, 0.85f) // Camgöbeği
  | 9  => @(0.20f, 0.45f, 0.95f) // Mavi
  | 10 => @(0.65f, 0.25f, 0.85f) // Mor
  | _  => @(0.55f, 0.35f, 0.20f) // Kahverengi

// --- Widget Durumu (State Record) ---
typedef UIWidgetsState = @{
  cur_r= float,
  cur_g= float,
  cur_b= float,
  cur_h= float,
  cur_s= float,
  cur_v= float,
  active_drag= int,
  val0= float,
  val1= float,
  val2= float,
  val3= float
}

fn ui_get(): ref(UIWidgetsState) = $UN.cast{ref(UIWidgetsState)}(get_g_ui_ptr())

fn get_slider_info(i: int): @(string, int, float, float, float) = let
  val u = ui_get()
in
  case+ i of
  | 0 => @("BOYUT", 3, 0.0f, 4.0f, u->val0)
  | 1 => @("SERTLIK", 4, 0.0f, 1.0f, u->val1)
  | 2 => @("OPAKLIK", 0, 0.0f, 1.0f, u->val2)
  | _ => @("YUMUSATMA", 31, 0.0f, 5.0f, u->val3)
end

fn set_slider_val(i: int, v: float): void = let
  val u = ui_get()
in
  case+ i of
  | 0 => u->val0 := v
  | 1 => u->val1 := v
  | 2 => u->val2 := v
  | _ => u->val3 := v
end

// --- Widget Olay ve Render Fonksiyonları (Pür ATS2) ---
extern fun widgets_is_dragging(): int = "ext#widgets_is_dragging"
implement widgets_is_dragging() = let
  val u = ui_get()
in
  if u->active_drag >= 0 then 1 else 0
end

extern fun widgets_on_mouse_up(canvas_ptr: ptr): void = "ext#widgets_on_mouse_up"
implement widgets_on_mouse_up(canvas_ptr) = let
  val u = ui_get()
in
  u->active_drag := ~1
end

extern fun widgets_on_mouse_down(mx: float, my: float, btn: int, canvas_ptr: ptr): int = "ext#widgets_on_mouse_down"
implement widgets_on_mouse_down(mx, my, btn, canvas_ptr) =
  if btn != 1 then 0
  else let
    val u = ui_get()
    val swatch_w = 22.0f
    val swatch_h = 20.0f
    fun check_pal(i: int): int =
      if i < 12 then let
        val row = i / 6
        val col = i % 6
        val bx = f_add(75.0f, f_mul(g0int2float(col), f_add(swatch_w, 5.0f)))
        val by = f_add(55.0f, f_mul(g0int2float(row), f_add(swatch_h, 5.0f)))
        val hit = (mx >= bx) * (mx <= f_add(bx, swatch_w)) * (my >= by) * (my <= f_add(by, swatch_h))
      in
        if hit then let
          val @(pr, pg, pb) = get_palette_color(i)
          val () = u->cur_r := pr
          val () = u->cur_g := pg
          val () = u->cur_b := pb
          val @(ph, ps, pv) = rgb_to_hsv(pr, pg, pb)
          val () = u->cur_h := ph
          val () = u->cur_s := ps
          val () = u->cur_v := pv
          val () = canvas_set_brush_color(canvas_ptr, pr, pg, pb)
        in 1 end
        else check_pal(i + 1)
      end else 0

    val pal_hit = check_pal(0)
  in
    if pal_hit > 0 then 1
    else let
      val bar_w = 210.0f
      val in_hue = (mx >= 20.0f) * (mx <= f_add(20.0f, bar_w)) * (my >= 115.0f) * (my <= 135.0f)
    in
      if in_hue then let
        val () = u->active_drag := 10
        val raw_h = f_div(f_sub(mx, 20.0f), bar_w)
        val h_val = f_clamp(raw_h, 0.0f, 1.0f)
        val () = u->cur_h := h_val
        val @(nr, ng, nb) = hsv_to_rgb(h_val, u->cur_s, u->cur_v)
        val () = u->cur_r := nr
        val () = u->cur_g := ng
        val () = u->cur_b := nb
        val () = canvas_set_brush_color(canvas_ptr, nr, ng, nb)
      in 1 end
      else let
        val in_sv = (mx >= 20.0f) * (mx <= f_add(20.0f, bar_w)) * (my >= 145.0f) * (my <= 220.0f)
      in
        if in_sv then let
          val () = u->active_drag := 11
          val raw_s = f_div(f_sub(mx, 20.0f), bar_w)
          val raw_v = f_sub(1.0f, f_div(f_sub(my, 145.0f), 75.0f))
          val s_val = f_clamp(raw_s, 0.0f, 1.0f)
          val v_val = f_clamp(raw_v, 0.0f, 1.0f)
          val () = u->cur_s := s_val
          val () = u->cur_v := v_val
          val @(nr, ng, nb) = hsv_to_rgb(u->cur_h, s_val, v_val)
          val () = u->cur_r := nr
          val () = u->cur_g := ng
          val () = u->cur_b := nb
          val () = canvas_set_brush_color(canvas_ptr, nr, ng, nb)
        in 1 end
        else let
          val slider_base_y = 250.0f
          val slider_spacing = 58.0f
          fun check_slider(i: int): int =
            if i < 4 then let
              val sy_pos = f_add(slider_base_y, f_mul(g0int2float(i), slider_spacing))
              val in_sl = (mx >= 15.0f) * (mx <= 235.0f) * (my >= f_add(sy_pos, 10.0f)) * (my <= f_add(sy_pos, 35.0f))
            in
              if in_sl then let
                val () = u->active_drag := i
                val raw_pct = f_div(f_sub(mx, 20.0f), bar_w)
                val pct = f_clamp(raw_pct, 0.0f, 1.0f)
                val @(_, set_id, min_v, max_v, _) = get_slider_info(i)
                val new_v = f_add(min_v, f_mul(pct, f_sub(max_v, min_v)))
                val () = set_slider_val(i, new_v)
                val () = canvas_set_brush_setting(canvas_ptr, set_id, new_v)
              in 1 end
              else check_slider(i + 1)
            end else 0
        in
          check_slider(0)
        end
      end
    end
  end

extern fun widgets_on_mouse_move(mx: float, my: float, canvas_ptr: ptr): int = "ext#widgets_on_mouse_move"
implement widgets_on_mouse_move(mx, my, canvas_ptr) = let
  val u = ui_get()
in
  if u->active_drag < 0 then 0
  else let
    val bar_w = 210.0f
  in
    if u->active_drag = 10 then let
      val raw_h = f_div(f_sub(mx, 20.0f), bar_w)
      val h_val = f_clamp(raw_h, 0.0f, 1.0f)
      val () = u->cur_h := h_val
      val @(nr, ng, nb) = hsv_to_rgb(h_val, u->cur_s, u->cur_v)
      val () = u->cur_r := nr
      val () = u->cur_g := ng
      val () = u->cur_b := nb
      val () = canvas_set_brush_color(canvas_ptr, nr, ng, nb)
    in 1 end
    else if u->active_drag = 11 then let
      val raw_s = f_div(f_sub(mx, 20.0f), bar_w)
      val raw_v = f_sub(1.0f, f_div(f_sub(my, 145.0f), 75.0f))
      val s_val = f_clamp(raw_s, 0.0f, 1.0f)
      val v_val = f_clamp(raw_v, 0.0f, 1.0f)
      val () = u->cur_s := s_val
      val () = u->cur_v := v_val
      val @(nr, ng, nb) = hsv_to_rgb(u->cur_h, s_val, v_val)
      val () = u->cur_r := nr
      val () = u->cur_g := ng
      val () = u->cur_b := nb
      val () = canvas_set_brush_color(canvas_ptr, nr, ng, nb)
    in 1 end
    else if (u->active_drag >= 0) * (u->active_drag < 4) then let
      val i = u->active_drag
      val raw_pct = f_div(f_sub(mx, 20.0f), bar_w)
      val pct = f_clamp(raw_pct, 0.0f, 1.0f)
      val @(_, set_id, min_v, max_v, _) = get_slider_info(i)
      val new_v = f_add(min_v, f_mul(pct, f_sub(max_v, min_v)))
      val () = set_slider_val(i, new_v)
      val () = canvas_set_brush_setting(canvas_ptr, set_id, new_v)
    in 1 end
    else 0
  end
end

extern fun widgets_render(sx: float, sy: float, sw: float, sh: float): void = "ext#widgets_render"
implement widgets_render(sx, sy, sw, sh) = let
  val u = ui_get()
  val () = glDisable(GL_DEPTH_TEST)
  val () = glDisable(GL_TEXTURE_2D)
  val () = glEnable(GL_BLEND)
  val () = glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  // 1. Sidebar Arka Planı (Koyu Şık Tema)
  val () = gl_draw_rect(sx, sy, sw, sh, 0.12f, 0.12f, 0.13f, 1.0f)
  val () = gl_draw_rect(sx, sy, 1.0f, sh, 0.22f, 0.22f, 0.25f, 1.0f)

  // 2. Başlık
  val () = glPointSize(2.0f)
  val () = gl_draw_string(f_add(sx, 20.0f), 20.0f, 1.5f, "MINEPAINT", 0.0f, 0.6f, 1.0f)
  val () = gl_draw_rect(f_add(sx, 20.0f), 42.0f, f_sub(sw, 40.0f), 1.0f, 0.2f, 0.2f, 0.22f, 1.0f)

  // 3. Renk Bölümü
  // Aktif Renk Önizleme Kutusu
  val () = gl_draw_rect(f_add(sx, 20.0f), 55.0f, 45.0f, 45.0f, u->cur_r, u->cur_g, u->cur_b, 1.0f)
  val () = gl_draw_rect_outline(f_add(sx, 20.0f), 55.0f, 45.0f, 45.0f, 0.5f, 0.5f, 0.55f, 1.0f)

  // 12'li Renk Paleti (2 satır x 6 sütun)
  val swatch_w = 22.0f
  val swatch_h = 20.0f
  fun draw_palette(i: int): void =
    if i < 12 then let
      val row = i / 6
      val col = i % 6
      val bx = f_add(f_add(sx, 75.0f), f_mul(g0int2float(col), f_add(swatch_w, 5.0f)))
      val by = f_add(55.0f, f_mul(g0int2float(row), f_add(swatch_h, 5.0f)))
      val @(pr, pg, pb) = get_palette_color(i)
      val () = gl_draw_rect(bx, by, swatch_w, swatch_h, pr, pg, pb, 1.0f)
      val () = gl_draw_rect_outline(bx, by, swatch_w, swatch_h, 0.3f, 0.3f, 0.35f, 1.0f)
    in draw_palette(i + 1) end else ()
  val () = draw_palette(0)

  // Gökkuşağı Hue (Renk Tonu) Çubuğu
  val hue_y = 115.0f
  val hue_h = 16.0f
  val bar_w = f_sub(sw, 40.0f)
  val () = glBegin(GL_QUAD_STRIP)
  val h_segs = 36
  fun draw_hue(i: int): void =
    if i <= h_segs then let
      val h_val = f_div(g0int2float(i), g0int2float(h_segs))
      val @(hr, hg, hb) = hsv_to_rgb(h_val, 1.0f, 1.0f)
      val () = glColor3f(hr, hg, hb)
      val () = glVertex2f(f_add(f_add(sx, 20.0f), f_mul(h_val, bar_w)), hue_y)
      val () = glVertex2f(f_add(f_add(sx, 20.0f), f_mul(h_val, bar_w)), f_add(hue_y, hue_h))
    in draw_hue(i + 1) end else ()
  val () = draw_hue(0)
  val () = glEnd()
  val () = gl_draw_rect_outline(f_add(sx, 20.0f), hue_y, bar_w, hue_h, 0.4f, 0.4f, 0.45f, 1.0f)

  // Hue Seçici İmleç
  val hue_cursor_x = f_add(f_add(sx, 20.0f), f_mul(u->cur_h, bar_w))
  val () = gl_draw_rect(f_sub(hue_cursor_x, 2.0f), f_sub(hue_y, 2.0f), 4.0f, f_add(hue_h, 4.0f), 1.0f, 1.0f, 1.0f, 1.0f)

  // Doygunluk ve Parlaklık (SV) Kutusu
  val sv_y = 145.0f
  val sv_h = 75.0f
  val @(pure_r, pure_g, pure_b) = hsv_to_rgb(u->cur_h, 1.0f, 1.0f)
  val () = glBegin(GL_QUADS)
  val () = glColor3f(1.0f, 1.0f, 1.0f)
  val () = glVertex2f(f_add(sx, 20.0f), sv_y)
  val () = glColor3f(pure_r, pure_g, pure_b)
  val () = glVertex2f(f_add(f_add(sx, 20.0f), bar_w), sv_y)
  val () = glColor3f(0.0f, 0.0f, 0.0f)
  val () = glVertex2f(f_add(f_add(sx, 20.0f), bar_w), f_add(sv_y, sv_h))
  val () = glColor3f(0.0f, 0.0f, 0.0f)
  val () = glVertex2f(f_add(sx, 20.0f), f_add(sv_y, sv_h))
  val () = glEnd()
  val () = gl_draw_rect_outline(f_add(sx, 20.0f), sv_y, bar_w, sv_h, 0.4f, 0.4f, 0.45f, 1.0f)

  // SV İmleç
  val sv_cursor_x = f_add(f_add(sx, 20.0f), f_mul(u->cur_s, bar_w))
  val sv_cursor_y = f_add(sv_y, f_mul(f_sub(1.0f, u->cur_v), sv_h))
  val () = gl_draw_circle(sv_cursor_x, sv_cursor_y, 4.0f, 1.0f, 1.0f, 1.0f, 1.0f)
  val () = gl_draw_circle(sv_cursor_x, sv_cursor_y, 3.0f, 0.0f, 0.0f, 0.0f, 1.0f)

  val () = gl_draw_rect(f_add(sx, 20.0f), 235.0f, bar_w, 1.0f, 0.2f, 0.2f, 0.22f, 1.0f)

  // 4. Sürgüler (Sliders)
  val slider_base_y = 250.0f
  val slider_spacing = 58.0f
  var val_buf = @[byte][16]()
  val p_buf = addr@(val_buf)
  fun draw_sliders(i: int): void =
    if i < 4 then let
      val sy_pos = f_add(slider_base_y, f_mul(g0int2float(i), slider_spacing))
      val @(lbl, _, min_v, max_v, v) = get_slider_info(i)
      val () = glPointSize(1.5f)
      val () = gl_draw_string(f_add(sx, 20.0f), sy_pos, 1.2f, lbl, 0.85f, 0.85f, 0.85f)

      val () = format_slider_val(p_buf, 16, v)
      val val_str = $UN.cast{string}(p_buf)
      val () = gl_draw_string(f_sub(f_add(sx, sw), 60.0f), sy_pos, 1.1f, val_str, 0.6f, 0.6f, 0.65f)

      val track_y = f_add(sy_pos, 18.0f)
      val track_h = 6.0f
      val () = gl_draw_rect(f_add(sx, 20.0f), track_y, bar_w, track_h, 0.18f, 0.18f, 0.20f, 1.0f)

      val raw_pct = f_div(f_sub(v, min_v), f_sub(max_v, min_v))
      val pct = f_clamp(raw_pct, 0.0f, 1.0f)
      val () = gl_draw_rect(f_add(sx, 20.0f), track_y, f_mul(pct, bar_w), track_h, 0.0f, 0.48f, 0.80f, 1.0f)

      val thumb_x = f_add(f_add(sx, 20.0f), f_mul(pct, bar_w))
      val () = gl_draw_circle(thumb_x, f_add(track_y, f_div(track_h, 2.0f)), 7.0f, 0.9f, 0.9f, 0.95f, 1.0f)
      val () = gl_draw_circle(thumb_x, f_add(track_y, f_div(track_h, 2.0f)), 4.0f, 0.0f, 0.48f, 0.80f, 1.0f)
    in draw_sliders(i + 1) end else ()
  val () = draw_sliders(0)
in () end
