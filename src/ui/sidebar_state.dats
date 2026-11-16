#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "sys/fs_io.sats"
staload "ui/state.dats"
staload "ui/slider_id.sats"
staload "brushes/brush_group.sats"
staload "ui/palette.dats"
staload "ui/session.dats"
staload "ui/color.dats"
#include "canvas/canvas_borrow.hats"

extern fun brush_count(g: BrushGroup): int = "ext#brush_count"

fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_min(a: float, b: float): float = if g0float_lt(a, b) then a else b
fn f_max(a: float, b: float): float = if g0float_gt(a, b) then a else b
fn f_clamp(x: float, lo: float, hi: float): float = f_max(lo, f_min(hi, x))

// --- Sidebar Sekme Etiketleri ---
extern fun tab_label(g: BrushGroup): string = "ext#tab_label"
implement tab_label(g) =
  case+ g of
  | GroupDieterle() => "DIET"
  | GroupClassic() => "CLAS"
  | GroupDeevad() => "DEEV"
  | GroupFavorites() => "FAV"
  | GroupRamon() => "RAMO"
  | GroupExperimental() => "EXPR"
  | GroupTanda() => "TAND"
  | GroupKaerhon() => "KAER"

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
fn get_slider_info(i: SliderId): @(string, int, float, float, float) = let
  val u = ui_get()
in
  case+ i of
  | SliderSize() => @("SIZE", 3, ~2.0f, 6.0f, u->val0)
  | SliderOpaque() => @("OPAQUE", 0, 0.0f, 2.0f, u->val1)
  | SliderSharp() => @("SHARP", 4, 0.0f, 1.0f, u->val2)
  | SliderGrain() => @("GRAIN", 18, 0.0f, 25.0f, u->val3)
  | SliderPigment() => @("PIGMENT", 44, 0.0f, 1.0f, u->val4)
  | SliderSmooth() => @("SMOOTH", 31, 0.0f, 10.0f, u->val5)
  | SliderPressure() => @("PRESSURE", 64, ~1.8f, 1.8f, u->val6)
  | SliderTwist() => @("TWIST", 56, 1.0f, 10.0f, u->val7)
end

fn set_slider_val(i: SliderId, v: float): void = let
  val u = ui_get()
in
  case+ i of
  | SliderSize() => u->val0 := v
  | SliderOpaque() => u->val1 := v
  | SliderSharp() => u->val2 := v
  | SliderGrain() => u->val3 := v
  | SliderPigment() => u->val4 := v
  | SliderSmooth() => u->val5 := v
  | SliderPressure() => u->val6 := v
  | SliderTwist() => u->val7 := v
end

extern fun slider_get_label(i: SliderId): string = "ext#slider_get_label"
implement slider_get_label(i) = let
  val @(lbl, _, _, _, _) = get_slider_info(i)
in lbl end

extern fun slider_get_val(i: SliderId): float = "ext#slider_get_val"
implement slider_get_val(i) = let
  val @(_, _, _, _, v) = get_slider_info(i)
in v end

extern fun slider_get_pct(i: SliderId): float = "ext#slider_get_pct"
implement slider_get_pct(i) = let
  val @(_, _, min_v, max_v, v) = get_slider_info(i)
  val raw_pct = f_div(f_sub(v, min_v), f_sub(max_v, min_v))
in
  f_clamp(raw_pct, 0.0f, 1.0f)
end

extern fun slider_update_from_pct(canvas_ptr: int, i: SliderId, pct: float): void = "ext#slider_update_from_pct"
implement slider_update_from_pct(canvas_ptr, i, pct) = let
  val @(_, set_id, min_v, max_v, _) = get_slider_info(i)
  val clamped_pct = f_clamp(pct, 0.0f, 1.0f)
  val new_v = f_add(min_v, f_mul(clamped_pct, f_sub(max_v, min_v)))
  val () = set_slider_val(i, new_v)
  val () = cv_set_brush_setting(canvas_ptr, set_id, new_v)
in () end

// Fırçadan UI kaydırıcılarına ayar kopyalama
extern fun sync_sliders(canvas_ptr: int): void = "ext#sync_sliders"
implement sync_sliders(canvas_ptr) = let
  val u = ui_get()
  val () = u->val0 := cv_get_brush_setting(canvas_ptr, 3)
  val () = u->val1 := cv_get_brush_setting(canvas_ptr, 0)
  val () = u->val2 := cv_get_brush_setting(canvas_ptr, 4)
  val () = u->val3 := cv_get_brush_setting(canvas_ptr, 18)
  val () = u->val4 := cv_get_brush_setting(canvas_ptr, 44)
  val () = u->val5 := cv_get_brush_setting(canvas_ptr, 31)
  val () = u->val6 := cv_get_brush_setting(canvas_ptr, 64)
  val () = u->val7 := cv_get_brush_setting(canvas_ptr, 56)
in () end

// UI kaydırıcılarından fırçaya ayar gönderme
fn push_sliders(canvas_ptr: int): void = let
  fn push_one(i: SliderId): void = let
    val @(_, set_id, lo, hi, v) = get_slider_info(i)
    val c = f_clamp(v, lo, hi)
    val () = set_slider_val(i, c)
  in
    cv_set_brush_setting(canvas_ptr, set_id, c)
  end
  fun loop {k:nat} .<k>. (k: int(k), i: int): void =
    if k > 0 then (
      let val @(ok, s) = slider_id_try(i) in
        if ok then (push_one(s); loop(k - 1, i + 1)) else ()
      end
    ) else ()
in
  loop(8, 0)
end

extern fun commit_swatch(): void = "ext#commit_swatch"
implement commit_swatch() = let
  val u = ui_get()
in
  case+ u->active_swatch of
  | SelNone() => ()
  | SelAt(i) => if i < 12 then let
      val () = pal_set(i, 0, u->cur_r)
      val () = pal_set(i, 1, u->cur_g)
      val () = pal_set(i, 2, u->cur_b)
    in () end else ()
end

extern fun do_reset(canvas_ptr: int): void = "ext#do_reset"
implement do_reset(canvas_ptr) = let
  val u = ui_get()
  val () = cv_apply_startup(canvas_ptr)
  val () = sync_sliders(canvas_ptr)
  val () = u->active_brush := SelNone()
  val () = u->cur_h := 1.0f
  val () = u->cur_s := 0.0f
  val () = u->cur_v := 0.729f
  val @(nr, ng, nb) = hsv_to_rgb(1.0f, 0.0f, 0.729f)
  val () = u->cur_r := nr
  val () = u->cur_g := ng
  val () = u->cur_b := nb
  val () = cv_set_brush_color(canvas_ptr, nr, ng, nb)
  val () = commit_swatch()
in () end

fn apply_saved_brush(canvas_ptr: int): void = let
  val u = ui_get()
  val g = u->active_group
  val n = brush_count(g)
in
  case+ u->active_brush of
  | SelAt(b) when b < n => cv_apply_catalog_brush(canvas_ptr, g, b)
  | SelAt(_) => (u->active_brush := SelNone(); cv_apply_startup(canvas_ptr))
  | SelNone() => (u->active_brush := SelNone(); cv_apply_startup(canvas_ptr))
end

// --- Oturum Yönetimi Entegrasyonu ---
extern fun widgets_save_session(fsio: !FS_IO | ): void = "ext#widgets_save_session"
implement widgets_save_session(fsio | ) = session_save(fsio | )

extern fun widgets_restore_session(fsio: !FS_IO | canvas_ptr: int): void = "ext#widgets_restore_session"
implement widgets_restore_session(fsio | canvas_ptr) = let
  val loaded = session_load(fsio | )
in
  if loaded <= 0 then ()
  else let
    val u = ui_get()
    val () = apply_saved_brush(canvas_ptr)
    val () = push_sliders(canvas_ptr)
    val scroll0 = u->brush_scroll
    val () = if scroll0 < 0 then u->brush_scroll := 0 else ()
    val @(h, s, v) = rgb_to_hsv(u->cur_r, u->cur_g, u->cur_b)
    val () = u->cur_h := h
    val () = u->cur_s := s
    val () = u->cur_v := v
    val () = cv_set_brush_color(canvas_ptr, u->cur_r, u->cur_g, u->cur_b)
  in () end
end
