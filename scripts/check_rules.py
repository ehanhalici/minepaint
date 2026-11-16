#!/usr/bin/env python3
"""kural kapisi: yasakli yapilari ve metriksiz ozyinelemeyi grep/tarama ile denetler.

Cikis kodu 0: tum kurallar saglandi; 1: ihlal var (satir satir yazilir).
Kurallar:
  R1 yasakli simgeler: $UNSAFE, castfn, %{ ... , $extfcall (src altinda hicbir yerde)
  R2 `assume` yalniz izinli sahip modullerde (ASSUME_ALLOWED: dosya -> sayi)
  R3 `praxi` yalniz src/sys/capability.sats; `extern prfun` hicbir yerde yok
  R4 `mp_id_ptr` .dats/.hats icinde adlandirilamaz (yalniz .sats ve cprelude.h)
  R5 kendini cagiran fun/fnx metrik (.<...>.) tasimali; tek istisna "tek izinli sonsuz dongu" isaretli fonksiyon
  R6 fonksiyon govdesi icinde `case-` / duz `case` yok (yalniz case+)
  R8 ptr tabanli sinir hava kilidi ailesi (airlock_*_n, airlock_alloc) yok: tamponlar tipli arrayref + Ix(n)
  R9 `gl*` (GL) bildirimleri yalniz src/gl/gl_io.sats icinde (GL_IO efekt kaniti); glX* yalniz src/gl/glx.dats
  R10 malloc/free/memset/realloc cagrilari yalniz src/sys/libc.dats (heap_new/heap_free/bytes_zero)
  R11 etki bildirimleri tek yerde: X11 sunucu cagrilari (X*, mp_x_*, c_xi2_query_*/cookie_get|free_data...; salt veri okuyucular serbest) x11/x_io.sats; dosya/ortam (fopen..getenv) sys/fs_io.sats; zaman (gettimeofday, usleep) sys/libc.dats + clock_io.sats
  R13 odunc "gorunum" tipi yok: MpText/MpXEvent/MpSwa/MpHints/MpDisplay/MpVisual/MpXVisual/MpGlCtx yasak (sahipli Buf(k)/Display + `!`)
  R15 joker kolu yok: `| _ =>` yasak (kapsamli case+; dis dunya tamsayilari tipli tablolarla ayristirilir)
  R16 .cats/.h icinde algoritma yok: for/while yalniz sinir korumasi airlock_cstr_len'de (algoritma ATS'tedir)
  R19 Text(n) NUL kaniti (tip durumu): `!Text` alan C islemleri yalniz salt okurlardir; yazicilar `!Text(n) >> TextRaw(n)` tipindedir ve ancak text_seal ile Text'e doner
  R18 cap_mint/cap_burn yalniz kanit ureten kaynak modullerde (mapping, brush, layer, canvas, window, effect_root)
  R17 fonksiyon govdesi <= 20 satir (tek istisna: varyant basina bir kol olan tam kapsamli kod tablolari setting_ix, state_ix)
  R14 ekran/baglam yasam dongusu cagrilari (mp_x_open_display, mp_x_close_display, glXCreateContext, glXDestroyContext) yalniz window.dats
  R7 duz `Option(`/`Some(`/`None()` yok: kutulu kurucu her cagrida bellek ayirir ve GC yoktur
     (Option_vt / option_v / duz demet @(bool, x) kullanin)
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "src")
EXT = (".dats", ".sats", ".hats", ".cats", ".h")
violations = []


def files():
    for d, _, fs in os.walk(SRC):
        for f in sorted(fs):
            if f.endswith(EXT):
                yield os.path.join(d, f)


def rel(p):
    return os.path.relpath(p, ROOT)


def strip_comment(line):
    i = line.find("//")
    return line[:i] if i >= 0 else line


def check_tokens(path, lines):
    for n, raw in enumerate(lines, 1):
        l = strip_comment(raw)
        if re.search(r"\$UNSAFE|\bcastfn\b|%\{|\$extfcall", l):
            violations.append("R1 %s:%d yasakli simge: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bextern\s+prfun\b", l):
            violations.append("R3 %s:%d extern prfun yasak: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bpraxi\b", l) and not path.endswith("sys/capability.sats"):
            violations.append("R3 %s:%d praxi yalniz capability.sats: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bmp_id_ptr\b", l) and path.endswith((".dats", ".hats")):
            violations.append("R4 %s:%d mp_id_ptr yalniz .sats/cprelude.h: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bOption\(|\bSome\(|\bNone\(\)", l):
            violations.append("R7 %s:%d kutulu Option/Some/None yasak (bellek sizintisi): %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bfun\s+gl(?!X)[A-Z]\w*\s*[({]", l) and not path.endswith("gl/gl_io.sats"):
            violations.append("R9 %s:%d GL bildirimi yalniz gl_io.sats: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bfun\s+glX\w*\s*[({]", l) and not path.endswith("gl/glx.dats"):
            violations.append("R9 %s:%d glX bildirimi yalniz glx.dats: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\b(malloc|free|memset|realloc)\(", l) and not path.endswith("sys/libc.dats") and not path.endswith(".h") and not path.endswith(".cats"):
            violations.append("R10 %s:%d ham bellek cagrisi yalniz libc.dats: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bfun\s+(X[A-Z]\w*|mp_x_(?!default_screen|root_window)\w+|mp_XCreateWindow|c_xi2_(?:query_\w+|select_root_events|device_class_val_label|cookie_get_data|cookie_free_data))\s*[({]", l) and not path.endswith("x11/x_io.sats"):
            violations.append("R11 %s:%d X11 bildirimi yalniz x_io.sats: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bfun\s+(fopen|fclose|fgets|fputs|fflush|fileno|fsync|rename|perror|fseek|ftell|rewind|getenv|mkdir)\s*\(", l) and not path.endswith("sys/fs_io.sats"):
            violations.append("R11 %s:%d dosya/ortam bildirimi yalniz fs_io.sats: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bfun\s+(gettimeofday|usleep)\s*\(", l) and not path.endswith("sys/libc.dats"):
            violations.append("R11 %s:%d zaman bildirimi yalniz libc.dats: %s" % (rel(path), n, raw.strip()))
        if path.endswith((".dats", ".hats")) and re.search(r"\b(stderr_ref|stdout_ref|fprint\w*!?|println!?|prerr\w*)\b", l) and not path.endswith(("sys/libc.dats", "sys/airlock.dats")):
            violations.append("R11 %s:%d stderr/stdout yazimi yalniz libc.dats (LOG_IO): %s" % (rel(path), n, raw.strip()))
        if re.search(r"\b(MpText|MpXEvent|MpSwa|MpHints|MpDisplay|MpVisual|MpXVisual|MpGlCtx)\b|\b(text_of|xev_of|swa_of|hints_of|buf_ptr|dpy_of|text_str)\(", l):
            violations.append("R13 %s:%d odunc gorunum tipi yasak (sahipli Buf(k)/Display kullanin): %s" % (rel(path), n, raw.strip()))
        if re.search(r"\b(mp_x_open_display|mp_x_close_display|glXCreateContext|glXDestroyContext)\(", l) and path.endswith((".dats", ".hats")) and not path.endswith(("window/window.dats", "gl/glx.dats")):
            violations.append("R14 %s:%d yasam dongusu cagrisi yalniz window.dats: %s" % (rel(path), n, raw.strip()))
        m19 = re.search(r"\bText\(.*\"mac#(\w*)\"", l)
        if m19 and ">> TextRaw" not in l and m19.group(1) not in TEXT_C_ALLOWED:
            violations.append("R19 %s:%d Text(n) degismezi (NUL sonlu): yalniz izinli C islemleri Text alir: %s" % (rel(path), n, raw.strip()))
        if path.endswith((".dats", ".hats")) and re.search(r"\bcap_(mint|burn)\b", l) and not path.endswith(CAP_SITES):
            violations.append("R18 %s:%d cap_mint/cap_burn yalniz *_new/*_claim/*_stash/*_free kaynak modullerinde: %s" % (rel(path), n, raw.strip()))
        if re.search(r"\bairlock_[a-z0-9]*_n\b|\bairlock_alloc\b", l):
            violations.append("R8 %s:%d ptr tamponu hava kilidi yasak (tipli arrayref kullanin): %s" % (rel(path), n, raw.strip()))
        if re.search(r"^\s*case-\s", l) or re.search(r"\bcase-\b", l):
            violations.append("R6 %s:%d case- yasak: %s" % (rel(path), n, raw.strip()))


TEXT_C_ALLOWED = ("sscanf", "fopen", "fputs", "rename", "mkdir", "strcasestr", "mp_text_byte")
CAP_SITES = ("draw_engine/mapping.dats", "draw_engine/brush.dats", "canvas/layer.dats", "canvas/canvas.dats", "window/window.dats", "sys/effect_root.dats")
LENGTH_EXEMPT = ("setting_ix", "state_ix")
FN_HDR = re.compile(r"^(fun|fn|fnx|implement|and)\b")
FN_END = re.compile(r"^(fun|fn|fnx|implement|extern|val|datatype|dataviewtype|typedef|vtypedef|macdef|staload|#|and|local|end|overload|stadef|sortdef|praxi|prfun|absview|absvtype|abst|assume|dataprop|dataview|infix|//)")


def check_length(path, lines):
    i = 0
    while i < len(lines):
        if not FN_HDR.match(lines[i]):
            i += 1
            continue
        j = i + 1
        while j < len(lines) and not (lines[j] and FN_END.match(lines[j])):
            j += 1
        n = j - i
        while n > 1 and (not lines[i + n - 1].strip() or lines[i + n - 1].strip().startswith("//")):
            n -= 1
        m = re.search(r"\b(?:fun|fn|fnx|implement|and)\s+(?:\{[^}]*\}\s*)*(\w+)", lines[i])
        name = m.group(1) if m else ""
        if n > 20 and name not in LENGTH_EXEMPT:
            violations.append("R17 %s:%d fonksiyon %s %d satir (>20)" % (rel(path), i + 1, name, n))
        i = j


def check_misc(path, lines):
    for n, raw in enumerate(lines, 1):
        l = strip_comment(raw)
        if path.endswith((".dats", ".hats")) and re.search(r"\|\s*_\s*=>", l):
            violations.append("R15 %s:%d joker kolu yasak: %s" % (rel(path), n, raw.strip()))
        if path.endswith((".cats", ".h")) and re.search(r"\b(for|while)\s*\(", l) and "airlock_cstr_len" not in "".join(lines[max(0, n - 4):n]):
            violations.append("R16 %s:%d C tarafinda algoritma yasak: %s" % (rel(path), n, raw.strip()))


ASSUME_RE = re.compile(r"^\s*assume\s")


# Sahipli (dogrusal) tip basina tek `assume`, sahip modulde. dosya -> beklenen sayi.
ASSUME_ALLOWED = {
    "window/window.dats": 4,   # MpApp, Display, GlCtx, Vis
    "x11/xi2.dats": 1,         # DevList
    "sys/libc.dats": 4,        # File, Buf, Text, TextRaw
}


def check_assume(all_lines):
    found = {}
    for path, lines in all_lines.items():
        for n, raw in enumerate(lines, 1):
            if ASSUME_RE.match(strip_comment(raw)):
                key = next((k for k in ASSUME_ALLOWED if path.endswith(k)), None)
                if key is None:
                    violations.append("R2 %s:%d izinsiz assume" % (rel(path), n))
                else:
                    found[key] = found.get(key, 0) + 1
    for key, want in ASSUME_ALLOWED.items():
        if found.get(key, 0) != want:
            violations.append("R2 %s icinde tam %d assume beklenir, bulundu: %d" % (key, want, found.get(key, 0)))


HDR = re.compile(r"^([ \t]*)(fun|fnx)[ \t]+(?:\{[^}]*\}[ \t]*)*(\w+)")
TOP = re.compile(r"^(fun|fn|fnx|implement|extern|val|datatype|dataviewtype|typedef|macdef|staload|#|and|local|overload|stadef|sortdef|praxi|prfun|absview|absvtype|abst)")


def header_end(text, start):
    d = 0
    i = start
    n = len(text)
    while i < n:
        c = text[i]
        if c in "([{":
            d += 1
        elif c in ")]}":
            d -= 1
        elif c == "=" and d == 0:
            prev = text[i - 1]
            nxt = text[i + 1] if i + 1 < n else " "
            if prev not in "<>=!:" and nxt not in "=>":
                return i
        i += 1
    return n


def merge_split_headers(lines):
    # `fun {..}` + satir sonu + `ad(`: ad bir sonraki satirdadir; satir sayisi korunur.
    out = list(lines)
    for i in range(len(out) - 1):
        if re.match(r"^(fun|fnx)[ \t]+(\{[^}]*\}[ \t]*)*$", out[i]):
            out[i] = out[i].rstrip() + " " + out[i + 1].strip()
            out[i + 1] = ""
    return out


def check_recursion(path, lines):
    text = "\n".join(lines)
    offs = [0]
    for l in lines:
        offs.append(offs[-1] + len(l) + 1)
    for idx, l in enumerate(lines):
        m = HDR.match(strip_comment(l))
        if not m:
            continue
        ind, name = len(m.group(1)), m.group(3)
        hdr = text[offs[idx]: header_end(text, offs[idx])]
        if ".<" in hdr:
            continue
        # govde: header sonundan sonraki satirlardan, girinti geri donene kadar
        eq_line = text[:header_end(text, offs[idx])].count("\n")
        body = []
        j = eq_line + 1
        while j < len(lines):
            s = lines[j]
            if s.strip():
                li = len(s) - len(s.lstrip())
                top_cont = ind == 0 and re.match(r"(in|end|else|then|\))\b", s.strip() if s.strip()[0] != ")" else ")")
                if li <= ind and not top_cont:
                    break
                if ind == 0 and TOP.match(s):
                    break
            body.append(s)
            j += 1
        # govde ayni satirda baslayabilir
        tail_same = text[header_end(text, offs[idx]) + 1: offs[eq_line + 1] - 1] if eq_line + 1 < len(offs) else ""
        blob = tail_same + "\n" + "\n".join(body)
        if not re.search(r"\b%s\s*\(" % re.escape(name), blob):
            continue
        prev = "\n".join(lines[max(0, idx - 4): idx])
        if "tek izinli sonsuz dongu" in prev:
            continue
        violations.append("R5 %s:%d ozyineleme metriksiz: %s" % (rel(path), idx + 1, name))


def main():
    all_lines = {}
    for p in files():
        with open(p, encoding="utf-8", errors="replace") as fh:
            all_lines[p] = fh.read().split("\n")
    for p, lines in all_lines.items():
        check_tokens(p, lines)
        check_misc(p, lines)
        if p.endswith((".dats", ".hats")):
            check_recursion(p, merge_split_headers(lines))
            check_length(p, lines)
    check_assume(all_lines)
    for v in violations:
        print(v)
    print("check_rules: %d ihlal" % len(violations))
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())
