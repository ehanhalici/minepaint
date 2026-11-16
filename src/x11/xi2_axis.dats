// src/x11/xi2_axis.dats
// XI2 ham olayinda valuator ekseni okuma: algoritma saf ATS (maske sayimi, eksen indeksi, secim);
// C tarafinda yalniz hava kilidiyle sinirli salt okur alan erisimcileri vardir (xi2_raw.cats).
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "sys/airlock.hats"
staload "x11/raw_box.sats"

extern fun c_xi2_raw_mask_len(pf: !RAW_LIVE | data: MpRaw): int = "mac#xi2_raw_mask_len"
extern fun c_xi2_raw_mask_byte(pf: !RAW_LIVE | data: MpRaw, i: int): int = "mac#xi2_raw_mask_byte"
extern fun c_xi2_raw_has_values(pf: !RAW_LIVE | data: MpRaw): int = "mac#xi2_raw_has_values"
extern fun c_xi2_raw_has_raw_values(pf: !RAW_LIVE | data: MpRaw): int = "mac#xi2_raw_has_raw_values"
extern fun c_xi2_raw_value_at(pf: !RAW_LIVE | data: MpRaw, idx: int, nval: int): double = "mac#xi2_raw_value_at"
extern fun c_xi2_raw_rawvalue_at(pf: !RAW_LIVE | data: MpRaw, idx: int, nval: int): double = "mac#xi2_raw_rawvalue_at"

fun pow2 {r:nat} .<r>. (r: int(r)): int = if r > 0 then 2 * pow2(r - 1) else 1

// k. bit (bayt k/8, bit k mod 8); aralik disi bayt 0 okunur.
fn bit_set(pf: !RAW_LIVE | data: MpRaw, k: int): bool =
  if k < 0 then false
  else let
    val byte = c_xi2_raw_mask_byte(pf | data, k / 8)
  in (byte / pow2(airlock_nat(k mod 8))) mod 2 = 1 end

// [0, k) araligindaki kurulu bit sayisi.
fun count_set {r:nat} .<r>. (pf: !RAW_LIVE | data: MpRaw, k: int, rem: int(r)): int =
  if rem > 0 then let
    val here: int = if bit_set(pf | data, k - rem) then 1 else 0
    val rest: int = count_set(pf | data, k, rem - 1)
  in g0int_add_int(here, rest) end
  else 0

fn count_below(pf: !RAW_LIVE | data: MpRaw, k: int): int = count_set(pf | data, k, airlock_nat(k))

fn count_all(pf: !RAW_LIVE | data: MpRaw): int = count_below(pf | data, 8 * c_xi2_raw_mask_len(pf | data))

// Kullanilabilir deger yoksa v, sonra ham deger, yoksa 0.0 (v <= 0 yolu).
fn fallback_value(has_v: bool, has_r: bool, in_range: bool, v: double, r: double): double =
  if has_v * in_range then v else if has_r * in_range then r else 0.0

fn axis_value(pf: !RAW_LIVE | data: MpRaw, idx: int, nval: int): double = let
  val v = c_xi2_raw_value_at(pf | data, idx, nval)
  val r = c_xi2_raw_rawvalue_at(pf | data, idx, nval)
  val in_range = (idx >= 0) * (idx < nval)
in
  if v > 0.0 then v
  else if r > 0.0 then r
  else fallback_value(c_xi2_raw_has_values(pf | data) > 0, c_xi2_raw_has_raw_values(pf | data) > 0, in_range, v, r)
end

extern fun xi2_axis_has(pf: !RAW_LIVE | data: MpRaw, axis: int): bool = "ext#xi2_axis_has"
implement xi2_axis_has(pf | data, axis) = bit_set(pf | data, axis)

extern fun xi2_axis_read(pf: !RAW_LIVE | data: MpRaw, axis: int): double = "ext#xi2_axis_read"
implement xi2_axis_read(pf | data, axis) =
  if bit_set(pf | data, axis) then axis_value(pf | data, count_below(pf | data, axis), count_all(pf | data)) else 0.0
