#include "MyGlSurface.hpp"



void print_dot(bool is_erasing, float radius, float color_r, float color_g, float color_b, float opaque, float hardness) {
    glEnable(GL_BLEND);
    if (is_erasing) {
        
        glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);
        radius *= 4.0f;
        // 4. parametre (Alpha) silme gücünü belirler.
        glColor4f(0.0f, 0.0f, 0.0f, 1.0f); 
        
    } else {
        // Standart Alpha Blending (Üst üste bindirme)
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glColor4f(color_r, color_g, color_b, opaque);
    }

    glBegin(GL_TRIANGLE_FAN);
    {
        // Matris ile zaten (x,y)'ye gitmiştik, o yüzden buraya 0,0 diyoruz.
        glVertex2f(0.0f, 0.0f); 

        // Kenar Yumuşatma Ayarı
        if (is_erasing) {
             glColor4f(0.0f, 0.0f, 0.0f, 1.0); 
        } else {
             // hardness kadar yumusat
             glColor4f(color_r, color_g, color_b, opaque * hardness);
        }
        int segments = 24;
        for (int i = 0; i <= segments; i++) {
            float theta = 2.0f * M_PI * float(i) / float(segments);
            float dx = radius * cosf(theta);
            float dy = radius * sinf(theta);
            glVertex2f(dx, dy); 
        }
    }
    glEnd();
}


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
    {
        glTranslatef(x, y, 0.0f);        // Kağıdı fırçanın olduğu (x,y) noktasına taşı
    
        float angle_deg = angle * 180.0f / M_PI; 
        glRotatef(angle_deg, 0.0f, 0.0f, 1.0f); // Kağıdı döndür
        
        if (aspect_ratio > 1.0f) glScalef(1.0f, 1.0f / aspect_ratio, 1.0f);
        else if (aspect_ratio < 1.0f) glScalef(aspect_ratio, 1.0f, 1.0f);
        
        print_dot(gl_surface->is_erasing, radius, color_r, color_g, color_g, opaque, hardness);

        glPopMatrix(); // Koordinat sistemini eski haline getir
    }
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
