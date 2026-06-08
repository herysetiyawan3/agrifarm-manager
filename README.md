# AgriFarm Manager 🌿📱

**AgriFarm Manager** adalah aplikasi manajemen pertanian modern berbasis **Flutter** dan **Firebase** yang dirancang khusus untuk petani dalam mengelola siklus tanam, jadwal pemupukan/penyemprotan, stok inventaris, tenaga kerja, keuangan (buku kas), hingga pencatatan panen dan penjualan dengan pembagian grade (A/B/C). 

Aplikasi ini mendukung **penyimpanan offline (Offline Persistence)** sehingga data tetap dapat dibaca/ditulis meskipun petani sedang berada di area lahan yang minim sinyal, dan akan otomatis tersinkronisasi saat terhubung ke internet.

---

## 🚀 Fitur Utama Aplikasi

### 📊 1. Dashboard Utama
* Menampilkan ringkasan statistik keuangan (Total Pendapatan vs Pengeluaran).
* Grafik perkembangan arus kas operasional kebun.
* Indikator Hari Setelah Tanam (HST) dari musim tanam aktif berjalan beserta informasi estimasi tanggal panen.

### 🗺️ 2. Manajemen Lahan & Katalog Tanaman
* **Lahan:** Pencatatan nama lahan, koordinat GPS, alamat, jenis tanah, sumber air, serta status kepemilikan (Milik Sendiri / Sewa lengkap dengan nominal & masa sewa).
* **Katalog Tanaman:** Katalog master untuk komoditas (misal: Melon, Semangka, Tomat, Cabai) beserta varietas, kebutuhan air, dan umur rata-rata siap panen.

### 📅 3. Siklus & Musim Tanam (Planting Seasons)
* Membuat perencanaan musim tanam baru dengan memilih lahan dan tanaman.
* **Slider Persentase Luas Tanam:** Luas lahan yang digunakan dapat digeser (1-100%) dan sistem akan menghitung luas lahan absolut secara real-time (m² atau hektar).
* Pencatatan jumlah bibit, tanggal semai, dan tanggal tanam.

### 🔔 4. Jadwal Kegiatan Tani & Pengingat Notifikasi
* Pencatatan jadwal **Pemupukan** (metode Kocor, Tabur, Fertigasi) dan **Penyemprotan** (Fungisida, Insektisida, Bakterisida, Herbisida).
* **Pengurangan Stok Otomatis:** Saat menandai kegiatan sebagai "Selesai", stok pupuk/pestisida di inventaris akan terpotong secara otomatis sesuai dosis yang digunakan.
* **Notifikasi Lokal:** Aplikasi otomatis mendaftarkan pengingat notifikasi pada jam 07:00 pagi di hari kegiatan terjadwal.
* **CRUD Lengkap:** Mendukung pembuatan, pengubahan, dan penghapusan jadwal kegiatan (stok otomatis dikembalikan ke inventaris jika jadwal berstatus "Selesai" dihapus).

### 🐛 5. Catatan Hama & Penyakit
* Log temuan serangan hama atau penyakit di lapangan dengan tingkat keparahan (Ringan, Sedang, Berat).
* Unggah foto gejala serangan hama langsung dari kamera atau galeri handphone untuk dokumentasi.

### 📦 6. Inventaris Stok & Riwayat Pembelian
* **Stok Barang:** Informasi stok terkini (masuk - keluar) dengan indikator peringatan jika stok menipis (di bawah 5 kg/liter).
* **Catatan Pembelian:** Pencatatan pembelian Saprotan (Benih, Pupuk, Pestisida, Mulsa, dll.) lengkap dengan harga, kuantitas, nama toko, dan foto struk/nota belanja.
* **Integrasi Keuangan:** Setiap pembelian yang dicatat otomatis dimasukkan sebagai pengeluaran kas operasional kebun.

### 👥 7. Manajemen Tenaga Kerja & Upah Gaji
* Pencatatan profil pekerja (Nama, No HP, Alamat).
* Absensi log aktivitas harian pekerja kebun (Upah Harian & Jumlah Hari Kerja).
* Upah otomatis terhitung dan tercatat langsung ke buku kas pengeluaran kategori **Upah**.

### 💸 8. Keuangan & Buku Kas Pengeluaran
* Pencatatan pengeluaran manual (di luar pembelian stok dan upah) seperti biaya BBM, air, listrik, transportasi, dll.
* Dilengkapi grafik klasifikasi pengeluaran berdasarkan kategori.

### 🍎 9. Rekap Panen & Penjualan (Grading System)
* **Grading Otomatis:** Input total berat panen dan berat Grade A & B, maka berat **Grade C otomatis dihitung** (C = Total - A - B).
* **Harga Per Grade:** Input harga jual berbeda untuk tiap Grade A, B, dan C. Total pendapatan dihitung secara dinamis di form.
* **Manajemen Tengkulak:** Database pembeli/tengkulak, area wilayah, dan komoditas yang sering dibeli.
* **Pencatatan Piutang:** Melacak status penjualan (Lunas / Belum Lunas) beserta sisa piutang yang belum dibayar tengkulak.
* **Filter & Ekspor:** Filter data panen menggunakan Custom Date Range Picker dan ekspor data ke format **CSV** secara langsung.

### 🔑 10. Integrasi Login Google (Direct Auth)
* Menggunakan login Google sekali ketuk (One-tap Sign-in) dengan desain tombol premium sesuai Google Design Guideline.
* Mendukung **Silent Sign-in (Auto-Login)** saat pertama kali aplikasi dibuka agar pengguna tidak perlu login berulang kali.

---

## 🛠️ Spesifikasi Teknologi (Tech Stack)

* **Framework:** Flutter (Dart) SDK >= 3.0.0
* **State Management:** Flutter Riverpod
* **Database & Auth:** Firebase Firestore (Offline Persistence enabled) & Firebase Auth (Google OAuth)
* **File Storage:** Firebase Storage
* **Notifikasi:** Flutter Local Notifications & Timezone
* **Kamera & Gambar:** Image Picker

---

## ⚙️ Panduan Setup & Konfigurasi Firebase

Agar aplikasi dapat berjalan di perangkat lokal Anda, Anda harus menghubungkan proyek Flutter ini ke akun Firebase Anda sendiri. Berikut adalah langkah-langkahnya:

### Langkah 1: Siapkan Project di Firebase Console
1. Buka [Firebase Console](https://console.firebase.google.com/) dan buat project baru dengan nama **tani-hub** (atau nama pilihan Anda).
2. Aktifkan layanan berikut:
   * **Authentication:** Aktifkan metode login **Email/Password** dan **Google**.
   * **Cloud Firestore:** Buat database Firestore dalam mode uji coba (test mode) atau produksi (production mode).
   * **Storage:** Aktifkan Firebase Storage untuk menyimpan foto nota dan hama.

### Langkah 2: Daftarkan Aplikasi Android ke Firebase
1. Di halaman ikhtisar proyek Firebase, tambahkan aplikasi **Android**.
2. Masukkan nama paket Android Anda (terdapat di [android/app/build.gradle](file:///E:/tani%20hub/android/app/build.gradle)):
   `com.agrifarm.agrifarm_manager`
3. Masukkan fingerprint SHA-1 laptop/PC Anda.
   * *Cara mendapatkan SHA-1 lokal di Windows:*
     Buka terminal CMD atau PowerShell di folder proyek Anda dan jalankan perintah:
     ```bash
     keytool -list -v -keystore \"%USERPROFILE%\.android\debug.keystore\" -alias androiddebugkey -storepass android
     ```
   * Salin kode SHA-1 yang muncul (contoh: `B0:01:E5:80:41...`) dan tempelkan ke kolom SHA-1 di Firebase Console.
4. Unduh berkas **google-services.json** yang dihasilkan oleh Firebase.
5. Pindahkan berkas tersebut ke direktori proyek Anda di:
   `android/app/google-services.json`

### Langkah 3: Konfigurasi Keamanan (Firestore & Storage Rules)
* **Aturan Firestore (Firestore Rules):**
  Salin aturan yang ada di berkas [firestore.rules](file:///E:/tani%20hub/firestore.rules) proyek ke tab *Rules* Firestore di Firebase Console Anda. Aturan ini memastikan hanya pengguna terautentikasi yang dapat membaca/menulis data mereka sendiri.
* **Aturan Storage (Storage Rules):**
  Pastikan aturan penyimpanan di Firebase Storage mengizinkan akses tulis bagi pengguna yang terautentikasi:
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

## 💻 Cara Menjalankan Aplikasi di Perangkat Lokal

1. **Unduh dependensi proyek:**
   Buka terminal di folder proyek ini dan jalankan perintah:
   ```bash
   flutter pub get
   ```

2. **Jalankan aplikasi di Emulator atau HP (Mode Debug):**
   Pastikan perangkat Android Anda sudah terhubung (USB Debugging aktif) atau emulator menyala, lalu jalankan:
   ```bash
   flutter run
   ```

3. **Kompilasi menjadi APK Rilis (Release APK):**
   Untuk membuat aplikasi siap di-install di HP lain tanpa memerlukan kabel data, jalankan perintah:
   ```bash
   flutter build apk --release
   ```
   Berkas APK hasil kompilasi akan tersimpan di direktori:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 📂 Struktur Direktori Proyek

* `lib/main.dart` — Titik masuk utama (Entry Point) aplikasi.
* `lib/core/` — Berisi tema desain (`app_theme.dart`), utilitas formatting (`formatters.dart`), dan layanan notifikasi/ekspor berkas.
* `lib/features/auth/` — Modul otentikasi (Auth repository, login, register, dan reset password).
* `lib/features/dashboard/` — Halaman beranda utama dengan statistik visual dan HST berjalan.
* `lib/features/lahan/` — Pengelolaan data lahan kebun.
* `lib/features/tanaman/` — Pengelolaan katalog komoditas tanaman.
* `lib/features/perencanaan/` — Pengelolaan siklus musim tanam dengan slider persentase.
* `lib/features/aktivitas/` — Pengelolaan jadwal pemupukan & penyemprotan.
* `lib/features/inventory/` — Pengelolaan stok barang dan riwayat pembelian saprotan.
* `lib/features/tenaga_kerja/` — Pengelolaan pekerja dan absensi gaji.
* `lib/features/keuangan/` — Buku kas pengeluaran operasional.
* `lib/features/penjualan/` — Manajemen panen, pembagian grade, data tengkulak, piutang, dan ekspor data CSV.
* `lib/features/laporan/` — Halaman pelaporan rekapitulasi performa bulanan kebun.
