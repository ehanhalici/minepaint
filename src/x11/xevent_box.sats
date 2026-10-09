abst@ype MpXEvent = ptr

fun xev_none(): MpXEvent = "mac#mp_null_ptr"
fun xev_is_null(e: MpXEvent): int = "mac#mp_ptr_is_null"
fun xev_of(p: ptr): MpXEvent = "mac#mp_id_ptr"
fun xev_ptr(e: MpXEvent): ptr = "mac#mp_id_ptr"
