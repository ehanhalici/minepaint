#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "gl/gl.dats"

fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)

// --- 5x7 Vektör Font Tablosu (Pür ATS2) ---
fun font_get_col(c: int, col: int): int =
  case+ c of
  | 32 => 0 // ' '
  | 46 => if col = 1 || col = 2 then 0x60 else 0 // '.'
  | 58 => if col = 1 || col = 2 then 0x36 else 0 // ':'
  | 45 => 0x08 // '-'
  | 60 => // '<' (Sola Ok / Chevron)
    if col = 0 then 0x08 else if col = 1 then 0x14 else if col = 2 then 0x22 else if col = 3 then 0x41 else 0x00
  | 62 => // '>' (Sağa Ok / Chevron)
    if col = 0 then 0x41 else if col = 1 then 0x22 else if col = 2 then 0x14 else if col = 3 then 0x08 else 0x00
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

// --- Vektör Metin Çizimi ---
extern fun gl_draw_string(x: float, y: float, scale: float, str: string, r: float, g: float, b: float): void = "ext#gl_draw_string"
implement gl_draw_string(x, y, scale, str, r, g, b) = let
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
