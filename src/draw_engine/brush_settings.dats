// src/draw_engine/brush_settings.dats
// Native ATS2 implementation of MinePaint Brush Settings Metadata
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
#include "./brushsettings_gen.hats"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun slot_settings_get(): ptr = "ext#slot_settings_get"
extern fun slot_settings_set(p: ptr): void = "ext#slot_settings_set"
extern fun slot_inputs_get(): ptr = "ext#slot_inputs_get"
extern fun slot_inputs_set(p: ptr): void = "ext#slot_inputs_set"

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
  val p = slot_settings_get()
in
  if p != the_null_ptr then p
  else let
    val sz = g0int2uint_int_size(MINEPAINT_BRUSH_SETTINGS_COUNT) * sizeof<MinePaintBrushSettingInfo>
    val new_p = malloc(sz)
    val () = populate_settings_info_array(new_p)
    val () = slot_settings_set(new_p)
  in
    new_p
  end
end

fun get_inputs_base(): ptr = let
  val p = slot_inputs_get()
in
  if p != the_null_ptr then p
  else let
    val sz = g0int2uint_int_size(MINEPAINT_BRUSH_INPUTS_COUNT) * sizeof<MinePaintBrushInputInfo>
    val new_p = malloc(sz)
    val () = populate_inputs_info_array(new_p)
    val () = slot_inputs_set(new_p)
  in
    new_p
  end
end

fn get_setting_info_ptr(idx: int): ptr =
  if idx >= 0 && idx < MINEPAINT_BRUSH_SETTINGS_COUNT then
    ptr_add<MinePaintBrushSettingInfo>(get_settings_base(), idx)
  else the_null_ptr

fn get_input_info_ptr(idx: int): ptr =
  if idx >= 0 && idx < MINEPAINT_BRUSH_INPUTS_COUNT then
    ptr_add<MinePaintBrushInputInfo>(get_inputs_base(), idx)
  else the_null_ptr

extern fun minepaint_brush_setting_info(id: int): ptr = "ext#minepaint_brush_setting_info"
implement minepaint_brush_setting_info(id) = get_setting_info_ptr(id)

extern fun minepaint_brush_setting_info_get_name(self: ptr): string = "ext#minepaint_brush_setting_info_get_name"
implement minepaint_brush_setting_info_get_name(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MinePaintBrushSettingInfo)}(self)
  in s->name end
  else ""

extern fun minepaint_brush_setting_info_get_tooltip(self: ptr): string = "ext#minepaint_brush_setting_info_get_tooltip"
implement minepaint_brush_setting_info_get_tooltip(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MinePaintBrushSettingInfo)}(self)
  in s->tooltip end
  else ""

extern fun minepaint_brush_setting_from_cname(cname: string): int = "ext#minepaint_brush_setting_from_cname"
implement minepaint_brush_setting_from_cname(cname) = let
  fun loop(i: int): int =
    if i < MINEPAINT_BRUSH_SETTINGS_COUNT then let
      val p = get_setting_info_ptr(i)
      val s = $UN.cast{ref(MinePaintBrushSettingInfo)}(p)
    in
      if str_equal(s->cname, cname) then i
      else loop(i + 1)
    end
    else ~1
in
  loop(0)
end

extern fun minepaint_brush_input_info(id: int): ptr = "ext#minepaint_brush_input_info"
implement minepaint_brush_input_info(id) = get_input_info_ptr(id)

extern fun minepaint_brush_input_info_get_name(self: ptr): string = "ext#minepaint_brush_input_info_get_name"
implement minepaint_brush_input_info_get_name(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MinePaintBrushInputInfo)}(self)
  in s->name end
  else ""

extern fun minepaint_brush_input_info_get_tooltip(self: ptr): string = "ext#minepaint_brush_input_info_get_tooltip"
implement minepaint_brush_input_info_get_tooltip(self) =
  if self != the_null_ptr then let
    val s = $UN.cast{ref(MinePaintBrushInputInfo)}(self)
  in s->tooltip end
  else ""

extern fun minepaint_brush_input_from_cname(cname: string): int = "ext#minepaint_brush_input_from_cname"
implement minepaint_brush_input_from_cname(cname) = let
  fun loop(i: int): int =
    if i < MINEPAINT_BRUSH_INPUTS_COUNT then let
      val p = get_input_info_ptr(i)
      val s = $UN.cast{ref(MinePaintBrushInputInfo)}(p)
    in
      if str_equal(s->cname, cname) then i
      else loop(i + 1)
    end
    else ~1
in
  loop(0)
end
