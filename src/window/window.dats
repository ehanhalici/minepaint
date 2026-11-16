// src/window/window.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/buf.sats"

staload "x11/event.sats"
staload "x11/display_box.sats"
staload "window/app_box.sats"
staload "sys/buf.sats"
staload "x11/visual_box.sats"
staload "gl/glctx_box.sats"
staload "x11/x_io.sats"
staload "gl/glx.dats"
staload "sys/capability.sats"
staload "sys/log_io.sats"
staload "gl/gl_io.sats"
staload "sys/libc.dats"

// Sahipli (dogrusal) C kaynaklari: ekran, GLX baglami, GLX gorsel bilgisi. Her biri tek `assume` ile ptr'ye
// muhurlenir; kayit alanlari ham ptr tutar (dogrusal deger kayitta saklanamaz), olusturma/yikim doğrusal
// fonksiyonlardan gecer: hata yollarinda kaynak sizdirmak derleme hatasidir.
assume Display = ptr
assume GlCtx = ptr
assume Vis = ptr

typedef X11App = @{
  dpy= ptr,
  win= ulint,
  glc= ptr,
  cursor= ulint,
  wm_delete= ulint
}

// Sanctioned assume (App): sahipli tutamac tipli kayit referansidir (ham ptr donusumu yok).
// Referans hucresi yikilamaz (GC yok); app_destroy kaynaklari (pencere, baglam, ekran) tuketir, tek 40 baytlik
// kayit surec sonuna kadar yasar.
assume MpApp = ref(X11App)

fn app_ref(app: !MpApp): ref(X11App) = app

fn i2u(i: int): uint = g0int2uint_int_uint(i)

macdef XC_CROSSHAIR = $extval(uint, "XC_crosshair")

fn event_mask(): lint =
  $extval(lint, "(ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask | PointerMotionMask | StructureNotifyMask)")

fn create_window(xio: !X_IO | dpy: !Display, root: ulint, vi: !Vis, w: int, h: int): ulint = let
  val cmap = mp_x_create_colormap(xio | dpy, root, vi)
  val swa = buf_new{KIND_SWA}(256)
  val () = mp_swa_set(swa, cmap, event_mask())
  val win = mp_x_create_window(xio | dpy, root, i2u(w), i2u(h), vi,
    $extval(ulint, "(CWColormap | CWEventMask)"), swa)
  val () = buf_free(swa)
in win end

fn set_size_hints(xio: !X_IO | dpy: !Display, win: ulint): void = let
  val hints = buf_new{KIND_HINTS}(256)
  val () = mp_hints_set_min(hints, 450, 350)
  val () = XSetWMNormalHints(xio | dpy, win, hints)
in buf_free(hints) end

fn create_window_with_hints(xio: !X_IO |
  dpy: !Display, root: ulint, vi: !Vis, w: int, h: int, title: string
): ulint = let
  val win = create_window(xio | dpy, root, vi, w, h)
  val () = set_size_hints(xio | dpy, win)
  val () = mp_x_map_window(xio | dpy, win)
  val _ = XStoreName(xio | dpy, win, title)
in win end

fn setup_wm_protocols(xio: !X_IO | dpy: !Display, win: ulint): ulint = let
  val wm = XInternAtom(xio | dpy, "WM_DELETE_WINDOW", 0)
  var proto: ulint = wm
  val _ = XSetWMProtocols(xio | dpy, win, addr@proto, 1)
in wm end

// Odunc verme: kayit ham ptr tutar (dogrusal deger kayitta saklanamaz). dpy_lend sahipli tutamaci cikarir,
// dpy_unlend ayni ptr'yi kayda geri birakir (kaynak kapanmaz); ikisi birlikte `!Display` odunc almasidir.
fn dpy_lend(a: ref(X11App)): Display = a->dpy
fn dpy_unlend(d: Display): ptr = d

// Claim: X_IO kaniti yalniz ekran gercekten acildiginda uretilir; display_close kaniti tuketir.
fn display_open(): [ok:bool] (option_v(X_IO, ok) | option_vt(Display, ok)) = let
  val v = mp_x_open_display()
in
  if ptr_isnot_null(v) then (Some_v(cap_mint{KIND_X, 0}()) | Some_vt(v))
  else (None_v() | None_vt())
end

fn display_close(xio: X_IO | d: Display): void = let
  val () = mp_x_close_display(xio | d)
  prval () = cap_burn(xio)
in () end

fn vis_choose(d: !Display, screen: int): Option_vt(Vis) = let
  var att = @[int][5](GLX_RGBA, GLX_DEPTH_SIZE, 16, GLX_DOUBLEBUFFER, 0)
  val vi = glXChooseVisual(d, screen, addr@att)
in
  if ptr_isnot_null(vi) then Some_vt(vi) else None_vt()
end

fn vis_free(xio: !X_IO | v: Vis): void = let val _ = XFree(xio | v) in () end

// Claim: GL_IO kaniti yalniz baglam gercekten olusturuldugunda uretilir; glctx_destroy kaniti tuketir.
fn glctx_create(d: !Display, v: !Vis): [ok:bool] (option_v(GL_IO, ok) | option_vt(GlCtx, ok)) = let
  val c = glXCreateContext(d, v, the_null_ptr, GL_TRUE)
in
  if ptr_isnot_null(c) then (Some_v(cap_mint{KIND_GL, 0}()) | Some_vt(c))
  else (None_v() | None_vt())
end

fn glctx_destroy(gio: GL_IO | d: !Display, c: GlCtx): void = let
  val () = glXDestroyContext(d, c)
  prval () = cap_burn(gio)
in () end

fn init_cursor(xio: !X_IO | dpy: !Display, win: ulint): ulint = let
  val cursor = XCreateFontCursor(xio | dpy, XC_CROSSHAIR)
  val () = mp_x_define_cursor(xio | dpy, win, cursor)
  val _ = xi2_init(xio | dpy)
in cursor end

vtypedef AppResult = [ok:bool] (option_v(@(GL_IO, X_IO), ok) | option_vt(MpApp, ok))

fn app_fail(xio: X_IO, d: Display): AppResult = let
  val () = display_close(xio | d)
in (None_v() | None_vt()) end

fn app_fail_ctx(logio: !LOG_IO | xio: X_IO, d: Display, vi: Vis, win: ulint): AppResult = let
  val () = log_error(logio | "HATA: GLX Context olusturulamadi!")
  val () = vis_free(xio | vi)
  val () = mp_x_destroy_window(xio | d, win)
in app_fail(xio, d) end

fn app_finish(xio: X_IO, gio: GL_IO, d: Display, c: GlCtx, vi: Vis, win: ulint, wm: ulint): AppResult = let
  val _ = glXMakeCurrent(d, win, c)
  val () = vis_free(xio | vi)
  val cursor = init_cursor(xio | d, win)
  val app = ref<X11App>(@{ dpy= d, win= win, glc= c, cursor= cursor, wm_delete= wm })
in (Some_v(@(gio, xio)) | Some_vt(app)) end

fn app_with_visual(logio: !LOG_IO | xio: X_IO, d: Display, vi: Vis, root: ulint, w: int, h: int, title: string): AppResult = let
  val win = create_window_with_hints(xio | d, root, vi, w, h, title)
  val wm = setup_wm_protocols(xio | d, win)
  val (pf | r) = glctx_create(d, vi)
in
  case+ r of
  | ~None_vt() => let
      prval None_v() = pf
    in app_fail_ctx(logio | xio, d, vi, win) end
  | ~Some_vt(c) => let
      prval Some_v(gio) = pf
    in app_finish(xio, gio, d, c, vi, win, wm) end
end

fn app_with_display(logio: !LOG_IO | xio: X_IO, d: Display, w: int, h: int, title: string): AppResult = let
  val screen = mp_x_default_screen(d)
  val root = mp_x_root_window(d, screen)
in
  case+ vis_choose(d, screen) of
  | ~None_vt() => let
      val () = log_error(logio | "HATA: Uygun GLX Visual bulunamadi!")
    in app_fail(xio, d) end
  | ~Some_vt(vi) => app_with_visual(logio | xio, d, vi, root, w, h, title)
end

implement app_create(logio | w, h, title) =
  let
    val (pf | r) = display_open()
  in
    case+ r of
    | ~None_vt() => let
        prval None_v() = pf
        val () = log_error(logio | "HATA: X11 Display acilamadi!")
      in (None_v() | None_vt()) end
    | ~Some_vt(d) => let
        prval Some_v(xio) = pf
      in app_with_display(logio | xio, d, w, h, title) end
  end

implement app_destroy(gio, xio | app) = let
  val a = app
  val d: Display = a->dpy
  val c: GlCtx = a->glc
  val _ = XFreeCursor(xio | d, a->cursor)
  val _ = glXReleaseCurrent(d)
  val () = glctx_destroy(gio | d, c)
  val () = mp_x_destroy_window(xio | d, a->win)
  val () = display_close(xio | d)
in () end

implement app_wm_delete(app) = let
  val a = app_ref(app)
in
  a->wm_delete
end

implement app_pending(xio | app) = let
  val d = dpy_lend(app_ref(app))
  val n = XPending(xio | d)
  val _ = dpy_unlend(d)
in n end

implement app_next_event(xio | app, ev) = let
  val d = dpy_lend(app_ref(app))
  val _ = XNextEvent(xio | d, ev)
  val _ = dpy_unlend(d)
in () end

implement app_peek_event(xio | app, ev) = let
  val d = dpy_lend(app_ref(app))
  val _ = XPeekEvent(xio | d, ev)
  val _ = dpy_unlend(d)
in () end

implement app_queued(xio | app, mode) = let
  val d = dpy_lend(app_ref(app))
  val n = XEventsQueued(xio | d, mode)
  val _ = dpy_unlend(d)
in n end

implement app_process_raw(xio | app, ev, now) = let
  val d = dpy_lend(app_ref(app))
  val r = xi2_process_raw_event(xio | d, ev, now)
  val _ = dpy_unlend(d)
in r end

implement app_swap(pf | app) = let
  val a = app_ref(app)
  val d = dpy_lend(a)
  val () = glXSwapBuffers(d, a->win)
  val _ = dpy_unlend(d)
in () end
