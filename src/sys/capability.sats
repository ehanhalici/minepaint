// src/sys/capability.sats
// Tum "yasiyor" yetenek kanitlari tek soyut view'dan turetilir: CAP(tur, kimlik).
// Ispatsiz aksiyomlar (praxi) YALNIZCA burada bildirilir; modullerde extern prfun yoktur.
// Kanit uretimi sadece her modulun *_new ve *_claim fonksiyonlarinda cagrilir
// (claim, calisma zamaninda yasiyor + alinmamis kontrolunden sonra).

absview CAP(kind: int, id: int)

stadef KIND_LAYER = 3
stadef KIND_MAPPING = 7
stadef KIND_CANVAS = 8
stadef KIND_BRUSH = 9
stadef KIND_GL = 10

// Aksiyomlar: tur ve kimlik statik indeks olarak tasindigi icin farkli turdeki kanitlar
// birbirinin yerine kullanilamaz (FIFO kaniti katman islemine verilemez).
praxi cap_mint {k,i:int} (): CAP(k, i)
praxi cap_burn {k,i:int} (pf: CAP(k, i)): void
