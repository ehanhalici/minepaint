#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "ui/state.dats"
staload "brushes/brush_group.sats"
staload "ui/palette.dats"
staload "ui/session.dats"
staload "ui/color.dats"

extern fun canvas_set_brush_setting(p: int, id: int, v: float): void = "ext#canvas_set_brush_setting"
extern fun canvas_set_brush_color(p: int, r: float, g: float, b: float): void = "ext#canvas_set_brush_color"
extern fun canvas_apply_startup(p: int): void = "ext#canvas_apply_startup"
extern fun canvas_apply_catalog_brush(p: int, g: BrushGroup, i: int): void = "ext#canvas_apply_catalog_brush"
extern fun canvas_get_brush_setting(p: int, id: int): float = "ext#canvas_get_brush_setting"
extern fun brush_count(g: BrushGroup): int = "ext#brush_count"

fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_min(a: float, b: float): float = if g0float_lt(a, b) then a else b
fn f_max(a: float, b: float): float = if g0float_gt(a, b) then a else b
fn f_clamp(x: float, lo: float, hi: float): float = f_max(lo, f_min(hi, x))

// --- Sidebar Sekme Etiketleri ---
extern fun tab_label(i: int): string = "ext#tab_label"
implement tab_label(i) =
  case+ i of
  | 0 => "DIET"
  | 1 => "CLAS"
  | 2 => "DEEV"
  | 3 => "FAV"
  | 4 => "RAMO"
  | 5 => "EXPR"
  | 6 => "TAND"
  | _ => "KAER"

// --- Kaydırma Listesi Boyutu ve Kısıtlama ---
extern fun list_visible(sh: float): int = "ext#list_visible"
implement list_visible(sh) = let
  val space = f_sub(sh, 578.0f)
  val n = g0float2int_float_int(f_div(space, 18.0f))
in
  if n < 1 then 1 else n
end

extern fun clamp_scroll(scroll: int, count: int, vis: int): int = "ext#clamp_scroll"
implement clamp_scroll(scroll, count, vis) = let
  val maxs = if count > vis then count - vis else 0
in
  if scroll < 0 then 0 else if scroll > maxs then maxs else scroll
end

// --- Fırça Ayar Kaydırıcıları Bilgisi ---
fn get_slider_info(i: int): @(string, int, float, float, float) = let
  val u = ui_get()
in
  case+ i of
  | 0 => @("SIZE", 3, ~2.0f, 6.0f, u->val0)
  | 1 => @("OPAQUE", 0, 0.0f, 2.0f, u->val1)
  | 2 => @("SHARP", 4, 0.0f, 1.0f, u->val2)
  | 3 => @("GRAIN", 18, 0.0f, 25.0f, u->val3)
  | 4 => @("PIGMENT", 44, 0.0f, 1.0f, u->val4)
  | 5 => @("SMOOTH", 31, 0.0f, 10.0f, u->val5)
  | 6 => @("PRESSURE", 64, ~1.8f, 1.8f, u->val6)
  | 7 => @("TWIST", 56, 1.0f, 10.0f, u->val7)
  | _ => @("SIZE", 3, ~2.0f, 6.0f, u->val0)
end

fn set_slider_val(i: int, v: float): void = let
  val u = ui_get()
in
  case+ i of
  | 0 => u->val0 := v
  | 1 => u->val1 := v
  | 2 => u->val2 := v
  | 3 => u->val3 := v
  | 4 => u->val4 := v
  | 5 => u->val5 := v
  | 6 => u->val6 := v
  | _ => u->val7 := v
end

extern fun slider_get_label(i: int): string = "ext#slider_get_label"
implement slider_get_label(i) = let
  val @(lbl, _, _, _, _) = get_slider_info(i)
in lbl end

extern fun slider_get_val(i: int): float = "ext#slider_get_val"
implement slider_get_val(i) = let
  val @(_, _, _, _, v) = get_slider_info(i)
in v end

extern fun slider_get_pct(i: int): float = "ext#slider_get_pct"
implement slider_get_pct(i) = let
  val @(_, _, min_v, max_v, v) = get_slider_info(i)
  val raw_pct = f_div(f_sub(v, min_v), f_sub(max_v, min_v))
in
  f_clamp(raw_pct, 0.0f, 1.0f)
end

extern fun slider_update_from_pct(canvas_ptr: int, i: int, pct: float): void = "ext#slider_update_from_pct"
implement slider_update_from_pct(canvas_ptr, i, pct) = let
  val @(_, set_id, min_v, max_v, _) = get_slider_info(i)
  val clamped_pct = f_clamp(pct, 0.0f, 1.0f)
  val new_v = f_add(min_v, f_mul(clamped_pct, f_sub(max_v, min_v)))
  val () = set_slider_val(i, new_v)
  val () = canvas_set_brush_setting(canvas_ptr, set_id, new_v)
in () end

// Fırçadan UI kaydırıcılarına ayar kopyalama
extern fun sync_sliders(canvas_ptr: int): void = "ext#sync_sliders"
implement sync_sliders(canvas_ptr) = let
  val u = ui_get()
  val () = u->val0 := canvas_get_brush_setting(canvas_ptr, 3)
  val () = u->val1 := canvas_get_brush_setting(canvas_ptr, 0)
  val () = u->val2 := canvas_get_brush_setting(canvas_ptr, 4)
  val () = u->val3 := canvas_get_brush_setting(canvas_ptr, 18)
  val () = u->val4 := canvas_get_brush_setting(canvas_ptr, 44)
  val () = u->val5 := canvas_get_brush_setting(canvas_ptr, 31)
  val () = u->val6 := canvas_get_brush_setting(canvas_ptr, 64)
  val () = u->val7 := canvas_get_brush_setting(canvas_ptr, 56)
in () end

// UI kaydırıcılarından fırçaya ayar gönderme
fn push_sliders(canvas_ptr: int): void = let
  fun loop(i: int): void =
    if i < 8 then let
      val @(_, set_id, lo, hi, v) = get_slider_info(i)
      val c = f_clamp(v, lo, hi)
      val () = set_slider_val(i, c)
      val () = canvas_set_brush_setting(canvas_ptr, set_id, c)
    in loop(i + 1) end else ()
in
  loop(0)
end

extern fun commit_swatch(): void = "ext#commit_swatch"
implement commit_swatch() = let
  val u = ui_get()
  val i = u->active_swatch
in
  if (i >= 0) * (i < 12) then let
    val () = pal_set(i, 0, u->cur_r)
    val () = pal_set(i, 1, u->cur_g)
    val () = pal_set(i, 2, u->cur_b)
  in () end else ()
end

extern fun do_reset(canvas_ptr: int): void = "ext#do_reset"
implement do_reset(canvas_ptr) = let
  val u = ui_get()
  val () = canvas_apply_startup(canvas_ptr)
  val () = sync_sliders(canvas_ptr)
  val () = u->active_brush := ~1
  val () = u->cur_h := 1.0f
  val () = u->cur_s := 0.0f
  val () = u->cur_v := 0.729f
  val @(nr, ng, nb) = hsv_to_rgb(1.0f, 0.0f, 0.729f)
  val () = u->cur_r := nr
  val () = u->cur_g := ng
  val () = u->cur_b := nb
  val () = canvas_set_brush_color(canvas_ptr, nr, ng, nb)
  val () = commit_swatch()
in () end

fn apply_saved_brush(canvas_ptr: int): void = let
  val u = ui_get()
  val g = u->active_group
  val n = brush_count(g)
  val b = u->active_brush
in
  if (b >= 0) * (b < n) then
    canvas_apply_catalog_brush(canvas_ptr, g, b)
  else let
    val () = u->active_brush := ~1
  in
    canvas_apply_startup(canvas_ptr)
  end
end

// --- Oturum Yönetimi Entegrasyonu ---
extern fun widgets_save_session(): void = "ext#widgets_save_session"
implement widgets_save_session() = session_save()

extern fun widgets_restore_session(canvas_ptr: int): void = "ext#widgets_restore_session"
implement widgets_restore_session(canvas_ptr) = let
  val loaded = session_load()
in
  if loaded <= 0 then ()
  else let
    val u = ui_get()
    val () = apply_saved_brush(canvas_ptr)
    val () = push_sliders(canvas_ptr)
    val scroll0 = u->brush_scroll
    val () = if scroll0 < 0 then u->brush_scroll := 0 else ()
    val sw = u->active_swatch
    val sw2 = if sw < ~1 then ~1 else if sw > 11 then ~1 else sw
    val () = u->active_swatch := sw2
    val @(h, s, v) = rgb_to_hsv(u->cur_r, u->cur_g, u->cur_b)
    val () = u->cur_h := h
    val () = u->cur_s := s
    val () = u->cur_v := v
    val () = canvas_set_brush_color(canvas_ptr, u->cur_r, u->cur_g, u->cur_b)
  in () end
end
