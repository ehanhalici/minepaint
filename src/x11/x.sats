(* MinePaint'in kullandığı Xlib yüzeyi. *)

%{#
#include "x11/x.cats"
%}

#define ATS_PACKNAME "ATSCNTRB.X11"
#define ATS_EXTERN_PREFIX "atscntrb_X11_"

abst@ype Window = $extype "Window"
abst@ype Cursor = $extype "Cursor"

absvtype Display_ptr (l:addr) = ptr(l)
vtypedef Display_ptr0 = [l:agez] Display_ptr(l)
vtypedef Display_ptr1 = [l:addr | l > null] Display_ptr(l)

fun Display_ptr_is_null{l:addr} (dpy: !Display_ptr(l)): bool (l == null) = "atspre_ptr_is_null"
fun Display_ptr_isnot_null{l:addr} (dpy: !Display_ptr(l)): bool (l > null) = "atspre_ptr_isnot_null"
overload iseqz with Display_ptr_is_null
overload isneqz with Display_ptr_isnot_null

macdef AllocNone = $extval(int, "AllocNone")
macdef InputOutput = $extval(int, "InputOutput")

fun XOpenDisplay(Stropt): Display_ptr0 = "mac#%"
fun XDefaultScreen{l:agz}(!Display_ptr(l)): int = "mac#%"
fun XRootWindow{l:agz}(!Display_ptr(l), int): Window = "mac#%"
fun XMapWindow{l:agz}(!Display_ptr(l), Window): void = "mac#%"
fun XDefineCursor{l:agz}(!Display_ptr(l), Window, Cursor): void = "mac#%"
fun XDestroyWindow{l:agz}(!Display_ptr(l), Window): void = "mac#%"
fun XCloseDisplay(Display_ptr1): void = "mac#%"
