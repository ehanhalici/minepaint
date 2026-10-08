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

val g_slot_settings = ref<ptr>(the_null_ptr)
val g_slot_inputs = ref<ptr>(the_null_ptr)
val g_slot_ui = ref<ptr>(the_null_ptr)
val g_slot_input = ref<ptr>(the_null_ptr)
val g_slot_xi2 = ref<ptr>(the_null_ptr)

extern fun slot_settings_get(): ptr = "ext#slot_settings_get"
implement slot_settings_get() = !g_slot_settings
extern fun slot_settings_set(p: ptr): void = "ext#slot_settings_set"
implement slot_settings_set(p) = !g_slot_settings := p

extern fun slot_inputs_get(): ptr = "ext#slot_inputs_get"
implement slot_inputs_get() = !g_slot_inputs
extern fun slot_inputs_set(p: ptr): void = "ext#slot_inputs_set"
implement slot_inputs_set(p) = !g_slot_inputs := p

extern fun slot_ui_get(): ptr = "ext#slot_ui_get"
implement slot_ui_get() = !g_slot_ui
extern fun slot_ui_set(p: ptr): void = "ext#slot_ui_set"
implement slot_ui_set(p) = !g_slot_ui := p

extern fun slot_input_get(): ptr = "ext#slot_input_get"
implement slot_input_get() = !g_slot_input
extern fun slot_input_set(p: ptr): void = "ext#slot_input_set"
implement slot_input_set(p) = !g_slot_input := p

extern fun slot_xi2_get(): ptr = "ext#slot_xi2_get"
implement slot_xi2_get() = !g_slot_xi2
extern fun slot_xi2_set(p: ptr): void = "ext#slot_xi2_set"
implement slot_xi2_set(p) = !g_slot_xi2 := p

implement main0(argc, argv) = let
  val _ = ui_init(argc, argv)
in
end
