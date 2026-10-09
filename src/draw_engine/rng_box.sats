abst@ype MpRng = ptr

fun rng_none(): MpRng = "mac#mp_null_ptr"
fun rng_is_null(r: MpRng): int = "mac#mp_ptr_is_null"
fun rng_of(p: ptr): MpRng = "mac#mp_id_ptr"
fun rng_ptr(r: MpRng): ptr = "mac#mp_id_ptr"
fun rng_add_dbl(r: MpRng, n: int): MpRng = "mac#mp_dbl_add"
fun rng_add_byte(r: MpRng, n: int): MpRng = "mac#mp_byte_add"

abst@ype DblBuf = ptr

fun dbl_of(p: ptr): DblBuf = "mac#mp_id_ptr"
fun dbl_ptr(b: DblBuf): ptr = "mac#mp_id_ptr"
