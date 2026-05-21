// src/MyCanvas.dats

#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"
staload "./MyGLSurface.dats"
staload "./Layer.dats"
// --- 1. C KÜTÜPHANE BAŞLIKLARI (Sadece Include, Fonksiyon Yok) ---
%{^

#include <GL/gl.h>
#include <mypaint-brush.h>
#include <mypaint-surface.h>
#include <math.h>
#include <stdlib.h>

typedef struct {
  void* win; void* brush; void* surf; void* layer;
  float cam_x; float cam_y; float zoom;
  int lw; int lh;
  void* q;
} canvas_state_record;
// GCC için doğrudan C cast makrolarımız (ATS bunlara dokunamaz)
#define my_f2i(x) ((int)(x))
#define my_i2f(x) ((float)(x))

extern void layer_drawOnScreen(void* l, int w, int h);
extern int fltk_event_x(void);
extern int fltk_event_y(void);
extern double ats_get_current_time(void);
extern void fltk_make_current(void* win);
extern void fltk_canvas_redraw(void* win);
// MyGLSurface'den gelen C fonksiyonlarının prototipleri (GCC'nin bilmesi için)
extern void* mygl_surface_create_c(void);
extern void mygl_surface_destroy_c(void* surf);
extern void mygl_surface_set_erasing(void* surf, int erasing);

// C tarafında hızlı RGB'den HSV'ye dönüşüm
void my_rgb_to_hsv(float r, float g, float b, float *h, float *s, float *v) {
    float max = r > g ? (r > b ? r : b) : (g > b ? g : b);
    float min = r < g ? (r < b ? r : b) : (g < b ? g : b);
    *v = max;
    if (max == 0.0f) { *s = 0.0f; *h = 0.0f; return; }
    *s = (max - min) / max;
    if (max == min) { *h = 0.0f; return; }
    
    if (max == r) *h = (g - b) / (max - min) * 60.0f;
    else if (max == g) *h = (2.0f + (b - r) / (max - min)) * 60.0f;
    else *h = (4.0f + (r - g) / (max - min)) * 60.0f;
    
    if (*h < 0.0f) *h += 360.0f;
    *h = *h / 360.0f; // MyPaint 0.0 - 1.0 aralığı ister
}

%}

typedef canvas_state_record = $extype_struct"canvas_state_record" of {
  win= ptr, brush= ptr, surf= ptr, layer= ptr,
  cam_x= float, cam_y= float, zoom= float,
  lw= int, lh= int, q= ptr
}


// --- 2. ATS FFI İMZALARI VE SABİTLER ---

macdef GL_PROJECTION = $extval(int, "0x1701")
macdef GL_MODELVIEW = $extval(int, "0x1700")
macdef GL_LINE_LOOP = $extval(int, "2")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "16384")

macdef MYPAINT_BRUSH_SETTING_OPAQUE = $extval(int, "MYPAINT_BRUSH_SETTING_OPAQUE")
macdef MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC = $extval(int, "MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC")
macdef MYPAINT_BRUSH_SETTING_HARDNESS = $extval(int, "MYPAINT_BRUSH_SETTING_HARDNESS")
macdef MYPAINT_BRUSH_SETTING_SLOW_TRACKING = $extval(int, "MYPAINT_BRUSH_SETTING_SLOW_TRACKING")
macdef MYPAINT_BRUSH_SETTING_COLOR_H = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_H")
macdef MYPAINT_BRUSH_SETTING_COLOR_S = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_S")
macdef MYPAINT_BRUSH_SETTING_COLOR_V = $extval(int, "MYPAINT_BRUSH_SETTING_COLOR_V")

// '&' referans sembolü ile C'deki pointer (*) karşılığını ATS'ye anlatıyoruz
extern fun my_rgb_to_hsv(r: float, g: float, b: float, h: &float? >> float, s: &float? >> float, v: &float? >> float): void = "mac#"
extern fun malloc(n: size_t): ptr = "mac#"
extern fun glMatrixMode(m: int): void = "mac#"
extern fun glLoadIdentity(): void = "mac#"
extern fun glOrtho(l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glBegin(m: int): void = "mac#"
extern fun glEnd(): void = "mac#"
extern fun glVertex2f(x: float, y: float): void = "mac#"
extern fun glColor4f(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glViewport(x: int, y: int, w: int, h: int): void = "mac#"
extern fun glClearColor(r: float, g: float, b: float, a: float): void = "mac#"
extern fun glClear(mask: int): void = "mac#"
extern fun glTranslatef(x: float, y: float, z: float): void = "mac#"
extern fun glScalef(x: float, y: float, z: float): void = "mac#"
extern fun mypaint_brush_stroke_to(
  brush: ptr, surf: ptr, 
  x: float, y: float, pressure: float, 
  xtilt: float, ytilt: float, dtime: double, 
  viewzoom: float, viewrotation: float, barrel_rotation: float, dir: int
): int = "mac#"
extern fun mypaint_brush_reset(brush: ptr): void = "mac#"
extern fun mypaint_brush_set_base_value(brush: ptr, setting: int, value: float): void = "mac#"
extern fun fltk_canvas_redraw(win: ptr): void = "mac#"
extern fun layer_drawOnScreen(l: ptr, w: int, h: int): void = "mac#"
extern fun sqrtf(x: float): float = "mac#"
extern fun powf(x: float, y: float): float = "mac#"
extern fun ats_get_current_time(): double = "mac#"
extern fun fltk_event_x(): int = "mac#"
extern fun fltk_event_y(): int = "mac#"
extern fun f2i(f: float): int = "mac#my_f2i"
extern fun i2f(i: int): float = "mac#my_i2f"
extern fun fltk_make_current(win: ptr): void = "mac#"

// --- 3. LİNEER VERİ YAPILARI ---
vtypedef input_point = @{ x= float, y= float, pressure= float, time= double }

datavtype point_queue =
  | QueueNil of ()
  | QueueCons of (input_point, point_queue)


// --- 4. SAF ATS İLE EKRAN VE KAMERA YÖNETİMİ ---
fun draw_camera_setup(): void = let
  val () = glMatrixMode(GL_PROJECTION)
  val () = glLoadIdentity()
  val () = glOrtho(0.0, 800.0, 600.0, 0.0, ~1.0, 1.0)
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glLoadIdentity()
  val () = glPushMatrix()
in end

fun draw_border(layer_w: int, layer_h: int): void = let
  val lw_f = g0int2float(layer_w)
  val lh_f = g0int2float(layer_h)
  val () = glColor4f(0.20f, 0.20f, 0.20f, 1.0f)
  val () = glBegin(GL_LINE_LOOP)
  val () = glVertex2f(0.0f, 0.0f)
  val () = glVertex2f(lw_f, 0.0f)
  val () = glVertex2f(lw_f, lh_f)
  val () = glVertex2f(0.0f, lh_f)
  val () = glEnd()
  val () = glPopMatrix()
in end

// --- 5. SAF ATS İLE MATEMATİK VE KUYRUK İŞLEMLERİ ---
fun interpolate_cubic(t: float, p0: input_point, p1: input_point, p2: input_point, p3: input_point): input_point = let
  val t2 = t * t
  val t3 = t2 * t
  fun solve(v0: float, v1: float, v2: float, v3: float): float =
    0.5f * ((2.0f * v1) + ((0.0f - v0) + v2) * t + (2.0f * v0 - 5.0f * v1 + 4.0f * v2 - v3) * t2 + ((0.0f - v0) + 3.0f * v1 - 3.0f * v2 + v3) * t3)
  val res_x = solve(p0.x, p1.x, p2.x, p3.x)
  val res_y = solve(p0.y, p1.y, p2.y, p3.y)
  val res_p = p1.pressure + (p2.pressure - p1.pressure) * t
  val res_t = p1.time + (p2.time - p1.time) * g0float2float_float_double(t)
in
  @{ x= res_x, y= res_y, pressure= res_p, time= res_t }
end

// Kuyruğu serbest bırakmak (Memory Leak önlemek için)
fun free_queue(q: point_queue): void =
  case+ q of
  | ~QueueNil() => ()
  | ~QueueCons(_, tail) => free_queue(tail)

// Kuyruğa eleman eklemek (Sona ekler)
fun push_queue(q: point_queue, pt: input_point): point_queue =
  case+ q of
  | ~QueueNil() => QueueCons(pt, QueueNil())
  | ~QueueCons(p, tail) => QueueCons(p, push_queue(tail, pt))

// Motora veriyi gönderen güncellenmiş işleyici
fun process_queue(brush: ptr, surf: ptr, zoom: float, queue: point_queue): point_queue =
  case+ queue of
  | ~QueueCons(p0, ~QueueCons(p1, ~QueueCons(p2, ~QueueCons(p3, tail)))) => let
      val dt_raw = p2.time - p1.time
      val dt: double = if dt_raw <= 0.0001 then 0.0001 else dt_raw
      val dist = sqrtf(powf(p2.x - p1.x, 2.0f) + powf(p2.y - p1.y, 2.0f))
      
      val dt_f: float = g0float2float_double_float(dt)
      
      // Güvenli C-Cast fonksiyonlarımızı kullanıyoruz (Artık GCC kızmayacak)
      val steps_t: int = f2i(dt_f / 0.01f)
      val steps_d: int = f2i(dist / 1.0f)
      
      val steps_max: int = max(steps_t, steps_d)
      val steps_min: int = max(steps_max, 1)
      val steps: int = min(steps_min, 100)

      // Tekrar float'a temiz bir dönüşüm
      val sub_dtime_f = dt_f / i2f(steps)
      val sub_dtime = g0float2float_float_double(sub_dtime_f)

      fun loop(i: int): void =
        if i <= steps then let
          // Bölme işlemi için iki tarafı da net olarak float yapıyoruz
          val t: float = i2f(i) / i2f(steps)
          val p = interpolate_cubic(t, p0, p1, p2, p3)
          
          // 12 PARAMETRE İLE ÇAĞIRIYORUZ (zoom dahil):
          val _ = if brush != the_null_ptr then
                    if surf != the_null_ptr then
                      mypaint_brush_stroke_to(brush, surf, p.x, p.y, p.pressure, 0.0f, 0.0f, sub_dtime, zoom, 0.0f, 0.0f, 0)
                    else 0
                  else 0
        in loop(i+1) end else ()        
        
      val () = loop(1)
      val nq = QueueCons(p1, QueueCons(p2, QueueCons(p3, tail)))
    // Recursive çağrı
    in process_queue(brush, surf, zoom, nq) end
  | _ => queue
  
// --- 6. CALLBACKLER (ÖDÜNÇ ALINMIŞ LİNEER TİPLER İLE) ---
extern fun canvas_draw_callback(state_ptr: ptr): void = "mac#"
implement canvas_draw_callback(state_ptr) = let
  val s = $UN.cast{ref(canvas_state_record)}(state_ptr)
  val () = glViewport(0, 0, 800, 600)
  val () = glClearColor(0.07f, 0.07f, 0.07f, 1.0f)
  val () = glClear(GL_COLOR_BUFFER_BIT)

  val () = draw_camera_setup()
  val () = glTranslatef(s->cam_x, s->cam_y, 0.0f)
  val () = glScalef(s->zoom, s->zoom, 1.0f)

  val () = if s->layer = the_null_ptr then s->layer := layer_create_c(s->lw, s->lh)
  val () = if s->layer != the_null_ptr then layer_drawOnScreen(s->layer, s->lw, s->lh) else ()
  val () = draw_border(s->lw, s->lh)
in end

extern fun canvas_handle_callback(p: ptr, ev: int): int = "mac#"
implement canvas_handle_callback(p, ev) = let
  val mx = $extval(float, "(float)fltk_event_x()")
  val my = $extval(float, "(float)fltk_event_y()")
  val cur = ats_get_current_time()

  val s = $UN.cast{ref(canvas_state_record)}(p)
  val () = fltk_make_current(s->win)
  val q = $UN.castvwtp0{point_queue}(s->q)
  // Kameraya göre fare kordinatlarını dünya koordinatlarına çevir
  val pt_x = (mx - s->cam_x) / s->zoom
  val pt_y = (my - s->cam_y) / s->zoom  
  // Tablet kalemi entegrasyonu olmadığı için sabit 0.5f basınç veriyoruz
  val pt = @{ x= pt_x, y= pt_y, pressure= 0.5f, time= cur }

  // İşlem sonucunu (res) tutacak değişken
  var res: int = 0

  // 'r' değişkenini referans (&int) olarak alıyoruz ki ATS bellek sahipliğini bilebilsin

fun handle_event(
    ev: int, 
    w: ptr,
    b: ptr, 
    surf: ptr,
    layer: ptr,
    z: float, 
    queue: point_queue, 
    point: input_point,
    r: &int 
  ): point_queue =
    if ev = 1 then let // 1: FL_PUSH 
       val () = if b != the_null_ptr then let
       val () = mypaint_brush_reset(b)
       // Fırçayı başlangıç noktasına ışınla (0 pressure ile):
       val _ = mypaint_brush_stroke_to(b, surf, point.x, point.y, 0.0f, 0.0f, 0.0f, 0.001, z, 0.0f, 0.0f, 0)
     in () end else ()
       val () = free_queue(queue)
       val () = r := 1
     in QueueCons(point, QueueNil()) end
    else if ev = 5 then let // 5: FL_DRAG 
      val () = if w != the_null_ptr then fltk_make_current(w)
      val q1 = push_queue(queue, point)
      val () = if layer != the_null_ptr then layer_bind_c(layer)
      val q2 = process_queue(b, surf, z, q1) 
      val () = if layer != the_null_ptr then layer_unbind_c(layer)
      val () = fltk_canvas_redraw(w)
      val () = r := 1
    in q2 end
    else if ev = 2 then let // 2: FL_RELEASE 
      val () = if w != the_null_ptr then fltk_make_current(w)
      val q1 = push_queue(queue, point)
      val () = if layer != the_null_ptr then layer_bind_c(layer)
      val q2 = process_queue(b, surf, z, q1) 
      val () = if layer != the_null_ptr then layer_unbind_c(layer)
      val () = free_queue(q2)
      val () = fltk_canvas_redraw(w)
      val () = r := 1
    in QueueNil() end
    else let
      val () = r := 0
    in queue end

  val new_q = handle_event(ev, s->win, s->brush, s->surf, s->layer, s->zoom, q, pt, res)
  val () = s->q := $UN.castvwtp0{ptr}(new_q)
in
  res
end
// --- 7. ARAYÜZ (UI) BAĞLANTILARI ---
extern fun canvas_set_brush_color(p: ptr, r: float, g: float, b: float): void = "ext#"
implement canvas_set_brush_color(p, r, g, b) = let
  // Dönüşüm için bellekte yer ayır
  var h: float
  var s: float
  var v: float
  
  // Referansları vererek C fonksiyonunu çağır
  val () = my_rgb_to_hsv(r, g, b, h, s, v)
  val st = $UN.cast{ref(canvas_state_record)}(p)
  
  val () = if st->brush != the_null_ptr then let
             val () = mypaint_brush_set_base_value(st->brush, MYPAINT_BRUSH_SETTING_COLOR_H, h)
             val () = mypaint_brush_set_base_value(st->brush, MYPAINT_BRUSH_SETTING_COLOR_S, s)
             val () = mypaint_brush_set_base_value(st->brush, MYPAINT_BRUSH_SETTING_COLOR_V, v)
           in () end
           else ()


in end

extern fun canvas_set_brush_setting(p: ptr, id: int, v: float): void = "ext#"
implement canvas_set_brush_setting(p, id, v) = let
  val st = $UN.cast{ref(canvas_state_record)}(p)
  val () = if st->brush != the_null_ptr then mypaint_brush_set_base_value(st->brush, id, v) else ()
in end

// C++ tarafından nesneleri alacak şekilde imza değiştirildi
extern fun canvas_state_create(win: ptr, brush: ptr): ptr = "ext#"
implement canvas_state_create(win, brush) = let
  val surf_linear = mygl_surface_create()
  val surf_ptr = $UN.castvwtp0{ptr}(surf_linear)
  
  // 1. the_null_ptr yerine C++'tan gelen 'win' pointer'ını ilk sıraya koyuyoruz
  val state = $UN.cast{ref(canvas_state_record)}(malloc($extval(size_t, "sizeof(canvas_state_record)")))
  val () = state->win := win
  val () = state->brush := brush
  val () = state->surf := surf_ptr
  val () = state->layer := the_null_ptr
  val () = state->cam_x := 0.0f
  val () = state->cam_y := 0.0f
  val () = state->zoom := 1.0f
  val () = state->lw := 800
  val () = state->lh := 600
  val () = state->q := $UN.castvwtp0{ptr}(QueueNil())
in
  $UN.cast{ptr}(state)
end

