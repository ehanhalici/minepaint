#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "sys/libc.dats"
#include "draw_engine/engine_safe.hats"
staload "sys/io_box.sats"
staload "ui/state.dats"
staload "brushes/brush_group.sats"
staload "ui/palette.dats"

macdef MODE_0755 = $extval(uint, "0755")
extern fun addr2str(p: ptr): string = "mac#mp_id_ptr"

fn f2d(v: float): double = g0float2float_float_double(v)

fn build_session_path(buf: MpText, cap: size_t, suffix: string): bool = let
  val home = getenv("HOME")
in
  if text_is_null(home) != 0 then false
  else let
    val home_str = addr2str(text_ptr(home))
  in
    if airlock_cstr_len(home_str) > 0 then let
      val _ = mp_format_path(buf, cap, home_str, suffix)
    in true end
    else false
  end
end

fn ensure_dirs(): void = let
  var buf = @[byte][512]()
  val p_buf = text_of(addr@(buf))
  val cap = g0int2uint_int_size(512)
  val ok1 = build_session_path(p_buf, cap, "/.config")
  val () = if ok1 then let
    val _ = mkdir(addr2str(text_ptr(p_buf)), MODE_0755)
  in () end
  val ok2 = build_session_path(p_buf, cap, "/.config/minepaint")
  val () = if ok2 then let
    val _ = mkdir(addr2str(text_ptr(p_buf)), MODE_0755)
  in () end
in () end

fn parse_swatch(line: string): bool = let
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

fn parse_active_swatch(line: string): bool = let
  var idx: int = 0
  val n = sscanf_i(line, "active_swatch %d", idx)
in
  if n = 1 then let
    val u = ui_get()
    val () = u->active_swatch := (if (idx < ~1) || (idx > 11) then ~1 else idx)
  in true end
  else false
end

// Dosyadan okunan geçersiz grup kimliği yerine varsayılan (Classic) kullanılır.
fn group_or_default(idx: int): BrushGroup =
  case+ brush_group_of_int(idx) of
  | Some(g) => g
  | None() => GroupClassic()

fn parse_group_brush_scroll(line: string): bool = let
  var idx: int = 0
  val u = ui_get()
in
  if sscanf_i(line, "group %d", idx) = 1 then let
    val () = u->active_group := group_or_default(idx)
  in true end
  else if sscanf_i(line, "brush %d", idx) = 1 then let
    val () = u->active_brush := (if idx < ~1 then ~1 else idx)
  in true end
  else if sscanf_i(line, "scroll %d", idx) = 1 then let
    val () = u->brush_scroll := (if idx < 0 then 0 else idx)
  in true end
  else false
end

fn parse_color(line: string): bool = let
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

fn parse_slider_setting(line: string): bool = let
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

fn apply_line(line: string): void =
  if parse_swatch(line) then ()
  else if parse_active_swatch(line) then ()
  else if parse_group_brush_scroll(line) then ()
  else if parse_color(line) then ()
  else if parse_slider_setting(line) then ()
  else ()

extern fun session_load(): int = "ext#session_load"
implement session_load() = let
  var path_buf = @[byte][512]()
  val p_path = text_of(addr@(path_buf))
  val ok = build_session_path(p_path, g0int2uint_int_size(512), "/.config/minepaint/session.conf")
in
  if not(ok) then 0
  else let
    val f = fopen(addr2str(text_ptr(p_path)), "r")
  in
    if file_is_null(f) != 0 then 0
    else let
      var line_buf = @[byte][256]()
      val p_line = text_of(addr@(line_buf))
      fnx loop {k:nat} .<k>. (k: int(k)): void =
        if k > 0 then
          if text_is_null(fgets(p_line, 256, f)) = 0 then let
            val () = apply_line(addr2str(text_ptr(p_line)))
          in loop(k - 1) end
          else ()
        else ()
      val () = loop(MP_REC_FUEL)
      val _ = fclose(f)
    in 1 end
  end
end

fn put_line(f: MpFile, buf: MpText): void = let
  val _ = fputs(addr2str(text_ptr(buf)), f)
in () end

fn save_palette_and_state(f: MpFile, buf: MpText, cap: size_t): void = let
  val u = ui_get()
  fnx swatches {i:nat | i <= 12} .<12 - i>. (i: int(i)): void =
    if i >= 12 then ()
    else let
      val r = pal_get(i, 0)
      val g = pal_get(i, 1)
      val b = pal_get(i, 2)
      val _ = mp_snprintf_ifff(buf, cap, "swatch %d %.6f %.6f %.6f\n", i, f2d(r), f2d(g), f2d(b))
      val () = put_line(f, buf)
    in swatches(i + 1) end
  val () = swatches(0)
  val _ = mp_snprintf_i(buf, cap, "active_swatch %d\n", u->active_swatch)
  val () = put_line(f, buf)
  val _ = mp_snprintf_i(buf, cap, "group %d\n", brush_group_to_int(u->active_group))
  val () = put_line(f, buf)
  val _ = mp_snprintf_i(buf, cap, "brush %d\n", u->active_brush)
  val () = put_line(f, buf)
  val _ = mp_snprintf_i(buf, cap, "scroll %d\n", u->brush_scroll)
  val () = put_line(f, buf)
  val _ = mp_snprintf_fff(buf, cap, "color %.6f %.6f %.6f\n", f2d(u->cur_r), f2d(u->cur_g), f2d(u->cur_b))
  val () = put_line(f, buf)
in () end

fn save_slider_values(f: MpFile, buf: MpText, cap: size_t): void = let
  val u = ui_get()
  val _ = mp_snprintf_f(buf, cap, "size %.6f\n", f2d(u->val0))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "opaque %.6f\n", f2d(u->val1))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "sharp %.6f\n", f2d(u->val2))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "grain %.6f\n", f2d(u->val3))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "pigment %.6f\n", f2d(u->val4))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "smooth %.6f\n", f2d(u->val5))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "pressure %.6f\n", f2d(u->val6))
  val () = put_line(f, buf)
  val _ = mp_snprintf_f(buf, cap, "twist %.6f\n", f2d(u->val7))
  val () = put_line(f, buf)
in () end

// Yazma: önce geçici dosyaya, sonra atomik rename ile hedefe (skill.md: Atomik Kalıcılık).
fn write_session_file(f: MpFile): void = let
  var buf = @[byte][256]()
  val p_buf = text_of(addr@(buf))
  val cap = g0int2uint_int_size(256)
  val () = save_palette_and_state(f, p_buf, cap)
in
  save_slider_values(f, p_buf, cap)
end

fn sync_to_disk(f: MpFile): bool = (fflush(f) = 0) andalso (fsync(fileno(f)) = 0)

fn write_session_tmp(p_tmp: MpText): bool = let
  val f = fopen(addr2str(text_ptr(p_tmp)), "w")
in
  if file_is_null(f) != 0 then false
  else let
    val () = write_session_file(f)
    val ok = sync_to_disk(f)
    val _ = fclose(f)
  in ok end
end

fn commit_session(p_tmp: MpText, p_path: MpText): void =
  if rename(addr2str(text_ptr(p_tmp)), addr2str(text_ptr(p_path))) = 0 then ()
  else perror("minepaint: session.conf kalici hale getirilemedi")

fn report_session_error(): void =
  perror("minepaint: session.conf yazilamadi")

fn save_atomically(p_tmp: MpText, p_path: MpText): void =
  if write_session_tmp(p_tmp) then commit_session(p_tmp, p_path)
  else report_session_error()

extern fun session_save(): void = "ext#session_save"
implement session_save() = let
  val () = ensure_dirs()
  var path_buf = @[byte][512]()
  var tmp_buf = @[byte][512]()
  val p_path = text_of(addr@(path_buf))
  val p_tmp = text_of(addr@(tmp_buf))
  val ok_path = build_session_path(p_path, g0int2uint_int_size(512), "/.config/minepaint/session.conf")
  val ok_tmp = build_session_path(p_tmp, g0int2uint_int_size(512), "/.config/minepaint/session.conf.tmp")
in
  if ok_path andalso ok_tmp then save_atomically(p_tmp, p_path)
  else report_session_error()
end
