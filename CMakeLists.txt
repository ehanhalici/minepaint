cmake_minimum_required(VERSION 3.10)
project(minepaint C)

set(CMAKE_C_STANDARD 99) 
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -include math.h -include stdlib.h -include string.h -Wno-implicit-function-declaration")

# --- ATS2 ENTEGRASYONU ---
set(PATSHOME $ENV{PATSHOME})
if("${PATSHOME}" STREQUAL "")
    message(FATAL_ERROR "HATA: PATSHOME ortam değişkeni bulunamadı. nix-shell içinde olduğunuzdan emin olun.")
endif()

include_directories("${PATSHOME}" "${PATSHOME}/ccomp/runtime")

add_definitions(-DGL_GLEXT_PROTOTYPES)

# X11 ve OpenGL paketlerini bul
find_package(X11 REQUIRED)
include_directories(${X11_INCLUDE_DIR})

set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED)

include_directories(${X11_INCLUDE_DIR} ${OPENGL_INCLUDE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/src/draw_engine)

# --- 1. ATS DOSYALARINI TANIMLAMA ---
set(ATS_SOURCES
    src/draw_engine/settings.dats
    src/draw_engine/helpers.dats
    src/draw_engine/fifo.dats
    src/draw_engine/rectangle.dats
    src/draw_engine/matrix.dats
    src/draw_engine/rng.dats
    src/draw_engine/mapping.dats
    src/draw_engine/symmetry.dats
    src/draw_engine/tilemap.dats
    src/draw_engine/operationqueue.dats
    src/draw_engine/brushmodes.dats
    src/draw_engine/surface.dats
    src/draw_engine/tiled_surface.dats
    src/draw_engine/fixed_tiled_surface.dats
    src/draw_engine/brush_settings.dats
    src/draw_engine/brush.dats
    src/draw_engine/draw_engine.dats
    src/Layer.dats
    src/MyGLSurface.dats
    src/MyCanvas.dats
    src/ui/widgets.dats
    src/ui/window.dats
    src/ui/ui.dats
    src/main.dats
)

set(GENERATED_C_SOURCES "")

# --- 2. ATS -> C DÖNÜŞÜMÜ ---
foreach(ATS_FILE ${ATS_SOURCES})
    get_filename_component(BASE_NAME ${ATS_FILE} NAME_WE)
    set(C_OUT "${CMAKE_CURRENT_BINARY_DIR}/${BASE_NAME}_dats.c")
    
    add_custom_command(
        OUTPUT ${C_OUT}
        COMMAND patsopt --debug --debug2 -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src/draw_engine -IATS $ENV{PATSHOME} -IATS $ENV{PATSHOME}/share -o ${C_OUT} -d ${CMAKE_CURRENT_SOURCE_DIR}/${ATS_FILE} 
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${ATS_FILE}
        COMMENT "[ATS] ${ATS_FILE} -> ${BASE_NAME}_dats.c C dönüşümü yapılıyor..."
    )
    list(APPEND GENERATED_C_SOURCES ${C_OUT})
endforeach()
  
# --- 3. ÇALIŞTIRILABİLİR DOSYA ---
add_executable(minepaint 
    ${GENERATED_C_SOURCES}
)
target_compile_definitions(minepaint PRIVATE ATS_MEMALLOC_LIBC)

# Kütüphaneleri linkle (LibMyPaint tamamen kaldırıldı, yerli draw_engine ile bağlandı)
target_link_libraries(minepaint 
    -Wl,-Bdynamic ${X11_LIBRARIES}
    -Wl,-Bdynamic ${OPENGL_LIBRARIES}
    -Wl,-Bdynamic m
    -Wl,-Bdynamic pthread
)
