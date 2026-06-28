---
tags:
  - predator
  - intellexa
  - spyware
  - surveillance
  - commercial-spyware
  - dual-use
aliases:
  - Predator spyware
  - Intellexa Alliance
  - Cytrox Predator
created: 2026-06-27
status: operational
cssclasses:
  - wide-table
---

> [!warning] Konteks Etis & Legal
> Predator adalah spyware komersial yang dikembangkan oleh Cytrox (bagian dari Intellexa Alliance). Seluruh informasi di bawah berasal dari publikasi terbuka: Citizen Lab, Amnesty International, Google Threat Analysis Group (TAG), Meta, dan dokumen forensik publik. Pembahasan ini murni **edukasional dan defensif**. Penggunaan tanpa otorisasi terhadap sistem milik orang lain adalah ilegal di hampir semua yurisdiksi. Tujuan dokumen ini adalah membekali pembaca dengan pengetahuan untuk mendeteksi, mencegah, dan merespons ancaman berbasis Predator.

---

## 🧬 Apa Itu Predator?

Predator adalah **platform spyware komersial** yang dikembangkan oleh perusahaan Makedonia Utara **Cytrox** (kemudian diakuisisi oleh **Intellexa Alliance**, konsorsium yang berbasis di Yunani dan Siprus). Intellexa Alliance mencakup beberapa entitas: Cytrox (pengembang Predator), Nexa Technologies (penjualan), WiSpear (network interception), dan lainnya. Predator adalah pesaing langsung Pegasus (NSO Group) dengan kemampuan serupa tetapi harga lebih rendah, menjadikannya pilihan bagi pemerintah dengan anggaran lebih kecil.

Predator pertama kali diungkap oleh Citizen Lab dan Google TAG pada 2021-2022, ketika ditemukan digunakan untuk menargetkan **politisi oposisi di Mesir, jurnalis di Armenia, aktivis di Yunani, dan diplomat di berbagai negara**. Tidak seperti Pegasus yang bergantung pada 0-click iMessage/WhatsApp, Predator diketahui menggunakan **multiple infection vectors** termasuk 0-day browser, link phishing, dan kemungkinan network injection.

### Perbandingan Predator vs Pegasus vs FinSpy

| Aspek                | Pegasus (NSO)                 | Predator (Intellexa)                                                | FinSpy (Gamma)                                           |
| -------------------- | ----------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------- |
| **Pengembang**       | NSO Group (Israel)            | Cytrox/Intellexa (Makedonia Utara/Yunani)                           | Gamma/FinFisher (Jerman)                                 |
| **Fokus Platform**   | iOS, Android (mobile only)    | iOS, Android, Chrome, Windows (multi-platform via browser exploits) | Windows, macOS, Linux, iOS, Android (desktop kuat)       |
| **Vektor Utama**     | 0-click iMessage/WhatsApp     | 0-day & n-day browser (Chrome, Safari), phishing, network injection | Phishing, fake apps, social engineering, physical access |
| **Harga**            | $10-20 juta+                  | $5-10 juta (estimasi)                                               | $1-5 juta (estimasi)                                     |
| **Klien Terungkap**  | 40+ negara                    | Mesir, Armenia, Yunani, Arab Saudi, Vietnam, Indonesia?             | 50+ negara                                               |
| **Deteksi Forensik** | MVT, iShutdown, Amnesty tools | MVT, Google TAG analysis, forensic traces di Chrome/Safari          | Kaspersky, ESET, rootkit scanner                         |

---

## 🏗️ Arsitektur Predator & Intellexa Ecosystem

Intellexa Alliance membangun ekosistem pengawasan yang terintegrasi, di mana Predator adalah ujung tombak. Arsitekturnya:

```
┌──────────────────────────────────────────────────────────────┐
│                    Intellexa Master Server                     │
│  (Control Center - berbasis cloud atau on-premise)             │
│  - Mengelola operasi, agen, pengumpulan data                  │
│  - Antarmuka operator untuk pencarian & analisis              │
│  - Terintegrasi dengan modul lain (WiSpear, dll.)             │
└───────────────────────────┬──────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│  Predator      │ │  Predator      │ │  Predator      │
│  Mobile Agent  │ │  Desktop Agent │ │  Browser Agent │
│  (iOS/Android) │ │  (Windows/mac) │ │  (Chrome/Saf)  │
└────────────────┘ └────────────────┘ └────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Intellexa Relay / Proxy                     │
│  - Menyembunyikan Master Server                               │
│  - Domain fronting, CDN abuse, multi-hop routing              │
│  - Komunikasi terenkripsi (AES-256, custom protocols)         │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Intellexa WiSpear (Opsional)                │
│  - Network interception & injection di level ISP              │
│  - Untuk memaksa target mengunjungi link exploit              │
│  - Man-in-the-middle pada traffic target                      │
└──────────────────────────────────────────────────────────────┘
```

### Komponen Ekosistem Intellexa

| Komponen                 | Fungsi                                                                      |
| ------------------------ | --------------------------------------------------------------------------- |
| **Cytrox Predator**      | Implant spyware untuk mobile dan desktop.                                   |
| **Nexa Technologies**    | Penjualan, negosiasi kontrak, dukungan pelanggan.                           |
| **WiSpear**              | Network interception: pasif (monitoring) dan aktif (injection).             |
| **Senpai** (kemungkinan) | Modul analisis data yang dikumpulkan.                                       |
| **Alias**                | Entitas depan untuk menghindari sanksi (berbasis di Siprus, Yunani, Swiss). |

---

## 💀 Vektor Infeksi & Kill Chain Predator

Berbeda dengan Pegasus yang sangat bergantung pada 0-click, Predator lebih fleksibel dan menggunakan **beberapa rantai infeksi secara paralel**.

### 1. Browser Exploit (Chrome & Safari)

Ini adalah vektor paling signifikan yang diungkap oleh Google TAG. Predator menggunakan **0-day dan n-day exploit** untuk browser Chrome (Windows, macOS, Android) dan Safari (iOS).

**Tahapan infeksi browser:**

```
[Target menerima link via SMS/email/WhatsApp]
         │
         ▼
[Link mengarah ke domain exploit server]
  (Domain sering dibuat dengan typosquatting
   dari situs berita/portal pemerintah)
         │
         ▼
[Halaman exploit memuat JavaScript/WebAssembly]
  (Mendeteksi browser, versi, OS)
         │
         ▼
[Exploit rantai (1-click)]
  Stage 1: Renderer RCE (misal: CVE-2022-3723 - Chrome V8)
  Stage 2: Sandbox escape (misal: CVE-2022-4135 - Chrome GPU)
  Stage 3: Kernel privilege escalation (OS-specific)
         │
         ▼
[Payload Predator terinstal di perangkat]
  - Android: APK dengan hak akses tinggi
  - iOS: Binary yang ditandatangani enterprise certificate
  - Windows/macOS: Executable/dylib persistence
```

**CVE yang pernah digunakan Predator (terungkap):**

| CVE            | Platform | Komponen  | Jenis                  |
| -------------- | -------- | --------- | ---------------------- |
| CVE-2022-3723  | Chrome   | V8 engine | Renderer RCE (0-day)   |
| CVE-2022-4135  | Chrome   | GPU       | Sandbox escape (0-day) |
| CVE-2022-4262  | Chrome   | V8 engine | Renderer RCE (0-day)   |
| CVE-2021-38003 | Chrome   | V8 engine | Renderer RCE (n-day)   |
| CVE-2021-37973 | Chrome   | Portals   | Use-after-free         |
| CVE-2022-2294  | WebRTC   | Video     | Buffer overflow        |
| CVE-2023-4762  | Chrome   | V8 engine | Type confusion (0-day) |

Google TAG mencatat bahwa Predator adalah salah satu pengguna 0-day Chrome paling produktif yang pernah mereka lacak.

### 2. Mobile Infection (Android & iOS)

**Android:**

- Link phishing yang mengarah ke APK berbahaya (menyamar sebagai aplikasi sistem).
- Exploit browser (Chrome) → mengunduh APK otomatis.
- Fake update via SMS.

**iOS:**

- Exploit Safari (WebKit) → mengunduh binary.
- **Enterprise certificate abuse**: Binary ditandatangani dengan sertifikat enterprise, mem-bypass App Store.
- **MDM profile abuse**: Membujuk korban menginstal profil Mobile Device Management yang memberikan kontrol penuh.

### 3. Network Injection (via WiSpear)

Jika klien Intellexa memiliki akses ke infrastruktur ISP lokal (melalui kolusi dengan pemerintah), mereka dapat menggunakan **WiSpear** untuk:

- Menyuntikkan iframe atau redirect ke website yang dikunjungi target.
- Memaksa target mengunduh exploit tanpa perlu mengklik link.
- Meng-intercept traffic untuk mengumpulkan metadata.

Ini mirip dengan network injection Pegasus, tetapi WiSpear adalah produk terpisah yang terintegrasi.

### 4. Phishing & Social Engineering

Operator Predator sering menggunakan **social engineering** yang ditargetkan:

- Email dengan lampiran berbahaya (PDF, DOCX dengan exploit).
- Pesan WhatsApp/SMS dari nomor yang tampak resmi.
- Fake news articles yang meminta target mengklik link.

---

## 🦠 Kemampuan Implant Predator

### Mobile (Android/iOS)

| Kemampuan                | Deskripsi                                                             |
| ------------------------ | --------------------------------------------------------------------- |
| **Audio Recording**      | Aktifkan mikrofon untuk merekam percakapan ambient.                   |
| **Call Recording**       | Rekam panggilan telepon (VoLTE, VoWiFi, GSM).                         |
| **Camera Capture**       | Ambil foto/video dari kamera depan/belakang.                          |
| **GPS Tracking**         | Lacak lokasi real-time dan history.                                   |
| **Message Interception** | Baca SMS, WhatsApp, Telegram, Signal, Viber, Facebook Messenger, dll. |
| **Contact/Calendar**     | Ekstrak kontak, kalender, catatan.                                    |
| **File Exfiltration**    | Akses penyimpanan internal, unggah file target.                       |
| **Keylogging**           | Rekam input keyboard.                                                 |
| **Screenshot**           | Ambil screenshot layar secara periodik.                               |
| **App Installation**     | Instal/matikan aplikasi dari jarak jauh.                              |
| **Persistence**          | Bertahan setelah reboot via proses sistem.                            |

### Desktop (Windows/macOS)

| Kemampuan                | Deskripsi                                                                        |
| ------------------------ | -------------------------------------------------------------------------------- |
| **File System Access**   | Browse, baca, tulis, unggah file apa pun.                                        |
| **Keylogging**           | Rekam semua ketukan keyboard.                                                    |
| **Screenshot**           | Screenshot periodik.                                                             |
| **Webcam/Mic**           | Streaming audio/video real-time.                                                 |
| **Browser Data**         | Ekstrak password, history, cookies, bookmark dari Chrome, Firefox, Edge, Safari. |
| **Email Exfiltration**   | Akses Outlook, Thunderbird, Apple Mail.                                          |
| **VoIP Interception**    | Rekam panggilan Skype, Zoom, Teams, dll. (via audio hook).                       |
| **Clipboard Monitoring** | Catat isi clipboard.                                                             |
| **Process/Service Enum** | Lihat proses berjalan, service, driver.                                          |
| **Network Monitoring**   | Tangkap traffic jaringan, lihat koneksi aktif.                                   |

---

## 🔬 Deteksi Forensik Predator

### 1. Jejak di Browser (Chrome)

Google TAG mengembangkan metode forensik untuk mendeteksi infeksi Predator melalui artefak browser:

- **Crash Reports**: Chrome mengirimkan crash report saat tab crash. Jika exploit gagal sebagian, crash report mungkin mengandung stack trace yang menunjukkan eksploitasi V8 atau GPU. Analisis `chrome://crashes` atau file dump lokal.
- **History & Downloads**: Periksa history browser untuk URL mencurigakan (domain dengan typosquatting, domain pendek aneh). Periksa download file APK atau executable yang tidak dikenal.
- **Service Worker**: Beberapa exploit Predator mendaftarkan service worker untuk persistensi. Periksa `chrome://serviceworker-internals/` untuk entri mencurigakan.
- **Extensions**: Beberapa varian mencoba menginstal ekstensi Chrome berbahaya. Periksa `chrome://extensions/`.
- **Log Files**: `chrome_debug.log` mungkin berisi error yang terkait dengan exploit.

### 2. Jejak di Android

| Artefak                   | Lokasi / Metode                                                                     |
| ------------------------- | ----------------------------------------------------------------------------------- |
| **APK mencurigakan**      | `/data/app/` atau `/data/data/` dengan nama paket tidak dikenal.                    |
| **Device Admin**          | Pengaturan > Keamanan > Administrator Perangkat — cari aplikasi yang tidak dikenal. |
| **Accessibility Service** | Pengaturan > Aksesibilitas — cari service mencurigakan dengan hak penuh.            |
| **Unknown Sources**       | Jika diaktifkan untuk aplikasi tidak dikenal.                                       |
| **Network Connections**   | `netstat` atau `lsof` untuk koneksi ke IP/domain mencurigakan.                      |
| **SMS/MMS**               | Pesan phishing yang mungkin masih ada di inbox.                                     |

### 3. Jejak di iOS

| Artefak                    | Lokasi / Metode                                                                 |
| -------------------------- | ------------------------------------------------------------------------------- |
| **Enterprise Certificate** | Pengaturan > Umum > VPN & Manajemen Perangkat — cari profil yang tidak dikenal. |
| **MDM Profile**            | Pengaturan > Umum > Manajemen Perangkat — profil MDM yang tidak sah.            |
| **Safari History**         | Periksa history untuk link exploit.                                             |
| **Shutdown Log**           | Analisis `shutdown.log` (via iShutdown tool) untuk proses aneh saat restart.    |
| **Backup Analysis**        | Gunakan MVT untuk memeriksa IOC (domain, IP, file hash).                        |
| **Battery Usage**          | Pengaturan > Baterai — aplikasi tidak dikenal yang menggunakan baterai tinggi.  |

### 4. Analisis Jaringan

- **Domain IOC**: Predator menggunakan domain dengan pola tertentu: domain pendek, typosquatting situs berita, domain dengan TLD tidak biasa (.xyz, .top, .online).
- **IP C2**: IP server C2 yang diketahui dari investigasi Citizen Lab dan Google TAG.
- **SSL/TLS Fingerprint**: Sertifikat server Intellexa mungkin memiliki karakteristik yang bisa diidentifikasi.

### 5. MVT (Mobile Verification Toolkit)

MVT dari Amnesty International mendukung deteksi Predator dengan IOC yang diperbarui. Fitur:

- Memindai backup iOS/Android untuk indikator kompromi.
- Mengecek domain C2, IP, dan hash file.
- Menganalisis log sistem untuk anomali.

---

## 📊 Studi Kasus & Penyalahgunaan Terungkap

### Kasus 1: Mesir — Politisi Oposisi

Pada 2021-2022, beberapa politisi oposisi Mesir di pengasingan (di Eropa) ditarget dengan Predator. Mereka menerima link via WhatsApp/SMS yang mengarah ke domain exploit. Google TAG mengonfirmasi bahwa link tersebut mengeksploitasi Chrome 0-day (CVE-2022-3723). Infeksi berhasil pada beberapa target.

### Kasus 2: Armenia — Jurnalis

Jurnalis investigasi di Armenia ditarget dengan Predator melalui phishing yang sangat ditargetkan. Link dikirim dari nomor yang menyamar sebagai kolega. Infeksi menggunakan exploit Safari dan Chrome.

### Kasus 3: Yunani — Aktivis & Politikus

Skandal "Greek Watergate" (2022) mengungkap bahwa badan intelijen Yunani (EYP) menggunakan Predator untuk menargetkan anggota parlemen oposisi, jurnalis, dan aktivis. Infeksi dilakukan melalui SMS berisi link exploit. Kasus ini menyebabkan pengunduran diri kepala intelijen Yunani.

### Kasus 4: Vietnam? — Indikasi Penggunaan

Laporan dari Amnesty International dan Electronic Frontier Foundation menunjukkan kemungkinan penggunaan Predator di Vietnam terhadap aktivis dan blogger, meskipun bukti teknis masih terbatas.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Law Enforcement           Intelijen                 Rezim Otoriter
(dengan warrant)          │                         │
│                         Spionase                 Menargetkan oposisi,
│                         terhadap                 aktivis, jurnalis,
▼                         diplomat                 pengacara HAM
Investigasi               │
kriminal serius           │                         ▼
│                         │                         Pelanggaran HAM
│                         │                         sistematis
└─────────────────────────────────────────────────┘
```

Intellexa mengklaim hanya menjual ke pemerintah untuk tujuan penegakan hukum dan intelijen sah. Namun, bukti menunjukkan penggunaan oleh rezim otoriter untuk menekan oposisi damai. Uni Eropa dan AS telah menjatuhkan sanksi kepada Intellexa Alliance dan entitas terkait.

---

## 🛡️ Countermeasures

| Lapisan               | Tindakan                                                                                                                                                 |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pengguna**          | Waspada terhadap link dari sumber tidak dikenal. Jangan klik link pendek atau mencurigakan. Verifikasi identitas pengirim.                               |
| **Browser**           | Selalu perbarui Chrome, Safari, Edge ke versi terbaru. Aktifkan "Enhanced Safe Browsing" di Chrome. Nonaktifkan JavaScript di browser jika memungkinkan. |
| **Mobile**            | Aktifkan Lockdown Mode di iOS 16+. Jangan instal profil konfigurasi dari sumber tidak dikenal. Periksa secara berkala Manajemen Perangkat.               |
| **Android**           | Matikan "Unknown Sources". Jangan instal APK di luar Play Store. Periksa Device Admin dan Accessibility Services secara berkala.                         |
| **Network**           | Gunakan VPN terpercaya. Monitor DNS untuk domain mencurigakan. Blokir IOC Intellexa di firewall.                                                         |
| **Scanning**          | Jalankan MVT secara berkala pada backup iOS/Android. Periksa log shutdown iOS dengan iShutdown.                                                          |
| **Incident Response** | Jika terinfeksi: isolasi perangkat, jangan restart (preserve memory), ambil forensik image, laporkan ke CERT lokal dan Citizen Lab/Amnesty.              |

---

## 🔗 Koneksi dalam Vault

- [[pegasus]] — Predator adalah pesaing utama Pegasus, menggunakan pendekatan berbeda (browser exploits vs 0-click iMessage). Keduanya adalah spyware komersial paling canggih.
- [[finspy]] — FinSpy lebih fokus desktop, Predator lebih mobile dan browser. Ketiganya adalah contoh spyware komersial yang disalahgunakan.
- [[shodan]] — Dapat digunakan untuk mencari server C2 Intellexa yang terekspos.
- [[google-dorks]] — Dapat digunakan untuk mencari domain exploit Predator yang terindeks.
- [[maltego]] — Untuk memetakan infrastruktur Intellexa dari IOC yang diketahui.
- [[xkeyscore]] — Platform SIGINT global dapat mendeteksi traffic C2 Predator di backbone.

---

## 📚 Referensi

- Citizen Lab, _Predator: The Mercenary Spyware_ (2021-2023)
- Google Threat Analysis Group (TAG), _Exposing Cytrox Predator Spyware_ (2022-2023)
- Amnesty International, _Predator Spyware and the Greek Watergate_ (2022)
- Meta, _Taking Action Against Surveillance-for-Hire_ (2022)
- MITRE ATT&CK: T1189 (Drive-by Compromise), T1203 (Exploitation for Client Execution), T1056.001 (Input Capture: Keylogging)
- European Parliament, _Sanctions Against Intellexa_ (2023)

---

_Predator Deep Dive | Intellexa Commercial Spyware | Browser Exploitation & Mobile Surveillance_
