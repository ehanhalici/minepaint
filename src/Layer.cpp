#include "Layer.hpp"

Layer::Layer(int w, int h) : width(w), height(h), initialized(false), fbo(0), texture(0) {}

Layer::~Layer() {
    if (initialized) {
        glDeleteTextures(1, &texture);
        glDeleteFramebuffers(1, &fbo);
    }
}

void Layer::resize(int w, int h) {
    if (w == width && h == height && initialized) return;

    // 1. Yeni (Yeni Boyutlu) FBO ve Texture Oluştur
    GLuint newTexture, newFbo;
    
    glGenTextures(1, &newTexture);
    glBindTexture(GL_TEXTURE_2D, newTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glGenFramebuffers(1, &newFbo);
    glBindFramebuffer(GL_FRAMEBUFFER, newFbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, newTexture, 0);

    // Yeni alanı şeffaf yap (Temizle)
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // 2. ESKİYİ YENİYE KOPYALA (Varsa)
    if (initialized) {
        // Eski FBO'yu okuma moduna al
        glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
        // Yeni FBO'yu yazma moduna al
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, newFbo);

        // Eski içeriği yeniye kopyala (Blit)
        // Koordinatları eşleştirerek kopyalıyoruz (Stretch yapmadan)
        glBlitFramebuffer(0, 0, width, height, 
                          0, 0, width, height, 
                          GL_COLOR_BUFFER_BIT, GL_NEAREST);

        // Eski kaynakları sil
        glDeleteTextures(1, &texture);
        glDeleteFramebuffers(1, &fbo);
    }

    // 3. Değişkenleri Güncelle
    texture = newTexture;
    fbo = newFbo;
    width = w;
    height = h;
    initialized = true;

    // Normal moda dön
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void Layer::bind() {
    if (!initialized) return;
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glViewport(0, 0, width, height); // Çizim alanı texture boyutu kadardır
}

void Layer::unbind() {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    // Viewport'u main.cpp içindeki draw() tekrar düzeltecek
}

void Layer::clear() {
    bind();
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f); // Şeffaf siyah
    glClear(GL_COLOR_BUFFER_BIT);
    unbind();
}

void Layer::drawOnScreen(int window_width, int window_height) {
    if (!initialized) return;

    // Texture çizimini aktif et
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texture);

    // Şeffaflık ayarları (Alpha Blending)
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Rengi beyaza çek (Texture'ın kendi rengi görünsün)
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

    // Tam ekrana (veya verilen boyuta) kare çiz ve texture'ı giydir
    glBegin(GL_QUADS);{
        // Sol Alt
        glTexCoord2f(0.0f, 0.0f); 
        glVertex2f(0.0f, (float)window_height); 
        
        // Sağ Alt
        glTexCoord2f(1.0f, 0.0f); 
        glVertex2f((float)window_width, (float)window_height);
        
        // Sağ Üst
        glTexCoord2f(1.0f, 1.0f); 
        glVertex2f((float)window_width, 0.0f);
        
        // Sol Üst
        glTexCoord2f(0.0f, 1.0f); 
        glVertex2f(0.0f, 0.0f);
    }glEnd();

    glDisable(GL_TEXTURE_2D);
}
