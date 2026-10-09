abst@ype MpFile = ptr
abst@ype MpText = ptr

fun file_none(): MpFile = "mac#mp_null_ptr"
fun file_is_null(f: MpFile): int = "mac#mp_ptr_is_null"
fun file_of(p: ptr): MpFile = "mac#mp_id_ptr"
fun file_ptr(f: MpFile): ptr = "mac#mp_id_ptr"

fun text_none(): MpText = "mac#mp_null_ptr"
fun text_is_null(t: MpText): int = "mac#mp_ptr_is_null"
fun text_of(p: ptr): MpText = "mac#mp_id_ptr"
fun text_ptr(t: MpText): ptr = "mac#mp_id_ptr"
