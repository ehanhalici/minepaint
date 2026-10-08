// src/draw_engine/rectangle.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

typedef MinePaintRectangle = @{
  x= int,
  y= int,
  width= int,
  height= int
}

// --- Saf Çekirdek (pointer yok, yan etki yok) ---

// Eksen genişletme: tek eksende noktayı kapsayan (pos, span) çiftini hesaplar.
fn expand_axis(pos: int, span: int, pt: int): @(int, int) =
  if pt < pos then @(pt, span + (pos - pt))
  else if pt >= pos + span then @(pos, pt - pos + 1)
  else @(pos, span)

// Noktayı kapsayacak dikdörtgen (değer döndürür, girdiyi değiştirmez).
fn rect_expand_point(r: MinePaintRectangle, x: int, y: int): MinePaintRectangle =
  if r.width = 0 then @{ x= x, y= y, width= 1, height= 1 }
  else let
    val @(nx, nw) = expand_axis(r.x, r.width, x)
    val @(ny, nh) = expand_axis(r.y, r.height, y)
  in
    @{ x= nx, y= ny, width= nw, height= nh }
  end

// Başka dikdörtgeni kapsayacak dikdörtgen: iki köşe noktası sırayla eklenir.
fn rect_expand_rect(r: MinePaintRectangle, o: MinePaintRectangle): MinePaintRectangle = let
  val r1 = rect_expand_point(r, o.x, o.y)
in
  rect_expand_point(r1, o.x + o.width - 1, o.y + o.height - 1)
end

// --- Sınır (C ABI pointer katmanı) ---
// Dış API ptr üzerinden çalışır; tüm hesap yukarıdaki saf fonksiyonlarda yapılır.

extern castfn ptr2rect(p: ptr): ref(MinePaintRectangle) = "mac#"

extern fun malloc(sz: size_t): ptr = "mac#malloc"
extern fun free(p: ptr): void = "mac#free"

fn rect_load(p: ptr): MinePaintRectangle = let
  val r = ptr2rect(p)
in
  @{ x= r->x, y= r->y, width= r->width, height= r->height }
end

fn rect_store(p: ptr, v: MinePaintRectangle): void = let
  val r = ptr2rect(p)
  val () = r->x := v.x
  val () = r->y := v.y
  val () = r->width := v.width
  val () = r->height := v.height
in () end

// Dikdörtgen Oluşturma
extern fun minepaint_rectangle_new(x: int, y: int, w: int, h: int): ptr = "ext#minepaint_rectangle_new"
implement minepaint_rectangle_new(x, y, w, h) = let
  val p = malloc(sizeof<MinePaintRectangle>)
  val () = assertloc(p > the_null_ptr)
  val () = rect_store(p, @{ x= x, y= y, width= w, height= h })
in
  p
end

// Dikdörtgen Kopyalama
extern fun minepaint_rectangle_copy(self: ptr): ptr = "ext#minepaint_rectangle_copy"
implement minepaint_rectangle_copy(self) =
  if self = the_null_ptr then the_null_ptr
  else let
    val p = malloc(sizeof<MinePaintRectangle>)
    val () = assertloc(p > the_null_ptr)
    val () = rect_store(p, rect_load(self))
  in
    p
  end

// Dikdörtgen Serbest Bırakma
extern fun minepaint_rectangle_free(self: ptr): void = "ext#minepaint_rectangle_free"
implement minepaint_rectangle_free(self) =
  if self != the_null_ptr then free(self) else ()

// Nokta Kapsayacak Şekilde Genişletme (in-place)
extern fun minepaint_rectangle_expand_to_include_point(
  r: ptr, x: int, y: int
): void = "ext#minepaint_rectangle_expand_to_include_point"
implement minepaint_rectangle_expand_to_include_point(r_p, x, y) =
  if r_p != the_null_ptr then
    rect_store(r_p, rect_expand_point(rect_load(r_p), x, y))
  else ()

// Başka Dikdörtgeni Kapsayacak Şekilde Genişletme (in-place)
extern fun minepaint_rectangle_expand_to_include_rect(
  r: ptr, other: ptr
): void = "ext#minepaint_rectangle_expand_to_include_rect"
implement minepaint_rectangle_expand_to_include_rect(r_p, other_p) =
  if (r_p != the_null_ptr) && (other_p != the_null_ptr) then
    rect_store(r_p, rect_expand_rect(rect_load(r_p), rect_load(other_p)))
  else ()
