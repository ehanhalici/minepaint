// Brush ayar metaverisi: tipli sabit tablo (brushsettings_fill.hats). Erisim Ix(65) ile; aralik disi tasarim ihlalidir.
// main.dats bu dosyayi baslatir (tablo kullanimdan once dolu).
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "sys/airlock.hats"
#include "sys/arena.hats"
#include "./brushsettings_gen.hats"

#include "./brushsettings_fill.hats"

extern fun minepaint_brush_setting_def(id: int): float = "ext#minepaint_brush_setting_def"
implement minepaint_brush_setting_def(id) = let
  val @(ok, i) = ix_try(id, 65)
in
  if ok then g_settings[i].def else g0float2float_double_float(anth_die_dbl(DieContractViolation()))
end
