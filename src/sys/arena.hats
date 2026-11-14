// src/sys/arena.hats
// Tipli arena yardimcilari (E.3): dis dunyadan gelen ham int'ler `ix_parse` ile BIR kez
// `Ix(n)` = [k:nat | k < n] int(k) tipine ayristirilir; ic erisimler `arrayref(a, n)` uzerinde
// derleme zamaninda kanitli indeksle yapilir (calisma zamani sinir kontrolu ve sessiz varsayilan yok).
#ifndef MINEPAINT_ARENA_HATS
#define MINEPAINT_ARENA_HATS

typedef Ix(n:int) = [k:nat | k < n] int(k)

// Ayristirma sonucu DUZ bir demettir: @(gecerli_mi, tipli_indeks). Option(...) bilincli olarak
// kullanilmaz: kutulu kurucu (Some) her cagrida bellek ayirir ve GC yoktur. Gecersiz girdide indeks
// 0'a kirpilir (her zaman aralik icinde), cagiran `gecerli_mi`yi denetlemelidir.
fn ix_try {n:pos} (i: int, n: int(n)): @(bool, Ix(n)) =
  @((i >= 0) * (i < n), airlock_below(i, n))

#endif
