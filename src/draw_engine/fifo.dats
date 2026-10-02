// src/draw_engine/fifo.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

typedef fifo_item = @{
  next= ptr,
  payload= ptr
}

typedef fifo = @{
  first= ptr,
  last= ptr,
  item_count= int
}

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

extern fun fifo_new(): ptr = "ext#fifo_new"
implement fifo_new() = let
  val sz = sizeof<fifo>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val q = $UN.cast{ref(fifo)}(p)
  val () = q->first := the_null_ptr
  val () = q->last := the_null_ptr
  val () = q->item_count := 0
in
  p
end

extern fun fifo_free(queue_ptr: ptr, user_free: (ptr) -> void): void = "ext#fifo_free"
implement fifo_free(queue_ptr, user_free) =
  if queue_ptr != the_null_ptr then let
    val q = $UN.cast{ref(fifo)}(queue_ptr)
    fun loop(cur: ptr): void =
      if cur != the_null_ptr then let
        val it = $UN.cast{ref(fifo_item)}(cur)
        val nxt = it->next
        val () = if it->payload != the_null_ptr then user_free(it->payload)
        val () = free(cur)
      in
        loop(nxt)
      end else ()
    val () = loop(q->first)
    val () = free(queue_ptr)
  in () end

extern fun fifo_push(queue_ptr: ptr, data: ptr): void = "ext#fifo_push"
implement fifo_push(queue_ptr, data) =
  if queue_ptr != the_null_ptr then let
    val q = $UN.cast{ref(fifo)}(queue_ptr)
    val sz = sizeof<fifo_item>
    val item_p = malloc(sz)
    val () = assertloc(item_p > the_null_ptr)
    val it = $UN.cast{ref(fifo_item)}(item_p)
    val () = it->next := the_null_ptr
    val () = it->payload := data

    val last_p = q->last
    val () =
      if last_p = the_null_ptr then
        q->first := item_p
      else let
        val last_it = $UN.cast{ref(fifo_item)}(last_p)
      in
        last_it->next := item_p
      end

    val () = q->last := item_p
    val () = q->item_count := q->item_count + 1
  in () end

extern fun fifo_pop(queue_ptr: ptr): ptr = "ext#fifo_pop"
implement fifo_pop(queue_ptr) =
  if queue_ptr = the_null_ptr then the_null_ptr
  else let
    val q = $UN.cast{ref(fifo)}(queue_ptr)
    val item_p = q->first
  in
    if item_p = the_null_ptr then the_null_ptr
    else let
      val it = $UN.cast{ref(fifo_item)}(item_p)
      val data = it->payload
      val () = q->first := it->next
      val () = if q->first = the_null_ptr then q->last := the_null_ptr
      val () = q->item_count := q->item_count - 1
      val () = free(item_p)
    in
      data
    end
  end

extern fun fifo_peek_first(queue_ptr: ptr): ptr = "ext#fifo_peek_first"
implement fifo_peek_first(queue_ptr) =
  if queue_ptr = the_null_ptr then the_null_ptr
  else let
    val q = $UN.cast{ref(fifo)}(queue_ptr)
    val item_p = q->first
  in
    if item_p = the_null_ptr then the_null_ptr
    else let
      val it = $UN.cast{ref(fifo_item)}(item_p)
    in
      it->payload
    end
  end

extern fun fifo_peek_last(queue_ptr: ptr): ptr = "ext#fifo_peek_last"
implement fifo_peek_last(queue_ptr) =
  if queue_ptr = the_null_ptr then the_null_ptr
  else let
    val q = $UN.cast{ref(fifo)}(queue_ptr)
    val item_p = q->last
  in
    if item_p = the_null_ptr then the_null_ptr
    else let
      val it = $UN.cast{ref(fifo_item)}(item_p)
    in
      it->payload
    end
  end
