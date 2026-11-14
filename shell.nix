{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  hardeningDisable = [ "fortify" ];

  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    ats2
    clang
    lld
  ];

  buildInputs = with pkgs; [
    libGL
    libx11
    libxext
    libxfixes
    libxi
  ];

  shellHook = ''
    # ATS2 ortam değişkenleri
    export PATSHOME=$(ls -d ${pkgs.ats2}/lib/ats2-postiats-* 2>/dev/null | head -n 1)
    if [ -z "$PATSHOME" ]; then
      export PATSHOME=$(ls -d ${pkgs.ats2}/share/ats2-postiats-* 2>/dev/null | head -n 1)
    fi
    export PATSHOMERELOC=$PATSHOME

    # Donanım hızlandırmalı OpenGL sürücü yolu
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH"

    unset NIX_ENFORCE_NO_NATIVE
    export NIX_HARDENING_ENABLE="''${NIX_HARDENING_ENABLE//fortify/}"


    echo "========================================="
    echo "ATS2 Geliştirme Ortamı Hazır."
    echo "Gerçek PATSHOME = $PATSHOME"
    patsopt --version
    echo "Clang:"
    clang --version | head -n 1
    echo "Debug:   bash compile.sh -d"
    echo "Release: bash compile.sh -r"
    echo "========================================="

 '';
}
