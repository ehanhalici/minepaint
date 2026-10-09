abst@ype ByteBuf = ptr

fun byte_none(): ByteBuf = "mac#mp_null_ptr"
fun byte_is_null(b: ByteBuf): int = "mac#mp_ptr_is_null"
fun byte_of(p: ptr): ByteBuf = "mac#mp_id_ptr"
fun byte_ptr(b: ByteBuf): ptr = "mac#mp_id_ptr"
