#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "sys/libc.dats"
staload "brushes/brush_group.sats"
staload "ui/widget_drag.sats"

extern fun slot_ui_get(): ptr = "ext#slot_ui_get"
extern fun slot_ui_set(p: ptr): void = "ext#slot_ui_set"

typedef UIWidgetsState = @{
  edge_hover_time= double,
  cur_r= float,
  cur_g= float,
  cur_b= float,
  cur_h= float,
  cur_s= float,
  cur_v= float,
  val0= float,
  val1= float,
  val2= float,
  val3= float,
  val4= float,
  val5= float,
  val6= float,
  val7= float,
  active_drag= WidgetDrag,
  active_group= BrushGroup,
  sidebar_visible= int,
  active_brush= int,
  brush_scroll= int,
  panel_h= int,
  active_swatch= int,
  pal= arrayref(float, 36)
}

extern castfn ptr2uistate(p: ptr): ref(UIWidgetsState)

extern fun ui_get(): ref(UIWidgetsState) = "ext#ui_get"
implement ui_get() = ptr2uistate(slot_ui_get())

extern fun ui_state_install(p: ptr): void = "ext#ui_state_install"
implement ui_state_install(p) = slot_ui_set(p)

fn pal_init_put(p: arrayref(float, 36), i: int, r: float, g: float, b: float): void = let
  val o = g1ofg0(i * 3)
in
  if (o >= 0) * (o + 2 < 36) then {
    val () = p[o] := r
    val () = p[o + 1] := g
    val () = p[o + 2] := b
  } else ()
end

fn init_palette_colors(p: arrayref(float, 36)): void = {
  val () = pal_init_put(p, 0, 1.00f, 1.00f, 1.00f)
  val () = pal_init_put(p, 1, 0.73f, 0.73f, 0.73f)
  val () = pal_init_put(p, 2, 0.30f, 0.30f, 0.30f)
  val () = pal_init_put(p, 3, 0.00f, 0.00f, 0.00f)
  val () = pal_init_put(p, 4, 0.95f, 0.20f, 0.20f)
  val () = pal_init_put(p, 5, 1.00f, 0.55f, 0.00f)
  val () = pal_init_put(p, 6, 1.00f, 0.90f, 0.10f)
  val () = pal_init_put(p, 7, 0.20f, 0.85f, 0.30f)
  val () = pal_init_put(p, 8, 0.10f, 0.85f, 0.85f)
  val () = pal_init_put(p, 9, 0.20f, 0.45f, 0.95f)
  val () = pal_init_put(p, 10, 0.65f, 0.25f, 0.85f)
  val () = pal_init_put(p, 11, 0.55f, 0.35f, 0.20f)
}

extern fun ui_state_new(): ptr = "ext#ui_state_new"
implement ui_state_new() = let
  val pal_arr = arrayref_make_elt<float>(i2sz(36), 0.0f)
  val () = init_palette_colors(pal_arr)
  val sz = sizeof<UIWidgetsState>
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val _ = memset(p, 0, sz)
  val u = ptr2uistate(p)
  val () = u->edge_hover_time := 0.0
  val () = u->cur_r := 0.73f
  val () = u->cur_g := 0.73f
  val () = u->cur_b := 0.73f
  val () = u->cur_h := 0.0f
  val () = u->cur_s := 0.0f
  val () = u->cur_v := 0.73f
  val () = u->val0 := 1.2f
  val () = u->val1 := 1.0f
  val () = u->val2 := 0.1f
  val () = u->val3 := 0.0f
  val () = u->val4 := 0.0f
  val () = u->val5 := 3.0f
  val () = u->val6 := 0.0f
  val () = u->val7 := 1.0f
  val () = u->active_drag := DragNone()
  val () = u->active_group := GroupClassic()
  val () = u->sidebar_visible := 1
  val () = u->active_brush := ~1
  val () = u->brush_scroll := 0
  val () = u->panel_h := 0
  val () = u->active_swatch := ~1
  val () = u->pal := pal_arr
in
  p
end
