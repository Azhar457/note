---
tags:
  - palantir
  - gotham
  - data-fusion
  - intelligence
  - analytics
aliases:
  - Palantir Gotham
  - Palantir Technologies
  - Palantir Platform
created: 2026-06-27
status: operational
cssclasses:
  - wide-table
---

> [!warning] Konteks Etis & Legal
> Palantir Technologies adalah perusahaan perangkat lunak Amerika yang menyediakan platform analisis data untuk badan intelijen, militer, dan penegak hukum. Seluruh informasi di bawah berasal dari dokumentasi publik, paten, presentasi investor, serta laporan investigasi oleh jurnalis dan organisasi hak asasi manusia. Pembahasan ini murni **edukasional dan defensif**. Tujuannya agar pembaca memahami bagaimana data fusion bekerja pada skala negara dan bagaimana privasi individu dapat terpengaruh.

---

## 🧬 Apa Itu Palantir Gotham?

Palantir Gotham adalah **platform data fusion dan analisis** yang dirancang untuk mengintegrasikan data dari ribuan sumber berbeda — SIGINT, HUMINT, OSINT, GEOINT, FININT, dokumen, gambar, video, log — ke dalam satu antarmuka terpadu. Platform ini awalnya dikembangkan dengan pendanaan dari CIA melalui In-Q-Tel untuk membantu analis intelijen "menghubungkan titik-titik" (connect the dots) setelah kegagalan intelijen 9/11.

Berbeda dengan alat sebelumnya di vault yang bersifat spesifik (XKEYSCORE untuk pencarian metadata internet, Pegasus untuk spyware mobile), Palantir adalah **meta-tool** — ia tidak mengumpulkan data sendiri, tetapi mengintegrasikan data dari semua sumber dan menyediakan alat analisis canggih di atasnya. Jika XKEYSCORE adalah "Google-nya NSA", Palantir adalah "Photoshop-nya data intelijen".

### Palantir Gotham vs Foundry vs Apollo

| Produk      | Fokus                             | Pengguna Utama                                           |
| ----------- | --------------------------------- | -------------------------------------------------------- |
| **Gotham**  | Intelijen, militer, penegak hukum | CIA, NSA, FBI, DHS, ICE, DoD, kepolisian, Angkatan Darat |
| **Foundry** | Bisnis, supply chain, keuangan    | Airbus, Ferrari, BP, NHS, bank                           |
| **Apollo**  | Manajemen infrastruktur software  | Internal & pelanggan Palantir                            |

---

## 🏗️ Arsitektur Data Fusion

Palantir Gotham dibangun di atas filosofi **"semantic data integration"** — semua data, apa pun formatnya, dikonversi menjadi **objek** (entities) dan **hubungan** (relationships) dalam model data dinamis.

### Arsitektur Inti

```
┌──────────────────────────────────────────────────────────────┐
│                      Sumber Data                              │
│  [SIGINT] [HUMINT] [OSINT] [GEOINT] [FININT] [DOC] [IMG]    │
│  [Database] [Spreadsheet] [Email] [API] [Log Files] [PDF]    │
└───────────────────────────┬──────────────────────────────────┘
                            │ (Ingestion Pipeline)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              Palantir Gotham Data Integration                 │
│  - Dynamic Ontology: objek (Person, Place, Event, Document)   │
│  - Graph Database: hubungan antar semua objek                 │
│  - Real-time & Batch Ingestion                               │
│  - Data versioning, provenance, audit trail                  │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              Palantir Applications                            │
│  [Browser] [Map] [Graph] [Timeline] [Table] [Search]         │
│  [Object Explorer] [Link Analysis] [Data Fusion View]         │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              Operator / Analyst Workstation                   │
│  - Full-text search di semua data                            │
│  - Graph visualization: jaringan, hubungan                    │
│  - Geospatial analysis: peta interaktif                      │
│  - Timeline: kronologi event                                 │
│  - Collaboration: berbagi temuan, anotasi, presentasi         │
└──────────────────────────────────────────────────────────────┘
```

### Dynamic Ontology

Ini adalah jantung Palantir. Alih-alih skema database kaku (tabel, kolom), Palantir menggunakan **dynamic ontology** di mana:

- **Objek** (Entities): Representasi dari hal nyata — orang, tempat, acara, dokumen, nomor telepon, kendaraan, transaksi, dll.
- **Properti** (Properties): Atribut objek — nama, tanggal lahir, lokasi, nomor seri, dll.
- **Hubungan** (Relationships/Links): Koneksi antar objek — "menelepon", "bertemu", "memiliki", "terjadi pada", dll.
- **Aturan** (Rules): Validasi, inferensi, dan alerting otomatis.

Ontologi ini **dinamis** — analis dapat menambah jenis objek dan hubungan baru tanpa mengubah skema database. Data dari sumber berbeda otomatis dipetakan ke ontologi.

---

## 🔬 Modul & Aplikasi Utama

### 1. Browser

Antarmuka utama untuk mencari dan menjelajahi data. Mirip dengan file explorer, tetapi untuk objek intelijen. Analis dapat:

- Mencari objek dengan full-text search.
- Melihat semua properti objek.
- Melihat semua hubungan objek (grafik mini).
- Melihat histori perubahan dan provenance data.

### 2. Graph (Link Analysis)

Aplikasi visualisasi graf untuk analisis jaringan. Kemampuan:

- Menampilkan jaringan sosial, komunikasi, keuangan.
- Filter, zoom, dan navigasi graf besar.
- Menghitung centrality, shortest path, community detection.
- Menganimasikan evolusi jaringan dari waktu ke waktu.
- Mendeteksi broker, hubs, dan anomali.

### 3. Map (Geospatial Analysis)

Aplikasi peta untuk analisis lokasi:

- Plot objek di peta (alamat, koordinat GPS, cell tower).
- Heatmap, density analysis.
- Geofencing & alerting.
- Rekonstruksi rute perjalanan.
- Integrasi dengan imagery satelit.

### 4. Timeline (Temporal Analysis)

Aplikasi kronologi untuk menganalisis urutan kejadian:

- Menampilkan objek dan event di timeline.
- Menganimasikan sequence.
- Mendeteksi pola temporal (misal: panggilan selalu terjadi sebelum jam 6 pagi).
- Identifikasi gap atau anomali.

### 5. Object Explorer

"Profile view" untuk objek tertentu — menampilkan semua yang diketahui tentang satu entitas:

- Semua properti.
- Semua hubungan ke objek lain.
- Semua dokumen/email yang terkait.
- Timeline aktivitas.
- Histori perubahan data.

### 6. Search & Discovery

Palantir mengindeks **semua** data (teks, metadata, anotasi) dan mendukung:

- Full-text search dengan boolean, fuzzy, proximity.
- Search by example (temukan objek mirip dengan ini).
- Search across sources (mencari di semua database yang terintegrasi sekaligus).

### 7. Collaboration & Presentation

Analis dapat:

- Membuat **investigative pathway**: urutan langkah analisis yang bisa direproduksi.
- Anotasi dan tagging.
- Membuat slide presentasi langsung dari data (dengan grafik yang bisa di-klik untuk drill-down).
- Berbagi temuan dengan tim, dengan kontrol akses granular.

---

## 🔄 Data Ingestion: Bagaimana Data Masuk

Palantir dapat mengintegrasikan hampir semua jenis data:

| Jenis Data               | Metode Ingestion                                      |
| ------------------------ | ----------------------------------------------------- |
| **Database relasional**  | JDBC connector: Oracle, SQL Server, PostgreSQL, MySQL |
| **Data streaming**       | Kafka, Kinesis, TCP/UDP feed real-time                |
| **File**                 | CSV, JSON, XML, Excel, PDF, Word, image, video        |
| **API**                  | REST, SOAP, GraphQL                                   |
| **HDFS / Cloud Storage** | Hadoop, S3, Azure Blob                                |
| **Email**                | PST, MBOX, Exchange                                   |
| **Log**                  | Syslog, Windows Event Log, custom format              |
| **Telephony**            | CDR (Call Detail Records), tower dumps                |

Pipeline ingestion memungkinkan:

- **Transformasi data** (normalisasi, parsing, enrichment).
- **Entity resolution**: Menggabungkan data tentang entitas yang sama dari sumber berbeda (misal: "John Doe" di database A = "jdoe@email.com" di database B).
- **Provenance tracking**: Setiap potongan data memiliki metadata tentang sumbernya (origin, timestamp, reliability rating).

---

## 🕵️‍♂️ Use Case Intelijen & Militer

### 1. Target Network Analysis

- Integrasi SIGINT (panggilan, email), HUMINT (laporan lapangan), OSINT (media sosial), dan FININT (transaksi).
- Membangun graf jaringan teroris/kriminal.
- Mengidentifikasi pemimpin, pendanaan, dan metode operasi.
- Simulasi dampak jika node tertentu dihapus ("what if").

### 2. Pattern-of-Life Analysis

- Mengumpulkan data lokasi (GPS, cell tower, Wi-Fi) selama berbulan-bulan.
- Membangun profil rutinitas target.
- Mendeteksi anomali (perubahan rutinitas sebelum kejadian).

### 3. Predictive Policing & Threat Assessment

- Menganalisis data kejahatan historis.
- Membangun model prediktif untuk "hot spots" dan individu berisiko tinggi.
- **Kontroversial**: Dianggap bias dan diskriminatif oleh banyak peneliti.

### 4. Battlefield Management

- Integrasi drone feed, laporan pasukan, SIGINT, GEOINT.
- Menampilkan situasi real-time di peta.
- Koordinasi serangan dan menghindari friendly fire.

### 5. Counterintelligence

- Mendeteksi insider threat.
- Menganalisis akses data dan pola komunikasi.
- Anomaly detection untuk aktivitas mencurigakan.

---

## 📊 Kasus Terkenal & Kontroversi

### Kasus 1: Perburuan Osama bin Laden

Palantir disebut-sebut (meskipun tidak dikonfirmasi resmi) digunakan dalam operasi yang mengarah pada pembunuhan Osama bin Laden pada 2011. Platform ini membantu analis mengintegrasikan data dari berbagai sumber — termasuk laporan informan, data telepon, dan imagery satelit — untuk membangun gambaran lengkap tentang jaringan bin Laden dan lokasi persembunyiannya.

### Kasus 2: LAPD & Predictive Policing

Palantir Gotham digunakan oleh Los Angeles Police Department (LAPD) untuk analisis kejahatan dan predictive policing. Kritikus menuduh bahwa sistem ini:

- Memperkuat bias rasial dalam kepolisian.
- Menarget komunitas minoritas secara tidak proporsional.
- Mengumpulkan data tanpa pengawasan yang memadai.

### Kasus 3: ICE & Deportasi

Palantir menyediakan platform untuk U.S. Immigration and Customs Enforcement (ICE) yang digunakan untuk:

- Melacak imigran tidak berdokumen.
- Mengintegrasikan data dari berbagai sumber (DMV, utilitas, media sosial) untuk menemukan target deportasi.
- Menuai protes dari karyawan Palantir sendiri dan organisasi HAM.

### Kasus 4: NHS & Data Privacy (UK)

Selama pandemi COVID-19, Palantir Foundry digunakan oleh NHS (National Health Service) untuk mengelola data pasien. Ini menuai kritik tentang privasi data kesehatan dan kurangnya transparansi.

---

## 🛡️ Countermeasures & Pertahanan

| Lapisan                  | Tindakan                                                                                                   |
| ------------------------ | ---------------------------------------------------------------------------------------------------------- |
| **Data Minimization**    | Kurangi jejak digital: batasi data yang dibagikan ke platform online, gunakan alat privasi.                |
| **Compartmentalization** | Pisahkan identitas digital — akun terpisah untuk kehidupan normal dan aktivitas sensitif.                  |
| **Metadata Awareness**   | Sadari bahwa metadata (siapa, kapan, di mana) saja sudah sangat informatif bagi platform seperti Palantir. |
| **E2EE**                 | Gunakan enkripsi end-to-end agar konten komunikasi tidak bisa diintegrasikan.                              |
| **Advokasi**             | Dukung regulasi pengawasan, transparansi algoritmik, dan akuntabilitas penggunaan platform data fusion.    |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Kontra-terorisme          Intelijen & Militer       Pengawasan Massal
│                         │                         │
Menganalisis              Memetakan jaringan        Melacak dan
jaringan teroris,         musuh asing,              memprofilkan warga
mencegah serangan         mendukung operasi         tanpa pengawasan
│                         militer                   hukum yang memadai
│                         │                         │
│                         │                         ▼
▼                         ▼                         Predictive policing
Keamanan nasional         Operasi kontra-           yang bias, deportasi
(legitimate,              terorisme                 massal, pelanggaran
dengan pengawasan)        (kontroversial)           privasi
```

Palantir adalah alat netral yang potensinya untuk kebaikan (menemukan teroris, mengoordinasikan bantuan bencana) sama besarnya dengan potensi penyalahgunaannya (pengawasan massal, profiling diskriminatif).

---

## 🔗 Koneksi dalam Vault

- [[XKEYSCORE]] — XKS adalah sumber data SIGINT yang dapat diintegrasikan ke Palantir untuk data fusion.
- [[PRISM]] / [[UPSTREAM & TEMPORA]] — Data dari program ini dapat diimpor ke Palantir untuk analisis lebih lanjut.
- [[Verint]] — Verint menyediakan data COMINT; Palantir menyediakan platform analisis di atasnya.
- [[Maltego]] — Maltego adalah versi ringan dan sipil dari Palantir Graph. Keduanya melakukan link analysis, tetapi Palantir pada skala enterprise dengan data rahasia.
- [[Pegasus]] / [[FinSpy]] — Data dari spyware dapat diintegrasikan ke Palantir untuk analisis.
- [[Shodan]] — Data OSINT dari Shodan dapat diimpor ke Palantir.

---

## 📚 Referensi

- Palantir Technologies. _Gotham Platform Overview & Documentation_ (2023-2024).
- Greenberg, A. (2019). _Palantir: The Secretive Tech Company That's Powering the Global Security State_. Wired.
- Waldman, P. (2020). _Palantir Knows Everything About You_. Bloomberg.
- EFF. _Palantir and the Surveillance State_ (2019).
- MITRE ATT&CK: T1591 (Gather Victim Org Information), T1590 (Gather Victim Network Information).

---

_Palantir Gotham Deep Dive | Intelligence Data Fusion & Analysis Platform | Dual-Use Analytics_
