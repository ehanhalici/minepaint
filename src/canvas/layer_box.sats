abst@ype MpLayer = ptr
abst@ype MpTile = ptr

fun layer_none(): MpLayer = "mac#mp_null_ptr"
fun layer_is_null(l: MpLayer): int = "mac#mp_ptr_is_null"
fun layer_of(p: ptr): MpLayer = "mac#mp_id_ptr"
fun layer_ptr(l: MpLayer): ptr = "mac#mp_id_ptr"

fun tile_none(): MpTile = "mac#mp_null_ptr"
fun tile_is_null(t: MpTile): int = "mac#mp_ptr_is_null"
fun tile_of(p: ptr): MpTile = "mac#mp_id_ptr"
fun tile_ptr(t: MpTile): ptr = "mac#mp_id_ptr"
