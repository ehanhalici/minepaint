// src/window/window.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/cast_box.sats"

staload "x11/event.sats"
staload "x11/display_box.sats"
staload "window/app_box.sats"
staload "x11/xevent_box.sats"
staload "x11/attr_box.sats"
staload "x11/visual_box.sats"
staload "gl/glctx_box.sats"
staload "x11/xi2.sats"
staload "gl/glx.dats"
staload "sys/capability.sats"
staload "gl/gl_io.sats"
staload "sys/libc.dats"

typedef X11App = @{
  dpy= MpDisplay,
  win= ulint,
  glc= MpGlCtx,
  cursor= ulint,
  wm_delete= ulint
}

fn view_app(p: ptr): ref(X11App) = ref_of_ptr{X11App}(p)

// Tek sanctioned assume (App): sahipli tutamac C tarafinda bir ptr'dir.
assume MpApp = ptr

fn app_ref(app: !MpApp): ref(X11App) = view_app(app)

fn i2u(i: int): uint = g0int2uint_int_uint(i)

macdef ALLOC_NONE = $extval(int, "AllocNone")
macdef INPUT_OUTPUT = $extval(int, "InputOutput")
macdef XC_CROSSHAIR = $extval(uint, "XC_crosshair")

fn event_mask(): lint =
  $extval(lint, "(ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask | PointerMotionMask | StructureNotifyMask)")

fn create_window_with_hints(
  dpy: MpDisplay, root: ulint, vi: MpVisual, w: int, h: int, title: string
): ulint = let
  val cmap = XCreateColormap(dpy, root, mp_xvi_visual(vi), ALLOC_NONE)
  var swa = @[byte][256]()
  val raw_swa = ptr_forget(addr@(swa))
  val _ = memset(raw_swa, 0, g0int2uint_int_size(256))
  val p_swa = swa_of(raw_swa)
  val () = mp_swa_set(p_swa, cmap, event_mask())
  val win = mp_XCreateWindow(
    dpy, root, 0, 0, i2u(w), i2u(h), 0u,
    mp_xvi_depth(vi), i2u(INPUT_OUTPUT), mp_xvi_visual(vi),
    $extval(ulint, "(CWColormap | CWEventMask)"), p_swa
  )
  var hints = @[byte][256]()
  val raw_hints = ptr_forget(addr@(hints))
  val _ = memset(raw_hints, 0, g0int2uint_int_size(256))
  val p_hints = hints_of(raw_hints)
  val () = mp_hints_set_min(p_hints, 450, 350)
  val () = XSetWMNormalHints(dpy, win, p_hints)
  val () = mp_x_map_window(dpy, win)
  val _ = XStoreName(dpy, win, title)
in win end

fn setup_wm_protocols(dpy: MpDisplay, win: ulint): ulint = let
  val wm = XInternAtom(dpy, "WM_DELETE_WINDOW", 0)
  var proto: ulint = wm
  val _ = XSetWMProtocols(dpy, win, addr@proto, 1)
in wm end

fn init_gl_and_cursor(dpy: MpDisplay, win: ulint, vi: MpVisual): @(MpGlCtx, ulint) = let
  val glc = glXCreateContext(dpy, vi, glctx_none(), GL_TRUE)
in
  if glctx_is_null(glc) != 0 then (glctx_none(), 0ul)
  else let
    val _ = glXMakeCurrent(dpy, win, glc)
    val _ = XFree(visual_ptr(vi))
    val cursor = XCreateFontCursor(dpy, XC_CROSSHAIR)
    val () = mp_x_define_cursor(dpy, win, cursor)
    val _ = xi2_init(dpy)
  in (glc, cursor) end
end

implement app_create(w, h, title) = let
  val dpy = mp_x_open_display()
in
  if dpy_is_null(dpy) != 0 then let
    val () = fprintln!(stderr_ref, "HATA: X11 Display acilamadi!")
  in (None_v() | None_vt()) end
  else let
    val screen = mp_x_default_screen(dpy)
    val root = mp_x_root_window(dpy, screen)
    var att = @[int][5](GLX_RGBA, GLX_DEPTH_SIZE, 16, GLX_DOUBLEBUFFER, 0)
    val vi = glXChooseVisual(dpy, screen, addr@att)
  in
    if visual_is_null(vi) != 0 then let
      val () = fprintln!(stderr_ref, "HATA: Uygun GLX Visual bulunamadi!")
      val () = mp_x_close_display(dpy)
    in (None_v() | None_vt()) end
    else let
      val win = create_window_with_hints(dpy, root, vi, w, h, title)
      val wm = setup_wm_protocols(dpy, win)
      val @(glc, cursor) = init_gl_and_cursor(dpy, win, vi)
    in
      if glctx_is_null(glc) != 0 then let
        val () = fprintln!(stderr_ref, "HATA: GLX Context olusturulamadi!")
        val _ = XFree(visual_ptr(vi))
        val () = mp_x_destroy_window(dpy, win)
        val () = mp_x_close_display(dpy)
      in (None_v() | None_vt()) end
      else let
        val app = malloc(sizeof<X11App>)
        val a = view_app(app)
        val () = a->dpy := dpy
        val () = a->win := win
        val () = a->glc := glc
        val () = a->cursor := cursor
        val () = a->wm_delete := wm
      in (Some_v(cap_mint()) | Some_vt(app)) end
    end
  end
end

implement app_destroy(pf | app) = let
    prval () = cap_burn(pf)
    val a = view_app(app)
    val dpy = a->dpy
    val _ = XFreeCursor(dpy, a->cursor)
    val _ = glXMakeCurrent(dpy, 0ul, glctx_none())
    val () = glXDestroyContext(dpy, a->glc)
    val () = mp_x_destroy_window(dpy, a->win)
    val () = mp_x_close_display(dpy)
  in
    free(app)
  end

implement app_wm_delete(app) = let
  val a = app_ref(app)
in
  a->wm_delete
end

implement app_pending(app) = let
  val a = app_ref(app)
in
  XPending(a->dpy)
end

implement app_next_event(app, ev) = let
  val a = app_ref(app)
  val _ = XNextEvent(a->dpy, ev)
in () end

implement app_swap(pf | app) = let
  val a = view_app(app)
in
  glXSwapBuffers(a->dpy, a->win)
end

implement app_dpy(app) = let
  val a = app_ref(app)
in
  a->dpy
end
