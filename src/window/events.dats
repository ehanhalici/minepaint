#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "x11/event.sats"
staload "x11/xi2.sats"
staload "window/input.dats"
staload "gl/gl.dats"
staload "sys/libc.dats"

extern fun canvas_render(p: int, canvas_w: int, canvas_h: int): void = "ext#canvas_render"
extern fun canvas_on_wheel(p: int, mx: int, my: int, dy: int): void = "ext#canvas_on_wheel"
extern fun canvas_on_mouse_down(p: int, mx: float, my: float, btn: int, is_pan: int, pressure: float): void = "ext#canvas_on_mouse_down"
extern fun canvas_on_mouse_move(p: int, mx: float, my: float, btn: int, is_pan: int, pressure: float): void = "ext#canvas_on_mouse_move"
extern fun canvas_on_mouse_up(p: int, mx: float, my: float, btn: int, is_pan: int): void = "ext#canvas_on_mouse_up"

extern fun widgets_render(sx: float, sy: float, sw: float, sh: float): void = "ext#widgets_render"
extern fun widgets_on_mouse_down(mx: float, my: float, btn: int, canvas_ptr: int): int = "ext#widgets_on_mouse_down"
extern fun widgets_on_mouse_move(mx: float, my: float, canvas_ptr: int): int = "ext#widgets_on_mouse_move"
extern fun widgets_on_mouse_up(canvas_ptr: int): void = "ext#widgets_on_mouse_up"
extern fun widgets_is_dragging(): int = "ext#widgets_is_dragging"
extern fun widgets_on_wheel(mx: float, my: float, dy: int): int = "ext#widgets_on_wheel"
extern fun widgets_get_sidebar_visible(): int = "ext#widgets_get_sidebar_visible"
extern fun widgets_on_edge_hover(mx: float, my: float, win_w: float, cur_time: double): void = "ext#widgets_on_edge_hover"
extern fun widgets_try_click_floating_toggle(mx: float, my: float, win_w: float, cur_time: double): int = "ext#widgets_try_click_floating_toggle"
extern fun widgets_render_floating_toggle(win_w: float, cur_time: double): void = "ext#widgets_render_floating_toggle"
extern fun widgets_restore_session(canvas_ptr: int): void = "ext#widgets_restore_session"
extern fun widgets_save_session(): void = "ext#widgets_save_session"

extern fun app_create(w: int, h: int, title: string): ptr = "ext#app_create"
extern fun app_destroy(app: ptr): void = "ext#app_destroy"
extern fun app_wm_delete(app: ptr): ulint = "ext#app_wm_delete"
extern fun app_pending(app: ptr): int = "ext#app_pending"
extern fun app_next_event(app: ptr, ev: ptr): void = "ext#app_next_event"
extern fun app_swap(app: ptr): void = "ext#app_swap"
extern fun app_dpy(app: ptr): ptr = "ext#app_dpy"

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

typedef AppState = @{
  win_w= int,
  win_h= int,
  sidebar_w= int,
  running= int,
  is_space_pressed= int,
  current_mouse_btn= int
}

extern castfn ptr2appstate(p: ptr): ref(AppState)
extern castfn ulint2lint(x: ulint): lint = "mac#"
extern castfn addr2ptr(p: ptr): ptr = "mac#"

// Boşluk Tuşu Otomatik Tekrar Kontrolü (Sıfır Heap Tahsisi, Stack Tabanlı)
fn is_space_autorepeat(dpy: ptr, ev: ptr): int =
  if XEventsQueued(dpy, QueuedAfterReading) <= 0 then 0
  else let
    var nev: @[byte][256]
    val nev_p = addr2ptr(addr@(nev))
    val _ = XPeekEvent(dpy, nev_p)
    val same =
      (mp_xevent_type(nev_p) = KeyPress) &&
      (mp_xevent_key_time(nev_p) = mp_xevent_key_time(ev)) &&
      (mp_xevent_keysym(nev_p) = XK_space)
    val () = if same then let val _ = XNextEvent(dpy, nev_p) in () end else ()
  in
    if same then 1 else 0
  end

fn handle_configure(p_st: ptr, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val () = st->win_w := mp_xevent_config_w(p_xev)
  val () = st->win_h := mp_xevent_config_h(p_xev)
in () end

fn handle_client_message(p_st: ptr, app: ptr, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val d0 = mp_xevent_client_data0(p_xev)
  val wm_del = ulint2lint(app_wm_delete(app))
in
  if g0int_eq(d0, wm_del) then st->running := 0 else ()
end

fn handle_key_press(p_st: ptr, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val ks = mp_xevent_keysym(p_xev)
in
  if ks = XK_Escape then st->running := 0
  else if ks = XK_space then st->is_space_pressed := 1
  else ()
end

fn handle_key_release(p_st: ptr, app: ptr, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val ks = mp_xevent_keysym(p_xev)
in
  if ks = XK_space then let
    val is_rep = is_space_autorepeat(app_dpy(app), p_xev)
  in
    if is_rep = 0 then st->is_space_pressed := 0 else ()
  end else ()
end

fn handle_wheel_action(
  st: ref(AppState), canvas_ptr: int, bx: int, by: int, dy: int
): void = let
  val s_vis = widgets_get_sidebar_visible()
  val sidebar_x = st->win_w - st->sidebar_w
in
  if (s_vis > 0) && (bx >= sidebar_x) then let
    val consumed = widgets_on_wheel(i2f(bx - sidebar_x), i2f(by), dy)
  in
    if consumed <= 0 then canvas_on_wheel(canvas_ptr, bx, by, dy) else ()
  end else canvas_on_wheel(canvas_ptr, bx, by, dy)
end

fn handle_button_press(p_st: ptr, canvas_ptr: int, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val bx = mp_xevent_btn_x(p_xev)
  val by = mp_xevent_btn_y(p_xev)
  val raw_btn = mp_xevent_btn_button(p_xev)
  val now = get_time_seconds()
  val is_eraser = input_is_eraser_active(now)
  val btn = input_remap_button(raw_btn, st->current_mouse_btn, is_eraser)
  val press = input_get_pressure(now)
in
  if (btn = 4) || (btn = 5) then
    handle_wheel_action(st, canvas_ptr, bx, by, if btn = 4 then ~1 else 1)
  else let
    val () = st->current_mouse_btn := btn
    val s_vis = widgets_get_sidebar_visible()
    val sidebar_x = st->win_w - st->sidebar_w
  in
    if s_vis > 0 && bx >= sidebar_x then (
      if btn = 1 then let
        val _ = widgets_on_mouse_down(i2f(bx - sidebar_x), i2f(by), btn, canvas_ptr)
      in () end else ()
    ) else let
      val is_pan = if btn = 2 || st->is_space_pressed > 0 then 1 else 0
      val clicked_toggle: int =
        if s_vis <= 0 then widgets_try_click_floating_toggle(i2f(bx), i2f(by), i2f(st->win_w), now)
        else 0
    in
      if g0int_lte(clicked_toggle, 0) then
        canvas_on_mouse_down(canvas_ptr, i2f(bx), i2f(by), btn, is_pan, press)
      else ()
    end
  end
end

fn handle_button_release(p_st: ptr, canvas_ptr: int, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val bx = mp_xevent_btn_x(p_xev)
  val by = mp_xevent_btn_y(p_xev)
  val raw_btn = mp_xevent_btn_button(p_xev)
  val cur_btn = st->current_mouse_btn
in
  if raw_btn != 4 && raw_btn != 5 then let
    val () =
      if widgets_is_dragging() > 0 then
        widgets_on_mouse_up(canvas_ptr)
      else if input_should_release_stroke(raw_btn, cur_btn) then let
        val is_pan = if cur_btn = 2 || st->is_space_pressed > 0 then 1 else 0
      in
        canvas_on_mouse_up(canvas_ptr, i2f(bx), i2f(by), cur_btn, is_pan)
      end else ()
    val () = st->current_mouse_btn := input_release_next_button(raw_btn, cur_btn)
  in () end else ()
end

fn handle_motion_notify(p_st: ptr, canvas_ptr: int, p_xev: ptr): void = let
  val st = ptr2appstate(p_st)
  val mx = mp_xevent_motion_x(p_xev)
  val my = mp_xevent_motion_y(p_xev)
  val cur_time = get_time_seconds()
  val () = widgets_on_edge_hover(i2f(mx), i2f(my), i2f(st->win_w), cur_time)
in
  if widgets_is_dragging() > 0 then let
    val sidebar_x = st->win_w - st->sidebar_w
    val _ = widgets_on_mouse_move(i2f(mx - sidebar_x), i2f(my), canvas_ptr)
  in () end
  else let
    val mask = mp_xevent_motion_state(p_xev)
    val has_b1 = (g0uint_land_uint(mask, Button1Mask) != 0U)
    val has_b2 = (g0uint_land_uint(mask, Button2Mask) != 0U)
    val has_b3 = (g0uint_land_uint(mask, Button3Mask) != 0U)
    val btn = input_motion_button(has_b1, has_b2, has_b3, st->current_mouse_btn)
  in
    if btn != 0 then let
      val is_pan = if btn = 2 || st->is_space_pressed > 0 then 1 else 0
      val is_eraser = input_is_eraser_active(cur_time)
      val eff_btn = input_remap_button(btn, btn, is_eraser)
      val press = input_get_pressure(cur_time)
    in
      canvas_on_mouse_move(canvas_ptr, i2f(mx), i2f(my), eff_btn, is_pan, press)
    end else ()
  end
end

fn render_frame(p_st: ptr, app: ptr, canvas_ptr: int): void = let
  val st = ptr2appstate(p_st)
  val s_vis = widgets_get_sidebar_visible()
  val cur_time = get_time_seconds()
  val canvas_w =
    if s_vis > 0 then (if st->win_w > st->sidebar_w then st->win_w - st->sidebar_w else 1)
    else st->win_w
  val () = canvas_render(canvas_ptr, canvas_w, st->win_h)
  val () = glViewport(0, 0, st->win_w, st->win_h)
  val () = glMatrixMode(GL_PROJECTION)
  val () = glLoadIdentity()
  val () = glOrtho(0.0, i2d(st->win_w), i2d(st->win_h), 0.0, ~1.0, 1.0)
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glLoadIdentity()
  val () =
    if s_vis > 0 then
      widgets_render(i2f(st->win_w - st->sidebar_w), 0.0f, i2f(st->sidebar_w), i2f(st->win_h))
    else
      widgets_render_floating_toggle(i2f(st->win_w), cur_time)
  val () = app_swap(app)
  val _ = usleep(10000u)
in () end

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

fn dispatch_xev(k: xev_kind, p_st: ptr, app: ptr, p_xev: ptr, canvas_ptr: int): void =
  case+ k of
  | XevConfigure() => handle_configure(p_st, p_xev)
  | XevClient() => handle_client_message(p_st, app, p_xev)
  | XevKeyPress() => handle_key_press(p_st, p_xev)
  | XevKeyRelease() => handle_key_release(p_st, app, p_xev)
  | XevGeneric() => let
      val _ = xi2_process_raw_event(app_dpy(app), p_xev)
    in () end
  | XevButtonPress() => handle_button_press(p_st, canvas_ptr, p_xev)
  | XevButtonRelease() => handle_button_release(p_st, canvas_ptr, p_xev)
  | XevMotion() => handle_motion_notify(p_st, canvas_ptr, p_xev)
  | XevOther() => ()

fun event_loop(p_st: ptr, app: ptr, p_xev: ptr, canvas_ptr: int): void = let
  val st = ptr2appstate(p_st)
in
  if st->running > 0 then let
    fun drain(): void =
      if app_pending(app) > 0 then let
        val () = app_next_event(app, p_xev)
        val () = dispatch_xev(xev_kind_of(mp_xevent_type(p_xev)), p_st, app, p_xev, canvas_ptr)
      in
        drain()
      end else ()
    val () = drain()
    val () = render_frame(p_st, app, canvas_ptr)
  in
    event_loop(p_st, app, p_xev, canvas_ptr)
  end else ()
end

extern fun window_create_and_run(canvas_ptr: int): int = "ext#window_create_and_run"
implement window_create_and_run(canvas_ptr) = let
  val app = app_create(1000, 600, "MinePaint")
in
  if app = the_null_ptr then 1
  else let
    var xev_buf: @[byte][256]
    val p_xev = addr2ptr(addr@(xev_buf))
    var st: AppState
    val () = st.win_w := 1000
    val () = st.win_h := 600
    val () = st.sidebar_w := 250
    val () = st.running := 1
    val () = st.is_space_pressed := 0
    val () = st.current_mouse_btn := 0
    val p_st = addr@(st)
    val () = widgets_restore_session(canvas_ptr)
    val () = event_loop(p_st, app, p_xev, canvas_ptr)
    val () = widgets_save_session()
    val () = app_destroy(app)
  in
    0
  end
end
