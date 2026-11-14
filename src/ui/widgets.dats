// src/ui/widgets.dats
// Native ATS2 Implementation of GUI Widgets (Sliders, Color Pickers, Vector Font, Presets, Collapsible Sidebar)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "gl/gl_io.sats"
staload "sys/cast_box.sats"
#include "sys/airlock.hats"

staload "gl/gl.dats"
staload "sys/libc.dats"
staload "sys/io_box.sats"
staload "ui/state.dats"
#include "canvas/canvas_borrow.hats"
staload "brushes/brush_group.sats"
staload "ui/slider_id.sats"
staload "ui/widget_drag.sats"
staload "ui/palette.dats"
staload "ui/color.dats"
staload "ui/draw2d.dats"
staload "ui/font.dats"
staload "ui/sidebar_state.dats"

extern fun brush_group_count(): int = "ext#brush_group_count"
extern fun brush_count(g: BrushGroup): int = "ext#brush_count"
extern fun brush_name(g: BrushGroup, i: int): string = "ext#brush_name"

// Sekme indeksi (0..7) -> fırça grubu; geçersiz indeks için None.
fn select_group_tab(t: int): bool =
  let val @(ok, g) = brush_group_try(t) in
    if ok then let
      val u = ui_get()
      val () = u->active_group := g
      val () = u->brush_scroll := 0
    in true end else false
  end

// --- Sidebar State API Declarations ---
extern fun tab_label(g: BrushGroup): string = "ext#tab_label"
extern fun list_visible(sh: float): int = "ext#list_visible"
extern fun clamp_scroll(scroll: int, count: int, vis: int): int = "ext#clamp_scroll"
extern fun sync_sliders(canvas_ptr: int): void = "ext#sync_sliders"
extern fun do_reset(canvas_ptr: int): void = "ext#do_reset"
extern fun commit_swatch(): void = "ext#commit_swatch"
extern fun slider_update_from_pct(canvas_ptr: int, i: SliderId, pct: float): void = "ext#slider_update_from_pct"
extern fun slider_get_label(i: SliderId): string = "ext#slider_get_label"
extern fun slider_get_val(i: SliderId): float = "ext#slider_get_val"
extern fun slider_get_pct(i: SliderId): float = "ext#slider_get_pct"

fn addr2str(p: ptr): string = cstr_of_ptr(p)

fn format_slider_val(buf: MpText, sz: int, v: float): void = let
  val _ = mp_snprintf_f(buf, g0int2uint_int_size(sz), "%.2f", g0float2float_float_double(v))
in () end

fn f_add(a: float, b: float): float = g0float_add_float(a, b)
fn f_sub(a: float, b: float): float = g0float_sub_float(a, b)
fn f_mul(a: float, b: float): float = g0float_mul_float(a, b)
fn f_div(a: float, b: float): float = g0float_div_float(a, b)
fn f_min(a: float, b: float): float = if g0float_lt(a, b) then a else b
fn f_max(a: float, b: float): float = if g0float_gt(a, b) then a else b
fn f_clamp(x: float, lo: float, hi: float): float = f_max(lo, f_min(hi, x))
fn f_lt(a: float, b: float): bool = g0float_lt(a, b)
fn f_gte(a: float, b: float): bool = g0float_gte(a, b)

fn d_sub(a: double, b: double): double = g0float_sub_double(a, b)
fn d_div(a: double, b: double): double = g0float_div_double(a, b)
fn d_gte(a: double, b: double): bool = g0float_gte_double(a, b)
fn d_lte(a: double, b: double): bool = g0float_lte_double(a, b)
fn d_gt(a: double, b: double): bool = g0float_gt_double(a, b)

fn get_palette_color(i: int): @(float, float, float) = pal_get_color(i)

fn str_len(s: string): int = g0uint2int_size_int(string_length(s))

// --- Widget Status Queries ---
extern fun widgets_is_dragging(): int = "ext#widgets_is_dragging"
implement widgets_is_dragging() = let
  val u = ui_get()
in
  case+ u->active_drag of
  | DragNone() => 0
  | DragHue() => 1
  | DragSv() => 1
  | DragSlider(_) => 1
end

extern fun widgets_on_mouse_up(canvas_ptr: int): void = "ext#widgets_on_mouse_up"
implement widgets_on_mouse_up(canvas_ptr) = let
  val u = ui_get()
in
  u->active_drag := DragNone()
end

// --- Atomic Mouse Dispatch Helpers ---
fn check_collapse_button(mx: float, my: float, sw: float): bool = let
  val in_collapse = (mx >= f_sub(sw, 40.0f)) * (mx <= f_sub(sw, 8.0f)) * (my >= 8.0f) * (my <= 36.0f)
in
  if in_collapse then let
    val u = ui_get()
    val () = u->sidebar := SidebarHidden()
  in true end
  else false
end

fn activate_swatch(i: int, canvas_ptr: int): void = let
  val u = ui_get()
  val @(pr, pg, pb) = get_palette_color(i)
  val @(ph, ps, pv) = rgb_to_hsv(pr, pg, pb)
  val () = u->active_swatch := SelAt(i)
  val () = u->cur_r := pr
  val () = u->cur_g := pg
  val () = u->cur_b := pb
  val () = u->cur_h := ph
  val () = u->cur_s := ps
  val () = u->cur_v := pv
  val () = cv_set_brush_color(canvas_ptr, pr, pg, pb)
in () end

fn check_swatch_click(mx: float, my: float, canvas_ptr: int): bool = let
  fun check_pal {i:nat | i <= 12} .<12 - i>. (i: int(i)): bool =
    if i < 12 then let
      val row = i / 6
      val col = i % 6
      val bx = f_add(75.0f, f_mul(g0int2float(col), 27.0f))
      val by = f_add(55.0f, f_mul(g0int2float(row), 25.0f))
      val hit = (mx >= bx) * (mx <= f_add(bx, 22.0f)) * (my >= by) * (my <= f_add(by, 20.0f))
    in
      if hit then (activate_swatch(i, canvas_ptr); true)
      else check_pal(i + 1)
    end else false
in
  check_pal(0)
end

fn update_hue(mx: float, canvas_ptr: int): void = let
  val u = ui_get()
  val raw_h = f_div(f_sub(mx, 20.0f), 210.0f)
  val h_val = f_clamp(raw_h, 0.0f, 1.0f)
  val () = u->cur_h := h_val
  val @(nr, ng, nb) = hsv_to_rgb(h_val, u->cur_s, u->cur_v)
  val () = u->cur_r := nr
  val () = u->cur_g := ng
  val () = u->cur_b := nb
  val () = cv_set_brush_color(canvas_ptr, nr, ng, nb)
  val () = commit_swatch()
in () end

fn check_hue_bar_click(mx: float, my: float, canvas_ptr: int): bool = let
  val in_hue = (mx >= 20.0f) * (mx <= 230.0f) * (my >= 115.0f) * (my <= 135.0f)
in
  if in_hue then let
    val u = ui_get()
    val () = u->active_drag := DragHue()
    val () = update_hue(mx, canvas_ptr)
  in true end
  else false
end

fn update_sv(mx: float, my: float, canvas_ptr: int): void = let
  val u = ui_get()
  val raw_s = f_div(f_sub(mx, 20.0f), 210.0f)
  val raw_v = f_sub(1.0f, f_div(f_sub(my, 145.0f), 75.0f))
  val s_val = f_clamp(raw_s, 0.0f, 1.0f)
  val v_val = f_clamp(raw_v, 0.0f, 1.0f)
  val () = u->cur_s := s_val
  val () = u->cur_v := v_val
  val @(nr, ng, nb) = hsv_to_rgb(u->cur_h, s_val, v_val)
  val () = u->cur_r := nr
  val () = u->cur_g := ng
  val () = u->cur_b := nb
  val () = cv_set_brush_color(canvas_ptr, nr, ng, nb)
  val () = commit_swatch()
in () end

fn check_sv_box_click(mx: float, my: float, canvas_ptr: int): bool = let
  val in_sv = (mx >= 20.0f) * (mx <= 230.0f) * (my >= 145.0f) * (my <= 220.0f)
in
  if in_sv then let
    val u = ui_get()
    val () = u->active_drag := DragSv()
    val () = update_sv(mx, my, canvas_ptr)
  in true end
  else false
end

fn slider_row_hit(mx: float, my: float, i: int): bool = let
  val sy_pos = f_add(242.0f, f_mul(g0int2float(i), 30.0f))
in
  (mx >= 15.0f) * (mx <= 235.0f) * (my >= f_add(sy_pos, 8.0f)) * (my <= f_add(sy_pos, 28.0f))
end

fn begin_slider_drag(mx: float, canvas_ptr: int, s: SliderId): void = let
  val u = ui_get()
  val () = u->active_drag := DragSlider(s)
  val raw_pct = f_div(f_sub(mx, 20.0f), 210.0f)
in
  slider_update_from_pct(canvas_ptr, s, raw_pct)
end

fn check_slider_click(mx: float, my: float, canvas_ptr: int): bool = let
  fun loop {k:nat} .<k>. (k: int(k), i: int): bool =
    if k > 0 then (
      let val @(ok, s) = slider_id_try(i) in
        if not(ok) then false
        else if slider_row_hit(mx, my, i) then (begin_slider_drag(mx, canvas_ptr, s); true)
        else loop(k - 1, i + 1)
      end
    ) else false
in
  loop(8, 0)
end

fn check_reset_click(mx: float, my: float, canvas_ptr: int): bool = let
  val in_reset = (mx >= 168.0f) * (mx <= 234.0f) * (my >= 492.0f) * (my <= 514.0f)
in
  if in_reset then (do_reset(canvas_ptr); true)
  else false
end

fn check_tab_click(mx: float, my: float): bool = let
  fun loop {t:nat | t <= 8} .<8 - t>. (t: int(t)): bool =
    if t < 8 then let
      val col = t % 4
      val row = t / 4
      val bx = f_add(16.0f, f_mul(g0int2float(col), 54.0f))
      val by = f_add(516.0f, f_mul(g0int2float(row), 26.0f))
      val hit = (mx >= bx) * (mx <= f_add(bx, 50.0f)) * (my >= by) * (my <= f_add(by, 22.0f))
    in
      if hit then select_group_tab(t)
      else loop(t + 1)
    end else false
in
  loop(0)
end

fn check_brush_list_click(mx: float, my: float, canvas_ptr: int): bool = let
  val u = ui_get()
  val ph = g0int2float(u->panel_h)
  val in_list = (mx >= 16.0f) * (mx <= 234.0f) * (my >= 568.0f) * (f_lt(my, f_sub(ph, 8.0f)))
in
  if not(in_list) then false
  else let
    val vis = list_visible(ph)
    val rel = g0float2int_float_int(f_div(f_sub(my, 568.0f), 18.0f))
    val idx = u->brush_scroll + rel
    val n = brush_count(u->active_group)
  in
    if (rel >= 0) * (rel < vis) * (idx >= 0) * (idx < n) then let
      val () = cv_apply_catalog_brush(canvas_ptr, u->active_group, idx)
      val () = sync_sliders(canvas_ptr)
      val () = u->active_brush := SelAt(idx)
    in true end
    else false
  end
end

extern fun widgets_on_mouse_down(mx: float, my: float, btn: int, canvas_ptr: int): int = "ext#widgets_on_mouse_down"
implement widgets_on_mouse_down(mx, my, btn, canvas_ptr) =
  if btn != 1 then 0
  else if check_collapse_button(mx, my, 250.0f) then 1
  else if check_swatch_click(mx, my, canvas_ptr) then 1
  else if check_hue_bar_click(mx, my, canvas_ptr) then 1
  else if check_sv_box_click(mx, my, canvas_ptr) then 1
  else if check_slider_click(mx, my, canvas_ptr) then 1
  else if check_reset_click(mx, my, canvas_ptr) then 1
  else if check_tab_click(mx, my) then 1
  else if check_brush_list_click(mx, my, canvas_ptr) then 1
  else 0

extern fun widgets_on_mouse_move(mx: float, my: float, canvas_ptr: int): int = "ext#widgets_on_mouse_move"
implement widgets_on_mouse_move(mx, my, canvas_ptr) = let
  val u = ui_get()
  val drag = u->active_drag
in
  case+ drag of
  | DragNone() => 0
  | DragHue() => (update_hue(mx, canvas_ptr); 1)
  | DragSv() => (update_sv(mx, my, canvas_ptr); 1)
  | DragSlider(i) => let
      val raw_pct = f_div(f_sub(mx, 20.0f), 210.0f)
      val () = slider_update_from_pct(canvas_ptr, i, raw_pct)
    in 1 end
end

extern fun widgets_on_wheel(mx: float, my: float, dy: int): int = "ext#widgets_on_wheel"
implement widgets_on_wheel(mx, my, dy) = let
  val u = ui_get()
  val sh = g0int2float(u->panel_h)
  val in_win = (mx >= 8.0f) * (mx <= 242.0f) * (my >= 488.0f) * (f_lt(my, sh))
in
  if in_win then let
    val vis = list_visible(sh)
    val n = brush_count(u->active_group)
    val () = u->brush_scroll := clamp_scroll(u->brush_scroll + dy, n, vis)
  in 1 end else 0
end

// --- Rendering Sub-Components (SLAP) ---

fn render_sidebar_background(gio: !GL_IO | sx: float, sy: float, sw: float, sh: float): void = let
  val () = gl_draw_rect(gio | sx, sy, sw, sh, 0.12f, 0.12f, 0.13f, 1.0f)
  val () = gl_draw_rect(gio | sx, sy, 1.0f, sh, 0.22f, 0.22f, 0.25f, 1.0f)
in () end

fn render_header_and_collapse(gio: !GL_IO | sx: float, sw: float): void = let
  val () = glPointSize(gio | 2.0f)
  val () = gl_draw_string(gio | f_add(sx, 20.0f), 20.0f, 1.5f, "MINEPAINT", 0.0f, 0.6f, 1.0f)
  val btn_x = f_sub(f_add(sx, sw), 38.0f)
  val btn_y = 10.0f
  val () = gl_draw_rect(gio | btn_x, btn_y, 28.0f, 24.0f, 0.18f, 0.18f, 0.22f, 1.0f)
  val () = gl_draw_rect_outline(gio | btn_x, btn_y, 28.0f, 24.0f, 0.35f, 0.35f, 0.40f, 1.0f)
  val () = glPointSize(gio | 1.5f)
  val () = gl_draw_string(gio | f_add(btn_x, 5.0f), f_add(btn_y, 5.0f), 1.2f, ">>", 0.80f, 0.80f, 0.90f)
  val () = gl_draw_rect(gio | f_add(sx, 20.0f), 42.0f, f_sub(sw, 40.0f), 1.0f, 0.2f, 0.2f, 0.22f, 1.0f)
in () end

fn render_swatch_outline_active(gio: !GL_IO | bx: float, by: float): void = let
  val t = 2.0f
  val fw = f_add(22.0f, f_mul(t, 2.0f))
  val () = gl_draw_rect(gio | f_sub(bx, t), f_sub(by, t), fw, t, 0.15f, 0.55f, 1.0f, 1.0f)
  val () = gl_draw_rect(gio | f_sub(bx, t), f_add(by, 20.0f), fw, t, 0.15f, 0.55f, 1.0f, 1.0f)
  val () = gl_draw_rect(gio | f_sub(bx, t), by, t, 20.0f, 0.15f, 0.55f, 1.0f, 1.0f)
in
  gl_draw_rect(gio | f_add(bx, 22.0f), by, t, 20.0f, 0.15f, 0.55f, 1.0f, 1.0f)
end

fn render_swatch_outline_idle(gio: !GL_IO | bx: float, by: float): void =
  gl_draw_rect_outline(gio | bx, by, 22.0f, 20.0f, 0.3f, 0.3f, 0.35f, 1.0f)

fn render_palette_swatches(gio: !GL_IO | sx: float): void = let
  val u = ui_get()
  val () = gl_draw_rect(gio | f_add(sx, 20.0f), 55.0f, 45.0f, 45.0f, u->cur_r, u->cur_g, u->cur_b, 1.0f)
  val () = gl_draw_rect_outline(gio | f_add(sx, 20.0f), 55.0f, 45.0f, 45.0f, 0.5f, 0.5f, 0.55f, 1.0f)
  fun loop {i:nat | i <= 12} .<12 - i>. (gio: !GL_IO | i: int(i)): void =
    if i < 12 then let
      val row = i / 6
      val col = i % 6
      val bx = f_add(f_add(sx, 75.0f), f_mul(g0int2float(col), 27.0f))
      val by = f_add(55.0f, f_mul(g0int2float(row), 25.0f))
      val @(pr, pg, pb) = get_palette_color(i)
      val () = gl_draw_rect(gio | bx, by, 22.0f, 20.0f, pr, pg, pb, 1.0f)
      val () =
        if selection_is_at(u->active_swatch, i) then render_swatch_outline_active(gio | bx, by)
        else render_swatch_outline_idle(gio | bx, by)
    in loop(gio | i + 1) end else ()
in
  loop(gio | 0)
end

fn render_hue_bar(gio: !GL_IO | sx: float, bar_w: float): void = let
  val u = ui_get()
  val hue_y = 115.0f
  val hue_h = 16.0f
  val () = glBegin(gio | GL_QUAD_STRIP)
  fun loop {i:nat | i <= 37} .<37 - i>. (gio: !GL_IO | i: int(i)): void =
    if i <= 36 then let
      val h_val = f_div(g0int2float(i), 36.0f)
      val @(hr, hg, hb) = hsv_to_rgb(h_val, 1.0f, 1.0f)
      val vx = f_add(f_add(sx, 20.0f), f_mul(h_val, bar_w))
      val () = glColor3f(gio | hr, hg, hb)
      val () = glVertex2f(gio | vx, hue_y)
      val () = glVertex2f(gio | vx, f_add(hue_y, hue_h))
    in loop(gio | i + 1) end else ()
  val () = loop(gio | 0)
  val () = glEnd(gio | )
  val () = gl_draw_rect_outline(gio | f_add(sx, 20.0f), hue_y, bar_w, hue_h, 0.4f, 0.4f, 0.45f, 1.0f)
  val cursor_x = f_add(f_add(sx, 20.0f), f_mul(u->cur_h, bar_w))
  val () = gl_draw_rect(gio | f_sub(cursor_x, 2.0f), f_sub(hue_y, 2.0f), 4.0f, f_add(hue_h, 4.0f), 1.0f, 1.0f, 1.0f, 1.0f)
in () end

fn render_sv_box(gio: !GL_IO | sx: float, bar_w: float): void = let
  val u = ui_get()
  val sv_y = 145.0f
  val sv_h = 75.0f
  val @(pure_r, pure_g, pure_b) = hsv_to_rgb(u->cur_h, 1.0f, 1.0f)
  val () = glBegin(gio | GL_QUADS)
  val () = (glColor3f(gio | 1.0f, 1.0f, 1.0f); glVertex2f(gio | f_add(sx, 20.0f), sv_y))
  val () = (glColor3f(gio | pure_r, pure_g, pure_b); glVertex2f(gio | f_add(f_add(sx, 20.0f), bar_w), sv_y))
  val () = (glColor3f(gio | 0.0f, 0.0f, 0.0f); glVertex2f(gio | f_add(f_add(sx, 20.0f), bar_w), f_add(sv_y, sv_h)))
  val () = (glColor3f(gio | 0.0f, 0.0f, 0.0f); glVertex2f(gio | f_add(sx, 20.0f), f_add(sv_y, sv_h)))
  val () = glEnd(gio | )
  val () = gl_draw_rect_outline(gio | f_add(sx, 20.0f), sv_y, bar_w, sv_h, 0.4f, 0.4f, 0.45f, 1.0f)
  val cx = f_add(f_add(sx, 20.0f), f_mul(u->cur_s, bar_w))
  val cy = f_add(sv_y, f_mul(f_sub(1.0f, u->cur_v), sv_h))
  val () = gl_draw_circle(gio | cx, cy, 4.0f, 1.0f, 1.0f, 1.0f, 1.0f)
  val () = gl_draw_circle(gio | cx, cy, 3.0f, 0.0f, 0.0f, 0.0f, 1.0f)
  val () = gl_draw_rect(gio | f_add(sx, 20.0f), 235.0f, bar_w, 1.0f, 0.2f, 0.2f, 0.22f, 1.0f)
in () end

fn render_single_slider(gio: !GL_IO | sx: float, sw: float, bar_w: float, i: int, id: SliderId, buf: MpText): void = let
  val sy_pos = f_add(242.0f, f_mul(g0int2float(i), 30.0f))
  val lbl = slider_get_label(id)
  val v = slider_get_val(id)
  val pct = slider_get_pct(id)
  val () = glPointSize(gio | 1.2f)
  val () = gl_draw_string(gio | f_add(sx, 20.0f), sy_pos, 1.0f, lbl, 0.85f, 0.85f, 0.85f)
  val () = format_slider_val(buf, 16, v)
  val () = gl_draw_string(gio | f_sub(f_add(sx, sw), 60.0f), sy_pos, 1.0f, addr2str(text_ptr(buf)), 0.6f, 0.6f, 0.65f)
  val track_y = f_add(sy_pos, 12.0f)
  val () = gl_draw_rect(gio | f_add(sx, 20.0f), track_y, bar_w, 4.0f, 0.18f, 0.18f, 0.20f, 1.0f)
  val () = gl_draw_rect(gio | f_add(sx, 20.0f), track_y, f_mul(pct, bar_w), 4.0f, 0.0f, 0.48f, 0.80f, 1.0f)
  val thumb_x = f_add(f_add(sx, 20.0f), f_mul(pct, bar_w))
  val thumb_y = f_add(track_y, 2.0f)
  val () = gl_draw_circle(gio | thumb_x, thumb_y, 5.0f, 0.9f, 0.9f, 0.95f, 1.0f)
  val () = gl_draw_circle(gio | thumb_x, thumb_y, 3.0f, 0.0f, 0.48f, 0.80f, 1.0f)
in () end

fn render_sliders_section(gio: !GL_IO | sx: float, sw: float, bar_w: float): void = let
  var val_buf = @[byte][16]()
  val p_buf = text_of(addr@(val_buf))
  fun loop {k:nat} .<k>. (gio: !GL_IO | k: int(k), i: int): void =
    if k > 0 then (
      let val @(ok, id) = slider_id_try(i) in
        if ok then (render_single_slider(gio | sx, sw, bar_w, i, id, p_buf); loop(gio | k - 1, i + 1)) else ()
      end
    ) else ()
in
  loop(gio | 8, 0)
end

fn render_brush_panel_bg(gio: !GL_IO | sx: float, sw: float, sh: float): void = let
  val win_x = f_add(sx, 12.0f)
  val win_y = 488.0f
  val win_w = f_sub(sw, 24.0f)
  val win_h = f_sub(sh, f_add(win_y, 8.0f))
  val () = gl_draw_rect(gio | win_x, win_y, win_w, win_h, 0.10f, 0.10f, 0.11f, 1.0f)
  val () = gl_draw_rect_outline(gio | win_x, win_y, win_w, win_h, 0.28f, 0.28f, 0.32f, 1.0f)
  val () = glPointSize(gio | 1.5f)
  val () = gl_draw_string(gio | f_add(sx, 20.0f), 496.0f, 1.1f, "FIRCALAR", 0.65f, 0.65f, 0.70f)
  val rx = f_add(sx, 168.0f)
  val ry = 492.0f
  val () = gl_draw_rect(gio | rx, ry, 66.0f, 22.0f, 0.18f, 0.18f, 0.20f, 1.0f)
  val () = gl_draw_rect_outline(gio | rx, ry, 66.0f, 22.0f, 0.30f, 0.30f, 0.35f, 1.0f)
  val () = gl_draw_string(gio | f_add(rx, 14.0f), f_add(ry, 5.0f), 1.0f, "RESET", 0.90f, 0.90f, 0.95f)
in () end

fn render_brush_tab(gio: !GL_IO | sx: float, t: int, g: BrushGroup): void = let
  val u = ui_get()
  val col = t % 4
  val row = t / 4
  val bx = f_add(sx, f_add(16.0f, f_mul(g0int2float(col), 54.0f)))
  val by = f_add(516.0f, f_mul(g0int2float(row), 26.0f))
  val on = brush_group_to_int(u->active_group) = t
  val label = tab_label(g)
  val txt_w = f_mul(g0int2float(str_len(label)), 7.0f)
  val tx = f_add(bx, f_div(f_sub(50.0f, txt_w), 2.0f))
  val () = if on then gl_draw_rect(gio | bx, by, 50.0f, 22.0f, 0.0f, 0.48f, 0.80f, 1.0f)
           else gl_draw_rect(gio | bx, by, 50.0f, 22.0f, 0.18f, 0.18f, 0.20f, 1.0f)
  val () = if on then gl_draw_rect_outline(gio | bx, by, 50.0f, 22.0f, 0.3f, 0.7f, 1.0f, 1.0f)
           else gl_draw_rect_outline(gio | bx, by, 50.0f, 22.0f, 0.30f, 0.30f, 0.35f, 1.0f)
  val () = glPointSize(gio | 1.3f)
  val () = if on then gl_draw_string(gio | tx, f_add(by, 6.0f), 1.0f, label, 1.0f, 1.0f, 1.0f)
           else gl_draw_string(gio | tx, f_add(by, 6.0f), 1.0f, label, 0.70f, 0.70f, 0.75f)
in () end

fn render_brush_tabs(gio: !GL_IO | sx: float): void = let
  fun loop {k:nat} .<k>. (gio: !GL_IO | k: int(k), t: int): void =
    if k > 0 then (
      let val @(ok, g) = brush_group_try(t) in
        if ok then (render_brush_tab(gio | sx, t, g); loop(gio | k - 1, t + 1)) else ()
      end
    ) else ()
in
  loop(gio | 8, 0)
end

fn render_brush_list(gio: !GL_IO | sx: float, sh: float): void = let
  val u = ui_get()
  val nbrush = brush_count(u->active_group)
  val vis = list_visible(sh)
  val [m_vis:int] vis_ix = airlock_nat(vis)
  fun loop {row:nat | row <= m_vis} .<m_vis - row>. (gio: !GL_IO | row: int(row)): void =
    if row < vis_ix then let
      val i = u->brush_scroll + row
    in
      if i < nbrush then let
        val y = f_add(568.0f, f_mul(g0int2float(row), 18.0f))
        val bx = f_add(sx, 16.0f)
        val on = selection_is_at(u->active_brush, i)
        val () = if on then gl_draw_rect(gio | bx, y, 218.0f, 16.0f, 0.0f, 0.48f, 0.80f, 1.0f) else ()
        val () = glPointSize(gio | 1.2f)
        val name = brush_name(u->active_group, i)
        val () = if on then gl_draw_string(gio | f_add(bx, 4.0f), f_add(y, 3.0f), 1.0f, name, 1.0f, 1.0f, 1.0f)
                 else gl_draw_string(gio | f_add(bx, 4.0f), f_add(y, 3.0f), 1.0f, name, 0.82f, 0.82f, 0.86f)
      in loop(gio | row + 1) end else ()
    end else ()
in
  loop(gio | 0)
end

// --- Main Sidebar Render Entrypoint (SLAP Pipeline) ---
extern fun widgets_render(gio: !GL_IO | sx: float, sy: float, sw: float, sh: float): void = "ext#widgets_render"
implement widgets_render(gio | sx, sy, sw, sh) = let
  val u = ui_get()
  val () = u->panel_h := g0float2int_float_int(sh)
  val () = u->brush_scroll := clamp_scroll(u->brush_scroll, brush_count(u->active_group), list_visible(sh))
  val () = glDisable(gio | GL_DEPTH_TEST)
  val () = glDisable(gio | GL_TEXTURE_2D)
  val () = glEnable(gio | GL_BLEND)
  val () = glBlendFunc(gio | GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  val bar_w = f_sub(sw, 40.0f)

  val () = render_sidebar_background(gio | sx, sy, sw, sh)
  val () = render_header_and_collapse(gio | sx, sw)
  val () = render_palette_swatches(gio | sx)
  val () = render_hue_bar(gio | sx, bar_w)
  val () = render_sv_box(gio | sx, bar_w)
  val () = render_sliders_section(gio | sx, sw, bar_w)
  val () = render_brush_panel_bg(gio | sx, sw, sh)
  val () = render_brush_tabs(gio | sx)
  val () = render_brush_list(gio | sx, sh)
in () end

// --- Sidebar Toggle & Floating State ---
fn sidebar_is_shown(m: SidebarMode): bool =
  case+ m of
  | SidebarShown() => true
  | SidebarHidden() => false

extern fun widgets_sidebar_shown(): bool = "ext#widgets_sidebar_shown"
implement widgets_sidebar_shown() = let
  val u = ui_get()
in
  sidebar_is_shown(u->sidebar)
end

extern fun widgets_on_edge_hover(mx: float, my: float, win_w: float, cur_time: double): void = "ext#widgets_on_edge_hover"
implement widgets_on_edge_hover(mx, my, win_w, cur_time) = let
  val u = ui_get()
in
  if not(sidebar_is_shown(u->sidebar)) then let
    val near_edge = f_gte(mx, f_sub(win_w, 25.0f))
    val near_btn = (mx >= f_sub(win_w, 45.0f)) * (my >= 8.0f) * (my <= 42.0f)
  in
    if (near_edge || near_btn) then
      u->edge_hover_time := cur_time
  end
end

extern fun widgets_try_click_floating_toggle(mx: float, my: float, win_w: float, cur_time: double): int = "ext#widgets_try_click_floating_toggle"
implement widgets_try_click_floating_toggle(mx, my, win_w, cur_time) = let
  val u = ui_get()
in
  if not(sidebar_is_shown(u->sidebar)) then let
    val dt = d_sub(cur_time, u->edge_hover_time)
    val is_active = d_gte(dt, 0.0) && d_lte(dt, 1.0)
  in
    if is_active then let
      val hit = (mx >= f_sub(win_w, 42.0f)) * (mx <= f_sub(win_w, 8.0f)) * (my >= 10.0f) * (my <= 40.0f)
    in
      if hit then (u->sidebar := SidebarShown(); 1)
      else 0
    end else 0
  end else 0
end

extern fun widgets_render_floating_toggle(gio: !GL_IO | win_w: float, cur_time: double): void = "ext#widgets_render_floating_toggle"
implement widgets_render_floating_toggle(gio | win_w, cur_time) = let
  val u = ui_get()
in
  if not(sidebar_is_shown(u->sidebar)) then let
    val dt = d_sub(cur_time, u->edge_hover_time)
    val is_active = d_gte(dt, 0.0) && d_lte(dt, 1.0)
  in
    if is_active then let
      val alpha_d = if d_gt(dt, 0.7) then d_div(d_sub(1.0, dt), 0.3) else 1.0
      val fa = g0float2float_double_float(alpha_d)
      val bx = f_sub(win_w, 42.0f)
      val by = 10.0f
      val bw = 34.0f
      val bh = 30.0f
      val () = glDisable(gio | GL_DEPTH_TEST)
      val () = glDisable(gio | GL_TEXTURE_2D)
      val () = glEnable(gio | GL_BLEND)
      val () = glBlendFunc(gio | GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      val () = gl_draw_rect(gio | bx, by, bw, bh, 0.12f, 0.12f, 0.15f, f_mul(0.85f, fa))
      val () = gl_draw_rect_outline(gio | bx, by, bw, bh, 0.0f, 0.55f, 0.95f, f_mul(0.95f, fa))
      val () = glPointSize(gio | 2.0f)
      val () = gl_draw_string(gio | f_add(bx, 9.0f), f_add(by, 8.0f), 1.3f, "<<", 0.3f, 0.8f, 1.0f)
    in () end
  end
end
