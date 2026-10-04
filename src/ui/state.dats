#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "sys/libc.dats"

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
  active_drag= int,
  active_group= int,
  sidebar_visible= int,
  active_brush= int,
  brush_scroll= int,
  panel_h= int,
  active_swatch= int,
  pal= ptr
}

extern fun ui_get(): ref(UIWidgetsState) = "ext#ui_get"
implement ui_get() = $UN.cast{ref(UIWidgetsState)}(slot_ui_get())

extern fun ui_state_install(p: ptr): void = "ext#ui_state_install"
implement ui_state_install(p) = slot_ui_set(p)

extern fun ui_pal_ptr(): ptr = "ext#ui_pal_ptr"
implement ui_pal_ptr() = let
  val u = ui_get()
in
  u->pal
end

fn pal_put(base: ptr, i: int, r: float, g: float, b: float): void = let
  val o = i * 3
  val () = $UN.ptr0_set<float>(ptr_add<float>(base, o), r)
  val () = $UN.ptr0_set<float>(ptr_add<float>(base, o + 1), g)
  val () = $UN.ptr0_set<float>(ptr_add<float>(base, o + 2), b)
in () end

extern fun ui_state_new(): ptr = "ext#ui_state_new"
implement ui_state_new() = let
  val extra = g0int2uint_int_size(36) * sizeof<float>
  val sz = sizeof<UIWidgetsState> + extra
  val p = malloc(sz)
  val _ = memset(p, 0, sz)
  val u = $UN.cast{ref(UIWidgetsState)}(p)
  val () = u->pal := add_ptr_bsz(p, sizeof<UIWidgetsState>)
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
  val () = u->active_drag := ~1
  val () = u->active_group := 1
  val () = u->sidebar_visible := 1
  val () = u->active_brush := ~1
  val () = u->brush_scroll := 0
  val () = u->panel_h := 0
  val () = u->active_swatch := ~1
  val base = u->pal
  val () = pal_put(base, 0, 1.00f, 1.00f, 1.00f)
  val () = pal_put(base, 1, 0.73f, 0.73f, 0.73f)
  val () = pal_put(base, 2, 0.30f, 0.30f, 0.30f)
  val () = pal_put(base, 3, 0.00f, 0.00f, 0.00f)
  val () = pal_put(base, 4, 0.95f, 0.20f, 0.20f)
  val () = pal_put(base, 5, 1.00f, 0.55f, 0.00f)
  val () = pal_put(base, 6, 1.00f, 0.90f, 0.10f)
  val () = pal_put(base, 7, 0.20f, 0.85f, 0.30f)
  val () = pal_put(base, 8, 0.10f, 0.85f, 0.85f)
  val () = pal_put(base, 9, 0.20f, 0.45f, 0.95f)
  val () = pal_put(base, 10, 0.65f, 0.25f, 0.85f)
  val () = pal_put(base, 11, 0.55f, 0.35f, 0.20f)
in
  p
end
