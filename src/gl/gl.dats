#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

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

extern fun glGenTextures(n: int, textures: ptr): void = "mac#"
extern fun glBindTexture(target: int, texture: uint): void = "mac#"
extern fun glTexImage2D(target: int, level: int, internalformat: int, width: int, height: int, border: int, format: int, atype: int, pixels: ptr): void = "mac#"
extern fun glTexParameteri(target: int, pname: int, param: int): void = "mac#"
extern fun glGenFramebuffers(n: int, fbos: ptr): void = "mac#"
extern fun glBindFramebuffer(target: int, framebuffer: uint): void = "mac#"
extern fun glFramebufferTexture2D(target: int, attachment: int, textarget: int, texture: uint, level: int): void = "mac#"
extern fun glDeleteTextures(n: int, textures: ptr): void = "mac#"
extern fun glDeleteFramebuffers(n: int, fbos: ptr): void = "mac#"
extern fun glEnable(cap: int): void = "mac#"
extern fun glDisable(cap: int): void = "mac#"
extern fun glBlendFunc(sfactor: int, dfactor: int): void = "mac#"
extern fun glColor3f(r: float, g: float, b: float): void = "mac#"
extern fun glColor4f(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glPointSize(sz: float): void = "mac#"
extern fun glBegin(mode: int): void = "mac#"
extern fun glEnd(): void = "mac#"
extern fun glTexCoord2f(s: float, t: float): void = "mac#"
extern fun glVertex2f(x: float, y: float): void = "mac#"
extern fun glClearColor(red: float, green: float, blue: float, alpha: float): void = "mac#"
extern fun glClear(mask: int): void = "mac#"
extern fun glViewport(x: int, y: int, w: int, h: int): void = "mac#"
extern fun glMatrixMode(m: int): void = "mac#"
extern fun glLoadIdentity(): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glOrtho(l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#"
extern fun glTranslatef(x: float, y: float, z: float): void = "mac#"
extern fun glRotatef(angle: float, x: float, y: float, z: float): void = "mac#"
extern fun glScalef(x: float, y: float, z: float): void = "mac#"
