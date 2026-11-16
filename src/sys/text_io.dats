// src/sys/text_io.dats
// Text(n) yazicilari: her ham C yazicisi `&Text(n) >> TextRaw(n)` tipindedir (NUL garantisini dusurur) ve burada
// text_seal ile geri `Text(n)`'e doner. Bu dosya Text/TextRaw'i SOYUT gorur (assume yok): bir sarmalayici muhru
// unutursa `!Text(n)` parametresi cikista geri kazanilamaz ve derleme basarisiz olur. Boylece sscanf/fopen/mkdir/
// rename/fputs tuketicilerinin NUL onkosulu derleyici tarafindan kanitlanir.
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/buf.sats"
staload "sys/capability.sats"
staload "sys/fs_io.sats"

extern fun c_snprintf_f{n:pos}(b: !Text(n) >> TextRaw(n), cap: int(n), fmt: string, v: double): int = "mac#snprintf"
extern fun c_snprintf_i{n:pos}(b: !Text(n) >> TextRaw(n), cap: int(n), fmt: string, v: int): int = "mac#snprintf"
extern fun c_snprintf_fff{n:pos}(b: !Text(n) >> TextRaw(n), cap: int(n), fmt: string, x: double, y: double, z: double): int = "mac#snprintf"
extern fun c_snprintf_ifff{n:pos}(b: !Text(n) >> TextRaw(n), cap: int(n), fmt: string, i: int, x: double, y: double, z: double): int = "mac#snprintf"
extern fun c_snprintf_ss{n:pos}(b: !Text(n) >> TextRaw(n), cap: int(n), fmt: string, s1: string, s2: string): int = "mac#mp_snprintf_two_strings"

extern fun mp_snprintf_f{n:pos}(b: !Text(n), cap: int(n), fmt: string, v: double): int = "ext#mp_snprintf_f"
implement mp_snprintf_f{n}(b, cap, fmt, v) = let
  val r = c_snprintf_f(b, cap, fmt, v)
  val () = text_seal(b, cap)
in r end

extern fun mp_snprintf_i{n:pos}(b: !Text(n), cap: int(n), fmt: string, v: int): int = "ext#mp_snprintf_i"
implement mp_snprintf_i{n}(b, cap, fmt, v) = let
  val r = c_snprintf_i(b, cap, fmt, v)
  val () = text_seal(b, cap)
in r end

extern fun mp_snprintf_fff{n:pos}(b: !Text(n), cap: int(n), fmt: string, x: double, y: double, z: double): int = "ext#mp_snprintf_fff"
implement mp_snprintf_fff{n}(b, cap, fmt, x, y, z) = let
  val r = c_snprintf_fff(b, cap, fmt, x, y, z)
  val () = text_seal(b, cap)
in r end

extern fun mp_snprintf_ifff{n:pos}(b: !Text(n), cap: int(n), fmt: string, i: int, x: double, y: double, z: double): int = "ext#mp_snprintf_ifff"
implement mp_snprintf_ifff{n}(b, cap, fmt, i, x, y, z) = let
  val r = c_snprintf_ifff(b, cap, fmt, i, x, y, z)
  val () = text_seal(b, cap)
in r end

extern fun mp_format_path{n:pos}(b: !Text(n), cap: int(n), s1: string, s2: string): int = "ext#mp_format_path"
implement mp_format_path{n}(b, cap, s1, s2) = let
  val r = c_snprintf_ss(b, cap, "%s%s", s1, s2)
  val () = text_seal(b, cap)
in r end

extern fun fgets{n:pos}(pf: !FS_IO | b: !Text(n), cnt: int(n), f: !File): bool = "ext#fgets_text"
implement fgets{n}(pf | b, cnt, f) = let
  val ok = c_fgets_raw(pf | b, cnt, f)
  val () = text_seal(b, cnt)
in ok end
