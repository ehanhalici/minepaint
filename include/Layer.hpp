#ifndef LAYER_H
#define LAYER_H

#include <FL/gl.h>
#include <FL/glu.h>

class Layer {
private:
    GLuint fbo;       // Framebuffer ID
    GLuint texture;   // Doku (Resim) ID
    int width;
    int height;
    bool initialized;

public:
    Layer(int w, int h);
    ~Layer();

    void resize(int w, int h);

    // Çizim modunu açar (Bundan sonraki OpenGL komutları bu katmana işlenir)
    void bind();

    // Çizim modunu kapatır (Tekrar ekrana dönülür)
    void unbind();

    // Katmanı temizler (Şeffaf hale getirir)
    void clear();

    // Katmanı ekrana (veya başka bir FBO'ya) çizer
    void drawOnScreen(int window_width, int window_height);
    
    // Geçerli texture ID'sini döndürür (Gerekirse)
    GLuint getTextureID() const { return texture; }
};

#endif
