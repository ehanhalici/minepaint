// src/x11/raw_box.sats
// XI2 ham olay verisi (cookie) X sunucusu tarafindan verilir ve XFreeEventData ile serbest birakilir.
// RAW_LIVE kaniti c_xi2_cookie_get_data basarisindan dogar, c_xi2_cookie_free_data tuketir; okuyucular `!RAW_LIVE`
// ister, yani serbest birakilmis veriyi okumak derleme hatasidir.
absview RAW_LIVE
abst@ype MpRaw = ptr

fun raw_is_null(r: MpRaw): int = "mac#mp_ptr_is_null"
