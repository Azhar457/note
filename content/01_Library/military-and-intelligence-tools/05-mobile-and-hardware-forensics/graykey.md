---
tags:
  - graykey
  - mobile-forensics
  - passcode-bypass
  - dual-use
  - forensic-tools
aliases:
  - GrayKey
  - Grayshift GrayKey
  - iPhone brute force
created: 2026-06-27
status: operational
cssclasses:
  - wide-table
---

> [!warning] Konteks Etis & Legal
> GrayKey adalah perangkat keras forensik yang diproduksi oleh Grayshift (AS) untuk membantu lembaga penegak hukum membuka perangkat iOS yang terkunci. Seluruh informasi di bawah berasal dari dokumentasi publik, materi pemasaran Grayshift, pelatihan forensik, serta penelitian keamanan independen. Pembahasan ini murni **edukasional dan defensif**. Penggunaan tanpa otorisasi pemilik perangkat adalah ilegal. Tujuannya agar defender dan pengguna memahami cara kerja alat ini dan memperkuat perlindungan.

---

## 🧬 Apa Itu GrayKey?

GrayKey adalah **hardware brute-force unlocker** khusus iPhone dan iPad, dikembangkan oleh perusahaan Amerika Serikat **Grayshift** (didirikan 2016). Tidak seperti Cellebrite UFED yang merupakan platform ekstraksi data multifungsi, GrayKey fokus pada satu tugas: **membuka passcode perangkat iOS** dengan cara mencoba ribuan kombinasi PIN/password secara otomatis melalui koneksi USB/Lightning.

GrayKey berbentuk kotak kecil (seukuran router Wi-Fi) dengan dua slot konektor Lightning untuk iPhone. Kotak ini terhubung ke komputer investigator melalui Wi-Fi atau kabel Ethernet, dan dioperasikan melalui antarmuka web. Setelah passcode berhasil dipecahkan, perangkat dapat di-unlock dan data siap diekstraksi oleh alat forensik lain seperti Cellebrite UFED, Magnet Axiom, atau XRY.

### Perbandingan GrayKey vs Cellebrite UFED (Unlock)

| Aspek                    | GrayKey (Grayshift)                                         | Cellebrite UFED Premium                                          |
| ------------------------ | ----------------------------------------------------------- | ---------------------------------------------------------------- |
| **Fokus**                | Hanya unlock passcode                                       | Ekstraksi data penuh + unlock sebagai langkah awal               |
| **Metode Unlock**        | Hardware brute-force via Secure Enclave (serial protocol)   | Software/exploit-based brute-force (bootrom/kernel exploit)      |
| **Koneksi**              | Kabel Lightning ke slot khusus                              | Kabel USB ke UFED Touch/PC                                       |
| **Kecepatan (4-digit)**  | ~6 menit                                                    | ~beberapa menit (dengan exploit)                                 |
| **Kecepatan (6-digit)**  | ~11 jam (rata-rata)                                         | ~jam (dengan exploit)                                            |
| **Dukungan iOS terbaru** | Ya, tanpa perlu exploit (mengandalkan hardware brute-force) | Memerlukan exploit; terbatas pada versi iOS yang ada exploit-nya |
| **Efektivitas**          | Semua iPhone (karena interface Secure Enclave standar)      | Bergantung pada kerentanan yang tersedia                         |
| **Harga**                | $15,000 – $30,000 (lisensi tahunan)                         | Termasuk dalam langganan Premium (lebih mahal)                   |
| **Produksi**             | Grayshift (AS)                                              | Cellebrite (Israel)                                              |

GrayKey bekerja dengan berkomunikasi langsung ke **Secure Enclave Processor (SEP)** melalui antarmuka serial yang tersedia pada port Lightning. Karena ini adalah serangan hardware, ia tidak bergantung pada bug perangkat lunak dan sulit ditambal sepenuhnya oleh Apple.

---

## 🏗️ Arsitektur & Cara Kerja GrayKey

### Komponen Fisik

GrayKey adalah kotak logam padat dengan dua slot konektor Lightning (disebut "sleds") untuk menampung dua iPhone sekaligus. Komponen internal meliputi:

- **Prosesor utama** (ARM-based) yang menjalankan firmware Grayshift.
- **Modul komunikasi** ke SEP melalui antarmuka serial (UART) yang dirutekan via Lightning.
- **Power supply** independen agar iPhone tetap terisi daya selama brute-force (yang bisa berjam-jam).
- **Ethernet/Wi-Fi** untuk koneksi ke workstation operator.

Tidak ada tombol fisik. Semua operasi dikendalikan dari antarmuka web.

### Prosedur Operasi

1. **Persiapan**: Operator menghubungkan iPhone yang terkunci ke salah satu slot GrayKey menggunakan kabel Lightning.
2. **Deteksi**: GrayKey mendeteksi model iPhone, versi iOS, dan status passcode.
3. **Brute-Force Attack**: GrayKey mengirimkan upaya kode sandi (PIN atau alphanumeric) melalui koneksi serial ke SEP.
4. **Rate Limiting Bypass**: SEP biasanya menerapkan escalating time delay (1 menit, 5 menit, 15 menit, 60 menit) setelah beberapa upaya gagal. GrayKey menggunakan **teknik proprietary** untuk menghindari penundaan ini — kemungkinan dengan mengirimkan perintah ke SEP seolah-olah setiap percobaan adalah percobaan pertama, atau dengan memanipulasi clock SEP.
5. **Passcode Cracking**: GrayKey secara otomatis mencoba semua kemungkinan kombinasi:
   - 0000, 0001, 0002, ..., 9999 (jika diyakini 4-digit).
   - 000000, 000001, ..., 999999 (6-digit).
   - Untuk alphanumeric, GrayKey dapat diberi daftar kata (wordlist) atau aturan kustom.
6. **Passcode Found**: Setelah passcode ditemukan, GrayKey menampilkannya di antarmuka web dan meng-unlock iPhone.
7. **Ekstraksi Data (Opsional)**: GrayKey sendiri tidak mengekstrak data; setelah unlock, investigator menggunakan Cellebrite UFED atau alat lain untuk logical/physical extraction. Beberapa konfigurasi GrayKey dapat melakukan **iTunes backup** langsung ke storage network.

### Model Lisensi

GrayKey dijual dengan model **lisensi tahunan** yang mencakup:

- Dukungan untuk semua iOS terbaru.
- Pembaruan firmware untuk menangani mitigasi baru Apple.
- Akses ke "GrayKey Cloud" untuk crack yang lebih cepat (cloud-assisted).
- Dua varian: **GrayKey Essential** (online, lebih murah, crack lebih lambat) dan **GrayKey Elite** (offline, crack cepat, lebih mahal).

---

## 🔬 Teknik Brute-Force: Mengapa GrayKey Sulit Dihentikan

### Antarmuka Serial ke Secure Enclave

Apple merancang Secure Enclave (SEP) untuk menangani verifikasi passcode secara independen dari prosesor aplikasi (AP). SEP memiliki antarmuka komunikasi serial (UART) yang terhubung ke konektor Lightning. GrayKey mengeksploitasi antarmuka ini untuk mengirimkan kode PIN langsung ke SEP, mem-bypass iOS sepenuhnya.

Karena komunikasi langsung ke SEP, GrayKey:

- Tidak memerlukan exploit kernel.
- Tidak peduli apakah iOS di-patch atau tidak.
- Tidak terpengaruh oleh USB Restricted Mode (karena USB Restricted Mode membatasi komunikasi data melalui AP, tetapi antarmuka serial SEP mungkin tetap aktif untuk keperluan diagnostik). Apple telah berusaha menonaktifkan antarmuka ini setelah perangkat terkunci lama, tetapi GrayKey terus menemukan cara.

### Bypass Escalating Time Delay

Secara default, SEP menerapkan penundaan yang meningkat:

- 5 upaya gagal → 1 menit.
- 6 → 5 menit.
- 7 → 15 menit.
- 8+ → 60 menit per upaya.

Ini akan membuat brute-force 10.000 PIN memakan waktu berbulan-bulan. GrayKey menggunakan **teknik clock glitching** atau **voltage fault injection** untuk mereset timer di dalam SEP, atau mengirimkan perintah yang menyebabkan SEP memperlakukan setiap percobaan sebagai upaya pertama. Detail pastinya rahasia, tetapi komunitas riset (seperti peneliti independent) telah mendemonstrasikan teknik serupa dengan peralatan murah.

### Kecepatan dan Waktu Crack

| Panjang PIN                                | Jumlah Kombinasi  | Waktu GrayKey (estimasi)       |
| ------------------------------------------ | ----------------- | ------------------------------ |
| 4-digit numeric                            | 10.000            | ~6–12 menit                    |
| 6-digit numeric                            | 1.000.000         | ~11–24 jam                     |
| 4-character alphanumeric (lowercase+digit) | 36^4 = 1,6 juta   | ~1–2 hari                      |
| 6-character alphanumeric (lowercase)       | 36^6 = 2,1 miliar | Bertahun-tahun (tidak praktis) |
| 8+ character random                        | Entropi tinggi    | Tidak mungkin                  |

Operator GrayKey sering menggunakan **wordlist attack** untuk password alfanumerik, mencoba kata-kata umum, pola keyboard, dan data pribadi target (tanggal lahir, nama, dll.).

### Eksfiltrasi Passcode via Cloud

Untuk perangkat yang dilindungi passcode kuat, GrayKey Elite dapat mengunggah dump memori SEP ke **GrayKey Cloud** untuk dianalisis dengan komputasi tinggi (GPU cluster), mempercepat pemecahan. Ini adalah alasan model Elite lebih mahal: mencakup kredit cloud.

---

## 🛡️ Countermeasures Terhadap GrayKey

### 1. Gunakan Passcode Alfanumerik Panjang (>8 karakter)

Ini adalah pertahanan paling efektif. GrayKey tidak mampu brute-force passcode alfanumerik panjang dalam waktu praktis.

### 2. Aktifkan "Erase Data" (Settings > Face ID & Passcode > Erase Data)

Setelah 10 upaya gagal berturut-turut, iPhone akan menghapus semua data secara otomatis. Ini adalah perlindungan yang dijalankan oleh Secure Enclave sendiri. GrayKey mungkin mencoba mem-bypass ini, tetapi pada iOS modern, SEP secara mandiri menghitung dan tidak bisa di-reset dengan mudah. Banyak lembaga penegak hukum justru meminta korban untuk tidak mengaktifkan fitur ini.

### 3. USB Restricted Mode (iOS 11.4.1+)

GrayKey memang terhubung melalui Lightning, tetapi jika USB Restricted Mode menonaktifkan antarmuka data sepenuhnya setelah 1 jam terkunci, SEP mungkin tidak dapat diakses. Namun, laporan menunjukkan GrayKey dapat beroperasi dalam mode DFU atau recovery, di mana USB Restricted Mode mungkin tidak berlaku karena SEP masih dapat dijangkau melalui jalur diagnostik.

### 4. Lockdown Mode (iOS 16+)

Lockdown Mode lebih agresif menonaktifkan koneksi kabel saat terkunci. Ini kemungkinan juga membatasi antarmuka SEP. Apple belum merilis rincian teknis, tetapi Lockdown Mode adalah standar emas saat ini.

### 5. Update iOS Secara Berkala

Setiap rilis iOS baru, Apple memperkuat keamanan SEP. Grayshift harus merekayasa balik dan menemukan cara baru, yang membutuhkan waktu. Memperbarui iOS secara cepat dapat menggagalkan GrayKey yang belum mendukung versi terbaru.

### 6. Jangan Biarkan Perangkat Disita dalam Keadaan Terkunci Terlalu Lama

Idealnya, jika ditangkap, segera matikan iPhone (shutdown). iPhone yang mati tidak bisa dijangkau oleh GrayKey hingga dinyalakan dan passcode dimasukkan sekali. Beberapa laporan menyarankan menekan tombol power 5 kali untuk mengaktifkan SOS, yang menonaktifkan biometrik dan mempersulit akses.

---

## 📊 Riwayat & Kontroversi

- **2018**: Grayshift muncul dengan GrayKey pertama. Hanya butuh beberapa jam untuk crack 6-digit PIN. Digunakan oleh FBI dan banyak kepolisian lokal AS.
- **2018 (Apple respons)**: Apple menambahkan **USB Restricted Mode** di iOS 11.4.1. GrayKey merespons dengan pembaruan firmware.
- **2019**: Grayshift meluncurkan GrayKey 2.0 dengan dukungan iOS 12/13 dan kecepatan lebih cepat.
- **2020–2022**: Apple terus memperkuat SEP dan menambahkan fitur seperti **Secure Enclave Patch** yang mempersulit brute-force.
- **2023**: Grayshift mengakuisisi **Magnet Forensics** (alat analisis) untuk integrasi yang lebih erat.
- **2024**: GrayKey Elite mendukung iPhone 15 dengan iOS 18, meskipun laporan menunjukkan Lockdown Mode secara signifikan menghambatnya.

Kontroversi: seperti Cellebrite, GrayKey telah dijual ke negara-negara dengan catatan HAM buruk. Laporan Amnesty International dan Citizen Lab mendokumentasikan penggunaan GrayKey oleh polisi di negara-negara represif.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Penegak Hukum             Intelijen Militer        Rezim Otoriter
│                         │                        │
Unlock iPhone             Unlock perangkat         Unlock perangkat
tersangka dengan          teroris di lapangan      aktivis, jurnalis,
warrant untuk             untuk intelijen          oposisi tanpa
bukti forensik            segera                   warrant
│                         │                        │
│                         │                        ▼
▼                         ▼                        Pelanggaran HAM,
Digital forensics         Operasi kontra-          pembungkaman
sesuai hukum              terorisme                suara kritis
```

---

## 🔗 Koneksi dalam Vault

- [[cellebrite-ufed]] — GrayKey membuka passcode; UFED mengekstrak data. Keduanya adalah duo standar di laboratorium forensik.
- [[pegasus]] — Jika spyware sudah berhasil menginfeksi, data bisa diambil tanpa perlu unlock. GrayKey digunakan untuk perangkat yang tidak terinfeksi.
- [[finspy]] — FinSpy melakukan surveillance langsung; setelah perangkat disita, GrayKey bisa digunakan untuk ekstraksi tambahan.
- [[victoria-hdd]] / [[pc-3000]] — GrayKey adalah padanan mobile untuk akses hardware-level pada HDD.
- [[xkeyscore]] — Data yang diekstrak bisa di-cross-reference dengan basis data SIGINT.

---

## 📚 Referensi

- Grayshift, _GrayKey Technical Overview & User Manual_ (2024)
- Apple, _Platform Security: Secure Enclave_ (2024)
- NIST, _Mobile Device Forensics: Tools and Techniques_ (2023)
- EFF, _GrayKey and the Fourth Amendment_ (2019)
- Motherboard (Vice), _GrayKey: The Box That Unlocks iPhones_ (2018)
- MITRE ATT&CK: T1588.001 (Obtain Capabilities: Malware), T1056.001 (Input Capture: Keylogging)

---

_GrayKey Deep Dive | iPhone Passcode Hardware Brute-Force | Mobile Forensics Unlock Tool_
