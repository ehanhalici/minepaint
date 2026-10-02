{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cmake
    ats2
  ];

  buildInputs = with pkgs; [
    libGL
    libx11
    libxext
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
    patsopt --version
    echo "========================================="
  '';
}
