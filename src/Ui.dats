// src/Ui.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// --- 1. MyCanvas'tan Gelecek Fonksiyon İmzaları ---
// Bu fonksiyonları MyCanvas.dats içinde yazacağız ki UI oraya hükmedebilsin
extern fun canvas_set_brush_color(canvas_ptr: ptr, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
extern fun canvas_set_brush_setting(canvas_ptr: ptr, setting_id: int, value: float): void = "ext#canvas_set_brush_setting"

// --- 2. C'den (FLTK) Çağrılacak ATS Callback'leri ---

// Renk değiştiğinde FLTK bu ispatlı ATS fonksiyonunu çağıracak
extern fun ui_on_color_changed(canvas_ptr: ptr, r: float, g: float, b: float): void = "ext#ui_on_color_changed"
implement ui_on_color_changed(canvas_ptr, r, g, b) = let
  // Gelen veriyi (HSV dönüşümü vs. gerekirse burada yapılabilir)
  // Güvenli Canvas fonksiyonuna iletiyoruz
  val () = canvas_set_brush_color(canvas_ptr, r, g, b)
in
end

// Slider kaydırıldığında FLTK bu ATS fonksiyonunu çağıracak
extern fun ui_on_slider_changed(canvas_ptr: ptr, setting_id: int, value: float): void = "ext#ui_on_slider_changed"
implement ui_on_slider_changed(canvas_ptr, setting_id, value) = let
  // MyPaint fırça ayarını ATS üzerinden güvenle yap
  val () = canvas_set_brush_setting(canvas_ptr, setting_id, value)
in
end

// --- 3. UI BAŞLATICI ---

// DÜZELTME: ptr yerine {n:int} (argc: int(n), argv: !argv(n)) kullanıyoruz.
extern fun ffi_ui_init {n:int} (argc: int(n), argv: !argv(n)): int = "ext#"

extern fun ui_init {n:int} (argc: int(n), argv: !argv(n)): int = "ext#ui_init"
implement ui_init(argc, argv) = let
  // FLTK arayüzünü ayağa kaldır ve olay döngüsünü başlat
  val ret = ffi_ui_init(argc, argv)
in
  ret
end