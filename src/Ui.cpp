#include "Ui.hpp"
#include <FL/Fl_Button.H>
#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Choice.H>

MyCanvas* Ui::create_canvas(int w) {
    MyCanvas *canvas = new MyCanvas(0, 0, w, 600);
    return canvas ;
    
}
Fl_Group* Ui::create_sidebar(int x, int w) {
    Fl_Group *sidebar = new Fl_Group(x, 0, w, 600);
    sidebar->box(FL_FLAT_BOX);
    sidebar->color(C_BG); 

    return sidebar;
}

Fl_Color_Chooser* Ui::create_cooser(int x, int y, int w) {
    Fl_Color_Chooser *chooser = new Fl_Color_Chooser(x, y, w, 150, "Renk");
    
    chooser->box(FL_FLAT_BOX); 
    chooser->color(C_BG); 
    chooser->labelcolor(C_TEXT);
    chooser->labelfont(FL_BOLD);
    chooser->mode(0); 

    for (int i = 0; i < chooser->children(); i++) {
        Fl_Widget *child = chooser->child(i);
        
        // --- 1. ORTAK AYARLAR ---
        child->box(FL_FLAT_BOX);     
        child->color(C_WIDGET);      
        child->labelcolor(C_TEXT);   
        
        // --- 2. SAYI GİRİŞ KUTULARI (0.75, 255 vb.) ---
        Fl_Value_Input* input = dynamic_cast<Fl_Value_Input*>(child);
        if (input) {
            input->textcolor(C_TEXT);
            input->cursor_color(C_TEXT);
            input->selection_color(C_ACCENT); 
            input->textfont(FL_SCREEN);     
        }

        // --- 3. MOD SEÇİCİ (RGB, Byte, Hex, HSV Yazan Menü) ---
        Fl_Choice* choice = dynamic_cast<Fl_Choice*>(child);
        if (choice) {
            choice->textfont(FL_HELVETICA_BOLD);
            choice->textsize(11);
            choice->textcolor(C_TEXT);
            choice->color(C_WIDGET);
        }
    }

    return chooser;
}

int Ui::init_ui(int argc, char **argv) {
    Fl::scheme("gleam"); 

    Fl_Double_Window *window = new Fl_Double_Window(1000, 600, "MyPaint C++ Studio");
    window->color(C_BG);

    // Uygulama widget'larını tutacak yapı
    static AppWidgets appState;
    appState.window = window;
    appState.sidebar_width = 250; // Sidebar genişliğini burada belirle

    int y = 20;
    appState.canvas = create_canvas(window->w() - appState.sidebar_width);
    appState.sidebar = create_sidebar(window->w() - appState.sidebar_width, appState.sidebar_width);
    appState.chooser = create_cooser(appState.sidebar->x() + 10, y, appState.sidebar_width - 20);
    y += 170;

    // --- YARDIMCI FONKSİYON: Slider Oluşturucu ---
    auto make_slider = [&](const char* label, int setting_id, double min, double max, double val) {
        Fl_Box* lbl = new Fl_Box(appState.sidebar->x() + 10, y, appState.sidebar_width - 20, 20, label);
        lbl->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        lbl->labelcolor(C_TEXT);
        lbl->labelfont(FL_BOLD);
        y += 15;

        Fl_Value_Slider* sld = new Fl_Value_Slider(appState.sidebar->x() + 10, y, appState.sidebar_width - 20, 5);
        sld->type(FL_HOR_NICE_SLIDER);
        sld->bounds(min, max);
        sld->value(val);
        sld->callback(slider_cb, (void*)(intptr_t)setting_id);

        sld->box(FL_FLAT_BOX);
        sld->color(C_WIDGET);
        sld->selection_color(C_ACCENT);
        sld->labelcolor(C_TEXT);
        sld->textcolor(C_TEXT);
        sld->type(FL_HOR_FILL_SLIDER); 

        y += 15;
        return sld;
    };

    make_slider("Fırça Boyutu", MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 0.0, 4.0, 2.0);
    make_slider("Sertlik", MYPAINT_BRUSH_SETTING_HARDNESS, 0.0, 1.0, 0.8);
    make_slider("Opaklık", MYPAINT_BRUSH_SETTING_OPAQUE, 0.0, 1.0, 1.0);
    make_slider("Yumuşatma", MYPAINT_BRUSH_SETTING_SLOW_TRACKING, 0.0, 5.0, 3.0);
    appState.sidebar->user_data((void*)appState.canvas); // Callbackler için
    appState.sidebar->end(); // Sidebar bitti

    // // --- TOGGLE BUTONU (Sidebar ve Canvas'ın üzerinde yüzen) ---
    // // Bu butonu en son ekliyoruz ki "Z-Order" olarak en üstte olsun.
    // Fl_Button* toggle_btn = new Fl_Button(window->w() - 30, 0, 30, 30, ">>");
    // toggle_btn->box(FL_FLAT_BOX);
    // toggle_btn->color(C_ACCENT);
    // toggle_btn->labelcolor(C_TEXT);
    // toggle_btn->callback(toggle_sidebar_cb, (void*)&appState);
    // appState.toggle_btn = toggle_btn; // Struct'a kaydet

    // Bağlantılar
    appState.chooser->callback(color_changed_cb, (void*)appState.canvas);
    appState.chooser->rgb(0.73, 0.73, 0.73);
    appState.canvas->set_brush_color(0.73, 0.73, 0.73);

    window->resizable(appState.canvas);

    window->end();
    window->show(argc, argv);
    return Fl::run();
    
}

// --- Renk Değişince Çalışacak Fonksiyon ---
void Ui::color_changed_cb(Fl_Widget* w, void* data) {
    Fl_Color_Chooser* chooser = (Fl_Color_Chooser*)w;
    MyCanvas* canvas = (MyCanvas*)data;
    canvas->set_brush_color(chooser->r(), chooser->g(), chooser->b());
}

void Ui::slider_cb(Fl_Widget* w, void* data) {
    Fl_Value_Slider* slider = (Fl_Value_Slider*)w;
    // Sidebar'ın user_data'sından canvas'ı al
    MyCanvas* canvas = (MyCanvas*)slider->parent()->user_data();

    int setting_id = (int)(intptr_t)data; 
    canvas->set_brush_setting(setting_id, (float)slider->value());
}


// --- SIDEBAR TOGGLE CALLBACK ---
void Ui::toggle_sidebar_cb(Fl_Widget* w, void* data) {
    AppWidgets* app = (AppWidgets*)data;
    
    if (app->sidebar->visible()) {
        app->sidebar->hide();
        // Canvas'ı pencerenin tamamına yay
        app->canvas->resize(0, 0, app->window->w(), app->window->h());
        app->toggle_btn->label("<<"); 
    } else {
        // Canvas'ı küçült
        app->canvas->resize(0, 0, app->window->w() - app->sidebar_width, app->window->h());
        // Sidebar'ı göster ve sağa yasla
        app->sidebar->resize(app->window->w() - app->sidebar_width, 0, app->sidebar_width, app->window->h());
        app->sidebar->show();
        app->toggle_btn->label(">>");
    }
    app->window->redraw();
}
