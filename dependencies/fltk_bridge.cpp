#include <FL/Fl.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_Value_Slider.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Gl_Window.H>
#include <GL/gl.h>
#include <sys/time.h>
#include "mypaint-brush.h"
#include "mypaint-brush-settings-gen.h"

// Renk paleti sabitleri (orijinal Ui.hpp ile birebir)
const Fl_Color C_BG = 0x1E1E1EFF;      // 30, 30, 30
const Fl_Color C_WIDGET = 0x2D2D2DFF;  // 45, 45, 45
const Fl_Color C_TEXT = 0xCCCCCCFF;    // 204, 204, 204
const Fl_Color C_ACCENT = 0x007ACCFF;  // 0, 122, 204

// ATS2 fonksiyon prototipleri
extern "C" {
    void ui_on_color_changed(void* canvas_ptr, float r, float g, float b);
    void ui_on_slider_changed(void* canvas_ptr, int setting_id, float value);
    void* canvas_state_create(void* win, void* brush);
    void canvas_draw_callback(void* state);
    int canvas_handle_callback(void* state, int event);
}

// FLTK OpenGL Penceresi (Alt sınıf)
class MyCanvasWindow : public Fl_Gl_Window {
    void* ats_state;
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
            glViewport(0, 0, pixel_w(), pixel_h());
        }
        if (draw_cb && ats_state) draw_cb(ats_state);
    }

    int handle(int event) override {
        if (event == FL_SHOW) return Fl_Gl_Window::handle(event);
        if (event == FL_ENTER) return 1; // Mouse hareket ve tekerlek olaylarını doğrudan alabilmek için
        if (handle_cb && ats_state) {
            int res = handle_cb(ats_state, event);
            if (res != 0) return res;
        }
        return Fl_Gl_Window::handle(event);
    }
};

// C köprü fonksiyonları (ATS2'nin çağıracağı C API)
extern "C" {
    void fltk_canvas_redraw(void* win) {
        if (win) ((Fl_Gl_Window*)win)->redraw();
    }

    void fltk_make_current(void* win) {
        if (win) ((Fl_Gl_Window*)win)->make_current();
    }

    int fltk_event_x(void) { return Fl::event_x(); }
    int fltk_event_y(void) { return Fl::event_y(); }
    int fltk_event_button(void) { return Fl::event_button(); }
    int fltk_event_dy(void) { return Fl::event_dy(); }
    int fltk_event_dx(void) { return Fl::event_dx(); }
    int fltk_window_pixel_w(void* win) { return win ? ((Fl_Gl_Window*)win)->pixel_w() : 0; }
    int fltk_window_pixel_h(void* win) { return win ? ((Fl_Gl_Window*)win)->pixel_h() : 0; }

    int fltk_event_mousewheel(void) { return FL_MOUSEWHEEL; }
    int fltk_event_push(void) { return FL_PUSH; }
    int fltk_event_release(void) { return FL_RELEASE; }
    int fltk_event_drag(void) { return FL_DRAG; }
    int fltk_event_is_panning(void) {
        return (Fl::event_button() == FL_MIDDLE_MOUSE) || Fl::get_key(' ');
    }

    double ats_get_current_time(void) {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        return (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0);
    }
}

static void fltk_color_changed_cb(Fl_Widget* w, void* data) {
    Fl_Color_Chooser* chooser = (Fl_Color_Chooser*)w;
    ui_on_color_changed(data, (float)chooser->r(), (float)chooser->g(), (float)chooser->b());
}

static void fltk_slider_cb(Fl_Widget* w, void* data) {
    Fl_Value_Slider* slider = (Fl_Value_Slider*)w;
    void* canvas_ptr = slider->parent()->user_data();
    int setting_id = (int)(__intptr_t)data;
    ui_on_slider_changed(canvas_ptr, setting_id, (float)slider->value());
}

extern "C" int ffi_ui_init(int argc, char** argv) {
    Fl::scheme(NULL);

    Fl_Double_Window *window = new Fl_Double_Window(1000, 600, "MinePaint");
    window->color(C_BG);

    int sidebar_width = 250;

    // 1. MyPaint Fırçasını oluştur ve başlangıç ayarlarını yap (MyCanvas.cpp ile tam uyumlu)
    MyPaintBrush* brush = mypaint_brush_new();
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE_LINEARIZE, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 1.5f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_HARDNESS, 0.1f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_DABS_PER_ACTUAL_RADIUS, 5.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_DABS_PER_SECOND, 40.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 3.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_TRACKING_NOISE, 0.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_ANTI_ALIASING, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_H, 1.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_S, 0.0f);
    mypaint_brush_set_base_value(brush, MYPAINT_BRUSH_SETTING_COLOR_V, 0.729f);

    // 2. Canvas Penceresi
    MyCanvasWindow* win = new MyCanvasWindow(0, 0, window->w() - sidebar_width, 600, nullptr,
                                             (void*)canvas_draw_callback, (void*)canvas_handle_callback);

    // 3. ATS2 State Yapısı
    void* actual_canvas_state = canvas_state_create((void*)win, (void*)brush);
    win->set_ats_state(actual_canvas_state);

    // 4. Kenar Çubuğu (Sidebar)
    Fl_Group *sidebar = new Fl_Group(window->w() - sidebar_width, 0, sidebar_width, 600);
    sidebar->box(FL_FLAT_BOX);
    sidebar->color(C_BG);
    sidebar->user_data(actual_canvas_state);

    // 5. Renk Seçici (Color Chooser)
    int y = 20;
    Fl_Color_Chooser *chooser = new Fl_Color_Chooser(sidebar->x() + 10, y, sidebar_width - 20, 150, "Renk");
    chooser->box(FL_FLAT_BOX);
    chooser->color(C_BG);
    chooser->labelcolor(C_TEXT);
    chooser->labelfont(FL_BOLD);
    chooser->mode(0);
    chooser->rgb(0.73, 0.73, 0.73);
    chooser->callback(fltk_color_changed_cb, actual_canvas_state);

    for (int i = 0; i < chooser->children(); i++) {
        Fl_Widget *child = chooser->child(i);
        child->box(FL_FLAT_BOX);
        child->color(C_WIDGET);
        child->labelcolor(C_TEXT);

        Fl_Value_Input* input = dynamic_cast<Fl_Value_Input*>(child);
        if (input) {
            input->textcolor(C_TEXT);
            input->cursor_color(C_TEXT);
            input->selection_color(C_ACCENT);
            input->textfont(FL_SCREEN);
        }

        Fl_Choice* choice = dynamic_cast<Fl_Choice*>(child);
        if (choice) {
            choice->textfont(FL_HELVETICA_BOLD);
            choice->textsize(11);
            choice->textcolor(C_TEXT);
            choice->color(C_WIDGET);
        }
    }
    y += 170;

    // 6. Sürgüler (Sliders) - Ui.cpp ile birebir aynı
    auto make_slider = [&](const char* label, int setting_id, double min, double max, double val) {
        Fl_Box* lbl = new Fl_Box(sidebar->x() + 10, y, sidebar_width - 20, 20, label);
        lbl->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        lbl->labelcolor(C_TEXT);
        lbl->labelfont(FL_BOLD);
        y += 15;

        Fl_Value_Slider* sld = new Fl_Value_Slider(sidebar->x() + 10, y, sidebar_width - 20, 5);
        sld->type(FL_HOR_NICE_SLIDER);
        sld->bounds(min, max);
        sld->value(val);
        sld->callback(fltk_slider_cb, (void*)(__intptr_t)setting_id);
        sld->box(FL_FLAT_BOX);
        sld->color(C_WIDGET);
        sld->selection_color(C_ACCENT);
        sld->labelcolor(C_TEXT);
        sld->textcolor(C_TEXT);
        sld->type(FL_HOR_FILL_SLIDER);
        y += 15;
    };

    make_slider("Fırça Boyutu", MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 0.0, 4.0, 1.2);
    make_slider("Sertlik", MYPAINT_BRUSH_SETTING_HARDNESS, 0.0, 1.0, 0.1);
    make_slider("Opaklık", MYPAINT_BRUSH_SETTING_OPAQUE, 0.0, 1.0, 0.9);
    make_slider("Yumuşatma", MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 0.0, 5.0, 3.0);

    sidebar->end();

    window->resizable(win);
    window->end();
    window->show(argc, argv);

    return Fl::run();
}
