// Dab records in a typed arena. A handle is an integer. Copying a dab
// for each tile copies the record, not a malloc'd byte blob.
// main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./engine_safe.hats"

#define DAB_CAP 262144

val g_blank = @{
  x= 0.0f, y= 0.0f, radius= 0.0f,
  color_r= 0, color_g= 0, color_b= 0,
  color_a= 0.0f, opaque= 0.0f, hardness= 0.0f, softness= 0.0f,
  aspect_ratio= 1.0f, angle= 0.0f, normal= 0.0f,
  lock_alpha= 0.0f, colorize= 0.0f, posterize= 0.0f,
  posterize_num= 0.0f, paint= 0.0f
} : OperationDataDrawDab

val g_alive = air_arena(DAB_CAP, airlock_esz_int())
val g_dab = arrayref_make_elt<OperationDataDrawDab>(i2sz(DAB_CAP), g_blank)
val g_fresh = ref<int>(0)
val g_nfree = ref<int>(0)
val g_free = air_arena(DAB_CAP, airlock_esz_int())

fn in_cap(i: int): bool = airlock_span(i, 1, DAB_CAP) != 0

fn alloc_dab(): int =
  if !g_nfree > 0 then let
    val n = !g_nfree - 1
    val () = !g_nfree := n
  in
    if in_cap(n) then airlock_iget_n(g_free, n, DAB_CAP) else DAB_NONE
  end else let
    val n = !g_fresh
  in
    if n < DAB_CAP then (!g_fresh := n + 1; n) else DAB_NONE
  end

fn recycle_dab(h: int): void = let
  val n = !g_nfree
  val () = if in_cap(n) then airlock_iset_n(g_free, n, DAB_CAP, h)
  val () = air_bset(g_alive, h, DAB_CAP, false)
  val () = if in_cap(h) then !g_nfree := n + 1
in () end

extern fun dab_get(h: int): OperationDataDrawDab = "ext#dab_get"
implement dab_get(h) =
  if airlock_span(h, 1, DAB_CAP) != 0 then
    if air_bget(g_alive, h, DAB_CAP) then g_dab[airlock_below(h, DAB_CAP)] else g_blank
  else g_blank

extern fun dab_new(v: OperationDataDrawDab): int = "ext#dab_new"
implement dab_new(v) = let
  val h = alloc_dab()
  val () = assertloc(h >= 0)
  val () = if airlock_span(h, 1, DAB_CAP) != 0 then g_dab[airlock_below(h, DAB_CAP)] := v
  val () = air_bset(g_alive, h, DAB_CAP, true)
in
  h
end

extern fun dab_clone(h: int): int = "ext#dab_clone"
implement dab_clone(h) = dab_new(dab_get(h))

extern fun dab_release(h: int): void = "ext#dab_release"
implement dab_release(h) =
  if airlock_span(h, 1, DAB_CAP) != 0 then
    if air_bget(g_alive, h, DAB_CAP) then recycle_dab(h) else ()
  else ()
