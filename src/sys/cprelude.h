#ifndef MINEPAINT_CPRELUDE_H
#define MINEPAINT_CPRELUDE_H

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <GL/gl.h>
#include <GL/glext.h>
#include <GL/glx.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/cursorfont.h>

typedef struct timeval mp_timeval;

static inline float mp_uint_to_float(unsigned int x) { return (float)x; }
static inline unsigned int mp_float_to_uint(float x) { return (unsigned int)x; }
static inline unsigned short mp_uint_to_u16(unsigned int x) { return (unsigned short)x; }
static inline void *mp_id_ptr(void *p) { return p; }
static inline long mp_ulint_to_lint(unsigned long x) { return (long)x; }
static inline void *mp_null_ptr(void) { return 0; }
static inline int mp_ptr_is_null(void *p) { return p == 0; }

#define MP_AIRLOCK_CAP 2000000

static inline int airlock_nat(int i) { return i >= 0 ? i : 0; }
static inline int airlock_pos(int i) { return i > 0 ? i : 0; }
static inline int airlock_below(int i, int n) {
  return (i >= 0 && n > 0 && i < n) ? 1 : 0;
}
static inline int airlock_span(int i, int len, int n) {
  if (i < 0 || len < 0 || n < 0 || i > n) return 0;
  if (len > n - i) return 0;
  return 1;
}
static inline int airlock_word(const void *p, int i, int n) {
  if (!p || !airlock_below(i, n)) return 0;
  return (int)((const unsigned char *)p)[i];
}

static inline float mp_fget(const float *p, int i) { return p[i]; }
static inline void mp_fset(float *p, int i, float v) { p[i] = v; }
static inline int mp_iget(const int *p, int i) { return p[i]; }
static inline void mp_iset(int *p, int i, int v) { p[i] = v; }
static inline unsigned short mp_u16get(const unsigned short *p, int i) { return p[i]; }
static inline void *mp_u16_add(void *p, int n) { return (void *)((unsigned short *)p + n); }
static inline void *mp_dbl_add(void *p, int n) { return (void *)((double *)p + n); }
static inline void *mp_flt_add(void *p, int n) { return (void *)((float *)p + n); }
static inline void *mp_byte_add(void *p, int n) { return (void *)((unsigned char *)p + n); }
static inline void mp_u16set(unsigned short *p, int i, unsigned short v) { p[i] = v; }
static inline void *mp_pget(void **p, int i) { return p[i]; }
static inline void mp_pset(void **p, int i, void *v) { p[i] = v; }
static inline double mp_dget(const double *p, int i) { return p[i]; }
static inline void mp_dset(double *p, int i, double v) { p[i] = v; }


static inline float airlock_fget(const void *p, int i) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return 0.f;
  return mp_fget((const float *)p, i);
}
static inline void airlock_fset(void *p, int i, float v) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return;
  mp_fset((float *)p, i, v);
}
static inline int airlock_iget(const void *p, int i) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return 0;
  return mp_iget((const int *)p, i);
}
static inline void airlock_iset(void *p, int i, int v) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return;
  mp_iset((int *)p, i, v);
}
static inline unsigned short airlock_u16get(const void *p, int i) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return 0;
  return mp_u16get((const unsigned short *)p, i);
}
static inline void airlock_u16set(void *p, int i, unsigned short v) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return;
  mp_u16set((unsigned short *)p, i, v);
}
static inline void *airlock_pget(void *p, int i) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return 0;
  return mp_pget((void **)p, i);
}
static inline void airlock_pset(void *p, int i, void *v) {
  if (!p || !airlock_below(i, MP_AIRLOCK_CAP)) return;
  mp_pset((void **)p, i, v);
}
static inline double airlock_dget_n(const void *p, int i, int n) {
  if (!p || !airlock_below(i, n)) return 0.0;
  return mp_dget((const double *)p, i);
}
static inline void airlock_dset_n(void *p, int i, int n, double v) {
  if (!p || !airlock_below(i, n)) return;
  mp_dset((double *)p, i, v);
}
static inline int airlock_iget_n(const void *p, int i, int n) {
  if (!p || !airlock_below(i, n)) return 0;
  return mp_iget((const int *)p, i);
}
static inline void airlock_iset_n(void *p, int i, int n, int v) {
  if (!p || !airlock_below(i, n)) return;
  mp_iset((int *)p, i, v);
}
static inline double airlock_dget(const void *p, int i) {
  return airlock_dget_n(p, i, MP_AIRLOCK_CAP);
}
static inline void airlock_dset(void *p, int i, double v) {
  airlock_dset_n(p, i, MP_AIRLOCK_CAP, v);
}

static inline int mp_rect_get_x(const void *p) { return airlock_iget_n(p, 0, 4); }
static inline int mp_rect_get_y(const void *p) { return airlock_iget_n(p, 1, 4); }
static inline int mp_rect_get_w(const void *p) { return airlock_iget_n(p, 2, 4); }
static inline int mp_rect_get_h(const void *p) { return airlock_iget_n(p, 3, 4); }
static inline void mp_rect_set(void *p, int x, int y, int w, int h) {
  airlock_iset_n(p, 0, 4, x);
  airlock_iset_n(p, 1, 4, y);
  airlock_iset_n(p, 2, 4, w);
  airlock_iset_n(p, 3, 4, h);
}

#endif
