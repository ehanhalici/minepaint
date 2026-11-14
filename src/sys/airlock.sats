// src/sys/airlock.sats
// Sinir hava kilidi sozlesmesi: C tarafi araligi denetler, disari tasan okuma 0 doner,
// disari tasan yazma yapilmaz. Olumcul durumlar anth_die_* ile belirleyici sekilde biter.

// Yakit tavani: 2^28. Metriksiz veri-bagimli ozyineleme bunu azaltir.
#define MAX_REC_FUEL 268435456
// Veri-gudumlü ozyinelemelerin fiziksel ust sinirlari. Bu dongulerin olcusu tipten cikmaz
// (C bellegindeki zincir, RLE tamponu, float durumu...); yakit = veri yapisinin kapasitesi,
// yani asilmasi gercek bir tasarim ihlalidir (anth_die_* ile durur). Gerekce her kullanimda yazilidir.
#define FUEL_DABS_PER_MOTION 65536
// Dizin tarama tavani.
#define MAX_DIR_ENTRIES 65536

// Yakit tukenmesi olaylari yer başına ayridir: stderr cikisinda "site" alani hangi dongunun tavani asildigini soyler.
datatype DieEvent =
  | DieAllocFailed
  | DieContractViolation
  | DieFuelDab


fun die_event_code (e: DieEvent): int
fun anth_die_void (e: DieEvent): void
fun anth_die_int (e: DieEvent): int
fun anth_die_dbl (e: DieEvent): double
fun anth_die_box {a:type} (e: DieEvent): a
fun anth_require (ok: bool): void

fun airlock_below {n:pos} (i: int, cap: int(n)): [k:nat | k < n] int(k) = "mac#airlock_ix"
fun airlock_word(p: ptr, i: int, n: int): int = "mac#airlock_word"
fun airlock_span(i: int, len: int, n: int): int = "mac#airlock_span"
fun airlock_cstr_len(s: string): [k:nat] int(k) = "mac#airlock_cstr_len"
fun airlock_cstr_at(s: string, i: int, n: int): int = "mac#airlock_cstr_at"
fun airlock_nat(i: int): [n:nat] int(n) = "mac#airlock_nat"
// Dinamik int degerini indeks terimine yukseltir (kisit yok; yalniz olcu/sinir terimi olarak kullanilir).
fun airlock_int(i: int): [n:int] int(n) = "mac#airlock_int"
