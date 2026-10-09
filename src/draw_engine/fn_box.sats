abst@ype MpFn = ptr

fun fn_none(): MpFn = "mac#mp_null_ptr"
fun fn_is_null(f: MpFn): int = "mac#mp_ptr_is_null"
fun fn_of(p: ptr): MpFn = "mac#mp_id_ptr"
fun fn_ptr(f: MpFn): ptr = "mac#mp_id_ptr"
