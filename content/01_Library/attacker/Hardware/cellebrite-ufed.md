---
title: Cellebrite Ufed
tags:
- 05-hardware-forensics-and-tactical-devices
- library
- military-and-intelligence-tools
created: '2026-06-27'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  

---

> [!warning] Konteks Etis & Legal
> Cellebrite UFED adalah perangkat forensik digital yang diproduksi oleh Cellebrite (anak perusahaan Sun Corporation, Jepang). Alat ini dipasarkan kepada lembaga penegak hukum, militer, laboratorium forensik, dan sektor swasta untuk ekstraksi data dari perangkat mobile. Seluruh informasi di bawah berasal dari dokumentasi publik, materi pemasaran Cellebrite, pelatihan forensik, serta penelitian keamanan independen. Pembahasan ini bersifat **edukasional dan defensif**. Penggunaan terhadap perangkat tanpa otorisasi pemilik melanggar hukum di hampir semua yurisdiksi. Tujuannya adalah agar defender dan individu memahami risiko dan menerapkan perlindungan yang tepat.

---

## 🧬 Apa Itu Cellebrite UFED?

Cellebrite UFED (Universal Forensic Extraction Device) adalah **platform terpadu untuk ekstraksi data forensik dari perangkat mobile, IoT, drone, kendaraan, dan perangkat GPS**. UFED bukan hanya satu alat, melainkan ekosistem produk yang terdiri dari perangkat keras (UFED Touch, UFED 4PC) dan perangkat lunak (UFED Physical Analyzer, Cellebrite Reader, Cellebrite Cloud Analyzer). Selama lebih dari dua dekade, UFED telah menjadi standar de facto di laboratorium forensik digital kepolisian global, mulai dari kepolisian lokal hingga FBI, Interpol, dan badan intelijen.

Pada 2024, Cellebrite mengklaim dapat mengekstrak data dari **lebih dari 45.000 profil perangkat** mencakup lebih dari 3.500 merek, termasuk iPhone terbaru, Samsung Galaxy, Google Pixel, Huawei, perangkat feature phone, perangkat satelit, sistem infotainment kendaraan, drone DJI, dan banyak lagi.

### Ekosistem Produk Cellebrite

| Produk | Fungsi |
|--------|--------|
| **UFED Touch3** | Tablet forensik lapangan (rugged) untuk ekstraksi langsung di TKP. Baterai tahan lama, konektivitas Wi-Fi/Bluetooth/kabel. |
| **UFED 4PC** | Software untuk laptop/PC investigator, dengan kabel kit ekstensif. |
| **UFED Physical Analyzer** | Software analisis desktop untuk memproses, mem-parsing, dan memvisualisasikan data hasil ekstraksi. |
| **Cellebrite Premium** | Suite eselon atas dengan kemampuan bypass lock screen terkini (termasuk brute-force hardware-assisted), cloud extraction, dan dukungan untuk chipset terbaru. |
| **UFED Cloud Analyzer** | Ekstraksi data dari cloud (iCloud, Google Drive, WhatsApp backup, dll.) dengan kredensial atau token yang didapat dari perangkat. |
| **UFED Reader** | Software gratis untuk berbagi hasil ekstraksi dengan jaksa/pengadilan tanpa lisensi penuh. |
| **UFED Link** | Remote extraction: agen di lapangan mengoperasikan UFED yang dikendalikan dari lab. |
| **Cellebrite Pathfinder** | Analitik lanjutan: relationship mapping, timeline, pattern detection, analisis gambar AI. |
| **Cellebrite Endpoint Inspector** | Forensik endpoint (laptop/desktop) untuk melengkapi mobile forensics. |

---

## 🔬 Teknologi Ekstraksi: Dari Sederhana hingga Destruktif

Cellebrite mendukung beberapa metode ekstraksi, diurutkan dari yang paling tidak invasif ke yang paling dalam:

### 1. Logical Extraction

**Prinsip:** UFED berkomunikasi dengan perangkat melalui protokol standar (iTunes/AFC untuk iOS, MTP/ADB untuk Android) dan meminta data yang "terlihat" oleh sistem operasi.

**Data yang bisa didapat:**
- Kontak, kalender, catatan, SMS/MMS, log panggilan.
- Media (foto, video, audio) di penyimpanan yang dapat diakses.
- Riwayat Wi-Fi, Bluetooth, lokasi.
- Beberapa data aplikasi (jika aplikasi mengizinkan backup).

**Keterbatasan:**
- Tidak bisa mendapat data aplikasi sandboxed (WhatsApp, Signal, Telegram).
- Tidak bisa mendapat data terhapus.
- Tidak bisa akses file sistem.
- Bergantung pada mode USB yang diizinkan perangkat (jika terkunci, logical extraction sering gagal).

**Metode koneksi:**
- **iOS**: pairing record (jika sebelumnya sudah dipercaya), atau iTunes backup.
- **Android**: USB debugging (jika diaktifkan), backup Android, atau MTP.

### 2. File System Extraction

**Prinsip:** UFED mendapatkan akses ke seluruh filesystem perangkat, termasuk direktori aplikasi sandboxed dan file sistem (tidak termasuk partisi terproteksi).

**Prasyarat:**
- Perangkat harus di-unlock (passcode diketahui atau sudah di-bypass).
- Pada iOS, biasanya memerlukan exploit bootrom (checkm8) atau exploit kernel untuk mengakses filesystem penuh.
- Pada Android, memerlukan root akses (temporary root via exploit) atau custom recovery.

**Data tambahan vs Logical:**
- Semua data aplikasi (WhatsApp, Signal, Telegram, Facebook, Instagram, TikTok, dll.).
- Cache, log, cookie, session token.
- Database yang disimpan aplikasi di direktori pribadi.
- File terhapus yang masih ada di filesystem (sebelum ditimpa).

### 3. Physical Extraction (Hex Dump)

**Prinsip:** UFED membuat salinan bit-ke-bit (bit-by-bit copy) dari seluruh penyimpanan internal perangkat, termasuk partisi yang tidak ter-mount, ruang kosong (unallocated space), dan area yang tidak dapat diakses melalui sistem operasi normal.

**Proses:**
1. UFED mengirimkan **bootloader exploit** atau **agent** ke perangkat (dalam mode recovery/DFU/Fastboot/EDL).
2. Agent ini mem-bypass verifikasi signature dan mengakses memori NAND secara langsung.
3. UFED membaca seluruh penyimpanan mentah dan menyalinnya ke file image.
4. File image kemudian di-mount dan dianalisis di Physical Analyzer.

**Keunggulan:**
- Mendapatkan SEMUA data, termasuk file terhapus (jika belum ditimpa).
- Mendapatkan data dari partisi yang tidak terlihat oleh OS (EFI, baseband, OEM).
- Mendapatkan artefak forensik seperti timestamp file, fragmentasi file, metadata filesystem.
- Bisa membaca data dari perangkat yang tidak bisa booting (rusak secara fisik tetapi chip penyimpanan masih utuh).

**Teknik yang digunakan:**
- **Bootrom exploit (checkm8)**: Untuk iPhone 4s hingga iPhone X (A5–A11). Eksploitasi ini bersifat permanen (tidak bisa ditambal Apple) karena ada di bootrom. UFED memanfaatkannya untuk menjalankan kode kustom dan membaca NAND.
- **EDL mode (Qualcomm)**: Untuk banyak perangkat Android dengan chip Qualcomm. Mode Emergency Download memungkinkan akses langsung ke memori.
- **Pre-loader exploit (MediaTek)**: Untuk perangkat MediaTek, UFED menggunakan mode BROM (Boot ROM) untuk membaca memori.
- **Kernel exploit**: Untuk perangkat di atas A12 (iPhone XR/XS ke atas) yang tidak memiliki bootrom exploit, Cellebrite menggunakan kernel exploit (0-day atau n-day) untuk mendapatkan hak akses yang cukup.
- **Custom recovery**: Untuk Android, UFED dapat mem-flash custom recovery (seperti TWRP) yang ditandatangani secara khusus, lalu melakukan dump penyimpanan.

### 4. Full File System (FFS) / Advanced Logical

Pada perangkat modern dengan enkripsi hardware (iOS 12+, Android 10+ dengan FBE), physical extraction sangat sulit dilakukan karena kunci enkripsi terikat dengan passcode. Cellebrite Premium mengklaim kemampuan **"Full File System"** atau **"Advanced Logical"** yang merupakan ekstraksi filesystem setelah unlock (passcode diketahui atau berhasil di-bypass). Ini bukan true physical dump, tetapi memberikan akses ke hampir semua data yang relevan bagi investigasi.

### 5. Chip-Off & ISP (In-System Programming)

Untuk perangkat yang rusak parah (hancur, terbakar, kena air), UFED mendukung:

- **Chip-off**: Melepaskan chip penyimpanan NAND/eMMC dari PCB, membacanya dengan reader khusus, lalu memproses image mentah. Ini destruktif dan memerlukan peralatan tambahan (hot air station, reader). UFED bekerja sama dengan alat seperti **Z3X Box** atau **Easy JTAG**.
- **ISP (In-System Programming)**: Koneksi langsung ke pin JTAG/eMMC pada PCB tanpa melepas chip, menggunakan konektor khusus. Berguna jika perangkat tidak bisa booting tetapi chip masih utuh.

---

## 🔓 Bypass Lock Screen: Perang Abadi Cellebrite vs Apple/Google

Kemampuan UFED untuk membuka kunci perangkat adalah aspek yang paling kontroversial dan paling dirahasiakan. Berikut metode yang diketahui secara publik:

### iPhone / iOS

| Model | Chip | Metode Bypass | Waktu Estimasi | Diperbaiki? |
|-------|------|---------------|----------------|-------------|
| iPhone 4s – iPhone X | A5–A11 | **Checkm8 bootrom exploit**: UFED mengeksploitasi bootrom untuk menonaktifkan passcode retry limit, lalu brute-force passcode dengan kecepatan tinggi (via USB, ribuan percobaan/detik). | 4-digit PIN: menit. 6-digit PIN: jam. Alphanumeric panjang: berbulan-bulan. | ❌ Tidak bisa ditambal (permanen). |
| iPhone XR/XS – iPhone 14 | A12–A15 | **Cellebrite Premium**: Kernel exploit untuk mengaktifkan brute-force (tanpa bootrom exploit). Detail rahasia; kemungkinan menggunakan 0-day atau kombinasi hardware attack. | 4-digit PIN: cepat (detail tidak diungkap). 6-digit PIN: lebih lama. | ✅ Ditambal di iOS 16+ (Lockdown Mode), iOS 17. |
| iPhone 15 | A16/A17 | **Terbatas**: Cellebrite Premium mengklaim dukungan terbatas. Detail tidak diungkap. | Mungkin lebih lambat. | ✅ Apple terus menambal. |
| Semua iPhone | Semua | **GrayKey/ GrayShift**: (Alat terpisah tapi terintegrasi) Brute-force hardware dengan mengirimkan kode PIN via koneksi serial ke Secure Enclave. UFED bisa bekerja sama dengan GrayKey untuk unlock lalu ekstraksi. | 4-digit: ~6 menit. 6-digit: ~11 jam. | ✅ Ditambal di iOS 12 (USB Restricted Mode). |

**Metode brute-force UFED sendiri (tanpa GrayKey):**
1. UFED menempatkan perangkat dalam mode recovery/DFU.
2. Mengirimkan payload eksploitasi (checkm8 atau kernel exploit) untuk memodifikasi boot chain.
3. Mem-patch kernel agar tidak menghapus perangkat setelah X percobaan gagal.
4. Mem-patch Secure Enclave (jika mungkin) untuk menghilangkan escalating time delay.
5. Mencoba PIN secara otomatis: 0000, 0001, 0002, ..., 9999.
6. Setelah PIN ditemukan, perangkat di-boot normal dan UFED melakukan ekstraksi penuh.

### Android

| Metode | Deskripsi |
|--------|-----------|
| **Google Account Bypass (FRP)** | Jika perangkat di-reset tapi masih terikat akun Google, UFED bisa mem-bypass Factory Reset Protection (FRP) dengan exploit tertentu. |
| **Bootloader Unlock** | Jika bootloader bisa di-unlock, UFED mem-flash custom image untuk akses data. |
| **EDL Mode (Qualcomm)** | Mode darurat pada chipset Qualcomm memungkinkan akses langsung ke memori, mem-bypass lockscreen sepenuhnya. Banyak perangkat Android yang EDL mode-nya tidak dilindungi. |
| **MediaTek BROM** | Mirip EDL, akses low-level ke memori via MediaTek Boot ROM. |
| **Samsung Exynos** | Beberapa chip Exynos memiliki kelemahan yang memungkinkan bypass. |
| **Brute-force PIN/Pattern** | UFED dapat mencoba ribuan pola/PIN via USB, meskipun lebih lambat dari iPhone. |

---

## 🖥️ UFED Physical Analyzer: Analisis Data Hasil Ekstraksi

Setelah data diekstrak, file image diproses oleh **UFED Physical Analyzer** (PA), software desktop untuk analisis forensik. PA melakukan:

### Parsing & Decoding

- **Database parsing**: Membaca SQLite database dari aplikasi, termasuk data terhapus (dari WAL journal, free pages). Aplikasi yang didukung: WhatsApp, Signal, Telegram, Facebook, Instagram, TikTok, WeChat, Line, Snapchat, Tinder, dll.
- **Media analysis**: Ekstrak metadata EXIF dari foto/video, thumbnail, foto terhapus dari thumbnail cache.
- **Message decoding**: Mendekripsi pesan dari backup terenkripsi (iTunes backup dengan password yang diketahui/di-crack).
- **Keychain (iOS)**: Mengekstrak kunci, token, dan password dari iOS Keychain.
- **Keystore (Android)**: Ekstrak kunci kriptografi dari Android Keystore jika perangkat di-root.

### Analitik & Visualisasi

| Fitur | Deskripsi |
|-------|-----------|
| **Timeline View** | Semua event (panggilan, pesan, foto, lokasi) dalam satu timeline kronologis. |
| **Connection Graph** | Visualisasi hubungan antara kontak, nomor telepon, email, akun media sosial. |
| **Location Mapping** | Plot data lokasi (GPS, cell tower, Wi-Fi) pada peta. |
| **Keyword Search** | Pencarian full-text di semua data, termasuk di gambar (OCR). |
| **Image Categorization** | AI untuk mengkategorikan gambar (senjata, narkoba, uang, dokumen, pornografi anak). |
| **Pattern Detection** | Mendeteksi pola komunikasi, rute perjalanan, anomali. |
| **Watch List** | Mencocokkan data dengan daftar target (nomor, email, nama). |

### Ekstraksi Cloud

Jika token atau kredensial ditemukan di perangkat, PA dapat menggunakannya untuk:
- Mengunduh backup iCloud penuh (termasuk foto, kontak, catatan, dll.).
- Mengakses Google Drive, Google Photos, Google Maps timeline.
- Mengunduh chat history WhatsApp dari Google Drive backup.
- Mengakses akun media sosial.

Ini dilakukan melalui **UFED Cloud Analyzer** yang terintegrasi.

---

## 🔐 Countermeasures: Melindungi Perangkat dari UFED

### 1. Strong Passcode / Passphrase

Ini adalah pertahanan paling fundamental. UFED mengandalkan brute-force.

- **4-digit PIN**: 10.000 kombinasi → brute-force dalam hitungan menit.
- **6-digit PIN**: 1.000.000 kombinasi → jam/hari.
- **Alphanumeric passphrase** (>12 karakter, campuran): Entropy sangat tinggi → brute-force tidak mungkin dalam waktu manusiawi (ratusan tahun).

**Apple's Time Delay:** iOS menerapkan escalating time delay setelah percobaan gagal (1 menit, 5 menit, 15 menit, 60 menit). Dengan bypass exploit, Cellebrite menghilangkan delay ini. Tetapi dengan kernel exploit yang ditambal (iOS 16+), delay mungkin tetap berlaku.

### 2. USB Restricted Mode (iOS 11.4.1+)

Jika iPhone tidak di-unlock selama lebih dari 1 jam, port Lightning akan menonaktifkan transfer data (hanya charging). Ini memblokir akses UFED via kabel. Untuk mengaktifkan: Settings > Face ID & Passcode > USB Accessories > Off (iOS 12+). Di iOS 16+, ini lebih agresif.

### 3. Lockdown Mode (iOS 16+)

Lockdown Mode secara drastis mempersempit permukaan serangan:
- Menonaktifkan koneksi kabel saat terkunci (bahkan lebih ketat dari USB Restricted Mode).
- Memblokir konfigurasi MDM saat terkunci.
- Menonaktifkan exploit vector di browser, pesan, FaceTime.
- Membatasi aksesori yang bisa terhubung.

Saat ini Lockdown Mode adalah pertahanan terkuat terhadap UFED.

### 4. Enkripsi Penuh (Full Disk Encryption)

- **iOS**: Semua perangkat iOS dengan passcode dienkripsi secara default (Data Protection). Kunci enkripsi terikat dengan passcode di Secure Enclave. Tanpa passcode, image dump adalah sampah terenkripsi.
- **Android**: File-Based Encryption (FBE) sejak Android 10+. Data aplikasi dienkripsi dengan kunci yang diturunkan dari kredensial layar kunci. Physical dump tanpa unlock akan menghasilkan data terenkripsi.

### 5. Secure Hardware

- **Apple Secure Enclave**: Prosesor terpisah yang menangani kunci dan brute-force rate limiting. Bahkan jika kernel dikompromikan, Secure Enclave secara independen membatasi percobaan PIN. Eksploitasi terhadap Secure Enclave sendiri sangat jarang dan mahal.
- **Google Titan M / Samsung Knox**: Chip keamanan khusus pada perangkat Android flagship yang melakukan rate limiting dan deteksi tamper.

### 6. Aplikasi dengan Enkripsi End-to-End

WhatsApp, Signal, iMessage, Telegram Secret Chat — meskipun data aplikasi bisa diekstrak, konten pesan tetap terenkripsi. Namun, jika backup tidak terenkripsi (WhatsApp backup ke iCloud tanpa password), data bisa dibaca dari cloud.

### 7. Hindari Backup Cloud Tidak Terenkripsi

- Matikan backup WhatsApp ke iCloud/Google Drive, atau aktifkan enkripsi backup (passphrase terpisah).
- Gunakan Signal yang tidak memiliki backup cloud default.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Penegak Hukum             Intelijen Militer        Rezim Otoriter
│                         │                        │
Forensik digital:         Ekstrak data dari        Menargetkan
ekstrak bukti dari        perangkat teroris/       aktivis, jurnalis,
HP tersangka dengan       kombatan untuk           oposisi politik
warrant yang sah          intelijen                tanpa proses hukum
│                         │                        │
│                         │                        ▼
▼                         ▼                        Penangkapan
Laboratorium              Operasi                  sewenang-wenang,
forensik kepolisian       kontra-terorisme,        penyiksaan,
(standar hukum)           battlefield extraction   penghilangan paksa
│
└── Sektor swasta:
    investigasi insider
    threat, eDiscovery
    (dengan consent)
```

### Kasus Penyalahgunaan Terdokumentasi

- **Myanmar (2021)**: Junta militer menggunakan Cellebrite UFED untuk membuka ponsel aktivis prodemokrasi, mengekstrak kontak, dan menangkap lebih banyak orang.
- **Filipina**: Polisi menggunakan UFED dalam perang narkoba untuk mengekstrak data dari ponsel tersangka yang dieksekusi di tempat.
- **Belarus**: Rezim Lukashenko menggunakan UFED untuk membuka ponsel demonstran dan jurnalis.
- **Nigeria**: Militer mengekstrak data dari ponsel warga sipil di wilayah konflik tanpa warrant.

Cellebrite telah berusaha membatasi penjualan ke negara dengan catatan HAM buruk, tetapi implementasinya tidak sempurna.

---

## 🔬 Studi Kasus Operasional

### Kasus: FBI vs San Bernardino Shooter (2016)

FBI meminta Apple untuk membuat backdoor pada iPhone 5C milik Syed Farook. Apple menolak. FBI kemudian menggunakan jasa perusahaan forensik pihak ketiga (kemungkinan Cellebrite, meskipun tidak dikonfirmasi resmi) untuk membuka iPhone tersebut. Biaya yang dilaporkan: $900.000–$1.3 juta. Ini menunjukkan bahwa bahkan tanpa kerja sama vendor, alat forensik komersial mampu membuka iPhone 5C (yang menggunakan A6 chip, rentan terhadap bootrom exploit).

### Kasus: Penggunaan di Medan Perang

Militer AS dan sekutu menggunakan Cellebrite UFED di Irak, Afghanistan, Suriah untuk mengekstrak intelijen dari perangkat yang disita dalam operasi. UFED Touch digunakan di lapangan, dengan data dikirim ke lab via UFED Link untuk analisis lebih lanjut. Data yang diekstrak sering digunakan untuk menemukan target berikutnya (pattern-of-life analysis).

---

## 🔗 Koneksi dalam Vault

- [[graykey]] — Alat komplementer untuk brute-force passcode iPhone. Cellebrite UFED sering digunakan bersama GrayKey: GrayKey untuk unlock, UFED untuk ekstraksi.
- [[pegasus]] — Pegasus adalah vektor infeksi; setelah infeksi, data bisa diambil langsung dari server tanpa perlu UFED. Tapi jika perangkat fisik disita, UFED digunakan untuk konfirmasi dan ekstraksi tambahan.
- [[finspy]] — FinSpy melakukan surveillance langsung; UFED digunakan untuk analisis forensik setelah penyitaan. Keduanya bisa paralel dalam investigasi yang sama.
- [[victoria-hdd]] / [[pc-3000]] — UFED adalah versi mobile dari Victoria/PC-3000: ekstraksi data dari perangkat dengan akses hardware-level.
- [[xkeyscore]] — Data hasil ekstraksi UFED bisa di-cross-reference dengan database SIGINT untuk memperkaya profil target.
- [[shodan]] — Tidak langsung, tetapi perangkat yang terhubung ke internet bisa dilacak, dan kemudian disita untuk ekstraksi UFED.

---

## 📚 Referensi

- Cellebrite, *UFED User Manual & Technical Specifications* (2024)
- Cellebrite, *Physical Analyzer Training Materials*
- NIST, *Guidelines on Mobile Device Forensics* (SP 800-101 Rev. 1)
- Apple, *Platform Security Guide* (2024)
- Amnesty International, *Cellebrite: The Tool That Unlocks Your Phone* (2021)
- Upturn, *Cellebrite and the Sale of Mobile Forensic Tools to Governments* (2020)
- MITRE ATT&CK: T1588.001 (Obtain Capabilities: Malware), T1592.002 (Gather Victim Host Information: Software)

---

*Cellebrite UFED Deep Dive | Mobile Forensic Extraction | Dual-Use Forensic Platform*
---

audited
---
