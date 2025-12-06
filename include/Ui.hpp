#include <FL/Fl.H>
#include <FL/Fl_Gl_Window.H>
#include <FL/Fl_Value_Slider.H> // Yeni: Sürgüler için
#include <FL/Fl_Check_Button.H> // Yeni: Silgi butonu için
#include <FL/Fl_Color_Chooser.H> // Renk Seçici
#include <FL/Fl_Double_Window.H>                                 //

#include "MyCanvas.hpp"

struct AppWidgets {
    Fl_Group* sidebar;
    MyCanvas* canvas;
    Fl_Double_Window* window;
    int sidebar_width;
    Fl_Button* toggle_btn;
    Fl_Color_Chooser* chooser;
};

const Fl_Color C_BG     = fl_rgb_color(18, 18, 18);    
const Fl_Color C_WIDGET = fl_rgb_color(25, 25, 25);    
const Fl_Color C_TEXT   = fl_rgb_color(186, 186, 186); 
const Fl_Color C_ACCENT = fl_rgb_color(40, 40, 40); 
const Fl_Color C_HOVER  = fl_rgb_color(60, 60, 60);


class Ui {

public:
    int init_ui(int argc, char **argv);
private:
    MyCanvas* create_canvas(int w);
    Fl_Group* create_sidebar(int x, int w);
    Fl_Color_Chooser* create_cooser(int x, int y, int w);
    
    static void color_changed_cb(Fl_Widget* w, void* data);
    static void slider_cb(Fl_Widget* w, void* data);
    static void toggle_sidebar_cb(Fl_Widget* w, void* data);
};
