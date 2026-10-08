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

#endif
