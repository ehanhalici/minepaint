// src/ui/window.dats
// Native ATS2 Implementation of X11 Window Management, Event Loop & UI Routing
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

%{^
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/cursorfont.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
    Display *dpy;
    Window win;
    GLXContext glc;
    Cursor cursor;
    Atom wmDelete;
    int init_w;
    int init_h;
} X11AppContext;

typedef struct {
    int win_w;
    int win_h;
    int sidebar_w;
    int running;
    int is_space_pressed;
    int current_mouse_btn;
} AppState;

static X11AppContext* x11_app_create(int w, int h, const char* title) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "HATA: X11 Display açılamadı!\n");
        return NULL;
    }

    int default_screen = DefaultScreen(dpy);
    Window root = RootWindow(dpy, default_screen);

    GLint att[] = {
        GLX_RGBA,
        GLX_DEPTH_SIZE, 16,
        GLX_DOUBLEBUFFER,
        None
    };

    XVisualInfo *vi = glXChooseVisual(dpy, default_screen, att);
    if (!vi) {
        fprintf(stderr, "HATA: Uygun GLX Visual bulunamadı!\n");
        XCloseDisplay(dpy);
        return NULL;
    }

    Colormap cmap = XCreateColormap(dpy, root, vi->visual, AllocNone);

    XSetWindowAttributes swa;
    swa.colormap = cmap;
    swa.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask |
                     ButtonPressMask | ButtonReleaseMask |
                     PointerMotionMask | StructureNotifyMask;

    Window win = XCreateWindow(
        dpy, root, 0, 0, w, h, 0,
        vi->depth, InputOutput, vi->visual,
        CWColormap | CWEventMask, &swa
    );

    XSizeHints hints;
    hints.flags = PMinSize;
    hints.min_width = 450;
    hints.min_height = 350;
    XSetWMNormalHints(dpy, win, &hints);

    XMapWindow(dpy, win);
    XStoreName(dpy, win, title);

    Atom wmDelete = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(dpy, win, &wmDelete, 1);

    GLXContext glc = glXCreateContext(dpy, vi, NULL, GL_TRUE);
    if (!glc) {
        fprintf(stderr, "HATA: GLX Context oluşturulamadı!\n");
        XDestroyWindow(dpy, win);
        XCloseDisplay(dpy);
        return NULL;
    }
    glXMakeCurrent(dpy, win, glc);

    Cursor cursor = XCreateFontCursor(dpy, XC_crosshair);
    XDefineCursor(dpy, win, cursor);

    X11AppContext* app = (X11AppContext*)malloc(sizeof(X11AppContext));
    app->dpy = dpy;
    app->win = win;
    app->glc = glc;
    app->cursor = cursor;
    app->wmDelete = wmDelete;
    app->init_w = w;
    app->init_h = h;
    return app;
}

static void x11_app_destroy(X11AppContext* app) {
    if (!app) return;
    XFreeCursor(app->dpy, app->cursor);
    glXMakeCurrent(app->dpy, None, NULL);
    glXDestroyContext(app->dpy, app->glc);
    XDestroyWindow(app->dpy, app->win);
    XCloseDisplay(app->dpy);
    free(app);
}

static inline int x11_xpending(X11AppContext* app) { return XPending(app->dpy); }
static inline void x11_next_event(X11AppContext* app, XEvent* xev) { XNextEvent(app->dpy, xev); }
static inline void x11_swap_buffers(X11AppContext* app) { glXSwapBuffers(app->dpy, app->win); }

static inline XEvent* xevent_alloc(void) { return (XEvent*)malloc(sizeof(XEvent)); }
static inline void xevent_free(XEvent* e) { free(e); }

static inline int xevent_get_type(XEvent* e) { return e->type; }
static inline int xevent_get_config_w(XEvent* e) { return e->xconfigure.width; }
static inline int xevent_get_config_h(XEvent* e) { return e->xconfigure.height; }
static inline long xevent_get_client_data0(XEvent* e) { return (long)e->xclient.data.l[0]; }
static inline long x11_get_wm_delete(X11AppContext* app) { return (long)app->wmDelete; }
static inline long xevent_get_keysym(XEvent* e) { return (long)XLookupKeysym(&e->xkey, 0); }
static inline int xevent_get_btn_x(XEvent* e) { return e->xbutton.x; }
static inline int xevent_get_btn_y(XEvent* e) { return e->xbutton.y; }
static inline int xevent_get_btn_button(XEvent* e) { return e->xbutton.button; }
static inline int xevent_get_motion_x(XEvent* e) { return e->xmotion.x; }
static inline int xevent_get_motion_y(XEvent* e) { return e->xmotion.y; }
static inline unsigned int xevent_get_motion_state(XEvent* e) { return (unsigned int)e->xmotion.state; }

static inline int x11_is_space_autorepeat(X11AppContext* app, XEvent* xev) {
    if (XEventsQueued(app->dpy, QueuedAfterReading)) {
        XEvent nev;
        XPeekEvent(app->dpy, &nev);
        if (nev.type == KeyPress && nev.xkey.time == xev->xkey.time &&
            XLookupKeysym(&nev.xkey, 0) == XK_space) {
            XNextEvent(app->dpy, &nev);
            return 1;
        }
    }
    return 0;
}

static inline void x11_usleep(int usec) { usleep(usec); }
static inline double x11_get_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
}
%}

// Canvas ve Widget FFI İmzaları
extern fun canvas_render(p: ptr, canvas_w: int, canvas_h: int): void = "ext#canvas_render"
extern fun canvas_on_wheel(p: ptr, mx: int, my: int, dy: int): void = "ext#canvas_on_wheel"
extern fun canvas_on_mouse_down(p: ptr, mx: int, my: int, btn: int, is_pan: int): void = "ext#canvas_on_mouse_down"
extern fun canvas_on_mouse_move(p: ptr, mx: int, my: int, btn: int, is_pan: int): void = "ext#canvas_on_mouse_move"
extern fun canvas_on_mouse_up(p: ptr, mx: int, my: int, btn: int, is_pan: int): void = "ext#canvas_on_mouse_up"

extern fun widgets_render(sx: float, sy: float, sw: float, sh: float): void = "ext#widgets_render"
extern fun widgets_on_mouse_down(mx: float, my: float, btn: int, canvas_ptr: ptr): int = "ext#widgets_on_mouse_down"
extern fun widgets_on_mouse_move(mx: float, my: float, canvas_ptr: ptr): int = "ext#widgets_on_mouse_move"
extern fun widgets_on_mouse_up(canvas_ptr: ptr): void = "ext#widgets_on_mouse_up"
extern fun widgets_is_dragging(): int = "ext#widgets_is_dragging"

extern fun widgets_get_sidebar_visible(): int = "ext#widgets_get_sidebar_visible"
extern fun widgets_set_sidebar_visible(v: int): void = "ext#widgets_set_sidebar_visible"
extern fun widgets_on_edge_hover(mx: float, my: float, win_w: float, cur_time: double): void = "ext#widgets_on_edge_hover"
extern fun widgets_try_click_floating_toggle(mx: float, my: float, win_w: float, cur_time: double): int = "ext#widgets_try_click_floating_toggle"
extern fun widgets_render_floating_toggle(win_w: float, cur_time: double): void = "ext#widgets_render_floating_toggle"

// OpenGL Sabitleri ve Fonksiyonları
macdef GL_PROJECTION = $extval(int, "GL_PROJECTION")
macdef GL_MODELVIEW = $extval(int, "GL_MODELVIEW")

extern fun glViewport(x: int, y: int, w: int, h: int): void = "mac#"
extern fun glMatrixMode(mode: int): void = "mac#"
extern fun glLoadIdentity(): void = "mac#"
extern fun glOrtho(l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#"

// X11 / GLX FFI İmzaları
extern fun x11_app_create(w: int, h: int, title: string): ptr = "mac#"
extern fun x11_app_destroy(app: ptr): void = "mac#"
extern fun x11_xpending(app: ptr): int = "mac#"
extern fun x11_next_event(app: ptr, xev: ptr): void = "mac#"
extern fun x11_swap_buffers(app: ptr): void = "mac#"
extern fun x11_is_space_autorepeat(app: ptr, xev: ptr): int = "mac#"
extern fun x11_get_wm_delete(app: ptr): lint = "mac#"
extern fun x11_usleep(usec: int): void = "mac#"
extern fun x11_get_time(): double = "mac#"

extern fun xevent_alloc(): ptr = "mac#"
extern fun xevent_free(p: ptr): void = "mac#"

extern fun xevent_get_type(e: ptr): int = "mac#"
extern fun xevent_get_config_w(e: ptr): int = "mac#"
extern fun xevent_get_config_h(e: ptr): int = "mac#"
extern fun xevent_get_client_data0(e: ptr): lint = "mac#"
extern fun xevent_get_keysym(e: ptr): lint = "mac#"
extern fun xevent_get_btn_x(e: ptr): int = "mac#"
extern fun xevent_get_btn_y(e: ptr): int = "mac#"
extern fun xevent_get_btn_button(e: ptr): int = "mac#"
extern fun xevent_get_motion_x(e: ptr): int = "mac#"
extern fun xevent_get_motion_y(e: ptr): int = "mac#"
extern fun xevent_get_motion_state(e: ptr): uint = "mac#"

macdef ConfigureNotify = $extval(int, "ConfigureNotify")
macdef ClientMessage = $extval(int, "ClientMessage")
macdef KeyPress = $extval(int, "KeyPress")
macdef KeyRelease = $extval(int, "KeyRelease")
macdef ButtonPress = $extval(int, "ButtonPress")
macdef ButtonRelease = $extval(int, "ButtonRelease")
macdef MotionNotify = $extval(int, "MotionNotify")

macdef XK_Escape = $extval(lint, "XK_Escape")
macdef XK_space = $extval(lint, "XK_space")

macdef Button1Mask = $extval(uint, "Button1Mask")
macdef Button2Mask = $extval(uint, "Button2Mask")
macdef Button3Mask = $extval(uint, "Button3Mask")

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

// --- X11 Olay İşleyicileri (Pür ATS2) ---

fn handle_configure(p_st: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val () = st->win_w := xevent_get_config_w(p_xev)
  val () = st->win_h := xevent_get_config_h(p_xev)
in () end

fn handle_client_message(p_st: ptr, app: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val d0 = xevent_get_client_data0(p_xev)
  val wm_del = x11_get_wm_delete(app)
in
  if d0 = wm_del then st->running := 0 else ()
end

fn handle_key_press(p_st: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val ks = xevent_get_keysym(p_xev)
in
  if ks = XK_Escape then st->running := 0
  else if ks = XK_space then st->is_space_pressed := 1
  else ()
end

fn handle_key_release(p_st: ptr, app: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val ks = xevent_get_keysym(p_xev)
in
  if ks = XK_space then let
    val is_rep = x11_is_space_autorepeat(app, p_xev)
  in
    if is_rep = 0 then st->is_space_pressed := 0 else ()
  end else ()
end

fn handle_button_press(p_st: ptr, canvas_ptr: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val bx = xevent_get_btn_x(p_xev)
  val by = xevent_get_btn_y(p_xev)
  val btn = xevent_get_btn_button(p_xev)
in
  if btn = 4 then canvas_on_wheel(canvas_ptr, bx, by, ~1)
  else if btn = 5 then canvas_on_wheel(canvas_ptr, bx, by, 1)
  else let
    val () = st->current_mouse_btn := btn
    val s_vis = widgets_get_sidebar_visible()
  in
    if s_vis > 0 then let
      val sidebar_x = st->win_w - st->sidebar_w
    in
      if bx >= sidebar_x then
        (if btn = 1 then let
          val _ = widgets_on_mouse_down(i2f(bx - sidebar_x), i2f(by), btn, canvas_ptr)
        in () end else ())
      else let
        val is_pan = if btn = 2 || st->is_space_pressed > 0 then 1 else 0
      in
        canvas_on_mouse_down(canvas_ptr, bx, by, btn, is_pan)
      end
    end else let
      // Sidebar gizli: Önce sağ üstteki "<<" yüzen düğme tıklandı mı kontrol et
      val cur_time = x11_get_time()
      val clicked_toggle = widgets_try_click_floating_toggle(i2f(bx), i2f(by), i2f(st->win_w), cur_time)
    in
      if clicked_toggle = 0 then let
        val is_pan = if btn = 2 || st->is_space_pressed > 0 then 1 else 0
      in
        canvas_on_mouse_down(canvas_ptr, bx, by, btn, is_pan)
      end else ()
    end
  end
end

fn handle_button_release(p_st: ptr, canvas_ptr: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val bx = xevent_get_btn_x(p_xev)
  val by = xevent_get_btn_y(p_xev)
  val btn = xevent_get_btn_button(p_xev)
in
  if btn != 4 && btn != 5 then let
    val () =
      if widgets_is_dragging() > 0 then
        widgets_on_mouse_up(canvas_ptr)
      else let
        val is_pan = if btn = 2 || st->is_space_pressed > 0 then 1 else 0
      in
        canvas_on_mouse_up(canvas_ptr, bx, by, btn, is_pan)
      end
    val () = st->current_mouse_btn := 0
  in () end else ()
end

fn handle_motion_notify(p_st: ptr, canvas_ptr: ptr, p_xev: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val mx = xevent_get_motion_x(p_xev)
  val my = xevent_get_motion_y(p_xev)
  val cur_time = x11_get_time()
  val () = widgets_on_edge_hover(i2f(mx), i2f(my), i2f(st->win_w), cur_time)
in
  if widgets_is_dragging() > 0 then let
    val sidebar_x = st->win_w - st->sidebar_w
    val _ = widgets_on_mouse_move(i2f(mx - sidebar_x), i2f(my), canvas_ptr)
  in () end
  else let
    var btn: int = st->current_mouse_btn
    val () = if btn = 0 then let
      val mask = xevent_get_motion_state(p_xev)
    in
      if g0uint_land_uint(mask, Button1Mask) != 0U then btn := 1
      else if g0uint_land_uint(mask, Button2Mask) != 0U then btn := 2
      else if g0uint_land_uint(mask, Button3Mask) != 0U then btn := 3
      else ()
    end else ()
  in
    if btn != 0 then let
      val is_pan = if btn = 2 || st->is_space_pressed > 0 then 1 else 0
    in
      canvas_on_mouse_move(canvas_ptr, mx, my, btn, is_pan)
    end else ()
  end
end

// --- Çizim ve Kare Render (Pür ATS2) ---

fn render_frame(p_st: ptr, app: ptr, canvas_ptr: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
  val s_vis = widgets_get_sidebar_visible()
  val cur_time = x11_get_time()
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

  val () = x11_swap_buffers(app)
  val () = x11_usleep(10000)
in () end

// --- Ana Olay Döngüsü (Pür ATS2) ---

fun event_loop(p_st: ptr, app: ptr, p_xev: ptr, canvas_ptr: ptr): void = let
  val st = $UN.cast{ref(AppState)}(p_st)
in
  if st->running > 0 then let
    fun drain(): void =
      if x11_xpending(app) > 0 then let
        val () = x11_next_event(app, p_xev)
        val ev_type = xevent_get_type(p_xev)
        val () =
          if ev_type = ConfigureNotify then handle_configure(p_st, p_xev)
          else if ev_type = ClientMessage then handle_client_message(p_st, app, p_xev)
          else if ev_type = KeyPress then handle_key_press(p_st, p_xev)
          else if ev_type = KeyRelease then handle_key_release(p_st, app, p_xev)
          else if ev_type = ButtonPress then handle_button_press(p_st, canvas_ptr, p_xev)
          else if ev_type = ButtonRelease then handle_button_release(p_st, canvas_ptr, p_xev)
          else if ev_type = MotionNotify then handle_motion_notify(p_st, canvas_ptr, p_xev)
          else ()
      in
        drain()
      end else ()

    val () = drain()
    val () = render_frame(p_st, app, canvas_ptr)
  in
    event_loop(p_st, app, p_xev, canvas_ptr)
  end else ()
end

// --- Ana Pencere Başlatıcı (Pür ATS2) ---

extern fun window_create_and_run(canvas_ptr: ptr): int = "ext#window_create_and_run"
implement window_create_and_run(canvas_ptr) = let
  val app = x11_app_create(1000, 600, "MinePaint (ATS2 + X11)")
in
  if app = the_null_ptr then 1
  else let
    val p_xev = xevent_alloc()
    var st: AppState
    val () = st.win_w := 1000
    val () = st.win_h := 600
    val () = st.sidebar_w := 250
    val () = st.running := 1
    val () = st.is_space_pressed := 0
    val () = st.current_mouse_btn := 0
    val p_st = addr@(st)

    val () = event_loop(p_st, app, p_xev, canvas_ptr)
    val () = xevent_free(p_xev)
    val () = x11_app_destroy(app)
  in
    0
  end
end
