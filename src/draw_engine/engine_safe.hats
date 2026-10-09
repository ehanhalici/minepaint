// src/draw_engine/engine_safe.hats
// Buffer loads go through the C airlock. Out of range reads return 0.
// Out of range writes do nothing. The check does not abort.
#ifndef ENGINE_SAFE_HATS
#define ENGINE_SAFE_HATS

extern fun u16(x: uint): uint16 = "mac#mp_uint_to_u16"

extern fun airlock_nat(i: int): int = "mac#airlock_nat"
extern fun airlock_pos(i: int): int = "mac#airlock_pos"
extern fun airlock_below(i: int, n: int): int = "mac#airlock_below"
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

#endif
