#ifndef MINEPAINT_EVENT_CATS
#define MINEPAINT_EVENT_CATS

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/cursorfont.h>

#define mp_xevent_sizeof() ((int)sizeof(XEvent))
#define mp_xevent_type(e) (((XEvent*)(e))->type)
#define mp_xevent_config_w(e) (((XEvent*)(e))->xconfigure.width)
#define mp_xevent_config_h(e) (((XEvent*)(e))->xconfigure.height)
#define mp_xevent_client_data0(e) ((atstype_lint)((XEvent*)(e))->xclient.data.l[0])
#define mp_xevent_key_time(e) ((atstype_ulint)((XEvent*)(e))->xkey.time)
#define mp_xevent_keysym(e) ((atstype_ulint)XLookupKeysym(&((XEvent*)(e))->xkey, 0))
#define mp_xevent_btn_x(e) (((XEvent*)(e))->xbutton.x)
#define mp_xevent_btn_y(e) (((XEvent*)(e))->xbutton.y)
#define mp_xevent_btn_button(e) (((XEvent*)(e))->xbutton.button)
#define mp_xevent_motion_x(e) (((XEvent*)(e))->xmotion.x)
#define mp_xevent_motion_y(e) (((XEvent*)(e))->xmotion.y)
#define mp_xevent_motion_state(e) ((unsigned int)((XEvent*)(e))->xmotion.state)

#define mp_xvi_depth(vi) (((XVisualInfo*)(vi))->depth)
#define mp_xvi_visual(vi) ((atstype_ptr)((XVisualInfo*)(vi))->visual)

#define mp_swa_sizeof() ((int)sizeof(XSetWindowAttributes))
#define mp_hints_sizeof() ((int)sizeof(XSizeHints))

static inline void mp_swa_set(XSetWindowAttributes *swa, Colormap cmap, long mask) {
  swa->colormap = cmap;
  swa->event_mask = mask;
}

static inline void mp_hints_set_min(XSizeHints *h, int w, int ht) {
  h->flags = PMinSize;
  h->min_width = w;
  h->min_height = ht;
}

#endif
