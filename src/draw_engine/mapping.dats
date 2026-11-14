// src/draw_engine/mapping.dats
// Piecewise-linear dynamics curves in a typed structure-of-arrays arena.
// A mapping is an integer handle. main.dats initialises this file so the
// arena exists before the first call. No raw pointers and no casts.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./minepaint_types.hats"
#include "sys/airlock.hats"
#include "sys/arena.hats"
staload "sys/capability.sats"
staload "draw_engine/mapping_view.sats"

#define CURVE_CAPACITY (MAPPING_CAPACITY * MAPPING_INPUTS)
#define POINT_CAPACITY (CURVE_CAPACITY * MAPPING_CURVE_POINTS)

// E.3: arenalar `arrayref`; tutamac / girdi / nokta indeksleri tipli, erisim kanitli.
typedef MIx = Ix(MAPPING_CAPACITY)
typedef JIx = Ix(MAPPING_INPUTS)

val g_alive = arrayref_make_elt<int>(i2sz(MAPPING_CAPACITY), 0)
val g_claim = arrayref_make_elt<int>(i2sz(MAPPING_CAPACITY), 0)
val g_base = arrayref_make_elt<float>(i2sz(MAPPING_CAPACITY), 0.0f)
val g_inputs = arrayref_make_elt<int>(i2sz(MAPPING_CAPACITY), 0)
val g_used = arrayref_make_elt<int>(i2sz(MAPPING_CAPACITY), 0)
val g_n = arrayref_make_elt<int>(i2sz(CURVE_CAPACITY), 0)
val g_x = arrayref_make_elt<float>(i2sz(POINT_CAPACITY), 0.0f)
val g_y = arrayref_make_elt<float>(i2sz(POINT_CAPACITY), 0.0f)

fn curve_slot {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS} (h: int(h), j: int(j)): [s:nat | s < CURVE_CAPACITY] int(s) =
  h * MAPPING_INPUTS + j

fn point_slot {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS}{k:nat | k < MAPPING_CURVE_POINTS} (
  h: int(h), j: int(j), k: int(k)
): [s:nat | s < POINT_CAPACITY] int(s) =
  (h * MAPPING_INPUTS + j) * MAPPING_CURVE_POINTS + k

fn alive_get(h: MIx): bool = g_alive[h] != 0
fn claim_get(h: MIx): bool = g_claim[h] != 0
fn claim_mark(h: MIx): void = g_claim[h] := 1
fn claim_clear(h: MIx): void = g_claim[h] := 0
fn alive_mark(h: MIx): void = g_alive[h] := 1
fn alive_clear(h: MIx): void = g_alive[h] := 0
fn base_get(h: MIx): float = g_base[h]
fn base_set(h: MIx, v: float): void = g_base[h] := v
fn inputs_get(h: MIx): int = g_inputs[h]
fn inputs_set(h: MIx, v: int): void = g_inputs[h] := v
fn used_get(h: MIx): int = g_used[h]
fn used_set(h: MIx, v: int): void = g_used[h] := v
fn n_get {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS} (h: int(h), j: int(j)): int = g_n[curve_slot(h, j)]
fn n_set {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS} (h: int(h), j: int(j), v: int): void = g_n[curve_slot(h, j)] := v
fn x_get {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS}{k:nat | k < MAPPING_CURVE_POINTS} (h: int(h), j: int(j), k: int(k)): float = g_x[point_slot(h, j, k)]
fn x_set {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS}{k:nat | k < MAPPING_CURVE_POINTS} (h: int(h), j: int(j), k: int(k), v: float): void = g_x[point_slot(h, j, k)] := v
fn y_get {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS}{k:nat | k < MAPPING_CURVE_POINTS} (h: int(h), j: int(j), k: int(k)): float = g_y[point_slot(h, j, k)]
fn y_set {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS}{k:nat | k < MAPPING_CURVE_POINTS} (h: int(h), j: int(j), k: int(k), v: float): void = g_y[point_slot(h, j, k)] := v

fnx find_free_slot {i:nat | i <= MAPPING_CAPACITY} .<MAPPING_CAPACITY - i>.
  (i: int(i)): int =
  if i >= MAPPING_CAPACITY then MAPPING_NONE
  else if alive_get(i) then find_free_slot(i + 1)
  else i

// A fresh mapping matches malloc+memset: counts and coordinates start at 0.
// Tail recursion walks one curve, then the next, so a reused slot cannot
// expose the previous owner's control points.
fnx clear_points
  {h:nat | h < MAPPING_CAPACITY}{j,k:nat | j <= MAPPING_INPUTS; k <= MAPPING_CURVE_POINTS}
  .<MAPPING_INPUTS - j, MAPPING_CURVE_POINTS - k>.
  (h: int(h), j: int(j), k: int(k)): void =
  if j >= MAPPING_INPUTS then ()
  else if k >= MAPPING_CURVE_POINTS then clear_points(h, j + 1, 0)
  else let
    val () = x_set(h, j, k, 0.0f)
    val () = y_set(h, j, k, 0.0f)
  in
    clear_points(h, j, k + 1)
  end

fnx clear_curves {h:nat | h < MAPPING_CAPACITY}{j:nat | j <= MAPPING_INPUTS} .<MAPPING_INPUTS - j>.
  (h: int(h), j: int(j)): void =
  if j < MAPPING_INPUTS then let
    val () = n_set(h, j, 0)
  in clear_curves(h, j + 1) end
  else clear_points(h, 0, 0)

implement minepaint_mapping_new(inputs) = let
  val () = anth_require((inputs >= 0) && (inputs <= MAPPING_INPUTS))
  val raw = find_free_slot(0)
  val () = anth_require(raw >= 0)
  val @(ok, h) = ix_try(raw, MAPPING_CAPACITY)
in
  if not(ok) then anth_die_any(DieContractViolation())
  else let
    val () = alive_mark(h)
    val () = base_set(h, 0.0f)
    val () = inputs_set(h, inputs)
    val () = used_set(h, 0)
    val () = clear_curves(h, 0)
  in (cap_mint() | h) end
end

implement minepaint_mapping_free(pf | h) = let
  prval () = cap_burn(pf)
  val () = claim_clear(h)
in
  alive_clear(h)
end

implement minepaint_mapping_stash(pf | h) = let
  prval () = cap_burn(pf)
  val () = claim_clear(h)
in
  h
end

fn claim_free_slot(h: MIx): [ok:bool][h2:nat | h2 < MAPPING_CAPACITY] (option_v(MAP_LIVE(h2), ok) | bool(ok), int(h2)) =
  // Cift claim engeli: egri zaten odunc alinmissa kanit bir daha uretilmez.
  if alive_get(h) * not(claim_get(h)) then let
    val () = claim_mark(h)
  in (Some_v(cap_mint()) | true, h) end
  else (None_v() | false, h)

implement minepaint_mapping_claim(raw) = let
  val @(ok, h) = ix_try(raw, MAPPING_CAPACITY)
in
  if ok then claim_free_slot(h) else (None_v() | false, h)
end

implement minepaint_mapping_get_base_value(pf | h) = base_get(h)

implement minepaint_mapping_set_base_value(pf | h, value) = base_set(h, value)

fn update_used_count(h: MIx, old_n: int, new_n: int): void = let
  val cur_used = used_get(h)
  val updated =
    if (new_n != 0) && (old_n = 0) then cur_used + 1
    else if (new_n = 0) && (old_n != 0) then cur_used - 1
    else cur_used
in
  used_set(h, updated)
end

// Girdi indeksi: aralik disi veya tanimli girdi sayisini asan indeks sozlesme ihlalidir.
fn input_parse(h: MIx, input: int): JIx = let
  val @(ok, j) = ix_try(input, MAPPING_INPUTS)
in
  if ok * (input < inputs_get(h)) then j else anth_die_any(DieContractViolation())
end

implement minepaint_mapping_set_n(pf | h, input, n) = let
  val j = input_parse(h, input)
  val () = anth_require((n >= 0) && (n <= MAPPING_CURVE_POINTS) && (n != 1))
  val () = update_used_count(h, n_get(h, j), n)
in
  n_set(h, j, n)
end

implement minepaint_mapping_get_n(pf | h, input) = n_get(h, input_parse(h, input))

// Nokta indeksi: 0 <= index < egrinin nokta sayisi (<= MAPPING_CURVE_POINTS).
fn point_parse(h: MIx, j: JIx, index: int): Ix(MAPPING_CURVE_POINTS) = let
  val @(ok, k) = ix_try(index, MAPPING_CURVE_POINTS)
in
  if ok * (index < n_get(h, j)) then k else anth_die_any(DieContractViolation())
end

implement minepaint_mapping_set_point(pf | h, input, index, x, y) = let
  val j = input_parse(h, input)
  val k = point_parse(h, j, index)
  val () = x_set(h, j, k, x)
in
  y_set(h, j, k, y)
end

implement minepaint_mapping_get_point(pf | h, input, index, x, y) = let
  val j = input_parse(h, input)
  val k = point_parse(h, j, index)
  val () = x := x_get(h, j, k)
in
  y := y_get(h, j, k)
end

implement minepaint_mapping_is_constant(pf | h) = used_get(h) = 0

implement minepaint_mapping_get_inputs_used_n(pf | h) = used_get(h)

fn eval_segment(x: float, x0: float, y0: float, x1: float, y1: float): float =
  if (x0 = x1) || (y0 = y1) then y0
  else let
    val num = g0float_add(g0float_mul(y1, g0float_sub(x, x0)), g0float_mul(y0, g0float_sub(x1, x)))
    val den = g0float_sub(x1, x0)
  in
    g0float_div(num, den)
  end

fun find_seg {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS}{n:nat | n <= MAPPING_CURVE_POINTS}{i:nat | i <= n} .<n - i>. (
  h: int(h), j: int(j), n: int(n), x: float, i: int(i),
  x0: float, y0: float, x1: float, y1: float
): @(float, float, float, float) =
  if i < n then (
    if x > x1 then find_seg(h, j, n, x, i + 1, x1, y1, x_get(h, j, i), y_get(h, j, i))
    else @(x0, y0, x1, y1)
  ) else @(x0, y0, x1, y1)

// n_get <= MAPPING_CURVE_POINTS set_n sozlesmesiyle saglanir; asan bozuk deger sozlesme ihlalidir.
fn curve_count(h: MIx, j: JIx): Ix(MAPPING_CURVE_POINTS + 1) = let
  val @(ok, n) = ix_try(n_get(h, j), MAPPING_CURVE_POINTS + 1)
in
  if ok then n else anth_die_any(DieContractViolation())
end

fn eval_curve {h:nat | h < MAPPING_CAPACITY}{j:nat | j < MAPPING_INPUTS} (h: int(h), j: int(j), x: float): float = let
  val n = curve_count(h, j)
in
  if n <= 0 then 0.0f
  else if n < 2 then y_get(h, j, 0)
  else let
    val x0 = x_get(h, j, 0)
    val y0 = y_get(h, j, 0)
    val x1 = x_get(h, j, 1)
    val y1 = y_get(h, j, 1)
    val @(sx0, sy0, sx1, sy1) = find_seg(h, j, n, x, 2, x0, y0, x1, y1)
  in
    eval_segment(x, sx0, sy0, sx1, sy1)
  end
end

fn input_at(data: &(@[float][MAPPING_INPUTS]), j: int): float = let
  val @(ok, k) = ix_try(j, MAPPING_INPUTS)
in
  if ok then data[k] else 0.0f
end

fnx sum_inputs {h:nat | h < MAPPING_CAPACITY}{j:nat | j <= MAPPING_INPUTS} .<MAPPING_INPUTS - j>. (
  h: int(h), data: &(@[float][MAPPING_INPUTS]), j: int(j), num_in: int, acc: float
): float =
  if j >= MAPPING_INPUTS then acc
  else if j >= num_in then acc
  else let
    val y = eval_curve(h, j, input_at(data, j))
  in
    sum_inputs(h, data, j + 1, num_in, g0float_add(acc, y))
  end

implement minepaint_mapping_calculate(pf | h, data) = let
  val base = base_get(h)
in
  if used_get(h) = 0 then base
  else sum_inputs(h, data, 0, inputs_get(h), base)
end

implement minepaint_mapping_calculate_single_input(pf | h, input) = let
  var buf: @[float][MAPPING_INPUTS] = @[float][MAPPING_INPUTS](0.0f)
  val () = buf[0] := input
in
  minepaint_mapping_calculate(pf | h, buf)
end
