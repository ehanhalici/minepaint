// src/sys/log_io.sats
// Hata gunlugu etkisi: stderr'e yazmak LOG_IO kanitini odunc alir (kural R11: stderr yazimi yalniz libc.dats).
// Kanit window_create_and_run'da uretilir; anth_die_* sureci sonlandirir ve kanit gerektirmez.
staload "sys/capability.sats"

stadef LOG_IO = CAP(KIND_LOG, 0)

fun log_error(pf: !LOG_IO | msg: string): void = "ext#log_error"
