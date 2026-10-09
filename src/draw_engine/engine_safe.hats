// src/draw_engine/engine_safe.hats
// Buffer loads go through the C airlock. Out of range reads return 0.
// Out of range writes do nothing. The check does not abort.
#ifndef ENGINE_SAFE_HATS
#define ENGINE_SAFE_HATS

extern fun u16(x: uint): uint16 = "mac#mp_uint_to_u16"

extern fun airlock_nat(i: int): [k:nat] int(k) = "mac#airlock_nat"
extern fun airlock_pos(i: int): [k:pos] int(k) = "mac#airlock_pos"
extern fun airlock_below {n:pos} (i: int, cap: int(n)): [k:nat | k < n] int(k) = "mac#airlock_ix"
extern fun airlock_word(p: ptr, i: int, n: int): int = "mac#airlock_word"
extern fun airlock_span(i: int, len: int, n: int): int = "mac#airlock_span"

extern fun mp_arr_fget(p: ptr, i: int): float = "mac#airlock_fget"
extern fun mp_arr_fset(p: ptr, i: int, v: float): void = "mac#airlock_fset"
extern fun mp_arr_iget(p: ptr, i: int): int = "mac#airlock_iget"
extern fun mp_arr_iset(p: ptr, i: int, v: int): void = "mac#airlock_iset"
extern fun mp_arr_u16get(p: ptr, i: int): uint16 = "mac#airlock_u16get"
extern fun mp_arr_u16set(p: ptr, i: int, v: uint16): void = "mac#airlock_u16set"
extern fun mp_arr_pget(p: ptr, i: int): ptr = "mac#airlock_pget"
extern fun mp_arr_pset(p: ptr, i: int, v: ptr): void = "mac#airlock_pset"
extern fun mp_arr_dget(p: ptr, i: int): double = "mac#airlock_dget"
extern fun mp_arr_dset(p: ptr, i: int, v: double): void = "mac#airlock_dset"

extern fun airlock_dget_n(p: ptr, i: int, n: int): double = "mac#airlock_dget_n"
extern fun airlock_dset_n(p: ptr, i: int, n: int, v: double): void = "mac#airlock_dset_n"
extern fun airlock_iget_n(p: ptr, i: int, n: int): int = "mac#airlock_iget_n"
extern fun airlock_iset_n(p: ptr, i: int, n: int, v: int): void = "mac#airlock_iset_n"
extern fun airlock_fget_n(p: ptr, i: int, n: int): float = "mac#airlock_fget_n"
extern fun airlock_fset_n(p: ptr, i: int, n: int, v: float): void = "mac#airlock_fset_n"
extern fun airlock_pget_n(p: ptr, i: int, n: int): ptr = "mac#airlock_pget_n"
extern fun airlock_pset_n(p: ptr, i: int, n: int, v: ptr): void = "mac#airlock_pset_n"
extern fun airlock_esz_int(): int = "mac#airlock_esz_int"
extern fun airlock_esz_float(): int = "mac#airlock_esz_float"
extern fun airlock_esz_double(): int = "mac#airlock_esz_double"
extern fun airlock_esz_ptr(): int = "mac#airlock_esz_ptr"
extern fun airlock_alloc(n: int, esz: int): ptr = "mac#airlock_alloc"
extern fun airlock_fill_int(p: ptr, n: int, v: int): void = "mac#airlock_fill_int"

fn air_bset(p: ptr, i: int, n: int, v: bool): void =
  airlock_iset_n(p, i, n, (if v then 1 else 0))

fn air_bget(p: ptr, i: int, n: int): bool =
  airlock_iget_n(p, i, n) != 0

fn air_arena(n: int, esz: int): ptr = let
  val p = airlock_alloc(n, esz)
  val () = assertloc(p > the_null_ptr)
in
  p
end

#endif
