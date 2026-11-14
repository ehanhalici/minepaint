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
// Duz demet (Option kutulu kurucusu her cagrida bellek ayirir, GC yok): @(gecerli_mi, grup).
// Gecersiz girdide grup GroupClassic (kullanilmamali).
fun brush_group_try(g: int): @(bool, BrushGroup)
fun brush_group_to_int(g: BrushGroup): int
