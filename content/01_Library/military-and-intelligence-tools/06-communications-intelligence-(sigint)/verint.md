---
title: "Verint"
tags:
  - 06-communications-intelligence-(sigint)
  - library
  - military-and-intelligence-tools
aliases:
  - "verint"
created: "2026-06-27"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> Verint Systems adalah perusahaan intelijen komunikasi yang menjual platform intersepsi kepada pemerintah dan penyedia telekomunikasi. Seluruh informasi di bawah berasal dari dokumen publik (Snowden leaks, kontrak pemerintah, dokumentasi pemasaran Verint, laporan Citizen Lab, EFF). Pembahasan ini murni **edukasional dan defensif**. Intersepsi komunikasi tanpa otorisasi hukum adalah pelanggaran serius di hampir semua yurisdiksi. Tujuannya membekali pembaca dengan pengetahuan tentang kemampuan pengawasan massal dan cara melindungi komunikasi.

---

## 🧬 Apa Itu Verint?

Verint Systems Inc. adalah perusahaan intelijen yang berkantor pusat di Melville, New York, dengan akar kuat di Israel (didirikan oleh veteran Unit 8200). Verint adalah salah satu pemain utama dalam industri **COMINT (Communications Intelligence)** global, menyediakan platform intersepsi, analisis, dan data fusion untuk badan intelijen, militer, dan lembaga penegak hukum di lebih dari 75 negara.

Jika PRISM dan UPSTREAM adalah program spesifik NSA, **Verint adalah vendor komersial yang membangun infrastruktur teknis** untuk program-program semacam itu. Dalam Snowden leaks, Verint muncul sebagai kontraktor utama yang menyediakan perangkat keras dan perangkat lunak untuk intersepsi komunikasi global, termasuk untuk program NSA dan sekutunya (Five Eyes).

### Posisi Verint dalam Ekosistem SIGINT

```
[Pengumpulan Data]               [Analisis]                  [Fusi]
──────────────────────────────────────────────────────────────────
Verint COMINT                Verint Analytics           Verint Fusion
(Mengintersep)               (Memproses, mencari,       (Gabungkan dgn
│                            menganalisis)              HUMINT, OSINT,
│                            │                          financial, dll.)
▼                            ▼                          ▼
PSTN, VoIP, Mobile,          Metadata analysis,         Verint Web 
Satcom, IP, Microwave        link analysis,             Intelligence,
                              pattern detection          social media
                                                        monitoring
```

---

## 🏗️ Arsitektur Platform Intersepsi Verint

Verint tidak menjual satu alat, melainkan **platform modular** yang bisa dikonfigurasi sesuai kebutuhan klien (negara atau penyedia telekomunikasi).

### Modul Utama

| Modul | Fungsi | Detail Teknis |
|-------|--------|---------------|
| **Verint COMINT** | Intersep pasif pada berbagai media komunikasi. | TAP pasif pada backbone fiber, microwave relay, satelit, PSTN, mobile core network (MSC, GGSN). |
| **Verint IP Intercept** | Intersep traffic internet (IP). | Deep Packet Inspection (DPI), rekonstruksi sesi TCP, ekstraksi email, chat, browsing, file transfer. |
| **Verint Voice** | Intersep suara (PSTN, VoIP). | Demodulasi, decoding codec (G.711, G.729, AMR, SILK, Opus), speaker identification, language ID. |
| **Verint Mobile** | Intersep mobile (GSM, 3G, LTE, 5G). | IMSI/IMEI catcher compatibility, passive intercept via core network, SS7/Diameter exploitation. |
| **Verint Satellite** | Intersep komunikasi satelit. | Downlink intercept, demodulasi VSAT, Inmarsat, Iridium, Thuraya. |
| **Verint Mass Data** | Penyimpanan dan pengolahan data masif. | Petabyte-scale storage, indexing, search engine untuk data intersep. |
| **Verint Analytics** | Analisis data intersep. | Link analysis, social network analysis, pattern detection, anomaly detection. |
| **Verint Fusion** | Fusi data dari berbagai sumber. | Gabungkan COMINT dengan HUMINT, OSINT, SIGINT lain, financial intel (FININT). |
| **Verint Web Intelligence** | Monitoring internet & media sosial. | Scraping, sentiment analysis, influence tracking. |

### Arsitektur Operasional

```
┌──────────────────────────────────────────────────────────────┐
│                     Sumber Komunikasi                         │
│  [PSTN] [VoIP] [Mobile Core] [IP Backbone] [Satellite]       │
└───────────────────────────┬──────────────────────────────────┘
                            │ (TAP pasif - fiber split, microwave horn, sat dish)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Verint Front-End                           │
│  - Probe hardware (rack-mount) di titik intersepsi            │
│  - Demodulator, decoder, DPI engine                           │
│  - Time-stamping & metadata extraction                        │
│  - Enkripsi data ke back-end                                  │
└───────────────────────────┬──────────────────────────────────┘
                            │ (Encrypted tunnel, dedicated fiber)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Verint Data Center                         │
│  - Mass storage (HDFS, custom FS)                             │
│  - Full-text indexing (Elasticsearch-like, custom)            │
│  - Metadata database (phone numbers, IMSI, IP, email, etc.)   │
│  - Analytics engine (link analysis, ML, pattern detection)    │
└───────────────────────────┬──────────────────────────────────┘
                            │ (Web GUI, API)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Operator Workstation                        │
│  - Search: "Tampilkan semua panggilan nomor X dalam 30 hari"  │
│  - Link analysis: Siapa yang sering dihubungi X?              │
│  - Real-time monitoring: Streaming audio/chat                 │
│  - Geospatial: Peta lokasi target                             │
└──────────────────────────────────────────────────────────────┘
```

---

## 📡 Metode Intersepsi Teknis

### 1. PSTN / Fixed Line

- **TAP di exchange (central office)**: Verint memasang probe pada switch telepon (sebelumnya TDM, sekarang softswitch/VoIP trunk) untuk merekam semua panggilan yang lewat.
- **SS7 interception**: Memanfaatkan kelemahan protokol SS7 untuk mengalihkan panggilan target ke perekam (redirection), atau mendapatkan metadata panggilan (Call Detail Records).
- **Audio mining**: Setelah direkam, suara dikonversi ke teks (speech-to-text) untuk pencarian kata kunci otomatis.

### 2. Mobile (GSM/3G/LTE/5G)

Verint dapat beroperasi di beberapa titik di jaringan mobile:

| Titik Intersepsi | Protokol | Data yang Didapat |
|------------------|----------|-------------------|
| **A-bis Interface** (BTS ↔ BSC) | GSM/LTE | Voice, SMS, data (sebelum enkripsi A5 diaktifkan jika lemah). |
| **A Interface** (BSC ↔ MSC) | GSM | Voice, SMS, signaling (SS7). |
| **MSC/VLR** | 3G/4G | Metadata panggilan, lokasi (cell ID, LAC, TAC). |
| **GGSN/PGW** | 3G/LTE/5G | Data IP (browsing, email, chat, VoIP). |
| **HSS/HLR** | Semua generasi | Informasi subscriber, lokasi, layanan. |
| **Diameter (4G/5G)** | LTE/5G | Metadata panggilan dan data, lokasi, roaming. |

Selain passive intercept, Verint juga mendukung **active measures** melalui eksploitasi SS7 dan Diameter:
- Mengirim pesan SS7 `ProvideSubscriberInfo` untuk mendapatkan lokasi target.
- Mengirim `InsertSubscriberData` untuk mengubah profil target (misal: aktifkan lawful intercept).
- Pada 4G/5G, eksploitasi Diameter untuk intercept data roaming.

### 3. VoIP & IP Communications

Verint IP Intercept menggunakan **Deep Packet Inspection (DPI)** pada backbone internet:
- Mengidentifikasi traffic VoIP (SIP, RTP) dan mengekstrak audio.
- Mengidentifikasi aplikasi chat (WhatsApp, Telegram, Skype, Viber, WeChat) dari signature traffic, lalu merekam metadata (siapa, kapan, berapa lama) — meskipun konten terenkripsi.
- Merekonstruksi email (SMTP, POP3, IMAP).
- Melacak browsing (HTTP) dan download.

Untuk traffic terenkripsi, Verint tidak bisa mendekripsi E2EE (WhatsApp, Signal, Telegram Secret Chat). Namun, ia bisa:
- Mengumpulkan metadata (siapa berbicara dengan siapa, kapan, berapa lama, berapa banyak data).
- Jika kunci tersedia (misal: server WhatsApp di-hijack, atau SSL termination di ISP), traffic bisa didekripsi.

### 4. Satellite Communications

Verint Satellite dapat mengintersep **downlink** dari satelit komunikasi:
- VSAT (Very Small Aperture Terminal) — internet via satelit.
- Inmarsat / Iridium / Thuraya — telepon satelit.
- Menggunakan parabolic dish besar + demodulator Verint.
- Lokasi target (GPS dari handset, atau triangulasi satelit).

### 5. Microwave & Wireless

- Intersepsi microwave relay point-to-point (sering digunakan oleh ISP dan operator seluler untuk backhaul).
- Wi-Fi interception (jika dekat dengan target).

---

## 🔍 Analisis & Data Fusion

Setelah data terkumpul, Verint menyediakan alat analisis canggih:

### Link Analysis & Social Network Analysis

Mirip dengan Maltego tetapi pada skala masif dan otomatis. Verint membangun **graf komunikasi** dari metadata (panggilan, SMS, chat, email). Operator bisa:
- Melihat jaringan sosial target (siapa yang sering dihubungi, siapa yang jarang, siapa yang baru muncul).
- Mendeteksi "broker" (orang yang menghubungkan dua kelompok berbeda).
- Mendeteksi perubahan pola komunikasi (misal: dua orang yang biasanya tidak pernah kontak tiba-tiba sering berkomunikasi sebelum kejadian).

### Speech-to-Text & Keyword Spotting

Semua panggilan yang direkam dikonversi ke teks (dengan mesin speech recognition Verint atau mitra). Teks diindeks untuk pencarian kata kunci. Operator bisa mencari: "bom", "serangan", "nama_target", dll., dan langsung melompat ke rekaman audio pada detik yang relevan.

### Location Tracking & Geofencing

Dari data seluler (cell ID, LAC, TAC, GPS dari handset), Verint bisa:
- Melacak pergerakan target dalam periode waktu.
- Membuat geofence (alert jika target masuk/keluar area tertentu).
- Menganalisis pola pergerakan (pattern-of-life).

### Data Fusion

Verint Fusion menggabungkan data COMINT dengan:
- **HUMINT**: Laporan agen lapangan.
- **OSINT**: Data dari media sosial, berita, web scraping.
- **FININT**: Transaksi keuangan mencurigakan.
- **Biometric**: Face recognition, voice ID, fingerprint.

Hasilnya adalah **"single pane of glass"** — satu antarmuka untuk melihat semua intelijen tentang target.

---

## 🕵️‍♂️ Verint dalam Snowden Leaks

Dokumen Snowden (2013) mengungkapkan hubungan erat Verint dengan NSA:

- **Verint adalah kontraktor utama** untuk program pengawasan NSA, termasuk PRISM dan UPSTREAM. Verint menyediakan hardware probe (disebut "Narus" box) untuk intersep IP backbone.
- **Verint STAR GATE**: Program untuk intersep komunikasi satelit, terungkap dalam slide NSA.
- **Verint Vantage**: Platform analytics yang digunakan oleh NSA dan sekutunya.
- **Koneksi Israel**: Verint didirikan oleh veteran Unit 8200 Israel. Banyak teknologi COMINT Verint berasal dari teknik yang dikembangkan oleh intelijen Israel. Ada kekhawatiran bahwa data yang dikumpulkan oleh Verint di suatu negara bisa diakses oleh Israel.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Law Enforcement         Intelijen Militer         Rezim Otoriter
(dengan warrant)        │                         │
│                       Kontra-terorisme,         Pengawasan massal
Investigasi             pengawasan musuh          terhadap warga
kriminal: narkoba,      asing                    sendiri, oposisi,
korupsi, terorisme      │                         jurnalis
│                       │                         │
│                       │                         ▼
▼                       ▼                         Pelanggaran HAM,
Pengadilan              Operasi ofensif           penangkapan
(bukti sah)             (targeted killing,        sewenang-wenang
                        drone strike)             
```

Verint, seperti semua alat SIGINT, sangat bergantung pada pengawasan dan kerangka hukum negara pengguna. Tanpa regulasi yang ketat, platform ini menjadi alat represi massal.

---

## 🛡️ Countermeasures & Pertahanan Terhadap Intersepsi Level Negara

| Lapisan | Tindakan |
|---------|----------|
| **Komunikasi** | Gunakan **E2EE** (Signal, WhatsApp, iMessage). Verint tidak bisa mendekripsi konten E2EE meskipun bisa mengumpulkan metadata. |
| **Metadata** | Gunakan **Tor** atau **VPN berlapis** untuk menyembunyikan IP. Gunakan nomor telepon burner yang tidak terkait identitas asli. |
| **Voice** | Gunakan **VoIP dengan E2EE** (Signal voice call, FaceTime Audio). Hindari PSTN/GSM untuk percakapan sensitif. |
| **Lokasi** | Matikan GPS dan layanan lokasi. Gunakan Faraday bag untuk memblokir sinyal seluler. |
| **Pola** | Hindari pola komunikasi yang bisa diprediksi. Jangan gunakan perangkat yang sama untuk kehidupan pribadi dan aktivitas sensitif. |
| **Deteksi** | Monitor SS7/Diameter: beberapa operator menyediakan alert jika ada permintaan lokasi mencurigakan. |

---

## 🔗 Koneksi dalam Vault

- [[prism]] — Verint adalah vendor yang membangun infrastruktur teknis untuk program PRISM (koleksi data langsung dari server perusahaan teknologi).
- [[upstream-and-tempora]] — Verint menyediakan probe DPI untuk intersep backbone internet (UPSTREAM/TEMPORA).
- [[xkeyscore]] — Verint Vantage adalah salah satu analytics engine yang digunakan oleh XKEYSCORE.
- [[pegasus]] — Pegasus adalah spyware individu; Verint adalah platform pengawasan massal. Mereka bisa saling melengkapi: Verint menemukan target, Pegasus menginfeksi.
- [[maltego]] — Verint melakukan link analysis serupa dengan Maltego, tetapi dengan data rahasia dan skala masif.

---

## 📚 Referensi

- Snowden, E. (2013). *NSA Documents: PRISM, UPSTREAM, XKEYSCORE* (The Guardian, Washington Post).
- Citizen Lab, *Verint: The Surveillance Company Behind the World's Most Repressive Regimes* (2018).
- EFF, *Verint and the Surveillance Industry* (2017).
- Verint Systems, *Communications Intelligence Solutions* (materi pemasaran publik, 2020-2024).
- MITRE ATT&CK: T1595 (Active Scanning), T1592 (Gather Victim Host Information).

---

*Verint Deep Dive | Communications Intelligence Platform | SIGINT Interception & Analysis*