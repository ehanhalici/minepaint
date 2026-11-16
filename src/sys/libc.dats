#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/io_box.sats"
staload "sys/fs_io.sats"
staload "sys/buf.sats"
staload "sys/clock_io.sats"
staload "sys/log_io.sats"
#include "sys/airlock.hats"

typedef mp_timeval = $extype_struct "mp_timeval" of {
  tv_sec= lint,
  tv_usec= lint
}

extern fun malloc(sz: size_t): ptr = "mac#"
extern fun free(p: ptr): void = "mac#"
extern fun memset(p: ptr, v: int, sz: size_t): ptr = "mac#"

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

extern fun sscanf_i{n:int}(s: !Text(n), fmt: string, i: &int): int = "mac#sscanf"
extern fun sscanf_f{n:int}(s: !Text(n), fmt: string, a: &float): int = "mac#sscanf"
extern fun sscanf_fff{n:int}(s: !Text(n), fmt: string, a: &float, b: &float, c: &float): int = "mac#sscanf"
extern fun sscanf_ifff{n:int}(s: !Text(n), fmt: string, i: &int, a: &float, b: &float, c: &float): int = "mac#sscanf"

implement get_time_seconds(pf | ) = let
  var tv: mp_timeval
  val () = tv.tv_sec := 0L
  val () = tv.tv_usec := 0L
  val _ = gettimeofday(tv, the_null_ptr)
  val sec = g0int2float_lint_double(tv.tv_sec)
  val usec = g0int2float_lint_double(tv.tv_usec)
in
  g0float_add_double(sec, g0float_div_double(usec, 1000000.0))
end

implement log_error(pf | msg) = fprintln!(stderr_ref, msg)

implement sleep_usec(pf | usec) = let
  val _ = usleep(usec)
in () end

// --- Bellek sinirinin tek yeri (kural R10): malloc/free/memset yalniz bu dosyada cagrilir. ---
// heap_new sifirlanmis bellek dondurur; basarisizlik tasarim ihlalidir (anth_die).
extern fun heap_new(sz: size_t): ptr = "ext#heap_new"
implement heap_new(sz) = let
  val p = malloc(sz)
  val () = anth_require(p > the_null_ptr)
  val _ = memset(p, 0, sz)
in p end

extern fun heap_free(p: ptr): void = "ext#heap_free"
implement heap_free(p) = free(p)

extern fun bytes_zero(p: ptr, n: int): void = "ext#bytes_zero"
implement bytes_zero(p, n) = let
  val _ = memset(p, 0, g0int2uint_int_size(n))
in () end

// --- Dosya sahipligi (sanctioned assume: File) ---
assume File = ptr

extern fun c_fopen{n:int}(path: !Text(n), mode: string): ptr = "mac#fopen"
extern fun c_fclose(f: ptr): int = "mac#fclose"

implement file_open{n}(pf | path, mode) = let
  val p = c_fopen(path, mode)
in
  if p > the_null_ptr then Some_vt(p) else None_vt()
end

implement file_close(pf | f) = let
  val _ = c_fclose(f)
in () end

// --- Tampon sahipligi (sanctioned assume: Buf) ---
assume Buf(k, n) = ptr
assume Text(n) = ptr
assume TextRaw(n) = ptr

implement buf_new{k}{n}(n) = heap_new(g0int2uint_int_size(n))
implement buf_free{k}{n}(b) = heap_free(b)
implement text_new{n}(n) = heap_new(g0int2uint_int_size(n))
implement text_free{n}(b) = heap_free(b)

// Muhur: son bayta 0 yazar (tek depolama; i = n-1 statik olarak < n).
extern fun c_text_store0{n,i:int | 0 <= i; i < n}(b: !TextRaw(n), i: int(i)): void = "mac#mp_text_store0"
implement text_seal{n}(b, n) = c_text_store0{n, n-1}(b, n - 1)

// text_len: sinirli ozyineleme (olcu n - 1 - i); son bayt sifir oldugundan (Text degismezi) tarama n-1'de durur.
fun text_scan {n:pos}{i:nat | i < n} .<n - i>. (b: !Text(n), n: int(n), i: int(i)): [m:nat | m < n] int(m) =
  if i + 1 < n then (if text_at{n,i}(b, i) = 0 then i else text_scan(b, n, i + 1)) else i

implement text_len{n}(b, n) = text_scan(b, n, 0)
