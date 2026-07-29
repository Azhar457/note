---
title: Imsi Catcher
tags:
  - 05-hardware-forensics-and-tactical-devices
  - library
  - military-and-intelligence-tools
created: "2026-06-28"
updated: "2026-07-01"
status: pending
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> IMSI Catcher (International Mobile Subscriber Identity Catcher), sering disebut StingRay (merek dagang Harris Corporation), adalah perangkat pengawasan seluler yang meniru Base Transceiver Station (BTS) sah untuk mencegat komunikasi dan melacak perangkat. Informasi di bawah berasal dari dokumen pengadilan, paten, laporan teknis (3GPP), penelitian akademis, serta investigasi jurnalistik (EFF, ACLU). Pembahasan ini murni **edukasional dan defensif**. Penggunaan tanpa otorisasi hukum adalah pelanggaran serius di hampir semua yurisdiksi.

---

## 🧬 Apa Itu IMSI Catcher / Stingray?

IMSI Catcher adalah perangkat yang menyamar sebagai **Base Transceiver Station (BTS)** atau **eNodeB** (pada 4G/5G) yang sah. Perangkat ini memaksa ponsel di sekitarnya untuk terhubung kepadanya alih-alih ke menara seluler operator asli. Setelah terhubung, IMSI Catcher dapat:

- **Mengumpulkan IMSI** (International Mobile Subscriber Identity) — nomor identitas unik pada SIM card.
- **Mengumpulkan IMEI** (International Mobile Equipment Identity) — nomor identitas perangkat keras ponsel.
- **Melacak lokasi** perangkat (dengan triangulasi atau kekuatan sinyal).
- **Mencegat panggilan suara dan SMS** (jika enkripsi A5/1, A5/2, atau tidak ada enkripsi).
- **Menyadap data seluler** (jika berhasil downgrade ke 2G atau mematikan enkripsi).
- **Menolak layanan (Denial of Service)** dengan memblokir akses ke jaringan asli.

StingRay adalah merek dagang dari **Harris Corporation** (AS), tetapi istilah ini sering digunakan secara generik untuk semua IMSI Catcher. Perangkat serupa diproduksi oleh:

| Produsen                           | Negara    | Produk                             |
| ---------------------------------- | --------- | ---------------------------------- |
| **Harris Corporation** (L3Harris)  | AS        | StingRay, KingFish, Hailstorm      |
| **Septier Communications**         | Israel    | Interceptor, EXODUS                |
| **Ability/Ultra Electronics**      | Israel/UK | GSM/3G/LTE Interceptor             |
| **PKI Electronic**                 | Jerman    | IMSI Catcher series                |
| **Comstrac**                       | UK        | Passive/Active GSM Interceptor     |
| **Rayzone**                        | Israel    | Piranha                            |
| **CETC (China Electronics Tech.)** | Tiongkok  | Berbagai sistem intersepsi seluler |

---

## 🏗️ Arsitektur & Cara Kerja

### Komponen Fisik

IMSI Catcher biasanya terdiri dari:

| Komponen                           | Fungsi                                                                             |
| ---------------------------------- | ---------------------------------------------------------------------------------- |
| **Radio Transceiver** (SDR-based)  | Memancarkan sinyal BTS pada frekuensi GSM/3G/LTE/5G.                               |
| **Amplifier & Antenna**            | Meningkatkan jangkauan (portabel: 100-500m; kendaraan: 1-2km; fixed: hingga 10km). |
| **Komputer Kontrol**               | Menjalankan software untuk mengelola koneksi, mengumpulkan data, dan logging.      |
| **Baterai / Power Supply**         | Untuk operasi portabel (backpack, kendaraan).                                      |
| **Backhaul Connection** (Opsional) | Untuk meneruskan panggilan/data ke jaringan asli (man-in-the-middle penuh).        |

### Mode Operasi

#### 1. Pasif (Passive IMSI Catcher)

- **Tidak memancarkan sinyal** — hanya mendengarkan (sniffing) komunikasi antara ponsel dan BTS asli.
- Mengumpulkan IMSI/IMEI dari prosedur otentikasi yang bocor (pada 2G/3G).
- **Keunggulan**: Tidak terdeteksi karena tidak memancarkan sinyal.
- **Kelemahan**: Hanya bisa menangkap data saat ponsel berkomunikasi; tidak bisa memaksa koneksi.

#### 2. Aktif (Active IMSI Catcher — Stingray Mode)

- **Memancarkan sinyal BTS palsu** dengan sinyal lebih kuat dari BTS asli.
- Ponsel di area akan otomatis terhubung ke BTS palsu (karena sinyal lebih kuat).
- Setelah terhubung, IMSI Catcher meminta IMSI/IMEI, lalu bisa:
  - Meneruskan panggilan ke jaringan asli (MITM penuh).
  - Merekam panggilan/SMS.
  - Melacak lokasi.
  - Mengirim SMS atau USSD command.

#### 3. Downgrade Attack

- IMSI Catcher memaksa ponsel untuk **turun ke 2G (GSM)** dari 4G/5G.
- GSM menggunakan enkripsi A5/1 yang sudah bisa dipecahkan secara real-time.
- Setelah downgrade, panggilan dan SMS bisa didekripsi.

#### 4. Denial of Service (DoS)

- IMSI Catcher mengirimkan pesan **Location Updating Reject** atau **Authentication Reject**.
- Ponsel target tidak bisa terhubung ke jaringan seluler sama sekali.
- Digunakan untuk membungkam komunikasi di area tertentu (misal: saat protes).

---

## 📡 Protokol & Kerentanan yang Dieksploitasi

### 1. Kerentanan di 2G (GSM)

| Kerentanan                      | Deskripsi                                                                                                                                 |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Mutual Authentication Lemah** | Hanya jaringan yang mengotentikasi ponsel; ponsel TIDAK mengotentikasi jaringan. IMSI Catcher bisa menyamar sebagai BTS tanpa terdeteksi. |
| **Enkripsi A5/1 Lemah**         | Cipher A5/1 (64-bit) bisa dipecahkan dengan rainbow tables dalam hitungan detik (teknik "A5/1 cracking").                                 |
| **A5/0 (No Encryption)**        | BTS bisa memerintahkan ponsel menggunakan A5/0 (tanpa enkripsi). IMSI Catcher mengeksploitasi ini.                                        |
| **IMSI Exposure**               | Dalam prosedur awal, ponsel mengirimkan IMSI dalam plaintext jika TMSI tidak tersedia.                                                    |

### 2. Kerentanan di 3G (UMTS)

| Kerentanan                             | Deskripsi                                                                                                                                                 |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mutual Authentication Ada, Tapi...** | 3G mewajibkan mutual authentication, tetapi ponsel bisa di-downgrade ke 2G oleh IMSI Catcher (dengan jamming sinyal 3G/4G atau mengirimkan pesan reject). |
| **IMSI Catcher Detection di 3G**       | Ponsel bisa mendeteksi BTS palsu jika menerima pesan yang tidak sesuai protokol 3G. Tapi IMSI Catcher modern bisa menghindari deteksi.                    |

### 3. Kerentanan di 4G (LTE) & 5G

| Kerentanan                                      | Deskripsi                                                                                                                                                                                                 |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **IMSI Catching via Diameter/SS7**              | Alih-alih menggunakan BTS palsu, penyerang bisa mengeksploitasi kelemahan protokol SS7/Diameter untuk mendapatkan IMSI dan lokasi target dari operator seluler langsung (tanpa perlu dekat secara fisik). |
| **LTE/5G Downgrade ke 2G**                      | Dengan jamming frekuensi LTE/5G, ponsel dipaksa turun ke 2G/3G yang lebih lemah.                                                                                                                          |
| **5G SUCI (Subscription Concealed Identifier)** | 5G memperkenalkan SUCI — IMSI terenkripsi. Tapi implementasi yang salah atau downgrade ke 4G/3G/2G bisa mem-bypass ini.                                                                                   |

---

## 🔬 Kemampuan Spesifik

### 1. IMSI Harvesting

IMSI Catcher mengumpulkan semua IMSI dari ponsel di sekitarnya. Dalam operasi pengawasan massal (misal: demonstrasi), ribuan IMSI bisa dikumpulkan dalam hitungan menit. Data ini kemudian bisa:

- Diidentifikasi (IMSI ↔ nomor telepon ↔ identitas pemilik via operator).
- Dilacak (muncul di lokasi protes → dicurigai aktivis).

### 2. Lokasi Tracking

- **Triangulasi**: Menggunakan beberapa IMSI Catcher untuk menentukan posisi target dengan presisi hingga beberapa meter.
- **Signal Strength**: Bahkan dengan satu perangkat, kekuatan sinyal bisa memperkirakan jarak target.
- **Real-time tracking**: Saat target bergerak, IMSI Catcher terus melacak perpindahannya.

### 3. Voice & SMS Interception

- **2G (GSM)**: Dengan downgrade dan A5/1 cracking, panggilan bisa direkam dan didekripsi real-time.
- **3G/4G**: Jika IMSI Catcher bertindak sebagai MITM penuh (meneruskan panggilan ke jaringan asli), panggilan bisa direkam di perangkat. Namun, enkripsi 3G/4G lebih kuat sehingga perlu downgrade dulu.
- **SMS**: SMS di 2G bisa ditangkap langsung; di 3G/4G perlu downgrade.

### 4. Data Interception

- **2G (GPRS/EDGE)**: Traffic data bisa diintersep dan didekripsi.
- **3G/4G**: Sulit tanpa downgrade, karena enkripsi lebih kuat. Tapi IMSI Catcher bisa memblokir 3G/4G sehingga ponsel jatuh ke 2G.

### 5. Targeted Attack

- **IMSI/IMEI Filtering**: IMSI Catcher bisa dikonfigurasi untuk hanya menyerang target spesifik (whitelist/blacklist), membiarkan ponsel lain tetap terhubung ke jaringan asli.

---

## 🕵️‍♂️ Penggunaan Terdokumentasi

| Negara      | Penggunaan                        | Detail                                                                     |
| ----------- | --------------------------------- | -------------------------------------------------------------------------- |
| **AS**      | Penegak hukum (FBI, polisi lokal) | Digunakan sejak 1990-an; kontroversi karena tanpa warrant di banyak kasus. |
| **UK**      | Polisi Metropolitan, MI5          | Digunakan untuk melacak tersangka kriminal dan teroris.                    |
| **Turki**   | Rezim Erdogan                     | Digunakan untuk melacak aktivis, jurnalis, dan lawan politik.              |
| **Myanmar** | Junta militer                     | Digunakan untuk melacak demonstran prodemokrasi.                           |
| **Meksiko** | Kartel & pemerintah               | Digunakan oleh kedua belah pihak.                                          |
| **China**   | MSS                               | Digunakan secara masif di Xinjiang dan terhadap aktivis.                   |

---

## 🛡️ Deteksi & Countermeasures

### 1. Deteksi IMSI Catcher

| Metode                            | Aplikasi/Tools                                                                                                       |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Android IMSI Catcher Detector** | Aplikasi seperti SnoopSnitch, Cell Spy Catcher, IMSI-Catcher Detector. Memonitor sinyal BTS anomali.                 |
| **iOS**                           | Tidak ada aplikasi khusus (keterbatasan API). Tapi indikator: ponsel tiba-tiba jatuh ke 2G di area yang biasanya 4G. |
| **Field Test Mode**               | Masuk ke Field Test Mode ( `*3001#12345#*` di iPhone) untuk melihat Cell ID, LAC, dan mendeteksi BTS tidak dikenal.  |
| **Femtocell Detection**           | BTS palsu sering tidak memiliki tetangga (neighbor cells) atau parameternya aneh.                                    |
| **Signal Monitoring**             | Lonjakan sinyal tiba-tiba di area yang biasanya sinyal lemah.                                                        |

### 2. Indikator BTS Palsu

| Indikator                    | Normal                   | IMSI Catcher                                                |
| ---------------------------- | ------------------------ | ----------------------------------------------------------- |
| **LAC (Location Area Code)** | Sesuai dengan area       | Berbeda dari sel sekitar, atau tidak berubah saat berpindah |
| **Cell ID**                  | Sesuai database operator | ID tidak dikenal atau duplikat                              |
| **Neighbor Cells**           | Banyak                   | Sedikit atau tidak ada                                      |
| **Enkripsi (Ciphering)**     | A5/1, A5/3               | A5/0 (no encryption) atau A5/1 lemah                        |
| **Sinyal Strength**          | Fluktuatif               | Tiba-tiba sangat kuat                                       |
| **Network Mode**             | 4G/5G stabil             | Tiba-tiba drop ke 2G                                        |

### 3. Countermeasures

| Lapisan        | Tindakan                                                                                         |
| -------------- | ------------------------------------------------------------------------------------------------ |
| **Pengguna**   | Gunakan aplikasi deteksi. Waspada jika ponsel tiba-tiba jatuh ke 2G.                             |
| **Komunikasi** | Gunakan **E2EE** (Signal, WhatsApp). Bahkan jika diintersep, konten tidak bisa dibaca.           |
| **Ponsel**     | Gunakan ponsel dengan chipset yang mendukung deteksi IMSI Catcher (Snapdragon X55+).             |
| **Operator**   | Operator harus mengimplementasikan **5G SUCI**, **mutual authentication**, dan **A5/3 minimal**. |
| **Regulasi**   | Larang penggunaan IMSI Catcher tanpa warrant. Audit penggunaan oleh penegak hukum.               |
| **Teknis**     | Gunakan **VPN** untuk data agar tidak bisa diintersep meskipun di 2G.                            |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Penegak Hukum             Intelijen                 Rezim Otoriter
(dengan warrant)          │                         │
│                         Spionase,                 Melacak aktivis,
Melacak penculik,         kontra-terorisme          jurnalis, oposisi
teroris, kriminal         │                         tanpa warrant
│                         │                         │
│                         │                         ▼
▼                         ▼                         Pelanggaran HAM
Penyelamatan              Operasi militer/          sistematis
sandera                   intelijen sah
```

---

## 🔗 Koneksi dalam Vault

- [[verint]] — Verint adalah platform COMINT skala besar; IMSI Catcher adalah alat taktis lapangan. Keduanya bisa terintegrasi.
- [[upstream-and-tempora]] — Intersep backbone; IMSI Catcher adalah intersep di edge (radio).
- [[pegasus]] — Pegasus menginfeksi perangkat; IMSI Catcher mencegat komunikasi tanpa perlu menginfeksi.
- [[graykey]] / [[cellebrite-ufed]] — Setelah perangkat disita, alat forensik digunakan; IMSI Catcher digunakan untuk melacak sebelum penyitaan.
- [[]] — Digital RF Memory untuk jamming dan spoofing; IMSI Catcher adalah bentuk spesifik dari RF spoofing.

---

## 📚 Referensi

- EFF. _Stingray: The Most Common Cell Phone Surveillance Device_. 2019.
- ACLU. _Stingray Tracking Devices: Who's Got Them?_. 2018.
- 3GPP TS 33.102: _Security Architecture for 3G/4G/5G_.
- Karsten Nohl et al. _A5/1 Cracking and GSM Security_.
- MITRE ATT&CK: T1588 (Obtain Capabilities), T1595 (Active Scanning).

---

_IMSI Catcher / Stingray Deep Dive | Cellular Interception & Tracking | Dual-Use Surveillance Hardware_
