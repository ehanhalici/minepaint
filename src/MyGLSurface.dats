// src/MyGLSurface.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// Pointer aritmetiği ve unsafe işlemler için
staload UN = "prelude/SATS/unsafe.sats"

// --- 1. HARİCİ KÜTÜPHANE VE OPENGL TANIMLARI ---
%{^
#include <GL/gl.h>
#include <mypaint-surface.h>
#include <math.h>
#include <stdlib.h>

typedef struct {
    MyPaintSurface parent; // İlk eleman
    int is_erasing;
} MyGLSurface_Record;

// 1. ATS'nin ürettiği gerçek fonksiyonun prototipi (İlk parametre void* olarak düzeltildi)
extern int draw_dab_callback(void *self, float x, float y, float radius,
                             float color_r, float color_g, float color_b,
                             float opaque, float hardness, float alpha_eraser,
                             float aspect_ratio, float angle,
                             float lock_alpha, float colorize,
                             float snap, float zoom, float rot, float barrel);

// 2. Tip Uyuşmazlığını Çözen Arabulucu C Fonksiyonu
// Libmypaint'in tam olarak beklediği imza (MyPaintSurface*)
int draw_dab_c_wrapper(MyPaintSurface *self, float x, float y, float radius,
                       float color_r, float color_g, float color_b,
                       float opaque, float hardness, float alpha_eraser,
                       float aspect_ratio, float angle,
                       float lock_alpha, float colorize,
                       float snap, float zoom, float rot, float barrel) {
    // ATS fonksiyonunu çağırıp self pointer'ını (void*)'a cast ederek veriyoruz
    return draw_dab_callback((void*)self, x, y, radius,
                             color_r, color_g, color_b,
                             opaque, hardness, alpha_eraser,
                             aspect_ratio, angle,
                             lock_alpha, colorize,
                             snap, zoom, rot, barrel);
}

// 3. Oluşturucu
MyGLSurface_Record* mygl_surface_create_c() {
    MyGLSurface_Record* surf = (MyGLSurface_Record*)malloc(sizeof(MyGLSurface_Record));
    mypaint_surface_init(&(surf->parent));
    
    // Doğrudan ATS fonksiyonu yerine uyumlu C arabulucusunu bağlıyoruz
    surf->parent.draw_dab = draw_dab_c_wrapper;
    
    surf->is_erasing = 0;
    return surf;
}

// 4. Yok Edici
void mygl_surface_destroy_c(MyGLSurface_Record* surf) {
    if(surf) free(surf);
}

// 5. Değişken Güncelleyici
void mygl_surface_set_erasing(MyGLSurface_Record* surf, int erasing) {
    if(surf) surf->is_erasing = erasing;
}
%}



// OpenGL Sabitleri
macdef GL_BLEND = $extval(int, "GL_BLEND")
macdef GL_ZERO = $extval(int, "GL_ZERO")
macdef GL_ONE_MINUS_SRC_ALPHA = $extval(int, "GL_ONE_MINUS_SRC_ALPHA")
macdef GL_SRC_ALPHA = $extval(int, "GL_SRC_ALPHA")
macdef GL_ONE = $extval(int, "GL_ONE")
macdef GL_TRIANGLE_FAN = $extval(int, "GL_TRIANGLE_FAN")
macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_DEPTH_TEST = $extval(int, "GL_DEPTH_TEST")

// OpenGL Fonksiyonları
extern fun glEnable(cap: int): void = "mac#"
extern fun glDisable(cap: int): void = "mac#"
extern fun glBlendFunc(sfactor: int, dfactor: int): void = "mac#"
extern fun glBlendFuncSeparate(srcRGB: int, dstRGB: int, srcAlpha: int, dstAlpha: int): void = "mac#"
extern fun glColor4f(red: float, green: float, blue: float, alpha: float): void = "mac#"
extern fun glBegin(mode: int): void = "mac#"
extern fun glEnd(): void = "mac#"
extern fun glVertex2f(x: float, y: float): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glTranslatef(x: float, y: float, z: float): void = "mac#"
extern fun glRotatef(angle: float, x: float, y: float, z: float): void = "mac#"
extern fun glScalef(x: float, y: float, z: float): void = "mac#"

// Matematik Fonksiyonları
extern fun cosf(x: float): float = "mac#"
extern fun sinf(x: float): float = "mac#"

// Standart C Fonksiyonları (ATS üzerinden çağrılır)
extern fun malloc(size: size_t): ptr = "mac#"
extern fun free(p: ptr): void = "mac#"
extern fun memset(p: ptr, value: int, size: size_t): ptr = "mac#"

// --- 2. LİBMYPAINT TİP TANIMLARI ---

// MyPaint'in beklediği fonksiyon imzası
typedef MyPaintDrawDabFunc = (
  ptr, float, float, float, float, float, float, 
  float, float, float, float, float, float, 
  float, float, float, float, float
) -> int

// MyPaintSurface struct'ının ATS karşılığı (Bellek yerleşimi C ile aynıdır)
typedef MyPaintSurface_Record = @{
  draw_dab= MyPaintDrawDabFunc,
  get_color= ptr,
  begin_atomic= ptr,
  end_atomic= ptr,
  save_png= ptr,
  refcount= int,
  _pad= int,          // hizalama
  refcount_mutex= int
}

// Bizim genişletilmiş Surface yapımız
typedef MyGLSurface_Record = @{
  parent= MyPaintSurface_Record,
  is_erasing= int
}


// MyGLSurface nesnesini sızıntı yapamayacak "Lineer Opak Pointer" olarak tanımlıyoruz
absvtype mygl_surface_vtype = ptr

// FFI Köprüleri (Doğrudan C makrolarına bağlıyoruz)
extern fun mygl_surface_create(): mygl_surface_vtype = "mac#mygl_surface_create_c"
extern fun mygl_surface_destroy(surf: mygl_surface_vtype): void = "mac#mygl_surface_destroy_c"

// ! sembolü: "Bu nesneyi geçici olarak ödünç alıyorum, yok etmeyeceğim" demek
extern fun mygl_surface_set_erasing(surf: !mygl_surface_vtype, erasing: int): void = "mac#"

typedef glsurface_vtype = ptr

extern fun draw_dab_callback : MyPaintDrawDabFunc = "ext#"
extern fun glsurface_create(): glsurface_vtype = "ext#"
extern fun glsurface_destroy(s: glsurface_vtype): void = "ext#"
extern fun glsurface_set_erasing(s: glsurface_vtype, v: int): void = "ext#"


// --- 3. ÇİZİM MANTIĞI (PÜR ATS) ---

fun print_dot(
  is_erasing: int, radius: float, color_r: float, color_g: float, color_b: float, opaque: float, hardness: float
): void = let
  val () = glEnable(GL_BLEND)
  val () = if is_erasing > 0 then let
    val () = glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(0.0f, 0.0f, 0.0f, 1.0f)
  in () end else let
    val () = glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(color_r, color_g, color_b, opaque)
  in () end
  
  val () = glBegin(GL_TRIANGLE_FAN)
  val () = glVertex2f(0.0f, 0.0f)
  val edge_alpha = if is_erasing > 0 then 1.0f else opaque * hardness
  val () = glColor4f(color_r, color_g, color_b, edge_alpha)
  val segments = 24
  val PI = 3.1415926535f
  
  fun loop (i: int): void =
    if i <= segments then let
      val theta = 2.0f * PI * g0int2float(i) / g0int2float(segments)
      val dx = radius * cosf(theta)
      val dy = radius * sinf(theta)
      val () = glVertex2f(dx, dy)
    in loop (i + 1) end else ()
    
  val () = loop(0)
  val () = glEnd()
in end

// --- 4. CALLBACK IMPLEMENTASYONU ---

implement draw_dab_callback(self, x, y, radius, r, g, b, opaque, hardness, eraser, aspect, angle, lock, colorize, snap, zoom, rot, barrel): int = let
  val surf = $UN.cast{ref(MyGLSurface_Record)}(self)
  val is_erasing = surf->is_erasing
in
  if radius > 0.0001f then let
    val () = glDisable(GL_TEXTURE_2D)
    val () = glDisable(GL_DEPTH_TEST)
    val () = glPushMatrix()
    val () = glTranslatef(x, y, 0.0f)
    val angle_deg = angle * 180.0f / 3.14159265f
    val () = glRotatef(angle_deg, 0.0f, 0.0f, 1.0f)
    val () = if aspect > 1.0f then glScalef(1.0f, 1.0f / aspect, 1.0f)
             else if aspect < 1.0f then glScalef(aspect, 1.0f, 1.0f)
             else ()
    val () = print_dot(is_erasing, radius, r, g, b, opaque, hardness)
    val () = glPopMatrix()
  in () end else ();
  1
end


// --- 5. LIFECYCLE (OLUŞTURMA VE YOK ETME) ---


implement glsurface_create() = let
  val sz = $UN.cast{size_t}(sizeof<MyGLSurface_Record>)
  val p = malloc(sz)
  val () = assertloc(p > the_null_ptr)
  val _ = memset(p, 0, sz)

  val p1 = $UN.cast{ref(MyGLSurface_Record)}(p)
  val () = p1->parent.draw_dab := draw_dab_callback
  val () = p1->parent.refcount := 1
  val () = p1->is_erasing := 0
in
  $UN.cast{glsurface_vtype}(p)
end

implement glsurface_destroy(s) = let
  val () = free($UN.cast{ptr}(s))
in end


implement glsurface_set_erasing(s, v) = let
  val surf = $UN.cast{ref(MyGLSurface_Record)}(s)
  val () = surf->is_erasing := v
in end
