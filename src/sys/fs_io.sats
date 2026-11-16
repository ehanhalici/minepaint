// src/sys/fs_io.sats
// Dosya sistemi ve ortam etkisi: tum dosya/dizin/ortam cagrilari FS_IO kanitini odunc alir
// (kural R11: bu bildirimler yalniz burada). Kanit window_create_and_run'da uretilir.
staload "sys/capability.sats"
staload "sys/buf.sats"

stadef FS_IO = CAP(KIND_FS, 0)

// Dosya sahipli (dogrusal) tutamactir: fopen Option_vt dondurur (basarisizlik deger), fclose tuketir,
// digerleri !File odunc alir. Tek `assume` libc.dats icindedir.
absvtype File = ptr

fun file_open{n:int}(pf: !FS_IO | path: !Text(n), mode: string): Option_vt(File) = "ext#file_open"
fun file_close(pf: !FS_IO | f: File): void = "ext#file_close"
// Ham yazici: Text durumunu bozar; muhurlu `fgets` sys/text_io.dats'tadir.
fun c_fgets_raw{n:pos}(pf: !FS_IO | buf: !Text(n) >> TextRaw(n), cnt: int(n), f: !File): bool = "mac#mp_fgets_ok"
fun fputs{n:int}(pf: !FS_IO | s: !Text(n), f: !File): int = "mac#fputs"
fun fflush(pf: !FS_IO | f: !File): int = "mac#fflush"
fun fileno(pf: !FS_IO | f: !File): int = "mac#fileno"
fun fsync(pf: !FS_IO | fd: int): int = "mac#fsync"
fun rename{n,m:int}(pf: !FS_IO | old: !Text(n), new: !Text(m)): int = "mac#rename"
fun perror(pf: !FS_IO | msg: string): void = "mac#perror"
fun fseek(pf: !FS_IO | f: !File, off: lint, whence: int): int = "mac#fseek"
fun ftell(pf: !FS_IO | f: !File): lint = "mac#ftell"
fun rewind(pf: !FS_IO | f: !File): void = "mac#rewind"
fun getenv_or_empty(pf: !FS_IO | name: string): string = "mac#mp_getenv_or_empty"
fun mkdir{n:int}(pf: !FS_IO | path: !Text(n), mode: uint): int = "mac#mkdir"
