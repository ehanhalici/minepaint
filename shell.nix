{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  hardeningDisable = [ "fortify" ];

  nativeBuildInputs = with pkgs; [
    cmake
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
    export PATSHOME=$(ls -d ${pkgs.ats2}/lib/ats2-postiats-* 2>/dev/null | head -n 1)
    if [ -z "$PATSHOME" ]; then
      export PATSHOME=$(ls -d ${pkgs.ats2}/share/ats2-postiats-* 2>/dev/null | head -n 1)
    fi
    export PATSHOMERELOC=$PATSHOME

    unset NIX_ENFORCE_NO_NATIVE
    export NIX_HARDENING_ENABLE="''${NIX_HARDENING_ENABLE//fortify/}"

    echo "========================================="
    echo "ATS2 Geliştirme Ortamı Hazır."
    echo "Gerçek PATSHOME = $PATSHOME"
    patsopt --version
    echo "Clang:"
    clang --version | head -n 1
    echo "Debug:  sh compile.sh Debug"
    echo "Release: sh compile.sh Release"
    echo "========================================="
  '';
}
