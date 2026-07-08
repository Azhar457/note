---
title: "Ant Catalog"
tags:
  - 07-nation-state-platforms
  - library
  - military-and-intelligence-tools
aliases:
  - "ant-catalog"
created: "2026-06-28"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> ANT Catalog adalah katalog internal NSA yang berisi perangkat keras implan untuk operasi ofensif, diungkap melalui dokumen Snowden pada 2013. Informasi di bawah berasal dari dokumen yang dipublikasikan Der Spiegel, analisis oleh peneliti keamanan, serta presentasi konferensi. Pembahasan ini murni **edukasional dan defensif**. Tidak ada instruksi untuk membangun atau menggunakan implan serupa. Tujuannya: memahami ancaman hardware-level dan membangun pertahanan.

---

## 🧬 Apa Itu ANT Catalog?

ANT Catalog (Advanced Network Technology) adalah **katalog internal NSA yang mendokumentasikan puluhan perangkat keras implan** — alat ofensif fisik yang dirancang untuk mengakses, mengintersep, atau memanipulasi sistem target secara diam-diam. Katalog ini dioperasikan oleh unit **TAO (Tailored Access Operations)**, yang merupakan unit elite NSA untuk operasi ofensif siber-fisik.

ANT Catalog terungkap melalui dokumen Snowden yang dipublikasikan oleh **Der Spiegel** pada 30 Desember 2013. Katalog ini mencakup:
- **USB implants** — perangkat yang ditanam di kabel atau konektor USB.
- **Ethernet implants** — perangkat yang dipasang di jalur jaringan kabel.
- **Wireless implants** — perangkat RF untuk eksfiltrasi data atau remote access.
- **BIOS/UEFI implants** — malware yang menetap di firmware.
- **Baseband implants** — perangkat untuk mengintersep komunikasi seluler.

### Filosofi ANT

Moto tidak resmi TAO adalah: **"Your security is our business. Your privacy is our product."** Filosofi mereka adalah **"If we can't hack it, we'll intercept it. If we can't intercept it, we'll implant it."**

ANT Catalog mencerminkan pendekatan ini: ketika software exploitation gagal atau tidak memungkinkan (air-gapped network, sistem terproteksi), NSA beralih ke **hardware implant** yang dipasang secara fisik — baik melalui supply chain interception, operasi lapangan, atau social engineering.

---

## 🏗️ Kategori Implan dalam ANT Catalog

### 1. USB Implants

| Nama Kode | Form Factor | Fungsi |
|-----------|-------------|--------|
| **COTTONMOUTH-I** | USB connector (USB-A) | Implan komunikasi RF + keylogger + data exfiltration. Bisa mengirim data via RF ke relay terdekat (hingga 8 km). |
| **COTTONMOUTH-II** | USB connector (USB-A) | Versi lebih kecil dari COTTONMOUTH-I. |
| **COTTONMOUTH-III** | USB connector (USB-A) | Versi mini dengan RF range lebih pendek. |
| **JETPLOW** | USB firmware implant | Menginfeksi firmware USB controller untuk persistensi. Bertahan setelah OS diinstal ulang. |
| **SURLYSPAWN** | Keyboard implant | Keylogger hardware yang dipasang di kabel keyboard (PS/2 atau USB). |
| **RAGEMASTER** | VGA cable implant | Implan yang dipasang di kabel VGA, menangkap dan mentransmisikan tampilan layar via RF. |

### 2. Ethernet / Network Implants

| Nama Kode | Form Factor | Fungsi |
|-----------|-------------|--------|
| **IRATEMONK** | Ethernet connector (RJ45) | Implan di dalam konektor Ethernet. Menyediakan backdoor akses ke jaringan target via RF. |
| **WATERWITCH** | Ethernet inline device | Perangkat yang dipasang di antara kabel Ethernet dan perangkat. Menangkap dan meneruskan traffic. |
| **DEITYBOUNCE** | Server motherboard implant | Implan yang dipasang di slot PCIe server Dell PowerEdge. Menyediakan akses remote permanent. |
| **IRONCHEF** | Network implant | Implan yang dipasang di jaringan untuk intercept traffic HTTP/HTTPS. |
| **FEEDTROUGH** | Firewall implant | Malware yang menetap di firmware firewall untuk mem-bypass aturan keamanan. |
| **HALLUXWATER** | Firewall backdoor | Implan firmware untuk firewall Huawei dan Juniper. |

### 3. Wireless / RF Implants

| Nama Kode | Form Factor | Fungsi |
|-----------|-------------|--------|
| **NIGHTSTAND** | Portable WiFi injection device | Menanamkan malware via WiFi dari jarak hingga 8 km. Bisa membobol WiFi yang terproteksi. |
| **NIGHTWATCH** | RF relay | Menerima data dari implan COTTONMOUTH/RAGEMASTER dan meneruskannya ke operator. |
| **SPARROW-II** | WiFi access point implant | Komputer kecil (ukuran deck kartu) yang berfungsi sebagai AP palsu untuk mengintersep traffic. |
| **LOUDAUTO** | RF bug | Alat pendengar audio via RF. |
| **GENESIS** | Portable GSM interception | IMSI Catcher portabel untuk mengintersep panggilan seluler. |

### 4. BIOS / UEFI / Firmware Implants

| Nama Kode | Target | Fungsi |
|-----------|--------|--------|
| **SWAP** | BIOS/UEFI firmware | Malware yang menetap di firmware motherboard. Bertahan setelah OS diinstal ulang, hard disk diganti. |
| **GODSURGE** | BIOS bootblock | Implan di bootblock BIOS — mengeksekusi sebelum OS dimuat. |
| **DEITYBOUNCE** | Server firmware | Implan firmware untuk server Dell PowerEdge. |
| **IRONCHEF** | Network device firmware | Implan di firmware switch/router. |
| **JETPLOW** | USB controller firmware | Implan di firmware USB controller. |

### 5. Audio / Visual Surveillance

| Nama Kode | Form Factor | Fungsi |
|-----------|-------------|--------|
| **LOUDAUTO** | Audio bug | Mendengarkan percakapan ruangan dan mentransmisikan via RF. |
| **RAGEMASTER** | VGA cable implant | Menangkap tampilan layar dan mentransmisikan via RF. |
| **TAWDRYYARD** | Monitor/printer implant | Menangkap data yang dikirim ke monitor atau printer. |

### 6. Supply Chain Interception

| Nama Kode | Metode | Fungsi |
|-----------|--------|--------|
| **INTERDICTION** | Operasi fisik | Mencegat perangkat yang dikirim (laptop, server, router) di perjalanan, memasang implant, dan mengirimkan kembali ke tujuan — tanpa sepengetahuan pembeli. |
| **CANDYGRAM** | Supply chain | Membuat fake cell tower (IMSI Catcher) yang dipasang di kedutaan AS di luar negeri. |

---

## 🔬 Implan Paling Signifikan — Detail Teknis

### 1. COTTONMOUTH Series (USB Implant + RF)

COTTONMOUTH adalah keluarga implan USB yang menanamkan komputer mikro di dalam konektor USB. Dari luar, kabel USB tampak normal — tebal sedikit, tetapi tidak mencurigakan.

**Komponen Internal:**
- **Mikrokontroler ARM** dengan RF transceiver (biasanya 2.4 GHz atau frekuensi kustom).
- **Flash storage** (MB-GB) untuk menyimpan data curian.
- **Antena terintegrasi** di dalam konektor atau kabel.
- **Baterai atau parasit power** (mengambil daya dari USB host).

**Kemampuan:**
- **Keylogging**: Merekam semua ketukan keyboard.
- **Data Exfiltration**: Mencuri file dari target.
- **Remote Access**: Menerima perintah via RF dari relay NIGHTWATCH.
- **Air-Gap Jumping**: Bahkan jika target tidak terhubung ke internet, COTTONMOUTH bisa mengirim data via RF ke relay terdekat.

**Kill Chain COTTONMOUTH:**
1. **Delivery**: Dipasang di kabel USB target (supply chain interception atau operasi lapangan).
2. **Infection**: Saat kabel digunakan, COTTONMOUTH aktif dan mulai merekam.
3. **Exfiltration**: Data dikirim via RF ke relay NIGHTWATCH di dekatnya (dalam radius 8 km).
4. **Relay**: NIGHTWATCH meneruskan data ke operator NSA via internet atau satelit.

### 2. RAGEMASTER (VGA Cable Implant)

RAGEMASTER adalah implan yang dipasang di kabel VGA (Video Graphics Array) yang menghubungkan komputer ke monitor. Ia menangkap sinyal video analog dan mentransmisikan tampilan layar target secara real-time.

**Kemampuan:**
- **Real-time screen capture**: Operator melihat apa yang dilihat target.
- **RF transmission**: Data dikirim via RF ke relay NIGHTWATCH.
- **Color recovery**: Bahkan dari sinyal VGA analog, teks dan gambar bisa direkonstruksi.

### 3. DEITYBOUNCE (Server Firmware Implant)

DEITYBOUNCE adalah implan yang dipasang di slot PCIe server Dell PowerEdge. Ia menetap di firmware server dan menyediakan akses remote permanent.

**Kemampuan:**
- **Persistensi absolut**: Bertahan setelah OS diinstal ulang.
- **Akses remote**: Operator bisa mengakses server dari jarak jauh.
- **Modular**: Bisa di-upgrade dengan modul tambahan via RF.

### 4. SWAP (BIOS/UEFI Implant)

SWAP adalah malware yang menetap di firmware BIOS/UEFI motherboard. Ia mengeksekusi sebelum sistem operasi dimuat, memberikan kontrol penuh kepada operator.

**Kemampuan:**
- **Bootkit**: Memuat sebelum OS; bisa menginfeksi bootloader.
- **Persistensi absolut**: Tidak bisa dihapus dengan format hard disk.
- **Invisible**: Tidak terlihat oleh OS atau antivirus.

---

## 🕵️‍♂️ Operasi Terdokumentasi

### Operasi INTERDICTION

NSA mencegat perangkat (laptop, server) yang dikirim ke target di luar AS. Perangkat dibuka, implan dipasang, dan dikemas kembali — semua tanpa sepengetahuan pembeli atau vendor. Ini adalah **supply chain attack fisik**.

### Operasi GENESIS

GENESIS adalah IMSI Catcher portabel yang digunakan untuk mengintersep panggilan seluler target. Dipasang di kedutaan AS atau kendaraan intelijen.

### Operasi CANDYGRAM

NSA memasang fake cell tower (IMSI Catcher) di kedutaan AS di luar negeri — termasuk Berlin, Frankfurt, dan kota lain. "Candygram" adalah nama kode untuk sistem ini.

---

## 🛡️ Countermeasures & Pertahanan

### 1. Deteksi Hardware Implant

| Metode | Detail |
|--------|--------|
| **X-ray / CT Scan** | Memindai perangkat untuk mendeteksi komponen asing di dalam kabel atau konektor. |
| **TDR (Time Domain Reflectometer)** | Mendeteksi anomali impedansi di kabel yang mengindikasikan splice atau implant. |
| **RF Sweeping (Oscor/ANDRE)** | Mendeteksi emisi RF dari implan aktif. |
| **Physical Inspection** | Bongkar konektor dan periksa dengan mikroskop. |
| **Supply Chain Integrity** | Gunakan supplier tepercaya, verifikasi rantai pasok. |

### 2. Pencegahan

| Tindakan | Detail |
|----------|--------|
| **Gunakan Kabel Sendiri** | Jangan pernah menerima kabel/perangkat dari sumber tidak dikenal. |
| **Tamper-Evident Packaging** | Gunakan segel anti-rusak, hologram. |
| **Secure Boot + TPM** | Deteksi modifikasi firmware dengan verifikasi tanda tangan. |
| **Air-Gap dengan Shielding** | Untuk sistem sangat sensitif, gunakan Faraday cage untuk memblokir RF exfiltration. |
| **Firmware Integrity** | Verifikasi hash firmware secara berkala. Gunakan firmware dari sumber resmi. |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Intelijen Defensif         Kontra-Terorisme         Operasi Ofensif
│                         │                        │
Melindungi sistem         Menanamkan implan        Memata-matai
dari implant musuh        di perangkat teroris     target asing
dengan TSCM +             untuk melacak            dengan supply
supply chain security     aktivitas                chain attack
│                         │                        │
│                         │                        ▼
▼                         ▼                        INTERDICTION:
Security hardening        Operasi sah              mencegat perangkat
                          (kontroversial)          di pengiriman
```

ANT Catalog adalah puncak dari **"when all else fails, use hardware"**. Kemampuan untuk menanamkan implan di level fisik — kabel, firmware, supply chain — memberikan NSA akses ke target yang tidak mungkin dijangkau secara digital.

---

## 🔗 Koneksi dalam Vault

- [[foxacid]] — FOXACID mengeksploitasi software; ANT Catalog mengeksploitasi hardware. Keduanya adalah tools TAO.
- [[QUANTUM (NSA)]] — QUANTUM untuk redirect; COTTONMOUTH untuk exfiltration dari air-gapped target.
- [[muscular]] — MUSCULAR untuk intersep data center; ANT Catalog untuk akses endpoint.
- [[Oscor / ANDRE]] — Oscor/ANDRE adalah alat untuk mendeteksi implan ANT Catalog.
- [[Hak5 Suite]] — Hak5 adalah versi sipil (dan kurang canggih) dari ANT Catalog.
- [[IMSI Catcher / Stingray]] — GENESIS/CANDYGRAM adalah StingRay versi NSA.

---

## 📚 Referensi

- Der Spiegel. *NSA ANT Catalog: The NSA's Secret Toolbox* (2013).
- Snowden, E. (2013). *NSA Documents: ANT Catalog*.
- Kaspersky. *Equation Group: The Crown Creator of Cyber-Espionage* (2015).
- MITRE ATT&CK: T1200 (Hardware Additions), T1542 (Pre-OS Boot: Bootkit), T1557 (Man-in-the-Middle).

---

*ANT Catalog Deep Dive | NSA Hardware Implant & Physical Access Toolkit | TAO Operations*