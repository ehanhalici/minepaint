// src/brushes/brush_helpers.hats
#ifndef BRUSH_HELPERS_HATS
#define BRUSH_HELPERS_HATS

extern castfn ptr2iarr{n:int}(p: ptr): arrayref(int, n) = "mac#"
extern castfn ptr2farr{n:int}(p: ptr): arrayref(float, n) = "mac#"
extern castfn ptr2sarr{n:int}(p: ptr): arrayref(string, n) = "mac#"

fn mp_arr_iget(p: ptr, k: int): int = let
  val a = ptr2iarr{2000000}(p)
  val idx = g1ofg0(k)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else 0
end

fn mp_arr_fget(p: ptr, k: int): float = let
  val a = ptr2farr{2000000}(p)
  val idx = g1ofg0(k)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else 0.0f
end

fn mp_arr_sget(p: ptr, k: int): string = let
  val a = ptr2sarr{2000000}(p)
  val idx = g1ofg0(k)
in
  if (idx >= 0) * (idx < 2000000) then a[idx] else ""
end

#endif
