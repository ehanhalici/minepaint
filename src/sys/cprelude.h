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

static inline float mp_fget(const float *p, int i) { return p[i]; }
static inline void mp_fset(float *p, int i, float v) { p[i] = v; }
static inline int mp_iget(const int *p, int i) { return p[i]; }
static inline void mp_iset(int *p, int i, int v) { p[i] = v; }
static inline unsigned short mp_u16get(const unsigned short *p, int i) { return p[i]; }
static inline void mp_u16set(unsigned short *p, int i, unsigned short v) { p[i] = v; }
static inline void *mp_pget(void **p, int i) { return p[i]; }
static inline void mp_pset(void **p, int i, void *v) { p[i] = v; }
static inline double mp_dget(const double *p, int i) { return p[i]; }
static inline void mp_dset(double *p, int i, double v) { p[i] = v; }

static inline int mp_rect_get_x(const void *p) { return ((const int *)p)[0]; }
static inline int mp_rect_get_y(const void *p) { return ((const int *)p)[1]; }
static inline int mp_rect_get_w(const void *p) { return ((const int *)p)[2]; }
static inline int mp_rect_get_h(const void *p) { return ((const int *)p)[3]; }
static inline void mp_rect_set(void *p, int x, int y, int w, int h) {
  int *r = (int *)p;
  r[0] = x;
  r[1] = y;
  r[2] = w;
  r[3] = h;
}

#endif
