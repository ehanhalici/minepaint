// src/canvas/layer_view.sats
// Katman tutamaci icin dogrusal yetenek: LAYER_LIVE(l) olmadan tile islemi yapilamaz.
// Kanit layer_new ile uretilir, layer_destroy ile tuketilir; canvas durum kaydi tutamaci
// layer_stash ile birakir, kullanan modul layer_claim ile odunc alip layer_stash ile geri verir.

staload "gl/gl_io.sats"
staload "canvas/layer_box.sats"

staload "sys/capability.sats"

stadef LAYER_LIVE (l: int) = CAP(KIND_LAYER, l)

fun layer_new (): [l:nat] (LAYER_LIVE(l) | int(l)) = "ext#layer_new"

fun layer_find_tile {l:int} (pf: !LAYER_LIVE(l) | l: int(l), tx: int, ty: int): MpTile = "ext#layer_find_tile"
fun layer_get_or_create_tile {l:int} (pf: !LAYER_LIVE(l), gio: !GL_IO | l: int(l), tx: int, ty: int): MpTile = "ext#layer_get_or_create_tile"
fun layer_draw_tiles {l:int} (
  pf: !LAYER_LIVE(l), gio: !GL_IO | l: int(l), view_l: float, view_t: float, view_r: float, view_b: float, zoom: float
): void = "ext#layer_draw_tiles"
fun layer_clear {l:int} (pf: !LAYER_LIVE(l), gio: !GL_IO | l: int(l)): void = "ext#layer_clear"
fun layer_destroy {l:int} (pf: LAYER_LIVE(l), gio: !GL_IO | l: int(l)): void = "ext#layer_destroy"

fun layer_stash {l:int} (pf: LAYER_LIVE(l) | l: int(l)): MpLayer = "ext#layer_stash"
fun layer_claim (layer: MpLayer): [ok:bool][l:nat] (option_v(LAYER_LIVE(l), ok) | bool(ok), int(l)) = "ext#layer_claim"

// Tile tabanli islemler katmana ihtiyac duymaz.
fun layer_bind_tile (gio: !GL_IO | tile: MpTile): void = "ext#layer_bind_tile"
fun layer_unbind_tile (gio: !GL_IO | ): void = "ext#layer_unbind_tile"
