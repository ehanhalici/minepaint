// src/ui/window.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

%{^
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/cursorfont.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Canvas ve Widget FFI İmzaları
extern void canvas_render(void* p, int canvas_w, int canvas_h);
extern void canvas_on_wheel(void* p, int mx, int my, int dy);
extern void canvas_on_mouse_down(void* p, int mx, int my, int btn, int is_pan);
extern void canvas_on_mouse_move(void* p, int mx, int my, int btn, int is_pan);
extern void canvas_on_mouse_up(void* p, int mx, int my, int btn, int is_pan);

extern void widgets_render(float sx, float sy, float sw, float sh);
extern int widgets_on_mouse_down(float mx, float my, int btn, void* canvas_ptr);
extern int widgets_on_mouse_move(float mx, float my, void* canvas_ptr);
extern void widgets_on_mouse_up(void* canvas_ptr);
extern int widgets_is_dragging(void);

static int run_x11_window(void* canvas_ptr) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "HATA: X11 Display açılamadı!\n");
        return 1;
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
        return 1;
    }

    Colormap cmap = XCreateColormap(dpy, root, vi->visual, AllocNone);

    XSetWindowAttributes swa;
    swa.colormap = cmap;
    swa.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask |
                     ButtonPressMask | ButtonReleaseMask |
                     PointerMotionMask | StructureNotifyMask;

    int win_w = 1000;
    int win_h = 600;
    const int sidebar_w = 250;

    Window win = XCreateWindow(
        dpy, root, 0, 0, win_w, win_h, 0,
        vi->depth, InputOutput, vi->visual,
        CWColormap | CWEventMask, &swa
    );

    // Minimum pencere boyutunu belirle
    XSizeHints hints;
    hints.flags = PMinSize;
    hints.min_width = 450;
    hints.min_height = 350;
    XSetWMNormalHints(dpy, win, &hints);

    XMapWindow(dpy, win);
    XStoreName(dpy, win, "MinePaint (ATS2 + X11)");

    // Pencere kapatma (X düğmesi) protokolü
    Atom wmDelete = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(dpy, win, &wmDelete, 1);

    // GLX Context oluşturma ve bağlama
    GLXContext glc = glXCreateContext(dpy, vi, NULL, GL_TRUE);
    if (!glc) {
        fprintf(stderr, "HATA: GLX Context oluşturulamadı!\n");
        XDestroyWindow(dpy, win);
        XCloseDisplay(dpy);
        return 1;
    }
    glXMakeCurrent(dpy, win, glc);

    // Çizim imleci (Crosshair)
    Cursor cursor = XCreateFontCursor(dpy, XC_crosshair);
    XDefineCursor(dpy, win, cursor);

    int running = 1;
    int is_space_pressed = 0;
    int current_mouse_btn = 0;

    while (running) {
        while (XPending(dpy)) {
            XEvent xev;
            XNextEvent(dpy, &xev);

            switch (xev.type) {
                case ConfigureNotify: {
                    win_w = xev.xconfigure.width;
                    win_h = xev.xconfigure.height;
                    break;
                }

                case ClientMessage: {
                    if ((Atom)xev.xclient.data.l[0] == wmDelete) {
                        running = 0;
                    }
                    break;
                }

                case KeyPress: {
                    KeySym ks = XLookupKeysym(&xev.xkey, 0);
                    if (ks == XK_Escape) {
                        running = 0;
                    } else if (ks == XK_space) {
                        is_space_pressed = 1;
                    }
                    break;
                }

                case KeyRelease: {
                    KeySym ks = XLookupKeysym(&xev.xkey, 0);
                    if (ks == XK_space) {
                        if (XEventsQueued(dpy, QueuedAfterReading)) {
                            XEvent nev;
                            XPeekEvent(dpy, &nev);
                            if (nev.type == KeyPress && nev.xkey.time == xev.xkey.time &&
                                XLookupKeysym(&nev.xkey, 0) == XK_space) {
                                XNextEvent(dpy, &nev);
                                continue;
                            }
                        }
                        is_space_pressed = 0;
                    }
                    break;
                }

                case ButtonPress: {
                    int bx = xev.xbutton.x;
                    int by = xev.xbutton.y;
                    int btn = xev.xbutton.button;

                    if (btn == 4) { // Tekerlek yukarı -> Yakınlaş (Zoom In)
                        canvas_on_wheel(canvas_ptr, bx, by, -1);
                    } else if (btn == 5) { // Tekerlek aşağı -> Uzaklaş (Zoom Out)
                        canvas_on_wheel(canvas_ptr, bx, by, 1);
                    } else {
                        current_mouse_btn = btn;
                        int sidebar_x = win_w - sidebar_w;
                        if (bx >= sidebar_x) {
                            if (btn == 1) { // Sidebar widget etkileşimi
                                widgets_on_mouse_down((float)(bx - sidebar_x), (float)by, btn, canvas_ptr);
                            }
                        } else {
                            int is_pan = (btn == 2) || is_space_pressed;
                            canvas_on_mouse_down(canvas_ptr, bx, by, btn, is_pan);
                        }
                    }
                    break;
                }

                case ButtonRelease: {
                    int bx = xev.xbutton.x;
                    int by = xev.xbutton.y;
                    int btn = xev.xbutton.button;

                    if (btn != 4 && btn != 5) {
                        if (widgets_is_dragging()) {
                            widgets_on_mouse_up(canvas_ptr);
                        } else {
                            int is_pan = (btn == 2) || is_space_pressed;
                            canvas_on_mouse_up(canvas_ptr, bx, by, btn, is_pan);
                        }
                        current_mouse_btn = 0;
                    }
                    break;
                }

                case MotionNotify: {
                    int mx = xev.xmotion.x;
                    int my = xev.xmotion.y;

                    if (widgets_is_dragging()) {
                        int sidebar_x = win_w - sidebar_w;
                        widgets_on_mouse_move((float)(mx - sidebar_x), (float)my, canvas_ptr);
                    } else {
                        int btn = current_mouse_btn;
                        if (btn == 0) {
                            if (xev.xmotion.state & Button1Mask) btn = 1;
                            else if (xev.xmotion.state & Button2Mask) btn = 2;
                            else if (xev.xmotion.state & Button3Mask) btn = 3;
                        }
                        if (btn != 0) {
                            int is_pan = (btn == 2) || is_space_pressed;
                            canvas_on_mouse_move(canvas_ptr, mx, my, btn, is_pan);
                        }
                    }
                    break;
                }

                default:
                    break;
            }
        }

        // Çizim Bölgesi
        int canvas_w = win_w - sidebar_w;
        if (canvas_w < 1) canvas_w = 1;

        // 1. Canvas çizimi
        canvas_render(canvas_ptr, canvas_w, win_h);

        // 2. Sidebar widget'ları çizimi
        glViewport(0, 0, win_w, win_h);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0.0, (double)win_w, (double)win_h, 0.0, -1.0, 1.0);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        widgets_render((float)(win_w - sidebar_w), 0.0f, (float)sidebar_w, (float)win_h);

        glXSwapBuffers(dpy, win);

        usleep(10000); // 10ms (~100 FPS)
    }

    // Temizlik
    XFreeCursor(dpy, cursor);
    glXMakeCurrent(dpy, None, NULL);
    glXDestroyContext(dpy, glc);
    XDestroyWindow(dpy, win);
    XCloseDisplay(dpy);

    return 0;
}
%}

// ATS2 Dışa Aktarılan Arayüz
extern fun run_x11_window(canvas_ptr: ptr): int = "mac#run_x11_window"

extern fun window_create_and_run(canvas_ptr: ptr): int = "ext#window_create_and_run"
implement window_create_and_run(canvas_ptr) = run_x11_window(canvas_ptr)
