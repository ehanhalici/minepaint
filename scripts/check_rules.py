#!/usr/bin/env python3
"""kural kapisi: yasakli yapilari ve metriksiz ozyinelemeyi grep/tarama ile denetler.

Cikis kodu 0: tum kurallar saglandi; 1: ihlal var (satir satir yazilir).
Kurallar:
  R1 yasakli simgeler: $UNSAFE, castfn, %{ ... , $extfcall (src altinda hicbir yerde)
  R2 `assume` yalniz src/window/window.dats icinde ve tam bir tane (App)
  R3 `praxi` yalniz src/sys/capability.sats; `extern prfun` hicbir yerde yok
  R4 `mp_id_ptr` .dats/.hats icinde adlandirilamaz (yalniz .sats ve cprelude.h)
  R5 kendini cagiran fun/fnx metrik (.<...>.) tasimali; tek istisna "tek izinli sonsuz dongu" isaretli fonksiyon
  R6 fonksiyon govdesi icinde `case-` / duz `case` yok (yalniz case+)
  R8 ptr tabanli sinir hava kilidi ailesi (airlock_*_n, airlock_alloc) yok: tamponlar tipli arrayref + Ix(n)
  R9 `gl*` (GL) bildirimleri yalniz src/gl/gl_io.sats icinde (GL_IO efekt kaniti); glX* yalniz src/gl/glx.dats
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
        if re.search(r"\bairlock_[a-z0-9]*_n\b|\bairlock_alloc\b", l):
            violations.append("R8 %s:%d ptr tamponu hava kilidi yasak (tipli arrayref kullanin): %s" % (rel(path), n, raw.strip()))
        if re.search(r"^\s*case-\s", l) or re.search(r"\bcase-\b", l):
            violations.append("R6 %s:%d case- yasak: %s" % (rel(path), n, raw.strip()))


ASSUME_RE = re.compile(r"^\s*assume\s")


def check_assume(all_lines):
    found = []
    for path, lines in all_lines.items():
        for n, raw in enumerate(lines, 1):
            if ASSUME_RE.match(strip_comment(raw)):
                found.append((path, n))
    ok = [x for x in found if x[0].endswith("window/window.dats")]
    for path, n in found:
        if not path.endswith("window/window.dats"):
            violations.append("R2 %s:%d izinsiz assume" % (rel(path), n))
    if len(ok) != 1:
        violations.append("R2 window.dats icinde tam 1 assume beklenir, bulundu: %d" % len(ok))


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
        if p.endswith(".dats") and "/brushes/" not in p.replace("\\", "/"):
            check_recursion(p, lines)
        elif p.endswith(".dats"):
            check_recursion(p, lines)
    check_assume(all_lines)
    for v in violations:
        print(v)
    print("check_rules: %d ihlal" % len(violations))
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())
