// src/ui/ui.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

%{^
#include <mypaint-brush.h>
#include <mypaint-brush-settings-gen.h>

extern void* canvas_state_create(void* brush);
extern int window_create_and_run(void* canvas_ptr);
extern void canvas_set_brush_color(void* canvas_ptr, float r, float g, float b);
extern void canvas_set_brush_setting(void* canvas_ptr, int setting_id, float value);
%}

// FFI Fonksiyon İmzaları
extern fun mypaint_brush_new(): ptr = "mac#"
extern fun mypaint_brush_set_base_value(brush: ptr, setting: int, value: float): void = "mac#"
extern fun canvas_state_create(brush: ptr): ptr = "ext#canvas_state_create"
extern fun window_create_and_run(canvas_ptr: ptr): int = "ext#window_create_and_run"
extern fun canvas_set_brush_color(canvas_ptr: ptr, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
extern fun canvas_set_brush_setting(canvas_ptr: ptr, setting_id: int, value: float): void = "ext#canvas_set_brush_setting"

// MyPaint Fırça Ayar Sabitleri
macdef MYPAINT_BRUSH_SETTING_OPAQUE = $extval(int, "MYPAINT_BRUSH_SETTING_OPAQUE")
macdef MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE = $extval(int, "MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE")
macdef MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY = $extval(int, "MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY")
macdef MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC = $extval(int, "MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC")
macdef MYPAINT_BRUSH_SETTING_HARDNESS = $extval(int, "MYPAINT_BRUSH_SETTING_HARDNESS")
macdef MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS = $extval(int, "MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS")
macdef MYPAINT_BRUSH_SETTING_DABS_PER_SECOND = $extval(int, "MYPAINT_BRUSH_SETTING_DABS_PER_SECOND")
macdef MYPAINT_BRUSH_SETTING_SLOW_TRACKING = $extval(int, "MYPAINT_BRUSH_SETTING_SLOW_TRACKING")
macdef MYPAINT_BRUSH_SETTING_TRACKING_NOISE = $extval(int, "MYPAINT_BRUSH_SETTING_TRACKING_NOISE")
macdef MYPAINT_BRUSH_SETTING_ANTI_ALIASING = $extval(int, "MYPAINT_BRUSH_SETTING_ANTI_ALIASING")
macdef MYPAINT_BRUSH_SETTING_COLOR_H = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_H")
macdef MYPAINT_BRUSH_SETTING_COLOR_S = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_S")
macdef MYPAINT_BRUSH_SETTING_COLOR_V = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_V")

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
