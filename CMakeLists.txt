cmake_minimum_required(VERSION 3.16)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Debug veya Release" FORCE)
endif()

find_program(MINEPAINT_CLANG clang REQUIRED)
set(CMAKE_C_COMPILER "${MINEPAINT_CLANG}" CACHE FILEPATH "clang" FORCE)
set(CMAKE_EXE_LINKER_FLAGS "" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS "-Wall -Wextra -Wshadow -pedantic -I${CMAKE_SOURCE_DIR}/src -include ${CMAKE_SOURCE_DIR}/src/sys/cprelude.h -Wno-implicit-function-declaration -Wno-format -U_FORTIFY_SOURCE" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_DEBUG "-O0 -g" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE "-O3 -flto=thin -march=native -funroll-loops -fomit-frame-pointer -fvectorize -fslp-vectorize -DNDEBUG" CACHE STRING "" FORCE)

project(minepaint C)

set(CMAKE_C_STANDARD 99)

set(PATSHOME $ENV{PATSHOME})
if("${PATSHOME}" STREQUAL "")
  message(FATAL_ERROR "HATA: PATSHOME ortam değişkeni bulunamadı. nix-shell içinde olduğunuzdan emin olun.")
endif()

include_directories("${PATSHOME}" "${PATSHOME}/ccomp/runtime")

add_definitions(-DGL_GLEXT_PROTOTYPES)

find_package(X11 REQUIRED)
if(NOT X11_Xi_FOUND OR NOT EXISTS "${X11_Xi_LIB}")
  file(GLOB _CANDIDATES "/nix/store/*libxi*/lib/libXi.so")
  foreach(_cand IN LISTS _CANDIDATES)
    execute_process(COMMAND file -b -L ${_cand} OUTPUT_VARIABLE _cand_type)
    if(_cand_type MATCHES "x86-64")
      set(X11_Xi_LIB "${_cand}" CACHE FILEPATH "libXi" FORCE)
      break()
    endif()
  endforeach()
  file(GLOB _INC_CANDIDATES "/nix/store/*libxi*-dev/include")
  find_path(X11_Xi_INCLUDE_PATH NAMES X11/extensions/XInput2.h PATHS ${X11_INCLUDE_DIR} ${_INC_CANDIDATES})
endif()
file(GLOB _XFIXES_INC_HINTS "/nix/store/*libxfixes*-dev/include")
find_path(X11_Xfixes_INCLUDE_PATH NAMES X11/extensions/Xfixes.h PATHS ${X11_INCLUDE_DIR} ${_XFIXES_INC_HINTS})

set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED)
if(OPENGL_gl_LIBRARY MATCHES "libOpenGL")
  get_filename_component(_gl_dir "${OPENGL_gl_LIBRARY}" DIRECTORY)
  if(EXISTS "${_gl_dir}/libGL.so")
    set(OPENGL_gl_LIBRARY "${_gl_dir}/libGL.so")
    set(OPENGL_LIBRARIES "${_gl_dir}/libGL.so")
  endif()
endif()

include_directories(
  ${X11_INCLUDE_DIR}
  ${X11_Xi_INCLUDE_PATH}
  ${X11_Xfixes_INCLUDE_PATH}
  ${OPENGL_INCLUDE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/src/draw_engine
)

file(GLOB_RECURSE ATS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.dats")
list(SORT ATS_SOURCES)
if(NOT ATS_SOURCES)
  message(FATAL_ERROR "src altında .dats bulunamadı")
endif()

set(GENERATED_C_SOURCES "")
set(SEEN_BASE "")

foreach(ATS_FILE ${ATS_SOURCES})
  get_filename_component(BASE_NAME ${ATS_FILE} NAME_WE)
  if(BASE_NAME IN_LIST SEEN_BASE)
    message(FATAL_ERROR "Aynı ada sahip iki .dats var, C çıktısı çakışır: ${BASE_NAME}")
  endif()
  list(APPEND SEEN_BASE ${BASE_NAME})

  file(RELATIVE_PATH REL_ATS "${CMAKE_SOURCE_DIR}" "${ATS_FILE}")
  set(C_OUT "${CMAKE_CURRENT_BINARY_DIR}/${BASE_NAME}_dats.c")
  add_custom_command(
    OUTPUT ${C_OUT}
    COMMAND patsopt --debug --debug2
      -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src
      -IATS ${CMAKE_CURRENT_SOURCE_DIR}/src/draw_engine
      -IATS $ENV{PATSHOME}
      -IATS $ENV{PATSHOME}/share
      -o ${C_OUT}
      -d ${REL_ATS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${ATS_FILE}
    COMMENT "[ATS] ${REL_ATS} -> ${BASE_NAME}_dats.c"
  )
  list(APPEND GENERATED_C_SOURCES ${C_OUT})
endforeach()

add_executable(minepaint ${GENERATED_C_SOURCES})
target_compile_definitions(minepaint PRIVATE ATS_MEMALLOC_LIBC)

set(MINEPAINT_RPATH_DIRS "")
foreach(lib IN LISTS X11_LIBRARIES X11_Xi_LIB OPENGL_LIBRARIES)
  if(IS_ABSOLUTE "${lib}")
    get_filename_component(libdir "${lib}" DIRECTORY)
    list(APPEND MINEPAINT_RPATH_DIRS "${libdir}")
  endif()
endforeach()
list(REMOVE_DUPLICATES MINEPAINT_RPATH_DIRS)
foreach(dir IN LISTS MINEPAINT_RPATH_DIRS)
  target_link_options(minepaint PRIVATE "-Wl,-rpath,${dir}" "-Wl,--disable-new-dtags")
endforeach()

target_link_libraries(minepaint m ${X11_LIBRARIES} ${X11_Xi_LIB} ${OPENGL_LIBRARIES})

if(CMAKE_BUILD_TYPE STREQUAL "Release")
  target_link_options(minepaint PRIVATE -flto=thin -fuse-ld=lld)
endif()
