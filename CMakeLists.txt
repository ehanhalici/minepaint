cmake_minimum_required(VERSION 3.10)
project(minepaint)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 99) 

# --- ATS2 ENTEGRASYONU ---
set(PATSHOME $ENV{PATSHOME})
if("${PATSHOME}" STREQUAL "")
    message(FATAL_ERROR "HATA: PATSHOME ortam değişkeni bulunamadı. nix-shell içinde olduğunuzdan emin olun.")
endif()


include_directories("${PATSHOME}" "${PATSHOME}/ccomp/runtime")
include_directories(include)

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

# --- 1. ATS DOSYALARINI TANIMLAMA ---
set(ATS_SOURCES
    src/main.dats
    src/Ui.dats
    src/Layer.dats
    src/MyCanvas.dats
    src/MyGLSurface.dats
)

set(GENERATED_C_SOURCES "")

# --- 2. ATS -> C DÖNÜŞÜMÜ ---
foreach(ATS_FILE ${ATS_SOURCES})
    get_filename_component(BASE_NAME ${ATS_FILE} NAME_WE)
    set(C_OUT "${CMAKE_CURRENT_BINARY_DIR}/${BASE_NAME}_dats.c")
    
    add_custom_command(
        OUTPUT ${C_OUT}
        # $ENV{PATSHOME} kullanarak Nix'teki kütüphane yolunu içeri aktarıyoruz
        COMMAND patsopt --debug --debug2  -IATS $ENV{PATSHOME} -IATS $ENV{PATSHOME}/share -o ${C_OUT} -d ${CMAKE_CURRENT_SOURCE_DIR}/${ATS_FILE} 
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${ATS_FILE}
        COMMENT "[ATS] ${ATS_FILE} -> ${BASE_NAME}_dats.c C dönüşümü yapılıyor..."
    )
    list(APPEND GENERATED_C_SOURCES ${C_OUT})
  endforeach()
  
# --- 3. ÇALIŞTIRILABİLİR DOSYA ---
add_executable(minepaint 
    ${GENERATED_C_SOURCES} 
    src/ffi_bindings.cpp # C++ kütüphanelerine (FLTK vb.) tek köprümüz
  )
target_compile_definitions(minepaint PRIVATE ATS_MEMALLOC_LIBC)
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
