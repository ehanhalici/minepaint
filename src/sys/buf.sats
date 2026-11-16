// src/sys/buf.sats
// Sahipli bayt tamponu (dogrusal), tur ve KAPASITE ile indekslenir: Buf(k, n). buf_new{k}(n) tam n bayt sifirlanmis
// heap bellegi verir, buf_free tuketir. Kapasite tipte oldugu icin kapasite alan her islem (fgets, snprintf, text_at)
// n'i tampondan alir: tampon boyutundan buyuk kapasite vermek derleme hatasidir. Metin, X olayi, pencere ozellikleri ve
// boyut ipuclari ayri turlerdir; hicbiri odunc "gorunum" degildir (yikimdan sonra kullanim derleme hatasi).
// Tek `assume` libc.dats icindedir.
stadef KIND_XEV = 1
stadef KIND_SWA = 2
stadef KIND_HINTS = 3

absvtype Buf(k: int, n: int) = ptr
// X yapilari sabit kapasitelidir; cprelude.h _Static_assert ile sizeof(...) <= 256 oldugunu dogrular.
vtypedef XEvBuf = Buf(KIND_XEV, 256)
vtypedef SwaBuf = Buf(KIND_SWA, 256)
vtypedef HintsBuf = Buf(KIND_HINTS, 256)

fun buf_new{k:int}{n:pos}(n: int(n)): Buf(k, n) = "ext#buf_new"
fun buf_free{k:int}{n:int}(b: Buf(k, n)): void = "ext#buf_free"

// --- Metin: tip durumu (typestate) ile NUL sonluluk KANITI ---
// Text(n)    : son bayt (indeks n-1) sifirdir; tuketiciler (sscanf/fopen/mkdir/rename/fputs/strcasestr) yalniz bunu alir.
// TextRaw(n) : icerigi bir C yazicisi degistirdi; sonlandirici garantisi YOK; tuketiciye verilemez (tip hatasi).
// text_new sifirli bellek verir (n >= 1) => Text. Her C yazicisi `&Text(n) >> TextRaw(n)` tipindedir (durumu bozar), geri
// donus yalniz text_seal iledir: indeks n-1'e 0 yazar (`TextRaw >> Text`). Yazicilar ve muhurleme `sys/text_io.dats`
// icinde, Text/TextRaw SOYUTKEN yazilir: muhur unutulursa fonksiyon cikisinda `!Text(n)` geri kazanilamaz (derleme hatasi).
// Guvenilen taban yalniz: (1) text_seal'in tek baytlik depolamasi, (2) C yazicilarin tahsisin disina yazmamasi
// (kapasite = n tipte), (3) heap_new'un sifirli bellek vermesi.
// Tampon `string`e donusturulmez; okuma sinirlidir (i < n statik).
absvtype Text(n: int) = ptr
absvtype TextRaw(n: int) = ptr

fun text_new{n:pos}(n: int(n)): Text(n) = "ext#text_new"
fun text_free{n:int}(b: Text(n)): void = "ext#text_free"
fun text_seal{n:pos}(b: !TextRaw(n) >> Text(n), n: int(n)): void = "ext#text_seal"
fun text_at{n,i:int | 0 <= i; i < n}(b: !Text(n), i: int(i)): int = "mac#mp_text_byte"
// NUL'a kadar uzunluk; sonlandirici (son bayt) garantili oldugundan sonuc < n.
fun text_len{n:pos}(b: !Text(n), n: int(n)): [m:nat | m < n] int(m) = "ext#text_len"
