#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "app/ui.dats"

val g_slot_settings = ref<ptr>(the_null_ptr)
val g_slot_inputs = ref<ptr>(the_null_ptr)
val g_slot_ui = ref<ptr>(the_null_ptr)

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

implement main0(argc, argv) = let
  val _ = ui_init(argc, argv)
in
end
