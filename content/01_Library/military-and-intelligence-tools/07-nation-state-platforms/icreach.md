---
title: Icreach
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
> ICREACH adalah sistem pencarian metadata telepon NSA yang diungkap oleh Edward Snowden pada 2014 melalui The Intercept. Seluruh informasi berasal dari dokumen bocor Snowden, laporan jurnalistik, dan dokumen pengadilan yang dideklasifikasi. Pembahasan ini murni **edukasional dan defensif**. Tujuannya agar pembaca memahami skala pengumpulan metadata global dan dapat mengambil langkah perlindungan privasi.

## 🧬 Apa Itu ICREACH?

ICREACH adalah **mesin pencari metadata komunikasi** (telepon, SMS, dan kemudian internet) yang dibangun NSA untuk diakses oleh ribuan analis dari NSA dan mitra Five Eyes. Jika XKEYSCORE adalah "Google untuk konten internet", ICREACH adalah **"Google untuk metadata teleponi global"**. ICREACH menyimpan **triliunan record metadata** — siapa menelepon siapa, kapan, berapa lama — dari seluruh dunia.

Snowden menyebut ICREACH sebagai "the first time we've seen a single database that allows access to the metadata of every call made in the world." Sistem ini dirancang agar analis dari berbagai badan intelijen (NSA, FBI, CIA, DEA, GCHQ, dan lainnya) dapat mencari dan berbagi metadata tanpa harus meminta akses ke database masing-masing badan.

### Metadata vs Content

|                        | Metadata                                                             | Content                            |
| ---------------------- | -------------------------------------------------------------------- | ---------------------------------- |
| **Definisi**           | Data tentang komunikasi: siapa, kapan, berapa lama, dari mana        | Isi komunikasi: suara, teks, pesan |
| **Contoh**             | Nomor penelepon, nomor penerima, durasi panggilan, lokasi cell tower | Rekaman audio panggilan, isi SMS   |
| **Perlindungan Hukum** | (Di AS) Tidak dilindungi Fourth Amendment (Smith v. Maryland, 1979)  | Dilindungi, butuh warrant          |
| **Volume**             | Sangat kecil (beberapa KB per record)                                | Sangat besar (MB-GB per panggilan) |
| **Disimpan di**        | ICREACH, MARINA, MAINWAY                                             | Pinwale, Trafficthief              |

---

## 🏗️ Arsitektur ICREACH

ICREACH adalah sistem **terpusat secara logis** tetapi **terdistribusi secara fisik** di seluruh instalasi NSA dan Five Eyes.

text

┌──────────────────────────────────────────────────────────────┐
│ Sumber Metadata │
│ [CDR dari operator telekomunikasi] [SS7 intercept] │
│ [Diameter intercept] [PRISM metadata] [UPSTREAM metadata] │
│ [MARINA (internet metadata)] [MAINWAY (telepon metadata)] │
└───────────────────────────┬──────────────────────────────────┘
│
▼
┌──────────────────────────────────────────────────────────────┐
│ ICREACH Ingest & Processing │
│ - Normalisasi format (berbagai format CDR → standar) │
│ - Entity resolution (siapa itu siapa) │
│ - Indeks: nomor telepon, IMSI, IMEI, IP, email, timestamp │
│ - Enrichment: lokasi (cell tower), geocoding │
└───────────────────────────┬──────────────────────────────────┘
│
▼
┌──────────────────────────────────────────────────────────────┐
│ ICREACH Query Engine │
│ - Full-text search di metadata │
│ - Contact chaining (hingga 3 hop) │
│ - Link analysis: graf panggilan │
│ - Alerting: notifikasi jika target muncul │
└───────────────────────────┬──────────────────────────────────┘
│ (Web GUI, API)
▼
┌──────────────────────────────────────────────────────────────┐
│ Analis (NSA, FBI, CIA, DEA, GCHQ, dll.) │
│ - > 1.000 analis memiliki akses (per 2013) │
│ - Clearance: TOP SECRET // SI // NOFORN (awalnya) │
│ - Kemudian diperluas ke Five Eyes + mitra domestik │
└──────────────────────────────────────────────────────────────┘

---

## 📊 Jenis Metadata yang Disimpan

| Jenis Metadata          | Detail                                                                                                           |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Telepon**             | Nomor penelepon (A-party), nomor penerima (B-party), timestamp mulai, durasi, IMSI, IMEI, cell tower ID (lokasi) |
| **SMS**                 | Nomor pengirim, nomor penerima, timestamp                                                                        |
| **Internet (metadata)** | Source/destination IP, port, domain, timestamp, durasi sesi, volume data                                         |
| **Email (metadata)**    | From, To, CC, BCC, Subject (tergantung), timestamp, IP pengirim                                                  |
| **VoIP**                | Username, IP, timestamp, durasi panggilan                                                                        |
| **Lokasi**              | Cell tower, LAC/TAC, koordinat GPS (dari handset), Wi-Fi access point                                            |

---

## 🔍 Cara Kerja: Contact Chaining & Social Network Analysis

Fitur paling kuat ICREACH adalah **contact chaining** — kemampuan untuk melihat jaringan sosial target hingga beberapa tingkat (hop).

### Contoh: 3-Hop Contact Chaining

text

Target: Nomor Telepon A
Hop 1: Semua nomor yang pernah dihubungi A dalam periode X
(Misal: 50 nomor)

Hop 2: Semua nomor yang pernah dihubungi 50 nomor tersebut
(Misal: 2.500 nomor)

Hop 3: Semua nomor yang pernah dihubungi 2.500 nomor tersebut
(Misal: 125.000 nomor)

Dengan 3 hop, dari 1 target, ICREACH bisa menghasilkan **ratusan ribu nomor** yang terhubung dalam jaringan sosial target. Ini digunakan untuk:

- Menemukan konspirator yang tidak diketahui.

- Mengidentifikasi struktur sel teroris (siapa menghubungi siapa).

- Menemukan "broker" yang menghubungkan sel berbeda.

### Chain of Communication Analysis

Analis juga bisa melihat:

- **Frekuensi**: Seberapa sering dua nomor berkomunikasi.

- **Durasi**: Berapa lama panggilan berlangsung.

- **Pola**: Panggilan singkat sebelum kejadian? Panggilan panjang di malam hari?

- **Perubahan**: Tiba-tiba berhenti berkomunikasi? Tiba-tiba muncul nomor baru?

---

## 📈 Skala & Cakupan

Dokumen Snowden mengungkapkan:

| Metrik                      | Angka                                         |
| --------------------------- | --------------------------------------------- |
| **Total record metadata**   | > 1 triliun (per 2013)                        |
| **Record baru per hari**    | > 1 miliar                                    |
| **Target yang bisa dicari** | Nomor telepon, IMSI, IMEI, email, IP, cookies |
| **Hop analysis**            | Hingga 3 hop (dapat diperluas)                |
| **Analis dengan akses**     | > 1.000 (NSA, FBI, CIA, DEA, GCHQ, dll.)      |
| **Retensi data**            | 5-10 tahun (metadata)                         |

---

## ⚖️ Isu Hukum & Privasi

### 1. Smith v. Maryland (1979)

Landasan hukum AS untuk pengumpulan metadata adalah **Smith v. Maryland**, di mana Mahkamah Agung memutuskan bahwa metadata telepon (nomor yang dihubungi) **tidak dilindungi** oleh Fourth Amendment karena diberikan secara sukarela ke pihak ketiga (perusahaan telepon). Doktrin ini disebut **Third-Party Doctrine**.

### 2. USA PATRIOT Act (Section 215)

Hingga 2015, NSA mengumpulkan metadata telepon domestik AS secara massal di bawah Section 215 USA PATRIOT Act. Program ini diungkap oleh Snowden dan kemudian dinyatakan ilegal oleh pengadilan. USA FREEDOM Act (2015) mengakhiri pengumpulan massal domestik dan memindahkan penyimpanan ke operator telekomunikasi, dengan NSA harus meminta data spesifik via warrant.

### 3. Metadata Bukan "Hanya Metadata"

Kritikus berpendapat bahwa metadata **sangat mengungkapkan**:

- Nomor yang dihubungi mengungkapkan asosiasi (dokter = masalah kesehatan, pengacara = masalah hukum, teroris = afiliasi).

- Pola panggilan mengungkapkan rutinitas, hubungan intim, dan aktivitas.

- Lokasi cell tower mengungkapkan pergerakan fisik.

- Metadata bisa digunakan untuk membangun profil yang sangat rinci tanpa perlu konten.

---

## 🛡️ Countermeasures

| Lapisan               | Tindakan                                                                                                                          |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Telepon**           | Gunakan **nomor burner** (prabayar, tidak terdaftar). Rotasi secara berkala. Hindari menelepon nomor yang terkait identitas asli. |
| **Panggilan**         | Gunakan **VoIP dengan E2EE** (Signal voice, FaceTime Audio) daripada PSTN/GSM.                                                    |
| **Lokasi**            | Matikan GPS dan layanan lokasi saat tidak diperlukan. Gunakan Faraday bag untuk memblokir sinyal.                                 |
| **Pola**              | Hindari pola panggilan yang bisa diprediksi. Jangan hubungi nomor yang sama dari nomor burner yang berbeda.                       |
| **Metadata Internet** | Gunakan **Tor** atau **VPN** untuk menyembunyikan IP asli.                                                                        |
| **Advokasi**          | Dukung reformasi Third-Party Doctrine dan pengumpulan metadata massal.                                                            |

---

## 🔗 Koneksi dalam Vault

- [[xkeyscore]] — ICREACH adalah padanan XKS untuk metadata telepon; XKS untuk konten internet.

- [[prism]] / [[upstream-and-tempora]] — Sumber metadata yang masuk ke ICREACH.

- [[verint]] — Verint menghasilkan data CDR dari intersepsi mobile; data ini bisa dimasukkan ke ICREACH.

- [[palantir-gotham]] — ICREACH dapat menjadi sumber data untuk Palantir; Palantir menyediakan analisis lanjutan.

- [[maltego]] — ICREACH melakukan link analysis serupa dengan Maltego tetapi pada skala global dengan data rahasia.

---

## 📚 Referensi

- Gallagher, R. (2014). _The Surveillance Engine: How the NSA Built Its Own Secret Google_. The Intercept.

- Snowden, E. (2019). _Permanent Record_. Metropolitan Books.

- Smith v. Maryland, 442 U.S. 735 (1979).

- USA FREEDOM Act (2015).

- EFF. _Metadata: How Your Phone Data Reveals Everything_.

---

_ICREACH Deep Dive | NSA Global Metadata Search Engine | Telephony Surveillance & Social Network Analysis_
