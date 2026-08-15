---
title: Muscular
tags:
- 07-nation-state-platforms
- library
- military-and-intelligence-tools
created: '2026-06-28'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  

---

> [!warning] Konteks Etis & Legal
> MUSCULAR adalah program intersepsi internal data center yang dioperasikan bersama oleh NSA dan GCHQ, diungkap oleh Edward Snowden pada 2013. Informasi di bawah berasal dari dokumen Snowden (dipublikasikan Washington Post, The Guardian), analisis forensik oleh peneliti keamanan, serta laporan perusahaan yang terdampak. Pembahasan ini murni **edukasional dan defensif**. Tujuannya: memahami ancaman intersepsi cloud dan memperkuat pertahanan data.

---

## 🧬 Apa Itu MUSCULAR?

MUSCULAR adalah **program intersepsi internal data center** yang dioperasikan oleh NSA dan GCHQ untuk mengakses data pengguna dari cloud provider besar — terutama **Google dan Yahoo**. Tidak seperti PRISM yang memperoleh data melalui proses legal (FISA), MUSCULAR dilakukan **tanpa sepengetahuan atau persetujuan perusahaan**.

MUSCULAR diungkap pada 30 Oktober 2013 melalui dokumen Snowden yang dipublikasikan Washington Post. Dokumen tersebut menunjukkan bahwa NSA dan GCHQ berhasil mengeksploitasi **link internal** yang menghubungkan data center Google dan Yahoo di luar Amerika Serikat — di mana data direplikasi dan disinkronkan antar data center.

### Perbandingan: PRISM vs MUSCULAR

| Aspek | PRISM | MUSCULAR |
|-------|-------|----------|
| **Metode** | Perusahaan diwajibkan memberikan data (FISA Section 702) | Intersepsi langsung pada kabel internal data center (tanpa sepengetahuan perusahaan) |
| **Legalitas (Klaim NSA)** | Legal di bawah FISA | Legal karena dilakukan di luar AS (EO 12333) |
| **Pengetahuan Perusahaan** | Ya (perusahaan comply) | Tidak (perusahaan tidak tahu) |
| **Titik Intersepsi** | Server perusahaan (data center AS) | Kabel fiber internal yang menghubungkan data center di luar AS |
| **Volume Data** | Tertarget (selector-based) | Massal (semua traffic yang lewat) |
| **Enkripsi** | Data diserahkan dalam bentuk plaintext | Traffic diintersep; jika ada enkripsi, harus dipecahkan |

---

## 🏗️ Arsitektur MUSCULAR

### Titik Intersepsi

Data center cloud besar (Google, Yahoo) memiliki puluhan fasilitas di seluruh dunia. Untuk memastikan data tetap tersedia dan cepat diakses, mereka mereplikasi data antar data center melalui **private fiber links**. Link ini membawa **semua data pengguna** — email, dokumen, foto, riwayat pencarian, dan metadata — dalam proses sinkronisasi.

NSA dan GCHQ menargetkan **link internal ini** di titik di mana mereka melintasi perbatasan internasional atau berada di wilayah yang dapat diakses secara fisik oleh GCHQ.

### Diagram Arsitektur

```
[Data Center Google - Eropa]
         │
         │ Private Fiber Link (replikasi data)
         │ (semua email, dokumen, metadata Google lewat sini)
         │
         ▼
    [TAP Point] ◄── GCHQ / NSA fiber splitter
         │
         │ (copy traffic ke server MUSCULAR)
         ▼
  [MUSCULAR Processing]
         │
         ├── DPI (Deep Packet Inspection)
         ├── Reassembly (TCP session reconstruction)
         ├── Decryption (jika SSL/TLS internal lemah)
         ├── Extraction (email, dokumen, metadata)
         └── Storage → XKEYSCORE / MARINA / MAINWAY
```

### Lokasi Intersepsi

Dokumen Snowden menyebutkan bahwa titik intersepsi berada di:
- **Data center Google di luar AS** — kemungkinan di Eropa (Irlandia, Belanda, Belgia) atau Asia.
- **Data center Yahoo di luar AS** — kemungkinan di Eropa.
- **Kabel fiber pribadi** yang menghubungkan data center — bukan kabel publik.

GCHQ memanfaatkan lokasi geografis Inggris sebagai titik pendaratan banyak kabel transatlantik — meskipun link ini adalah private fiber, mereka mungkin melintasi wilayah yang bisa dijangkau oleh operasi GCHQ.

---

## 🔬 Kemampuan Teknis

### 1. Volume Data yang Diintersep

Dokumen Snowden mengungkapkan volume luar biasa:

| Metrik | Angka (estimasi 2012-2013) |
|--------|---------------------------|
| **Data per hari** | 181 juta records (email, dokumen, metadata) |
| **Data dalam 30 hari** | > 5 miliar records |
| **Peak rate** | Puluhan gigabit per detik |
| **Format** | Email, chat, dokumen, foto, video, metadata |

### 2. Eksploitasi Enkripsi Internal

Google dan Yahoo menggunakan enkripsi untuk melindungi data pengguna — terutama setelah Snowden leaks. Namun, pada saat MUSCULAR aktif:

- **Link internal antar data center** sering menggunakan **SSL/TLS** atau enkripsi proprietary, tetapi tidak sekuat enkripsi yang digunakan untuk traffic publik.
- NSA/GCHQ diduga **memecahkan atau mem-bypass** enkripsi ini (kemungkinan dengan kunci yang dicuri, serangan man-in-the-middle, atau kerentanan protokol).
- Slide NSA yang bocor menunjukkan frustasi: "SSL added and removed here" — mengindikasikan bahwa di beberapa titik, traffic didekripsi untuk diproses.

### 3. Data yang Ditarget

Tidak seperti PRISM yang berbasis selector, MUSCULAR mengumpulkan **semua traffic** yang lewat. Data kemudian diproses untuk mengekstrak:

| Jenis Data | Detail |
|------------|--------|
| **Email** | From, To, Subject, Body, Attachments |
| **Google Drive / Docs** | Dokumen, spreadsheet, presentasi |
| **Google Photos** | Foto dan metadata EXIF |
| **Yahoo Mail** | Email, lampiran, kontak |
| **Google Chat / Hangouts** | Riwayat chat, kontak |
| **Metadata** | IP address, session cookies, device info, geolocation |

### 4. Integrasi dengan XKEYSCORE

Data yang dikumpulkan MUSCULAR dimasukkan ke **XKEYSCORE** — memungkinkan analis NSA dan GCHQ mencari data pengguna Google/Yahoo menggunakan selector seperti email, nama, atau kata kunci.

---

## 🕵️‍♂️ Reaksi Perusahaan

### Google

Google sangat marah atas pengungkapan MUSCULAR. Mereka:
- **Mempercepat enkripsi** pada semua link internal antar data center (sebelumnya beberapa link tidak dienkripsi).
- **Mengimplementasikan enkripsi end-to-end** untuk replikasi data (Google Cloud Encryption).
- Meningkatkan keamanan fisik data center di luar AS.
- Mempublikasikan laporan transparansi yang lebih detail.

### Yahoo

Yahoo juga:
- **Mengenkripsi semua traffic internal** antar data center.
- Memperketat akses fisik ke fasilitas mereka.

### Dampak Jangka Panjang

MUSCULAR adalah **wake-up call** bagi seluruh industri cloud. Setelah 2013, semua cloud provider besar (Google, Amazon, Microsoft) mengenkripsi **semua traffic internal** mereka — tidak hanya traffic publik. Ini menjadikan operasi seperti MUSCULAR jauh lebih sulit.

---

## 📊 Perbandingan dengan Program Intersepsi Lain

| Program | Target | Metode | Volume | Legal Basis |
|---------|--------|--------|--------|-------------|
| **PRISM** | Data di server perusahaan | Perusahaan comply (FISA) | Selector-based | Section 702 |
| **UPSTREAM** | Traffic backbone internet | Fiber TAP di IXP | Massal | EO 12333 |
| **TEMPORA** | Traffic backbone (UK) | Fiber TAP di pendaratan kabel | Massal | RIPA 2000 |
| **MUSCULAR** | Internal data center links | TAP pada private fiber | Massal | EO 12333 (klaim) |
| **INCENSER** | Kabel bawah laut | TAP pada kabel internasional | Massal | EO 12333 |

MUSCULAR unik karena menargetkan **internal infrastructure** perusahaan — bukan traffic publik, melainkan data yang sedang direplikasi antar data center sendiri.

---

## 🛡️ Countermeasures & Pertahanan

### 1. Enkripsi Internal

| Tindakan | Detail |
|----------|--------|
| **Encrypt All Internal Links** | Semua traffic antar data center harus dienkripsi (TLS 1.3, IPSec, atau kustom). |
| **End-to-End Encryption** | Data pengguna dienkripsi sebelum meninggalkan data center sumber, hanya didekripsi di data center tujuan. |
| **Quantum-Safe Encryption** | Persiapkan transisi ke PQC untuk melindungi data terhadap "harvest now, decrypt later". |

### 2. Keamanan Fisik

| Tindakan | Detail |
|----------|--------|
| **Physical Security** | Data center harus dilindungi dari akses fisik tidak sah. |
| **Fiber Monitoring** | Monitor integritas fiber untuk deteksi TAP fisik (optical time-domain reflectometer). |
| **Route Diversity** | Jangan bergantung pada satu rute fiber. |

### 3. Untuk Pengguna Cloud

| Lapisan | Tindakan |
|---------|----------|
| **E2EE** | Gunakan enkripsi end-to-end untuk data sebelum upload ke cloud (Cryptomator, Veracrypt, rclone crypt). |
| **Client-Side Encryption** | Gunakan layanan yang menyediakan client-side encryption (kunci hanya dipegang pengguna). |
| **Zero-Knowledge Providers** | Pilih provider yang tidak bisa mengakses data pengguna (Proton Drive, Tresorit, Sync.com). |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Intelijen Defensif         Kontra-Terorisme         Spionase Massal
│                         │                        │
Melindungi data center    Mencari komunikasi       Mengumpulkan data
dari intersepsi dengan    teroris di cloud         warga dunia tanpa
enkripsi internal         │                        batasan
│                         │                        │
│                         │                        ▼
▼                         ▼                        Pelanggaran privasi
Cloud security            Operasi sah              massal, tanpa
best practices            (kontroversial)          pengawasan hukum
```

MUSCULAR adalah contoh ekstrem dari **"collect it all" philosophy** NSA. Meskipun dilakukan di luar AS (dan karenanya "legal" di bawah EO 12333 menurut interpretasi NSA), tindakan mengintersep link internal data center tanpa sepengetahuan perusahaan adalah pelanggaran serius terhadap kedaulatan data dan privasi global.

---

## 🔗 Koneksi dalam Vault

- [[prism]] — PRISM adalah jalur legal; MUSCULAR adalah jalur rahasia. Keduanya mengumpulkan data dari perusahaan yang sama.
- [[upstream-and-tempora]] — MUSCULAR adalah "UPSTREAM untuk data center" — intersepsi backbone internal, bukan publik.
- [[xkeyscore]] — Data MUSCULAR diindeks dan dapat dicari via XKEYSCORE.
- [[quantum]] — QUANTUM bisa digunakan untuk mengalihkan traffic ke titik intersepsi MUSCULAR.
- [[foxacid]] — Jika MUSCULAR tidak bisa mendekripsi data, FOXACID bisa digunakan untuk menginfeksi target dan mencuri kunci enkripsi.
- [[verint]] — Verint menyediakan perangkat keras DPI untuk program seperti MUSCULAR.

---

## 📚 Referensi

- Gellman, B. & Soltani, A. (2013). *NSA Infiltrates Links to Yahoo, Google Data Centers Worldwide, Snowden Documents Say*. Washington Post.
- Greenwald, G. (2014). *No Place to Hide: Edward Snowden, the NSA, and the U.S. Surveillance State*. Metropolitan Books.
- Google. *Encrypting Data at Rest and in Transit* (2013-2024).
- MITRE ATT&CK: T1557 (Man-in-the-Middle), T1595 (Active Scanning).

---

*MUSCULAR Deep Dive | NSA/GCHQ Internal Data Center Interception | Private Fiber TAP & Cloud Data Collection*
---

audited
---
