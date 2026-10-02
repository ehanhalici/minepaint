// src/draw_engine/brush_settings.dats
// Native ATS2 implementation of MyPaint Brush Settings Metadata
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
#include "./brushsettings_gen.hats"

%{^
#include <stdlib.h>

static void *g_settings_table_ptr = NULL;
static void *g_inputs_table_ptr = NULL;

static inline void* get_g_settings_table_ptr(void) { return g_settings_table_ptr; }
static inline void set_g_settings_table_ptr(void *p) { g_settings_table_ptr = p; }
static inline void* get_g_inputs_table_ptr(void) { return g_inputs_table_ptr; }
static inline void set_g_inputs_table_ptr(void *p) { g_inputs_table_ptr = p; }
%}

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun get_g_settings_table_ptr(): ptr = "mac#"
extern fun set_g_settings_table_ptr(p: ptr): void = "mac#"
extern fun get_g_inputs_table_ptr(): ptr = "mac#"
extern fun set_g_inputs_table_ptr(p: ptr): void = "mac#"

fn str_equal(s1: string, s2: string): bool = let
  val p1 = $UN.cast{ptr}(s1)
  val p2 = $UN.cast{ptr}(s2)
  fun loop(p1: ptr, p2: ptr): bool = let
    val c1 = $UN.ptr0_get<char>(p1)
    val c2 = $UN.ptr0_get<char>(p2)
  in
    if c1 != c2 then false
    else if c1 = '\0' then true
    else loop(ptr_add<char>(p1, 1), ptr_add<char>(p2, 1))
  end
in
  loop(p1, p2)
end

fun get_settings_base(): ptr = let
  val p = get_g_settings_table_ptr()
in
  if p != the_null_ptr then p
  else let
    val sz = g0int2uint_int_size(MYPAINT_BRUSH_SETTINGS_COUNT) * sizeof<MyPaintBrushSettingInfo>
    val new_p = malloc(sz)
    val () = populate_settings_info_array(new_p)
    val () = set_g_settings_table_ptr(new_p)
  in
    new_p
  end
end

fun get_inputs_base(): ptr = let
  val p = get_g_inputs_table_ptr()
in
  if p != the_null_ptr then p
  else let
    val sz = g0int2uint_int_size(MYPAINT_BRUSH_INPUTS_COUNT) * sizeof<MyPaintBrushInputInfo>
    val new_p = malloc(sz)
    val () = populate_inputs_info_array(new_p)
    val () = set_g_inputs_table_ptr(new_p)
  in
    new_p
  end
end

fn get_setting_info_ptr(idx: int): ptr =
  if idx >= 0 && idx < MYPAINT_BRUSH_SETTINGS_COUNT then
    ptr_add<MyPaintBrushSettingInfo>(get_settings_base(), idx)
  else the_null_ptr

fn get_input_info_ptr(idx: int): ptr =
  if idx >= 0 && idx < MYPAINT_BRUSH_INPUTS_COUNT then
    ptr_add<MyPaintBrushInputInfo>(get_inputs_base(), idx)
  else the_null_ptr

extern fun mypaint_brush_setting_info(id: int): ptr = "ext#mypaint_brush_setting_info"
implement mypaint_brush_setting_info(id) = get_setting_info_ptr(id)

extern fun mypaint_brush_setting_info_get_name(self: ptr): string = "ext#mypaint_brush_setting_info_get_name"
implement mypaint_brush_setting_info_get_name(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MyPaintBrushSettingInfo)}(self)
  in s->name end
  else ""

extern fun mypaint_brush_setting_info_get_tooltip(self: ptr): string = "ext#mypaint_brush_setting_info_get_tooltip"
implement mypaint_brush_setting_info_get_tooltip(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MyPaintBrushSettingInfo)}(self)
  in s->tooltip end
  else ""

extern fun mypaint_brush_setting_from_cname(cname: string): int = "ext#mypaint_brush_setting_from_cname"
implement mypaint_brush_setting_from_cname(cname) = let
  fun loop(i: int): int =
    if i < MYPAINT_BRUSH_SETTINGS_COUNT then let
      val p = get_setting_info_ptr(i)
      val s = $UN.cast{ref(MyPaintBrushSettingInfo)}(p)
    in
      if str_equal(s->cname, cname) then i
      else loop(i + 1)
    end
    else ~1
in
  loop(0)
end

extern fun mypaint_brush_input_info(id: int): ptr = "ext#mypaint_brush_input_info"
implement mypaint_brush_input_info(id) = get_input_info_ptr(id)

extern fun mypaint_brush_input_info_get_name(self: ptr): string = "ext#mypaint_brush_input_info_get_name"
implement mypaint_brush_input_info_get_name(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MyPaintBrushInputInfo)}(self)
  in s->name end
  else ""

extern fun mypaint_brush_input_info_get_tooltip(self: ptr): string = "ext#mypaint_brush_input_info_get_tooltip"
implement mypaint_brush_input_info_get_tooltip(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MyPaintBrushInputInfo)}(self)
  in s->tooltip end
  else ""

extern fun mypaint_brush_input_from_cname(cname: string): int = "ext#mypaint_brush_input_from_cname"
implement mypaint_brush_input_from_cname(cname) = let
  fun loop(i: int): int =
    if i < MYPAINT_BRUSH_INPUTS_COUNT then let
      val p = get_input_info_ptr(i)
      val s = $UN.cast{ref(MyPaintBrushInputInfo)}(p)
    in
      if str_equal(s->cname, cname) then i
      else loop(i + 1)
    end
    else ~1
in
  loop(0)
end
