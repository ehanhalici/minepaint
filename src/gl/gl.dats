#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/cast_box.sats"
staload "gl/gl_io.sats"

macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_RGBA = $extval(int, "GL_RGBA")
macdef GL_UNSIGNED_BYTE = $extval(int, "GL_UNSIGNED_BYTE")
macdef GL_FRAMEBUFFER = $extval(int, "GL_FRAMEBUFFER")
macdef GL_COLOR_ATTACHMENT0 = $extval(int, "GL_COLOR_ATTACHMENT0")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "GL_COLOR_BUFFER_BIT")
macdef GL_TEXTURE_MIN_FILTER = $extval(int, "GL_TEXTURE_MIN_FILTER")
macdef GL_TEXTURE_MAG_FILTER = $extval(int, "GL_TEXTURE_MAG_FILTER")
macdef GL_LINEAR = $extval(int, "GL_LINEAR")
macdef GL_BLEND = $extval(int, "GL_BLEND")
macdef GL_SRC_ALPHA = $extval(int, "GL_SRC_ALPHA")
macdef GL_ONE_MINUS_SRC_ALPHA = $extval(int, "GL_ONE_MINUS_SRC_ALPHA")
macdef GL_QUADS = $extval(int, "GL_QUADS")
macdef GL_QUAD_STRIP = $extval(int, "GL_QUAD_STRIP")
macdef GL_LINE_LOOP = $extval(int, "GL_LINE_LOOP")
macdef GL_TRIANGLE_FAN = $extval(int, "GL_TRIANGLE_FAN")
macdef GL_POINTS = $extval(int, "GL_POINTS")
macdef GL_PROJECTION = $extval(int, "GL_PROJECTION")
macdef GL_MODELVIEW = $extval(int, "GL_MODELVIEW")
macdef GL_DEPTH_TEST = $extval(int, "GL_DEPTH_TEST")
macdef GL_ZERO = $extval(int, "GL_ZERO")
macdef GL_ONE = $extval(int, "GL_ONE")


// --- Tekil nesne uretim/yikim sarmalayicilari (C cikis parametresi sinirda kalir) ---
implement gl_gen_texture(pf | ) = let
  var id: uint = 0u
  val () = glGenTextures(pf | 1, ptr_forget(addr@(id)))
in id end

implement gl_gen_framebuffer(pf | ) = let
  var id: uint = 0u
  val () = glGenFramebuffers(pf | 1, ptr_forget(addr@(id)))
in id end

implement gl_delete_texture(pf | id) = let
  var v: uint = id
in glDeleteTextures(pf | 1, ptr_forget(addr@(v))) end

implement gl_delete_framebuffer(pf | id) = let
  var v: uint = id
in glDeleteFramebuffers(pf | 1, ptr_forget(addr@(v))) end
