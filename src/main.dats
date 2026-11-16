#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "app/ui.dats"

// mapping.dats keeps its arena in top-level values. Those run only when this
// file initialises mapping. The path must match patsopt -d.
#dynload "src/draw_engine/setting_id.dats"
#dynload "src/draw_engine/state_id.dats"
#dynload "src/draw_engine/input_id.dats"
#dynload "src/ui/slider_id.dats"
#dynload "src/ui/color.dats"
#dynload "src/ui/font.dats"
#dynload "src/draw_engine/mapping.dats"
#dynload "src/draw_engine/brush_settings.dats"
#dynload "src/draw_engine/rng.dats"
#dynload "src/draw_engine/brush.dats"
#dynload "src/canvas/layer.dats"
#dynload "src/canvas/stroke_queue.dats"
#dynload "src/canvas/canvas.dats"
#dynload "src/ui/state.dats"
#dynload "src/window/input.dats"
#dynload "src/x11/xi2.dats"
#dynload "src/brushes/catalog.dats"
#dynload "src/brushes/classic.dats"
#dynload "src/brushes/deevad.dats"
#dynload "src/brushes/dieterle.dats"
#dynload "src/brushes/experimental.dats"
#dynload "src/brushes/ramon.dats"
#dynload "src/brushes/tanda.dats"
#dynload "src/brushes/kaerhon.dats"

implement main0(argc, argv) = let
  val _ = ui_init(argc, argv)
in
end
