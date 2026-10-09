// src/draw_engine/rng.dats
// Knuth's Lagged Fibonacci Double RNG ported to native ATS2
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "./engine_safe.hats"
staload "draw_engine/rng_box.sats"
staload "sys/libc.dats"

#define KK 10
#define LL 7
#define QUALITY 19
#define TT 7

#define RNG_DOUBLE_SIZE 240

// Durum düzeni (double dizisi): [0..9] u, [10..28] buf, sonra arr_pos (int).
// Öz-referanslı pointer yerine buf içindeki konum indeks olarak tutulur.
#define RNG_ARR_POS_BYTE_OFFSET 232
#define RNG_ARR_NONE (~1)

fn mp_rng_get_u(s: MpRng, i: int): double =
  airlock_dget_n(rng_ptr(s), i, 10)

fn mp_rng_set_u(s: MpRng, i: int, v: double): void =
  airlock_dset_n(rng_ptr(s), i, 10, v)

fn mp_rng_get_buf(s: MpRng, i: int): double = let
  val base = rng_ptr(rng_add_dbl(s, 10))
in
  airlock_dget_n(base, i, 19)
end

fn mp_rng_set_buf(s: MpRng, i: int, v: double): void = let
  val base = rng_ptr(rng_add_dbl(s, 10))
in
  airlock_dset_n(base, i, 19, v)
end

fn sdget(u: DblBuf, i: int): double = airlock_dget_n(dbl_ptr(u), i, 19)
fn sdset(u: DblBuf, i: int, v: double): void = airlock_dset_n(dbl_ptr(u), i, 19, v)

fn mp_rng_get_buf_ptr(s: MpRng, i: int): DblBuf =
  dbl_of(rng_ptr(rng_add_dbl(s, 10 + i)))

fn mp_rng_get_arr_pos(s: MpRng): int =
  airlock_iget_n(rng_ptr(rng_add_byte(s, RNG_ARR_POS_BYTE_OFFSET)), 0, 1)

fn mp_rng_set_arr_pos(s: MpRng, v: int): void =
  airlock_iset_n(rng_ptr(rng_add_byte(s, RNG_ARR_POS_BYTE_OFFSET)), 0, 1, v)

fn mod_sum(x: double, y: double): double = let
  val s = x + y
  val i = g0float2int_double_int(s)
in
  s - g0int2float_int_double(i)
end

fn is_odd(s: lint): bool =
  g0int_mod_lint(s, 2L) != 0L

extern fun rng_double_get_array(self: MpRng, aa: DblBuf, n: int): void = "ext#rng_double_get_array"
implement rng_double_get_array(self, aa, n) = let
  fun loop1(j: int): void =
    if j < KK then (sdset(aa, j, mp_rng_get_u(self, j)); loop1(j + 1)) else ()
  val () = loop1(0)

  fun loop2(j: int): int =
    if j < n then let
      val v = mod_sum(sdget(aa, j - KK), sdget(aa, j - LL))
      val () = sdset(aa, j, v)
    in loop2(j + 1) end else j
  val j_after2 = loop2(KK)

  fun loop3(i: int, j: int): @(int, int) =
    if i < LL then let
      val v = mod_sum(sdget(aa, j - KK), sdget(aa, j - LL))
      val () = mp_rng_set_u(self, i, v)
    in loop3(i + 1, j + 1) end else @(i, j)
  val @(i3, j3) = loop3(0, j_after2)

  fun loop4(i: int, j: int): void =
    if i < KK then let
      val v = mod_sum(sdget(aa, j - KK), mp_rng_get_u(self, i - LL))
      val () = mp_rng_set_u(self, i, v)
    in loop4(i + 1, j + 1) end else ()
  val () = loop4(i3, j3)
in () end

fn seed_init_u(u_ptr: DblBuf, ss_init: double, ulp: double): void = let
  fun loop_boot(j: int, ss: double): void =
    if j < KK then let
      val () = sdset(u_ptr, j, ss)
      val ss2 = ss + ss
      val ss_next = if ss2 >= 1.0 then ss2 - (1.0 - 2.0 * ulp) else ss2
    in loop_boot(j + 1, ss_next) end else ()
  val () = loop_boot(0, ss_init)
  val () = sdset(u_ptr, 1, sdget(u_ptr, 1) + ulp)
in () end

fn seed_square_and_fold(u_ptr: DblBuf): void = let
  fun loop_sq(j: int): void =
    if j > 0 then let
      val () = sdset(u_ptr, j + j, sdget(u_ptr, j))
      val () = sdset(u_ptr, j + j - 1, 0.0)
    in loop_sq(j - 1) end else ()
  val () = loop_sq(KK - 1)

  fun loop_fold(j: int): void =
    if j >= KK then let
      val uj = sdget(u_ptr, j)
      val () = sdset(u_ptr, j - (KK - LL), mod_sum(sdget(u_ptr, j - (KK - LL)), uj))
      val () = sdset(u_ptr, j - KK, mod_sum(sdget(u_ptr, j - KK), uj))
    in loop_fold(j - 1) end else ()
  val () = loop_fold(KK + KK - 2)
in () end

fn seed_shift_odd(u_ptr: DblBuf): void = let
  fun loop_shift(j: int): void =
    if j > 0 then (sdset(u_ptr, j, sdget(u_ptr, j - 1)); loop_shift(j - 1)) else ()
  val () = loop_shift(KK)
  val ukk = sdget(u_ptr, KK)
  val () = sdset(u_ptr, 0, ukk)
  val () = sdset(u_ptr, LL, mod_sum(sdget(u_ptr, LL), ukk))
in () end

fn seed_outer_step(u_ptr: DblBuf, s: lint, t: int): @(lint, int) = let
  val () = seed_square_and_fold(u_ptr)
  val () = if is_odd(s) then seed_shift_odd(u_ptr)
  val s_next = g0int_div_lint(s, 2L)
  val t_next = if s != 0L then t else t - 1
in @(s_next, t_next) end

fun seed_outer_loop(u_ptr: DblBuf, s: lint, t: int): void =
  if t > 0 then let
    val @(s_next, t_next) = seed_outer_step(u_ptr, s, t)
  in seed_outer_loop(u_ptr, s_next, t_next) end else ()

fn seed_copy_to_ran_u(self: MpRng, u_ptr: DblBuf): void = let
  fun loop1(j: int): void =
    if j < LL then (mp_rng_set_u(self, j + KK - LL, sdget(u_ptr, j)); loop1(j + 1)) else ()
  val () = loop1(0)
  fun loop2(j: int): void =
    if j < KK then (mp_rng_set_u(self, j - LL, sdget(u_ptr, j)); loop2(j + 1)) else ()
  val () = loop2(LL)
  fun loop_warm(j: int): void =
    if j < 10 then (rng_double_get_array(self, u_ptr, KK + KK - 1); loop_warm(j + 1)) else ()
  val () = loop_warm(0)
in () end

extern fun rng_double_set_seed(self: MpRng, seed: lint): void = "ext#rng_double_set_seed"
implement rng_double_set_seed(self, seed) = let
  var u_buf: @[double][19]
  val u_ptr = dbl_of(addr@(u_buf))
  val ulp: double = (1.0 / 1073741824.0) / 4194304.0
  val seed_masked = g0int_mod_lint(seed, 1073741824L)
  val seed_dbl = g0int2float_lint_double(seed_masked + 2L)
  val ss_init: double = 2.0 * ulp * seed_dbl

  val () = seed_init_u(u_ptr, ss_init, ulp)
  val () = seed_outer_loop(u_ptr, seed_masked, TT - 1)
  val () = seed_copy_to_ran_u(self, u_ptr)
  val () = mp_rng_set_arr_pos(self, RNG_ARR_NONE)
in () end

extern fun rng_double_cycle(self: MpRng): double = "ext#rng_double_cycle"
implement rng_double_cycle(self) = let
  val buf_ptr = mp_rng_get_buf_ptr(self, 0)
  val () = rng_double_get_array(self, buf_ptr, QUALITY)
  val () = mp_rng_set_buf(self, KK, ~1.0)
  val () = mp_rng_set_arr_pos(self, 1)
in
  mp_rng_get_buf(self, 0)
end

extern fun rng_double_next(self: MpRng): double = "ext#rng_double_next"
implement rng_double_next(self) = let
  val pos = mp_rng_get_arr_pos(self)
in
  if pos < 0 then rng_double_cycle(self)
  else let
    val v = mp_rng_get_buf(self, pos)
  in
    if v >= 0.0 then let
      val () = mp_rng_set_arr_pos(self, pos + 1)
    in v end
    else rng_double_cycle(self)
  end
end

extern fun rng_double_new(seed: lint): MpRng = "ext#rng_double_new"
implement rng_double_new(seed) = let
  val sz = g0int2uint_int_size(RNG_DOUBLE_SIZE)
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val r = rng_of(p)
  val () = mp_rng_set_arr_pos(r, RNG_ARR_NONE)
  val () = rng_double_set_seed(r, seed)
in
  r
end

extern fun rng_double_free(self: MpRng): void = "ext#rng_double_free"
implement rng_double_free(self) =
  if rng_is_null(self) = 0 then free(rng_ptr(self)) else ()

extern fun rand_gauss(rng: MpRng): float = "ext#rand_gauss"
implement rand_gauss(rng) = let
  val s1 = rng_double_next(rng)
  val s2 = rng_double_next(rng)
  val s3 = rng_double_next(rng)
  val s4 = rng_double_next(rng)
  val sum = s1 + s2 + s3 + s4
  val res: double = sum * 1.73205080757 - 3.46410161514
in
  g0float2float_double_float(res)
end
