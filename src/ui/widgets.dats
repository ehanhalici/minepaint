// src/ui/widgets.dats
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload UN = "prelude/SATS/unsafe.sats"

%{^
#include <GL/gl.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "mypaint-brush-settings-gen.h"

extern void canvas_set_brush_setting(void* canvas_ptr, int setting_id, float value);
extern void canvas_set_brush_color(void* canvas_ptr, float r, float g, float b);

// Basit 2D Çizim Yardımcıları
static void gl_draw_rect(float x, float y, float w, float h, float r, float g, float b, float a) {
    glColor4f(r, g, b, a);
    glBegin(GL_QUADS);
    glVertex2f(x, y);
    glVertex2f(x + w, y);
    glVertex2f(x + w, y + h);
    glVertex2f(x, y + h);
    glEnd();
}

static void gl_draw_rect_outline(float x, float y, float w, float h, float r, float g, float b, float a) {
    glColor4f(r, g, b, a);
    glBegin(GL_LINE_LOOP);
    glVertex2f(x, y);
    glVertex2f(x + w, y);
    glVertex2f(x + w, y + h);
    glVertex2f(x, y + h);
    glEnd();
}

static void gl_draw_circle(float cx, float cy, float radius, float r, float g, float b, float a) {
    glColor4f(r, g, b, a);
    glBegin(GL_TRIANGLE_FAN);
    glVertex2f(cx, cy);
    int segs = 20;
    for (int i = 0; i <= segs; i++) {
        float theta = 2.0f * 3.14159265f * (float)i / (float)segs;
        glVertex2f(cx + radius * cosf(theta), cy + radius * sinf(theta));
    }
    glEnd();
}

// Minimal 5x7 Vektör Çizgi Fontu (Harici kütüphane gerektirmez)
static const unsigned char FONT_5X7[][5] = {
    [' '] = {0x00, 0x00, 0x00, 0x00, 0x00},
    ['.'] = {0x00, 0x60, 0x60, 0x00, 0x00},
    [':'] = {0x00, 0x36, 0x36, 0x00, 0x00},
    ['-'] = {0x08, 0x08, 0x08, 0x08, 0x08},
    ['%'] = {0x63, 0x33, 0x18, 0x0c, 0x66},
    ['0'] = {0x3e, 0x51, 0x49, 0x45, 0x3e},
    ['1'] = {0x00, 0x42, 0x7f, 0x40, 0x00},
    ['2'] = {0x42, 0x61, 0x51, 0x49, 0x46},
    ['3'] = {0x21, 0x41, 0x45, 0x4b, 0x31},
    ['4'] = {0x18, 0x14, 0x12, 0x7f, 0x10},
    ['5'] = {0x27, 0x45, 0x45, 0x45, 0x39},
    ['6'] = {0x3c, 0x4a, 0x49, 0x49, 0x30},
    ['7'] = {0x01, 0x71, 0x09, 0x05, 0x03},
    ['8'] = {0x36, 0x49, 0x49, 0x49, 0x36},
    ['9'] = {0x06, 0x49, 0x49, 0x29, 0x1e},
    ['A'] = {0x7c, 0x12, 0x11, 0x12, 0x7c},
    ['B'] = {0x7f, 0x49, 0x49, 0x49, 0x36},
    ['C'] = {0x3e, 0x41, 0x41, 0x41, 0x22},
    ['D'] = {0x7f, 0x41, 0x41, 0x22, 0x1c},
    ['E'] = {0x7f, 0x49, 0x49, 0x49, 0x41},
    ['F'] = {0x7f, 0x09, 0x09, 0x09, 0x01},
    ['G'] = {0x3e, 0x41, 0x49, 0x49, 0x7a},
    ['H'] = {0x7f, 0x08, 0x08, 0x08, 0x7f},
    ['I'] = {0x00, 0x41, 0x7f, 0x41, 0x00},
    ['J'] = {0x20, 0x40, 0x41, 0x3f, 0x01},
    ['K'] = {0x7f, 0x08, 0x14, 0x22, 0x41},
    ['L'] = {0x7f, 0x40, 0x40, 0x40, 0x40},
    ['M'] = {0x7f, 0x02, 0x0c, 0x02, 0x7f},
    ['N'] = {0x7f, 0x04, 0x08, 0x10, 0x7f},
    ['O'] = {0x3e, 0x41, 0x41, 0x41, 0x3e},
    ['P'] = {0x7f, 0x09, 0x09, 0x09, 0x06},
    ['R'] = {0x7f, 0x09, 0x19, 0x29, 0x46},
    ['S'] = {0x46, 0x49, 0x49, 0x49, 0x31},
    ['T'] = {0x01, 0x01, 0x7f, 0x01, 0x01},
    ['U'] = {0x3f, 0x40, 0x40, 0x40, 0x3f},
    ['V'] = {0x1f, 0x20, 0x40, 0x20, 0x1f},
    ['Y'] = {0x07, 0x08, 0x70, 0x08, 0x07},
};

static void gl_draw_string(float x, float y, float scale, const char* str, float r, float g, float b) {
    glColor3f(r, g, b);
    glBegin(GL_POINTS);
    while (*str) {
        unsigned char c = (unsigned char)*str;
        if (c >= 'a' && c <= 'z') c -= 32; // Uppercase
        if (c <= 'Y') {
            for (int col = 0; col < 5; col++) {
                unsigned char bits = FONT_5X7[c][col];
                for (int row = 0; row < 7; row++) {
                    if (bits & (1 << row)) {
                        glVertex2f(x + col * scale, y + row * scale);
                    }
                }
            }
        }
        x += 7.0f * scale;
        str++;
    }
    glEnd();
}

static void hsv_to_rgb(float h, float s, float v, float *r, float *g, float *b) {
    if (s <= 0.0f) { *r = v; *g = v; *b = v; return; }
    float hh = h * 6.0f;
    if (hh >= 6.0f) hh = 0.0f;
    int i = (int)hh;
    float ff = hh - i;
    float p = v * (1.0f - s);
    float q = v * (1.0f - (s * ff));
    float t = v * (1.0f - (s * (1.0f - ff)));
    switch (i) {
        case 0: *r = v; *g = t; *b = p; break;
        case 1: *r = q; *g = v; *b = p; break;
        case 2: *r = p; *g = v; *b = t; break;
        case 3: *r = p; *g = q; *b = v; break;
        case 4: *r = t; *g = p; *b = v; break;
        default: *r = v; *g = p; *b = q; break;
    }
}

typedef struct {
    const char* label;
    int setting_id;
    float min_val;
    float max_val;
    float val;
} SliderInfo;

typedef struct {
    float cur_r;
    float cur_g;
    float cur_b;
    float cur_h;
    float cur_s;
    float cur_v;
    SliderInfo sliders[4];
    int active_drag; // -1: none, 0..3: slider, 10: hue bar, 11: sv box
} UIWidgetsState;

static UIWidgetsState g_ui = {
    .cur_r = 0.73f, .cur_g = 0.73f, .cur_b = 0.73f,
    .cur_h = 0.0f,  .cur_s = 0.0f,  .cur_v = 0.73f,
    .sliders = {
        {"BOYUT",     MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC, 0.0f, 4.0f, 1.2f},
        {"SERTLIK",   MYPAINT_BRUSH_SETTING_HARDNESS,            0.0f, 1.0f, 0.1f},
        {"OPAKLIK",   MYPAINT_BRUSH_SETTING_OPAQUE,              0.0f, 1.0f, 0.9f},
        {"YUMUSATMA", MYPAINT_BRUSH_SETTING_SLOW_TRACKING,       0.0f, 5.0f, 3.0f}
    },
    .active_drag = -1
};

// 12 Renkli Hızlı Palet
static const float PALETTE[12][3] = {
    {1.0f, 1.0f, 1.0f}, // Beyaz
    {0.73f, 0.73f, 0.73f}, // Gri
    {0.3f, 0.3f, 0.3f}, // Koyu Gri
    {0.0f, 0.0f, 0.0f}, // Siyah
    {0.95f, 0.2f, 0.2f}, // Kırmızı
    {1.0f, 0.55f, 0.0f}, // Turuncu
    {1.0f, 0.9f, 0.1f}, // Sarı
    {0.2f, 0.85f, 0.3f}, // Yeşil
    {0.1f, 0.85f, 0.85f}, // Camgöbeği
    {0.2f, 0.45f, 0.95f}, // Mavi
    {0.65f, 0.25f, 0.85f}, // Mor
    {0.55f, 0.35f, 0.2f}  // Kahverengi
};

void widgets_render(float sx, float sy, float sw, float sh) {
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // 1. Sidebar Arka Planı (Koyu Şık Tema)
    gl_draw_rect(sx, sy, sw, sh, 0.12f, 0.12f, 0.13f, 1.0f);
    gl_draw_rect(sx, sy, 1.0f, sh, 0.22f, 0.22f, 0.25f, 1.0f); // Kenarlık

    // 2. Başlık
    glPointSize(2.0f);
    gl_draw_string(sx + 20, 20, 1.5f, "MINEPAINT", 0.0f, 0.6f, 1.0f);
    gl_draw_rect(sx + 20, 42, sw - 40, 1.0f, 0.2f, 0.2f, 0.22f, 1.0f);

    // 3. Renk Bölümü
    // Aktif Renk Önizleme Kutusu
    gl_draw_rect(sx + 20, 55, 45, 45, g_ui.cur_r, g_ui.cur_g, g_ui.cur_b, 1.0f);
    gl_draw_rect_outline(sx + 20, 55, 45, 45, 0.5f, 0.5f, 0.55f, 1.0f);

    // 12'li Renk Paleti (2 satır x 6 sütun)
    float swatch_w = 22.0f;
    float swatch_h = 20.0f;
    for (int i = 0; i < 12; i++) {
        int row = i / 6;
        int col = i % 6;
        float bx = sx + 75 + col * (swatch_w + 5);
        float by = 55 + row * (swatch_h + 5);
        gl_draw_rect(bx, by, swatch_w, swatch_h, PALETTE[i][0], PALETTE[i][1], PALETTE[i][2], 1.0f);
        gl_draw_rect_outline(bx, by, swatch_w, swatch_h, 0.3f, 0.3f, 0.35f, 1.0f);
    }

    // Gökkuşağı Hue (Renk Tonu) Çubuğu
    float hue_y = 115.0f;
    float hue_h = 16.0f;
    float bar_w = sw - 40.0f;
    glBegin(GL_QUAD_STRIP);
    int h_segs = 36;
    for (int i = 0; i <= h_segs; i++) {
        float h_val = (float)i / (float)h_segs;
        float hr, hg, hb;
        hsv_to_rgb(h_val, 1.0f, 1.0f, &hr, &hg, &hb);
        glColor3f(hr, hg, hb);
        glVertex2f(sx + 20 + h_val * bar_w, hue_y);
        glVertex2f(sx + 20 + h_val * bar_w, hue_y + hue_h);
    }
    glEnd();
    gl_draw_rect_outline(sx + 20, hue_y, bar_w, hue_h, 0.4f, 0.4f, 0.45f, 1.0f);

    // Hue Seçici İmleç
    float hue_cursor_x = sx + 20 + g_ui.cur_h * bar_w;
    gl_draw_rect(hue_cursor_x - 2, hue_y - 2, 4, hue_h + 4, 1.0f, 1.0f, 1.0f, 1.0f);

    // Doygunluk ve Parlaklık (SV) Kutusu
    float sv_y = 145.0f;
    float sv_h = 75.0f;
    glBegin(GL_QUADS);
    float pure_r, pure_g, pure_b;
    hsv_to_rgb(g_ui.cur_h, 1.0f, 1.0f, &pure_r, &pure_g, &pure_b);
    glColor3f(1.0f, 1.0f, 1.0f); glVertex2f(sx + 20, sv_y);
    glColor3f(pure_r, pure_g, pure_b); glVertex2f(sx + 20 + bar_w, sv_y);
    glColor3f(0.0f, 0.0f, 0.0f); glVertex2f(sx + 20 + bar_w, sv_y + sv_h);
    glColor3f(0.0f, 0.0f, 0.0f); glVertex2f(sx + 20, sv_y + sv_h);
    glEnd();
    gl_draw_rect_outline(sx + 20, sv_y, bar_w, sv_h, 0.4f, 0.4f, 0.45f, 1.0f);

    // SV İmleç
    float sv_cursor_x = sx + 20 + g_ui.cur_s * bar_w;
    float sv_cursor_y = sv_y + (1.0f - g_ui.cur_v) * sv_h;
    gl_draw_circle(sv_cursor_x, sv_cursor_y, 4.0f, 1.0f, 1.0f, 1.0f, 1.0f);
    gl_draw_circle(sv_cursor_x, sv_cursor_y, 3.0f, 0.0f, 0.0f, 0.0f, 1.0f);

    gl_draw_rect(sx + 20, 235, bar_w, 1.0f, 0.2f, 0.2f, 0.22f, 1.0f);

    // 4. Sürgüler (Sliders)
    float slider_base_y = 250.0f;
    float slider_spacing = 58.0f;
    for (int i = 0; i < 4; i++) {
        float sy_pos = slider_base_y + i * slider_spacing;
        // Etiket
        glPointSize(1.5f);
        gl_draw_string(sx + 20, sy_pos, 1.2f, g_ui.sliders[i].label, 0.85f, 0.85f, 0.85f);

        // Değer Metni
        char val_str[16];
        snprintf(val_str, sizeof(val_str), "%.2f", g_ui.sliders[i].val);
        gl_draw_string(sx + sw - 60, sy_pos, 1.1f, val_str, 0.6f, 0.6f, 0.65f);

        // Ray
        float track_y = sy_pos + 18.0f;
        float track_h = 6.0f;
        gl_draw_rect(sx + 20, track_y, bar_w, track_h, 0.18f, 0.18f, 0.20f, 1.0f);

        // Doldurulan Kısım (Vurgu Rengi)
        float pct = (g_ui.sliders[i].val - g_ui.sliders[i].min_val) / (g_ui.sliders[i].max_val - g_ui.sliders[i].min_val);
        if (pct < 0.0f) pct = 0.0f;
        if (pct > 1.0f) pct = 1.0f;
        gl_draw_rect(sx + 20, track_y, pct * bar_w, track_h, 0.0f, 0.48f, 0.80f, 1.0f);

        // Tutacak (Thumb Knob)
        float thumb_x = sx + 20 + pct * bar_w;
        gl_draw_circle(thumb_x, track_y + track_h / 2.0f, 7.0f, 0.9f, 0.9f, 0.95f, 1.0f);
        gl_draw_circle(thumb_x, track_y + track_h / 2.0f, 4.0f, 0.0f, 0.48f, 0.80f, 1.0f);
    }
}

int widgets_on_mouse_down(float mx, float my, int btn, void* canvas_ptr) {
    if (btn != 1) return 0; // Sadece sol tıkla arayüz kontrolü

    // 12'li Palet Tıklaması
    float swatch_w = 22.0f;
    float swatch_h = 20.0f;
    for (int i = 0; i < 12; i++) {
        int row = i / 6;
        int col = i % 6;
        float bx = 75 + col * (swatch_w + 5);
        float by = 55 + row * (swatch_h + 5);
        if (mx >= bx && mx <= bx + swatch_w && my >= by && my <= by + swatch_h) {
            g_ui.cur_r = PALETTE[i][0];
            g_ui.cur_g = PALETTE[i][1];
            g_ui.cur_b = PALETTE[i][2];
            canvas_set_brush_color(canvas_ptr, g_ui.cur_r, g_ui.cur_g, g_ui.cur_b);
            return 1;
        }
    }

    // Hue Çubuğu Tıklaması
    float bar_w = 210.0f;
    if (mx >= 20 && mx <= 20 + bar_w && my >= 115 && my <= 135) {
        g_ui.active_drag = 10;
        float h_val = (mx - 20) / bar_w;
        if (h_val < 0.0f) h_val = 0.0f;
        if (h_val > 1.0f) h_val = 1.0f;
        g_ui.cur_h = h_val;
        hsv_to_rgb(g_ui.cur_h, g_ui.cur_s, g_ui.cur_v, &g_ui.cur_r, &g_ui.cur_g, &g_ui.cur_b);
        canvas_set_brush_color(canvas_ptr, g_ui.cur_r, g_ui.cur_g, g_ui.cur_b);
        return 1;
    }

    // SV Kutusu Tıklaması
    if (mx >= 20 && mx <= 20 + bar_w && my >= 145 && my <= 220) {
        g_ui.active_drag = 11;
        float s_val = (mx - 20) / bar_w;
        float v_val = 1.0f - (my - 145) / 75.0f;
        if (s_val < 0.0f) s_val = 0.0f; if (s_val > 1.0f) s_val = 1.0f;
        if (v_val < 0.0f) v_val = 0.0f; if (v_val > 1.0f) v_val = 1.0f;
        g_ui.cur_s = s_val;
        g_ui.cur_v = v_val;
        hsv_to_rgb(g_ui.cur_h, g_ui.cur_s, g_ui.cur_v, &g_ui.cur_r, &g_ui.cur_g, &g_ui.cur_b);
        canvas_set_brush_color(canvas_ptr, g_ui.cur_r, g_ui.cur_g, g_ui.cur_b);
        return 1;
    }

    // Sürgüler
    float slider_base_y = 250.0f;
    float slider_spacing = 58.0f;
    for (int i = 0; i < 4; i++) {
        float sy_pos = slider_base_y + i * slider_spacing;
        if (mx >= 15 && mx <= 235 && my >= sy_pos + 10 && my <= sy_pos + 35) {
            g_ui.active_drag = i;
            float pct = (mx - 20) / bar_w;
            if (pct < 0.0f) pct = 0.0f;
            if (pct > 1.0f) pct = 1.0f;
            float new_val = g_ui.sliders[i].min_val + pct * (g_ui.sliders[i].max_val - g_ui.sliders[i].min_val);
            g_ui.sliders[i].val = new_val;
            canvas_set_brush_setting(canvas_ptr, g_ui.sliders[i].setting_id, new_val);
            return 1;
        }
    }
    return 1;
}

int widgets_on_mouse_move(float mx, float my, void* canvas_ptr) {
    if (g_ui.active_drag < 0) return 0;
    float bar_w = 210.0f;

    if (g_ui.active_drag == 10) { // Hue Sürükleme
        float h_val = (mx - 20) / bar_w;
        if (h_val < 0.0f) h_val = 0.0f; if (h_val > 1.0f) h_val = 1.0f;
        g_ui.cur_h = h_val;
        hsv_to_rgb(g_ui.cur_h, g_ui.cur_s, g_ui.cur_v, &g_ui.cur_r, &g_ui.cur_g, &g_ui.cur_b);
        canvas_set_brush_color(canvas_ptr, g_ui.cur_r, g_ui.cur_g, g_ui.cur_b);
        return 1;
    } else if (g_ui.active_drag == 11) { // SV Sürükleme
        float s_val = (mx - 20) / bar_w;
        float v_val = 1.0f - (my - 145) / 75.0f;
        if (s_val < 0.0f) s_val = 0.0f; if (s_val > 1.0f) s_val = 1.0f;
        if (v_val < 0.0f) v_val = 0.0f; if (v_val > 1.0f) v_val = 1.0f;
        g_ui.cur_s = s_val;
        g_ui.cur_v = v_val;
        hsv_to_rgb(g_ui.cur_h, g_ui.cur_s, g_ui.cur_v, &g_ui.cur_r, &g_ui.cur_g, &g_ui.cur_b);
        canvas_set_brush_color(canvas_ptr, g_ui.cur_r, g_ui.cur_g, g_ui.cur_b);
        return 1;
    } else if (g_ui.active_drag >= 0 && g_ui.active_drag < 4) { // Sürgü Sürükleme
        int i = g_ui.active_drag;
        float pct = (mx - 20) / bar_w;
        if (pct < 0.0f) pct = 0.0f; if (pct > 1.0f) pct = 1.0f;
        float new_val = g_ui.sliders[i].min_val + pct * (g_ui.sliders[i].max_val - g_ui.sliders[i].min_val);
        g_ui.sliders[i].val = new_val;
        canvas_set_brush_setting(canvas_ptr, g_ui.sliders[i].setting_id, new_val);
        return 1;
    }
    return 0;
}

void widgets_on_mouse_up(void* canvas_ptr) {
    g_ui.active_drag = -1;
}

int widgets_is_dragging(void) {
    return g_ui.active_drag >= 0;
}
%}

// ATS2 FFI İmzaları
extern fun widgets_render(sx: float, sy: float, sw: float, sh: float): void = "mac#"
extern fun widgets_on_mouse_down(mx: float, my: float, btn: int, canvas_ptr: ptr): int = "mac#"
extern fun widgets_on_mouse_move(mx: float, my: float, canvas_ptr: ptr): int = "mac#"
extern fun widgets_on_mouse_up(canvas_ptr: ptr): void = "mac#"
extern fun widgets_is_dragging(): int = "mac#"
