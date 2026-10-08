// Brush setting and input metadata as typed arrays.
// main.dats dynloads this file so the tables are filled before use.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "./brushsettings_gen.hats"

val g_set_blank = @{
  cname= "", name= "", constant= 0,
  min= 0.0f, def= 0.0f, max= 0.0f, tooltip= ""
} : MinePaintBrushSettingInfo
val g_in_blank = @{
  cname= "", hard_min= 0.0f, soft_min= 0.0f, normal= 0.0f,
  soft_max= 0.0f, hard_max= 0.0f, name= "", tooltip= ""
} : MinePaintBrushInputInfo
val g_settings = arrayref_make_elt<MinePaintBrushSettingInfo>(i2sz(65), g_set_blank)
val g_inputs = arrayref_make_elt<MinePaintBrushInputInfo>(i2sz(18), g_in_blank)

#include "./brushsettings_fill.hats"

val () = populate_settings_info_array()
val () = populate_inputs_info_array()

fn setting_at(id: int): MinePaintBrushSettingInfo = let
  val i = g1ofg0(id)
in
  if (i >= 0) * (i < 65) then g_settings[i] else g_set_blank
end

fn input_at(id: int): MinePaintBrushInputInfo = let
  val i = g1ofg0(id)
in
  if (i >= 0) * (i < 18) then g_inputs[i] else g_in_blank
end

extern fun minepaint_brush_setting_info(id: int): MinePaintBrushSettingInfo = "ext#minepaint_brush_setting_info"
implement minepaint_brush_setting_info(id) = setting_at(id)

extern fun minepaint_brush_setting_info_get_name(id: int): string = "ext#minepaint_brush_setting_info_get_name"
implement minepaint_brush_setting_info_get_name(id) = let
  val s = setting_at(id)
in
  s.name
end

extern fun minepaint_brush_setting_info_get_tooltip(id: int): string = "ext#minepaint_brush_setting_info_get_tooltip"
implement minepaint_brush_setting_info_get_tooltip(id) = let
  val s = setting_at(id)
in
  s.tooltip
end

extern fun minepaint_brush_setting_from_cname(cname: string): int = "ext#minepaint_brush_setting_from_cname"
implement minepaint_brush_setting_from_cname(cname) = let
  fun loop(i: int): int =
    if i < 65 then let
      val s = setting_at(i)
    in
      if s.cname = cname then i else loop(i + 1)
    end
    else ~1
in
  loop(0)
end

extern fun minepaint_brush_input_info(id: int): MinePaintBrushInputInfo = "ext#minepaint_brush_input_info"
implement minepaint_brush_input_info(id) = input_at(id)

extern fun minepaint_brush_input_info_get_name(id: int): string = "ext#minepaint_brush_input_info_get_name"
implement minepaint_brush_input_info_get_name(id) = let
  val s = input_at(id)
in
  s.name
end

extern fun minepaint_brush_input_info_get_tooltip(id: int): string = "ext#minepaint_brush_input_info_get_tooltip"
implement minepaint_brush_input_info_get_tooltip(id) = let
  val s = input_at(id)
in
  s.tooltip
end

extern fun minepaint_brush_input_from_cname(cname: string): int = "ext#minepaint_brush_input_from_cname"
implement minepaint_brush_input_from_cname(cname) = let
  fun loop(i: int): int =
    if i < 18 then let
      val s = input_at(i)
    in
      if s.cname = cname then i else loop(i + 1)
    end
    else ~1
in
  loop(0)
end
