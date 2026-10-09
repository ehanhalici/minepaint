abst@ype MpGlCtx = ptr

fun glctx_none(): MpGlCtx = "mac#mp_null_ptr"
fun glctx_is_null(c: MpGlCtx): int = "mac#mp_ptr_is_null"
fun glctx_of(p: ptr): MpGlCtx = "mac#mp_id_ptr"
fun glctx_ptr(c: MpGlCtx): ptr = "mac#mp_id_ptr"
