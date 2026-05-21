#include <FL/Fl.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_Value_Slider.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Gl_Window.H> // EKLENDİ: Fltk OpenGL Penceresi için
#include <GL/gl.h>
#include "mypaint-brush.h"
#include "mypaint-brush-settings-gen.h"

// --- ATS'DE YAZDIĞIMIZ FONKSİYONLARIN C İMZALARI ---
extern "C" {
    void ui_on_color_changed(void* canvas_ptr, float r, float g, float b);
    void ui_on_slider_changed(void* canvas_ptr, int setting_id, float value);
}

// --- ÖZEL FLTK OPENGL CANVAS SINIFI ---
class MyCanvasWindow : public Fl_Gl_Window {
    void* ats_state; // ATS'den gelen CanvasState pointer'ı
    typedef void (*DrawCallback)(void*);
    typedef int (*HandleCallback)(void*, int);
    DrawCallback draw_cb;
    HandleCallback handle_cb;

public:
    MyCanvasWindow(int x, int y, int w, int h, void* state, void* dcb, void* hcb)
        : Fl_Gl_Window(x, y, w, h), ats_state(state), draw_cb((DrawCallback)dcb), handle_cb((HandleCallback)hcb) {
        mode(FL_RGB | FL_ALPHA | FL_DOUBLE | FL_OPENGL3);
    }

    void set_ats_state(void* state) {
        ats_state = state;
    }
    
    void draw() override {
        if (!valid()) {
            valid(1);
            glViewport(0, 0, w(), h());
        }
        // Ekran çizileceği zaman ATS'deki canvas_draw_callback'i çağırır
        if (draw_cb) draw_cb(ats_state);
    }
    
    int handle(int event) override {
        if (event == FL_SHOW) return Fl_Gl_Window::handle(event);
        if (handle_cb && ats_state) {
            int res = handle_cb(ats_state, event);
            if (res != 0) return res;
        }
        return Fl_Gl_Window::handle(event);
    }
};

// --- EKSİK OLAN C KÖPRÜ FONKSİYONLARI BURADA DOLDURULDU ---
extern "C" {
    void* fltk_canvas_create(int x, int y, int w, int h, void* state, void* draw_cb, void* handle_cb) {
        MyCanvasWindow* win = new MyCanvasWindow(x, y, w, h, state, draw_cb, handle_cb);
        return win;
    }

    void fltk_canvas_redraw(void* win) {
        if (win) {
            ((Fl_Gl_Window*)win)->redraw();
        }
    }

    // ATS'nin beklediği FLTK event sarmalayıcıları
    int fltk_event_x(void) {
        return Fl::event_x();
    }

    int fltk_event_y(void) {
        return Fl::event_y();
    }
}


// --- FLTK KÖPRÜ CALLBACK'LERİ (ATS'yi tetikler) ---
void fltk_color_changed_cb(Fl_Widget* w, void* data) {
    Fl_Color_Chooser* chooser = (Fl_Color_Chooser*)w;
    // Güvenli ATS fonksiyonunu çağır!
    ui_on_color_changed(data, chooser->r(), chooser->g(), chooser->b());
}

void fltk_slider_cb(Fl_Widget* w, void* data) {
    Fl_Value_Slider* slider = (Fl_Value_Slider*)w;
    void* canvas_ptr = slider->parent()->user_data();
    int setting_id = (int)(__intptr_t)data;
    // Güvenli ATS fonksiyonunu çağır!
    ui_on_slider_changed(canvas_ptr, setting_id, slider->value());
}

extern "C" void* canvas_state_create(void* win, void* brush);
extern "C" void canvas_draw_callback(void*);
extern "C" int canvas_handle_callback(void*, int);

extern "C" int ffi_ui_init(int argc, char** argv) {
    Fl::scheme(NULL);

    Fl_Double_Window *window = new Fl_Double_Window(1000, 600, "MinePaint (Pür ATS)");
    window->color(0x33333300); // Koyu gri (C_BG karşılığı)

    int sidebar_width = 250;

    // 1. Fırçayı Oluştur
    MyPaintBrush* brush = mypaint_brush_new();
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 1.5f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_HARDNESS, 0.5f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS, 4.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_DABS_PER_SECOND, 40.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_H, 0.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_S, 0.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_V, 0.8f);
    
    // 2. Pencereyi henüz ATS state'i YOKKEN (nullptr) oluştur. 
    MyCanvasWindow* win = new MyCanvasWindow(0, 0, window->w() - sidebar_width, 600, nullptr, (void*)canvas_draw_callback, (void*)canvas_handle_callback);
    // 3. Pencere (win) pointer'ını kullanarak ATS State'ini güvenle oluştur
    void* actual_canvas_state = canvas_state_create((void*)win, (void*)brush);

    // 4. Son olarak, oluşan state'i pencereye bağla (Döngü kapandı!)
    win->set_ats_state(actual_canvas_state);
    
    // 5. Sidebar Grubu
    Fl_Group *sidebar = new Fl_Group(window->w() - sidebar_width, 0, sidebar_width, 600);
    sidebar->box(FL_FLAT_BOX);
    sidebar->color(0x33333300);
    sidebar->user_data(actual_canvas_state); // Slider'lar canvas'ı bulsun diye

    // 6. Renk Seçici (Color Chooser)
    int y = 20;
    Fl_Color_Chooser *chooser = new Fl_Color_Chooser(sidebar->x() + 10, y, sidebar_width - 20, 150, "Renk");
    chooser->box(FL_FLAT_BOX); 
    chooser->mode(0);
    // ATS'ye bağla
    chooser->callback(fltk_color_changed_cb, actual_canvas_state);
    
    y += 170;

    // 7. Slider Oluşturucu Lambda
    auto make_slider = [&](const char* label, int setting_id, double min, double max, double val) {
        Fl_Box* lbl = new Fl_Box(sidebar->x() + 10, y, sidebar_width - 20, 20, label);
        lbl->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        lbl->labelcolor(FL_WHITE);
        y += 15;

        Fl_Value_Slider* sld = new Fl_Value_Slider(sidebar->x() + 10, y, sidebar_width - 20, 5);
        sld->type(FL_HOR_NICE_SLIDER);
        sld->bounds(min, max);
        sld->value(val);
        // ATS'ye bağla
        sld->callback(fltk_slider_cb, (void*)(__intptr_t)setting_id);
        sld->type(FL_HOR_FILL_SLIDER); 
        y += 15;
    };

    make_slider("Fırça Boyutu", MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC /* RADIUS_LOGARITHMIC */, 0.0, 4.0, 1.2);
    make_slider("Sertlik", MYPAINT_BRUSH_SETTING_HARDNESS /* HARDNESS */, 0.0, 1.0, 0.1);
    make_slider("Opaklık", MYPAINT_BRUSH_SETTING_OPAQUE /* OPAQUE */, 0.0, 1.0, 0.9);

    sidebar->end();
    window->end();
    window->show(argc, argv);

    // FLTK Olay Döngüsünü başlat
    return Fl::run();
}

#include <sys/time.h>
extern "C" double ats_get_current_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + (tv.tv_usec / 1000000.0);
}



extern "C" void fltk_make_current(void* win) {
    if (win) ((Fl_Gl_Window*)win)->make_current();
}
