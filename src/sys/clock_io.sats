// src/sys/clock_io.sats
// Zaman etkisi: saati okumak ve uyumak CLOCK_IO kanitini odunc alir (kural R11: zaman cagrilari yalniz burada).
// Kanit window_create_and_run'da uretilir; zaman olay dongusunun kenarinda okunur, canvas'a `now` degeri olarak verilir.
staload "sys/capability.sats"

stadef CLOCK_IO = CAP(KIND_CLOCK, 0)

fun get_time_seconds(pf: !CLOCK_IO | ): double = "ext#get_time_seconds"
fun sleep_usec(pf: !CLOCK_IO | usec: uint): void = "ext#sleep_usec"
