(* X11 XInput2 Tablet Arayüzü *)

staload "x11/display_box.sats"

fun xi2_init(dpy: MpDisplay): int = "ext#xi2_init"
fun xi2_process_raw_event(dpy: MpDisplay, p_xev: ptr): int = "ext#xi2_process_raw_event"
