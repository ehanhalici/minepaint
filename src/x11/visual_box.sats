abst@ype MpVisual = ptr

fun visual_none(): MpVisual = "mac#mp_null_ptr"
fun visual_is_null(v: MpVisual): int = "mac#mp_ptr_is_null"
fun visual_of(p: ptr): MpVisual = "mac#mp_id_ptr"
fun visual_ptr(v: MpVisual): ptr = "mac#mp_id_ptr"
