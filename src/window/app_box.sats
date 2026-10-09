abst@ype MpApp = ptr

fun app_none(): MpApp = "mac#mp_null_ptr"
fun app_is_null(a: MpApp): int = "mac#mp_ptr_is_null"
fun app_of(p: ptr): MpApp = "mac#mp_id_ptr"
fun app_ptr(a: MpApp): ptr = "mac#mp_id_ptr"
