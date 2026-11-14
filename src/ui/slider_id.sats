// src/ui/slider_id.sats
// Fırça kaydırıcılarının kapalı kümesi. Sıra, kenar çubuğundaki sırayla (0..7) aynıdır.

datatype SliderId =
  | SliderSize
  | SliderOpaque
  | SliderSharp
  | SliderGrain
  | SliderPigment
  | SliderSmooth
  | SliderPressure
  | SliderTwist

// Sınır dönüşümleri: yalnızca düzen indeksini (0..7) çevirir.
// Duz demet (Option kutulu kurucusu her cagrida bellek ayirir, GC yok): @(gecerli_mi, kimlik).
// Gecersiz girdide kimlik SliderSize (kullanilmamali).
fun slider_id_try(i: int): @(bool, SliderId)
fun slider_id_to_int(s: SliderId): int
