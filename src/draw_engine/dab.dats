// Dab records in a typed arena. A handle is an integer. Copying a dab
// for each tile copies the record, not a malloc'd byte blob.
// main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"

#define DAB_CAP 262144

val g_blank = @{
  x= 0.0f, y= 0.0f, radius= 0.0f,
  color_r= 0, color_g= 0, color_b= 0,
  color_a= 0.0f, opaque= 0.0f, hardness= 0.0f, softness= 0.0f,
  aspect_ratio= 1.0f, angle= 0.0f, normal= 0.0f,
  lock_alpha= 0.0f, colorize= 0.0f, posterize= 0.0f,
  posterize_num= 0.0f, paint= 0.0f
} : OperationDataDrawDab

val g_alive = arrayref_make_elt<bool>(i2sz(DAB_CAP), false)
val g_dab = arrayref_make_elt<OperationDataDrawDab>(i2sz(DAB_CAP), g_blank)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = arrayref_make_elt<int>(i2sz(DAB_CAP), 0)

fn in_cap(i: int): bool = (i >= 0) * (i < DAB_CAP)

fn alloc_dab(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < DAB_CAP) then g_free[i] else DAB_NONE
  end else let
    val n = !g_fresh
  in
    if n < DAB_CAP then (!g_fresh := n + 1; n) else DAB_NONE
  end

fn recycle_dab(h: int): void = let
  val n = !g_nfree
  val i = g1ofg0(n)
  val hi = g1ofg0(h)
  val () = if (i >= 0) * (i < DAB_CAP) then g_free[i] := h
  val () = if (hi >= 0) * (hi < DAB_CAP) then g_alive[hi] := false
  val () = if in_cap(h) then !g_nfree := n + 1
in () end

extern fun dab_get(h: int): OperationDataDrawDab = "ext#dab_get"
implement dab_get(h) = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < DAB_CAP) then
    if g_alive[i] then g_dab[i] else g_blank
  else g_blank
end

extern fun dab_new(v: OperationDataDrawDab): int = "ext#dab_new"
implement dab_new(v) = let
  val h = alloc_dab()
  val () = assertloc(h >= 0)
  val i = g1ofg0(h)
  val () = if (i >= 0) * (i < DAB_CAP) then g_dab[i] := v
  val () = if (i >= 0) * (i < DAB_CAP) then g_alive[i] := true
in
  h
end

extern fun dab_clone(h: int): int = "ext#dab_clone"
implement dab_clone(h) = dab_new(dab_get(h))

extern fun dab_release(h: int): void = "ext#dab_release"
implement dab_release(h) = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < DAB_CAP) then
    if g_alive[i] then recycle_dab(h) else ()
  else ()
end
