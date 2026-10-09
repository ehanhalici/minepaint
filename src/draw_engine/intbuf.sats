abst@ype IntBuf = ptr

fun intbuf_none(): IntBuf = "mac#mp_null_ptr"
fun intbuf_is_null(b: IntBuf): int = "mac#mp_ptr_is_null"
fun intbuf_of(p: ptr): IntBuf = "mac#mp_id_ptr"
fun intbuf_ptr(b: IntBuf): ptr = "mac#mp_id_ptr"
