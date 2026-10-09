abst@ype MpRect = ptr

fun rect_none(): MpRect = "mac#mp_null_ptr"
fun rect_is_null(r: MpRect): int = "mac#mp_ptr_is_null"
fun rect_of(p: ptr): MpRect = "mac#mp_id_ptr"
fun rect_ptr(r: MpRect): ptr = "mac#mp_id_ptr"

abst@ype RectRun = ptr

fun rectrun_of(p: ptr): RectRun = "mac#mp_id_ptr"
fun rectrun_ptr(r: RectRun): ptr = "mac#mp_id_ptr"
fun rectrun_add(r: RectRun, n: int): RectRun = "mac#mp_byte_add"
