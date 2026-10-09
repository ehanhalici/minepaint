abst@ype MpReq = ptr
abst@ype MpRoi = ptr

fun req_is_null(r: MpReq): int = "mac#mp_ptr_is_null"
fun req_of(p: ptr): MpReq = "mac#mp_id_ptr"
fun req_ptr(r: MpReq): ptr = "mac#mp_id_ptr"

fun roi_is_null(r: MpRoi): int = "mac#mp_ptr_is_null"
fun roi_of(p: ptr): MpRoi = "mac#mp_id_ptr"
fun roi_ptr(r: MpRoi): ptr = "mac#mp_id_ptr"
