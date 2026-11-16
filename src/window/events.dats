#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/buf.sats"
staload "sys/fs_io.sats"
staload "gl/gl_io.sats"
staload "sys/capability.sats"
staload "sys/clock_io.sats"
staload "sys/log_io.sats"
staload "sys/effect_root.dats"
#include "sys/airlock.hats"

staload "x11/event.sats"
staload "sys/buf.sats"
staload "window/app_box.sats"
staload "x11/x_io.sats"
staload "window/input.dats"
staload "gl/gl.dats"
#include "canvas/canvas_borrow.hats"
staload "sys/libc.dats"


extern fun widgets_render(gio: !GL_IO | sx: float, sy: float, sw: float, sh: float): void = "ext#widgets_render"
extern fun widgets_on_mouse_down(mx: float, my: float, btn: int, canvas_ptr: int): int = "ext#widgets_on_mouse_down"
extern fun widgets_on_mouse_move(mx: float, my: float, canvas_ptr: int): int = "ext#widgets_on_mouse_move"
extern fun widgets_on_mouse_up(canvas_ptr: int): void = "ext#widgets_on_mouse_up"
extern fun widgets_is_dragging(): int = "ext#widgets_is_dragging"
extern fun widgets_on_wheel(mx: float, my: float, dy: int): int = "ext#widgets_on_wheel"
extern fun widgets_sidebar_shown(): bool = "ext#widgets_sidebar_shown"
extern fun widgets_on_edge_hover(mx: float, my: float, win_w: float, cur_time: double): void = "ext#widgets_on_edge_hover"
extern fun widgets_try_click_floating_toggle(mx: float, my: float, win_w: float, cur_time: double): int = "ext#widgets_try_click_floating_toggle"
extern fun widgets_render_floating_toggle(gio: !GL_IO | win_w: float, cur_time: double): void = "ext#widgets_render_floating_toggle"
extern fun widgets_restore_session(fsio: !FS_IO | canvas_ptr: int): void = "ext#widgets_restore_session"
extern fun widgets_save_session(fsio: !FS_IO | ): void = "ext#widgets_save_session"


macdef ConfigureNotify = $extval(int, "ConfigureNotify")
macdef ClientMessage = $extval(int, "ClientMessage")
macdef KeyPress = $extval(int, "KeyPress")
macdef KeyRelease = $extval(int, "KeyRelease")
macdef ButtonPress = $extval(int, "ButtonPress")
macdef ButtonRelease = $extval(int, "ButtonRelease")
macdef MotionNotify = $extval(int, "MotionNotify")
macdef GenericEvent = $extval(int, "GenericEvent")
macdef XK_Escape = $extval(ulint, "XK_Escape")
macdef XK_space = $extval(ulint, "XK_space")
macdef Button1Mask = $extval(uint, "Button1Mask")
macdef Button2Mask = $extval(uint, "Button2Mask")
macdef Button3Mask = $extval(uint, "Button3Mask")
macdef QueuedAfterReading = $extval(int, "QueuedAfterReading")

fn i2f(i: int): float = g0int2float_int_float(i)
fn i2d(i: int): double = g0int2float_int_double(i)

datatype AppPhase = PhaseRunning | PhaseQuit
datatype KeyState = KeyUp | KeyDown

typedef AppState = @{
  win_w= int,
  win_h= int,
  sidebar_w= int,
  phase= AppPhase,
  space_key= KeyState,
  current_mouse_btn= MouseBtn
}

fn phase_is_running(p: AppPhase): bool =
  case+ p of
  | PhaseRunning() => true
  | PhaseQuit() => false

fn key_is_down(k: KeyState): bool =
  case+ k of
  | KeyDown() => true
  | KeyUp() => false

// Pan modu: orta tuş veya basılı boşluk (canvas sınırı int bayrak ister)
fn pan_flag_of(btn: MouseBtn, space: KeyState): int =
  if btn_is_middle(btn) || key_is_down(space) then 1 else 0

fn held_button_of_mask(mask: uint): HeldButton =
  if g0uint_land_uint(mask, Button2Mask) != 0U then HeldMiddle()
  else if g0uint_land_uint(mask, Button3Mask) != 0U then HeldRight()
  else if g0uint_land_uint(mask, Button1Mask) != 0U then HeldLeft()
  else HeldNone()

extern fun ulint2lint(x: ulint): lint = "mac#mp_ulint_to_lint"

// Boşluk Tuşu Otomatik Tekrar Kontrolü (Sıfır Heap Tahsisi, Stack Tabanlı)
fn is_space_autorepeat(xio: !X_IO | app: !MpApp, ev: !XEvBuf): int =
  if app_queued(xio | app, QueuedAfterReading) <= 0 then 0
  else let
    val nev = buf_new{KIND_XEV}(256)
    val _ = app_peek_event(xio | app, nev)
    val same =
      (mp_xevent_type(nev) = KeyPress) &&
      (mp_xevent_key_time(nev) = mp_xevent_key_time(ev)) &&
      (mp_xevent_keysym(nev) = XK_space)
    val () = if same then let val _ = app_next_event(xio | app, nev) in () end else ()
    val () = buf_free(nev)
  in
    if same then 1 else 0
  end

fn handle_configure(st: ref(AppState), p_xev: !XEvBuf): void = let
  val () = st->win_w := mp_xevent_config_w(p_xev)
  val () = st->win_h := mp_xevent_config_h(p_xev)
in () end

fn handle_client_message(st: ref(AppState), app: !MpApp, p_xev: !XEvBuf): void = let
  val d0 = mp_xevent_client_data0(p_xev)
  val wm_del = ulint2lint(app_wm_delete(app))
in
  if g0int_eq(d0, wm_del) then st->phase := PhaseQuit() else ()
end

fn handle_key_press(st: ref(AppState), p_xev: !XEvBuf): void = let
  val ks = mp_xevent_keysym(p_xev)
in
  if ks = XK_Escape then st->phase := PhaseQuit()
  else if ks = XK_space then st->space_key := KeyDown()
  else ()
end

fn handle_key_release(xio: !X_IO | st: ref(AppState), app: !MpApp, p_xev: !XEvBuf): void = let
  val ks = mp_xevent_keysym(p_xev)
in
  if ks = XK_space then let
    val is_rep = is_space_autorepeat(xio | app, p_xev)
  in
    if is_rep = 0 then st->space_key := KeyUp() else ()
  end else ()
end

fn handle_wheel_action(
  st: ref(AppState), canvas_ptr: int, bx: int, by: int, dy: int
): void = let
  val s_vis = widgets_sidebar_shown()
  val sidebar_x = st->win_w - st->sidebar_w
in
  if s_vis && (bx >= sidebar_x) then let
    val consumed = widgets_on_wheel(i2f(bx - sidebar_x), i2f(by), dy)
  in
    if consumed <= 0 then cv_on_wheel(canvas_ptr, bx, by, dy) else ()
  end else cv_on_wheel(canvas_ptr, bx, by, dy)
end

fn wheel_direction(btn: MouseBtn): int =
  case+ btn of
  | BtnWheelUp() => ~1
  | BtnWheelDown() => 1
  | BtnNone() => 0
  | BtnLeft() => 0
  | BtnMiddle() => 0
  | BtnRight() => 0

fn btn_is_wheel(btn: MouseBtn): bool =
  case+ btn of
  | BtnWheelUp() => true
  | BtnWheelDown() => true
  | BtnNone() => false
  | BtnLeft() => false
  | BtnMiddle() => false
  | BtnRight() => false

fn press_in_sidebar(st: ref(AppState), canvas_ptr: int, btn: MouseBtn, bx: int, by: int): void = let
  val sidebar_x = st->win_w - st->sidebar_w
in
  if btn_is_left(btn) then let
    val _ = widgets_on_mouse_down(i2f(bx - sidebar_x), i2f(by), mouse_btn_code(btn), canvas_ptr)
  in () end else ()
end

fn floating_toggle_clicked(st: ref(AppState), bx: int, by: int, now: double): bool =
  if widgets_sidebar_shown() then false
  else widgets_try_click_floating_toggle(i2f(bx), i2f(by), i2f(st->win_w), now) > 0

fn press_on_canvas(gio: !GL_IO | st: ref(AppState), canvas_ptr: int, btn: MouseBtn, bx: int, by: int, now: double): void = let
  val press = input_get_pressure(now)
in
  if floating_toggle_clicked(st, bx, by, now) then ()
  else cv_on_mouse_down(gio | canvas_ptr, i2f(bx), i2f(by), mouse_btn_code(btn), pan_flag_of(btn, st->space_key), press, now)
end

fn press_routed(gio: !GL_IO | st: ref(AppState), canvas_ptr: int, btn: MouseBtn, bx: int, by: int, now: double): void = let
  val () = st->current_mouse_btn := btn
  val in_sidebar = (widgets_sidebar_shown()) && (bx >= st->win_w - st->sidebar_w)
in
  if in_sidebar then press_in_sidebar(st, canvas_ptr, btn, bx, by)
  else press_on_canvas(gio | st, canvas_ptr, btn, bx, by, now)
end

fn handle_button_press(gio: !GL_IO, clk: !CLOCK_IO | st: ref(AppState), canvas_ptr: int, p_xev: !XEvBuf): void = let
  val bx = mp_xevent_btn_x(p_xev)
  val by = mp_xevent_btn_y(p_xev)
  val now = get_time_seconds(clk | )
  val raw_btn = mouse_btn_of_code(mp_xevent_btn_button(p_xev))
  val btn = input_remap_button(raw_btn, st->current_mouse_btn, input_stylus_tip(now))
in
  if btn_is_wheel(btn) then handle_wheel_action(st, canvas_ptr, bx, by, wheel_direction(btn))
  else press_routed(gio | st, canvas_ptr, btn, bx, by, now)
end

fn release_stroke_or_drag(gio: !GL_IO | st: ref(AppState), canvas_ptr: int, raw_btn: MouseBtn, bx: int, by: int): void = let
  val cur_btn = st->current_mouse_btn
in
  if widgets_is_dragging() > 0 then widgets_on_mouse_up(canvas_ptr)
  else if input_should_release_stroke(raw_btn, cur_btn) then
    cv_on_mouse_up(gio | canvas_ptr, i2f(bx), i2f(by), mouse_btn_code(cur_btn), pan_flag_of(cur_btn, st->space_key))
  else ()
end

fn handle_button_release(gio: !GL_IO | st: ref(AppState), canvas_ptr: int, p_xev: !XEvBuf): void = let
  val raw_btn = mouse_btn_of_code(mp_xevent_btn_button(p_xev))
in
  if btn_is_wheel(raw_btn) then ()
  else let
    val () = release_stroke_or_drag(gio | st, canvas_ptr, raw_btn, mp_xevent_btn_x(p_xev), mp_xevent_btn_y(p_xev))
  in
    st->current_mouse_btn := input_release_next_button(raw_btn, st->current_mouse_btn)
  end
end

fn motion_drag_widget(st: ref(AppState), canvas_ptr: int, mx: int, my: int): void = let
  val sidebar_x = st->win_w - st->sidebar_w
  val _ = widgets_on_mouse_move(i2f(mx - sidebar_x), i2f(my), canvas_ptr)
in () end

fn motion_on_canvas(gio: !GL_IO | st: ref(AppState), canvas_ptr: int, p_xev: !XEvBuf, mx: int, my: int, now: double): void = let
  val held = held_button_of_mask(mp_xevent_motion_state(p_xev))
  val btn = input_motion_button(held, st->current_mouse_btn)
  val eff_btn = input_remap_button(btn, btn, input_stylus_tip(now))
in
  if btn_is_none(btn) then ()
  else cv_on_mouse_move(gio | canvas_ptr, i2f(mx), i2f(my), mouse_btn_code(eff_btn), pan_flag_of(btn, st->space_key), input_get_pressure(now), now)
end

fn handle_motion_notify(gio: !GL_IO, clk: !CLOCK_IO | st: ref(AppState), canvas_ptr: int, p_xev: !XEvBuf): void = let
  val mx = mp_xevent_motion_x(p_xev)
  val my = mp_xevent_motion_y(p_xev)
  val now = get_time_seconds(clk | )
  val () = widgets_on_edge_hover(i2f(mx), i2f(my), i2f(st->win_w), now)
in
  if widgets_is_dragging() > 0 then motion_drag_widget(st, canvas_ptr, mx, my)
  else motion_on_canvas(gio | st, canvas_ptr, p_xev, mx, my, now)
end

fn canvas_width(st: ref(AppState), sidebar_shown: bool): int =
  if sidebar_shown then (if st->win_w > st->sidebar_w then st->win_w - st->sidebar_w else 1)
  else st->win_w

fn setup_screen_projection(gio: !GL_IO | st: ref(AppState)): void = let
  val () = glViewport(gio | 0, 0, st->win_w, st->win_h)
  val () = glMatrixMode(gio | GL_PROJECTION)
  val () = glLoadIdentity(gio | )
  val () = glOrtho(gio | 0.0, i2d(st->win_w), i2d(st->win_h), 0.0, ~1.0, 1.0)
  val () = glMatrixMode(gio | GL_MODELVIEW)
in glLoadIdentity(gio | ) end

fn render_overlay(gio: !GL_IO | st: ref(AppState), sidebar_shown: bool, cur_time: double): void =
  if sidebar_shown then
    widgets_render(gio | i2f(st->win_w - st->sidebar_w), 0.0f, i2f(st->sidebar_w), i2f(st->win_h))
  else
    widgets_render_floating_toggle(gio | i2f(st->win_w), cur_time)

fn render_frame(gio: !GL_IO, clk: !CLOCK_IO | st: ref(AppState), app: !MpApp, canvas_ptr: int): void = let
  val s_vis = widgets_sidebar_shown()
  val cur_time = get_time_seconds(clk | )
  val () = cv_render(gio | canvas_ptr, canvas_width(st, s_vis), st->win_h)
  val () = setup_screen_projection(gio | st)
  val () = render_overlay(gio | st, s_vis, cur_time)
  val () = app_swap(gio | app)
in sleep_usec(clk | 10000u) end

datatype xev_kind =
  | XevConfigure
  | XevClient
  | XevKeyPress
  | XevKeyRelease
  | XevGeneric
  | XevButtonPress
  | XevButtonRelease
  | XevMotion
  | XevOther

fn xev_kind_of(t: int): xev_kind =
  if t = ConfigureNotify then XevConfigure()
  else if t = ClientMessage then XevClient()
  else if t = KeyPress then XevKeyPress()
  else if t = KeyRelease then XevKeyRelease()
  else if t = GenericEvent then XevGeneric()
  else if t = ButtonPress then XevButtonPress()
  else if t = ButtonRelease then XevButtonRelease()
  else if t = MotionNotify then XevMotion()
  else XevOther()

fn dispatch_xev(gio: !GL_IO, clk: !CLOCK_IO, xio: !X_IO | k: xev_kind, st: ref(AppState), app: !MpApp, p_xev: !XEvBuf, canvas_ptr: int): void =
  case+ k of
  | XevConfigure() => handle_configure(st, p_xev)
  | XevClient() => handle_client_message(st, app, p_xev)
  | XevKeyPress() => handle_key_press(st, p_xev)
  | XevKeyRelease() => handle_key_release(xio | st, app, p_xev)
  | XevGeneric() => let
      val _ = app_process_raw(xio | app, p_xev, get_time_seconds(clk | ))
    in () end
  | XevButtonPress() => handle_button_press(gio, clk | st, canvas_ptr, p_xev)
  | XevButtonRelease() => handle_button_release(gio | st, canvas_ptr, p_xev)
  | XevMotion() => handle_motion_notify(gio, clk | st, canvas_ptr, p_xev)
  | XevOther() => ()

// X'te o ana kadar bekleyen olaylar kadar yineleme: olcu n - i, yakitsiz.
// Bu sirada gelen yeni olaylar sonraki kareye kalir.
fun drain_pending {n:nat}{i:nat | i <= n} .<n - i>. (gio: !GL_IO, clk: !CLOCK_IO, xio: !X_IO | 
  i: int(i), n: int(n), st: ref(AppState), app: !MpApp, p_xev: !XEvBuf, canvas_ptr: int
): void =
  if i < n then let
    val () = app_next_event(xio | app, p_xev)
    val () = dispatch_xev(gio, clk, xio | xev_kind_of(mp_xevent_type(p_xev)), st, app, p_xev, canvas_ptr)
  in
    drain_pending(gio, clk, xio | i + 1, n, st, app, p_xev, canvas_ptr)
  end else ()

// Bir karenin sonucu deger olarak doner (Idris'teki `Either`/sonuc mantigi): dongu degisken bayrak
// okumaz, karar sonuc degerinden verilir.
datatype FrameOutcome = FrameContinue | FrameQuit

// Tek kare: olaylari bosalt, sonra ciz. Sonlanan (total) adim.
fn step_frame(gio: !GL_IO, clk: !CLOCK_IO, xio: !X_IO | st: ref(AppState), app: !MpApp, p_xev: !XEvBuf, canvas_ptr: int): FrameOutcome = let
  val pending = airlock_nat(app_pending(xio | app))
  val () = drain_pending(gio, clk, xio | 0, pending, st, app, p_xev, canvas_ptr)
  val () = render_frame(gio, clk | st, app, canvas_ptr)
in
  if phase_is_running(st->phase) then FrameContinue() else FrameQuit()
end

// Bilincli sonlanmama (Idris `partial`/codata karsiligi): uygulama kullanici kapatana kadar calisir, bu yuzden
// ne metrik ne yakit vardir; tek izinli sonsuz dongu. Efekt `!all` olarak acikca yazilidir (ntm dahil).
// Her yineleme step_frame'in (sonlanan) tamamlanmasiyla ilerler; karar FrameOutcome degerindendir.
fun event_loop(gio: !GL_IO, clk: !CLOCK_IO, xio: !X_IO | st: ref(AppState), app: !MpApp, p_xev: !XEvBuf, canvas_ptr: int):<!all> void =
  case+ step_frame(gio, clk, xio | st, app, p_xev, canvas_ptr) of
  | FrameContinue() => event_loop(gio, clk, xio | st, app, p_xev, canvas_ptr)
  | FrameQuit() => ()

extern fun window_create_and_run(canvas_ptr: int): int = "ext#window_create_and_run"
fn new_app_state(): ref(AppState) =
  ref<AppState>(@{
    win_w= 1000, win_h= 600, sidebar_w= 250,
    phase= PhaseRunning(), space_key= KeyUp(), current_mouse_btn= BtnNone()
  })

// Oturum geri yukle -> olay dongusu -> oturum kaydet; kanitlar cagirandan odunc gelir.
fn run_session(gio: !GL_IO, clk: !CLOCK_IO, xio: !X_IO, fsio: !FS_IO |
  app: !MpApp, p_xev: !XEvBuf, canvas_ptr: int
): void = let
  val p_st = new_app_state()
  val () = widgets_restore_session(fsio | canvas_ptr)
  val () = event_loop(gio, clk, xio | p_st, app, p_xev, canvas_ptr)
in widgets_save_session(fsio | ) end

fn run_app(gio: GL_IO, xio: X_IO, logio: LOG_IO, clk: CLOCK_IO, fsio: FS_IO |
  app: MpApp, canvas_ptr: int
): int = let
  val xev_buf = buf_new{KIND_XEV}(256)
  val () = run_session(gio, clk, xio, fsio | app, xev_buf, canvas_ptr)
  val () = buf_free(xev_buf)
  val () = app_destroy(gio, xio | app)
  val () = env_close(logio, clk, fsio | )
in 0 end

implement window_create_and_run(canvas_ptr) = let
  val (logio, clk, fsio | ()) = env_open()
  val (pfo | opt) = app_create(logio | 1000, 600, "MinePaint")
in
  case+ opt of
  | ~None_vt() => let
      prval None_v() = pfo
      val () = env_close(logio, clk, fsio | )
    in 1 end
  | ~Some_vt(app) => let
      prval Some_v(@(gio, xio)) = pfo
    in run_app(gio, xio, logio, clk, fsio | app, canvas_ptr) end
end
