// src/draw_engine/mapping_view.sats
// Dinamik egri (mapping) icin dogrusal yetenek: MAP_LIVE(h) olmadan okuma/yazma yapilamaz.

#include "draw_engine/minepaint_types.hats"
staload "sys/capability.sats"

#define MAPPING_CAPACITY 512

stadef MAP_LIVE (h: int) = CAP(KIND_MAPPING, h)

fun minepaint_mapping_new (inputs: int): [h:nat | h < MAPPING_CAPACITY] (MAP_LIVE(h) | int(h)) = "ext#minepaint_mapping_new"
fun minepaint_mapping_free {h:nat | h < MAPPING_CAPACITY} (pf: MAP_LIVE(h) | h: int(h)): void = "ext#minepaint_mapping_free"

fun minepaint_mapping_get_base_value {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h)): float = "ext#minepaint_mapping_get_base_value"
fun minepaint_mapping_set_base_value {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h), value: float): void = "ext#minepaint_mapping_set_base_value"
fun minepaint_mapping_set_n {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h), input: int, n: int): void = "ext#minepaint_mapping_set_n"
fun minepaint_mapping_get_n {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h), input: int): int = "ext#minepaint_mapping_get_n"
fun minepaint_mapping_set_point {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h), input: int, index: int, x: float, y: float): void = "ext#minepaint_mapping_set_point"
fun minepaint_mapping_get_point {h:nat | h < MAPPING_CAPACITY} (
  pf: !MAP_LIVE(h) | h: int(h), input: int, index: int, x: &float? >> float, y: &float? >> float
): void = "ext#minepaint_mapping_get_point"
fun minepaint_mapping_is_constant {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h)): bool = "ext#minepaint_mapping_is_constant"
fun minepaint_mapping_get_inputs_used_n {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h)): int = "ext#minepaint_mapping_get_inputs_used_n"
fun minepaint_mapping_calculate {h:nat | h < MAPPING_CAPACITY} (
  pf: !MAP_LIVE(h) | h: int(h), data: &(@[float][MAPPING_INPUTS])
): float = "ext#minepaint_mapping_calculate"
fun minepaint_mapping_calculate_single_input {h:nat | h < MAPPING_CAPACITY} (pf: !MAP_LIVE(h) | h: int(h), input: float): float = "ext#minepaint_mapping_calculate_single_input"

fun minepaint_mapping_stash {h:nat | h < MAPPING_CAPACITY} (pf: MAP_LIVE(h) | h: int(h)): int = "ext#minepaint_mapping_stash"
fun minepaint_mapping_claim (raw: int): [ok:bool][h:nat | h < MAPPING_CAPACITY] (option_v(MAP_LIVE(h), ok) | bool(ok), int(h)) = "ext#minepaint_mapping_claim"
