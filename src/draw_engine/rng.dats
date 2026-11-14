// src/draw_engine/rng.dats
// Knuth's Lagged Fibonacci Double RNG ported to native ATS2
// E.3: durum tipli `arrayref` arenasindadir; tutamac Ix(RNG_CAP). Ham ptr ve sinir hava kilidi yok.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

#include "sys/airlock.hats"
#include "sys/arena.hats"
staload "sys/libc.dats"

#define KK 10
#define LL 7
#define QUALITY 19
#define TT 7

#define RNG_CAP 8
#define RNG_NONE (~1)
#define RNG_BUFS 9
#define RNG_SCRATCH 8
#define RNG_U_SLOTS 80
#define RNG_BUF_SLOTS 171

typedef RIx = Ix(RNG_CAP)
typedef BufIx = Ix(RNG_BUFS)

// Durum: g_u[h*10+i] (u), g_buf[b*19+i] (buf; b = h veya gecici RNG_SCRATCH), g_pos[h] (arr_pos).
val g_alive = arrayref_make_elt<int>(i2sz(RNG_CAP), 0)
val g_pos = arrayref_make_elt<int>(i2sz(RNG_CAP), RNG_NONE)
val g_u = arrayref_make_elt<double>(i2sz(RNG_U_SLOTS), 0.0)
val g_buf = arrayref_make_elt<double>(i2sz(RNG_BUF_SLOTS), 0.0)

fn u_slot {h:nat | h < RNG_CAP}{i:nat | i < KK} (h: int(h), i: int(i)): [s:nat | s < RNG_U_SLOTS] int(s) =
  h * KK + i

fn buf_slot {h:nat | h < RNG_BUFS}{i:nat | i < QUALITY} (h: int(h), i: int(i)): [s:nat | s < RNG_BUF_SLOTS] int(s) =
  h * QUALITY + i

// Sozlesme: erisim her zaman aralik icinde olmalidir; disi tasarim ihlalidir (sessiz varsayilan yok).
fn mp_rng_get_u(s: RIx, i: int): double = let
  val @(ok, k) = ix_try(i, KK)
in
  if ok then g_u[u_slot(s, k)] else anth_die_dbl(DieContractViolation())
end

fn mp_rng_set_u(s: RIx, i: int, v: double): void = let
  val @(ok, k) = ix_try(i, KK)
in
  if ok then g_u[u_slot(s, k)] := v else anth_die_void(DieContractViolation())
end

fn sdget(b: BufIx, i: int): double = let
  val @(ok, k) = ix_try(i, QUALITY)
in
  if ok then g_buf[buf_slot(b, k)] else anth_die_dbl(DieContractViolation())
end

fn sdset(b: BufIx, i: int, v: double): void = let
  val @(ok, k) = ix_try(i, QUALITY)
in
  if ok then g_buf[buf_slot(b, k)] := v else anth_die_void(DieContractViolation())
end

fn buf_of(s: RIx): BufIx = s

fn mp_rng_get_buf(s: RIx, i: int): double = sdget(buf_of(s), i)
fn mp_rng_set_buf(s: RIx, i: int, v: double): void = sdset(buf_of(s), i, v)

fn mp_rng_get_arr_pos(s: RIx): int = g_pos[s]
fn mp_rng_set_arr_pos(s: RIx, v: int): void = g_pos[s] := v

fn mod_sum(x: double, y: double): double = let
  val s = x + y
  val i = g0float2int_double_int(s)
in
  s - g0int2float_int_double(i)
end

fn is_odd(s: lint): bool =
  g0int_mod_lint(s, 2L) != 0L

fn rng_double_get_array(self: RIx, aa: BufIx, n: int): void = let
  fnx loop1 {j:nat | j <= KK} .<KK - j>. (j: int(j)): void =
    if j >= KK then ()
    else let
      val () = sdset(aa, j, mp_rng_get_u(self, j))
    in loop1(j + 1) end
  val () = loop1(0)

  val [nn:int] n_ix = airlock_int(n)
  fnx loop2 {j:nat | j <= nn} .<nn - j>. (j: int(j)): int =
    if j < n_ix then let
      val v = mod_sum(sdget(aa, j - KK), sdget(aa, j - LL))
      val () = sdset(aa, j, v)
    in loop2(j + 1) end
    else j
  val j_after2 = if KK <= n_ix then loop2(KK) else KK

  fnx loop3 {i:nat | i <= LL} .<LL - i>. (i: int(i), j: int): int =
    if i >= LL then j
    else let
      val v = mod_sum(sdget(aa, j - KK), sdget(aa, j - LL))
      val () = mp_rng_set_u(self, i, v)
    in loop3(i + 1, j + 1) end
  val j3 = loop3(0, j_after2)

  fnx loop4 {i:nat | i <= KK} .<KK - i>. (i: int(i), j: int): void =
    if i >= KK then ()
    else let
      val v = mod_sum(sdget(aa, j - KK), mp_rng_get_u(self, i - LL))
      val () = mp_rng_set_u(self, i, v)
    in loop4(i + 1, j + 1) end
  val () = loop4(LL, j3)
in () end

fn seed_init_u(u_ptr: BufIx, ss_init: double, ulp: double): void = let
  fnx loop_boot {j:nat | j <= KK} .<KK - j>. (j: int(j), ss: double): void =
    if j >= KK then ()
    else let
      val () = sdset(u_ptr, j, ss)
      val ss2 = ss + ss
      val ss_next = if ss2 >= 1.0 then ss2 - (1.0 - 2.0 * ulp) else ss2
    in loop_boot(j + 1, ss_next) end
  val () = loop_boot(0, ss_init)
  val () = sdset(u_ptr, 1, sdget(u_ptr, 1) + ulp)
in () end

fn seed_square_and_fold(u_ptr: BufIx): void = let
  fnx loop_sq {j:nat} .<j>. (j: int(j)): void =
    if j > 0 then let
      val () = sdset(u_ptr, j + j, sdget(u_ptr, j))
      val () = sdset(u_ptr, j + j - 1, 0.0)
    in loop_sq(j - 1) end else ()
  val () = loop_sq(KK - 1)

  fnx loop_fold {j:nat} .<j>. (j: int(j)): void =
    if j >= KK then let
      val uj = sdget(u_ptr, j)
      val () = sdset(u_ptr, j - (KK - LL), mod_sum(sdget(u_ptr, j - (KK - LL)), uj))
      val () = sdset(u_ptr, j - KK, mod_sum(sdget(u_ptr, j - KK), uj))
    in loop_fold(j - 1) end else ()
  val () = loop_fold(KK + KK - 2)
in () end

fn seed_shift_odd(u_ptr: BufIx): void = let
  fnx loop_shift {j:nat} .<j>. (j: int(j)): void =
    if j > 0 then let
      val () = sdset(u_ptr, j, sdget(u_ptr, j - 1))
    in loop_shift(j - 1) end else ()
  val () = loop_shift(KK)
  val ukk = sdget(u_ptr, KK)
  val () = sdset(u_ptr, 0, ukk)
  val () = sdset(u_ptr, LL, mod_sum(sdget(u_ptr, LL), ukk))
in () end

fn seed_outer_step(u_ptr: BufIx, s: lint, t: int): @(lint, int) = let
  val () = seed_square_and_fold(u_ptr)
  val () = if is_odd(s) then seed_shift_odd(u_ptr)
  val s_next = g0int_div_lint(s, 2L)
  val t_next = if s != 0L then t else t - 1
in @(s_next, t_next) end

// Olcu SEED_STEPS - i. s < 2^30 her adim yarilanir (en cok 30 adim), s = 0 olunca t her adim
// azalir (TT - 1 adim): gerekli en cok 36 adim; 64 tavan bir tasarim ihlalidir.
#define SEED_STEPS 64
fnx seed_outer_loop {i:nat | i <= SEED_STEPS} .<SEED_STEPS - i>. (
  i: int(i), u_ptr: BufIx, s: lint, t: int
): void =
  if t > 0 then
    if i < SEED_STEPS then let
      val @(s_next, t_next) = seed_outer_step(u_ptr, s, t)
    in seed_outer_loop(i + 1, u_ptr, s_next, t_next) end
    else anth_die_void(DieContractViolation())
  else ()

fn seed_copy_to_ran_u(self: RIx, u_ptr: BufIx): void = let
  fnx loop1 {j:nat | j <= LL} .<LL - j>. (j: int(j)): void =
    if j >= LL then ()
    else let
      val () = mp_rng_set_u(self, j + KK - LL, sdget(u_ptr, j))
    in loop1(j + 1) end
  val () = loop1(0)
  fnx loop2 {j:nat | j <= KK} .<KK - j>. (j: int(j)): void =
    if j >= KK then ()
    else let
      val () = mp_rng_set_u(self, j - LL, sdget(u_ptr, j))
    in loop2(j + 1) end
  val () = loop2(LL)
  fnx loop_warm {j:nat | j <= 10} .<10 - j>. (j: int(j)): void =
    if j >= 10 then ()
    else let
      val () = rng_double_get_array(self, u_ptr, KK + KK - 1)
    in loop_warm(j + 1) end
  val () = loop_warm(0)
in () end

fn rng_double_set_seed(self: RIx, seed: lint): void = let
  val u_ptr: BufIx = RNG_SCRATCH
  val ulp: double = (1.0 / 1073741824.0) / 4194304.0
  val seed_masked = g0int_mod_lint(seed, 1073741824L)
  val seed_dbl = g0int2float_lint_double(seed_masked + 2L)
  val ss_init: double = 2.0 * ulp * seed_dbl

  val () = seed_init_u(u_ptr, ss_init, ulp)
  val () = seed_outer_loop(0, u_ptr, seed_masked, TT - 1)
  val () = seed_copy_to_ran_u(self, u_ptr)
  val () = mp_rng_set_arr_pos(self, RNG_NONE)
in () end

fn rng_double_cycle(self: RIx): double = let
  val () = rng_double_get_array(self, buf_of(self), QUALITY)
  val () = mp_rng_set_buf(self, KK, ~1.0)
  val () = mp_rng_set_arr_pos(self, 1)
in
  mp_rng_get_buf(self, 0)
end

// Yasayan rng'nin tipli indeksi: @(yasiyor_mu, indeks). Indeks her zaman aralik icindedir.
fn live_rng(h: int): @(bool, RIx) = let
  val @(ok, r) = ix_try(h, RNG_CAP)
in
  @(ok * (g_alive[r] != 0), r)
end

fn next_live(r: RIx): double = let
  val pos = mp_rng_get_arr_pos(r)
in
  if pos < 0 then rng_double_cycle(r)
  else let
    val v = mp_rng_get_buf(r, pos)
  in
    if v >= 0.0 then let
      val () = mp_rng_set_arr_pos(r, pos + 1)
    in v end
    else rng_double_cycle(r)
  end
end

extern fun rng_double_next(h: int): double = "ext#rng_double_next"
implement rng_double_next(h) = let
  val @(ok, r) = live_rng(h)
in
  if ok then next_live(r) else 0.0
end

// Bos yuvayi arar (olcu: RNG_CAP - i); dolu ise tasarim ihlali (yuva sayisi BRUSH_CAP ile esittir).
fun find_slot {i:nat | i <= RNG_CAP} .<RNG_CAP - i>. (i: int(i)): int =
  if i < RNG_CAP then
    (if g_alive[i] = 0 then i else find_slot(i + 1))
  else anth_die_int(DieContractViolation())

extern fun rng_double_new(seed: lint): int = "ext#rng_double_new"
implement rng_double_new(seed) = let
  val h = find_slot(0)
  val @(ok, r) = ix_try(h, RNG_CAP)
in
  if ok then let
    val () = g_alive[r] := 1
    val () = rng_double_set_seed(r, seed)
  in h end
  else anth_die_int(DieContractViolation())
end

extern fun rng_double_free(h: int): void = "ext#rng_double_free"
implement rng_double_free(h) = let
  val @(ok, r) = live_rng(h)
in
  if ok then (g_alive[r] := 0; g_pos[r] := RNG_NONE) else ()
end

extern fun rand_gauss(h: int): float = "ext#rand_gauss"
implement rand_gauss(h) = let
  val s1 = rng_double_next(h)
  val s2 = rng_double_next(h)
  val s3 = rng_double_next(h)
  val s4 = rng_double_next(h)
  val sum = s1 + s2 + s3 + s4
  val res: double = sum * 1.73205080757 - 3.46410161514
in
  g0float2float_double_float(res)
end
