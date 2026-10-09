abst@ype MpSurface = ptr

fun mp_surface_none(): MpSurface = "mac#mp_null_ptr"
fun mp_surface_is_null(s: MpSurface): int = "mac#mp_ptr_is_null"
fun mp_surface_of_ptr(p: ptr): MpSurface = "mac#mp_id_ptr"
fun mp_surface_to_ptr(s: MpSurface): ptr = "mac#mp_id_ptr"
