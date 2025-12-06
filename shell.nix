{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "fltk-dev-shell";

nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    gcc
    autoconf
    automake
    libtool
    intltool
  ];

  buildInputs = with pkgs; [
    fltk
    libGL
    libGLU
    xorg.libX11
    # Libmypaint bağımlılıkları
    json_c
    glib
    gettext
  ];
  
  shellHook = ''
    echo "FLTK + OpenGL Geliştirme Ortamı Hazır!"
  '';
}
