#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/io_box.sats"

typedef mp_timeval = $extype_struct "mp_timeval" of {
  tv_sec= lint,
  tv_usec= lint
}

extern fun malloc(sz: size_t): ptr = "mac#"
extern fun free(p: ptr): void = "mac#"
extern fun realloc(p: ptr, sz: size_t): ptr = "mac#"
extern fun memset(p: ptr, v: int, sz: size_t): ptr = "mac#"
extern fun memcpy(dst: ptr, src: ptr, sz: size_t): ptr = "mac#"

extern fun fopen(path: string, mode: string): MpFile = "mac#"
extern fun fclose(f: MpFile): int = "mac#"
extern fun fgets(buf: MpText, n: int, f: MpFile): MpText = "mac#"
extern fun fputs(s: string, f: MpFile): int = "mac#"
extern fun fflush(f: MpFile): int = "mac#"
extern fun fileno(f: MpFile): int = "mac#"
extern fun fsync(fd: int): int = "mac#"
extern fun rename(old: string, new: string): int = "mac#"
extern fun perror(msg: string): void = "mac#"
extern fun getenv(name: string): ptr = "mac#"
extern fun mkdir(path: string, mode: uint): int = "mac#"
extern fun usleep(usec: uint): int = "mac#"
extern fun gettimeofday(tv: &mp_timeval, tz: ptr): int = "mac#"

extern fun expf(x: float): float = "mac#"
extern fun logf(x: float): float = "mac#"
extern fun fabsf(x: float): float = "mac#"
extern fun fmodf(x: float, y: float): float = "mac#"
extern fun powf(x: float, y: float): float = "mac#"
extern fun hypotf(x: float, y: float): float = "mac#"
extern fun cosf(x: float): float = "mac#"
extern fun sinf(x: float): float = "mac#"
extern fun sqrtf(x: float): float = "mac#"
extern fun floorf(x: float): float = "mac#"
extern fun roundf(x: float): float = "mac#"
extern fun ceilf(x: float): float = "mac#"
extern fun rand(): int = "mac#"

extern fun mp_snprintf_f(buf: MpText, n: size_t, fmt: string, v: double): int = "mac#snprintf"
extern fun mp_snprintf_i(buf: MpText, n: size_t, fmt: string, v: int): int = "mac#snprintf"
extern fun mp_snprintf_fff(buf: MpText, n: size_t, fmt: string, a: double, b: double, c: double): int = "mac#snprintf"
extern fun mp_snprintf_ifff(buf: MpText, n: size_t, fmt: string, i: int, a: double, b: double, c: double): int = "mac#snprintf"
extern fun mp_snprintf_ss(buf: MpText, n: size_t, fmt: string, s1: string, s2: string): int = "mac#snprintf"
extern fun mp_format_path(buf: MpText, n: size_t, s1: string, s2: string): int = "ext#mp_format_path"
implement mp_format_path(buf, n, s1, s2) =
  mp_snprintf_ss(buf, n, "%s%s", s1, s2)

extern fun sscanf_i(s: string, fmt: string, i: &int): int = "mac#sscanf"
extern fun sscanf_f(s: string, fmt: string, a: &float): int = "mac#sscanf"
extern fun sscanf_fff(s: string, fmt: string, a: &float, b: &float, c: &float): int = "mac#sscanf"
extern fun sscanf_ifff(s: string, fmt: string, i: &int, a: &float, b: &float, c: &float): int = "mac#sscanf"

extern fun get_time_seconds(): double = "ext#get_time_seconds"
implement get_time_seconds() = let
  var tv: mp_timeval
  val () = tv.tv_sec := 0L
  val () = tv.tv_usec := 0L
  val _ = gettimeofday(tv, the_null_ptr)
  val sec = g0int2float_lint_double(tv.tv_sec)
  val usec = g0int2float_lint_double(tv.tv_usec)
in
  g0float_add_double(sec, g0float_div_double(usec, 1000000.0))
end
