// --- 1. ATS PRELUDE VE STANDART KÜTÜPHANELER ---
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// --- 2. MODÜL YÜKLEMELERİ (STALOAD) ---
// Uygulamanın UI mantığını ve state yönetimini barındıran modülü dahil ediyoruz.
// Bu dosya, FFI üzerinden ffi_bindings.cpp ile konuşacak olan arayüzdür.
staload "./Ui.dats"

// --- 3. ANA GİRİŞ NOKTASI (ENTRY POINT) ---

(*
 * implement main0: ATS'nin standart main fonksiyonu uygulamasıdır.
 * * argc: Argüman sayısı (statik olarak tamsayı olduğu ispatlıdır).
 * argv: Argüman listesi (pointer güvenliği ATS'nin bağımlı tipleriyle korunur).
 *)
implement main0 (argc, argv) = let
  // ATS dünyasında programın yaşam döngüsü burada başlar.
  
  // ui_init fonksiyonu:
  // 1. Ui.dats içinde tanımlanmıştır.
  // 2. ffi_bindings.cpp üzerindeki ffi_ui_init() fonksiyonunu tetikler.
  // 3. FLTK pencerelerini, MyCanvas'ı ve MyPaint fırça motorunu ayağa kaldırır.
  
  // val status: Fl::run() döngüsü bittiğinde dönen çıkış kodu (0 veya 1).
  val status = ui_init(argc, argv)
  
in
  // Not: ATS'de main0 void (unit) tipi döner. 
  // İşlem sona erdiğinde çalışma zamanı (runtime) otomatik olarak temizlik yapar.
  // Eğer özel bir çıkış kodu (exit code) ile çıkmak isterseniz 'main1' kullanılabilir.
  
  // Program FLTK olay döngüsünden çıktığında kontrol buraya döner.
end