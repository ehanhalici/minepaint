// Integer-handle FIFO. Payloads stay pointers because the queued dabs are
// malloc'd operation records. main.dats dynloads this file.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"

#define FIFO_CAP 4096
#define ITEM_CAP 262144

val g_qalive = arrayref_make_elt<bool>(i2sz(FIFO_CAP), false)
val g_qfirst = arrayref_make_elt<int>(i2sz(FIFO_CAP), FIFO_NONE)
val g_qlast = arrayref_make_elt<int>(i2sz(FIFO_CAP), FIFO_NONE)
val g_qcount = arrayref_make_elt<int>(i2sz(FIFO_CAP), 0)
val g_qfresh = ref<int>(0)
val g_qnfree = ref<int>(0)
val g_qfree = arrayref_make_elt<int>(i2sz(FIFO_CAP), 0)

val g_ialive = arrayref_make_elt<bool>(i2sz(ITEM_CAP), false)
val g_inext = arrayref_make_elt<int>(i2sz(ITEM_CAP), FIFO_NONE)
val g_ipay = arrayref_make_elt<ptr>(i2sz(ITEM_CAP), the_null_ptr)
val g_ifresh = ref<int>(0)
val g_infree = ref<int>(0)
val g_ifree = arrayref_make_elt<int>(i2sz(ITEM_CAP), 0)

fn q_in(h: int): bool = let
  val i = g1ofg0(h)
in
  (i >= 0) * (i < FIFO_CAP)
end

fn qalive_get(h: int): bool = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qalive[i] else false
end

fn qalive_set(h: int, v: bool): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qalive[i] := v else ()
end

fn qfirst_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qfirst[i] else FIFO_NONE
end

fn qfirst_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qfirst[i] := v else ()
end

fn qlast_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qlast[i] else FIFO_NONE
end

fn qlast_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qlast[i] := v else ()
end

fn qcount_get(h: int): int = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qcount[i] else 0
end

fn qcount_set(h: int, v: int): void = let
  val i = g1ofg0(h)
in
  if (i >= 0) * (i < FIFO_CAP) then g_qcount[i] := v else ()
end

fn inext_get(it: int): int = let
  val i = g1ofg0(it)
in
  if (i >= 0) * (i < ITEM_CAP) then g_inext[i] else FIFO_NONE
end

fn inext_set(it: int, v: int): void = let
  val i = g1ofg0(it)
in
  if (i >= 0) * (i < ITEM_CAP) then g_inext[i] := v else ()
end

fn ipay_get(it: int): ptr = let
  val i = g1ofg0(it)
in
  if (i >= 0) * (i < ITEM_CAP) then g_ipay[i] else the_null_ptr
end

fn ipay_set(it: int, v: ptr): void = let
  val i = g1ofg0(it)
in
  if (i >= 0) * (i < ITEM_CAP) then g_ipay[i] := v else ()
end

fn ialive_set(it: int, v: bool): void = let
  val i = g1ofg0(it)
in
  if (i >= 0) * (i < ITEM_CAP) then g_ialive[i] := v else ()
end

fn take_free(nref: ref(int), stack: arrayref(int, FIFO_CAP)): int =
  if !nref > 0 then let
    val n = !nref - 1
    val () = !nref := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < FIFO_CAP) then stack[i] else FIFO_NONE
  end else FIFO_NONE

fn take_ifree(): int =
  if !g_infree > 0 then let
    val n = !g_infree - 1
    val () = !g_infree := n
    val i = g1ofg0(n)
  in
    if (i >= 0) * (i < ITEM_CAP) then g_ifree[i] else FIFO_NONE
  end else FIFO_NONE

fn alloc_q(): int =
  if !g_qnfree > 0 then take_free(g_qnfree, g_qfree)
  else let
    val n = !g_qfresh
  in
    if n < FIFO_CAP then (!g_qfresh := n + 1; n) else FIFO_NONE
  end

fn alloc_item(): int =
  if !g_infree > 0 then take_ifree()
  else let
    val n = !g_ifresh
  in
    if n < ITEM_CAP then (!g_ifresh := n + 1; n) else FIFO_NONE
  end

fn recycle_q(h: int): void = let
  val n = !g_qnfree
  val i = g1ofg0(n)
  val () = if (i >= 0) * (i < FIFO_CAP) then g_qfree[i] := h
  val () = if q_in(h) then !g_qnfree := n + 1
in () end

fn recycle_item(it: int): void = let
  val n = !g_infree
  val i = g1ofg0(n)
  val () = if (i >= 0) * (i < ITEM_CAP) then g_ifree[i] := it
  val () = if (g1ofg0(it) >= 0) * (g1ofg0(it) < ITEM_CAP) then !g_infree := n + 1
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

extern fun fifo_push(h: int, data: ptr): void = "ext#fifo_push"
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

extern fun fifo_pop(h: int): ptr = "ext#fifo_pop"
implement fifo_pop(h) =
  if not(qalive_get(h)) then the_null_ptr
  else let
    val it = qfirst_get(h)
  in
    if it < 0 then the_null_ptr
    else let
      val data = ipay_get(it)
      val nxt = inext_get(it)
      val () = qfirst_set(h, nxt)
      val () = if nxt < 0 then qlast_set(h, FIFO_NONE)
      val () = qcount_set(h, qcount_get(h) - 1)
      val () = ialive_set(it, false)
      val () = ipay_set(it, the_null_ptr)
      val () = recycle_item(it)
    in
      data
    end
  end

extern fun fifo_peek_first(h: int): ptr = "ext#fifo_peek_first"
implement fifo_peek_first(h) =
  if not(qalive_get(h)) then the_null_ptr
  else let
    val it = qfirst_get(h)
  in
    if it < 0 then the_null_ptr else ipay_get(it)
  end

extern fun fifo_peek_last(h: int): ptr = "ext#fifo_peek_last"
implement fifo_peek_last(h) =
  if not(qalive_get(h)) then the_null_ptr
  else let
    val it = qlast_get(h)
  in
    if it < 0 then the_null_ptr else ipay_get(it)
  end

extern fun fifo_free(h: int, user_free: (ptr) -> void): void = "ext#fifo_free"
implement fifo_free(h, user_free) =
  if qalive_get(h) then let
    fun drain(): void =
      if qfirst_get(h) >= 0 then let
        val data = fifo_pop(h)
        val () = if data != the_null_ptr then user_free(data)
      in
        drain()
      end else ()
    val () = drain()
    val () = qalive_set(h, false)
  in
    recycle_q(h)
  end else ()
