---
title: Great Cannon
tags:
- 07-nation-state-platforms
- library
- military-and-intelligence-tools
created: '2026-06-28'
updated: '2026-07-01'
status: operational
cssclasses: ''
---

> [!warning] Konteks Etis & Legal
> Great Cannon adalah sebutan untuk alat ofensif siber yang memanfaatkan infrastruktur Great Firewall Tiongkok. Informasi di bawah berasal dari laporan peneliti keamanan (Citizen Lab, Recorded Future), analisis forensik insiden GitHub 2015, serta dokumen publik. Pembahasan ini murni **edukasional dan defensif**. Tidak ada instruksi atau advokasi untuk membangun atau menggunakan alat serupa. Tujuannya agar defender memahami kemampuan ofensif tingkat negara yang memanfaatkan infrastruktur nasional.

---

## 🧬 Apa Itu Great Cannon?

Great Cannon adalah **senjata siber ofensif** yang memanfaatkan infrastruktur **Great Firewall (GFW)** Tiongkok untuk melancarkan serangan terhadap target di luar Tiongkok. Berbeda dengan Great Firewall yang bersifat defensif (memblokir konten masuk), Great Cannon adalah **kemampuan ofensif** yang dapat:

- **Melancarkan DDoS** (Distributed Denial of Service) massal
- **Menyuntikkan malware** ke traffic internet
- **Mengalihkan (redirect) traffic** target ke server jahat
- **Memanipulasi konten** yang diunduh target

Great Cannon pertama kali diidentifikasi secara publik pada Maret 2015 ketika digunakan untuk menyerang **GitHub** — menyebabkan gangguan besar pada layanan tersebut. Serangan ini menargetkan proyek-proyek anti-sensor di GitHub.

### Great Firewall vs Great Cannon

| | Great Firewall (GFW) | Great Cannon |
|---|---|---|
| **Fungsi** | Defensif: blokir, throttle, reset koneksi ke konten terlarang di dalam Tiongkok | Ofensif: serang target di luar Tiongkok dengan DDoS, injeksi, redirect |
| **Target** | Warga Tiongkok yang mengakses konten luar | Server, website, dan individu di luar Tiongkok |
| **Metode** | DNS poisoning, IP blocking, TCP RST injection, DPI | HTTP injection, BGP hijack, traffic amplification |
| **Infrastruktur** | Router ISP di perbatasan Tiongkok | Infrastruktur yang sama, tetapi digunakan untuk ofensif |
| **Terungkap** | Dikenal sejak awal 2000-an | Maret 2015 (serangan GitHub) |

---

## 🏗️ Arsitektur Great Cannon

Great Cannon memanfaatkan posisi unik Tiongkok dalam arsitektur internet global: semua traffic yang melintasi perbatasan Tiongkok (masuk dan keluar) harus melewati router yang dikendalikan oleh pemerintah. Ini memberi kemampuan Man-in-the-Middle (MitM) pada skala nasional.

### Mekanisme Serangan

```
[Target di Luar Tiongkok]
         │
         │  (1) Traffic normal menuju website
         ▼
[Website Target]  ◄── [Internet Global]
         │
         │  (2) Traffic dari target melewati border router Tiongkok
         │      (misalnya saat mengakses konten di Tiongkok atau lewat AS Tiongkok)
         ▼
[Great Cannon System]
  (DPI + Injection Engine di border router)
         │
         │  (3) Sistem mendeteksi traffic target
         │      dan menyuntikkan respons palsu
         ▼
[Target] menerima:
  - HTTP 302 Redirect ke server exploit
  - JavaScript berbahaya
  - Malware payload
  - Atau: DDoS traffic ke korban (amplifikasi)
```

### Komponen Teknis

| Komponen | Fungsi |
|----------|--------|
| **DPI Engine** | Mendeteksi traffic target berdasarkan IP, cookie, atau pola browsing. |
| **Injection Engine** | Membuat dan mengirimkan respons palsu yang menang race condition dengan server asli. |
| **Amplification Engine** | Memanfaatkan bandwidth besar border router untuk membanjiri target dengan traffic (DDoS). |
| **Redirect System** | Mengalihkan target ke server exploit atau honeypot. |
| **Content Modification** | Memodifikasi file yang diunduh (software, dokumen) dengan menyisipkan malware. |

---

## 🔥 Serangan Terdokumentasi

### 1. GitHub DDoS (Maret 2015)

**Kronologi:**
- GitHub mengalami DDoS masif yang berasal dari **ratusan ribu IP di Tiongkok**.
- Traffic bukan dari botnet tradisional, melainkan dari **border router GFW** yang membanjiri GitHub dengan permintaan.
- Target: Proyek **GreatFire** dan **CN-NYTimes** (alat anti-sensor).

**Metode Teknis:**
- Setiap kali pengguna di Tiongkok mengakses website yang mengandung **JavaScript bait** (disisipkan oleh GFW), browser mereka tanpa sadar mengirimkan permintaan ke GitHub.
- Jutaan pengguna Tiongkok secara tidak sengaja berpartisipasi dalam DDoS.

**Dampak:**
- GitHub lumpuh selama beberapa hari.
- Ini adalah pertama kalinya sebuah negara menggunakan infrastruktur internet nasionalnya sebagai senjata DDoS.

### 2. Great Cannon vs. VPN Providers (2015-2020)

- Beberapa penyedia VPN yang membantu warga Tiongkok melewati GFW menjadi target Great Cannon.
- Serangan: **HTTP injection** untuk mengalihkan pengguna VPN ke halaman palsu yang mencuri kredensial.
- **DNS poisoning** untuk memblokir resolusi domain VPN.

### 3. Malware Injection via Software Downloads (2017)

- Peneliti menemukan bahwa Great Cannon digunakan untuk **memodifikasi file yang diunduh** dari internet oleh target di luar Tiongkok.
- File yang diunduh (misal: installer software, PDF reader) disisipkan dengan malware saat melewati border router.
- Target yang terinfeksi termasuk lembaga pemerintah dan perusahaan di Asia Tenggara.

---

## 🧰 GFW Arsenal: Ekosistem Alat Ofensif Tiongkok

Great Cannon adalah bagian dari **ekosistem alat ofensif** yang lebih besar yang terintegrasi dengan infrastruktur GFW:

### Alat- Alat dalam GFW Arsenal

| Nama | Fungsi | Status |
|------|--------|--------|
| **Great Cannon** | DDoS, HTTP injection, content modification | Terkonfirmasi |
| **Great Firewall** (defensif) | Blokir, throttle, reset koneksi | Terkonfirmasi |
| **DNS Poisoning System** | Memalsukan respons DNS untuk mengarahkan traffic | Terkonfirmasi |
| **BGP Hijack Capability** | Mengumumkan rute palsu untuk mengalihkan traffic internasional | Diduga kuat |
| **QR Code Attack System** | Menyisipkan URL berbahaya di QR code yang dipindai (WeChat, Alipay) | Laporan terbatas |
| **5G Network Slicing Exploit** | Memanfaatkan network slicing 5G untuk isolasi dan serangan | Diduga (teoretis) |

### Karakteristik Unik GFW Arsenal

1. **Skala Nasional**: Tidak seperti botnet yang harus dibangun dari perangkat terinfeksi, Great Cannon langsung memanfaatkan infrastruktur internet nasional — bandwidth besar, jutaan IP sah.

2. **Legitimate IPs**: Traffic serangan berasal dari IP publik pengguna biasa di Tiongkok, bukan IP server jahat. Ini membuat mitigasi DDoS sangat sulit — Anda tidak bisa memblokir seluruh rentang IP Tiongkok.

3. **Dual-Use Infrastructure**: Infrastruktur yang sama digunakan untuk defensive (GFW) dan ofensif (Great Cannon). Tidak ada pemisahan yang jelas.

4. **Plausible Deniability**: Karena traffic berasal dari jutaan pengguna biasa, Tiongkok dapat menyangkal keterlibatan. Serangan GitHub direspons dengan: "Ini hanya traffic normal dari netizen."

---

## 🔬 Analisis Teknis Serangan GitHub 2015

Serangan GitHub 2015 adalah studi kasus sempurna untuk memahami Great Cannon:

### Langkah Demi Langkah

1. **Penyisipan JavaScript Bait**:
   - GFW memodifikasi halaman web yang diakses pengguna Tiongkok (misal: Baidu, Sina).
   - Menyisipkan script `<script src="http://github.com/greatfire/...">` ke dalam halaman.

2. **Amplifikasi oleh Browser**:
   - Jutaan browser pengguna Tiongkok secara otomatis memuat script tersebut.
   - Setiap browser mengirimkan HTTP GET ke GitHub.

3. **DDoS Masif**:
   - GitHub menerima **jutaan permintaan per detik** dari IP sah di seluruh Tiongkok.
   - Traffic bukan SYN flood atau UDP amplification, melainkan **HTTP GET valid** — sangat sulit difilter.

4. **Looping untuk Keberlanjutan**:
   - Script bait juga menyertakan **meta refresh** atau **Ajax polling** sehingga browser terus-menerus mengirimkan permintaan selama halaman terbuka.

### Keunggulan Teknis

- **Tidak memerlukan botnet**: Tidak ada perangkat yang terinfeksi. Semua partisipan adalah pengguna sah yang tidak sadar.
- **Tidak terdeteksi sebagai malicious**: Traffic adalah HTTP GET normal, bukan paket jahat.
- **Skalabilitas tak terbatas**: Semakin banyak pengguna online di Tiongkok, semakin besar kekuatan DDoS.

---

## 🛡️ Countermeasures & Pertahanan

### 1. Terhadap DDoS dari Great Cannon

| Metode | Detail |
|--------|--------|
| **Geographic Filtering** | Blokir atau rate-limit traffic dari rentang IP Tiongkok (kontroversial, tapi efektif). |
| **JavaScript Challenge** | Gunakan CAPTCHA atau JS challenge untuk memvalidasi bahwa pengguna adalah manusia, bukan script bait. |
| **CDN dengan DDoS Protection** | Cloudflare, Akamai, AWS Shield — dapat menyerap traffic masif. |
| **Anycast Network** | Sebarkan traffic ke banyak titik global untuk mencegah satu titik lumpuh. |
| **Behavioral Analysis** | Deteksi pola traffic yang tidak wajar (misal: ribuan GET ke URL yang sama dari IP berbeda dalam satu wilayah). |

### 2. Terhadap HTTP Injection

| Metode | Detail |
|--------|--------|
| **HTTPS + HSTS** | Enkripsi end-to-end mencegah modifikasi konten di tengah jalan. Preload HSTS. |
| **Subresource Integrity (SRI)** | Tag `<script integrity="sha384-...">` memungkinkan browser memverifikasi bahwa script tidak dimodifikasi. |
| **Content Security Policy (CSP)** | Header CSP membatasi dari mana browser boleh memuat resource. |
| **Certificate Pinning** | Mencegah MITM dengan memvalidasi sertifikat server secara ketat. |

### 3. Terhadap Content Modification

| Metode | Detail |
|--------|--------|
| **Code Signing** | Semua software harus ditandatangani secara digital. OS memverifikasi sebelum eksekusi. |
| **Checksum Verification** | Sediakan hash SHA-256 untuk setiap file yang diunduh; verifikasi setelah download. |
| **Download via Torrent/Magnet** | Desentralisasi download untuk menghindari satu titik modifikasi. |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Kontrol konten            Intelijen &               Serangan ofensif
│                         Kontra-spionase           │
Memblokir konten          │                         DDoS terhadap
berbahaya/ilegal          Memantau traffic           GitHub, VPN providers,
masuk Tiongkok            mencurigakan,             injeksi malware ke
(klaim resmi)             melacak spy asing          target luar Tiongkok
│                         │                         │
│                         │                         ▼
▼                         ▼                         Senjata siber
Great Firewall            Kemampuan                 nasional yang
(defensif)                intelijen                 disalahgunakan
                          (legitimate)              (ofensif)
```

Great Cannon adalah contoh sempurna bagaimana infrastruktur defensif dapat dengan mudah diubah menjadi senjata ofensif. Tidak ada pemisahan teknis antara GFW dan Great Cannon — keduanya berjalan di router yang sama, dioperasikan oleh entitas yang sama.

---

## 🔗 Koneksi dalam Vault

- [[quantum-insert-and-blackpearl]] — Teknik injeksi HTTP yang identik; Quantum Insert (NSA/Unit 8200) dan Great Cannon (Tiongkok) menggunakan prinsip race condition yang sama.
- [[foxacid]] — NSA menggunakan FOXACID untuk exploit delivery setelah redirect; Great Cannon bisa melakukan redirect ke server exploit serupa.
- [[upstream-and-tempora]] — Intersep backbone pasif; Great Cannon adalah versi ofensif dari kemampuan ini.
- [[muscular]] — Operasi NSA/GCHQ untuk mengintersep link internal data center; Great Cannon mengintersep dan memodifikasi traffic di border.
- [[quantum]] — Program NSA untuk active network attack; Great Cannon adalah padanan Tiongkok.
- `DNS Poisoning` — Teknik yang digunakan oleh Great Cannon untuk mengalihkan traffic.
- `BGP Hijack` — Bagian dari GFW Arsenal untuk mengalihkan rute internasional.

---

## 📚 Referensi

- Marczak, B., et al. (2015). *China's Great Cannon*. Citizen Lab.
- Goodin, D. (2015). *Meet the Great Cannon: The Chinese government's DDoS tool*. Ars Technica.
- Recorded Future. *China's Offensive Cyber Capabilities: Great Cannon and Beyond* (2020).
- Cimpanu, C. (2020). *The Great Firewall of China: Technical Analysis*. ZDNet.
- MITRE ATT&CK: T1498 (Network Denial of Service), T1189 (Drive-by Compromise), T1583.004 (Acquire Infrastructure: Server).

---

*Great Cannon / GFW Arsenal Deep Dive | China's Offensive Cyber Infrastructure | Nation-State DDoS & Traffic Injection*