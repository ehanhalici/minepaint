// src/sys/cast_box.sats
// Sinir donusumleri: C dunyasindan gelen adresin tipli gorunume cevrildigi TEK nokta.
// Mantik dosyalari mp_id_ptr kullanmaz; bu uc fonksiyon uzerinden gecer.

fun ref_of_ptr {a:t@ype} (p: ptr): ref(a) = "mac#mp_id_ptr"
fun fnptr_load {a:type} (p: ptr): a = "mac#mp_id_ptr"
fun fnptr_store {a:type} (f: a): ptr = "mac#mp_id_ptr"
fun cstr_of_ptr (p: ptr): string = "mac#mp_id_ptr"
fun ptr_forget (p: ptr): ptr = "mac#mp_id_ptr"
