{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config  # CMake'in kütüphaneleri bulmasını kolaylaştırır
    ats2
  ];

  buildInputs = with pkgs; [
    fltk
    libmypaint
    json_c
    
    # --- EKSİK OLAN OPENGL KÜTÜPHANELERİ ---
    libGL
    libGLU
    # ---------------------------------------
    
    xorg.libX11
    xorg.libXext
    xorg.libXrender
  ];
  
shellHook = ''
    # ATS2'nin kurulu olduğu gerçek kütüphane dizinini otomatik bul:
    export PATSHOME=$(ls -d ${pkgs.ats2}/lib/ats2-postiats-* 2>/dev/null | head -n 1)
    
    # Her ihtimale karşı share dizininde de arama (farklı bir nixpkgs versiyonu için)
    if [ -z "$PATSHOME" ]; then
      export PATSHOME=$(ls -d ${pkgs.ats2}/share/ats2-postiats-* 2>/dev/null | head -n 1)
    fi

    export PATSHOMERELOC=$PATSHOME
    
    echo "========================================="
    echo "ATS2 Geliştirme Ortamı Hazır."
    echo "Gerçek PATSHOME = $PATSHOME"
    patscc -version
    echo "========================================="
  '';
}
