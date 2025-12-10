#include "MyCanvas.hpp"
#include "mypaint-brush.h"
#include <algorithm>


MyCanvas::MyCanvas(int x, int y, int w, int h) : Fl_Gl_Window(x, y, w, h) {
    mode(FL_RGB | FL_ALPHA | FL_DOUBLE | FL_DEPTH | FL_MULTISAMPLE);
    brush = mypaint_brush_new();
    mypaint_surface = new MyGLSurface();
    mainLayer = nullptr; 

    // 1. Temel Opaklık
    set_brush_setting(MYPAINT_BRUSH_SETTING_OPAQUE, 1.0f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE, 1.0f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY, 1.0f);

    // 3. Diğer Ayarlar
    set_brush_setting(MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 1.5f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_HARDNESS, 0.1f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS, 3.0f);
    //set_brush_setting MYPAINT_BRUSH_SETTING_DABS_PER_SECOND, 0.0f); // Sadece mesafeye göre çiz
    //set_brush_setting MYPAINT_BRUSH_SETTING_ERASER, 0.0f);
    // sik nokta koysun
    set_brush_setting(MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS, 20.0f);
    // durdugun yerde de ciz
    set_brush_setting(MYPAINT_BRUSH_SETTING_DABS_PER_SECOND, 40.0f);

    // 1. YUMUŞATMA (SLOW TRACKING): 
    // Bu değer ne kadar yüksekse, çizgi o kadar "gecikmeli" ama "pürüzsüz" gelir.
    // 0.0 = Köşeli, 2.0 = Çok Yumuşak, 5.0 = İp ile çekiyor gibi
    set_brush_setting(MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 3.0f);

    // 2. TİTREŞİM ENGELLEME
    // Fırçanın rastgele sağa sola sapmasını engeller.
    set_brush_setting(MYPAINT_BRUSH_SETTING_TRACKING_NOISE, 0.0f);

    // Anti-alias ve Dabs
    set_brush_setting(MYPAINT_BRUSH_SETTING_ANTI_ALIASING, 1.0f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS, 5.0f);


    set_brush_setting(MYPAINT_BRUSH_SETTING_COLOR_H, 1.0f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_COLOR_S, 0.0f);
    set_brush_setting(MYPAINT_BRUSH_SETTING_COLOR_V, 0.729f);
}

MyCanvas::~MyCanvas() {
        mypaint_brush_unref(brush);
        delete mypaint_surface;
        delete mainLayer;
    }


void MyCanvas::set_brush_setting(int setting_id, float value) {
     mypaint_brush_set_base_value(brush, (MyPaintBrushSetting)setting_id, value);
}
    

void MyCanvas::set_brush_color(double r, double g, double b) {
        float h, s, v;
        rgb_to_hsv((float)r, (float)g, (float)b, h, s, v);
        set_brush_setting(MYPAINT_BRUSH_SETTING_COLOR_H, h);
        set_brush_setting(MYPAINT_BRUSH_SETTING_COLOR_S, s);
        set_brush_setting(MYPAINT_BRUSH_SETTING_COLOR_V, v);
    }

void MyCanvas::draw() {
    if (!valid()) {
        if (!mainLayer) {
            mainLayer = new Layer(pixel_w(), pixel_h());
            mainLayer->resize(pixel_w(), pixel_h());
        } else {
            mainLayer->resize(pixel_w(), pixel_h());
        }

        // EKRAN PROJEKSİYONU
        glViewport(0, 0, pixel_w(), pixel_h());
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, pixel_w(), pixel_h(), 0, -1, 1);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        valid(1);
    }

    // (Arka Plan Rengi)
    glClearColor(0.07f, 0.07f, 0.07f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // 2. Layer'ı Ekrana Bas
    if (mainLayer) {
        mainLayer->drawOnScreen(pixel_w(), pixel_h());
    }
}

// Fırçayı çizim yapmadan, lastik etkisi olmadan ışınlar
// Mevcut (Slow Tracking) i kaydet, gecici olarak 0 yapip brush i resetle,
// x,y noktasina isinla,
// new_stroke ile yeni cizgi baslat
void MyCanvas::teleport_brush(MyPaintBrush* brush, float x, float y,  MyPaintSurface* mypaint_surface) {
    float saved_tracking = mypaint_brush_get_base_value(brush, MYPAINT_BRUSH_SETTING_SLOW_TRACKING);
    set_brush_setting(MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 0.0f);
    mypaint_brush_reset(brush);
    mypaint_brush_stroke_to(brush, (MyPaintSurface*)mypaint_surface, x, y, 0.0f, 0, 0, 0.0, 1.0, 0.0, 0.0, 0);
    mypaint_brush_new_stroke(brush);
    set_brush_setting(MYPAINT_BRUSH_SETTING_SLOW_TRACKING, saved_tracking);
}

int MyCanvas::handle(int event){
    float start_x = (float)Fl::event_x();
    float start_y = (float)Fl::event_y();

        switch(event) {
            case FL_PUSH: {

                teleport_brush(brush, start_x, start_y, mypaint_surface);

                point_history.clear();
                last_time = std::chrono::steady_clock::now();
                
                mypaint_surface->is_erasing =  (Fl::event_button() == FL_RIGHT_MOUSE) ? true : false;
                
                InputPoint p={.x=start_x, .y=start_y, .pressure=0.8f, .time=0.0};
                point_history.push_back(p);
                return 1;
            }

            case FL_DRAG: {
                // Spline Matematiği: process_queue fonksiyonu, elindeki 4 noktayı alıp
                // aradaki boşlukları interpolate_cubic fonksiyonu ile dolduruyor.
                // Otomatik Sıklık: Fareyi çok hızlı hareket ettirsen bile (dist büyük olsa bile),
                // steps_d sayesinde araya yüzlerce nokta ekleniyor. Bu da köşeli görünümü (Angular lines) tamamen yok ediyor.
                
                auto now = std::chrono::steady_clock::now();
                std::chrono::duration<double> elapsed = now - last_time;
                double current_time = elapsed.count();

                InputPoint p={.x=start_x, .y=start_y, .pressure=0.8f, .time=current_time};
                point_history.push_back(p);

                process_queue(false);
                
                return 1; 
            }
            
            case FL_RELEASE:
                process_queue(true);
                mypaint_brush_reset(brush);
                mypaint_surface->is_erasing = false;
                return 1;

            default:
                return Fl_Gl_Window::handle(event);
        }
}


void MyCanvas::process_queue(bool force_finish) {
    // Spline çizmek için en az 4 nokta gerekir: P0, P1, P2, P3
    // Biz P1 ile P2 arasını çizeriz.

    while (point_history.size() >= 4) {
        InputPoint p0 = point_history[0];
        InputPoint p1 = point_history[1];
        InputPoint p2 = point_history[2];
        InputPoint p3 = point_history[3];

        double total_dtime = p2.time - p1.time;
        if (total_dtime <= 0.0001) total_dtime = 0.0001;

        float dist = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));

        // Adım sayılarını hesapla
        int steps_t = (int)(total_dtime / INTERPOLATION_MAX_SLICE_TIME);
        int steps_d = (int)(dist / INTERPOLATION_MAX_SLICE_DISTANCE);
        
        // En az 1 adım olmalı
        int steps = std::max(1, std::max(steps_t, steps_d));

        // Performans limiti (Çok hızlı hareketlerde takılmayı önler)
        if (steps > 100) steps = 100;

        double sub_dtime = total_dtime / (double)steps; 
        for (int i = 1; i <= steps; i++) {
            float t = (float)i / (float)steps;
            // Ara noktayı hesapla (Konum ve Basınç)
            InputPoint p = interpolate_cubic(t, p0, p1, p2, p3);
            // Motora gönder
            send_stroke_to_engine(p.x, p.y, p.pressure, sub_dtime);
        }
        point_history.pop_front();
    }
    if (force_finish) {
        point_history.clear();
    }
}

void MyCanvas::send_stroke_to_engine(float x, float y, float pressure, double dtime) {
    if (!mainLayer) return;
    make_current(); 
    mainLayer->bind(); 

    glMatrixMode(GL_PROJECTION); glPushMatrix(); glLoadIdentity(); {
        glOrtho(0, pixel_w(), pixel_h(), 0, -1, 1);
        glMatrixMode(GL_MODELVIEW); glLoadIdentity();
    
        mypaint_brush_stroke_to(brush, (MyPaintSurface*)mypaint_surface, x, y, pressure, 0, 0, dtime, 1.0, 0.0, 0.0, 0);
    } glMatrixMode(GL_PROJECTION); glPopMatrix(); glMatrixMode(GL_MODELVIEW);

    mainLayer->unbind(); 
    redraw();
}


InputPoint MyCanvas::interpolate_cubic(float t, InputPoint p0, InputPoint p1, InputPoint p2, InputPoint p3) {
    InputPoint result;
    
    // X ve Y için Cubic hesaplama
    // Formül: P(t) = 0.5 * ((2*P1) + (-P0 + P2) * t + (2*P0 - 5*P1 + 4*P2 - P3) * t^2 + (-P0 + 3*P1 - 3*P2 + P3) * t^3)    
    float t2 = t * t;
    float t3 = t2 * t;
    auto solve = [&](float v0, float v1, float v2, float v3) -> float {
        return 0.5f * ((2.0f * v1) +
                       (-v0 + v2) * t +
                       (2.0f * v0 - 5.0f * v1 + 4.0f * v2 - v3) * t2 +
                       (-v0 + 3.0f * v1 - 3.0f * v2 + v3) * t3);
    };

    result.x = solve(p0.x, p1.x, p2.x, p3.x);
    result.y = solve(p0.y, p1.y, p2.y, p3.y);
    
    // Basınç ve Zaman için Lineer enterpolasyon
    result.pressure = p1.pressure + (p2.pressure - p1.pressure) * t;
    result.time = p1.time + (p2.time - p1.time) * t;

    return result;
}


void MyCanvas::rgb_to_hsv(float r, float g, float b, float &h, float &s, float &v) {
    float max_val = std::max({r, g, b});
    float min_val = std::min({r, g, b});
    float delta = max_val - min_val;

    v = max_val; // Value

    if (delta < 0.00001f) {
        s = 0;
        h = 0; // Renksiz (Gri/Siyah/Beyaz)
        return;
    }

    s = (max_val > 0.0f) ? (delta / max_val) : 0.0f; // Saturation

    if (r >= max_val)
        h = (g - b) / delta;
    else if (g >= max_val)
        h = 2.0f + (b - r) / delta;
    else
        h = 4.0f + (r - g) / delta;

    h *= 60.0f; // Dereceye çevir
    if (h < 0.0f) h += 360.0f;
    
    h /= 360.0f; // MyPaint 0.0 - 1.0 arası ister
}
