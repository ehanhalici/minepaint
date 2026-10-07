#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
#include "x11/staloadall.hats"
staload "x11/event.sats"
staload "x11/xi2.sats"
staload "gl/glx.dats"
staload "sys/libc.dats"

typedef X11App = @{
  dpy= ptr,
  win= ulint,
  glc= ptr,
  cursor= ulint,
  wm_delete= ulint
}

fn app_ref(app: ptr): ref(X11App) = $UN.cast{ref(X11App)}(app)

fn i2u(i: int): uint = g0int2uint_int_uint(i)

fn x_default_screen(p: ptr): int = let
  val dpy = $UN.castvwtp1{Display_ptr1}(p)
  val s = XDefaultScreen(dpy)
  val _ = $UN.castvwtp0{ptr}(dpy)
in s end

fn x_root(p: ptr, screen: int): ulint = let
  val dpy = $UN.castvwtp1{Display_ptr1}(p)
  val w = XRootWindow(dpy, screen)
  val _ = $UN.castvwtp0{ptr}(dpy)
in $UN.cast{ulint}(w) end

fn x_map(p: ptr, win: ulint): void = let
  val dpy = $UN.castvwtp1{Display_ptr1}(p)
  val () = XMapWindow(dpy, $UN.cast{Window}(win))
  val _ = $UN.castvwtp0{ptr}(dpy)
in () end

fn x_define_cursor(p: ptr, win: ulint, cursor: ulint): void = let
  val dpy = $UN.castvwtp1{Display_ptr1}(p)
  val () = XDefineCursor(dpy, $UN.cast{Window}(win), $UN.cast{Cursor}(cursor))
  val _ = $UN.castvwtp0{ptr}(dpy)
in () end

fn x_destroy(p: ptr, win: ulint): void = let
  val dpy = $UN.castvwtp1{Display_ptr1}(p)
  val () = XDestroyWindow(dpy, $UN.cast{Window}(win))
  val _ = $UN.castvwtp0{ptr}(dpy)
in () end

fn x_close(p: ptr): void = let
  val dpy = $UN.castvwtp1{Display_ptr1}(p)
in
  XCloseDisplay(dpy)
end

fn event_mask(): lint =
  $extval(lint, "(ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask | PointerMotionMask | StructureNotifyMask)")

extern fun app_create(w: int, h: int, title: string): ptr = "ext#app_create"
implement app_create(w, h, title) = let
  val dpy0 = XOpenDisplay(stropt_none())
  val dpy = $UN.castvwtp0{ptr}(dpy0)
in
  if dpy = the_null_ptr then let
    val () = fprintln!(stderr_ref, "HATA: X11 Display açılamadı!")
  in the_null_ptr end
  else let
    val screen = x_default_screen(dpy)
    val root = x_root(dpy, screen)
    var att = @[int][5](GLX_RGBA, GLX_DEPTH_SIZE, 16, GLX_DOUBLEBUFFER, 0)
    val vi = glXChooseVisual(dpy, screen, addr@att)
  in
    if vi = the_null_ptr then let
      val () = fprintln!(stderr_ref, "HATA: Uygun GLX Visual bulunamadı!")
      val () = x_close(dpy)
    in the_null_ptr end
    else let
      val cmap = XCreateColormap(dpy, root, mp_xvi_visual(vi), AllocNone)
      val swa = malloc(g0int2uint_int_size(mp_swa_sizeof()))
      val _ = memset(swa, 0, g0int2uint_int_size(mp_swa_sizeof()))
      val () = mp_swa_set(swa, cmap, event_mask())
      val win = mp_XCreateWindow(
        dpy, root, 0, 0, i2u(w), i2u(h), 0u,
        mp_xvi_depth(vi), i2u(InputOutput), mp_xvi_visual(vi),
        $extval(ulint, "(CWColormap | CWEventMask)"), swa
      )
      val () = free(swa)
      val hints = malloc(g0int2uint_int_size(mp_hints_sizeof()))
      val _ = memset(hints, 0, g0int2uint_int_size(mp_hints_sizeof()))
      val () = mp_hints_set_min(hints, 450, 350)
      val () = XSetWMNormalHints(dpy, win, hints)
      val () = free(hints)
      val () = x_map(dpy, win)
      val _ = XStoreName(dpy, win, title)
      val wm = XInternAtom(dpy, "WM_DELETE_WINDOW", 0)
      var proto: ulint = wm
      val _ = XSetWMProtocols(dpy, win, addr@proto, 1)
      val glc = glXCreateContext(dpy, vi, the_null_ptr, GL_TRUE)
    in
      if glc = the_null_ptr then let
        val () = fprintln!(stderr_ref, "HATA: GLX Context oluşturulamadı!")
        val _ = XFree(vi)
        val () = x_destroy(dpy, win)
        val () = x_close(dpy)
      in the_null_ptr end
      else let
        val _ = glXMakeCurrent(dpy, win, glc)
        val _ = XFree(vi)
        val cursor = XCreateFontCursor(dpy, $extval(uint, "XC_crosshair"))
        val () = x_define_cursor(dpy, win, cursor)
        val _ = xi2_init(dpy)
        val app = malloc(sizeof<X11App>)
        val a = $UN.cast{ref(X11App)}(app)
        val () = a->dpy := dpy
        val () = a->win := win
        val () = a->glc := glc
        val () = a->cursor := cursor
        val () = a->wm_delete := wm
      in app end
    end
  end
end

extern fun app_destroy(app: ptr): void = "ext#app_destroy"
implement app_destroy(app) =
  if app = the_null_ptr then ()
  else let
    val a = $UN.cast{ref(X11App)}(app)
    val dpy = a->dpy
    val _ = XFreeCursor(dpy, a->cursor)
    val _ = glXMakeCurrent(dpy, $UN.cast{ulint}(0), the_null_ptr)
    val () = glXDestroyContext(dpy, a->glc)
    val () = x_destroy(dpy, a->win)
    val () = x_close(dpy)
  in
    free(app)
  end

extern fun app_wm_delete(app: ptr): ulint = "ext#app_wm_delete"
implement app_wm_delete(app) = let
  val a = app_ref(app)
in
  a->wm_delete
end

extern fun app_pending(app: ptr): int = "ext#app_pending"
implement app_pending(app) = let
  val a = app_ref(app)
in
  XPending(a->dpy)
end

extern fun app_next_event(app: ptr, ev: ptr): void = "ext#app_next_event"
implement app_next_event(app, ev) = let
  val a = app_ref(app)
  val _ = XNextEvent(a->dpy, ev)
in () end

extern fun app_swap(app: ptr): void = "ext#app_swap"
implement app_swap(app) = let
  val a = $UN.cast{ref(X11App)}(app)
in
  glXSwapBuffers(a->dpy, a->win)
end

extern fun app_dpy(app: ptr): ptr = "ext#app_dpy"
implement app_dpy(app) = let
  val a = app_ref(app)
in
  a->dpy
end
