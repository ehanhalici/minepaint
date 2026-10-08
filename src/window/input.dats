// src/window/input.dats
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// --- Araç Türleri (Platform-Bağımsız) ---
#define INPUT_TOOL_MOUSE 0
#define INPUT_TOOL_STYLUS 1
#define INPUT_TOOL_ERASER 2

#define INPUT_DEFAULT_PRESSURE 0.8f
#define INPUT_TOOL_TIMEOUT 0.5

#define BTN_NONE 0
#define BTN_LEFT 1
#define BTN_MIDDLE 2
#define BTN_RIGHT 3

typedef InputState = @{
  tool= int,
  pressure= float,
  last_time= double
}

val g_in = ref<InputState>(@{
  tool= INPUT_TOOL_MOUSE,
  pressure= INPUT_DEFAULT_PRESSURE,
  last_time= 0.0
})

fn input_state_ref(): ref(InputState) = g_in

// --- Basınç Değeri Yardımcıları ---
extern fun input_get_default_pressure(): float = "ext#input_get_default_pressure"
implement input_get_default_pressure() = INPUT_DEFAULT_PRESSURE

fn input_clamp_pressure(p: float): float =
  if p < 0.01f then 0.01f
  else if p > 1.0f then 1.0f
  else p

// --- Kalem ve Silgi Durumu Güncelleme ---
extern fun input_set_stylus_pressure(p: float, now: double): void = "ext#input_set_stylus_pressure"
implement input_set_stylus_pressure(p, now) = let
  val st = input_state_ref()
  val () = st->tool := INPUT_TOOL_STYLUS
  val () = st->pressure := input_clamp_pressure(p)
  val () = st->last_time := now
in () end

extern fun input_set_eraser_pressure(p: float, now: double): void = "ext#input_set_eraser_pressure"
implement input_set_eraser_pressure(p, now) = let
  val st = input_state_ref()
  val () = st->tool := INPUT_TOOL_ERASER
  val () = st->pressure := input_clamp_pressure(p)
  val () = st->last_time := now
in () end

// --- Araç ve Basınç Sorgulama ---
extern fun input_is_stylus_active(now: double): bool = "ext#input_is_stylus_active"
implement input_is_stylus_active(now) = let
  val st = input_state_ref()
  val diff = now - st->last_time
in
  (st->tool != INPUT_TOOL_MOUSE) && (diff < INPUT_TOOL_TIMEOUT)
end

extern fun input_is_eraser_active(now: double): bool = "ext#input_is_eraser_active"
implement input_is_eraser_active(now) = let
  val st = input_state_ref()
  val diff = now - st->last_time
in
  (st->tool = INPUT_TOOL_ERASER) && (diff < INPUT_TOOL_TIMEOUT)
end

extern fun input_get_pressure(now: double): float = "ext#input_get_pressure"
implement input_get_pressure(now) = let
  val st = input_state_ref()
in
  if input_is_stylus_active(now) then st->pressure
  else INPUT_DEFAULT_PRESSURE
end

// --- Buton Eşleme ve Ayrıştırma (Pan / Silgi Önceliği) ---

// Fiziksel silgi ucu veya basılı tuşlara göre buton remapping
extern fun input_remap_button(raw_btn: int, active_btn: int, is_eraser: bool): int = "ext#input_remap_button"
implement input_remap_button(raw_btn, active_btn, is_eraser) =
  if is_eraser && (raw_btn = BTN_LEFT) then BTN_RIGHT
  else if (active_btn = BTN_MIDDLE || active_btn = BTN_RIGHT) && (raw_btn = BTN_LEFT) then active_btn
  else raw_btn

// Hareket esnasında geçerli fare / kalem butonu seçimi
extern fun input_motion_button(has_b1: bool, has_b2: bool, has_b3: bool, active_btn: int): int = "ext#input_motion_button"
implement input_motion_button(has_b1, has_b2, has_b3, active_btn) =
  if has_b2 then BTN_MIDDLE
  else if has_b3 then BTN_RIGHT
  else if (active_btn = BTN_MIDDLE || active_btn = BTN_RIGHT) then active_btn
  else if active_btn != BTN_NONE then active_btn
  else if has_b1 then BTN_LEFT
  else BTN_NONE

// Tuş bırakıldığında sonraki aktif buton durumu
extern fun input_release_next_button(released_raw_btn: int, active_btn: int): int = "ext#input_release_next_button"
implement input_release_next_button(released_raw_btn, active_btn) =
  if active_btn = BTN_MIDDLE then (if released_raw_btn = BTN_MIDDLE then BTN_NONE else BTN_MIDDLE)
  else if active_btn = BTN_RIGHT then (if released_raw_btn = BTN_RIGHT then BTN_NONE else BTN_RIGHT)
  else BTN_NONE

// Çizginin sonlandırılıp sonlandırılmayacağı kararı
extern fun input_should_release_stroke(released_raw_btn: int, active_btn: int): bool = "ext#input_should_release_stroke"
implement input_should_release_stroke(released_raw_btn, active_btn) =
  if active_btn = BTN_MIDDLE then (released_raw_btn = BTN_MIDDLE)
  else true
