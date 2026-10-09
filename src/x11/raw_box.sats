abst@ype MpRaw = ptr

fun raw_none(): MpRaw = "mac#mp_null_ptr"
fun raw_is_null(r: MpRaw): int = "mac#mp_ptr_is_null"
fun raw_of(p: ptr): MpRaw = "mac#mp_id_ptr"
fun raw_ptr(r: MpRaw): ptr = "mac#mp_id_ptr"
