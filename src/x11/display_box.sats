abst@ype MpDisplay = ptr

fun dpy_none(): MpDisplay = "mac#mp_null_ptr"
fun dpy_is_null(d: MpDisplay): int = "mac#mp_ptr_is_null"
fun dpy_of(p: ptr): MpDisplay = "mac#mp_id_ptr"
fun dpy_ptr(d: MpDisplay): ptr = "mac#mp_id_ptr"
