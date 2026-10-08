#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "sys/libc.dats"
staload "window/input.dats"
staload "x11/xi2.sats"

%{#
#include "x11/xi2_raw.cats"
%}

// --- Düşük Seviye C Köprüsü Tanımları ---
extern fun c_xi2_query_extension(dpy: ptr, opcode: ptr): int = "mac#xi2_query_extension"
extern fun c_xi2_query_version(dpy: ptr, maj: int, min: int): int = "mac#xi2_query_version"
extern fun c_xi2_select_root_events(dpy: ptr): int = "mac#xi2_select_root_events"
extern fun c_xi2_query_devices(dpy: ptr, num: ptr): ptr = "mac#xi2_query_devices"
extern fun c_xi2_free_devices(devs: ptr): void = "mac#xi2_free_devices"
extern fun c_xi2_device_id(devs: ptr, idx: int): int = "mac#xi2_device_id"
extern fun c_xi2_device_is_master(devs: ptr, idx: int): int = "mac#xi2_device_is_master"
extern fun c_xi2_device_name(devs: ptr, idx: int): string = "mac#xi2_device_name"
extern fun c_xi2_device_num_classes(devs: ptr, idx: int): int = "mac#xi2_device_num_classes"
extern fun c_xi2_device_class_type(devs: ptr, dev_idx: int, class_idx: int): int = "mac#xi2_device_class_type"
extern fun c_xi2_device_class_val_axis(devs: ptr, dev_idx: int, class_idx: int): int = "mac#xi2_device_class_val_axis"
extern fun c_xi2_device_class_val_min(devs: ptr, dev_idx: int, class_idx: int): double = "mac#xi2_device_class_val_min"
extern fun c_xi2_device_class_val_max(devs: ptr, dev_idx: int, class_idx: int): double = "mac#xi2_device_class_val_max"
extern fun c_xi2_device_class_val_label(dpy: ptr, devs: ptr, dev_idx: int, class_idx: int, buf: ptr, bufsz: int): int = "mac#xi2_device_class_val_label"
extern fun c_xi2_cookie_extension(ev: ptr): int = "mac#xi2_cookie_extension"
extern fun c_xi2_cookie_get_data(dpy: ptr, ev: ptr): int = "mac#xi2_cookie_get_data"
extern fun c_xi2_cookie_free_data(dpy: ptr, ev: ptr): void = "mac#xi2_cookie_free_data"
extern fun c_xi2_cookie_evtype(ev: ptr): int = "mac#xi2_cookie_evtype"
extern fun c_xi2_cookie_data(ev: ptr): ptr = "mac#xi2_cookie_data"
extern fun c_xi2_raw_deviceid(data: ptr): int = "mac#xi2_raw_deviceid"
extern fun c_xi2_raw_has_axis(data: ptr, axis: int): int = "mac#xi2_raw_has_axis"
extern fun c_xi2_raw_read_axis(data: ptr, axis: int): double = "mac#xi2_raw_read_axis"

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

typedef XI2BackendState = @{
  opcode= int,
  active= int,
  devs= ptr
}

extern castfn ptr2dev_info(p: ptr): ref(XI2DevInfo) = "mac#"
extern castfn addr2str(p: ptr): string = "mac#"

val g_dev_sz = g0int2uint_int_size(XI2_MAX_DEVICES) * sizeof<XI2DevInfo>
val g_devs = malloc(g_dev_sz)
val () = assertloc(g_devs > the_null_ptr)
val _ = memset(g_devs, 0, g_dev_sz)
val g_xi = ref<XI2BackendState>(@{
  opcode= 0,
  active= 0,
  devs= g_devs
})

fn xi2_state_ref(): ref(XI2BackendState) = g_xi

fn xi2_dev_ptr(base: ptr, id: int): ptr =
  ptr_add<XI2DevInfo>(base, id)

fn xi2_dev_ref(base: ptr, id: int): ref(XI2DevInfo) =
  ptr2dev_info(xi2_dev_ptr(base, id))

fn xi2_clear_device(base: ptr, id: int): void = let
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

fn xi2_clear_all_devices(base: ptr): void = let
  fun loop(i: int): void =
    if i < XI2_MAX_DEVICES then (xi2_clear_device(base, i); loop(i + 1)) else ()
in
  loop(0)
end

// --- Valuator ve Eksen İnceleme ---
fn xi2_inspect_valuator(
  dpy: ptr, devs: ptr, dev_idx: int, class_idx: int, dev_p: ptr
): void = let
  val ctype = c_xi2_device_class_type(devs, dev_idx, class_idx)
in
  if ctype != XI2_VALUATOR_CLASS then ()
  else let
    var buf = @[char][128]()
    val p_buf = addr@(buf)
    val ok = c_xi2_device_class_val_label(dpy, devs, dev_idx, class_idx, p_buf, 128)
    val is_press = if ok > 0 then str_has_substr_ci(addr2str(p_buf), "pressure") else false
  in
    if is_press then let
      val dev = ptr2dev_info(dev_p)
      val axis = c_xi2_device_class_val_axis(devs, dev_idx, class_idx)
      val min_v = c_xi2_device_class_val_min(devs, dev_idx, class_idx)
      val max_v = c_xi2_device_class_val_max(devs, dev_idx, class_idx)
      val () = dev->pressure_axis := axis
      val () = dev->pressure_min := min_v
      val () = dev->pressure_max := (if d_lte(max_v, min_v) then min_v + 1.0 else max_v)
      val () = dev->is_stylus := 1
    in () end else ()
  end
end

fn xi2_inspect_device_classes(
  dpy: ptr, devs: ptr, dev_idx: int, num_classes: int, dev_p: ptr
): void = let
  fun loop(c: int): void =
    if c < num_classes then (xi2_inspect_valuator(dpy, devs, dev_idx, c, dev_p); loop(c + 1)) else ()
in
  loop(0)
end

fn xi2_inspect_single_device(dpy: ptr, devs: ptr, idx: int, base: ptr): void = let
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
      val () = xi2_inspect_device_classes(dpy, devs, idx, nclasses, xi2_dev_ptr(base, did))
    in () end else ()
  end
end

fn xi2_refresh_devices_internal(dpy: ptr, base: ptr): void = let
  val () = xi2_clear_all_devices(base)
  var ndevs: int = 0
  val devs = c_xi2_query_devices(dpy, addr@ndevs)
in
  if devs != the_null_ptr then let
    val n = ndevs
    fun loop(i: int): void =
      if i < n then (xi2_inspect_single_device(dpy, devs, i, base); loop(i + 1)) else ()
    val () = loop(0)
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
implement xi2_init(dpy) =
  if dpy = the_null_ptr then 0
  else let
    val st = xi2_state_ref()
    var opcode: int = 0
    val ok_ext = c_xi2_query_extension(dpy, addr@opcode)
  in
    if ok_ext = 0 then (st->active := 0; 0)
    else let
      val ok_ver = c_xi2_query_version(dpy, 2, 2)
      val ok_ver_final = (ok_ver > 0) || (c_xi2_query_version(dpy, 2, 0) > 0)
    in
      if not(ok_ver_final) then (st->active := 0; 0)
      else let
        val () = st->opcode := opcode
        val () = xi2_refresh_devices_internal(dpy, st->devs)
      in
        if c_xi2_select_root_events(dpy) = 0 then (st->active := 0; 0)
        else (st->active := 1; 1)
      end
    end
  end

// --- Ham Olay İşleme ---
fn xi2_compute_norm(raw_data: ptr, dev: ref(XI2DevInfo), axis: int, evtype: int): float = let
  val has_press = c_xi2_raw_has_axis(raw_data, axis)
  val norm = if has_press > 0 then let
    val raw_val = c_xi2_raw_read_axis(raw_data, axis)
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
  raw_data: ptr, dev_p: ptr, evtype: int, now: double
): void = let
  val dev = ptr2dev_info(dev_p)
  val axis = dev->pressure_axis
in
  if axis >= 0 then let
    val norm_adj = xi2_compute_norm(raw_data, dev, axis, evtype)
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

fn xi2_handle_motion_event(
  dpy: ptr, st: ref(XI2BackendState), raw_data: ptr, evtype: int
): void =
  if raw_data = the_null_ptr then ()
  else let
    val did = c_xi2_raw_deviceid(raw_data)
  in
    if (did < 0) || (did >= XI2_MAX_DEVICES) then ()
    else let
      val dev = xi2_dev_ref(st->devs, did)
      val () = if dev->deviceid = ~1 then xi2_refresh_devices_internal(dpy, st->devs) else ()
      val dev2 = xi2_dev_ref(st->devs, did)
    in
      if dev2->is_stylus > 0 then let
        val now = get_time_seconds()
        val () = xi2_process_stylus_event(raw_data, xi2_dev_ptr(st->devs, did), evtype, now)
      in () end
      else ()
    end
  end

fn xi2_dispatch_event_type(
  dpy: ptr, st: ref(XI2BackendState), p_xev: ptr, evtype: int
): void =
  if (evtype = XI2_HIERARCHY_CHANGED) || (evtype = XI2_DEVICE_CHANGED) then
    xi2_refresh_devices_internal(dpy, st->devs)
  else if (evtype = XI2_RAW_MOTION) || (evtype = XI2_RAW_BUTTON_PRESS) || (evtype = XI2_RAW_BUTTON_RELEASE) then
    xi2_handle_motion_event(dpy, st, c_xi2_cookie_data(p_xev), evtype)
  else ()

implement xi2_process_raw_event(dpy, p_xev) =
  if (dpy = the_null_ptr) || (p_xev = the_null_ptr) then 0
  else let
    val st = xi2_state_ref()
  in
    if c_xi2_cookie_extension(p_xev) != st->opcode then 0
    else if c_xi2_cookie_get_data(dpy, p_xev) = 0 then 0
    else let
      val evtype = c_xi2_cookie_evtype(p_xev)
      val () = xi2_dispatch_event_type(dpy, st, p_xev, evtype)
      val () = c_xi2_cookie_free_data(dpy, p_xev)
    in 1 end
  end
