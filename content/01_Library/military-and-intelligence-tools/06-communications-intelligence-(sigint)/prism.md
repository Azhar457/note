---
title: Prism
tags:
- 06-communications-intelligence-(sigint)
- library
- military-and-intelligence-tools
created: '2026-06-27'
updated: '2026-07-01'
status: pending
cssclasses: ''
---

> [!warning] Konteks Etis & Legal
> PRISM adalah program pengawasan elektronik National Security Agency (NSA) Amerika Serikat yang diungkap oleh Edward Snowden pada Juni 2013 melalui The Guardian dan Washington Post. Seluruh informasi di bawah berasal dari dokumen yang bocor, laporan jurnalistik, dokumen pengadilan FISC yang dideklasifikasi, dan pernyataan resmi pemerintah AS. Pembahasan ini murni **edukasional dan defensif**. Tujuannya agar pembaca memahami kemampuan pengawasan massal dan dapat mengambil langkah untuk melindungi privasi komunikasi mereka.

## 🧬 Apa Itu PRISM?

PRISM (Planning Tool for Resource Integration, Synchronization, and Management) adalah program NSA yang melakukan **pengumpulan data komunikasi internet langsung dari server perusahaan teknologi besar AS**. Program ini beroperasi di bawah otoritas **Section 702 of the Foreign Intelligence Surveillance Act (FISA Amendments Act of 2008)**, yang mengizinkan pengawasan terhadap non-US persons yang berada di luar Amerika Serikat.

PRISM bukanlah program intersepsi backbone seperti UPSTREAM. Ia adalah mekanisme legal-teknis di mana NSA mengirimkan **tasking/selector** (alamat email, nomor telepon, username, IP address) ke perusahaan teknologi, dan perusahaan tersebut **secara legal diwajibkan** untuk memberikan data komunikasi yang relevan — baik yang tersimpan (historical) maupun real-time.

### Perbedaan Fundamental: PRISM vs UPSTREAM

| Aspek | PRISM | UPSTREAM |
|-------|-------|----------|
| **Metode Pengumpulan** | Dari server perusahaan (Facebook, Google, Microsoft, dll.) | TAP fisik pada fiber optic backbone |
| **Cara Kerja** | NSA mengirim selector ke perusahaan; perusahaan mengirim balik data | NSA mengintersep langsung traffic yang lewat kabel fiber |
| **Jenis Data** | Email, chat, file, foto, video, VoIP, social media, stored data | Raw internet traffic, metadata, content yang lewat backbone |
| **Lokasi Target** | Data pengguna yang di-hosting oleh perusahaan AS | Traffic yang melintasi titik TAP fisik (AS dan internasional) |
| **Otoritas Hukum** | FISA Section 702 (wajibkan perusahaan) | Executive Order 12333 (intersep di luar AS tanpa warrant) |
| **Cakupan Target** | Hanya non-US persons di luar AS | Siapa saja yang traffic-nya lewat backbone yang dimonitor |
| **Keterlibatan Perusahaan** | ✅ Ya, perusahaan harus comply | ❌ Tidak, NSA mengintersep sendiri |

PRISM dan UPSTREAM saling melengkapi: PRISM untuk data yang tersimpan di server, UPSTREAM untuk traffic real-time yang lewat backbone.

---

## 🏗️ Arsitektur PRISM: Bagaimana Data Mengalir dari Perusahaan ke NSA

```
┌──────────────────────────────────────────────────────────────┐
│                    NSA / FBI / CIA                            │
│  (Analyst mengirimkan tasking/selector)                       │
│  - Selector: alamat email, username, nomor telepon, IP        │
│  - Tasking: "Berikan semua komunikasi selector ini"           │
└───────────────────────────┬──────────────────────────────────┘
                            │ (via FISA warrant / Section 702 certification)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              PRISM Processing Unit (NSA)                      │
│  - Menerjemahkan tasking ke format perusahaan                 │
│  - Mengelola koneksi teknis ke perusahaan                     │
│  - Menerima, memproses, dan menyimpan data                    │
└───────────────────────────┬──────────────────────────────────┘
                            │ (dedicated secure channels)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              Perusahaan Teknologi                              │
│  Microsoft │ Yahoo │ Google │ Facebook │ PalTalk │ YouTube   │
│  Skype │ AOL │ Apple │ Dropbox (kemudian)                      │
│  - Menerima tasking (selector + parameter)                   │
│  - Mencari data pengguna yang cocok di server mereka         │
│  - Mengirim data kembali via secure portal                    │
└───────────────────────────┬──────────────────────────────────┘
                            │ (data terenkripsi via VPN/dedicated line)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              NSA Data Repositories                            │
│  - Data disimpan di MARINA (metadata) & MAINWAY (content)     │
│  - Dapat dicari via XKEYSCORE, ICREACH                        │
│  - Dapat diakses oleh NSA, FBI, CIA (dengan batasan)          │
└──────────────────────────────────────────────────────────────┘
```

### Perusahaan yang Terlibat (Dokumen Snowden, 2012-2013)

| Perusahaan | Bergabung Sejak | Jenis Data Utama |
|------------|-----------------|------------------|
| **Microsoft** | 2007 | Hotmail/Outlook email, OneDrive files, Skype audio/video/chat |
| **Yahoo** | 2008 | Yahoo Mail, Yahoo Messenger, Flickr |
| **Google** | 2009 | Gmail, Google Drive, Google Voice, Hangouts, YouTube |
| **Facebook** | 2009 | Facebook messages, posts, photos, friend lists, events |
| **PalTalk** | 2009 | Voice chat, video, text messaging |
| **YouTube** | 2010 | Video uploads, comments, viewing history |
| **Skype** | 2011 | Audio calls, video calls, instant messaging |
| **AOL** | 2011 | AOL Mail, AIM instant messenger |
| **Apple** | 2012 | iCloud email, iMessage, FaceTime, iCloud backups (terbatas saat itu) |

Setelah Snowden leaks, beberapa perusahaan mengklaim telah memperkuat enkripsi dan menolak memberikan akses langsung. **Namun, kewajiban hukum Section 702 tetap ada**, dan perusahaan tetap diwajibkan memberikan data ketika menerima FISA order yang sah.

---

## 🔬 Data Apa yang Dikumpulkan?

### Metadata & Content

| Kategori | Contoh Data |
|----------|-------------|
| **Email** | To, From, CC, BCC, Subject, Body, Attachments (file, gambar), timestamp, IP address pengirim/penerima. |
| **Chat & IM** | Kontak, isi pesan, timestamp, durasi sesi, file yang dikirim. |
| **VoIP (Skype, dll.)** | Audio call, video call, call duration, participants, IP address. |
| **Social Media** | Posts, comments, photos, friend lists, profile info, private messages, events. |
| **File Storage** | File yang diunggah (Google Drive, OneDrive, Dropbox), metadata file. |
| **Login & Session** | IP address login, browser/device fingerprint, durasi sesi, lokasi. |
| **Search History** | (Tidak dikonfirmasi, tetapi mungkin via Google/Yahoo) |

### Selector (Tasking)

NSA dapat men-target data berdasarkan:
- **Email address**: `target@example.com`
- **Username / Account ID**: `target_user`
- **Phone number**: `+1-202-555-0123`
- **IP address**: `203.0.113.45`
- **Cookie / Device ID**: (kemungkinan)
- **MAC address**: (kemungkinan, via tracking)

Ketika satu selector masuk, PRISM mengumpulkan **semua data yang terkait**: email yang dikirim/diterima, chat history, file, foto, kontak, dan metadata. Tidak hanya untuk target, tetapi juga **"about" collection**: komunikasi yang *membahas* atau *menyebut* target, meskipun pengirim/penerima bukan target. (Praktik "about" collection dihentikan NSA pada 2017 setelah kritik luas).

---

## ⚖️ Kerangka Hukum: Section 702 FISA

PRISM beroperasi di bawah **Section 702 of the FISA Amendments Act (FAA)**:

1. **Target**: Hanya non-US persons yang berada di luar AS.
2. **Tujuan**: Foreign intelligence (kontra-terorisme, kontra-proliferasi, siber, dll.).
3. **Prosedur**: Attorney General dan Director of National Intelligence menyetujui **annual certifications** yang menentukan kategori target (misal: terorisme, proliferasi nuklir).
4. **Warrant**: Tidak ada warrant individual. NSA/FBI menentukan sendiri selector-nya, dengan pengawasan internal dan review oleh FISA Court (FISC).
5. **Minimization Procedures**: Data US persons yang tidak sengaja terkumpul harus "diminimalkan" (dibatasi akses dan penyimpanannya). Namun, laporan menunjukkan prosedur ini sering dilanggar atau tidak efektif.

### Kontroversi & Kritik

- **"Incidental Collection"**: Meskipun target adalah non-US person, komunikasi mereka dengan US persons ikut terkumpul. Data US persons ini sering tetap tersimpan.
- **"Backdoor Search"**: FBI dan NSA dapat mencari database PRISM untuk informasi tentang US persons tanpa warrant (disebut "backdoor search"). Praktik ini legal di AS hingga reformasi terbatas pada 2018.
- **Lack of Transparency**: Perusahaan dilarang mengungkapkan jumlah FISA order yang mereka terima hingga aturan dilonggarkan setelah Snowden leaks.

---

## 🔄 PRISM dalam Alur Kerja Intelijen NSA

1. **Identifikasi Target**: Analis intelijen mengidentifikasi individu atau kelompok yang menjadi target (misal: tersangka teroris, mata-mata asing).
2. **Selector Tasking**: Analis mengirimkan selector (email, nomor telepon, dll.) ke sistem PRISM.
3. **FISA Review Internal**: (Seharusnya) diverifikasi bahwa selector memenuhi kriteria Section 702.
4. **Pengiriman ke Perusahaan**: Selector diterjemahkan ke format yang dimengerti perusahaan dan dikirim via portal aman.
5. **Data Return**: Perusahaan mencari data yang cocok dan mengirimkannya kembali — kadang real-time (streaming), kadang batch.
6. **Processing & Storage**: Data disimpan di MARINA (metadata) dan MAINWAY (content).
7. **Analysis**: Data dapat dicari via XKEYSCORE, dianalisis dengan link analysis, dan difusikan dengan intelijen lain (HUMINT, SIGINT dari UPSTREAM).

---

## 🔍 Deteksi & Countermeasures Terhadap PRISM

### 1. Gunakan Layanan Non-AS

Perusahaan AS (Google, Microsoft, Apple, Facebook, Amazon, dll.) tunduk pada yurisdiksi AS, termasuk FISA dan National Security Letters. Data yang di-hosting di server mereka dapat diakses PRISM.

- **Alternatif**: Layanan yang berbasis di yurisdiksi dengan perlindungan privasi kuat (EU/EEA dengan GDPR) atau negara tanpa perjanjian MLAT dengan AS. Namun, banyak negara memiliki program serupa.
- **Self-hosting**: Hosting email/file sendiri di server yang Anda kendalikan (dengan enkripsi).

### 2. Enkripsi End-to-End untuk Semua Data

PRISM mengumpulkan data dari server perusahaan — artinya data yang disimpan di server (email di Gmail, file di OneDrive) dapat diakses jika tidak dienkripsi client-side.

- Gunakan **email terenkripsi**: ProtonMail, Tutanota, atau PGP untuk email biasa.
- Gunakan **cloud storage dengan E2EE**: Sync.com, Tresorit, atau enkripsi lokal sebelum upload (Cryptomator, rclone crypt, Veracrypt).
- Gunakan **messenger E2EE**: Signal, WhatsApp (chat, bukan backup), Session.
- Matikan **backup cloud tidak terenkripsi** (WhatsApp backup ke iCloud/Google Drive).

### 3. Minimalkan Metadata

Bahkan dengan enkripsi, metadata (siapa, kapan, dari mana) tetap terekspos. PRISM bisa mengumpulkan metadata dari server.

- Gunakan **Tor** atau **VPN berlapis** untuk menyembunyikan IP login.
- Jangan gunakan nama asli/email pribadi untuk registrasi layanan sensitif.
- Rotasi akun secara berkala.

### 4. Compartmentalization & Operasi Keamanan

- Pisahkan identitas: satu email untuk kehidupan normal, satu untuk aktivitas sensitif.
- Jangan pernah mengakses akun sensitif dari perangkat/jaringan yang sama dengan akun normal (menghubungkan identitas via IP/cookie).
- Gunakan **Tails OS** atau **Qubes OS** untuk isolasi.

### 5. Legal & Policy (AS-specific)

- Non-US persons di luar AS memiliki sedikit perlindungan hukum terhadap PRISM karena Section 702 tidak berlaku untuk mereka.
- US persons dapat menggunakan hak privasi konstitusional (Fourth Amendment), tetapi "incidental collection" tetap terjadi.
- Advokasi: dukung reformasi FISA Section 702, transparansi perusahaan, dan enkripsi yang kuat.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Kontra-terorisme          Intelijen Luar Negeri     Pengawasan Massal
│                         │                         │
Mencegah serangan         Spionase terhadap         Pengumpulan data
teroris dengan            musuh asing,              warga dunia tanpa
memantau komunikasi       diplomat,                 batasan,
│                         perusahaan asing           pelanggaran privasi
│                         │                         │
│                         │                         ▼
▼                         ▼                         Potensi
Keamanan nasional         Keunggulan                penyalahgunaan
(legitimate,              kompetitif                politik (targeting
dengan pengawasan)        (kontroversial)           aktivis, jurnalis)
```

PRISM, dalam desain aslinya, adalah alat kontra-terorisme dan intelijen luar negeri yang sah. Namun, kurangnya transparansi, pengawasan yang lemah, dan cakupan yang sangat luas membuatnya menjadi simbol pengawasan massal global.

---

## 🔗 Koneksi dalam Vault

- [[upstream-and-tempora]] — PRISM untuk data di server; UPSTREAM/TEMPORA untuk traffic di backbone. Keduanya adalah dua pilar pengumpulan SIGINT NSA/GCHQ.
- [[verint]] — Verint adalah vendor yang membangun infrastruktur teknis untuk program seperti PRISM (meskipun PRISM sendiri lebih bergantung pada portal legal, Verint bisa menyediakan front-end DPI).
- [[xkeyscore]] — Data yang dikumpulkan PRISM dapat dicari oleh analis NSA menggunakan XKEYSCORE.
- [[pegasus]] — PRISM mengumpulkan data dari server; Pegasus menginfeksi perangkat individu. Jika target menggunakan enkripsi, Pegasus bisa menjadi solusi untuk membaca sebelum enkripsi.
- [[finspy]] — Spyware untuk desktop/mobile; PRISM untuk data cloud. Keduanya saling melengkapi dalam pengawasan total.
- [[shodan]] — Tidak langsung, tetapi server PRISM (jika ada yang terekspos) mungkin bisa ditemukan.

---

## 📚 Referensi

- Greenwald, G. & MacAskill, E. (2013). *NSA Prism Program Taps into User Data of Apple, Google and Others* (The Guardian).
- Gellman, B. & Poitras, L. (2013). *U.S., British Intelligence Mining Data from Nine U.S. Internet Companies in Broad Secret Program* (Washington Post).
- Snowden, E. (2019). *Permanent Record*. Metropolitan Books.
- Privacy and Civil Liberties Oversight Board (PCLOB). *Report on the Surveillance Program Operated Pursuant to Section 702 of the Foreign Intelligence Surveillance Act* (2014).
- NSA. *Section 702 of the FISA Amendments Act: Overview* (dokumen deklasifikasi).
- MITRE ATT&CK: T1595 (Active Scanning), T1590 (Gather Victim Network Information).

---

*PRISM Deep Dive | NSA Data Collection Program | FISA Section 702 Mass Surveillance*