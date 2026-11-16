// src/draw_engine/brushsettings_gen.hats
// Pure ATS2 definitions for MinePaint Brush Settings and Inputs metadata
#ifndef BRUSHSETTINGS_GEN_HATS
#define BRUSHSETTINGS_GEN_HATS

#define MINEPAINT_BRUSH_SETTINGS_COUNT 65

typedef MinePaintBrushSettingInfo = @{
  cname= string,
  name= string,
  constant= int,
  min= float,
  def= float,
  max= float,
  tooltip= string
}

#endif
