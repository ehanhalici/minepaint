// src/draw_engine/engine_safe.hats
#ifndef ENGINE_SAFE_HATS
#define ENGINE_SAFE_HATS

extern castfn u16(x: uint): uint16 = "mac#"
extern castfn ptr2farr{n:int}(p: ptr): arrayref(float, n) = "mac#"
extern castfn ptr2iarr{n:int}(p: ptr): arrayref(int, n) = "mac#"
extern castfn ptr2u16arr{n:int}(p: ptr): arrayref(uint16, n) = "mac#"
extern castfn ptr2parr{n:int}(p: ptr): arrayref(ptr, n) = "mac#"
extern castfn ptr2darr{n:int}(p: ptr): arrayref(double, n) = "mac#"

fn mp_arr_fget(p: ptr, i: int): float = let
  val a = ptr2farr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else 0.0f
end

fn mp_arr_fset(p: ptr, i: int, v: float): void = let
  val a = ptr2farr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] := v else ()
end

fn mp_arr_iget(p: ptr, i: int): int = let
  val a = ptr2iarr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else 0
end

fn mp_arr_iset(p: ptr, i: int, v: int): void = let
  val a = ptr2iarr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] := v else ()
end

fn mp_arr_u16get(p: ptr, i: int): uint16 = let
  val a = ptr2u16arr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else u16(0U)
end

fn mp_arr_u16set(p: ptr, i: int, v: uint16): void = let
  val a = ptr2u16arr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] := v else ()
end

fn mp_arr_pget(p: ptr, i: int): ptr = let
  val a = ptr2parr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else the_null_ptr
end

fn mp_arr_pset(p: ptr, i: int, v: ptr): void = let
  val a = ptr2parr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] := v else ()
end

fn mp_arr_dget(p: ptr, i: int): double = let
  val a = ptr2darr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else 0.0
end

fn mp_arr_dset(p: ptr, i: int, v: double): void = let
  val a = ptr2darr{2000000}(p)
  val idx = g1ofg0(i)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] := v else ()
end

extern castfn fn2ptr{a:t@ype}(f: a): ptr = "mac#"
extern castfn ptr2fn{a:t@ype}(p: ptr): a = "mac#"

#endif
