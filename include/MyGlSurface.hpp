#include <FL/Fl.H>
#include <FL/Fl_Gl_Window.H>
#include <FL/gl.h>
#include <iostream>
#include <vector>
#include <cmath>
#include "Layer.hpp"
#include "mypaint-brush-settings-gen.h"
#include <FL/Fl_Value_Slider.H> // Yeni: Sürgüler için
#include <FL/Fl_Check_Button.H> // Yeni: Silgi butonu için

// C kütüphanesi olduğu için extern "C" bloğu
extern "C" {
    #include "mypaint-brush.h"
    #include "mypaint-surface.h"
    // Glib TRUE/FALSE tanımları için gerekebilir, yoksa manuel 1/0 kullanırız
    #include <glib.h> 
}


class MyGLSurface : public MyPaintSurface {
    
public:
    MyGLSurface();
    bool is_erasing = false;
};

