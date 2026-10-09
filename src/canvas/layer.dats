// src/Layer.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "draw_engine/engine_safe.hats"

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

extern fun view_layer(p: ptr): ref(Layer_Record) = "mac#mp_id_ptr"
extern fun view_tile(p: ptr): ref(CanvasTile) = "mac#mp_id_ptr"

fn mp_slot_get(p: ptr): ptr = mp_arr_pget(p, 0)

fn mp_slot_set(p: ptr, v: ptr): void = mp_arr_pset(p, 0, v)

// OpenGL Sabitleri
macdef GL_TEXTURE_2D = $extval(int, "GL_TEXTURE_2D")
macdef GL_RGBA = $extval(int, "GL_RGBA")
macdef GL_UNSIGNED_BYTE = $extval(int, "GL_UNSIGNED_BYTE")
macdef GL_FRAMEBUFFER = $extval(int, "GL_FRAMEBUFFER")
macdef GL_COLOR_ATTACHMENT0 = $extval(int, "GL_COLOR_ATTACHMENT0")
macdef GL_COLOR_BUFFER_BIT = $extval(int, "GL_COLOR_BUFFER_BIT")
macdef GL_TEXTURE_MIN_FILTER = $extval(int, "GL_TEXTURE_MIN_FILTER")
macdef GL_TEXTURE_MAG_FILTER = $extval(int, "GL_TEXTURE_MAG_FILTER")
macdef GL_TEXTURE_WRAP_S = $extval(int, "GL_TEXTURE_WRAP_S")
macdef GL_TEXTURE_WRAP_T = $extval(int, "GL_TEXTURE_WRAP_T")
macdef GL_LINEAR = $extval(int, "GL_LINEAR")
macdef GL_CLAMP_TO_EDGE = $extval(int, "GL_CLAMP_TO_EDGE")
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
extern fun layer_draw_tiles(layer: ptr, view_l: float, view_t: float, view_r: float, view_b: float, zoom: float): void = "ext#layer_draw_tiles"
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

// --- Pür ATS2 ile Sonsuz Katman Oluşturma ---
implement layer_create(w, h) = let
  val p = malloc(sizeof<Layer_Record>)
  val r = view_layer(p)
  val sz = g0int2uint_int_size(TILE_HASH_SIZE) * sizeof<ptr>
  val buckets_mem = malloc(sz)
  val () = assertloc(buckets_mem > the_null_ptr)

  fun init_buckets(i: int): void =
    if i < TILE_HASH_SIZE then let
      val () = mp_slot_set(ptr_add<ptr>(buckets_mem, i), the_null_ptr)
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
    val t = view_tile(cur)
  in
    if (t->tx = tx) && (t->ty = ty) then cur
    else find_tile_in_bucket(t->next_in_bucket, tx, ty)
  end

implement layer_find_tile(layer, tx, ty) = let
  val () = assertloc(layer != the_null_ptr)
  val lr = view_layer(layer)
  val idx = tile_hash(tx, ty)
  val head = mp_slot_get(ptr_add<ptr>(lr->buckets, idx))
in
  find_tile_in_bucket(head, tx, ty)
end

// --- Tile Oluşturma (1024x1024 - 4MB Sparse Allocation) ---
fn init_tile_texture_and_fbo(): @(GLuint, GLuint) = let
  var tex_id: GLuint
  var fbo_id: GLuint
  val () = glGenTextures(1, tex_id)
  val () = glBindTexture(GL_TEXTURE_2D, tex_id)
  val () = glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, the_null_ptr)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  val () = glGenFramebuffers(1, fbo_id)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, fbo_id)
  val () = glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_id, 0)
  val () = glClearColor(0.0f, 0.0f, 0.0f, 0.0f)
  val () = glClear(GL_COLOR_BUFFER_BIT)
  val () = glBindFramebuffer(GL_FRAMEBUFFER, 0u)
  val () = glBindTexture(GL_TEXTURE_2D, 0u)
in
  @(tex_id, fbo_id)
end

fun alloc_tile(tx: int, ty: int, next_bucket: ptr, next_layer: ptr): ptr = let
  val p = malloc(sizeof<CanvasTile>)
  val t = view_tile(p)
  val @(tex_id, fbo_id) = init_tile_texture_and_fbo()
  val () = t->tx := tx
  val () = t->ty := ty
  val () = t->texture := tex_id
  val () = t->fbo := fbo_id
  val () = t->next_in_bucket := next_bucket
  val () = t->next_in_layer := next_layer
in
  p
end

implement layer_get_or_create_tile(layer, tx, ty) = let
  val lr = view_layer(layer)
  val found = layer_find_tile(layer, tx, ty)
in
  if found != the_null_ptr then found
  else let
    val idx = tile_hash(tx, ty)
    val slot = ptr_add<ptr>(lr->buckets, idx)
    val old_head = mp_slot_get(slot)
    val nt = alloc_tile(tx, ty, old_head, lr->tiles)
    val () = mp_slot_set(slot, nt)
    val () = lr->tiles := nt
    val () = lr->tile_count := lr->tile_count + 1
  in
    nt
  end
end

// --- Tile Çizim Bağlantısı (FBO + Projeksiyon) ---
implement layer_bind_tile(tile) = let
  val t = view_tile(tile)
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

// --- Görünür Tile'ları Ekrana Çizme ---
fn render_tile_quad(
  tex: GLuint, u0: float, u1: float, v0: float, v1: float,
  x0: float, y0: float, x1: float, y1: float
): void = let
  val () = glBindTexture(GL_TEXTURE_2D, tex)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  val () = glBegin(GL_QUADS)
  val () = (glTexCoord2f(u0, v1); glVertex2f(x0, y0))
  val () = (glTexCoord2f(u1, v1); glVertex2f(x1, y0))
  val () = (glTexCoord2f(u1, v0); glVertex2f(x1, y1))
  val () = (glTexCoord2f(u0, v0); glVertex2f(x0, y1))
  val () = glEnd()
in () end

fun draw_tiles_rec(cur: ptr, vl: float, vt: float, vr: float, vb: float, zoom: float): void =
  if cur = the_null_ptr then ()
  else let
    val t = view_tile(cur)
    val x0 = g0int2float(t->tx) * 1024.0f
    val y0 = g0int2float(t->ty) * 1024.0f
    val bleed = g0float_div_float(0.5f, zoom)
    val du = g0float_div_float(bleed, 1024.0f)
    val x0e = g0float_sub_float(x0, bleed)
    val y0e = g0float_sub_float(y0, bleed)
    val x1e = g0float_add_float(x0 + 1024.0f, bleed)
    val y1e = g0float_add_float(y0 + 1024.0f, bleed)
    val visible = (x1e >= vl) && (x0e <= vr) && (y1e >= vt) && (y0e <= vb)
    val () = if visible then
      render_tile_quad(t->texture, ~du, 1.0f + du, ~du, 1.0f + du, x0e, y0e, x1e, y1e)
    else ()
  in
    draw_tiles_rec(t->next_in_layer, vl, vt, vr, vb, zoom)
  end

implement layer_draw_tiles(layer, vl, vt, vr, vb, zoom) = let
  val lr = view_layer(layer)
in
  if lr->tiles != the_null_ptr then let
    val () = glEnable(GL_TEXTURE_2D)
    val () = glEnable(GL_BLEND)
    val () = glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(1.0f, 1.0f, 1.0f, 1.0f)
    val () = draw_tiles_rec(lr->tiles, vl, vt, vr, vb, zoom)
    val () = glDisable(GL_TEXTURE_2D)
  in () end else ()
end

// --- Tile Belleğini Boşaltma ---
fun free_tiles_rec(cur: ptr): void =
  if cur = the_null_ptr then ()
  else let
    val t = view_tile(cur)
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
  val lr = view_layer(layer)
  val () = free_tiles_rec(lr->tiles)
  val () = lr->tiles := the_null_ptr
  val () = lr->tile_count := 0
  fun clear_buckets(i: int): void =
    if i < TILE_HASH_SIZE then let
      val () = mp_slot_set(ptr_add<ptr>(lr->buckets, i), the_null_ptr)
    in clear_buckets(i + 1) end else ()
in
  clear_buckets(0)
end

implement layer_destroy(layer) = let
  val lr = view_layer(layer)
  val () = layer_clear(layer)
  val () = free(lr->buckets)
  val () = free(layer)
in () end

// Geriye dönük uyumluluk fonksiyonları
implement layer_drawOnScreen(layer, w, h) =
  layer_draw_tiles(layer, 0.0f, 0.0f, g0int2float(w), g0int2float(h), 1.0f)

implement layer_bind(l) = ()
implement layer_unbind(l) = ()
implement layer_bind_c(l) = ()
implement layer_unbind_c(l) = ()
