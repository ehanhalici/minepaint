// src/canvas/layer_box.sats
// Katman ve tile tutamaclari: arena indeksleri, dogrudan dogrulanmis tamsayilardir (-1 = yok). Soyut tip ve
// tamsayi<->tutamac C donusumu yoktur; gecerlilik statik indeks (>= -1) ve CAP kanitlariyla korunur.
typedef MpLayer = [l:int | l >= ~1] int(l)
typedef MpTile = [t:int | t >= ~1] int(t)
