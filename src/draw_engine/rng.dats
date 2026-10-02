// src/draw_engine/rng.dats
// Knuth's Lagged Fibonacci Double RNG ported to native ATS2
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

#define KK 10
#define LL 7
#define QUALITY 19
#define TT 7

#define RNG_DOUBLE_SIZE 240

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

// Helper accessors for RngDouble
fn get_ran_u(self: ptr, i: int): double = let
  val p = ptr_add<double>(self, i)
in
  $UN.ptr0_get<double>(p)
end

fn set_ran_u(self: ptr, i: int, v: double): void = let
  val p = ptr_add<double>(self, i)
in
  $UN.ptr0_set<double>(p, v)
end

fn get_buf(self: ptr, i: int): double = let
  val p = ptr_add<double>(self, 10 + i)
in
  $UN.ptr0_get<double>(p)
end

fn set_buf(self: ptr, i: int, v: double): void = let
  val p = ptr_add<double>(self, 10 + i)
in
  $UN.ptr0_set<double>(p, v)
end

fn get_buf_ptr(self: ptr, i: int): ptr =
  ptr_add<double>(self, 10 + i)

fn get_ranf_arr_ptr(self: ptr): ptr =
  $UN.ptr0_get<ptr>(ptr_add<double>(self, 29))

fn set_ranf_arr_ptr(self: ptr, v: ptr): void =
  $UN.ptr0_set<ptr>(ptr_add<double>(self, 29), v)

fn mod_sum(x: double, y: double): double = let
  val s = x + y
  val i = g0float2int_double_int(s)
in
  s - g0int2float_int_double(i)
end

fn is_odd(s: lint): bool =
  g0int_mod_lint(s, 2L) != 0L

extern fun rng_double_get_array(self: ptr, aa: ptr, n: int): void = "ext#rng_double_get_array"
implement rng_double_get_array(self, aa, n) = let
  fun set_aa(idx: int, v: double): void =
    $UN.ptr0_set<double>(ptr_add<double>(aa, idx), v)
  fun get_aa(idx: int): double =
    $UN.ptr0_get<double>(ptr_add<double>(aa, idx))

  // for (j=0;j<KK;j++) aa[j]=self->ran_u[j];
  fun loop1(j: int): void =
    if j < KK then (set_aa(j, get_ran_u(self, j)); loop1(j + 1))
    else ()
  val () = loop1(0)

  // for (;j<n;j++) aa[j]=mod_sum(aa[j-KK],aa[j-LL]);
  fun loop2(j: int): int =
    if j < n then let
      val v = mod_sum(get_aa(j - KK), get_aa(j - LL))
      val () = set_aa(j, v)
    in
      loop2(j + 1)
    end else j
  val j_after2 = loop2(KK)

  // for (i=0;i<LL;i++,j++) self->ran_u[i]=mod_sum(aa[j-KK],aa[j-LL]);
  fun loop3(i: int, j: int): @(int, int) =
    if i < LL then let
      val v = mod_sum(get_aa(j - KK), get_aa(j - LL))
      val () = set_ran_u(self, i, v)
    in
      loop3(i + 1, j + 1)
    end else @(i, j)
  val @(i_after3, j_after3) = loop3(0, j_after2)

  // for (;i<KK;i++,j++) self->ran_u[i]=mod_sum(aa[j-KK],self->ran_u[i-LL]);
  fun loop4(i: int, j: int): void =
    if i < KK then let
      val v = mod_sum(get_aa(j - KK), get_ran_u(self, i - LL))
      val () = set_ran_u(self, i, v)
    in
      loop4(i + 1, j + 1)
    end else ()
  val () = loop4(i_after3, j_after3)
in
  ()
end

extern fun rng_double_set_seed(self: ptr, seed: lint): void = "ext#rng_double_set_seed"
implement rng_double_set_seed(self, seed) = let
  // double u[KK+KK-1] = 19 doubles (152 bytes stack buffer)
  var u_buf: @[double][19]
  val u_ptr = addr@(u_buf)

  fn set_u(idx: int, v: double): void =
    $UN.ptr0_set<double>(ptr_add<double>(u_ptr, idx), v)
  fn get_u(idx: int): double =
    $UN.ptr0_get<double>(ptr_add<double>(u_ptr, idx))

  // double ulp=(1.0/(1L<<30))/(1L<<22); /* 2 to the -52 */
  val ulp: double = (1.0 / 1073741824.0) / 4194304.0
  val seed_masked = g0int_mod_lint(seed, 1073741824L)
  val seed_dbl = g0int2float_lint_double(seed_masked + 2L)
  val ss_init: double = 2.0 * ulp * seed_dbl

  fun loop_boot(j: int, ss: double): void =
    if j < KK then let
      val () = set_u(j, ss)
      val ss2 = ss + ss
      val ss_next = if ss2 >= 1.0 then ss2 - (1.0 - 2.0 * ulp) else ss2
    in
      loop_boot(j + 1, ss_next)
    end else ()

  val () = loop_boot(0, ss_init)
  val () = set_u(1, get_u(1) + ulp)

  // Square and cyclic shift loops
  fun loop_outer(s: lint, t: int): void =
    if t > 0 then let
      // for (j=KK-1;j>0;j--) u[j+j]=u[j],u[j+j-1]=0.0;
      fun loop_sq(j: int): void =
        if j > 0 then let
          val () = set_u(j + j, get_u(j))
          val () = set_u(j + j - 1, 0.0)
        in
          loop_sq(j - 1)
        end else ()
      val () = loop_sq(KK - 1)

      // for (j=KK+KK-2;j>=KK;j--) { u[j-(KK-LL)]=mod_sum(u[j-(KK-LL)],u[j]); u[j-KK]=mod_sum(u[j-KK],u[j]); }
      fun loop_fold(j: int): void =
        if j >= KK then let
          val uj = get_u(j)
          val () = set_u(j - (KK - LL), mod_sum(get_u(j - (KK - LL)), uj))
          val () = set_u(j - KK, mod_sum(get_u(j - KK), uj))
        in
          loop_fold(j - 1)
        end else ()
      val () = loop_fold(KK + KK - 2)

      val () =
        if is_odd(s) then let
          // for (j=KK;j>0;j--) u[j]=u[j-1];
          fun loop_shift(j: int): void =
            if j > 0 then (set_u(j, get_u(j - 1)); loop_shift(j - 1)) else ()
          val () = loop_shift(KK)
          val () = set_u(0, get_u(KK))
          val () = set_u(LL, mod_sum(get_u(LL), get_u(KK)))
        in () end

      val s_next = g0int_div_lint(s, 2L)
      val t_next = if s != 0L then t else t - 1
    in
      loop_outer(s_next, t_next)
    end else ()

  val () = loop_outer(seed_masked, TT - 1)

  // for (j=0;j<LL;j++) self->ran_u[j+KK-LL]=u[j];
  fun loop_u1(j: int): void =
    if j < LL then (set_ran_u(self, j + KK - LL, get_u(j)); loop_u1(j + 1)) else ()
  val () = loop_u1(0)

  // for (;j<KK;j++) self->ran_u[j-LL]=u[j];
  fun loop_u2(j: int): void =
    if j < KK then (set_ran_u(self, j - LL, get_u(j)); loop_u2(j + 1)) else ()
  val () = loop_u2(LL)

  // for (j=0;j<10;j++) rng_double_get_array(self, u,KK+KK-1);
  fun loop_warm(j: int): void =
    if j < 10 then (rng_double_get_array(self, u_ptr, KK + KK - 1); loop_warm(j + 1)) else ()
  val () = loop_warm(0)

  val () = set_ranf_arr_ptr(self, the_null_ptr) // marked as started/reset
in
  ()
end

extern fun rng_double_cycle(self: ptr): double = "ext#rng_double_cycle"
implement rng_double_cycle(self) = let
  val buf_ptr = get_buf_ptr(self, 0)
  val () = rng_double_get_array(self, buf_ptr, QUALITY)
  val () = set_buf(self, KK, ~1.0)
  val () = set_ranf_arr_ptr(self, get_buf_ptr(self, 1))
in
  get_buf(self, 0)
end

extern fun rng_double_next(self: ptr): double = "ext#rng_double_next"
implement rng_double_next(self) = let
  val p = get_ranf_arr_ptr(self)
in
  if p = the_null_ptr then rng_double_cycle(self)
  else let
    val v = $UN.ptr0_get<double>(p)
  in
    if v >= 0.0 then let
      val () = set_ranf_arr_ptr(self, ptr_add<double>(p, 1))
    in
      v
    end else
      rng_double_cycle(self)
  end
end

extern fun rng_double_new(seed: lint): ptr = "ext#rng_double_new"
implement rng_double_new(seed) = let
  val sz = g0int2uint_int_size(RNG_DOUBLE_SIZE)
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val () = set_ranf_arr_ptr(p, the_null_ptr)
  val () = rng_double_set_seed(p, seed)
in
  p
end

extern fun rng_double_free(self: ptr): void = "ext#rng_double_free"
implement rng_double_free(self) =
  if self != the_null_ptr then free(self) else ()

// Gaussian random generator (sum of 4 uniform random doubles)
extern fun rand_gauss(rng: ptr): float = "ext#rand_gauss"
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
