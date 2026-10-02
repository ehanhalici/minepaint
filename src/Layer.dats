// src/Layer.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

// --- Harici C Kütüphaneleri (Sadece OpenGL) ---
%{^
#include <GL/gl.h>
#include <GL/glext.h>
#include <stdlib.h>
%}

typedef GLuint = uint

#define TILE_HASH_SIZE 1024
#define TILE_HASH_MASK 1023

typedef CanvasTile = @{
  tx= int,
  ty= int,
  texture= uint,
  fbo= uint,
  next_in_bucket= ptr,
  next_in_layer= ptr
}

typedef Layer_Record = @{
  buckets= ptr,
  tiles= ptr,
  tile_count= int
}

// OpenGL Sabitleri
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
macdef GL_PROJECTION = $extval(int, "GL_PROJECTION")
macdef GL_MODELVIEW = $extval(int, "GL_MODELVIEW")

// OpenGL Fonksiyon İmzaları
extern fun glGenTextures(n: int, textures: &GLuint? >> GLuint): void = "mac#glGenTextures"
extern fun glBindTexture(target: int, texture: GLuint): void = "mac#glBindTexture"
extern fun glTexImage2D(target: int, level: int, internalformat: int, width: int, height: int, border: int, format: int, atype: int, pixels: ptr): void = "mac#glTexImage2D"
extern fun glTexParameteri(target: int, pname: int, param: int): void = "mac#glTexParameteri"
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
extern fun glClearColor(red: float, green: float, blue: float, alpha: float): void = "mac#"
extern fun glClear(mask: int): void = "mac#"
extern fun glViewport(x: int, y: int, w: int, h: int): void = "mac#"
extern fun glMatrixMode(m: int): void = "mac#"
extern fun glLoadIdentity(): void = "mac#"
extern fun glPushMatrix(): void = "mac#"
extern fun glPopMatrix(): void = "mac#"
extern fun glOrtho(l: double, r: double, b: double, t: double, n: double, f: double): void = "mac#"

extern fun malloc(n: size_t): ptr = "mac#"
extern fun free(p: ptr): void = "mac#"

// --- Sonsuz Kanvas / Tile Yönetim API'si ---
extern fun layer_create(w: int, h: int): ptr = "ext#layer_create"
extern fun layer_create_c(w: int, h: int): ptr = "ext#layer_create_c"
extern fun layer_find_tile(layer: ptr, tx: int, ty: int): ptr = "ext#layer_find_tile"
extern fun layer_get_or_create_tile(layer: ptr, tx: int, ty: int): ptr = "ext#layer_get_or_create_tile"
extern fun layer_bind_tile(tile: ptr): void = "ext#layer_bind_tile"
extern fun layer_unbind_tile(): void = "ext#layer_unbind_tile"
extern fun layer_draw_tiles(layer: ptr, view_l: float, view_t: float, view_r: float, view_b: float): void = "ext#layer_draw_tiles"
extern fun layer_clear(layer: ptr): void = "ext#layer_clear"
extern fun layer_destroy(layer: ptr): void = "ext#layer_destroy"

// Geriye dönük uyumluluk imzaları
extern fun layer_drawOnScreen(layer: ptr, w: int, h: int): void = "ext#layer_drawOnScreen"
extern fun layer_bind(l: ptr): void = "ext#layer_bind"
extern fun layer_unbind(l: ptr): void = "ext#layer_unbind"
extern fun layer_bind_c(l: ptr): void = "ext#layer_bind_c"
extern fun layer_unbind_c(l: ptr): void = "ext#layer_unbind_c"

// 2D Karo Koordinat Hash Fonksiyonu - Saf ATS2
fn tile_hash(tx: int, ty: int): int = let
  val u_tx = g0int2uint_int_uint(tx)
  val u_ty = g0int2uint_int_uint(ty)
  val h1 = g0uint_mul_uint(u_tx, 73856093U)
  val h2 = g0uint_mul_uint(u_ty, 19349663U)
  val h = g0uint_lxor_uint(h1, h2)
  val idx = g0uint_land_uint(h, 1023U)
in
  g0uint2int_uint_int(idx)
end

// --- Pür ATS2 ile Sonsuz Katman Oluşturma (O(1) Hash Tablosu ile) ---
implement layer_create(w, h) = let
  val p = malloc(sizeof<Layer_Record>)
  val r = $UN.cast{ref(Layer_Record)}(p)
  val buckets_mem = malloc(g0int2uint_int_size(TILE_HASH_SIZE) * sizeof<ptr>)
  val () = assertloc(buckets_mem > the_null_ptr)

  fun init_buckets(i: int): void =
    if i < TILE_HASH_SIZE then let
      val () = $UN.ptr0_set<ptr>(ptr_add<ptr>(buckets_mem, i), the_null_ptr)
    in init_buckets(i + 1) end else ()

  val () = init_buckets(0)
  val () = r->buckets := buckets_mem
  val () = r->tiles := the_null_ptr
  val () = r->tile_count := 0
in
  p
end

implement layer_create_c(w, h) = layer_create(w, h)

// --- O(1) Hash Tablosu ile Tile Arama ---
fun find_tile_in_bucket(cur: ptr, tx: int, ty: int): ptr =
  if cur = the_null_ptr then the_null_ptr
  else let
    val t = $UN.cast{ref(CanvasTile)}(cur)
  in
    if (t->tx = tx) && (t->ty = ty) then cur
    else find_tile_in_bucket(t->next_in_bucket, tx, ty)
  end

implement layer_find_tile(layer, tx, ty) = let
  val () = assertloc(layer != the_null_ptr)
  val lr = $UN.cast{ref(Layer_Record)}(layer)
  val idx = tile_hash(tx, ty)
  val slot = ptr_add<ptr>(lr->buckets, idx)
  val head = $UN.ptr0_get<ptr>(slot)
in
  find_tile_in_bucket(head, tx, ty)
end

// --- Tile Oluşturma (1024x1024 - 4MB Sparse Allocation) ---
fun alloc_tile(tx: int, ty: int, next_bucket: ptr, next_layer: ptr): ptr = let
  val p = malloc(sizeof<CanvasTile>)
  val t = $UN.cast{ref(CanvasTile)}(p)
  val () = t->tx := tx
  val () = t->ty := ty

  var tex_id: GLuint
  var fbo_id: GLuint
  val () = glGenTextures(1, tex_id)
  val () = glBindTexture(GL_TEXTURE_2D, tex_id)
  val () = glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, the_null_ptr)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

  val () = glGenFramebuffers(1, fbo_id)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, fbo_id)
  val () = glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_id, 0)

  val () = glClearColor(0.0f, 0.0f, 0.0f, 0.0f)
  val () = glClear(GL_COLOR_BUFFER_BIT)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, 0u)
  val () = glBindTexture(GL_TEXTURE_2D, 0u)

  val () = t->texture := tex_id
  val () = t->fbo := fbo_id
  val () = t->next_in_bucket := next_bucket
  val () = t->next_in_layer := next_layer
in
  p
end

implement layer_get_or_create_tile(layer, tx, ty) = let
  val lr = $UN.cast{ref(Layer_Record)}(layer)
  val found = layer_find_tile(layer, tx, ty)
in
  if found != the_null_ptr then found
  else let
    val idx = tile_hash(tx, ty)
    val slot = ptr_add<ptr>(lr->buckets, idx)
    val old_head = $UN.ptr0_get<ptr>(slot)
    val nt = alloc_tile(tx, ty, old_head, lr->tiles)
    val () = $UN.ptr0_set<ptr>(slot, nt)
    val () = lr->tiles := nt
    val () = lr->tile_count := lr->tile_count + 1
  in
    nt
  end
end

// --- Tile Çizim Bağlantısı (FBO + Projeksiyon) ---
implement layer_bind_tile(tile) = let
  val t = $UN.cast{ref(CanvasTile)}(tile)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, t->fbo)
  val () = glViewport(0, 0, 1024, 1024)

  val tx_f = g0int2float(t->tx) * 1024.0f
  val ty_f = g0int2float(t->ty) * 1024.0f
  val tx1_f = tx_f + 1024.0f
  val ty1_f = ty_f + 1024.0f

  val () = glMatrixMode(GL_PROJECTION)
  val () = glPushMatrix()
  val () = glLoadIdentity()
  val () = glOrtho(
    g0float2float_float_double(tx_f),
    g0float2float_float_double(tx1_f),
    g0float2float_float_double(ty1_f),
    g0float2float_float_double(ty_f),
    ~1.0, 1.0
  )
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glPushMatrix()
  val () = glLoadIdentity()
in () end

// --- Tile Bağlantısını Kapatma ---
implement layer_unbind_tile() = let
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glPopMatrix()
  val () = glMatrixMode(GL_PROJECTION)
  val () = glPopMatrix()
  val () = glMatrixMode(GL_MODELVIEW)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, 0u)
in () end

// --- Görünür Tile'ları Ekrana Çizme (Frustum Culling ile) ---
fun draw_tiles_rec(cur: ptr, vl: float, vt: float, vr: float, vb: float): void =
  if cur = the_null_ptr then ()
  else let
    val t = $UN.cast{ref(CanvasTile)}(cur)
    val x0 = g0int2float(t->tx) * 1024.0f
    val y0 = g0int2float(t->ty) * 1024.0f
    val x1 = x0 + 1024.0f
    val y1 = y0 + 1024.0f

    // Ekran görüş alanı (AABB) ile kesişim kontrolü
    val visible = (x1 >= vl) && (x0 <= vr) && (y1 >= vt) && (y0 <= vb)
    val () = if visible then let
      val () = glBindTexture(GL_TEXTURE_2D, t->texture)
      val () = glBegin(GL_QUADS)
      val () = glTexCoord2f(0.0f, 1.0f)
      val () = glVertex2f(x0, y0)
      val () = glTexCoord2f(1.0f, 1.0f)
      val () = glVertex2f(x1, y0)
      val () = glTexCoord2f(1.0f, 0.0f)
      val () = glVertex2f(x1, y1)
      val () = glTexCoord2f(0.0f, 0.0f)
      val () = glVertex2f(x0, y1)
      val () = glEnd()
    in () end else ()
  in
    draw_tiles_rec(t->next_in_layer, vl, vt, vr, vb)
  end

implement layer_draw_tiles(layer, vl, vt, vr, vb) = let
  val lr = $UN.cast{ref(Layer_Record)}(layer)
in
  if lr->tiles != the_null_ptr then let
    val () = glEnable(GL_TEXTURE_2D)
    val () = glEnable(GL_BLEND)
    val () = glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(1.0f, 1.0f, 1.0f, 1.0f)
    val () = draw_tiles_rec(lr->tiles, vl, vt, vr, vb)
    val () = glDisable(GL_TEXTURE_2D)
  in () end else ()
end

// --- Tile Belleğini Boşaltma ---
fun free_tiles_rec(cur: ptr): void =
  if cur = the_null_ptr then ()
  else let
    val t = $UN.cast{ref(CanvasTile)}(cur)
    val next = t->next_in_layer
    var tex: GLuint = t->texture
    var fbo: GLuint = t->fbo
    val () = glDeleteTextures(1, tex)
    val () = glDeleteFramebuffers(1, fbo)
    val () = free(cur)
  in
    free_tiles_rec(next)
  end

implement layer_clear(layer) = let
  val lr = $UN.cast{ref(Layer_Record)}(layer)
  val () = free_tiles_rec(lr->tiles)
  val () = lr->tiles := the_null_ptr
  val () = lr->tile_count := 0

  fun clear_buckets(i: int): void =
    if i < TILE_HASH_SIZE then let
      val () = $UN.ptr0_set<ptr>(ptr_add<ptr>(lr->buckets, i), the_null_ptr)
    in clear_buckets(i + 1) end else ()

  val () = clear_buckets(0)
in () end

implement layer_destroy(layer) = let
  val lr = $UN.cast{ref(Layer_Record)}(layer)
  val () = layer_clear(layer)
  val () = free(lr->buckets)
  val () = free(layer)
in () end

// Geriye dönük uyumluluk fonksiyonları
implement layer_drawOnScreen(layer, w, h) =
  layer_draw_tiles(layer, 0.0f, 0.0f, g0int2float(w), g0int2float(h))

implement layer_bind(l) = ()
implement layer_unbind(l) = ()
implement layer_bind_c(l) = ()
implement layer_unbind_c(l) = ()
