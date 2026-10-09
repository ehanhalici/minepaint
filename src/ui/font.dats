#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "gl/gl.dats"
#include "draw_engine/engine_safe.hats"

fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)

fn font_col_symbol(c: int, col: int): int =
  case+ c of
  | 32 => 0
  | 46 => (if col = 1 || col = 2 then 0x60 else 0)
  | 58 => (if col = 1 || col = 2 then 0x36 else 0)
  | 45 => 0x08
  | 60 => (case+ col of 0 => 0x08 | 1 => 0x14 | 2 => 0x22 | 3 => 0x41 | _ => 0x00)
  | 62 => (case+ col of 0 => 0x41 | 1 => 0x22 | 2 => 0x14 | 3 => 0x08 | _ => 0x00)
  | 37 => (case+ col of 0 => 0x63 | 1 => 0x33 | 2 => 0x18 | 3 => 0x0c | _ => 0x66)
  | _ => 0

fn font_col_digit(c: int, col: int): int =
  case+ c of
  | 48 => (case+ col of 0 => 0x3e | 1 => 0x51 | 2 => 0x49 | 3 => 0x45 | _ => 0x3e)
  | 49 => (case+ col of 1 => 0x42 | 2 => 0x7f | 3 => 0x40 | _ => 0x00)
  | 50 => (case+ col of 0 => 0x42 | 1 => 0x61 | 2 => 0x51 | 3 => 0x49 | _ => 0x46)
  | 51 => (case+ col of 0 => 0x21 | 1 => 0x41 | 2 => 0x45 | 3 => 0x4b | _ => 0x31)
  | 52 => (case+ col of 0 => 0x18 | 1 => 0x14 | 2 => 0x12 | 3 => 0x7f | _ => 0x10)
  | 53 => (case+ col of 0 => 0x27 | 1 => 0x45 | 2 => 0x45 | 3 => 0x45 | _ => 0x39)
  | 54 => (case+ col of 0 => 0x3c | 1 => 0x4a | 2 => 0x49 | 3 => 0x49 | _ => 0x30)
  | 55 => (case+ col of 0 => 0x01 | 1 => 0x71 | 2 => 0x09 | 3 => 0x05 | _ => 0x03)
  | 56 => (case+ col of 0 => 0x36 | 1 => 0x49 | 2 => 0x49 | 3 => 0x49 | _ => 0x36)
  | 57 => (case+ col of 0 => 0x06 | 1 => 0x49 | 2 => 0x49 | 3 => 0x29 | _ => 0x1e)
  | _ => 0

fn font_col_alpha1(c: int, col: int): int =
  case+ c of
  | 65 => (case+ col of 0 => 0x7c | 1 => 0x12 | 2 => 0x11 | 3 => 0x12 | _ => 0x7c)
  | 66 => (case+ col of 0 => 0x7f | 1 => 0x49 | 2 => 0x49 | 3 => 0x49 | _ => 0x36)
  | 67 => (case+ col of 0 => 0x3e | 1 => 0x41 | 2 => 0x41 | 3 => 0x41 | _ => 0x22)
  | 68 => (case+ col of 0 => 0x7f | 1 => 0x41 | 2 => 0x41 | 3 => 0x22 | _ => 0x1c)
  | 69 => (case+ col of 0 => 0x7f | 1 => 0x49 | 2 => 0x49 | 3 => 0x49 | _ => 0x41)
  | 70 => (case+ col of 0 => 0x7f | 1 => 0x09 | 2 => 0x09 | 3 => 0x09 | _ => 0x01)
  | 71 => (case+ col of 0 => 0x3e | 1 => 0x41 | 2 => 0x49 | 3 => 0x49 | _ => 0x7a)
  | _ => 0

fn font_col_alpha2(c: int, col: int): int =
  case+ c of
  | 72 => (case+ col of 0 => 0x7f | 1 => 0x08 | 2 => 0x08 | 3 => 0x08 | _ => 0x7f)
  | 73 => (case+ col of 1 => 0x41 | 2 => 0x7f | 3 => 0x41 | _ => 0x00)
  | 74 => (case+ col of 0 => 0x20 | 1 => 0x40 | 2 => 0x41 | 3 => 0x3f | _ => 0x01)
  | 75 => (case+ col of 0 => 0x7f | 1 => 0x08 | 2 => 0x14 | 3 => 0x22 | _ => 0x41)
  | 76 => (if col = 0 then 0x7f else 0x40)
  | 77 => (case+ col of 0 => 0x7f | 1 => 0x02 | 2 => 0x0c | 3 => 0x02 | _ => 0x7f)
  | 78 => (case+ col of 0 => 0x7f | 1 => 0x04 | 2 => 0x08 | 3 => 0x10 | _ => 0x7f)
  | _ => 0

fn font_col_alpha3(c: int, col: int): int =
  case+ c of
  | 79 => (case+ col of 0 => 0x3e | 1 => 0x41 | 2 => 0x41 | 3 => 0x41 | _ => 0x3e)
  | 80 => (case+ col of 0 => 0x7f | 1 => 0x09 | 2 => 0x09 | 3 => 0x09 | _ => 0x06)
  | 82 => (case+ col of 0 => 0x7f | 1 => 0x09 | 2 => 0x19 | 3 => 0x29 | _ => 0x46)
  | 83 => (case+ col of 0 => 0x46 | 1 => 0x49 | 2 => 0x49 | 3 => 0x49 | _ => 0x31)
  | 84 => (if col = 2 then 0x7f else 0x01)
  | 85 => (if col = 0 || col = 4 then 0x3f else 0x40)
  | 86 => (if col = 0 || col = 4 then 0x1f else if col = 1 || col = 3 then 0x20 else 0x40)
  | 89 => (if col = 0 || col = 4 then 0x07 else if col = 1 || col = 3 then 0x08 else 0x70)
  | _ => 0

// --- 5x7 Vektör Font Tablosu (Atomik ve Tamamen Güvenli) ---
fun font_get_col(c: int, col: int): int =
  if c >= 48 && c <= 57 then font_col_digit(c, col)
  else if c >= 65 && c <= 71 then font_col_alpha1(c, col)
  else if c >= 72 && c <= 78 then font_col_alpha2(c, col)
  else if c >= 79 && c <= 89 then font_col_alpha3(c, col)
  else font_col_symbol(c, col)

fn gl_draw_row_pixels(col_x: float, y: float, scale: float, bits: int): void = let
  fun loop(row: int, p2: int): void =
    if row < 7 then let
      val bit_set = (bits / p2) mod 2 != 0
      val () = if bit_set then glVertex2f(col_x, f_add(y, f_mul(g0int2float(row), scale)))
    in loop(row + 1, p2 * 2) end else ()
in loop(0, 1) end

fn gl_draw_glyph_cols(cur_x: float, y: float, scale: float, code: int): void = let
  fun loop(col: int): void =
    if col < 5 then let
      val bits = font_get_col(code, col)
      val col_x = f_add(cur_x, f_mul(g0int2float(col), scale))
      val () = gl_draw_row_pixels(col_x, y, scale, bits)
    in loop(col + 1) end else ()
in loop(0) end

fn gl_draw_char(cur_x: float, y: float, scale: float, ch: char): void = let
  val code = char2int0(ch)
  val upper = if code >= 97 && code <= 122 then code - 32 else code
in
  gl_draw_glyph_cols(cur_x, y, scale, upper)
end

// --- Vektör Metin Çizimi (Sıfır Unsafe, Tip Güvenli Dize İndeksleme) ---
extern fun gl_draw_string(x: float, y: float, scale: float, str: string, r: float, g: float, b: float): void = "ext#gl_draw_string"
implement gl_draw_string(x, y, scale, str, r, g, b) = let
  val () = glColor3f(r, g, b)
  val () = glBegin(GL_POINTS)
  val n = airlock_cstr_len(str)
  val char_advance = f_mul(7.0f, scale)

  fun loop(i: int, cur_x: float): void =
    if i < n then let
      val ch = int2char0(airlock_cstr_at(str, i, n))
      val () = gl_draw_char(cur_x, y, scale, ch)
    in
      loop(i + 1, f_add(cur_x, char_advance))
    end else ()

  val () = loop(0, x)
  val () = glEnd()
in () end
