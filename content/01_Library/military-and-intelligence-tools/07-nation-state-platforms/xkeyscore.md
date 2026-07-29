---
title: Xkeyscore
tags:
  - 07-nation-state-platforms
  - library
  - military-and-intelligence-tools
created: "2026-06-27"
updated: "2026-07-01"
status: pending
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> XKEYSCORE adalah sistem pencarian dan analisis data internet NSA yang diungkap oleh Edward Snowden pada 2013 melalui The Guardian. Seluruh informasi di bawah berasal dari dokumen bocor Snowden, slide presentasi NSA yang dipublikasikan, laporan jurnalistik, serta analisis oleh peneliti keamanan dan organisasi hak asasi manusia. Pembahasan ini murni **edukasional dan defensif**. Tujuannya agar pembaca memahami skala dan kemampuan pengawasan digital global serta dapat mengambil langkah-langkah untuk melindungi privasi mereka.

## 🧬 Apa Itu XKEYSCORE?

XKEYSCORE (XKS) adalah **"Google-nya NSA"** — sebuah sistem terdistribusi global yang memungkinkan analis intelijen mencari dan menganalisis data internet yang dikumpulkan dari berbagai program pengawasan (PRISM, UPSTREAM, TEMPORA, FAIRVIEW, dan lainnya). Jika PRISM adalah pipa pengumpulan data dan UPSTREAM adalah TAP pada backbone, XKEYSCORE adalah **mesin pencari** yang menyatukan semuanya.

Edward Snowden menggambarkan XKEYSCORE sebagai sistem di mana "saya bisa melihat siapa pun, di mana pun, kapan pun. Saya bisa membuka email Anda, password Anda, catatan telepon Anda, kartu kredit Anda, pesan teks Anda. Saya bisa melihat komunikasi Anda dengan akuntan Anda, pengacara Anda, dokter Anda. Dan saya bisa melakukan ini sambil duduk di meja saya."

### Posisi XKEYSCORE dalam Ekosistem NSA

```
[PRISM] ────┐
[UPSTREAM] ─┤
[TEMPORA] ──┼──► [MARINA / MAINWAY Database] ──► [XKEYSCORE Query Engine] ──► [Analyst Workstation]
[FAIRVIEW] ─┤
[BLARNEY] ──┘
```

XKEYSCORE tidak mengumpulkan data sendiri; ia adalah **query interface** dan **analytics engine** yang duduk di atas database raksasa NSA (MARINA untuk metadata internet, MAINWAY untuk metadata telepon, dan content repositories).

---

## 🏗️ Arsitektur XKEYSCORE

XKEYSCORE adalah sistem **terdistribusi global** dengan lebih dari 700 server (perkiraan dari dokumen Snowden) di instalasi NSA dan mitra Five Eyes di seluruh dunia.

### Komponen Sistem

| Komponen                         | Fungsi                                                                                                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **XKEYSCORE Nodes**              | Server di lokasi fisik yang menerima, memproses, dan mengindeks data dari sumber pengumpulan. Disebut "Narus box" atau "Boeing server" dalam dokumen Snowden. |
| **Deep Packet Inspection (DPI)** | Sebagian node XKS melakukan DPI pada traffic yang lewat (dari UPSTREAM) sebelum menyimpan.                                                                    |
| **Indexing Engine**              | Mengindeks semua metadata dan content yang diterima — email address, IP, phone number, keywords, file hash, cookie, MAC address, dll.                         |
| **Query Interface**              | Antarmuka web bagi analis NSA untuk mencari data. Mendukung query berbasis form dan query "free text" yang powerful.                                          |
| **Processing Rules**             | Aturan otomatis yang memproses data: filter, alerting, routing ke database lain.                                                                              |
| **MARINA / MAINWAY**             | Database backend yang menyimpan metadata internet (MARINA) dan metadata telepon (MAINWAY).                                                                    |
| **Trafficthief / Pinwale**       | Sistem penyimpanan content (isi komunikasi) yang dapat diakses melalui XKS.                                                                                   |

### Arsitektur Terdistribusi

```
[Internet Backbone TAP] ──► [XKS Node #1 - Virginia]
                              │
[Kabel Transatlantik TAP] ──► [XKS Node #2 - UK (GCHQ)]
                              │
[IXP TAP - California] ────► [XKS Node #3 - California]
                              │
[Data dari PRISM] ──────────► [XKS Central Processing]
                              │
                              ▼
                    [Global XKS Query Interface]
                    (Analis di mana pun bisa query
                     semua node secara transparan)
```

Setiap node XKS menyimpan data yang dikumpulkan di wilayah geografisnya. Namun, analis dengan clearance yang tepat dapat melakukan query lintas node, menciptakan cakupan global yang hampir tanpa celah.

---

## 🔍 Cara Kerja: Dari Query ke Data Target

### 1. Analis Memasukkan Query

Antarmuka XKS memungkinkan query berdasarkan **selector**:

| Jenis Selector        | Contoh                                           |
| --------------------- | ------------------------------------------------ |
| **Email address**     | `target@domain.com`                              |
| **Phone number**      | `+1-202-555-0123`                                |
| **IP address**        | `203.0.113.45`                                   |
| **Username / Handle** | `@target_user`                                   |
| **MAC address**       | `00:1A:2B:3C:4D:5E`                              |
| **Cookie value**      | `session_id=abc123def456`                        |
| **Full-text keyword** | `"bomb attack"`, `"nama_organisasi"`             |
| **File hash**         | MD5/SHA dari file yang diunggah                  |
| **Language**          | Semua email dalam bahasa Arab, Urdu, Farsi, dll. |
| **Location**          | Traffic dari/ke negara X, kota Y                 |

### 2. XKS Mencari di Database Terindeks

XKS mencari data di:

- **Metadata**: Header email, log panggilan, IP session, DNS query, HTTP request.
- **Content**: Body email, chat messages, file attachments (jika didekripsi), browsing history.
- **Derived data**: Hasil analisis otomatis (language detection, speaker ID, face recognition, sentiment).

### 3. Hasil Dikembalikan dalam Hitungan Detik

Analis menerima:

- Daftar semua komunikasi yang cocok (dengan metadata).
- Kemampuan untuk "drill down" ke konten penuh (jika tersedia dan clearance mencukupi).
- Grafik hubungan (link analysis) yang menunjukkan jaringan sosial target.

### 4. Analis Dapat Menyimpan, Menganalisis, dan Membagikan

- Menyimpan query sebagai "watch list" untuk alerting otomatis.
- Mengekspor data ke alat analisis lain (Palantir, Analyst Notebook).
- Membagikan temuan ke mitra Five Eyes.

---

## 📊 Contoh Query XKEYSCORE (dari Slide NSA yang Bocor)

Slide pelatihan NSA yang bocor menunjukkan beberapa contoh query:

**Contoh 1: Mencari Semua Aktivitas Target**

```
Query: email = "target@terrorist-group.com"
Date Range: Last 30 days
Result: Semua email yang dikirim/diterima, IP login, browsing history,
        file yang diunggah/download, VoIP calls, chat sessions.
```

**Contoh 2: Mencari Komunikasi tentang Target ("About" Collection)**

```
Query: fulltext = "target_name" AND language = "Arabic"
Date Range: Last 7 days
Result: Semua email/chat yang menyebut nama target, meskipun target
        bukan pengirim/penerima. (Praktik dihentikan 2017).
```

**Contoh 3: Mencari Berdasarkan Lokasi**

```
Query: country = "Iran" AND protocol = "SMTP"
Date Range: Last 24 hours
Result: Semua email yang melewati server di Iran.
```

**Contoh 4: Mencari Pengguna Tor / VPN**

```
Query: software = "Tor" OR "VPN" AND country = "US"
Result: Semua user yang terdeteksi menggunakan Tor/VPN di AS.
```

**Contoh 5: Mencari Dokumen Spesifik**

```
Query: filetype = "pdf" AND filehash = "a1b2c3d4e5f6..."
Result: Semua instance file PDF dengan hash spesifik yang dikirim/diunduh.
```

---

## 📈 Skala & Kapasitas

Dokumen Snowden mengungkapkan skala XKEYSCORE yang luar biasa:

| Metrik                    | Angka                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------- |
| **Total records indexed** | > 40 miliar (per 2012)                                                              |
| **New records per day**   | > 10 miliar (per 2012)                                                              |
| **Content buffer**        | 3-5 hari (full content), lebih lama untuk metadata                                  |
| **Nodes globally**        | > 700 server di 150+ lokasi                                                         |
| **Analis dengan akses**   | Ribuan (NSA, GCHQ, mitra Five Eyes)                                                 |
| **Data sources**          | PRISM, UPSTREAM, TEMPORA, FAIRVIEW, BLARNEY, OAKSTAR, STORMBREW, MUSCULAR, INCENSER |
| **Volume data per hari**  | Petabytes                                                                           |

---

## 🔬 Kemampuan Teknis: Lebih dari Sekadar Pencarian

### 1. AppID & Fingerprinting

XKS memiliki **application identification engine** yang bisa mengenali aplikasi spesifik dari traffic:

- **WhatsApp**: Dari signature protokol, domain, dan pola traffic.
- **Signal**: Dari TLS fingerprint dan pola koneksi.
- **Telegram**: Dari protokol MTProto.
- **Tor**: Dari TLS fingerprint dan koneksi ke direktori Tor.
- **BitTorrent**: Dari DHT dan peer protocol.
- **Game online**: World of Warcraft, Counter-Strike, dll.

Ini memungkinkan NSA memantau penggunaan aplikasi tertentu dan menarget penggunanya.

### 2. Language & Keyword Processing

XKS secara otomatis:

- Mendeteksi bahasa (Natural Language Processing).
- Mengekstrak kata kunci dan entitas (nama orang, tempat, organisasi).
- Menganalisis sentimen.
- Menerjemahkan (machine translation) jika diperlukan.

### 3. EXIF & Metadata Extraction

Semua file (foto, dokumen, PDF) yang melewati XKS diproses untuk mengekstrak:

- **EXIF data** dari foto (kamera, GPS, timestamp).
- **Document metadata** (author, revision history, printer).
- **PDF metadata** (creator, creation date).
- **Video/audio metadata** (codec, duration, device).

### 4. Anomaly Detection & Alerting

XKS dapat dikonfigurasi untuk alerting otomatis:

- Jika target spesifik muncul dalam komunikasi baru.
- Jika pola komunikasi menyimpang dari baseline (behavioral anomaly).
- Jika kata kunci tertentu (misal: "attack", "bomb") muncul dengan frekuensi tinggi di area geografis.

### 5. Network Graph & Social Network Analysis

XKS secara otomatis membangun **graf komunikasi**:

- Siapa menghubungi siapa.
- Seberapa sering.
- Pola komunikasi (siapa yang memulai, siapa yang merespons).
- Deteksi "broker" (orang yang menghubungkan grup berbeda).
- Deteksi perubahan pola (misal: dua orang yang biasanya tidak kontak tiba-tiba sering berkomunikasi sebelum kejadian).

---

## ⚠️ Kontroversi & Isu Hukum

### 1. "No Audit Trail yang Efektif"

Snowden mengungkapkan bahwa meskipun XKS secara teknis memiliki logging, pengawasan terhadap penggunaan analis sangat lemah. Seorang analis NSA dapat mencari data tentang siapa pun — termasuk warga AS, jurnalis, atau kekasih — tanpa terdeteksi. Ini dikenal sebagai **LOVEINT** (Love Intelligence) — penyalahgunaan untuk kepentingan pribadi.

### 2. "About" Collection (Dihentikan 2017)

Hingga 2017, XKS mendukung "about" collection: mencari komunikasi yang _membahas_ target, bukan hanya oleh/ke target. Ini berarti email antara dua orang tak bersalah bisa dikumpulkan jika mereka menyebut nama target. NSA menghentikan praktik ini pada 2017 karena kritik dan kesulitan teknis.

### 3. FISA & Executive Order 12333

XKS beroperasi di bawah dua otoritas:

- **FISA Section 702**: Untuk target non-US persons di luar AS (dengan "minimization" untuk US persons).
- **Executive Order 12333**: Untuk pengumpulan di luar AS tanpa warrant sama sekali (termasuk traffic internasional yang lewat backbone AS).

Kritikus menyebut ini sebagai **"pengawasan tanpa warrant"** yang melanggar Fourth Amendment (untuk US persons) dan hukum internasional (untuk warga negara lain).

### 4. Penyimpanan Data Warga Dunia

Karena internet bersifat global, traffic warga negara mana pun yang melewati titik intersepsi Five Eyes akan dikumpulkan. Ini menimbulkan pertanyaan kedaulatan data dan privasi global.

---

## 🛡️ Countermeasures & Pertahanan

| Lapisan                | Tindakan                                                                                                                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Enkripsi**           | Gunakan **E2EE** (Signal, WhatsApp, Telegram Secret Chat). XKS tidak bisa mencari isi komunikasi E2EE.                                                                |
| **Metadata**           | Gunakan **Tor** untuk browsing, **VPN** tanpa log untuk traffic umum. XKS masih bisa mengumpulkan metadata tapi tidak bisa mengaitkan ke identitas asli dengan mudah. |
| **Minimalkan Jejak**   | Hindari menggunakan nama asli, email pribadi, atau nomor telepon pribadi untuk aktivitas sensitif. Gunakan akun burner.                                               |
| **Pisahkan Identitas** | Jangan pernah login ke akun sensitif dari perangkat/jaringan yang sama dengan akun normal.                                                                            |
| **Hindari Pola**       | Jangan buat pola komunikasi yang bisa diprediksi. Variasikan waktu, perangkat, dan lokasi.                                                                            |
| **E2EE untuk Cloud**   | Enkripsi file sebelum upload ke cloud. Jangan gunakan backup tidak terenkripsi.                                                                                       |
| **Advokasi**           | Dukung reformasi pengawasan, transparansi, dan enkripsi kuat. Dukung organisasi seperti EFF, ACLU, Privacy International.                                             |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Kontra-terorisme          Intelijen Luar Negeri     Pengawasan Massal
│                         │                         │
Mencari komunikasi        Memata-matai              Mencari data warga
teroris, melacak          musuh asing,              dunia tanpa
jaringan sel tidur        diplomat,                 batasan, termasuk
│                         perusahaan asing           aktivis, jurnalis,
│                         │                         warga biasa
│                         │                         │
▼                         ▼                         ▼
Mencegah serangan         Keunggulan                Pelanggaran HAM
(Persetujuan luas)        kompetitif                global, chilling
                          (Kontroversial)           effect, penyalahgunaan
```

XKEYSCORE adalah puncak dari **"collect it all" philosophy** NSA. Kemampuannya yang luar biasa sebagai alat intelijen juga menjadikannya ancaman terbesar terhadap privasi global dalam sejarah digital.

---

## 🔗 Koneksi dalam Vault

- [[prism]] — PRISM adalah sumber data utama XKS untuk data dari perusahaan teknologi.
- [[upstream-and-tempora]] — UPSTREAM/TEMPORA adalah sumber data utama XKS untuk traffic backbone.
- [[verint]] — Verint menyediakan hardware DPI untuk node XKS.
- [[palantir-gotham]] — Data dari XKS dapat diekspor ke Palantir untuk analisis lebih lanjut dan data fusion.
- [[icreach]] — ICREACH adalah mesin pencari metadata telepon NSA; XKS adalah padanannya untuk internet.
- [[pegasus]] — Jika XKS tidak bisa mendekripsi, Pegasus bisa digunakan untuk menginfeksi perangkat target dan membaca data sebelum enkripsi.
- [[shodan]] — Tidak langsung, tetapi Shodan adalah "XKS versi sipil" — mesin pencari untuk perangkat yang terhubung internet.

---

## 📚 Referensi

- Greenwald, G. (2013). _XKeyscore: NSA Tool Collects 'Nearly Everything a User Does on the Internet'_ (The Guardian).
- Snowden, E. (2019). _Permanent Record_. Metropolitan Books.
- NSA. _XKEYSCORE Training Slides_ (dokumen Snowden, 2008-2012).
- PCLOB. _Report on the Section 702 Program_ (2014).
- EFF. _XKEYSCORE: NSA's Google for the World's Communications_.
- MITRE ATT&CK: T1595 (Active Scanning), T1592 (Gather Victim Host Information), T1591 (Gather Victim Org Information).

---

_XKEYSCORE Deep Dive | NSA Global Internet Search Engine | SIGINT Data Analysis Platform_
