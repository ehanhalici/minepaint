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
#include "MyGlSurface.hpp"
#include <chrono>
#include <deque> // Kuyruk yapısı için

extern "C" {
    #include "mypaint-brush.h"
    #include "mypaint-surface.h"
}


// Nokta verisi
struct InputPoint {
    float x, y, pressure;
    double time; // Olayın gerçekleştiği an (saniye)
};

struct Vector2 {
    float x;
    float y;
};

struct LayerVector2 {
    int w;
    int h;
};


class MyCanvas : public Fl_Gl_Window {
    MyPaintBrush *brush;
    MyGLSurface *mypaint_surface;
    LayerVector2 LayerSize = {14000, 14000}; 
    Layer *mainLayer;

    std::chrono::steady_clock::time_point last_time;

public:
    MyCanvas(int x, int y, int w, int h);
    ~MyCanvas();
    void set_brush_setting(int setting_id, float value);    
    void set_brush_color(double r, double g, double b);
    int handle(int event) override;
    void draw() override;
    // Nokta geçmişini tutan kuyruk (En az 4 nokta lazım)
    std::deque<InputPoint> point_history;
    
    // Sabitler (Python kodundaki ayarlar)
    const double INTERPOLATION_MAX_SLICE_TIME = 0.01;     // 10ms
    const double INTERPOLATION_MAX_SLICE_DISTANCE = 1.0;  // 1 piksel

private:
    Vector2 camera = {0.0f,0.0f};
    float zoom = 1.0f;

    int last_mouse_x = 0;   // Orta tuşla kaydırma için
    int last_mouse_y = 0;
    InputPoint screen_to_world(float screen_x, float screen_y);
    void process_queue(bool force_finish = false);
    void send_stroke_to_engine(float x, float y, float pressure, double dtime);
    void rgb_to_hsv(float r, float g, float b, float &h, float &s, float &v);
    void teleport_brush(float x, float y);
    InputPoint interpolate_cubic(float t, InputPoint p0, InputPoint p1, InputPoint p2, InputPoint p3);
    float get_pressure();
};
