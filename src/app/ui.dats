#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "draw_engine/brush_view.sats"
staload "sys/capability.sats"
staload "canvas/canvas_view.sats"
extern fun window_create_and_run(canvas_ptr: int): int = "ext#window_create_and_run"
extern fun ui_state_new(): void = "ext#ui_state_new"

extern fun ui_init {n:int} (argc: int(n), argv: !argv(n)): int = "ext#ui_init"
implement ui_init(argc, argv) = let
  val (bpf | bidx) = minepaint_brush_new()
  val () = minepaint_brush_apply_startup(bpf | bidx)
  val brush = minepaint_brush_stash(bpf | bidx)
  val (cpf | cidx) = canvas_state_create(brush)
  val canvas_state = canvas_stash(cpf | cidx)
  val () = ui_state_new()
  val ret = window_create_and_run(canvas_state)
in
  ret
end
