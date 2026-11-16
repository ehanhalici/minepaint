#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "x11/display_box.sats"
staload "x11/visual_box.sats"
staload "gl/glctx_box.sats"

macdef GLX_RGBA = $extval(int, "GLX_RGBA")
macdef GLX_DEPTH_SIZE = $extval(int, "GLX_DEPTH_SIZE")
macdef GLX_DOUBLEBUFFER = $extval(int, "GLX_DOUBLEBUFFER")
macdef GL_TRUE = $extval(int, "GL_TRUE")

// Ham ptr donusleri (null = basarisiz) yalniz window.dats'ta sahipli Vis/GlCtx'e muhurlenir.
extern fun glXChooseVisual(dpy: !Display, screen: int, attrib: ptr): ptr = "mac#"
extern fun glXCreateContext(dpy: !Display, vi: !Vis, share: ptr, direct: int): ptr = "mac#"
extern fun glXMakeCurrent(dpy: !Display, drawable: ulint, ctx: !GlCtx): int = "mac#"
extern fun glXReleaseCurrent(dpy: !Display): int = "mac#mp_glx_release"
extern fun glXSwapBuffers(dpy: !Display, drawable: ulint): void = "mac#"
extern fun glXDestroyContext(dpy: !Display, ctx: GlCtx): void = "mac#"
