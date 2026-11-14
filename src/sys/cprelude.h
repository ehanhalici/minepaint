#ifndef MINEPAINT_CPRELUDE_H
#define MINEPAINT_CPRELUDE_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h>
#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif
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
static inline void *mp_id_ptr(void *p) { return p; }
static inline long mp_ulint_to_lint(unsigned long x) { return (long)x; }
static inline void *mp_null_ptr(void) { return 0; }
static inline int mp_none_handle(void) { return -1; }
static inline int mp_handle_is_none(int h) { return h < 0; }
static inline int mp_id_int(int i) { return i; }
static inline int mp_ptr_is_null(void *p) { return p == 0; }
static inline int mp_snprintf_two_strings(char *buf, size_t n, const char *fmt,
                                          const char *s1, const char *s2) {
  return snprintf(buf, n, fmt, s1, s2);
}

/* Deterministic abort: one structured line on stderr, then exit. Never returns. */
static inline const char *anth_event_name(int code) {
  switch (code) {
  case 1: return "alloc_failed";
  case 2: return "contract_violation";
  default: return code >= 10 && code <= 18 ? "recursion_fuel" : "unknown";
  }
}
static inline const char *anth_site_name(int code) {
  switch (code) {
  case 15: return "dab_loop";
  default: return "";
  }
}
static inline void anth_die_c(int code) {
  fprintf(stderr, "{\"level\":\"fatal\",\"event\":\"%s\",\"site\":\"%s\"}\n",
          anth_event_name(code), anth_site_name(code));
  exit(70);
}
static inline void anth_die_void_c(int code) { anth_die_c(code); }
static inline int anth_die_int_c(int code) { anth_die_c(code); return 0; }
static inline double anth_die_dbl_c(int code) { anth_die_c(code); return 0.0; }
static inline void *anth_die_box_c(int code) { anth_die_c(code); return 0; }

#define MP_AIRLOCK_CAP 2000000

static inline int airlock_nat(int i) { return i >= 0 ? i : 0; }
static inline int airlock_int(int i) { return i; }
static inline int airlock_below(int i, int n) {
  return (i >= 0 && n > 0 && i < n) ? 1 : 0;
}
/* In-range index, else 0. Callers skip the access when airlock_below is 0. */
static inline int airlock_ix(int i, int n) {
  return airlock_below(i, n) ? i : 0;
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



static inline int airlock_cstr_len(const char *s) {
  if (!s) return 0;
  int n = 0;
  while (n < MP_AIRLOCK_CAP && s[n]) n++;
  return n;
}
static inline int airlock_cstr_at(const char *s, int i, int n) {
  return airlock_word(s, i, n);
}


#include "x11/event.cats"
#include "x11/xi2_raw.cats"

#endif
