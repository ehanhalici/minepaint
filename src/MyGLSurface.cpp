#include "MyGlSurface.hpp"


int draw_dab_callback(MyPaintSurface *self, float x, float y, float radius,
                      float color_r, float color_g, float color_b,
                      float opaque, float hardness, float alpha_eraser,
                      float aspect_ratio, float angle, float lock_alpha,
                      float colorize,
                      float snap_to_pixel,
                      float view_zoom, float view_rotation, float barrel_rotation) {
    
    (void)self; (void)snap_to_pixel; (void)view_zoom; 
    (void)view_rotation; (void)barrel_rotation; (void)colorize;

    MyGLSurface *gl_surface = (MyGLSurface*)self;
    if (radius < 0.00001f) return 1;


    glDisable(GL_TEXTURE_2D); // Doku kaplamayı kapali, Sadece renk
    glDisable(GL_DEPTH_TEST); // Derinlik testini kapali, 2D

    glPushMatrix(); // Mevcut koordinat sistemini kaydet

    // 1. KAĞIDI KAYDIR VE DÖNDÜR
    glTranslatef(x, y, 0.0f);        // Kağıdı fırçanın olduğu (x,y) noktasına taşı
    
    float angle_deg = angle * 180.0f / M_PI; 
    glRotatef(angle_deg, 0.0f, 0.0f, 1.0f); // Kağıdı döndür

    if (aspect_ratio > 1.0f) glScalef(1.0f, 1.0f / aspect_ratio, 1.0f);
    else if (aspect_ratio < 1.0f) glScalef(aspect_ratio, 1.0f, 1.0f);

    // 2. RENK VE KARIŞIM AYARLARI
    glEnable(GL_BLEND);

    if (gl_surface->is_erasing) {
        // === SİLGİ MODU (ERASER) ===
        // Matematik: Hedef Piksel = 0 * Kaynak + Hedef * (1 - SilgiGücü)
        // Yani: Eski rengi, silginin gücü kadar azalt.

        glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);
        radius *= 4.0f;
        
        // Burada R,G,B'nin önemi yok (GL_ZERO yutacak). 
        // 4. parametre (Alpha) silme gücünü belirler.
        glColor4f(0.0f, 0.0f, 0.0f, 1.0f); 
        
    } else {
        // === NORMAL BOYA MODU ===
        // Standart Alpha Blending (Üst üste bindirme)
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        // Rengi ayarla
        // merkez nokta tam opak tam gucte
        glColor4f(color_r, color_g, color_b, opaque);
    }
    

    // ============================================================
    // --- ASIL ÇİZİMİ YAPAN KISIM BURASI ---
    // ============================================================
    glBegin(GL_TRIANGLE_FAN);
    {
        // A. MERKEZ NOKTA (0,0)
        // Matris ile zaten (x,y)'ye gitmiştik, o yüzden buraya 0,0 diyoruz.
        glVertex2f(0.0f, 0.0f); 

        // B. KENAR NOKTALARI (ÇEMBER)
        
        // Kenarları biraz şeffaflaştır (Sertlik etkisi)

        // Kenar Yumuşatma Ayarı
        if (gl_surface->is_erasing) {
             // Silgide kenarlar daha az siler (Yumuşak silgi etkisi)
             glColor4f(0.0f, 0.0f, 0.0f, 1.0); 
        } else {
             // Normal boyada kenarlar daha şeffaftır
             glColor4f(color_r, color_g, color_b, opaque * hardness);
        }
        int segments = 24; // Daireyi kaç üçgenle oluşturacağız? (Düşükse köşeli, yüksekse yuvarlak olur)
        for (int i = 0; i <= segments; i++) {
            // 1. Açıyı Hesapla (Radyan cinsinden)
            // 360 dereceyi (2*PI) 24 parçaya bölüyoruz.
            float theta = 2.0f * M_PI * float(i) / float(segments);
            
            // 2. Kutupsal Koordinattan -> Kartezyen Koordinata Geçiş
            // Lise trigonometrisi: Bir açının X bileşeni Cos, Y bileşeni Sin ile bulunur.
            float dx = radius * cosf(theta);
            float dy = radius * sinf(theta);
            
            // 3. Noktayı Koy
            glVertex2f(dx, dy); 
        }
    }
    glEnd();
    // ============================================================

    glPopMatrix(); // Koordinat sistemini eski haline getir
    return 1;
}


MyGLSurface::MyGLSurface() {
        // Struct içini sıfırla
        this->draw_dab = draw_dab_callback;
        this->get_color = NULL;       // Renk okuma (Smudge için gerekli)
        this->begin_atomic = NULL;
        this->end_atomic = NULL;
        this->save_png = NULL;
        this->refcount = 1; // Referans sayacı
        this->is_erasing = false;
    }
