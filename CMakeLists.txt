cmake_minimum_required(VERSION 3.10)
project(minepaint)

set(CMAKE_CXX_STANDARD 17)

# --- 1. STATİK DERLEME AYARLARI (KRİTİK) ---

# A. Linker'a statik derleme yapmasını söyle. (Bu, sistem kütüphaneleri için zorunludur.)
#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")

# B. CMake'e, kütüphaneleri ararken önce .a (statik) uzantılı dosyaları bulmasını söyle.
#set(CMAKE_FIND_LIBRARY_SUFFIXES ".a" ".so" ${CMAKE_FIND_LIBRARY_SUFFIXES})

add_definitions(-DGL_GLEXT_PROTOTYPES)

# FLTK paketini bul
# C. FLTK'ya statik kütüphaneyi (fltk.a) bulmasını iste.
find_package(FLTK REQUIRED NO_MODULE) 
include_directories(${FLTK_INCLUDE_DIRS})

# OpenGL paketini bul
set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED)
find_package(PkgConfig REQUIRED)

# D. PkgConfig'e de statik kütüphaneleri aramasını söyle.
set(PKG_CONFIG_STATIC_LIBS TRUE)
pkg_check_modules(DEPS REQUIRED json-c glib-2.0)

# --- Geri kalan kod (Aynı kalmalı) ---

include_directories(include)
# --- LIBMYPAINT BAĞLANTISI ---

# find_library zaten .a'yı öncelikli arayacaktır
find_library(MYPAINT_LIB 
    NAMES mypaint mypaint-2.0 mypaint-1.5
    PATHS 
        "${CMAKE_SOURCE_DIR}/dependencies/libmypaint/.libs" 
        "${CMAKE_SOURCE_DIR}/dependencies/libmypaint"
    NO_DEFAULT_PATH
)

if(NOT MYPAINT_LIB)
    message(FATAL_ERROR "HATA: libmypaint kütüphanesi bulunamadı! 'dependencies/libmypaint' içinde 'make' çalıştırdın mı?")
else()
    message(STATUS "LibMyPaint Bulundu: ${MYPAINT_LIB}")
endif()

# Header dosyalarının yeri
include_directories(dependencies/libmypaint) 

# Statik linklemede link_directories çok gerekli değildir ama kalsın
link_directories(dependencies/libmypaint/.libs)

include_directories(${FLTK_INCLUDE_DIRS} ${DEPS_INCLUDE_DIRS})

set(PROJECT_SOURCES
    src/main.cpp
    src/Layer.cpp
    src/MyCanvas.cpp
    src/MyGLSurface.cpp
    src/Ui.cpp
)

add_executable(minepaint ${PROJECT_SOURCES})

# Kütüphaneleri linkle
# Linux'ta statik linklemede sıralama önemlidir. En bağımlı olandan sistem kütüphanesine doğru.
# Kütüphaneleri linkle
target_link_libraries(minepaint 
    # YEREL VE STATİK KALACAK KÜTÜPHANELER
    ${MYPAINT_LIB}      # libmypaint'ın statik (.a) sürümü
    fltk                # FLTK'nın statik sürümü
    fltk_gl             # FLTK'nın OpenGL kısmı

    # SİSTEM DİNAMİK KALACAK KÜTÜPHANELER (OpenGL/GLIBC)
    -Wl,-Bdynamic ${OPENGL_LIBRARIES} # libGL.so ve türevlerini dinamik bağla
    -Wl,-Bdynamic ${DEPS_LIBRARIES}   # json-c, glib (dinamik kalsın)
    -Wl,-Bdynamic m                   # libm
    -Wl,-Bdynamic gomp                # libgomp
)
