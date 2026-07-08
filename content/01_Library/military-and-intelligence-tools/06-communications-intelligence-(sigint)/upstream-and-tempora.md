---
title: "Upstream and Tempora"
tags:
  - 06-communications-intelligence-(sigint)
  - library
  - military-and-intelligence-tools
aliases:
  - "upstream-and-tempora"
created: "2026-06-27"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> UPSTREAM adalah program intersepsi backbone internet NSA (Amerika Serikat); TEMPORA adalah program setara GCHQ (Britania Raya). Keduanya diungkap oleh Edward Snowden pada 2013. Informasi di bawah berasal dari dokumen bocor Snowden (dipublikasikan The Guardian, Washington Post, Der Spiegel), laporan parlemen UK, serta analisis teknis oleh peneliti keamanan. Pembahasan ini murni **edukasional dan defensif**. Intersepsi komunikasi tanpa otorisasi hukum adalah pelanggaran berat di banyak yurisdiksi. Tujuannya agar pembaca memahami arsitektur pengawasan global dan dapat mengambil langkah perlindungan.

## 🧬 Definisi: UPSTREAM & TEMPORA

UPSTREAM dan TEMPORA adalah **program intersepsi backbone internet** — yaitu pengumpulan data langsung dari kabel fiber optik dan titik pertukaran internet (IXP) yang membawa traffic global.

| Aspek                | UPSTREAM (NSA, AS)                                   | TEMPORA (GCHQ, UK)                                      |
| -------------------- | ---------------------------------------------------- | ------------------------------------------------------- |
| **Operator**         | NSA (dengan bantuan perusahaan telekomunikasi AS)    | GCHQ (dengan bantuan BT, Vodafone Cable, dll.)          |
| **Metode**           | TAP fisik pada fiber optic backbone & IXP            | TAP fisik pada kabel fiber transatlantik & domestik     |
| **Cakupan**          | Traffic yang melintasi AS (domestik & internasional) | Traffic yang melintasi UK (transatlantik ke/dari Eropa) |
| **Buffer Content**   | Tidak diungkap (diduga mirip TEMPORA)                | 3 hari content, 30 hari metadata                        |
| **Program Terkait**  | FAIRVIEW, STORMBREW, OAKSTAR, BLARNEY                | MASTERSHAKE, TUNINGFORK, SQUEAKYDOLL                    |
| **Titik Intersepsi** | AT&T, Verizon (kemungkinan), IXP di AS               | BT, Vodafone, Cable & Wireless, IXP di UK               |
| **Otoritas Hukum**   | Executive Order 12333 (luar AS), FISA (dalam AS)     | Regulation of Investigatory Powers Act 2000 (RIPA)      |
| **Data Sharing**     | Dibagi ke Five Eyes (termasuk GCHQ)                  | Dibagi ke Five Eyes (termasuk NSA)                      |

### Perbandingan dengan PRISM

|                 | PRISM                                                | UPSTREAM / TEMPORA                                                   |
| --------------- | ---------------------------------------------------- | -------------------------------------------------------------------- |
| **Sumber Data** | Server perusahaan teknologi                          | Kabel fiber backbone                                                 |
| **Jenis Data**  | Email, chat, file, foto, video (tersimpan di server) | Raw internet traffic: browsing, email, VoIP, file transfer, metadata |
| **Cara Akses**  | Perusahaan wajib memberikan data                     | NSA/GCHQ mengintersep langsung via TAP fisik                         |
| **Enkripsi**    | Bisa dapat plaintext (data sebelum enkripsi server)  | Harus mendekripsi traffic (SSL/TLS, VPN)                             |
| **Volume**      | Selektor-spesifik (target tertentu)                  | Massal (semua traffic yang lewat)                                    |

---

## 🏗️ Arsitektur Intersepsi Backbone

### Bagaimana Fiber TAP Bekerja

Serat optik mentransmisikan data sebagai pulsa cahaya. Intersepsi backbone dilakukan dengan **fiber optic splitter** — perangkat optik pasif yang membagi sinyal cahaya menjadi dua jalur:

```
[Fiber Backbone] ───────┬──────────────────► [Tujuan Normal]
                        │
                    [Optical Splitter]
                    (90% daya lanjut,
                     10% daya ke monitor)
                        │
                        ▼
              [TAP / Probe Hardware]
              (Rack-mount server dengan
               optik receiver berkecepatan
               tinggi: 10/40/100 Gbps)
                        │
                        ▼
              [Packet Processing Engine]
              (DPI, filtering, reassembly)
                        │
                        ▼
              [Storage & Analysis]
```

Fiber splitter bersifat **pasif** — tidak mengubah sinyal asli. Traffic tujuan tetap berjalan normal tanpa penundaan atau kehilangan. Tidak mungkin mendeteksi keberadaan splitter dari analisis jaringan biasa karena ia tidak memancarkan sinyal apapun.

### Titik Intersepsi Strategis

| Titik Intersepsi                  | Lokasi                                                           | Program                                  | Traffic yang Terjaring                                          |
| --------------------------------- | ---------------------------------------------------------------- | ---------------------------------------- | --------------------------------------------------------------- |
| **Kabel Transatlantik**           | Titik pendaratan di Cornwall (UK), New Jersey (AS), dll.         | TEMPORA                                  | Traffic antara Eropa dan Amerika Utara (email, browsing, VoIP)  |
| **IXP (Internet Exchange Point)** | Equinix Ashburn/Chicago (AS), LINX London (UK), AMS-IX Amsterdam | UPSTREAM, TEMPORA                        | Traffic domestik dan internasional yang dipertukarkan antar ISP |
| **Backbone Operator**             | Jaringan AT&T, Verizon, BT, Vodafone                             | FAIRVIEW (NSA), STORMBREW (NSA), TEMPORA | Traffic pengguna operator tersebut                              |
| **Kabel Bawah Laut Asia-Pasifik** | SEA-ME-WE 3, APCN-2, dll.                                        | Program terkait (MUSCULAR, INCENSER)     | Traffic Asia, Timur Tengah, Australia                           |

---

## 🔬 Kemampuan Teknis: Dari Fiber ke Data Intelijen

### 1. Deep Packet Inspection (DPI) Skala Masif

Hardware probe di titik TAP melakukan DPI pada traffic yang lewat dengan kecepatan line-rate (hingga 100 Gbps per fiber). DPI engine mengidentifikasi:

- **Protokol**: HTTP, HTTPS, SMTP, POP3, IMAP, FTP, DNS, SIP, RTP, BitTorrent, dll.
- **Aplikasi**: WhatsApp, Facebook, Gmail, Skype, Telegram, WeChat, dll. (dari signature traffic).
- **Metadata**: Source/destination IP, port, domain, URL, email address, phone number, cookie, device fingerprint.

### 2. Rekonstruksi Sesi

Traffic internet terfragmentasi menjadi paket. DPI engine merekonstruksi sesi penuh:

- **Email**: Menggabungkan paket SMTP menjadi email lengkap (To, From, Subject, Body, Attachments).
- **VoIP**: Menggabungkan paket RTP menjadi audio stream, lalu mendekripsi jika codec tidak terenkripsi.
- **Browsing**: Merekam URL yang dikunjungi, konten halaman (HTTP), dan file yang diunduh.
- **File Transfer**: Merekam file yang dikirim via FTP, HTTP download, atau attachment email.

### 3. Dekripsi SSL/TLS (Kontroversial)

Mayoritas traffic modern dienkripsi (HTTPS, E2EE). NSA dan GCHQ memiliki beberapa pendekatan untuk mendekripsi:

- **SSL/TLS Interception**: Jika mereka memiliki kunci privat server (misal: diperoleh dari perusahaan atau melalui peretasan), traffic bisa didekripsi.
- **Downgrade Attack**: Memaksa koneksi menggunakan cipher suite lemah yang bisa dipecahkan dengan kekuatan komputasi besar.
- **BULLRUN**: Program NSA untuk memecahkan enkripsi (termasuk mempengaruhi standar enkripsi NIST agar memiliki backdoor — terungkap dalam Snowden leaks).
- **Man-in-the-Middle via Kolusi**: Jika ISP/operator bekerja sama, mereka bisa mengarahkan traffic melalui proxy yang melakukan SSL termination dan re-encryption.
- **Traffic Analysis & Metadata**: Bahkan tanpa mendekripsi, metadata yang kaya (siapa, kapan, berapa lama, berapa banyak data) sudah sangat informatif.

### 4. Penyimpanan & Analisis

TEMPORA (GCHQ) menyimpan:

- **Content buffer**: 3 hari (semua konten yang lewat — email, browsing, file).
- **Metadata buffer**: 30 hari (siapa, kapan, dari mana, ke mana).

UPSTREAM (NSA) tidak diungkapkan secara publik, tetapi diasumsikan memiliki kapasitas serupa atau lebih besar, dengan data mengalir ke database MARINA (metadata) dan MAINWAY (content).

Dengan buffer ini, analis bisa:

- **Retrospective analysis**: Setelah target teridentifikasi, analis bisa melihat komunikasi 3-30 hari terakhir tanpa perlu mencegat sebelumnya.
- **Pattern-of-life**: Menganalisis pola komunikasi selama sebulan untuk membangun profil target.
- **Contact chaining**: Melihat siapa yang dihubungi target, lalu siapa yang dihubungi oleh kontak tersebut (two-hop, three-hop).

---

## 📊 Program Spesifik di Bawah UPSTREAM & TEMPORA

### UPSTREAM (NSA)

| Sub-program   | Titik Intersepsi                        | Mitra                                  |
| ------------- | --------------------------------------- | -------------------------------------- |
| **FAIRVIEW**  | AT&T backbone & peering points          | AT&T                                   |
| **STORMBREW** | Verizon backbone (kemungkinan)          | Verizon (tidak dikonfirmasi)           |
| **BLARNEY**   | IXP di AS (Equinix, dll.)               | Pemilik data center                    |
| **OAKSTAR**   | Backbone operator regional              | Operator kecil                         |
| **MUSCULAR**  | Link internal Google/Yahoo (di luar AS) | (akses tanpa sepengetahuan perusahaan) |
| **INCENSER**  | Kabel bawah laut Asia-Pasifik           | Mitra lokal                            |

### TEMPORA (GCHQ)

| Sub-program     | Titik Intersepsi                          | Mitra                      |
| --------------- | ----------------------------------------- | -------------------------- |
| **MASTERSHAKE** | Kabel transatlantik (pendaratan Cornwall) | BT, Vodafone Cable         |
| **TUNINGFORK**  | IXP di London (LINX)                      | LINX, operator UK          |
| **SQUEAKYDOLL** | Kabel domestik UK                         | Operator telekomunikasi UK |

---

## 🔗 Data Sharing: Five Eyes & Beyond

Data dari UPSTREAM dan TEMPORA dibagikan dalam kerangka **Five Eyes** (AS, UK, Kanada, Australia, Selandia Baru), dengan aturan informal **"You collect ours, we'll collect yours"** untuk menghindari larangan hukum memata-matai warga sendiri.

- **NSA (AS)** memata-matai traffic Eropa, dibagi ke GCHQ.
- **GCHQ (UK)** memata-matai traffic AS, dibagi ke NSA.
- **CSE (Kanada)**, **ASD (Australia)**, **GCSB (Selandia Baru)** melakukan hal serupa di wilayah mereka.

Hasilnya adalah **jaring pengawasan global** di mana tidak ada traffic internasional yang benar-benar aman dari intersepsi oleh setidaknya satu anggota Five Eyes.

---

## 🛡️ Countermeasures & Pertahanan

| Lapisan                    | Tindakan                                                                                                                                                       |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Enkripsi**               | Gunakan **E2EE** untuk semua komunikasi. Signal, WhatsApp, Telegram Secret Chat. UPSTREAM/TEMPORA tidak bisa mendekripsi E2EE (tapi metadata tetap terekspos). |
| **VPN & Tor**              | Gunakan **VPN** (dengan enkripsi kuat, tanpa logging) atau **Tor** untuk menyembunyikan IP dan konten. Traffic tetap lewat backbone, tetapi terenkripsi.       |
| **Metadata Obfuscation**   | Minimalkan metadata: gunakan email burner, nomor telepon burner, hindari pola komunikasi yang bisa diprediksi.                                                 |
| **Traffic Obfuscation**    | Gunakan **pluggable transports** (obfs4, meek) untuk menyembunyikan traffic Tor dari DPI.                                                                      |
| **Decentralized Services** | Hindari layanan yang terpusat di AS/UK. Gunakan layanan dengan server di yurisdiksi ramah privasi (Islandia, Swiss).                                           |
| **Self-Hosting**           | Hosting sendiri email/cloud di server yang Anda kendalikan, dengan enkripsi penuh.                                                                             |
| **Awareness**              | Sadari bahwa traffic internasional hampir pasti melewati titik intersepsi Five Eyes. Desain komunikasi dengan asumsi itu.                                      |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Kontra-terorisme          Intelijen Luar Negeri     Pengawasan Massal
│                         │                         │
Intersepsi komunikasi     Spionase ekonomi          Mengumpulkan data
teroris, sindikat         dan politik terhadap      seluruh populasi
narkoba, kejahatan        negara asing              tanpa diskriminasi
transnasional             │                         │
│                         │                         ▼
│                         ▼                         Pelanggaran privasi
▼                         Diplomasi paksa,          global, chilling
Keamanan nasional         tekanan ekonomi           effect pada
(legitimate)              pada perusahaan           kebebasan berbicara
                          asing
```

UPSTREAM dan TEMPORA adalah perwujudan **pengawasan massal tanpa diskriminasi**. Semua traffic yang lewat dikumpulkan, bukan hanya target spesifik. Ini adalah perbedaan mendasar dengan PRISM yang lebih tertarget.

---

## 🔗 Koneksi dalam Vault

- [[prism]] — PRISM mengumpulkan dari server; UPSTREAM/TEMPORA mengumpulkan dari kabel. Keduanya adalah dua pilar pengumpulan SIGINT.
- [[verint]] — Verint menyediakan hardware DPI untuk program seperti UPSTREAM/TEMPORA.
- [[xkeyscore]] — Data dari UPSTREAM/TEMPORA disimpan di MARINA/MAINWAY dan dapat dicari via XKEYSCORE.
- [[pegasus]] — Jika UPSTREAM/TEMPORA tidak bisa mendekripsi traffic E2EE, Pegasus bisa digunakan untuk menginfeksi perangkat target dan membaca data sebelum enkripsi.
- [[shodan]] — Tidak langsung, tetapi pemahaman tentang backbone internet membantu memahami di mana TAP mungkin ditempatkan.

---

## 📚 Referensi

- MacAskill, E., Borger, J., Hopkins, N., Davies, N., & Ball, J. (2013). _GCHQ Taps Fibre-Optic Cables for Secret Access to World's Communications_ (The Guardian).
- Gellman, B., & Soltani, A. (2013). _NSA Infiltrates Links to Yahoo, Google Data Centers Worldwide, Snowden Documents Say_ (Washington Post).
- Greenwald, G. (2014). _No Place to Hide: Edward Snowden, the NSA, and the U.S. Surveillance State_. Metropolitan Books.
- UK Parliament. _Privacy and Security: A Modern and Transparent Legal Framework_ (2015).
- EFF. _NSA Spying on Americans: How the NSA's Domestic Surveillance Programs Work_.
- MITRE ATT&CK: T1595 (Active Scanning), T1592 (Gather Victim Host Information), T1590 (Gather Victim Network Information).

---

_UPSTREAM & TEMPORA Deep Dive | Backbone Internet Interception | Global Mass Surveillance Programs_
