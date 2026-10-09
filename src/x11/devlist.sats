abst@ype MpDevList = ptr

fun devlist_none(): MpDevList = "mac#mp_null_ptr"
fun devlist_is_null(d: MpDevList): int = "mac#mp_ptr_is_null"
fun devlist_of(p: ptr): MpDevList = "mac#mp_id_ptr"
fun devlist_ptr(d: MpDevList): ptr = "mac#mp_id_ptr"
