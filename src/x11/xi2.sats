(* X11 XInput2 Tablet Arayüzü *)

fun xi2_init(dpy: ptr): int = "ext#xi2_init"
fun xi2_process_raw_event(dpy: ptr, p_xev: ptr): int = "ext#xi2_process_raw_event"
