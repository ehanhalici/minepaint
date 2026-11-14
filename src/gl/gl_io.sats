// src/gl/gl_io.sats
// GL "IO" etkisi: her GL cagrisi GL_IO kanitini ODUNC alir. Kanit yalniz baglam aktifken var
// (window.dats: glXMakeCurrent basarisindan sonra uretilir, baglam birakilmadan once tuketilir).
// Boylece GL temasi imzada gorunur; saf fonksiyonlarin imzasinda GL_IO yoktur. Kanitlar derlemede
// silinir: calisma zamani maliyeti sifirdir. `gl*` bildirimleri YALNIZ bu dosyadadir (kural R9).
staload "sys/capability.sats"

stadef GL_IO = CAP(KIND_GL, 0)

fun glBegin(pf: !GL_IO | mode: int): void = "mac#glBegin"
fun glBindFramebuffer(pf: !GL_IO | target: int, framebuffer: uint): void = "mac#glBindFramebuffer"
fun glBindTexture(pf: !GL_IO | target: int, texture: uint): void = "mac#glBindTexture"
fun glBlendFunc(pf: !GL_IO | sfactor: int, dfactor: int): void = "mac#glBlendFunc"
fun glClear(pf: !GL_IO | mask: int): void = "mac#glClear"
fun glClearColor(pf: !GL_IO | r: float, g: float, b: float, a: float): void = "mac#glClearColor"
fun glColor3f(pf: !GL_IO | r: float, g: float, b: float): void = "mac#glColor3f"
fun glColor4f(pf: !GL_IO | r: float, g: float, b: float, a: float): void = "mac#glColor4f"
fun glDeleteFramebuffers(pf: !GL_IO | n: int, fbos: ptr): void = "mac#glDeleteFramebuffers"
fun glDeleteTextures(pf: !GL_IO | n: int, textures: ptr): void = "mac#glDeleteTextures"
fun glDisable(pf: !GL_IO | cap: int): void = "mac#glDisable"
fun glEnable(pf: !GL_IO | cap: int): void = "mac#glEnable"
fun glEnd(pf: !GL_IO | ): void = "mac#glEnd"
fun glFramebufferTexture2D(pf: !GL_IO | target: int, attachment: int, textarget: int, texture: uint, level: int): void = "mac#glFramebufferTexture2D"
fun glGenFramebuffers(pf: !GL_IO | n: int, fbos: ptr): void = "mac#glGenFramebuffers"
fun glGenTextures(pf: !GL_IO | n: int, textures: ptr): void = "mac#glGenTextures"
fun glLoadIdentity(pf: !GL_IO | ): void = "mac#glLoadIdentity"
fun glMatrixMode(pf: !GL_IO | m: int): void = "mac#glMatrixMode"
fun glOrtho(pf: !GL_IO | l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#glOrtho"
fun glPointSize(pf: !GL_IO | sz: float): void = "mac#glPointSize"
fun glPopMatrix(pf: !GL_IO | ): void = "mac#glPopMatrix"
fun glPushMatrix(pf: !GL_IO | ): void = "mac#glPushMatrix"
fun glRotatef(pf: !GL_IO | angle: float, x: float, y: float, z: float): void = "mac#glRotatef"
fun glScalef(pf: !GL_IO | x: float, y: float, z: float): void = "mac#glScalef"
fun glTexCoord2f(pf: !GL_IO | s: float, t: float): void = "mac#glTexCoord2f"
fun glTexImage2D(pf: !GL_IO | target: int, level: int, internalformat: int, width: int, height: int, border: int, format: int, atype: int, pixels: ptr): void = "mac#glTexImage2D"
fun glTexParameteri(pf: !GL_IO | target: int, pname: int, param: int): void = "mac#glTexParameteri"
fun glTranslatef(pf: !GL_IO | x: float, y: float, z: float): void = "mac#glTranslatef"
fun glVertex2f(pf: !GL_IO | x: float, y: float): void = "mac#glVertex2f"
fun glViewport(pf: !GL_IO | x: int, y: int, w: int, h: int): void = "mac#glViewport"

// Tekil nesne uretim/yikim sarmalayicilari (C cikis parametresi gl.dats icinde kalir).
fun gl_gen_texture(pf: !GL_IO | ): uint = "ext#gl_gen_texture"
fun gl_gen_framebuffer(pf: !GL_IO | ): uint = "ext#gl_gen_framebuffer"
fun gl_delete_texture(pf: !GL_IO | id: uint): void = "ext#gl_delete_texture"
fun gl_delete_framebuffer(pf: !GL_IO | id: uint): void = "ext#gl_delete_framebuffer"
