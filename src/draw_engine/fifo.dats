// Integer-handle FIFO. Each payload is an integer dab handle.
// main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "./engine_safe.hats"

#define FIFO_CAP 4096
#define ITEM_CAP 262144

val g_qalive = air_arena(FIFO_CAP, airlock_esz_int())
val g_qfirst = air_arena(FIFO_CAP, airlock_esz_int())
val () = airlock_fill_int(g_qfirst, FIFO_CAP, FIFO_NONE)
val g_qlast = air_arena(FIFO_CAP, airlock_esz_int())
val () = airlock_fill_int(g_qlast, FIFO_CAP, FIFO_NONE)
val g_qcount = air_arena(FIFO_CAP, airlock_esz_int())
val g_qfresh = ref<int>(0)
val g_qnfree = ref<int>(0)
val g_qfree = air_arena(FIFO_CAP, airlock_esz_int())

val g_ialive = air_arena(ITEM_CAP, airlock_esz_int())
val g_inext = air_arena(ITEM_CAP, airlock_esz_int())
val () = airlock_fill_int(g_inext, ITEM_CAP, FIFO_NONE)
val g_ipay = air_arena(ITEM_CAP, airlock_esz_int())
val () = airlock_fill_int(g_ipay, ITEM_CAP, FIFO_NONE)
val g_ifresh = ref<int>(0)
val g_infree = ref<int>(0)
val g_ifree = air_arena(ITEM_CAP, airlock_esz_int())

fn q_in(h: int): bool = airlock_below(h, FIFO_CAP) != 0
fn item_in(it: int): bool = airlock_below(it, ITEM_CAP) != 0

fn qalive_get(h: int): bool = air_bget(g_qalive, h, FIFO_CAP)
fn qalive_set(h: int, v: bool): void = air_bset(g_qalive, h, FIFO_CAP, v)
fn qfirst_get(h: int): int =
  if q_in(h) then airlock_iget_n(g_qfirst, h, FIFO_CAP) else FIFO_NONE
fn qfirst_set(h: int, v: int): void = airlock_iset_n(g_qfirst, h, FIFO_CAP, v)
fn qlast_get(h: int): int =
  if q_in(h) then airlock_iget_n(g_qlast, h, FIFO_CAP) else FIFO_NONE
fn qlast_set(h: int, v: int): void = airlock_iset_n(g_qlast, h, FIFO_CAP, v)
fn qcount_get(h: int): int = airlock_iget_n(g_qcount, h, FIFO_CAP)
fn qcount_set(h: int, v: int): void = airlock_iset_n(g_qcount, h, FIFO_CAP, v)
fn inext_get(it: int): int =
  if item_in(it) then airlock_iget_n(g_inext, it, ITEM_CAP) else FIFO_NONE
fn inext_set(it: int, v: int): void = airlock_iset_n(g_inext, it, ITEM_CAP, v)
fn ipay_get(it: int): int =
  if item_in(it) then airlock_iget_n(g_ipay, it, ITEM_CAP) else FIFO_NONE
fn ipay_set(it: int, v: int): void = airlock_iset_n(g_ipay, it, ITEM_CAP, v)
fn ialive_set(it: int, v: bool): void = air_bset(g_ialive, it, ITEM_CAP, v)

fn take_free(nref: ref(int), stack: ptr, cap: int): int =
  if !nref > 0 then let
    val n = !nref - 1
    val () = !nref := n
  in
    if airlock_below(n, cap) != 0 then airlock_iget_n(stack, n, cap) else FIFO_NONE
  end else FIFO_NONE

fn alloc_q(): int =
  if !g_qnfree > 0 then take_free(g_qnfree, g_qfree, FIFO_CAP)
  else let
    val n = !g_qfresh
  in
    if n < FIFO_CAP then (!g_qfresh := n + 1; n) else FIFO_NONE
  end

fn alloc_item(): int =
  if !g_infree > 0 then take_free(g_infree, g_ifree, ITEM_CAP)
  else let
    val n = !g_ifresh
  in
    if n < ITEM_CAP then (!g_ifresh := n + 1; n) else FIFO_NONE
  end

fn recycle_q(h: int): void = let
  val n = !g_qnfree
  val () = if q_in(n) then airlock_iset_n(g_qfree, n, FIFO_CAP, h)
  val () = if q_in(h) then !g_qnfree := n + 1
in () end

fn recycle_item(it: int): void = let
  val n = !g_infree
  val () = if item_in(n) then airlock_iset_n(g_ifree, n, ITEM_CAP, it)
  val () = if item_in(it) then !g_infree := n + 1
in () end

fn q_reset(h: int): void = let
  val () = qfirst_set(h, FIFO_NONE)
  val () = qlast_set(h, FIFO_NONE)
  val () = qcount_set(h, 0)
in
  qalive_set(h, true)
end

extern fun fifo_new(): int = "ext#fifo_new"
implement fifo_new() = let
  val h = alloc_q()
  val () = assertloc(h >= 0)
  val () = q_reset(h)
in
  h
end

extern fun fifo_push(h: int, data: int): void = "ext#fifo_push"
implement fifo_push(h, data) =
  if qalive_get(h) then let
    val it = alloc_item()
    val () = assertloc(it >= 0)
    val () = inext_set(it, FIFO_NONE)
    val () = ipay_set(it, data)
    val () = ialive_set(it, true)
    val last = qlast_get(h)
    val () = if last < 0 then qfirst_set(h, it) else inext_set(last, it)
    val () = qlast_set(h, it)
  in
    qcount_set(h, qcount_get(h) + 1)
  end else ()

extern fun fifo_pop(h: int): int = "ext#fifo_pop"
implement fifo_pop(h) =
  if not(qalive_get(h)) then FIFO_NONE
  else let
    val it = qfirst_get(h)
  in
    if it < 0 then FIFO_NONE
    else let
      val data = ipay_get(it)
      val nxt = inext_get(it)
      val () = qfirst_set(h, nxt)
      val () = if nxt < 0 then qlast_set(h, FIFO_NONE)
      val () = qcount_set(h, qcount_get(h) - 1)
      val () = ialive_set(it, false)
      val () = ipay_set(it, FIFO_NONE)
      val () = recycle_item(it)
    in
      data
    end
  end

extern fun fifo_peek_first(h: int): int = "ext#fifo_peek_first"
implement fifo_peek_first(h) =
  if not(qalive_get(h)) then FIFO_NONE
  else let
    val it = qfirst_get(h)
  in
    if it < 0 then FIFO_NONE else ipay_get(it)
  end

extern fun fifo_peek_last(h: int): int = "ext#fifo_peek_last"
implement fifo_peek_last(h) =
  if not(qalive_get(h)) then FIFO_NONE
  else let
    val it = qlast_get(h)
  in
    if it < 0 then FIFO_NONE else ipay_get(it)
  end

extern fun fifo_free(h: int, user_free: (int) -> void): void = "ext#fifo_free"
implement fifo_free(h, user_free) =
  if qalive_get(h) then let
    fun drain(): void =
      if qfirst_get(h) >= 0 then let
        val data = fifo_pop(h)
        val () = if data >= 0 then user_free(data)
      in
        drain()
      end else ()
    val () = drain()
    val () = qalive_set(h, false)
  in
    recycle_q(h)
  end else ()
