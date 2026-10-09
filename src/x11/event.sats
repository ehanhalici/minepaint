(* XEvent alanları ve ats-X11'de olmayan Xlib çağrıları. *)

%{#
#include "x11/event.cats"
%}

fun mp_xevent_sizeof(): int = "mac#"
fun mp_xevent_type(e: ptr): int = "mac#"
fun mp_xevent_config_w(e: ptr): int = "mac#"
fun mp_xevent_config_h(e: ptr): int = "mac#"
fun mp_xevent_client_data0(e: ptr): lint = "mac#"
fun mp_xevent_key_time(e: ptr): ulint = "mac#"
fun mp_xevent_keysym(e: ptr): ulint = "mac#"
fun mp_xevent_btn_x(e: ptr): int = "mac#"
fun mp_xevent_btn_y(e: ptr): int = "mac#"
fun mp_xevent_btn_button(e: ptr): int = "mac#"
fun mp_xevent_motion_x(e: ptr): int = "mac#"
fun mp_xevent_motion_y(e: ptr): int = "mac#"
fun mp_xevent_motion_state(e: ptr): uint = "mac#"

fun mp_xvi_depth(vi: ptr): int = "mac#"
fun mp_xvi_visual(vi: ptr): ptr = "mac#"
fun mp_swa_sizeof(): int = "mac#"
fun mp_hints_sizeof(): int = "mac#"
fun mp_swa_set(swa: ptr, cmap: ulint, mask: lint): void = "mac#"
fun mp_hints_set_min(h: ptr, w: int, ht: int): void = "mac#"
fun mp_x_open_display(): ptr = "mac#"
fun mp_x_default_screen(d: ptr): int = "mac#"
fun mp_x_root_window(d: ptr, s: int): ulint = "mac#"
fun mp_x_map_window(d: ptr, w: ulint): void = "mac#"
fun mp_x_define_cursor(d: ptr, w: ulint, c: ulint): void = "mac#"
fun mp_x_destroy_window(d: ptr, w: ulint): void = "mac#"
fun mp_x_close_display(d: ptr): void = "mac#"

fun XCreateColormap(dpy: ptr, w: ulint, visual: ptr, alloc: int): ulint = "mac#"
fun mp_XCreateWindow(
  dpy: ptr, parent: ulint, x: int, y: int,
  width: uint, height: uint, border: uint,
  depth: int, klass: uint, visual: ptr,
  valuemask: ulint, swa: ptr
): ulint = "mac#XCreateWindow"
fun XStoreName(dpy: ptr, w: ulint, name: string): int = "mac#"
fun XInternAtom(dpy: ptr, name: string, only_if_exists: int): ulint = "mac#"
fun XSetWMProtocols(dpy: ptr, w: ulint, atoms: ptr, n: int): int = "mac#"
fun XSetWMNormalHints(dpy: ptr, w: ulint, hints: ptr): void = "mac#"
fun XCreateFontCursor(dpy: ptr, shape: uint): ulint = "mac#"
fun XFreeCursor(dpy: ptr, cursor: ulint): int = "mac#"
fun XPending(dpy: ptr): int = "mac#"
fun XNextEvent(dpy: ptr, ev: ptr): int = "mac#"
fun XPeekEvent(dpy: ptr, ev: ptr): int = "mac#"
fun XEventsQueued(dpy: ptr, mode: int): int = "mac#"
fun XFree(p: ptr): int = "mac#"
