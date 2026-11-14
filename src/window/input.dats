// src/window/input.dats
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// --- Araç Türleri (Platform-Bağımsız) ---
datatype InputTool = ToolMouse | ToolStylus | ToolEraser

// Kalem ucunun hangi yüzü (silgi ucu sol tuşu sağ tuşa çevirir)
datatype StylusTip = TipNib | TipEraser

// Hareket olayında basılı tutulan fare tuşu (öncelik: orta > sağ > sol)
datatype HeldButton = HeldNone | HeldLeft | HeldMiddle | HeldRight

// X11 buton numarası sınırında ayrıştırılan tuş türü
datatype MouseBtn = BtnNone | BtnLeft | BtnMiddle | BtnRight | BtnWheelUp | BtnWheelDown

#define INPUT_DEFAULT_PRESSURE 0.8f
#define INPUT_TOOL_TIMEOUT 0.5

extern fun mouse_btn_of_code(code: int): MouseBtn = "ext#mouse_btn_of_code"
implement mouse_btn_of_code(code) =
  if code = 1 then BtnLeft()
  else if code = 2 then BtnMiddle()
  else if code = 3 then BtnRight()
  else if code = 4 then BtnWheelUp()
  else if code = 5 then BtnWheelDown()
  else BtnNone()

extern fun mouse_btn_code(b: MouseBtn): int = "ext#mouse_btn_code"
implement mouse_btn_code(b) =
  case+ b of
  | BtnNone() => 0
  | BtnLeft() => 1
  | BtnMiddle() => 2
  | BtnRight() => 3
  | BtnWheelUp() => 4
  | BtnWheelDown() => 5

typedef InputState = @{
  tool= InputTool,
  pressure= float,
  last_time= double
}

val g_in = ref<InputState>(@{
  tool= ToolMouse(),
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
  val () = st->tool := ToolStylus()
  val () = st->pressure := input_clamp_pressure(p)
  val () = st->last_time := now
in () end

extern fun input_set_eraser_pressure(p: float, now: double): void = "ext#input_set_eraser_pressure"
implement input_set_eraser_pressure(p, now) = let
  val st = input_state_ref()
  val () = st->tool := ToolEraser()
  val () = st->pressure := input_clamp_pressure(p)
  val () = st->last_time := now
in () end

// --- Araç ve Basınç Sorgulama ---
fn tool_is_mouse(t: InputTool): bool =
  case+ t of
  | ToolMouse() => true
  | ToolStylus() => false
  | ToolEraser() => false

fn tool_is_eraser(t: InputTool): bool =
  case+ t of
  | ToolMouse() => false
  | ToolStylus() => false
  | ToolEraser() => true

extern fun input_is_stylus_active(now: double): bool = "ext#input_is_stylus_active"
implement input_is_stylus_active(now) = let
  val st = input_state_ref()
  val diff = now - st->last_time
in
  (not(tool_is_mouse(st->tool))) && (diff < INPUT_TOOL_TIMEOUT)
end

extern fun input_is_eraser_active(now: double): bool = "ext#input_is_eraser_active"
implement input_is_eraser_active(now) = let
  val st = input_state_ref()
  val diff = now - st->last_time
in
  tool_is_eraser(st->tool) && (diff < INPUT_TOOL_TIMEOUT)
end

extern fun input_stylus_tip(now: double): StylusTip = "ext#input_stylus_tip"
implement input_stylus_tip(now) =
  if input_is_eraser_active(now) then TipEraser() else TipNib()

extern fun input_get_pressure(now: double): float = "ext#input_get_pressure"
implement input_get_pressure(now) = let
  val st = input_state_ref()
in
  if input_is_stylus_active(now) then st->pressure
  else INPUT_DEFAULT_PRESSURE
end

// --- Buton Eşleme ve Ayrıştırma (Pan / Silgi Önceliği) ---

fn btn_is_pan_hold(b: MouseBtn): bool =
  case+ b of
  | BtnMiddle() => true
  | BtnRight() => true
  | BtnNone() => false
  | BtnLeft() => false
  | BtnWheelUp() => false
  | BtnWheelDown() => false

extern fun btn_is_none(b: MouseBtn): bool = "ext#btn_is_none"
implement btn_is_none(b) =
  case+ b of
  | BtnNone() => true
  | BtnLeft() => false
  | BtnMiddle() => false
  | BtnRight() => false
  | BtnWheelUp() => false
  | BtnWheelDown() => false

extern fun btn_is_middle(b: MouseBtn): bool = "ext#btn_is_middle"
implement btn_is_middle(b) =
  case+ b of
  | BtnMiddle() => true
  | BtnNone() => false
  | BtnLeft() => false
  | BtnRight() => false
  | BtnWheelUp() => false
  | BtnWheelDown() => false

fn btn_is_right(b: MouseBtn): bool =
  case+ b of
  | BtnRight() => true
  | BtnNone() => false
  | BtnLeft() => false
  | BtnMiddle() => false
  | BtnWheelUp() => false
  | BtnWheelDown() => false

extern fun btn_is_left(b: MouseBtn): bool = "ext#btn_is_left"
implement btn_is_left(b) =
  case+ b of
  | BtnLeft() => true
  | BtnNone() => false
  | BtnMiddle() => false
  | BtnRight() => false
  | BtnWheelUp() => false
  | BtnWheelDown() => false

fn remap_left(active_btn: MouseBtn, tip: StylusTip): MouseBtn =
  case+ tip of
  | TipEraser() => BtnRight()
  | TipNib() => if btn_is_pan_hold(active_btn) then active_btn else BtnLeft()

// Fiziksel silgi ucu veya basılı tuşlara göre buton remapping
extern fun input_remap_button(raw_btn: MouseBtn, active_btn: MouseBtn, tip: StylusTip): MouseBtn = "ext#input_remap_button"
implement input_remap_button(raw_btn, active_btn, tip) =
  if btn_is_left(raw_btn) then remap_left(active_btn, tip) else raw_btn

fn motion_held_left(active_btn: MouseBtn): MouseBtn =
  if btn_is_none(active_btn) then BtnLeft() else active_btn

// Hareket esnasında geçerli fare / kalem butonu seçimi
extern fun input_motion_button(held: HeldButton, active_btn: MouseBtn): MouseBtn = "ext#input_motion_button"
implement input_motion_button(held, active_btn) =
  case+ held of
  | HeldMiddle() => BtnMiddle()
  | HeldRight() => BtnRight()
  | HeldLeft() => motion_held_left(active_btn)
  | HeldNone() => active_btn

fn release_keep(active_btn: MouseBtn, hit: bool): MouseBtn =
  if hit then BtnNone() else active_btn

// Tuş bırakıldığında sonraki aktif buton durumu
extern fun input_release_next_button(released_raw_btn: MouseBtn, active_btn: MouseBtn): MouseBtn = "ext#input_release_next_button"
implement input_release_next_button(released_raw_btn, active_btn) =
  if btn_is_middle(active_btn) then release_keep(active_btn, btn_is_middle(released_raw_btn))
  else if btn_is_right(active_btn) then release_keep(active_btn, btn_is_right(released_raw_btn))
  else BtnNone()

// Çizginin sonlandırılıp sonlandırılmayacağı kararı
extern fun input_should_release_stroke(released_raw_btn: MouseBtn, active_btn: MouseBtn): bool = "ext#input_should_release_stroke"
implement input_should_release_stroke(released_raw_btn, active_btn) =
  if btn_is_middle(active_btn) then btn_is_middle(released_raw_btn)
  else true
