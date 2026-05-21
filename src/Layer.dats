// src/Layer.dats
#define ATS_DYNLOADFLAG 0 // Sadece kütüphane/modül dosyası olduğunu belirtir
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// --- OpenGL C Başlık Dosyaları ---
// Bu blok üretilen C dosyasının en üstüne konur.
%{^
#include <GL/gl.h>
#include <GL/glext.h>
typedef struct {
  int width;
  int height;
  int initialized;
  unsigned int fbo;
  unsigned int texture;
} Layer_Record;
%}

staload UN = "prelude/SATS/unsafe.sats"

macdef GL_BLEND = $extval(int, "GL_BLEND")
macdef GL_SRC_ALPHA = $extval(int, "GL_SRC_ALPHA")
macdef GL_ONE_MINUS_SRC_ALPHA = $extval(int, "GL_ONE_MINUS_SRC_ALPHA")
macdef GL_QUADS = $extval(int, "GL_QUADS")
macdef GL_PROJECTION = $extval(int, "0x1701")
macdef GL_MODELVIEW = $extval(int, "0x1700")
macdef GL_LINE_LOOP = $extval(int, "2")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "16384")


// --- OpenGL Sabitleri ve Tipleri (ATS dünyasına tanıtım) ---

// $extype YERİNE, C'nin unsigned int tipini ATS'nin uint tipine doğrudan bağlıyoruz
typedef GLuint = uint

macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_RGBA = $extval(int, "GL_RGBA")
macdef GL_UNSIGNED_BYTE = $extval(int, "GL_UNSIGNED_BYTE")
macdef GL_FRAMEBUFFER = $extval(int, "GL_FRAMEBUFFER")
macdef GL_COLOR_ATTACHMENT0 = $extval(int, "GL_COLOR_ATTACHMENT0")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "16384")
macdef GL_TEXTURE_MIN_FILTER = $extval(int, "0x2801")
macdef GL_TEXTURE_MAG_FILTER = $extval(int, "0x2800")
macdef GL_LINEAR = $extval(int, "9729")

// --- OpenGL Fonksiyon İmzaları ---
// C'deki OpenGL fonksiyonlarını ATS tipleriyle güvence altına alıyoruz.
extern fun glGenTextures(n: int, textures: &GLuint? >> GLuint): void = "mac#glGenTextures"
extern fun glBindTexture(target: int, texture: GLuint): void = "mac#glBindTexture"
extern fun glTexImage2D(target: int, level: int, internalformat: int, width: int, height: int, border: int, format: int, atype: int, pixels: ptr): void = "mac#glTexImage2D"
extern fun glGenFramebuffers(n: int, fbos: &GLuint? >> GLuint): void = "mac#glGenFramebuffers"
extern fun glBindFramebuffer(target: int, framebuffer: GLuint): void = "mac#glBindFramebuffer"
extern fun glFramebufferTexture2D(target: int, attachment: int, textarget: int, texture: GLuint, level: int): void = "mac#glFramebufferTexture2D"
extern fun glDeleteTextures(n: int, textures: &GLuint): void = "mac#glDeleteTextures"
extern fun glDeleteFramebuffers(n: int, fbos: &GLuint): void = "mac#glDeleteFramebuffers"
extern fun glEnable(cap: int): void = "mac#"
extern fun glDisable(cap: int): void = "mac#"
extern fun glBlendFunc(sfactor: int, dfactor: int): void = "mac#"
extern fun glColor4f(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glBegin(mode: int): void = "mac#"
extern fun glEnd(): void = "mac#"
extern fun glTexCoord2f(s: float, t: float): void = "mac#"
extern fun glVertex2f(x: float, y: float): void = "mac#"
extern fun glTexParameteri(target: int, pname: int, param: int ): void = "mac#"
extern fun glClearColor( red: float, green:float, blue:float, alpha:float ): void = "mac#"
extern fun glClear(mask: int): void = "mac#"

// --- LAYER TİPİ VE MANTIĞI (FORMAL İSPATLI) ---

// datavtype: ATS'nin en güçlü silahı. Lineer (tüketilmesi zorunlu) bir struct üretir.
// Layer nesnesi genişlik, yükseklik, texture id ve fbo id tutar.

typedef Layer_Record = $extype_struct"Layer_Record" of {
  width= int,
  height= int,
  initialized= int,
  fbo= uint,
  texture= uint
}

extern fun malloc(n: size_t): ptr = "mac#"

extern fun glMatrixMode(m: int): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glLoadIdentity(): void = "mac#"
extern fun glOrtho(l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#"
extern fun glViewport(x: int, y: int, w: int, h: int): void = "mac#"

extern fun layer_bind_c(l: ptr): void = "ext#"
implement layer_bind_c(l) = let
  val r = $UN.cast{ref(Layer_Record)}(l)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, r->fbo)
  val () = glViewport(0, 0, r->width, r->height)
  val () = glMatrixMode(GL_PROJECTION)
  val () = glPushMatrix()
  val () = glLoadIdentity()
  val () = glOrtho(0.0, g0int2float(r->width), g0int2float(r->height), 0.0, ~1.0, 1.0)
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glLoadIdentity()
in () end

extern fun layer_unbind_c(l: ptr): void = "ext#"
implement layer_unbind_c(l) = let
  val () = glMatrixMode(GL_PROJECTION)
  val () = glPopMatrix()
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, 0u)
  val () = glViewport(0, 0, 800, 600)
in () end


extern fun layer_create_c(w: int, h: int): ptr = "ext#"
implement layer_create_c(w: int, h: int): ptr = let
  val p = malloc($extval(size_t, "sizeof(Layer_Record)"))
  val r = $UN.cast{ref(Layer_Record)}(p)
  val () = r->width := w
  val () = r->height := h
  val () = r->initialized := 1
  var tex_id: GLuint
  var fbo_id: GLuint
  val () = glGenTextures(1, tex_id)
  val () = glBindTexture(GL_TEXTURE_2D, tex_id)
  val () = glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, the_null_ptr)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  val () = glGenFramebuffers(1, fbo_id)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, fbo_id)
  val () = glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_id, 0)
  val () = glClearColor(0.0f, 0.0f, 0.0f, 0.0f)
  val () = glClear(GL_COLOR_BUFFER_BIT)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, 0u)
  val () = glBindTexture(GL_TEXTURE_2D, 0u)
  val () = r->texture := tex_id
  val () = r->fbo := fbo_id
in
  p
end

extern fun layer_drawOnScreen(l: ptr, w: int, h: int): void = "ext#"
implement layer_drawOnScreen(l, window_width, window_height) = let
  val layer_ref = $UN.cast{ref(Layer_Record)}(l)
  val is_init = layer_ref->initialized
in
  // Eğer başlatılmamışsa (0 ise) hiçbir şey yapma (return karşılığı)
  if is_init > 0 then let
    val tex_id = layer_ref->texture
    
    val () = glEnable(GL_TEXTURE_2D)
    val () = glBindTexture(GL_TEXTURE_2D, tex_id)
    
    val () = glEnable(GL_BLEND)
    val () = glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    
    val () = glColor4f(1.0f, 1.0f, 1.0f, 1.0f)
    val () = glBegin(GL_QUADS)
    
    // float dönüşümleri
    val w_f = g0int2float(window_width)
    val h_f = g0int2float(window_height)

    // Sol Alt
    val () = glTexCoord2f(0.0f, 0.0f)
    val () = glVertex2f(0.0f, h_f)
    
    // Sağ Alt
    val () = glTexCoord2f(1.0f, 0.0f)
    val () = glVertex2f(w_f, h_f)
    
    // Sağ Üst
    val () = glTexCoord2f(1.0f, 1.0f)
    val () = glVertex2f(w_f, 0.0f)
    
    // Sol Üst
    val () = glTexCoord2f(0.0f, 1.0f)
    val () = glVertex2f(0.0f, 0.0f)
    
    val () = glEnd()
    val () = glDisable(GL_TEXTURE_2D)
    val () = glDisable(GL_TEXTURE_2D)
  in () end else ()
end
