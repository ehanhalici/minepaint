(* XEvent alanları ve ats-X11'de olmayan Xlib çağrıları. *)

staload "x11/display_box.sats"
staload "x11/visual_box.sats"
staload "sys/buf.sats"

fun mp_xevent_sizeof(): int = "mac#"
fun mp_xevent_type(e: !XEvBuf): int = "mac#"
fun mp_xevent_config_w(e: !XEvBuf): int = "mac#"
fun mp_xevent_config_h(e: !XEvBuf): int = "mac#"
fun mp_xevent_client_data0(e: !XEvBuf): lint = "mac#"
fun mp_xevent_key_time(e: !XEvBuf): ulint = "mac#"
fun mp_xevent_keysym(e: !XEvBuf): ulint = "mac#"
fun mp_xevent_btn_x(e: !XEvBuf): int = "mac#"
fun mp_xevent_btn_y(e: !XEvBuf): int = "mac#"
fun mp_xevent_btn_button(e: !XEvBuf): int = "mac#"
fun mp_xevent_motion_x(e: !XEvBuf): int = "mac#"
fun mp_xevent_motion_y(e: !XEvBuf): int = "mac#"
fun mp_xevent_motion_state(e: !XEvBuf): uint = "mac#"

fun mp_swa_sizeof(): int = "mac#"
fun mp_hints_sizeof(): int = "mac#"
fun mp_swa_set(swa: !SwaBuf, cmap: ulint, mask: lint): void = "mac#"
fun mp_hints_set_min(h: !HintsBuf, w: int, ht: int): void = "mac#"
fun mp_x_default_screen(d: !Display): int = "mac#"
fun mp_x_root_window(d: !Display, s: int): ulint = "mac#"

