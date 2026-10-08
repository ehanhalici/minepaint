// src/brushes/brush_group.sats
// Fırça grubunun tek kaynaklı cebirsel tanımı.
// Sıra, eski tamsayı kimlikleriyle birebir aynıdır (0..7).

datatype BrushGroup =
  | GroupDieterle
  | GroupClassic
  | GroupDeevad
  | GroupFavorites
  | GroupRamon
  | GroupExperimental
  | GroupTanda
  | GroupKaerhon

// Sınır dönüşümleri: yalnızca dış dünya tamsayılarını (session dosyası, sekme indeksi) çevirir.
fun brush_group_of_int(g: int): Option(BrushGroup)
fun brush_group_to_int(g: BrushGroup): int
