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

static inline int xi2_device_id(void *devs, int idx) {
  return ((XIDeviceInfo*)devs)[idx].deviceid;
}

static inline int xi2_device_is_master(void *devs, int idx) {
  int use = ((XIDeviceInfo*)devs)[idx].use;
  return (use == XIMasterPointer || use == XIMasterKeyboard) ? 1 : 0;
}

static inline char* xi2_device_name(void *devs, int idx) {
  return ((XIDeviceInfo*)devs)[idx].name ? ((XIDeviceInfo*)devs)[idx].name : "";
}

static inline int xi2_device_num_classes(void *devs, int idx) {
  return ((XIDeviceInfo*)devs)[idx].num_classes;
}

static inline int xi2_device_class_type(void *devs, int dev_idx, int class_idx) {
  XIAnyClassInfo *ci = ((XIDeviceInfo*)devs)[dev_idx].classes[class_idx];
  return ci ? ci->type : -1;
}

static inline int xi2_device_class_val_axis(void *devs, int dev_idx, int class_idx) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo*)(((XIDeviceInfo*)devs)[dev_idx].classes[class_idx]);
  return val ? val->number : -1;
}

static inline double xi2_device_class_val_min(void *devs, int dev_idx, int class_idx) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo*)(((XIDeviceInfo*)devs)[dev_idx].classes[class_idx]);
  return val ? val->min : 0.0;
}

static inline double xi2_device_class_val_max(void *devs, int dev_idx, int class_idx) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo*)(((XIDeviceInfo*)devs)[dev_idx].classes[class_idx]);
  return val ? val->max : 1.0;
}

static inline int xi2_device_class_val_label(Display *dpy, void *devs, int dev_idx, int class_idx, char *buf, int bufsz) {
  XIValuatorClassInfo *val = (XIValuatorClassInfo*)(((XIDeviceInfo*)devs)[dev_idx].classes[class_idx]);
  if (!val || val->label == None) return 0;
  char *aname = XGetAtomName(dpy, val->label);
  if (!aname) return 0;
  strncpy(buf, aname, bufsz - 1);
  buf[bufsz - 1] = '\0';
  XFree(aname);
  return 1;
}

static inline int xi2_cookie_extension(void *ev) {
  return ((XEvent*)ev)->xcookie.extension;
}

static inline int xi2_cookie_get_data(Display *dpy, void *ev) {
  return XGetEventData(dpy, &(((XEvent*)ev)->xcookie)) ? 1 : 0;
}

static inline void xi2_cookie_free_data(Display *dpy, void *ev) {
  XFreeEventData(dpy, &(((XEvent*)ev)->xcookie));
}

static inline int xi2_cookie_evtype(void *ev) {
  return ((XEvent*)ev)->xcookie.evtype;
}

static inline void* xi2_cookie_data(void *ev) {
  return ((XEvent*)ev)->xcookie.data;
}

static inline int xi2_raw_deviceid(void *data) {
  return ((XIRawEvent*)data)->deviceid;
}

static inline int xi2_raw_has_axis(void *data, int axis) {
  XIRawEvent *raw = (XIRawEvent*)data;
  return (raw && axis >= 0 && XIMaskIsSet(raw->valuators.mask, axis)) ? 1 : 0;
}

static inline double xi2_raw_read_axis(void *data, int axis) {
  XIRawEvent *raw = (XIRawEvent*)data;
  if (!raw || axis < 0 || !XIMaskIsSet(raw->valuators.mask, axis)) return 0.0;
  int idx = 0;
  for (int a = 0; a < axis; a++) {
    if (XIMaskIsSet(raw->valuators.mask, a)) idx++;
  }
  if (raw->valuators.values && raw->valuators.values[idx] > 0.0) {
    return raw->valuators.values[idx];
  }
  if (raw->raw_values && raw->raw_values[idx] > 0.0) {
    return raw->raw_values[idx];
  }
  if (raw->valuators.values) {
    return raw->valuators.values[idx];
  }
  if (raw->raw_values) {
    return raw->raw_values[idx];
  }
  return 0.0;
}

#endif /* MINEPAINT_XI2_RAW_CATS */
