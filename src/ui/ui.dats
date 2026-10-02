// src/ui/ui.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"



// FFI Fonksiyon İmzaları
extern fun mypaint_brush_new(): ptr = "ext#mypaint_brush_new"
extern fun mypaint_brush_set_base_value(brush: ptr, setting: int, value: float): void = "ext#mypaint_brush_set_base_value"
extern fun canvas_state_create(brush: ptr): ptr = "ext#canvas_state_create"
extern fun window_create_and_run(canvas_ptr: ptr): int = "ext#window_create_and_run"
extern fun canvas_set_brush_color(canvas_ptr: ptr, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
extern fun canvas_set_brush_setting(canvas_ptr: ptr, setting_id: int, value: float): void = "ext#canvas_set_brush_setting"

// MyPaint Fırça Ayar Sabitleri
#define MYPAINT_BRUSH_SETTING_OPAQUE 0
#define MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE 2
#define MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY 1
#define MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC 3
#define MYPAINT_BRUSH_SETTING_HARDNESS 4
#define MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS 8
#define MYPAINT_BRUSH_SETTING_DABS_PER_SECOND 9
#define MYPAINT_BRUSH_SETTING_SLOW_TRACKING 31
#define MYPAINT_BRUSH_SETTING_TRACKING_NOISE 33
#define MYPAINT_BRUSH_SETTING_ANTI_ALIASING 6
#define MYPAINT_BRUSH_SETTING_COLOR_H 34
#define MYPAINT_BRUSH_SETTING_COLOR_S 35
#define MYPAINT_BRUSH_SETTING_COLOR_V 36

// UI Başlatıcı
extern fun ui_init {n:int} (argc: int(n), argv: !argv(n)): int = "ext#ui_init"
implement ui_init(argc, argv) = let
  // 1. MyPaint Fırçasını oluştur ve başlangıç ayarlarını yap
  val brush = mypaint_brush_new()
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE, 1.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE, 1.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY, 1.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 1.2f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_HARDNESS, 0.1f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS, 5.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_DABS_PER_SECOND, 40.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 3.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_TRACKING_NOISE, 0.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_ANTI_ALIASING, 1.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_H, 1.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_S, 0.0f)
  val () = mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_V, 0.729f)

  // 2. Canvas Durumunu Başlat
  val canvas_state = canvas_state_create(brush)

  // 3. Pencere ve Olay Döngüsünü Başlat
  val ret = window_create_and_run(canvas_state)
in
  ret
end
