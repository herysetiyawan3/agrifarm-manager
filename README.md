# AgriFarm Manager 🌿📱

**AgriFarm Manager** adalah aplikasi manajemen pertanian modern berbasis **Flutter** dan **Firebase** yang dirancang khusus untuk membantu petani, pemilik kebun, dan manajer pertanian dalam mengelola seluruh siklus pertanian secara efektif. Aplikasi ini mendukung **Offline Persistence** (penyimpanan offline), memastikan data tetap dapat dibaca dan ditulis di area lahan yang minim sinyal, dan akan otomatis tersinkronisasi ketika perangkat terhubung ke internet.

---

## ⚙️ Panduan Setup & Konfigurasi Lengkap

Agar aplikasi dapat berjalan di lingkungan lokal Anda dan terhubung dengan Firebase serta Google Auth, ikuti langkah-langkah konfigurasi berikut dengan teliti.

### 1. Prasyarat Sistem (Prerequisites)
Sebelum memulai, pastikan perangkat pengembangan Anda telah terinstal:
* **Flutter SDK**: Versi `>= 3.2.3` (Saluran Stable)
* **Dart SDK**: Versi `>= 3.2.3 < 4.0.0`
* **Java Development Kit (JDK)**: Versi `17` (Disarankan menggunakan JDK bawaan Android Studio di `C:\Program Files\Android\Android Studio\jbr` atau OpenJDK 17)
* **Android SDK**: API Level 33 atau lebih tinggi dengan Android Build Tools terbaru

---

### 2. Pendaftaran Fingerprint SHA-1 di Firebase Console (Sangat Krusial untuk Google Sign-In)
Google Sign-In memerlukan sidik jari sertifikat SHA-1 dari mesin pengembangan Anda agar autentikasi tidak memicu **Developer Error (Status Code 10)**.

#### A. Cara Mendapatkan SHA-1 Debug (Lokal)
Buka terminal (PowerShell atau Command Prompt) di komputer Anda, lalu jalankan perintah berikut:

* **Menggunakan Keytool (Windows):**
  ```powershell
  keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android
  ```
* **Menggunakan Gradle (Rekomendasi - Jalankan dari root folder proyek):**
  ```powershell
  cd android
  ./gradlew signingReport
  ```
  Cari bagian output `Variant: debug` dan salin baris kode **SHA-1** (contoh: `B0:01:E5:80:41:B2:FC:2D:8C:5D:6F:3D:54:3A:10:5F:9C:AD:E2:22`).

#### B. Cara Mendapatkan SHA-1 Release (Untuk APK Produksi)
Jika Anda merilis aplikasi ke Google Play Store atau membuat APK rilis yang ditandatangani sendiri (self-signed):
1. Jika ditandatangani sendiri, jalankan `keytool` pada berkas keystore rilis Anda:
   ```powershell
   keytool -list -v -keystore <path-keystore-rilis-anda> -alias <alias-keystore>
   ```
2. Jika menggunakan Google Play App Signing, salin SHA-1 dari tab **Setup -> App Integrity** di Google Play Console Anda.

#### C. Mendaftarkan SHA-1 ke Firebase
1. Buka [Firebase Console](https://console.firebase.google.com/).
2. Pilih proyek Anda (**tani-hub**).
3. Klik ikon gigi roda (Project Settings) -> **General**.
4. Gulir ke bawah ke bagian **Your apps** -> **Android app (com.agrifarm.agrifarm_manager)**.
5. Klik **Add fingerprint** dan tempelkan sidik jari SHA-1 Anda (baik debug maupun release).
6. Klik **Save**.
7. Unduh kembali berkas **google-services.json** terbaru.

---

### 3. Integrasi Berkas Firebase ke Proyek
1. Letakkan berkas `google-services.json` yang baru diunduh ke direktori proyek Anda di:
   `android/app/google-services.json`
2. **Penting untuk Keamanan (Gitignore):** Pastikan berkas `google-services.json` tidak diunggah ke repositori publik untuk melindungi kredensial Firebase Anda. File ini telah ditambahkan ke berkas `.gitignore` utama.

---

### 4. Konfigurasi Layanan di Firebase Console
Pastikan layanan berikut telah diaktifkan dan dikonfigurasi di Firebase Console Anda:

#### A. Firebase Authentication
* Buka tab **Authentication** -> **Sign-in method**.
* Aktifkan metode **Email/Password**.
* Aktifkan metode **Google**. Pastikan Anda memilih email dukungan proyek dan menyimpan konfigurasi tersebut.
* Salin **Web client ID** yang dihasilkan di bawah pengaturan Google provider jika diperlukan untuk konfigurasi OAuth.

#### B. Cloud Firestore (Aturan Database)
Salin aturan keamanan berikut ke tab **Rules** di Cloud Firestore Console Anda untuk memastikan keamanan data antar pengguna:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Memastikan user hanya bisa membaca dan menulis data mereka sendiri
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

#### C. Firebase Storage (Aturan Penyimpanan Gambar)
Gunakan aturan penyimpanan berikut agar pengguna terautentikasi dapat mengunggah foto struk belanja inventaris atau dokumentasi hama/penyakit:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 💻 Panduan Menjalankan & Membangun Aplikasi

### 1. Unduh Dependensi
Jalankan perintah berikut di root folder proyek untuk mengunduh semua paket Flutter yang dibutuhkan:
```powershell
flutter pub get
```

### 2. Jalankan Aplikasi dalam Mode Debug
Hubungkan HP Android Anda (aktifkan USB Debugging) atau jalankan Emulator, lalu ketik:
```powershell
flutter run
```

### 3. Kompilasi Menjadi APK Rilis (Release APK)
Untuk membuat berkas installer APK mandiri yang siap diinstal langsung di HP Android tanpa komputer:
```powershell
flutter build apk --release
```
Hasil kompilasi APK rilis akan disimpan di folder:
`build/app/outputs/flutter-apk/app-release.apk`

* **Panduan Instalasi di HP Fisik:**
  Karena APK ini ditandatangani secara mandiri (self-signed) atau menggunakan tanda tangan debug, sistem Android mungkin menampilkan peringatan Google Play Protect saat instalasi. Pengguna cukup memilih **"Install Anyway" (Tetap Instal)** dan memastikan izin **"Install unknown apps"** untuk browser/file manager telah diaktifkan di pengaturan HP.

---

## 📱 Penjelasan Detail Modul & Fitur Aplikasi (APK)

Aplikasi AgriFarm Manager memiliki arsitektur modular yang solid dengan integrasi dinamis antar modul untuk menyajikan pencatatan pertanian yang otomatis dan akurat.

### 📊 1. Dashboard & Analisis Keuangan
* **Ringkasan Kas**: Menampilkan akumulasi total Pendapatan (dari penjualan panen) dan total Pengeluaran (dari pembelian stok, upah pekerja, dan pengeluaran manual) secara real-time.
* **Grafik Arus Kas**: Diagram batang/garis interaktif (`fl_chart`) yang memperlihatkan tren keuangan bulanan secara visual.
* **Indikator Siklus Tanam**: Menunjukkan informasi musim tanam yang sedang aktif berjalan, menghitung metrik **Hari Setelah Tanam (HST)** secara otomatis, dan memprediksi estimasi tanggal panen berdasarkan umur rata-rata komoditas tanaman.

### 🗺️ 2. Manajemen Lahan & Katalog Tanaman
* **Modul Lahan**: Pencatatan data fisik lahan (Nama lahan, Alamat, Koordinat GPS, Jenis Tanah, Sumber Air).
  * *Sistem Kepemilikan*: Mendukung lahan milik sendiri maupun sewa. Jika lahan berstatus **Sewa**, pengguna dapat mencatat biaya sewa per tahun, tanggal mulai, dan tanggal berakhir sewa sebagai pengingat masa berlaku sewa.
* **Katalog Tanaman**: Master data untuk komoditas (Melon, Cabai, Semangka, Tomat, dll.) beserta varietas spesifik, estimasi masa panen (HST), dan kebutuhan air rata-rata.

### 📅 3. Perencanaan Musim Tanam (Planting Seasons)
* Pembuatan siklus tanam baru dengan menghubungkan lahan yang tersedia dan jenis tanaman dari katalog.
* **Slider Persentase Luas Tanam**: Fitur interaktif di mana pengguna cukup menggeser persentase penggunaan lahan (1-100%). Sistem akan menghitung luas lahan terpakai secara absolut (m² atau Hektar) berdasarkan total luas lahan yang dipilih secara real-time.
* Log penanaman mencakup: Jumlah bibit yang ditanam, tanggal semai, dan tanggal tanam aktual.

### 🔔 4. Jadwal Kegiatan Tani & Pengurangan Stok Otomatis
* **Penjadwalan Kegiatan**: Memungkinkan pembuatan jadwal Pemupukan (metode Kocor, Tabur, Fertigasi) dan Penyemprotan (Fungisida, Insektisida, Herbisida, Bakterisida).
* **Integrasi Pengurangan Stok Inventaris**:
  * Ketika status kegiatan diubah menjadi **"Selesai"**, sistem secara otomatis memotong stok pupuk atau pestisida terkait di inventaris sesuai dosis pemakaian yang diinput.
  * **CRUD & Pemulihan Stok**: Jika kegiatan yang telah selesai diubah kembali statusnya menjadi "Belum Selesai" atau dihapus sepenuhnya, sistem akan secara otomatis **mengembalikan/menambahkan kembali** jumlah stok ke inventaris agar pencatatan stok tetap akurat.
* **Notifikasi Pengingat Lokal**: Menggunakan `flutter_local_notifications`. Aplikasi otomatis menjadwalkan pengingat notifikasi pada pukul 07:00 pagi pada hari kegiatan terjadwal di perangkat lokal pengguna tanpa memerlukan koneksi internet.

### 🐛 5. Catatan Hama & Penyakit (Pest & Disease Logs)
* Log deteksi serangan hama/penyakit di area lahan kebun.
* Pencatatan meliputi nama hama/penyakit, tanggal temuan, tindakan penanganan yang dilakukan, dan tingkat keparahan (Skala: Ringan, Sedang, Berat).
* Dukungan unggah bukti foto visual gejala hama langsung melalui jepretan Kamera atau galeri perangkat ke Firebase Storage.

### 📦 6. Inventaris & Riwayat Pembelian (Saprotan)
* **Manajemen Stok**: Menampilkan daftar stok Saprotan (Benih, Pupuk, Pestisida, Mulsa, dll.) yang terbagi atas kuantitas masuk dan keluar.
* **Indikator Stok Menipis (Alert System)**: Memberikan tanda peringatan visual (warna kuning/merah) apabila jumlah stok suatu barang berada di bawah ambang batas minimal (5 kg/liter/bungkus).
* **Riwayat Pembelian**: Pencatatan pembelian barang inventaris baru secara mendetail (Nama barang, kuantitas, harga satuan, nama toko, tanggal beli, dan foto nota belanja).
* **Auto-posting Keuangan**: Setiap kali pembelian dicatat, sistem secara otomatis membuat entri pengeluaran kas operasional baru di modul Keuangan dengan kategori **Bahan & Alat**.

### 👥 7. Manajemen Tenaga Kerja & Gaji Otomatis
* **Database Pekerja**: Berisi profil lengkap pekerja kebun (Nama lengkap, Nomor Telepon, Alamat).
* **Log Absensi & Tugas**: Pencatatan hari kerja pekerja, jenis pekerjaan harian, dan upah harian yang disepakati.
* **Auto-posting Kas**: Sistem secara otomatis menjumlahkan upah pekerja berdasarkan hari kerja mereka dan mencatatnya sebagai pengeluaran kas kategori **Upah** di Buku Kas. Pengubahan atau penghapusan log absensi pekerja secara otomatis akan menyesuaikan atau menghapus nominal pengeluaran kas terkait.

### 💸 8. Buku Kas & Keuangan Operasional
* **Pencatatan Transaksi**: Menyimpan riwayat pengeluaran kebun baik yang diinput secara manual (misal: Biaya BBM pompa air, biaya listrik, biaya makan bersama, dll.) maupun yang dihasilkan secara otomatis (pembelian inventaris dan gaji pekerja).
* **Diagram Klasifikasi Pengeluaran**: Pie chart interaktif untuk melihat persentase pengeluaran berdasarkan kategori utama (Upah, Bahan & Alat, Sewa Lahan, BBM, dll.) untuk memudahkan evaluasi efisiensi biaya.

### 🍎 9. Rekap Panen & Penjualan (Grading & CSV Export)
* **Sistem Grading Otomatis**: Cukup masukkan Total Berat Panen, Berat Grade A, dan Berat Grade B. Sistem akan menghitung berat **Grade C secara otomatis (Grade C = Total - (Grade A + Grade B))** guna meminimalisir kesalahan hitung manual.
* **Perhitungan Pendapatan Dinamis**: Memasukkan harga jual yang berbeda untuk masing-masing Grade A, B, dan C. Sistem akan mengalikan berat masing-masing grade dengan harganya dan menampilkan estimasi total pendapatan secara real-time pada form.
* **Database Tengkulak/Pembeli**: Mencatat nama tengkulak, komoditas yang sering dibeli, nomor kontak, dan wilayah asal.
* **Pelacakan Piutang (Status Bayar)**: Status pembayaran panen dapat diatur menjadi Lunas atau Belum Lunas. Jika Belum Lunas, sisa piutang akan tercatat dan ditampilkan pada ringkasan piutang tengkulak.
* **Ekspor Data CSV**: Pengguna dapat menyaring data panen berdasarkan rentang tanggal kustom (Custom Date Range Picker) dan mengekspornya ke berkas **CSV** untuk kebutuhan pelaporan eksternal atau analisis lebih lanjut di Microsoft Excel.

### 🔑 10. Autentikasi Google Sign-In & Keamanan
* **One-tap Google Sign-In**: Proses masuk yang sangat cepat menggunakan akun Google pengguna yang terhubung di HP Android.
* **Silent Sign-In (Auto-Login)**: Aplikasi secara otomatis mendeteksi sesi masuk yang aktif saat pertama kali dibuka. Petani tidak perlu melakukan login ulang setiap kali membuka aplikasi.

---

## 📂 Struktur Direktori Proyek

Aplikasi dikembangkan menggunakan pendekatan berbasis fitur (Feature-First Architecture) untuk meningkatkan pemeliharaan kode:

```text
lib/
├── main.dart                          # Titik masuk utama aplikasi (Entry Point)
├── core/                              # Utilitas umum & layanan bersama
│   ├── theme/                         # Pengaturan AppTheme & skema warna premium
│   ├── utils/                         # Formatters (Rupiah, HST, tanggal)
│   └── services/                      # Notifikasi lokal & ekspor CSV/Excel
└── features/                          # Direktori fitur modular
    ├── auth/                          # Manajemen autentikasi pengguna & Google Sign-In
    │   ├── presentation/
    │   └── data/
    ├── dashboard/                     # Tampilan beranda utama & grafik keuangan
    ├── lahan/                         # Fitur manajemen lahan & kepemilikan
    ├── tanaman/                       # Fitur master katalog varietas tanaman
    ├── perencanaan/                   # Siklus musim tanam & slider persentase lahan
    ├── aktivitas/                     # Penjadwalan kegiatan tani (pupuk & pestisida)
    ├── inventory/                     # Inventaris stok & pencatatan riwayat pembelian
    ├── tenaga_kerja/                  # Profil pekerja & log absensi penggajian
    ├── keuangan/                      # Buku kas pengeluaran operasional
    └── penjualan/                     # Panen, sistem grading, database tengkulak, & ekspor CSV
```

---

## 🔧 Panduan Troubleshooting & FAQ

#### 1. Masalah: Tombol Google Login tidak merespons atau memicu "Developer Error" (Status Code 10)
* **Penyebab**: Sidik jari SHA-1 debug/release komputer Anda belum didaftarkan di Firebase Console, atau file `google-services.json` yang ada di dalam proyek belum diperbarui setelah pendaftaran SHA-1.
* **Solusi**: Ikuti kembali langkah **Pendaftaran Fingerprint SHA-1 di Firebase Console** di atas, unduh kembali file `google-services.json`, tempatkan di `android/app/`, jalankan perintah `flutter clean` lalu bangun kembali proyek Anda.

#### 2. Masalah: Notifikasi Jadwal Kegiatan tidak muncul di HP Android
* **Penyebab**: Sejak Android 13 (API 33), aplikasi memerlukan izin eksplisit dari pengguna untuk menampilkan notifikasi.
* **Solusi**: Pastikan Anda menyetujui dialog permintaan izin notifikasi saat aplikasi pertama kali dibuka. Anda juga dapat mengaktifkan izin notifikasi secara manual melalui: **Pengaturan HP -> Aplikasi -> AgriFarm Manager -> Notifikasi -> Izinkan**.

#### 3. Masalah: Apakah aplikasi memerlukan koneksi internet setiap saat?
* **Penyebab**: Tidak. Berkat fitur **Firestore Offline Persistence**, semua data yang Anda inputkan (lahan, panen, keuangan, dll.) akan disimpan terlebih dahulu di memori lokal perangkat. Saat Anda mendapatkan akses internet kembali, Firebase akan secara otomatis menyinkronkan data lokal tersebut dengan database Cloud Firestore.

---
*Dikembangkan dengan ❤️ untuk mendukung kemajuan pertanian modern.*
