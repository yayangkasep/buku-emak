Kamu adalah Flutter developer. Tugasmu adalah mengupdate konfigurasi launcher icon 
agar mendukung Android Adaptive Icon.

## Konteks
Project Flutter ini menggunakan package `flutter_launcher_icons`. Konfigurasi 
saat ini di `pubspec.yaml` BELUM memiliki support adaptive icon, sehingga icon 
aplikasi terlihat tidak konsisten dengan aplikasi lain di Android 12+.

## Konfigurasi Saat Ini (di pubspec.yaml)
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21

## Tugas Kamu
1. Update bagian flutter_launcher_icons di `pubspec.yaml` untuk menambahkan 
   konfigurasi adaptive icon
2. Warna background adaptive icon menggunakan putih (#FFFFFF)
3. Foreground adaptive icon menggunakan "assets/icon/app_icon_foreground.png"
4. Jalankan perintah `dart run flutter_launcher_icons` untuk generate icon
5. Verifikasi file hasil generate ada di `android/app/src/main/res/mipmap-anydpi-v26/`

## Ketentuan
- Jangan hapus konfigurasi yang sudah ada, hanya TAMBAHKAN field adaptive icon
- Jangan ubah image_path yang sudah ada (digunakan untuk iOS dan Android lama)
- Jika file foreground belum ada, SALIN file `assets/icon/app_icon.png` 
  menjadi `assets/icon/app_icon_foreground.png` sebagai placeholder
- Laporkan file apa saja yang dibuat atau diubah

## Kriteria Berhasil
- File `mipmap-anydpi-v26/launcher_icon.xml` ada dan berisi tag <adaptive-icon>
- Tidak ada fitur yang rusak setelah perubahan