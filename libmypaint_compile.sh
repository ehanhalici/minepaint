# 1. Proje klasörüne git
cd dependencies/libmypaint

# 2. Gerekli dosyaları oluştur
./autogen.sh

# 3. STATİK ve DİNAMİK KÜTÜPHANELERİN YÖNETİMİ
# --enable-static: Statik kütüphane (.a) oluşturmayı zorlar.
# --disable-shared: Dinamik kütüphane (.so) oluşturmayı engeller.
# PKG_CONFIG_LIBS: Bağımlılıkların (glib, json-c) statik sürümlerini aramasını sağlar.

# Not: Bu satır, bağımlı kütüphanelerin (glib, json-c) de statik sürümlerinin 
# sisteminizde (NixOS ortamınızda) kurulu olmasını gerektirir.
PKG_CONFIG_LIBS="--static" \
./configure --enable-static --disable-shared --enable-openmp --disable-introspection

# 4. Derleme (j=işlemci sayısı)
make -j $(nproc)

# 5. Ana proje klasörüne dön
cd ../..
