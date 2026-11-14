// src/canvas/layer.dats
// Sonsuz katman: tile'lar arena dizilerinde tutulur (C bellegindeki bagli listeler yok).
// Arama: acik adreslemeli hash tablosu; her dongunun olcusu gercek sinirdan turer
// (TABLE_SIZE - i veya tile_count - i), yakit yoktur.
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "gl/gl_io.sats"
#include "sys/airlock.hats"
#include "sys/arena.hats"
staload "canvas/layer_box.sats"
staload "sys/capability.sats"
staload "canvas/layer_view.sats"
staload "sys/libc.dats"
staload "gl/gl.dats"

typedef GLuint = uint

#define LAYER_CAP 4
#define MAX_TILES 4096
#define TABLE_SIZE 8192
#define TABLE_MASK 8191U
#define NO_ENTRY (~1)
#define TILE_ARR (LAYER_CAP * MAX_TILES)
#define TABLE_ARR (LAYER_CAP * TABLE_SIZE)

// E.3: arenalar `arrayref`; ham katman/tile/tablo numaralari `ix_try` ile tipli indekse cevrilir.
// Gecersiz numara politikasi (eski airlock davranisi): okuma varsayilan deger, yazma etkisiz.
val g_lalive = arrayref_make_elt<int>(i2sz(LAYER_CAP), 0)
val g_lcount = arrayref_make_elt<int>(i2sz(LAYER_CAP), 0)
val g_lclaim = arrayref_make_elt<int>(i2sz(LAYER_CAP), 0)
val g_lfree = arrayref_make_elt<int>(i2sz(LAYER_CAP), 0)
val g_lfresh = ref<int>(0)
val g_lnfree = ref<int>(0)

val g_tx = arrayref_make_elt<int>(i2sz(TILE_ARR), 0)
val g_ty = arrayref_make_elt<int>(i2sz(TILE_ARR), 0)
val g_tex = arrayref_make_elt<int>(i2sz(TILE_ARR), 0)
val g_fbo = arrayref_make_elt<int>(i2sz(TILE_ARR), 0)
val g_table = arrayref_make_elt<int>(i2sz(TABLE_ARR), NO_ENTRY)

// OpenGL Sabitleri
macdef GL_TEXTURE_WRAP_S = $extval(int, "GL_TEXTURE_WRAP_S")
macdef GL_TEXTURE_WRAP_T = $extval(int, "GL_TEXTURE_WRAP_T")
macdef GL_CLAMP_TO_EDGE = $extval(int, "GL_CLAMP_TO_EDGE")

// Kanit uretimi/tuketimi sys/capability.sats aksiyomlariyla; yalniz layer_new ve layer_claim uretir.

// --- Arena erisimcileri ---
fn lix(l: int): @(bool, Ix(LAYER_CAP)) = ix_try(l, LAYER_CAP)
fn lalive_get(l: int): bool = let val @(ok, i) = lix(l) in if ok then g_lalive[i] != 0 else false end
fn lclaim_get(l: int): bool = let val @(ok, i) = lix(l) in if ok then g_lclaim[i] != 0 else true end
fn lclaim_mark(l: int): void = let val @(ok, i) = lix(l) in if ok then g_lclaim[i] := 1 end
fn lclaim_clear(l: int): void = let val @(ok, i) = lix(l) in if ok then g_lclaim[i] := 0 end
fn lalive_set(l: int, v: int): void = let val @(ok, i) = lix(l) in if ok then g_lalive[i] := v end
fn count_get(l: int): int = let val @(ok, i) = lix(l) in if ok then g_lcount[i] else 0 end
fn count_set(l: int, v: int): void = let val @(ok, i) = lix(l) in if ok then g_lcount[i] := v end
fn tile_idx(l: int, i: int): int = l * MAX_TILES + i
fn table_idx(l: int, s: int): int = l * TABLE_SIZE + s

fn tix(e: int): @(bool, Ix(TILE_ARR)) = ix_try(e, TILE_ARR)
fn tx_get(e: int): int = let val @(ok, i) = tix(e) in if ok then g_tx[i] else 0 end
fn ty_get(e: int): int = let val @(ok, i) = tix(e) in if ok then g_ty[i] else 0 end
fn tex_get(e: int): int = let val @(ok, i) = tix(e) in if ok then g_tex[i] else 0 end
fn fbo_get(e: int): int = let val @(ok, i) = tix(e) in if ok then g_fbo[i] else 0 end
fn tx_set(e: int, v: int): void = let val @(ok, i) = tix(e) in if ok then g_tx[i] := v end
fn ty_set(e: int, v: int): void = let val @(ok, i) = tix(e) in if ok then g_ty[i] := v end
fn tex_set(e: int, v: int): void = let val @(ok, i) = tix(e) in if ok then g_tex[i] := v end
fn fbo_set(e: int, v: int): void = let val @(ok, i) = tix(e) in if ok then g_fbo[i] := v end

fn entry_get(l: int, s: int): int =
  let val @(ok, i) = ix_try(table_idx(l, s), TABLE_ARR) in if ok then g_table[i] else NO_ENTRY end
fn entry_set(l: int, s: int, v: int): void =
  let val @(ok, i) = ix_try(table_idx(l, s), TABLE_ARR) in if ok then g_table[i] := v end

// 2D Karo Koordinat Hash Fonksiyonu
fn tile_hash(tx: int, ty: int): int = let
  val u_tx = g0int2uint_int_uint(tx)
  val u_ty = g0int2uint_int_uint(ty)
  val h1 = g0uint_mul_uint(u_tx, 73856093U)
  val h2 = g0uint_mul_uint(u_ty, 19349663U)
  val h = g0uint_lxor_uint(h1, h2)
in
  g0uint2int_uint_int(g0uint_land_uint(h, TABLE_MASK))
end

fn probe_slot(h0: int, i: int): int =
  g0uint2int_uint_int(g0uint_land_uint(g0int2uint_int_uint(h0 + i), TABLE_MASK))

// --- Katman ayirma / birakma (diger arena modulleriyle ayni kalip) ---
fn alloc_layer(): int =
  if !g_lnfree > 0 then let
    val n = !g_lnfree - 1
    val () = !g_lnfree := n
  in
    let val @(ok_, i_) = ix_try(n, LAYER_CAP) in if ok_ then g_lfree[i_] else NO_ENTRY end
  end else let
    val n = !g_lfresh
  in
    if n < LAYER_CAP then (!g_lfresh := n + 1; n) else NO_ENTRY
  end

fn recycle_layer(l: int): void = let
  val n = !g_lnfree
  val @(ok_n, i_n) = ix_try(n, LAYER_CAP)
  val @(ok_l, _) = ix_try(l, LAYER_CAP)
  val () = if ok_n then g_lfree[i_n] := l
  val () = if ok_l then !g_lnfree := n + 1
in () end

implement layer_new() = let
  val l = alloc_layer()
  val () = anth_require(l >= 0)
  val () = count_set(l, 0)
  val () = lalive_set(l, 1)
  val ln = airlock_nat(l)
in
  (cap_mint() | ln)
end

implement layer_stash(pf | l) = let
  prval () = cap_burn(pf)
  val () = lclaim_clear(l)
in
  layer_of_int(l)
end

implement layer_claim(layer) = let
  val l = layer_to_int(layer)
  val l2 = airlock_nat(l)
in
  // Cift claim engeli: katman zaten odunc alinmissa kanit bir daha uretilmez.
  if lalive_get(l) * not(lclaim_get(l)) then let
    val () = lclaim_mark(l)
  in (Some_v(cap_mint()) | true, l2) end
  else (None_v() | false, l2)
end

// --- Acik adreslemeli arama: olcu TABLE_SIZE - i ---
fun probe_find {i:nat | i <= TABLE_SIZE} .<TABLE_SIZE - i>. (
  l: int, h0: int, tx: int, ty: int, i: int(i)
): int =
  if i < TABLE_SIZE then let
    val s = probe_slot(h0, i)
    val e = entry_get(l, s)
  in
    if e < 0 then NO_ENTRY
    else if (tx_get(e) = tx) && (ty_get(e) = ty) then e
    else probe_find(l, h0, tx, ty, i + 1)
  end else NO_ENTRY

fun probe_insert {i:nat | i <= TABLE_SIZE} .<TABLE_SIZE - i>. (
  l: int, h0: int, e_new: int, i: int(i)
): void =
  if i < TABLE_SIZE then let
    val s = probe_slot(h0, i)
  in
    if entry_get(l, s) < 0 then entry_set(l, s, e_new)
    else probe_insert(l, h0, e_new, i + 1)
  end else anth_die_void(DieContractViolation())

implement layer_find_tile(pf | l, tx, ty) =
  tile_of_int(probe_find(l, tile_hash(tx, ty), tx, ty, 0))

// --- Tile Olusturma (1024x1024 doku + FBO) ---
fn init_tile_texture_and_fbo(gio: !GL_IO | ): @(GLuint, GLuint) = let
  val tex_id = gl_gen_texture(gio | )
  val () = glBindTexture(gio | GL_TEXTURE_2D, tex_id)
  val () = glTexImage2D(gio | GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, the_null_ptr)
  val () = glTexParameteri(gio | GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  val () = glTexParameteri(gio | GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  val () = glTexParameteri(gio | GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  val () = glTexParameteri(gio | GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  val fbo_id = gl_gen_framebuffer(gio | )
  val () = glBindFramebuffer(gio | GL_FRAMEBUFFER, fbo_id)
  val () = glFramebufferTexture2D(gio | GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_id, 0)
  val () = glClearColor(gio | 0.0f, 0.0f, 0.0f, 0.0f)
  val () = glClear(gio | GL_COLOR_BUFFER_BIT)
  val () = glBindFramebuffer(gio | GL_FRAMEBUFFER, 0u)
  val () = glBindTexture(gio | GL_TEXTURE_2D, 0u)
in
  @(tex_id, fbo_id)
end

fn store_tile(gio: !GL_IO | l: int, e: int, tx: int, ty: int): void = let
  val @(tex_id, fbo_id) = init_tile_texture_and_fbo(gio | )
  val () = tx_set(e, tx)
  val () = ty_set(e, ty)
  val () = tex_set(e, g0uint2int_uint_int(tex_id))
in
  fbo_set(e, g0uint2int_uint_int(fbo_id))
end

fn create_tile(gio: !GL_IO | l: int, tx: int, ty: int): int = let
  val n = count_get(l)
  val () = anth_require(n < MAX_TILES)
  val e = tile_idx(l, n)
  val () = store_tile(gio | l, e, tx, ty)
  val () = probe_insert(l, tile_hash(tx, ty), e, 0)
  val () = count_set(l, n + 1)
in
  e
end

implement layer_get_or_create_tile(pf, gio | l, tx, ty) = let
  val found = layer_find_tile(pf | l, tx, ty)
in
  if tile_is_null(found) = 0 then found
  else tile_of_int(create_tile(gio | l, tx, ty))
end

// --- Tile Cizim Baglantisi (FBO + Projeksiyon) ---
implement layer_bind_tile(gio | tile) = let
  val e = tile_to_int(tile)
  val tx = tx_get(e)
  val ty = ty_get(e)
  val () = glBindFramebuffer(gio | GL_FRAMEBUFFER, g0int2uint_int_uint(fbo_get(e)))
  val () = glViewport(gio | 0, 0, 1024, 1024)
  val tx_f = g0int2float(tx) * 1024.0f
  val ty_f = g0int2float(ty) * 1024.0f
  val tx1_f = tx_f + 1024.0f
  val ty1_f = ty_f + 1024.0f
  val () = glMatrixMode(gio | GL_PROJECTION)
  val () = glPushMatrix(gio | )
  val () = glLoadIdentity(gio | )
  val () = glOrtho(gio | 
    g0float2float_float_double(tx_f),
    g0float2float_float_double(tx1_f),
    g0float2float_float_double(ty1_f),
    g0float2float_float_double(ty_f),
    ~1.0, 1.0
  )
  val () = glMatrixMode(gio | GL_MODELVIEW)
  val () = glPushMatrix(gio | )
  val () = glLoadIdentity(gio | )
in () end

// --- Tile Baglantisini Kapatma ---
implement layer_unbind_tile(gio | ) = let
  val () = glMatrixMode(gio | GL_MODELVIEW)
  val () = glPopMatrix(gio | )
  val () = glMatrixMode(gio | GL_PROJECTION)
  val () = glPopMatrix(gio | )
  val () = glMatrixMode(gio | GL_MODELVIEW)
  val () = glBindFramebuffer(gio | GL_FRAMEBUFFER, 0u)
in () end

// --- Gorunur Tile'lari Ekrana Cizme ---
fn render_tile_quad(gio: !GL_IO | 
  tex: GLuint, u0: float, u1: float, v0: float, v1: float,
  x0: float, y0: float, x1: float, y1: float
): void = let
  val () = glBindTexture(gio | GL_TEXTURE_2D, tex)
  val () = glTexParameteri(gio | GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  val () = glTexParameteri(gio | GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  val () = glBegin(gio | GL_QUADS)
  val () = (glTexCoord2f(gio | u0, v1); glVertex2f(gio | x0, y0))
  val () = (glTexCoord2f(gio | u1, v1); glVertex2f(gio | x1, y0))
  val () = (glTexCoord2f(gio | u1, v0); glVertex2f(gio | x1, y1))
  val () = (glTexCoord2f(gio | u0, v0); glVertex2f(gio | x0, y1))
  val () = glEnd(gio | )
in () end

fn draw_one_tile(gio: !GL_IO | e: int, vl: float, vt: float, vr: float, vb: float, zoom: float): void = let
  val x0 = g0int2float(tx_get(e)) * 1024.0f
  val y0 = g0int2float(ty_get(e)) * 1024.0f
  val bleed = g0float_div_float(0.5f, zoom)
  val du = g0float_div_float(bleed, 1024.0f)
  val x0e = g0float_sub_float(x0, bleed)
  val y0e = g0float_sub_float(y0, bleed)
  val x1e = g0float_add_float(x0 + 1024.0f, bleed)
  val y1e = g0float_add_float(y0 + 1024.0f, bleed)
  val visible = (x1e >= vl) && (x0e <= vr) && (y1e >= vt) && (y0e <= vb)
in
  if visible then
    render_tile_quad(gio | g0int2uint_int_uint(tex_get(e)), ~du, 1.0f + du, ~du, 1.0f + du, x0e, y0e, x1e, y1e)
  else ()
end

// Olcu n - i: n = katmandaki tile sayisi. En yeni tile once cizilir (eski bagli liste sirasi).
fun draw_tiles_from {n:nat}{i:nat | i <= n} .<n - i>. (gio: !GL_IO | 
  l: int, i: int(i), n: int(n), vl: float, vt: float, vr: float, vb: float, zoom: float
): void =
  if i < n then let
    val () = draw_one_tile(gio | tile_idx(l, n - 1 - i), vl, vt, vr, vb, zoom)
  in
    draw_tiles_from(gio | l, i + 1, n, vl, vt, vr, vb, zoom)
  end else ()

implement layer_draw_tiles(pf, gio | l, vl, vt, vr, vb, zoom) = let
  val n = count_get(l)
in
  if n > 0 then let
    val () = glEnable(gio | GL_TEXTURE_2D)
    val () = glEnable(gio | GL_BLEND)
    val () = glBlendFunc(gio | GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    val () = glColor4f(gio | 1.0f, 1.0f, 1.0f, 1.0f)
    val () = draw_tiles_from(gio | l, 0, airlock_nat(n), vl, vt, vr, vb, zoom)
    val () = glDisable(gio | GL_TEXTURE_2D)
  in () end else ()
end

// --- Tile Bellegini Bosaltma ---
fn delete_one_tile(gio: !GL_IO | e: int): void = let
  val () = gl_delete_texture(gio | g0int2uint_int_uint(tex_get(e)))
in
  gl_delete_framebuffer(gio | g0int2uint_int_uint(fbo_get(e)))
end

fun delete_tiles_from {n:nat}{i:nat | i <= n} .<n - i>. (gio: !GL_IO | l: int, i: int(i), n: int(n)): void =
  if i < n then let
    val () = delete_one_tile(gio | tile_idx(l, i))
  in
    delete_tiles_from(gio | l, i + 1, n)
  end else ()

fun reset_table {i:nat | i <= TABLE_SIZE} .<TABLE_SIZE - i>. (l: int, i: int(i)): void =
  if i < TABLE_SIZE then let
    val () = entry_set(l, i, NO_ENTRY)
  in
    reset_table(l, i + 1)
  end else ()

implement layer_clear(pf, gio | l) = let
  val () = delete_tiles_from(gio | l, 0, airlock_nat(count_get(l)))
  val () = count_set(l, 0)
in
  reset_table(l, 0)
end

implement layer_destroy(pf, gio | l) = let
  val () = layer_clear(pf, gio | l)
  val () = lalive_set(l, 0)
  val () = lclaim_clear(l)
  prval () = cap_burn(pf)
in
  recycle_layer(l)
end
