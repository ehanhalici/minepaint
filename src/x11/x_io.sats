// src/x11/x_io.sats
// X11 etkisi: sunucuya dokunan tum cagrilar X_IO kanitini odunc alir (kural R11: bu bildirimler yalniz burada).
// Kanit window.dats app_create'te (ekran acildiktan sonra) uretilir, app_destroy'da (ekran kapanmadan once) tuketilir.
// Olay alanlarini okuyan saf erisimciler (mp_xevent_*, mp_xvi_*) event.sats'ta kalir.
staload "sys/capability.sats"
staload "x11/display_box.sats"
staload "x11/visual_box.sats"
staload "sys/buf.sats"
staload "x11/raw_box.sats"
staload "x11/devlist.sats"

stadef X_IO = CAP(KIND_X, 0)

fun mp_x_open_display(): ptr = "mac#"

fun mp_x_create_colormap(pf: !X_IO | dpy: !Display, root: ulint, vi: !Vis): ulint = "mac#"
fun mp_x_create_window(pf: !X_IO | dpy: !Display, root: ulint, w: uint, h: uint, vi: !Vis, mask: ulint, swa: !SwaBuf): ulint = "mac#"
fun XStoreName(pf: !X_IO | dpy: !Display, w: ulint, name: string): int = "mac#"
fun XInternAtom(pf: !X_IO | dpy: !Display, name: string, only_if_exists: int): ulint = "mac#"
fun XSetWMProtocols(pf: !X_IO | dpy: !Display, w: ulint, atoms: ptr, n: int): int = "mac#"
fun XSetWMNormalHints(pf: !X_IO | dpy: !Display, w: ulint, hints: !HintsBuf): void = "mac#"
fun XCreateFontCursor(pf: !X_IO | dpy: !Display, shape: uint): ulint = "mac#"
fun XFreeCursor(pf: !X_IO | dpy: !Display, cursor: ulint): int = "mac#"
fun XPending(pf: !X_IO | dpy: !Display): int = "mac#"
fun XNextEvent(pf: !X_IO | dpy: !Display, ev: !XEvBuf): int = "mac#"
fun XPeekEvent(pf: !X_IO | dpy: !Display, ev: !XEvBuf): int = "mac#"
fun XEventsQueued(pf: !X_IO | dpy: !Display, mode: int): int = "mac#"
fun XFree(pf: !X_IO | p: ptr): int = "mac#"
fun mp_x_map_window(pf: !X_IO | d: !Display, w: ulint): void = "mac#"
fun mp_x_define_cursor(pf: !X_IO | d: !Display, w: ulint, c: ulint): void = "mac#"
fun mp_x_destroy_window(pf: !X_IO | d: !Display, w: ulint): void = "mac#"
fun mp_x_close_display(pf: !X_IO | d: Display): void = "mac#"

fun c_xi2_query_extension(pf: !X_IO | dpy: !Display, opcode: ptr): int = "mac#xi2_query_extension"
fun c_xi2_query_version(pf: !X_IO | dpy: !Display, maj: int, min: int): int = "mac#xi2_query_version"
fun c_xi2_select_root_events(pf: !X_IO | dpy: !Display): int = "mac#xi2_select_root_events"
fun c_xi2_query_devices(pf: !X_IO | dpy: !Display, num: ptr): ptr = "mac#xi2_query_devices"
fun c_xi2_device_class_val_label{n:pos}(pf: !X_IO | dpy: !Display, devs: !DevList, dev_idx: int, class_idx: int, buf: !Text(n) >> TextRaw(n), bufsz: int(n)): int = "mac#xi2_device_class_val_label"
fun c_xi2_cookie_get_data(pf: !X_IO | dpy: !Display, ev: !XEvBuf): [ok:bool] (option_v(RAW_LIVE, ok) | bool(ok)) = "mac#xi2_cookie_get_data"
fun c_xi2_cookie_free_data(pf: !X_IO, raw: RAW_LIVE | dpy: !Display, ev: !XEvBuf): void = "mac#xi2_cookie_free_data"

fun xi2_init(pf: !X_IO | dpy: !Display): int = "ext#xi2_init"
fun xi2_process_raw_event(pf: !X_IO | dpy: !Display, p_xev: !XEvBuf, now: double): int = "ext#xi2_process_raw_event"
