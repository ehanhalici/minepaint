#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/buf.sats"
staload "sys/fs_io.sats"

staload "sys/libc.dats"
staload "sys/text_io.dats"
#include "sys/airlock.hats"
staload "sys/buf.sats"
staload "ui/state.dats"
staload "brushes/brush_group.sats"
staload "ui/palette.dats"

macdef MODE_0755 = $extval(uint, "0755")

fn f2d(v: float): double = g0float2float_float_double(v)

fn build_session_path{n:pos}(fsio: !FS_IO | buf: !Text(n), cap: int(n), suffix: string): bool = let
  val home_str = getenv_or_empty(fsio | "HOME")
in
  if airlock_cstr_len(home_str) > 0 then let
    val _ = mp_format_path(buf, cap, home_str, suffix)
  in true end
  else false
end

fn ensure_dirs(fsio: !FS_IO | ): void = let
  val buf = text_new(512)
  val cap = 512
  val ok1 = build_session_path(fsio | buf, cap, "/.config")
  val () = if ok1 then let
    val _ = mkdir(fsio | buf, MODE_0755)
  in () end
  val ok2 = build_session_path(fsio | buf, cap, "/.config/minepaint")
  val () = if ok2 then let
    val _ = mkdir(fsio | buf, MODE_0755)
  in () end
in text_free(buf) end

fn parse_swatch(line: !Text(256)): bool = let
  var idx: int = 0
  var a: float = 0.0f
  var b: float = 0.0f
  var c: float = 0.0f
  val n = sscanf_ifff(line, "swatch %d %f %f %f", idx, a, b, c)
in
  if n = 4 then let
    val () = pal_set(idx, 0, a)
    val () = pal_set(idx, 1, b)
    val () = pal_set(idx, 2, c)
  in true end
  else false
end

fn parse_active_swatch(line: !Text(256)): bool = let
  var idx: int = 0
  val n = sscanf_i(line, "active_swatch %d", idx)
in
  if n = 1 then let
    val u = ui_get()
    val () = u->active_swatch := selection_of_code(idx, 12)
  in true end
  else false
end

// Dosyadan okunan geçersiz grup kimliği yerine varsayılan (Classic) kullanılır.
fn group_or_default(idx: int): BrushGroup = let
  val @(ok, g) = brush_group_try(idx)
in
  if ok then g else GroupClassic()
end

fn parse_group_brush_scroll(line: !Text(256)): bool = let
  var idx: int = 0
  val u = ui_get()
in
  if sscanf_i(line, "group %d", idx) = 1 then let
    val () = u->active_group := group_or_default(idx)
  in true end
  else if sscanf_i(line, "brush %d", idx) = 1 then let
    val () = u->active_brush := selection_of_code(idx, 2147483647)
  in true end
  else if sscanf_i(line, "scroll %d", idx) = 1 then let
    val () = u->brush_scroll := (if idx < 0 then 0 else idx)
  in true end
  else false
end

fn parse_color(line: !Text(256)): bool = let
  var a: float = 0.0f
  var b: float = 0.0f
  var c: float = 0.0f
  val n = sscanf_fff(line, "color %f %f %f", a, b, c)
in
  if n = 3 then let
    val u = ui_get()
    val () = u->cur_r := (if g0float_lt(a, 0.0f) then 0.0f else if g0float_gt(a, 1.0f) then 1.0f else a)
    val () = u->cur_g := (if g0float_lt(b, 0.0f) then 0.0f else if g0float_gt(b, 1.0f) then 1.0f else b)
    val () = u->cur_b := (if g0float_lt(c, 0.0f) then 0.0f else if g0float_gt(c, 1.0f) then 1.0f else c)
  in true end
  else false
end

fn parse_slider_setting(line: !Text(256)): bool = let
  var a: float = 0.0f
  val u = ui_get()
in
  if sscanf_f(line, "size %f", a) = 1 then (u->val0 := a; true)
  else if sscanf_f(line, "opaque %f", a) = 1 then (u->val1 := a; true)
  else if sscanf_f(line, "sharp %f", a) = 1 then (u->val2 := a; true)
  else if sscanf_f(line, "grain %f", a) = 1 then (u->val3 := a; true)
  else if sscanf_f(line, "pigment %f", a) = 1 then (u->val4 := a; true)
  else if sscanf_f(line, "smooth %f", a) = 1 then (u->val5 := a; true)
  else if sscanf_f(line, "pressure %f", a) = 1 then (u->val6 := a; true)
  else if sscanf_f(line, "twist %f", a) = 1 then (u->val7 := a; true)
  else false
end

fn apply_line(line: !Text(256)): void =
  if parse_swatch(line) then ()
  else if parse_active_swatch(line) then ()
  else if parse_group_brush_scroll(line) then ()
  else if parse_color(line) then ()
  else if parse_slider_setting(line) then ()
  else ()

// Dosya boyutu (bayt): sonuna git, konumu oku, basa don.
fn file_size_of(fsio: !FS_IO | f: !File): int = let
  val _ = fseek(fsio | f, 0L, 2)
  val sz = ftell(fsio | f)
  val () = rewind(fsio | f)
in
  g0int2int_lint_int(sz)
end

// Olcu m - i: her basarili fgets en az bir bayt tuketir; satir sayisi dosya boyutunu asamaz
// (m = boyut + 1: son fgets NULL doner). Dosya okunurken buyurse fazlasi bir sonraki acilista okunur.
fun read_lines {m:nat}{i:nat | i <= m} .<m - i>. (
  fsio: !FS_IO | f: !File, i: int(i), max: int(m), p_line: !Text(256)
): void =
  if i < max then
    (let val got = fgets(fsio | p_line, 256, f) in
     if got then let
       val () = apply_line(p_line)
       val () = read_lines(fsio | f, i + 1, max, p_line)
     in () end
     else () end)
  else ()

// Acik dosyayi okur ve kapatir. Olcu m - i: her basarili fgets en az bir bayt tuketir; satir sayisi dosya boyutunu
// asamaz (m = boyut + 1: son fgets NULL doner). Dosya okunurken buyurse fazlasi bir sonraki acilista okunur.
fn load_session_file(fsio: !FS_IO | f: File): int = let
  val line_buf = text_new(256)
  val max_lines = airlock_nat(file_size_of(fsio | f) + 1)
  val () = read_lines(fsio | f, 0, max_lines, line_buf)
  val () = file_close(fsio | f)
  val () = text_free(line_buf)
in 1 end

fn open_and_load(fsio: !FS_IO | path_buf: !Text(512)): int =
  case+ file_open(fsio | path_buf, "r") of
  | ~None_vt() => 0
  | ~Some_vt(f) => load_session_file(fsio | f)

extern fun session_load(fsio: !FS_IO | ): int = "ext#session_load"
implement session_load(fsio | ) = let
  val path_buf = text_new(512)
  val ok = build_session_path(fsio | path_buf, 512, "/.config/minepaint/session.conf")
  val result = if ok then open_and_load(fsio | path_buf) else 0
  val () = text_free(path_buf)
in result end

fn put_line(fsio: !FS_IO | f: !File, buf: !Text(256)): void = let
  val _ = fputs(fsio | buf, f)
in () end

// Ust duzey (ic ice degil): dogrusal !File parametresi ic ice fonksiyonda C koduna dogru uretilmez.
fun save_swatches {i:nat | i <= 12} .<12 - i>. (
  fsio: !FS_IO | f: !File, i: int(i), buf: !Text(256), cap: int(256)
): void =
  if i >= 12 then ()
  else let
    val r = pal_get(i, 0)
    val g = pal_get(i, 1)
    val b = pal_get(i, 2)
    val _ = mp_snprintf_ifff(buf, cap, "swatch %d %.6f %.6f %.6f\n", i, f2d(r), f2d(g), f2d(b))
    val () = put_line(fsio | f, buf)
    val () = save_swatches(fsio | f, i + 1, buf, cap)
  in () end

fn save_palette_and_state(fsio: !FS_IO | f: !File, buf: !Text(256), cap: int(256)): void = let
  val u = ui_get()
  val () = save_swatches(fsio | f, 0, buf, cap)
  val _ = mp_snprintf_i(buf, cap, "active_swatch %d\n", selection_code(u->active_swatch))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_i(buf, cap, "group %d\n", brush_group_to_int(u->active_group))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_i(buf, cap, "brush %d\n", selection_code(u->active_brush))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_i(buf, cap, "scroll %d\n", u->brush_scroll)
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_fff(buf, cap, "color %.6f %.6f %.6f\n", f2d(u->cur_r), f2d(u->cur_g), f2d(u->cur_b))
  val () = put_line(fsio | f, buf)
in () end

fn save_slider_values(fsio: !FS_IO | f: !File, buf: !Text(256), cap: int(256)): void = let
  val u = ui_get()
  val _ = mp_snprintf_f(buf, cap, "size %.6f\n", f2d(u->val0))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "opaque %.6f\n", f2d(u->val1))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "sharp %.6f\n", f2d(u->val2))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "grain %.6f\n", f2d(u->val3))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "pigment %.6f\n", f2d(u->val4))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "smooth %.6f\n", f2d(u->val5))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "pressure %.6f\n", f2d(u->val6))
  val () = put_line(fsio | f, buf)
  val _ = mp_snprintf_f(buf, cap, "twist %.6f\n", f2d(u->val7))
  val () = put_line(fsio | f, buf)
in () end

// Yazma: önce geçici dosyaya, sonra atomik rename ile hedefe (skill.md: Atomik Kalıcılık).
fn write_session_file(fsio: !FS_IO | f: !File): void = let
  val buf = text_new(256)
  val cap = 256
  val () = save_palette_and_state(fsio | f, buf, cap)
  val () = save_slider_values(fsio | f, buf, cap)
in
  text_free(buf)
end

fn sync_to_disk(fsio: !FS_IO | f: !File): bool = (fflush(fsio | f) = 0) andalso (fsync(fsio | fileno(fsio | f)) = 0)

fn write_session_tmp(fsio: !FS_IO | p_tmp: !Text(512)): bool = let
in
  case+ file_open(fsio | p_tmp, "w") of
  | ~None_vt() => false
  | ~Some_vt(f) => let
      val () = write_session_file(fsio | f)
      val ok = sync_to_disk(fsio | f)
      val () = file_close(fsio | f)
    in ok end
end

fn commit_session(fsio: !FS_IO | p_tmp: !Text(512), path_buf: !Text(512)): void =
  if rename(fsio | p_tmp, path_buf) = 0 then ()
  else perror(fsio | "minepaint: session.conf kalici hale getirilemedi")

fn report_session_error(fsio: !FS_IO | ): void =
  perror(fsio | "minepaint: session.conf yazilamadi")

fn save_atomically(fsio: !FS_IO | p_tmp: !Text(512), path_buf: !Text(512)): void =
  if write_session_tmp(fsio | p_tmp) then commit_session(fsio | p_tmp, path_buf)
  else report_session_error(fsio | )

extern fun session_save(fsio: !FS_IO | ): void = "ext#session_save"
implement session_save(fsio | ) = let
  val () = ensure_dirs(fsio | )
  val path_buf = text_new(512)
  val tmp_buf = text_new(512)
  val ok_path = build_session_path(fsio | path_buf, 512, "/.config/minepaint/session.conf")
  val ok_tmp = build_session_path(fsio | tmp_buf, 512, "/.config/minepaint/session.conf.tmp")
  val () =
    if ok_path andalso ok_tmp then save_atomically(fsio | tmp_buf, path_buf)
    else report_session_error(fsio | )
in
  text_free(path_buf); text_free(tmp_buf)
end
