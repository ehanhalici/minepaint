#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

extern fun minepaint_brush_new(): int = "ext#minepaint_brush_new"
extern fun minepaint_brush_apply_startup(brush: int): void = "ext#minepaint_brush_apply_startup"
extern fun canvas_state_create(brush: int): int = "ext#canvas_state_create"
extern fun window_create_and_run(canvas_ptr: int, ui: ptr): int = "ext#window_create_and_run"
extern fun ui_state_new(): ptr = "ext#ui_state_new"

extern fun ui_init {n:int} (argc: int(n), argv: !argv(n)): int = "ext#ui_init"
implement ui_init(argc, argv) = let
  val brush = minepaint_brush_new()
  val () = minepaint_brush_apply_startup(brush)
  val canvas_state = canvas_state_create(brush)
  val ui = ui_state_new()
  val ret = window_create_and_run(canvas_state, ui)
in
  ret
end
