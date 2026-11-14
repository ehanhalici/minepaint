// src/window/app_box.sats
// Pencere uygulamasi: sahipli (dogrusal) tutamac. app_create bir Option_vt dondurur (basarisizsa None),
// app_destroy tuketir; diger islemler tutamaci odunc alir (!MpApp). Tek `assume` window.dats icindedir.

staload "x11/xevent_box.sats"
staload "x11/display_box.sats"
staload "sys/capability.sats"
staload "gl/gl_io.sats"

absvtype MpApp = ptr

fun app_create (w: int, h: int, title: string): [ok:bool] (option_v(GL_IO, ok) | option_vt(MpApp, ok)) = "ext#app_create"
fun app_destroy (pf: GL_IO | app: MpApp): void = "ext#app_destroy"
fun app_wm_delete (app: !MpApp): ulint = "ext#app_wm_delete"
fun app_pending (app: !MpApp): int = "ext#app_pending"
fun app_next_event (app: !MpApp, ev: MpXEvent): void = "ext#app_next_event"
fun app_swap (pf: !GL_IO | app: !MpApp): void = "ext#app_swap"
fun app_dpy (app: !MpApp): MpDisplay = "ext#app_dpy"
