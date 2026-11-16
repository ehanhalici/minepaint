#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/buf.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"

staload "sys/libc.dats"
staload "window/input.dats"
staload "x11/x_io.sats"
staload "x11/devlist.sats"

// Sanctioned assume (DevList): sahipli cihaz listesi C tarafinda bir ptr'dir.
assume DevList = ptr
staload "x11/raw_box.sats"
staload "x11/xi2_axis.dats"
staload "x11/display_box.sats"
staload "sys/buf.sats"

// --- Düşük Seviye C Köprüsü Tanımları ---
extern fun c_xi2_free_devices(devs: DevList): void = "mac#xi2_free_devices"
extern fun c_xi2_device_id(devs: !DevList, idx: int): int = "mac#xi2_device_id"
extern fun c_xi2_device_is_master(devs: !DevList, idx: int): int = "mac#xi2_device_is_master"
extern fun c_xi2_device_name(devs: !DevList, idx: int): string = "mac#xi2_device_name"
extern fun c_xi2_device_num_classes(devs: !DevList, idx: int): int = "mac#xi2_device_num_classes"
extern fun c_xi2_device_class_type(devs: !DevList, dev_idx: int, class_idx: int): int = "mac#xi2_device_class_type"
extern fun c_xi2_device_class_val_axis(devs: !DevList, dev_idx: int, class_idx: int): int = "mac#xi2_device_class_val_axis"
extern fun c_xi2_device_class_val_min(devs: !DevList, dev_idx: int, class_idx: int): double = "mac#xi2_device_class_val_min"
extern fun c_xi2_device_class_val_max(devs: !DevList, dev_idx: int, class_idx: int): double = "mac#xi2_device_class_val_max"
extern fun c_xi2_cookie_extension(ev: !XEvBuf): int = "mac#xi2_cookie_extension"
extern fun c_xi2_cookie_evtype(ev: !XEvBuf): int = "mac#xi2_cookie_evtype"
extern fun c_xi2_cookie_data(pf: !RAW_LIVE | ev: !XEvBuf): MpRaw = "mac#xi2_cookie_data"
extern fun c_xi2_raw_deviceid(pf: !RAW_LIVE | data: MpRaw): int = "mac#xi2_raw_deviceid"

// POSIX string search helper (no pointer crawling required)
extern fun strcasestr(haystack: string, needle: string): ptr = "mac#strcasestr"

// --- Sabitler ---
#define XI2_VALUATOR_CLASS 2
#define XI2_HIERARCHY_CHANGED 11
#define XI2_DEVICE_CHANGED 1
#define XI2_RAW_MOTION 17
#define XI2_RAW_BUTTON_PRESS 15
#define XI2_RAW_BUTTON_RELEASE 16

#define XI2_MAX_DEVICES 128

// --- Aritmetik Yardımcıları ---
fn f_lt(a: float, b: float): bool = g0float_lt(a, b)
fn d_sub(a: double, b: double): double = g0float_sub(a, b)
fn d_div(a: double, b: double): double = g0float_div(a, b)
fn d_lt(a: double, b: double): bool = g0float_lt(a, b)
fn d_gt(a: double, b: double): bool = g0float_gt(a, b)
fn d_lte(a: double, b: double): bool = g0float_lte(a, b)

extern fun strcasestr_buf{n:int}(haystack: !Text(n), needle: string): ptr = "mac#strcasestr"
fn buf_has_substr_ci{n:int}(haystack: !Text(n), needle: string): bool =
  strcasestr_buf(haystack, needle) != the_null_ptr

fn str_has_substr_ci(haystack: string, needle: string): bool =
  strcasestr(haystack, needle) != the_null_ptr

// --- Cihaz Adı Ayrıştırma ---
fn xi2_is_mouse_name(name: string): bool =
  str_has_substr_ci(name, "mouse")

fn xi2_is_eraser_name(name: string): bool =
  str_has_substr_ci(name, "eraser")

fn xi2_is_stylus_keyword(name: string): bool =
  str_has_substr_ci(name, "pen") ||
  str_has_substr_ci(name, "stylus") ||
  str_has_substr_ci(name, "wacom") ||
  str_has_substr_ci(name, "tablet") ||
  str_has_substr_ci(name, "huion") ||
  str_has_substr_ci(name, "xp-pen") ||
  str_has_substr_ci(name, "xppen") ||
  str_has_substr_ci(name, "ugee") ||
  str_has_substr_ci(name, "gaomon") ||
  str_has_substr_ci(name, "digitizer")

fn xi2_is_stylus_name(name: string): bool =
  not(xi2_is_mouse_name(name)) && xi2_is_stylus_keyword(name)

// --- Aygıt Bilgisi Veri Yapısı ---
typedef XI2DevInfo = @{
  deviceid= int,
  is_stylus= int,
  is_eraser= int,
  is_master= int,
  pressure_axis= int,
  pressure_min= double,
  pressure_max= double,
  last_pressure= double
}

// Aygit tablosu: XI2_MAX_DEVICES adet tipli kayit referansi (ham ptr aritmetigi yok); indeks Ix(128).
typedef DevTab = arrayref(ref(XI2DevInfo), 128)
typedef XI2BackendState = @{
  opcode= int,
  active= int,
  devs= DevTab
}

fn new_dev_info(): ref(XI2DevInfo) =
  ref<XI2DevInfo>(@{ deviceid= ~1, is_stylus= 0, is_eraser= 0, is_master= 0, pressure_axis= ~1,
                     pressure_min= 0.0, pressure_max= 1.0, last_pressure= 0.8 })

val g_devs: DevTab = arrayref_make_elt<ref(XI2DevInfo)>(i2sz(128), new_dev_info())

// Her yuvaya ayri kayit (olcu 128 - i).
fun fill_devs {i:nat | i <= 128} .<128 - i>. (i: int(i)): void =
  if i < 128 then (g_devs[i] := new_dev_info(); fill_devs(i + 1)) else ()
val () = fill_devs(0)

val g_xi = ref<XI2BackendState>(@{
  opcode= 0,
  active= 0,
  devs= g_devs
})

fn xi2_state_ref(): ref(XI2BackendState) = g_xi

// Sozlesme: cagiranlar id'yi [0, XI2_MAX_DEVICES) icinde denetler; disi tasarim ihlalidir.
fn xi2_dev_ref(base: DevTab, id: int): ref(XI2DevInfo) = let
  val @(ok, ix) = ix_try(id, 128)
in
  if ok then base[ix] else anth_die_any(DieContractViolation())
end

fn xi2_dev_ptr(base: DevTab, id: int): ref(XI2DevInfo) = xi2_dev_ref(base, id)

fn xi2_clear_device(base: DevTab, id: int): void = let
  val dev = xi2_dev_ref(base, id)
  val () = dev->deviceid := ~1
  val () = dev->is_stylus := 0
  val () = dev->is_eraser := 0
  val () = dev->is_master := 0
  val () = dev->pressure_axis := ~1
  val () = dev->pressure_min := 0.0
  val () = dev->pressure_max := 1.0
  val () = dev->last_pressure := 0.8
in () end

fn xi2_clear_all_devices(base: DevTab): void = let
  fun loop {i:nat | i <= XI2_MAX_DEVICES} .<XI2_MAX_DEVICES - i>. (i: int(i)): void =
    if i < XI2_MAX_DEVICES then (xi2_clear_device(base, i); loop(i + 1)) else ()
in
  loop(0)
end

// --- Valuator ve Eksen İnceleme ---
fn xi2_label_is_pressure(xio: !X_IO |
  dpy: !Display, devs: !DevList, dev_idx: int, class_idx: int
): bool = let
  val buf = text_new(128)
  val ok = c_xi2_device_class_val_label(xio | dpy, devs, dev_idx, class_idx, buf, 128)
  val () = text_seal(buf, 128)
  val is_press = if ok > 0 then buf_has_substr_ci(buf, "pressure") else false
  val () = text_free(buf)
in is_press end

fn xi2_set_pressure_axis(devs: !DevList, dev_idx: int, class_idx: int, dev: ref(XI2DevInfo)): void = let
  val min_v = c_xi2_device_class_val_min(devs, dev_idx, class_idx)
  val max_v = c_xi2_device_class_val_max(devs, dev_idx, class_idx)
  val () = dev->pressure_axis := c_xi2_device_class_val_axis(devs, dev_idx, class_idx)
  val () = dev->pressure_min := min_v
  val () = dev->pressure_max := (if d_lte(max_v, min_v) then min_v + 1.0 else max_v)
  val () = dev->is_stylus := 1
in () end

fn xi2_inspect_valuator(xio: !X_IO |
  dpy: !Display, devs: !DevList, dev_idx: int, class_idx: int, dev_p: ref(XI2DevInfo)
): void =
  if c_xi2_device_class_type(devs, dev_idx, class_idx) != XI2_VALUATOR_CLASS then ()
  else if xi2_label_is_pressure(xio | dpy, devs, dev_idx, class_idx) then
    xi2_set_pressure_axis(devs, dev_idx, class_idx, dev_p)
  else ()

// Ust duzey (ic ice degil): dogrusal !DevList ic ice fonksiyona yakalanamaz.
fun xi2_inspect_class_loop {m:nat}{c:nat | c <= m} .<m - c>. (xio: !X_IO |
  dpy: !Display, devs: !DevList, dev_idx: int, dev_p: ref(XI2DevInfo), ncls: int(m), c: int(c)
): void =
  if c < ncls then let
    val () = xi2_inspect_valuator(xio | dpy, devs, dev_idx, c, dev_p)
    val () = xi2_inspect_class_loop(xio | dpy, devs, dev_idx, dev_p, ncls, c + 1)
  in () end else ()

fn xi2_inspect_device_classes(xio: !X_IO | 
  dpy: !Display, devs: !DevList, dev_idx: int, num_classes: int, dev_p: ref(XI2DevInfo)
): void = let
  val ncls = airlock_nat(num_classes)
in
  xi2_inspect_class_loop(xio | dpy, devs, dev_idx, dev_p, ncls, 0)
end

fn xi2_inspect_single_device(xio: !X_IO | dpy: !Display, devs: !DevList, idx: int, base: DevTab): void = let
  val did = c_xi2_device_id(devs, idx)
in
  if (did < 0) || (did >= XI2_MAX_DEVICES) then ()
  else let
    val dev = xi2_dev_ref(base, did)
    val () = dev->deviceid := did
    val is_master = c_xi2_device_is_master(devs, idx)
    val () = dev->is_master := is_master
  in
    if is_master = 0 then let
      val name = c_xi2_device_name(devs, idx)
      val is_eraser = xi2_is_eraser_name(name)
      val is_stylus = if is_eraser then true else xi2_is_stylus_name(name)
      val () = if is_eraser then dev->is_eraser := 1 else ()
      val () = if is_stylus then dev->is_stylus := 1 else ()
      val nclasses = c_xi2_device_num_classes(devs, idx)
      val () = xi2_inspect_device_classes(xio | dpy, devs, idx, nclasses, xi2_dev_ptr(base, did))
    in () end else ()
  end
end

fun xi2_inspect_devs_loop {m:nat}{i:nat | i <= m} .<m - i>. (xio: !X_IO |
  dpy: !Display, devs: !DevList, base: DevTab, n: int(m), i: int(i)
): void =
  if i < n then let
    val () = xi2_inspect_single_device(xio | dpy, devs, i, base)
    val () = xi2_inspect_devs_loop(xio | dpy, devs, base, n, i + 1)
  in () end else ()

fn xi2_refresh_devices_internal(xio: !X_IO | dpy: !Display, base: DevTab): void = let
  val () = xi2_clear_all_devices(base)
  var ndevs: int = 0
  val raw = c_xi2_query_devices(xio | dpy, addr@ndevs)
in
  if raw > the_null_ptr then let
    val devs: DevList = raw
    val n = airlock_nat(ndevs)
    val () = xi2_inspect_devs_loop(xio | dpy, devs, base, n, 0)
    val () = c_xi2_free_devices(devs)
  in () end else ()
end

// --- Basınç Değeri Normalizasyonu ---
fn xi2_normalize_pressure(raw_val: double, min_v: double, max_v: double): float = let
  val range = d_sub(max_v, min_v)
  val r = if d_lte(range, 0.0) then 1.0 else range
  val norm = d_div(d_sub(raw_val, min_v), r)
  val cl1 = if d_lt(norm, 0.0) then 0.0 else norm
  val cl2 = if d_gt(cl1, 1.0) then 1.0 else cl1
in
  g0float2float_double_float(cl2)
end

// --- XInput2 Başlatma ---
fn xi2_deactivate(st: ref(XI2BackendState)): int = (st->active := 0; 0)

fn xi2_version_ok(xio: !X_IO | dpy: !Display): bool =
  (c_xi2_query_version(xio | dpy, 2, 2) > 0) || (c_xi2_query_version(xio | dpy, 2, 0) > 0)

fn xi2_activate(xio: !X_IO | dpy: !Display, st: ref(XI2BackendState), opcode: int): int = let
  val () = st->opcode := opcode
  val () = xi2_refresh_devices_internal(xio | dpy, st->devs)
in
  if c_xi2_select_root_events(xio | dpy) = 0 then xi2_deactivate(st)
  else (st->active := 1; 1)
end

implement xi2_init(xio | dpy) = let
  val st = xi2_state_ref()
  var opcode: int = 0
  val ok_ext = c_xi2_query_extension(xio | dpy, addr@opcode)
in
  if ok_ext = 0 then xi2_deactivate(st)
  else if xi2_version_ok(xio | dpy) then xi2_activate(xio | dpy, st, opcode)
  else xi2_deactivate(st)
end

// --- Ham Olay İşleme ---
fn xi2_compute_norm(pf: !RAW_LIVE | raw_data: MpRaw, dev: ref(XI2DevInfo), axis: int, evtype: int): float = let
  val norm = if xi2_axis_has(pf | raw_data, axis) then let
    val raw_val = xi2_axis_read(pf | raw_data, axis)
    val () = if raw_val > dev->pressure_max then dev->pressure_max := raw_val else ()
    val () = if raw_val < dev->pressure_min then dev->pressure_min := raw_val else ()
    val p = xi2_normalize_pressure(raw_val, dev->pressure_min, dev->pressure_max)
    val () = dev->last_pressure := g0float2float_float_double(p)
  in p end
  else g0float2float_double_float(dev->last_pressure)
in
  if (evtype = XI2_RAW_BUTTON_PRESS) * (f_lt(norm, 0.05f)) then 0.05f else norm
end

fn xi2_process_stylus_event(
  pf: !RAW_LIVE | raw_data: MpRaw, dev_p: ref(XI2DevInfo), evtype: int, now: double
): void = let
  val dev = dev_p
  val axis = dev->pressure_axis
in
  if axis >= 0 then let
    val norm_adj = xi2_compute_norm(pf | raw_data, dev, axis, evtype)
  in
    if dev->is_eraser > 0 then input_set_eraser_pressure(norm_adj, now)
    else input_set_stylus_pressure(norm_adj, now)
  end else let
    val def_p = input_get_default_pressure()
  in
    if dev->is_eraser > 0 then input_set_eraser_pressure(def_p, now)
    else input_set_stylus_pressure(def_p, now)
  end
end

fn xi2_handle_motion_event(xio: !X_IO, pf: !RAW_LIVE | 
  dpy: !Display, st: ref(XI2BackendState), raw_data: MpRaw, evtype: int, now: double
): void =
  if raw_is_null(raw_data) != 0 then ()
  else let
    val did = c_xi2_raw_deviceid(pf | raw_data)
  in
    if (did < 0) || (did >= XI2_MAX_DEVICES) then ()
    else let
      val dev = xi2_dev_ref(st->devs, did)
      val () = if dev->deviceid = ~1 then xi2_refresh_devices_internal(xio | dpy, st->devs) else ()
      val dev2 = xi2_dev_ref(st->devs, did)
    in
      if dev2->is_stylus > 0 then let
        val () = xi2_process_stylus_event(pf | raw_data, xi2_dev_ptr(st->devs, did), evtype, now)
      in () end
      else ()
    end
  end

fn xi2_dispatch_event_type(xio: !X_IO, pf: !RAW_LIVE | 
  dpy: !Display, st: ref(XI2BackendState), p_xev: !XEvBuf, evtype: int, now: double
): void =
  if (evtype = XI2_HIERARCHY_CHANGED) || (evtype = XI2_DEVICE_CHANGED) then
    xi2_refresh_devices_internal(xio | dpy, st->devs)
  else if (evtype = XI2_RAW_MOTION) || (evtype = XI2_RAW_BUTTON_PRESS) || (evtype = XI2_RAW_BUTTON_RELEASE) then
    xi2_handle_motion_event(xio, pf | dpy, st, c_xi2_cookie_data(pf | p_xev), evtype, now)
  else ()

implement xi2_process_raw_event(xio | dpy, p_xev, now) = let
  val st = xi2_state_ref()
in
  if c_xi2_cookie_extension(p_xev) != st->opcode then 0
  else let
    val (pf | ok) = c_xi2_cookie_get_data(xio | dpy, p_xev)
  in
    if ok then let
      prval Some_v(live) = pf
      val evtype = c_xi2_cookie_evtype(p_xev)
      val () = xi2_dispatch_event_type(xio, live | dpy, st, p_xev, evtype, now)
      val () = c_xi2_cookie_free_data(xio, live | dpy, p_xev)
    in 1 end
    else let
      prval None_v() = pf
    in 0 end
  end
end
