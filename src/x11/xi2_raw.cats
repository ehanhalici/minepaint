#ifndef MINEPAINT_XI2_RAW_CATS
#define MINEPAINT_XI2_RAW_CATS

#include <X11/Xlib.h>
#include <X11/extensions/XInput2.h>
#include <string.h>

static inline int xi2_query_extension(Display *dpy, int *opcode_out) {
  int ev, err;
  return XQueryExtension(dpy, "XInputExtension", opcode_out, &ev, &err) ? 1 : 0;
}

static inline int xi2_query_version(Display *dpy, int major, int minor) {
  int maj = major, min = minor;
  return (XIQueryVersion(dpy, &maj, &min) == Success) ? 1 : 0;
}

static inline int xi2_select_root_events(Display *dpy) {
  Window root = DefaultRootWindow(dpy);
  XIEventMask evmasks[1];
  unsigned char m1[XIMaskLen(XI_LASTEVENT)];
  memset(m1, 0, sizeof(m1));

  evmasks[0].deviceid = XIAllDevices;
  evmasks[0].mask_len = sizeof(m1);
  evmasks[0].mask = m1;
  XISetMask(m1, XI_RawMotion);
  XISetMask(m1, XI_RawButtonPress);
  XISetMask(m1, XI_RawButtonRelease);
  XISetMask(m1, XI_DeviceChanged);
  XISetMask(m1, XI_HierarchyChanged);

  return (XISelectEvents(dpy, root, evmasks, 1) == Success) ? 1 : 0;
}

static inline void* xi2_query_devices(Display *dpy, int *num_devs_out) {
  return (void*)XIQueryDevice(dpy, XIAllDevices, num_devs_out);
}

static inline void xi2_free_devices(void *devs) {
  if (devs) XIFreeDeviceInfo((XIDeviceInfo*)devs);
}

static inline XIDeviceInfo *xi2_dev_at(void *devs, int idx) {
  if (!devs || !airlock_below(idx, MP_AIRLOCK_CAP)) return 0;
  return &((XIDeviceInfo *)devs)[idx];
}

static inline XIAnyClassInfo *xi2_class_at(void *devs, int dev_idx, int class_idx) {
  XIDeviceInfo *d = xi2_dev_at(devs, dev_idx);
  if (!d || !d->classes || !airlock_below(class_idx, d->num_classes)) return 0;
  return d->classes[class_idx];
}

static inline int xi2_device_id(void *devs, int idx) {
  XIDeviceInfo *d = xi2_dev_at(devs, idx);
  return d ? d->deviceid : 0;
}

static inline int xi2_device_is_master(void *devs, int idx) {
  XIDeviceInfo *d = xi2_dev_at(devs, idx);
  if (!d) return 0;
  return (d->use == XIMasterPointer || d->use == XIMasterKeyboard) ? 1 : 0;
}

static inline char *xi2_device_name(void *devs, int idx) {
  XIDeviceInfo *d = xi2_dev_at(devs, idx);
  if (!d || !d->name) return "";
  return d->name;
}

static inline int xi2_device_num_classes(void *devs, int idx) {
  XIDeviceInfo *d = xi2_dev_at(devs, idx);
  return d ? d->num_classes : 0;
}

static inline int xi2_device_class_type(void *devs, int dev_idx, int class_idx) {
  XIAnyClassInfo *ci = xi2_class_at(devs, dev_idx, class_idx);
  return ci ? ci->type : -1;
}

static inline int xi2_device_class_val_axis(void *devs, int dev_idx, int class_idx) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo *)xi2_class_at(devs, dev_idx, class_idx);
  return val ? val->number : -1;
}

static inline double xi2_device_class_val_min(void *devs, int dev_idx, int class_idx) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo *)xi2_class_at(devs, dev_idx, class_idx);
  return val ? val->min : 0.0;
}

static inline double xi2_device_class_val_max(void *devs, int dev_idx, int class_idx) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo *)xi2_class_at(devs, dev_idx, class_idx);
  return val ? val->max : 1.0;
}

static inline int xi2_device_class_val_label(Display *dpy, void *devs, int dev_idx, int class_idx, char *buf, int bufsz) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo *)xi2_class_at(devs, dev_idx, class_idx);
  if (!val || val->label == None || !buf || bufsz <= 0) return 0;
  char *aname = XGetAtomName(dpy, val->label);
  if (!aname) return 0;
  strncpy(buf, aname, (size_t)(bufsz - 1));
  buf[bufsz - 1] = '\0';
  XFree(aname);
  return 1;
}

static inline int xi2_cookie_extension(void *ev) {
  if (!ev) return 0;
  return ((XEvent*)ev)->xcookie.extension;
}

static inline int xi2_cookie_get_data(Display *dpy, void *ev) {
  if (!dpy || !ev) return 0;
  return XGetEventData(dpy, &(((XEvent*)ev)->xcookie)) ? 1 : 0;
}

static inline void xi2_cookie_free_data(Display *dpy, void *ev) {
  if (!dpy || !ev) return;
  XFreeEventData(dpy, &(((XEvent*)ev)->xcookie));
}

static inline int xi2_cookie_evtype(void *ev) {
  if (!ev) return 0;
  return ((XEvent*)ev)->xcookie.evtype;
}

static inline void* xi2_cookie_data(void *ev) {
  if (!ev) return 0;
  return ((XEvent*)ev)->xcookie.data;
}

static inline int xi2_raw_deviceid(void *data) {
  if (!data) return 0;
  return ((XIRawEvent*)data)->deviceid;
}

static inline int xi2_mask_popcount(const unsigned char *mask, int mask_len) {
  if (!mask || mask_len <= 0) return 0;
  int n = 0;
  for (int i = 0; i < mask_len; i++) {
    unsigned char b = (unsigned char)airlock_word(mask, i, mask_len);
    while (b) { n += b & 1; b = (unsigned char)(b >> 1); }
  }
  return n;
}

static inline int xi2_raw_has_axis(void *data, int axis) {
  XIRawEvent *raw = (XIRawEvent*)data;
  return (raw && airlock_nat(axis) == axis && raw->valuators.mask &&
          XIMaskIsSet(raw->valuators.mask, axis)) ? 1 : 0;
}

static inline double xi2_raw_axis_at(const double *vals, int idx, int nval) {
  if (!vals || !airlock_below(idx, nval)) return 0.0;
  return vals[idx];
}

static inline double xi2_raw_read_axis(void *data, int axis) {
  XIRawEvent *raw = (XIRawEvent*)data;
  if (!raw || airlock_nat(axis) != axis || !raw->valuators.mask ||
      !XIMaskIsSet(raw->valuators.mask, axis)) return 0.0;
  int idx = 0;
  for (int a = 0; a < axis; a++) {
    if (XIMaskIsSet(raw->valuators.mask, a)) idx++;
  }
  int nval = xi2_mask_popcount((const unsigned char *)raw->valuators.mask, raw->valuators.mask_len);
  double v = xi2_raw_axis_at(raw->valuators.values, idx, nval);
  if (v > 0.0) return v;
  double r = xi2_raw_axis_at(raw->raw_values, idx, nval);
  if (r > 0.0) return r;
  if (raw->valuators.values && airlock_below(idx, nval)) return v;
  if (raw->raw_values && airlock_below(idx, nval)) return r;
  return 0.0;
}

#endif /* MINEPAINT_XI2_RAW_CATS */
