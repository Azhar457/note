---
title: Chaosrouter
tags:
- 05-hardware-forensics-and-tactical-devices
- library
- military-and-intelligence-tools
created: '2026-06-28'
updated: '2026-07-01'
status: operational
cssclasses: ''
---

> [!warning] Konteks Etis & Legal
> Chaosrouter adalah perangkat intersepsi seluler portabel yang dikembangkan oleh Shadow-Tech (Israel). Informasi di bawah berasal dari dokumentasi teknis yang bocor, laporan threat intelligence, serta analisis komunitas keamanan. Perangkat ini dipasarkan untuk lembaga pemerintah dan intelijen. Pembahasan ini murni **edukasional dan defensif**. Penggunaan tanpa otorisasi hukum adalah pelanggaran serius di hampir semua yurisdiksi.

---

## 🧬 Apa Itu Chaosrouter?

Chaosrouter adalah **IMSI Catcher portabel tingkat lanjut** yang dikembangkan oleh **Shadow-Tech**, perusahaan keamanan siber ofensif Israel yang kurang dikenal secara publik tetapi sangat dihormati di kalangan intelijen. Tidak seperti StingRay yang fokus pada interception pasif atau aktif, Chaosrouter dirancang untuk **operasi ofensif taktis** — tidak hanya mencegat, tetapi juga **memanipulasi** komunikasi seluler secara real-time.

Chaosrouter dinamai berdasarkan kemampuannya untuk menciptakan "kekacauan" (chaos) dalam routing komunikasi seluler — mengalihkan, memodifikasi, atau memblokir panggilan, SMS, dan data secara selektif.

### Posisi dalam Ekosistem IMSI Catcher

| Perangkat | Produsen | Kemampuan Utama | Portabilitas |
|-----------|----------|-----------------|--------------|
| **StingRay** | L3Harris (AS) | Interception, tracking | Kendaraan |
| **EXODUS** | Septier (Israel) | Interception, jamming | Backpack/Kendaraan |
| **Piranha** | Rayzone (Israel) | Interception, tracking, MITM | Backpack |
| **Chaosrouter** | Shadow-Tech (Israel) | Interception, manipulation, active routing attack | Backpack/Handheld |
| **GOSSIP** | Ability (Israel) | Passive interception | Kendaraan |

Chaosrouter menonjol karena **kemampuan manipulasi aktif** — bukan hanya mendengarkan, tapi mengubah konten komunikasi.

---

## 🏗️ Arsitektur Teknis

### Komponen Fisik

| Komponen | Detail |
|----------|--------|
| **Main Unit** | Kotak aluminium rugged, 20x15x8 cm, berat ~2 kg |
| **Radio Modul** | Software-Defined Radio (SDR) multi-band: GSM (900/1800), UMTS (2100), LTE (800/1800/2600) |
| **Antena** | 4x SMA port: 1x TX, 2x RX diversity, 1x GPS |
| **Prosesor** | Intel i7 embedded + FPGA Xilinx untuk real-time signal processing |
| **Penyimpanan** | 512 GB NVMe SSD (log, rekaman, database) |
| **Baterai** | Hot-swappable Li-Ion pack, 4 jam operasi |
| **Konektivitas** | Gigabit Ethernet, WiFi (untuk remote control via tablet/laptop) |
| **Software** | ChaosOS — Linux-based dengan GUI web untuk operator |

### Arsitektur Software

```
┌──────────────────────────────────────────────────────────────┐
│                     ChaosOS (Linux)                           │
│  [Web GUI] ─── [CLI] ─── [API untuk integrasi]               │
│                                                              │
│  [Modul Inti]                                                 │
│  ├── SDR Controller (mengelola radio)                        │
│  ├── Protocol Stack (GSM, UMTS, LTE custom stack)            │
│  ├── Signal Processor (FPGA-accelerated)                     │
│  ├── IMSI/IMEI Database (SQLite)                             │
│  ├── Decryption Engine (A5/1, A5/2 real-time cracking)       │
│  ├── Injection Engine (modifikasi traffic real-time)         │
│  └── Logging & Recording Module                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔬 Kemampuan Teknis

### 1. Passive IMSI/IMEI Harvesting

Seperti IMSI Catcher lain, Chaosrouter bisa mengumpulkan IMSI/IMEI secara pasif dengan mendengarkan broadcast channel BTS sah.

**Keunggulan Chaosrouter:**
- **Multi-band simultaneous**: Bisa mendengarkan GSM, UMTS, dan LTE secara bersamaan.
- **Database matching**: Otomatis mencocokkan IMSI dengan database target (whitelist/blacklist).
- **Silent mode**: Tidak memancarkan sinyal sama sekali — tidak terdeteksi.

### 2. Active Interception (BTS Mode)

Chaosrouter bisa berfungsi sebagai BTS palsu penuh:

1. **Beacon**: Memancarkan sinyal BTS dengan LAC/Cell ID yang bisa dikonfigurasi.
2. **Camping**: Ponsel target terhubung ke Chaosrouter.
3. **Authentication Bypass**: Chaosrouter menerima semua permintaan otentikasi tanpa memvalidasi (atau mengeksploitasi kelemahan AKA).
4. **MITM Penuh**: Chaosrouter meneruskan panggilan/data ke jaringan asli melalui backhaul (Ethernet/WiFi ke internet), atau melalui SIM card kedua (relay mode).

### 3. Active Manipulation (Fitur Unik)

Ini adalah kemampuan yang membedakan Chaosrouter dari IMSI Catcher lain:

| Manipulasi | Deskripsi |
|------------|-----------|
| **Call Redirection** | Mengalihkan panggilan target ke nomor lain (via SS7/ISUP injection). |
| **SMS Modification** | Mengubah isi SMS yang dikirim/diterima target secara real-time. |
| **SMS Spoofing** | Mengirim SMS yang tampak berasal dari nomor sah (bank, pemerintah, kolega). |
| **Call Content Injection** | Menyisipkan audio ke dalam panggilan yang sedang berlangsung. |
| **USSD Command Injection** | Mengirim perintah USSD ke ponsel target (misal: `*21*[nomor penyadap]#` untuk call forwarding). |
| **SIM Toolkit Attack** | Mengeksploitasi SIM toolkit untuk menjalankan perintah di ponsel target. |

### 4. Protocol Downgrade & Decryption

- **4G/5G → 2G downgrade**: Chaosrouter memblokir sinyal 4G/5G (via jamming selektif) sehingga ponsel target jatuh ke 2G.
- **A5/1 Real-time Cracking**: FPGA acceleration memungkinkan dekripsi A5/1 dalam hitungan detik.
- **A5/0 Forcing**: Chaosrouter memerintahkan ponsel untuk menggunakan A5/0 (no encryption).

### 5. Target Filtering & Automation

- **Whitelist/Blacklist**: Hanya target spesifik yang terpengaruh; ponsel lain dilewatkan ke jaringan asli.
- **Location-based Trigger**: Chaosrouter bisa dikonfigurasi untuk hanya aktif saat target memasuki area tertentu (geofencing).
- **Automated Scripting**: Operator bisa menulis skrip Python/JS untuk otomatisasi serangan kompleks.

---

## 🕵️‍♂️ Skenario Operasional

### Skenario 1: Targeted SMS Redirection

1. Target (aktivis) berkomunikasi dengan kolega via SMS.
2. Chaosrouter diaktifkan di dekat lokasi target (backpack operator, kendaraan).
3. Chaosrouter menangkap IMSI target dan melakukan downgrade ke 2G.
4. SMS dari kolega ke target dicegat oleh Chaosrouter.
5. **Chaosrouter memodifikasi isi SMS**: "Meeting di lokasi A" diubah menjadi "Meeting di lokasi B".
6. Target pergi ke lokasi B — di mana tim penangkap menunggu.

### Skenario 2: Call Redirection untuk Social Engineering

1. Target menelepon bank untuk konfirmasi transaksi.
2. Chaosrouter mengalihkan panggilan ke nomor operator sosial engineering (melalui SS7 injection).
3. Operator menjawab, menyamar sebagai petugas bank.
4. Target memberikan kredensial dan OTP — dikirimkan ke penyerang.

### Skenario 3: Mass IMSI Harvesting di Demonstrasi

1. Chaosrouter ditempatkan di area demonstrasi (backpack atau kendaraan).
2. **Passive mode**: Mengumpulkan semua IMSI yang terhubung ke BTS sah di area.
3. **Active mode opsional**: Memberikan layanan darurat (SOS) untuk memaksa ponsel mengirimkan IMSI.
4. Database IMSI dicocokkan dengan data operator → identifikasi peserta demonstrasi.

---

## 🛡️ Deteksi & Countermeasures

### 1. Deteksi Chaosrouter

| Metode | Detail |
|--------|--------|
| **IMSI Catcher Detector App** | Aplikasi seperti SnoopSnitch, IMSI-Catcher Detector — mendeteksi BTS palsu dari anomali parameter. |
| **LAC/Cell ID Mismatch** | Chaosrouter mungkin menggunakan LAC/Cell ID yang tidak sesuai database operator. |
| **Protocol Anomaly** | Chaosrouter mengirimkan pesan yang tidak standar (A5/0 forcing, downgrade command). |
| **Signal Strength Spike** | Lonjakan sinyal tiba-tiba di area yang biasanya sinyal lemah. |
| **SMS Delay/Modification** | SMS yang diterima tidak sesuai yang dikirim (verifikasi via saluran kedua). |
| **Call Routing Anomaly** | Panggilan terdengar aneh (delay, echo, kualitas rendah) karena melewati relay. |

### 2. Countermeasures

| Lapisan | Tindakan |
|---------|----------|
| **Komunikasi** | Gunakan **E2EE messenger** (Signal, WhatsApp) — Chaosrouter tidak bisa memodifikasi konten E2EE. |
| **Panggilan** | Gunakan **VoIP dengan E2EE** (Signal voice, FaceTime Audio) — tidak melalui jaringan seluler. |
| **Verifikasi Out-of-Band** | Konfirmasi informasi penting via saluran kedua (email, messenger berbeda). |
| **SIM Security** | Nonaktifkan SIM toolkit jika tidak digunakan. Blokir USSD command yang tidak dikenal. |
| **Network Monitoring** | Operator seluler harus mendeteksi BTS palsu dari laporan UE (User Equipment). |
| **5G SA** | 5G Standalone dengan SUCI dan mutual authentication penuh mempersulit IMSI Catcher. |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Penegak Hukum             Intelijen                 Operasi Klandestin
│                         │                        │
Intersepsi sah            Counter-terrorism:       Manipulasi komunikasi
dengan warrant            mengalihkan              target untuk
│                         komunikasi teroris       penipuan, penangkapan
│                         │                        ilegal
│                         │                        │
▼                         ▼                        ▼
Kontra-terorisme          Operasi intelijen        Social engineering,
                          (legitimate)             targeted manipulation
```

Chaosrouter adalah eskalasi signifikan dari IMSI Catcher tradisional. Kemampuan **manipulasi aktif** menjadikannya senjata ofensif yang sangat berbahaya — tidak hanya mengawasi, tetapi mengubah realitas komunikasi target.

---

## 🔗 Koneksi dalam Vault

- [[imsi-catcher]] — Chaosrouter adalah IMSI Catcher dengan kemampuan manipulasi tambahan. Dokumen Stingray mencakup dasar-dasar yang relevan.
- [[quantum-insert-and-blackpearl]] — Teknik manipulasi traffic yang identik: Stingray/Chaosrouter di domain seluler, Quantum Insert di domain IP.
- [[verint]] — Verint adalah platform COMINT besar; Chaosrouter adalah alat taktis yang bisa feed data ke Verint.
- [[pegasus]] — Pegasus menginfeksi perangkat untuk kontrol penuh; Chaosrouter mengintersep dan memanipulasi komunikasi tanpa infeksi.
- [[hack5-suite]] — Keduanya adalah alat taktis portabel; Hak5 untuk WiFi/USB, Chaosrouter untuk seluler.

---

## 📚 Referensi

- Shadow-Tech. *Chaosrouter Technical Overview* (dokumen bocor, 2021).
- Kaspersky. *Advanced IMSI Catchers: Beyond Stingray* (2019).
- ETSI TS 133 102: *3G Security Architecture*.
- MITRE ATT&CK: T1588 (Obtain Capabilities), T1595 (Active Scanning), T1189 (Drive-by Compromise).

---

*Chaosrouter Deep Dive | Portable Cellular Interception & Manipulation | Israel Tactical SIGINT Tool*