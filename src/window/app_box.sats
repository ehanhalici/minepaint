// src/window/app_box.sats
// Pencere uygulamasi: sahipli (dogrusal) tutamac. app_create bir Option_vt dondurur (basarisizsa None),
// app_destroy tuketir; diger islemler tutamaci odunc alir (!MpApp). Tek `assume` window.dats icindedir.

staload "x11/x_io.sats"
staload "sys/buf.sats"
staload "sys/capability.sats"
staload "gl/gl_io.sats"
staload "sys/log_io.sats"

absvtype MpApp = ptr

fun app_create (logio: !LOG_IO | w: int, h: int, title: string): [ok:bool] (option_v(@(GL_IO, X_IO), ok) | option_vt(MpApp, ok)) = "ext#app_create"
fun app_destroy (gio: GL_IO, xio: X_IO | app: MpApp): void = "ext#app_destroy"
fun app_wm_delete (app: !MpApp): ulint = "ext#app_wm_delete"
fun app_pending (xio: !X_IO | app: !MpApp): int = "ext#app_pending"
fun app_next_event (xio: !X_IO | app: !MpApp, ev: !XEvBuf): void = "ext#app_next_event"
fun app_swap (pf: !GL_IO | app: !MpApp): void = "ext#app_swap"
fun app_peek_event (xio: !X_IO | app: !MpApp, ev: !XEvBuf): void = "ext#app_peek_event"
fun app_queued (xio: !X_IO | app: !MpApp, mode: int): int = "ext#app_queued"
fun app_process_raw (xio: !X_IO | app: !MpApp, ev: !XEvBuf, now: double): int = "ext#app_process_raw"
