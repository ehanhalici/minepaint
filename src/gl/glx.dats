#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

macdef GLX_RGBA = $extval(int, "GLX_RGBA")
macdef GLX_DEPTH_SIZE = $extval(int, "GLX_DEPTH_SIZE")
macdef GLX_DOUBLEBUFFER = $extval(int, "GLX_DOUBLEBUFFER")
macdef GL_TRUE = $extval(int, "GL_TRUE")

extern fun glXChooseVisual(dpy: ptr, screen: int, attrib: ptr): ptr = "mac#"
extern fun glXCreateContext(dpy: ptr, vi: ptr, share: ptr, direct: int): ptr = "mac#"
extern fun glXMakeCurrent(dpy: ptr, drawable: ulint, ctx: ptr): int = "mac#"
extern fun glXSwapBuffers(dpy: ptr, drawable: ulint): void = "mac#"
extern fun glXDestroyContext(dpy: ptr, ctx: ptr): void = "mac#"
