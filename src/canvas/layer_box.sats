// src/canvas/layer_box.sats
// Katman ve tile tutamaclari: arena indeksleri. -1 = yok. Tamsayi <-> tutamac donusumu yalniz burada.

abst@ype MpLayer = int
abst@ype MpTile = int

fun layer_none(): MpLayer = "mac#mp_none_handle"
fun layer_is_null(l: MpLayer): int = "mac#mp_handle_is_none"
fun layer_of_int(i: int): MpLayer = "mac#mp_id_int"
fun layer_to_int(l: MpLayer): int = "mac#mp_id_int"

fun tile_none(): MpTile = "mac#mp_none_handle"
fun tile_is_null(t: MpTile): int = "mac#mp_handle_is_none"
fun tile_of_int(i: int): MpTile = "mac#mp_id_int"
fun tile_to_int(t: MpTile): int = "mac#mp_id_int"
