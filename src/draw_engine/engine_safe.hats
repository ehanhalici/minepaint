// src/draw_engine/engine_safe.hats
// Pixel and table loads go through C functions in cprelude.h.
// The index check stays here; there is no cast.
#ifndef ENGINE_SAFE_HATS
#define ENGINE_SAFE_HATS

extern fun u16(x: uint): uint16 = "mac#mp_uint_to_u16"
extern fun mp_c_fget(p: ptr, i: int): float = "mac#mp_fget"
extern fun mp_c_fset(p: ptr, i: int, v: float): void = "mac#mp_fset"
extern fun mp_c_iget(p: ptr, i: int): int = "mac#mp_iget"
extern fun mp_c_iset(p: ptr, i: int, v: int): void = "mac#mp_iset"
extern fun mp_c_u16get(p: ptr, i: int): uint16 = "mac#mp_u16get"
extern fun mp_c_u16set(p: ptr, i: int, v: uint16): void = "mac#mp_u16set"
extern fun mp_c_pget(p: ptr, i: int): ptr = "mac#mp_pget"
extern fun mp_c_pset(p: ptr, i: int, v: ptr): void = "mac#mp_pset"
extern fun mp_c_dget(p: ptr, i: int): double = "mac#mp_dget"
extern fun mp_c_dset(p: ptr, i: int, v: double): void = "mac#mp_dset"

fn mp_arr_in(i: int): bool = (i >= 0) * (i < 2000000)

fn mp_arr_fget(p: ptr, i: int): float =
  if mp_arr_in(i) then mp_c_fget(p, i) else 0.0f

fn mp_arr_fset(p: ptr, i: int, v: float): void =
  if mp_arr_in(i) then mp_c_fset(p, i, v) else ()

fn mp_arr_iget(p: ptr, i: int): int =
  if mp_arr_in(i) then mp_c_iget(p, i) else 0

fn mp_arr_iset(p: ptr, i: int, v: int): void =
  if mp_arr_in(i) then mp_c_iset(p, i, v) else ()

fn mp_arr_u16get(p: ptr, i: int): uint16 =
  if mp_arr_in(i) then mp_c_u16get(p, i) else u16(0U)

fn mp_arr_u16set(p: ptr, i: int, v: uint16): void =
  if mp_arr_in(i) then mp_c_u16set(p, i, v) else ()

fn mp_arr_pget(p: ptr, i: int): ptr =
  if mp_arr_in(i) then mp_c_pget(p, i) else the_null_ptr

fn mp_arr_pset(p: ptr, i: int, v: ptr): void =
  if mp_arr_in(i) then mp_c_pset(p, i, v) else ()

fn mp_arr_dget(p: ptr, i: int): double =
  if mp_arr_in(i) then mp_c_dget(p, i) else 0.0

fn mp_arr_dset(p: ptr, i: int, v: double): void =
  if mp_arr_in(i) then mp_c_dset(p, i, v) else ()

#endif
