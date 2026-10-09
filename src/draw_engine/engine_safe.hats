// src/draw_engine/engine_safe.hats
// Buffer loads go through the C airlock. Out of range reads return 0.
// Out of range writes do nothing. The check does not abort.
#ifndef ENGINE_SAFE_HATS
#define ENGINE_SAFE_HATS

extern fun u16(x: uint): uint16 = "mac#mp_uint_to_u16"

// Yakıt tavanı: 2^28. Metriği olmayan veri-bağımlı özyineleme bunu azaltır.
#define MP_REC_FUEL 268435456

extern fun airlock_below {n:pos} (i: int, cap: int(n)): [k:nat | k < n] int(k) = "mac#airlock_ix"
extern fun airlock_word(p: ptr, i: int, n: int): int = "mac#airlock_word"
extern fun airlock_span(i: int, len: int, n: int): int = "mac#airlock_span"
extern fun airlock_cstr_len(s: string): [k:nat] int(k) = "mac#airlock_cstr_len"
extern fun airlock_cstr_at(s: string, i: int, n: int): int = "mac#airlock_cstr_at"
extern fun airlock_u16get_n(p: ptr, i: int, n: int): uint16 = "mac#airlock_u16get_n"
extern fun airlock_u16set_n(p: ptr, i: int, n: int, v: uint16): void = "mac#airlock_u16set_n"

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
