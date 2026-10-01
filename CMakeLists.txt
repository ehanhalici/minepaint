cmake_minimum_required(VERSION 3.10)
project(minepaint C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 99) 

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
find_package(PkgConfig REQUIRED)

# PkgConfig ile bağımlılıkları kontrol et
set(PKG_CONFIG_STATIC_LIBS TRUE)
pkg_check_modules(DEPS REQUIRED json-c glib-2.0)

# --- LIBMYPAINT BAĞLANTISI ---
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
link_directories(dependencies/libmypaint/.libs)

include_directories(${X11_INCLUDE_DIR} ${OPENGL_INCLUDE_DIR} ${DEPS_INCLUDE_DIRS})

# --- 1. ATS DOSYALARINI TANIMLAMA ---
set(ATS_SOURCES
    src/main.dats
    src/Layer.dats
    src/MyCanvas.dats
    src/MyGLSurface.dats
    src/ui/widgets.dats
    src/ui/window.dats
    src/ui/ui.dats
)

set(GENERATED_C_SOURCES "")

# --- 2. ATS -> C DÖNÜŞÜMÜ ---
foreach(ATS_FILE ${ATS_SOURCES})
    get_filename_component(BASE_NAME ${ATS_FILE} NAME_WE)
    set(C_OUT "${CMAKE_CURRENT_BINARY_DIR}/${BASE_NAME}_dats.c")
    
    add_custom_command(
        OUTPUT ${C_OUT}
        COMMAND patsopt --debug --debug2 -IATS $ENV{PATSHOME} -IATS $ENV{PATSHOME}/share -o ${C_OUT} -d ${CMAKE_CURRENT_SOURCE_DIR}/${ATS_FILE} 
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

# Kütüphaneleri linkle
target_link_libraries(minepaint 
    # YEREL VE STATİK KALACAK KÜTÜPHANELER
    ${MYPAINT_LIB}

    # SİSTEM KÜTÜPHANELERİ
    -Wl,-Bdynamic ${X11_LIBRARIES}
    -Wl,-Bdynamic ${OPENGL_LIBRARIES}
    -Wl,-Bdynamic ${DEPS_LIBRARIES}
    -Wl,-Bdynamic m
    -Wl,-Bdynamic pthread
    -Wl,-Bdynamic gomp
)
