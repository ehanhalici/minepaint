#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "sys/libc.dats"
staload "ui/state.dats"
staload "ui/palette.dats"

macdef MODE_0755 = $extval(uint, "0755")

fn cstr_empty(p: ptr): bool =
  $UN.ptr0_get<char>(p) = '\0'

fn copy_chars(dst: ptr, cap: int, src: ptr): int = let
  fun loop(di: int, s: ptr): int =
    if di >= cap - 1 then ~1
    else let
      val c = $UN.ptr0_get<char>(s)
    in
      if c = '\0' then let
        val () = $UN.ptr0_set<char>(ptr_add<char>(dst, di), '\0')
      in di end
      else let
        val () = $UN.ptr0_set<char>(ptr_add<char>(dst, di), c)
      in loop(di + 1, ptr_add<char>(s, 1)) end
    end
in
  loop(0, src)
end

fn append_chars(dst: ptr, cap: int, off: int, src: string): int = let
  val sp = $UN.cast{ptr}(src)
  fun loop(di: int, s: ptr): int =
    if di >= cap - 1 then ~1
    else let
      val c = $UN.ptr0_get<char>(s)
    in
      if c = '\0' then let
        val () = $UN.ptr0_set<char>(ptr_add<char>(dst, di), '\0')
      in di end
      else let
        val () = $UN.ptr0_set<char>(ptr_add<char>(dst, di), c)
      in loop(di + 1, ptr_add<char>(s, 1)) end
    end
in
  loop(off, sp)
end

fn make_path(suffix: string): ptr = let
  val home = getenv("HOME")
in
  if home = the_null_ptr then the_null_ptr
  else if cstr_empty(home) then the_null_ptr
  else let
    val buf = malloc(g0int2uint_int_size(512))
    val n = copy_chars(buf, 512, home)
  in
    if n < 0 then let
      val () = free(buf)
    in the_null_ptr end
    else let
      val n2 = append_chars(buf, 512, n, suffix)
    in
      if n2 < 0 then let
        val () = free(buf)
      in the_null_ptr end
      else buf
    end
  end
end

fn ensure_dirs(): void = let
  val cfg = make_path("/.config")
  val () = if cfg != the_null_ptr then let
    val _ = mkdir($UN.cast{string}(cfg), MODE_0755)
    val () = free(cfg)
  in () end else ()
  val mp = make_path("/.config/minepaint")
  val () = if mp != the_null_ptr then let
    val _ = mkdir($UN.cast{string}(mp), MODE_0755)
    val () = free(mp)
  in () end else ()
in () end

fn f2d(v: float): double = g0float2float_float_double(v)

fn apply_line(line: string): void = let
  var idx: int = 0
  var a: float = 0.0f
  var b: float = 0.0f
  var c: float = 0.0f
  val u = ui_get()
  val n4 = sscanf_ifff(line, "swatch %d %f %f %f", idx, a, b, c)
in
  if n4 = 4 then let
    val () = pal_set(idx, 0, a)
    val () = pal_set(idx, 1, b)
    val () = pal_set(idx, 2, c)
  in () end
  else let
    val n1 = sscanf_i(line, "active_swatch %d", idx)
  in
    if n1 = 1 then
      u->active_swatch := (if (idx < ~1) || (idx > 11) then ~1 else idx)
    else let
      val ng = sscanf_i(line, "group %d", idx)
    in
      if ng = 1 then
        u->active_group := (if (idx < 0) || (idx > 7) then 1 else idx)
      else let
        val nb = sscanf_i(line, "brush %d", idx)
      in
        if nb = 1 then
          u->active_brush := (if idx < ~1 then ~1 else idx)
        else let
          val ns = sscanf_i(line, "scroll %d", idx)
        in
          if ns = 1 then
            u->brush_scroll := (if idx < 0 then 0 else idx)
          else let
            val nc = sscanf_fff(line, "color %f %f %f", a, b, c)
          in
            if nc = 3 then let
              val () = u->cur_r := (if g0float_lt(a, 0.0f) then 0.0f else if g0float_gt(a, 1.0f) then 1.0f else a)
              val () = u->cur_g := (if g0float_lt(b, 0.0f) then 0.0f else if g0float_gt(b, 1.0f) then 1.0f else b)
              val () = u->cur_b := (if g0float_lt(c, 0.0f) then 0.0f else if g0float_gt(c, 1.0f) then 1.0f else c)
            in () end
            else let
              val n = sscanf_f(line, "size %f", a)
            in
              if n = 1 then u->val0 := a
              else let
                val n = sscanf_f(line, "opaque %f", a)
              in
                if n = 1 then u->val1 := a
                else let
                  val n = sscanf_f(line, "sharp %f", a)
                in
                  if n = 1 then u->val2 := a
                  else let
                    val n = sscanf_f(line, "grain %f", a)
                  in
                    if n = 1 then u->val3 := a
                    else let
                      val n = sscanf_f(line, "pigment %f", a)
                    in
                      if n = 1 then u->val4 := a
                      else let
                        val n = sscanf_f(line, "smooth %f", a)
                      in
                        if n = 1 then u->val5 := a
                        else let
                          val n = sscanf_f(line, "pressure %f", a)
                        in
                          if n = 1 then u->val6 := a
                          else let
                            val n = sscanf_f(line, "twist %f", a)
                          in
                            if n = 1 then u->val7 := a else ()
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

extern fun session_load(): int = "ext#session_load"
implement session_load() = let
  val path = make_path("/.config/minepaint/session.conf")
in
  if path = the_null_ptr then 0
  else let
    val f = fopen($UN.cast{string}(path), "r")
    val () = free(path)
  in
    if f = the_null_ptr then 0
    else let
      val buf = malloc(g0int2uint_int_size(256))
      fun loop(): void =
        if fgets(buf, 256, f) != the_null_ptr then let
          val () = apply_line($UN.cast{string}(buf))
        in loop() end else ()
      val () = loop()
      val () = free(buf)
      val _ = fclose(f)
    in 1 end
  end
end

fn put_line(f: ptr, buf: ptr): void = let
  val _ = fputs($UN.cast{string}(buf), f)
in () end

extern fun session_save(): void = "ext#session_save"
implement session_save() = let
  val () = ensure_dirs()
  val path = make_path("/.config/minepaint/session.conf")
in
  if path = the_null_ptr then ()
  else let
    val f = fopen($UN.cast{string}(path), "w")
    val () = free(path)
  in
    if f = the_null_ptr then ()
    else let
      val u = ui_get()
      val buf = malloc(g0int2uint_int_size(256))
      val cap = g0int2uint_int_size(256)
      fun swatches(i: int): void =
        if i < 12 then let
          val r = pal_get(i, 0)
          val g = pal_get(i, 1)
          val b = pal_get(i, 2)
          val _ = mp_snprintf_ifff(buf, cap, "swatch %d %.6f %.6f %.6f\n", i, f2d(r), f2d(g), f2d(b))
          val () = put_line(f, buf)
        in swatches(i + 1) end else ()
      val () = swatches(0)
      val _ = mp_snprintf_i(buf, cap, "active_swatch %d\n", u->active_swatch)
      val () = put_line(f, buf)
      val _ = mp_snprintf_i(buf, cap, "group %d\n", u->active_group)
      val () = put_line(f, buf)
      val _ = mp_snprintf_i(buf, cap, "brush %d\n", u->active_brush)
      val () = put_line(f, buf)
      val _ = mp_snprintf_i(buf, cap, "scroll %d\n", u->brush_scroll)
      val () = put_line(f, buf)
      val _ = mp_snprintf_fff(buf, cap, "color %.6f %.6f %.6f\n", f2d(u->cur_r), f2d(u->cur_g), f2d(u->cur_b))
      val () = put_line(f, buf)
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
      val () = free(buf)
      val _ = fclose(f)
    in () end
  end
end
