// src/draw_engine/surface_target.sats
// Cizim hedefi SAF DEGERDIR (nesne, vtable, refcount, geri cagri yok): hangi katman ve hangi kip.
// Dab cizimi tek tipli islevdir; GL etkisi uygulamasinda (canvas/gl_surface.dats) yasar.
staload "gl/gl_io.sats"
staload "canvas/layer_box.sats"

datatype DrawMode = DrawPaint | DrawErase

typedef MpTarget = @{ layer= MpLayer, mode= DrawMode }

fun draw_dab_on(gio: !GL_IO | 
  t: MpTarget, x: float, y: float, radius: float,
  r: float, g: float, b: float, opaque: float, hardness: float,
  aspect: float, angle: float
): int = "ext#draw_dab_on"
