// src/gl/glctx_box.sats
// GLX baglami sahipli tutamactir: glXCreateContext ile olusur, glXDestroyContext tuketir.
// Tek `assume` window.dats icindedir; kullanicilar `!GlCtx` odunc alir.
absvtype GlCtx = ptr
