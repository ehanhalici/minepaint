#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "app/ui.dats"

// mapping.dats keeps its arena in top-level values. Those run only when this
// file's dynload calls mapping's dynload. The path must match patsopt -d.
#dynload "src/draw_engine/mapping.dats"
#dynload "src/draw_engine/brush_settings.dats"
#dynload "src/draw_engine/brush.dats"
#dynload "src/draw_engine/symmetry.dats"
#dynload "src/draw_engine/dab.dats"
#dynload "src/draw_engine/bbox.dats"
#dynload "src/draw_engine/fifo.dats"
#dynload "src/draw_engine/tilemap.dats"
#dynload "src/draw_engine/operationqueue.dats"
#dynload "src/canvas/stroke_queue.dats"
#dynload "src/canvas/canvas.dats"
#dynload "src/ui/state.dats"
#dynload "src/window/input.dats"
#dynload "src/x11/xi2.dats"

implement main0(argc, argv) = let
  val _ = ui_init(argc, argv)
in
end
