---
title: Quantum Insert and Blackpearl
tags:
- 07-nation-state-platforms
- library
- military-and-intelligence-tools
created: '2026-06-28'
updated: '2026-07-01'
status: pending
cssclasses: ''
---

> [!warning] Konteks Etis & Legal
> Quantum Insert adalah teknik serangan jaringan aktif yang diungkap melalui dokumen Snowden (2013) dan laporan threat intelligence. Blackpearl adalah toolkit yang dikaitkan dengan Unit 8200 Israel berdasarkan laporan Kaspersky, Symantec, dan media internasional. Seluruh informasi berasal dari sumber publik. Pembahasan ini murni **edukasional dan defensif**. Tidak ada instruksi operasional. Tujuan: membantu defender memahami TTP tingkat negara dan memperkuat postur keamanan jaringan.

---

## 🧬 Gambaran Umum

Quantum Insert dan Blackpearl adalah **teknik serangan jaringan aktif** yang memungkinkan aktor negara untuk mencegat, memodifikasi, atau menyuntikkan traffic internet secara real-time. Berbeda dengan pengawasan pasif (intersep kabel), teknik ini **mengubah traffic yang sedang berjalan** — memungkinkan infeksi malware, pencurian kredensial, dan pengalihan komunikasi target.

**Quantum Insert** adalah nama kode NSA/GCHQ untuk teknik ini, diungkap oleh Snowden.  
**Blackpearl** adalah nama yang diberikan oleh peneliti keamanan untuk toolkit serupa yang dikaitkan dengan Unit 8200 Israel, berdasarkan pola operasi, target, dan infrastruktur.

### Perbandingan dengan Teknik Serupa

| Teknik | Aktor | Metode | Kecepatan Respons |
|--------|-------|--------|-------------------|
| **QUANTUM (NSA)** | NSA | BGP injection, race condition | Milidetik (harus menang dari server asli) |
| **FOXACID (NSA)** | NSA | Exploit delivery via redirect | Milidetik (redirect ke exploit server) |
| **Quantum Insert** | NSA / Unit 8200 | Packet injection, DNS spoofing | Milidetik |
| **Blackpearl** | Unit 8200 | Man-in-the-Middle via ISP kolusi, BGP hijack | Milidetik hingga detik |

---

## 🏗️ Arsitektur Quantum Insert

Quantum Insert bekerja dengan prinsip **race condition**: penyerang harus mengirimkan respons palsu sebelum server sah merespons permintaan target.

### Mekanisme Teknis

1. **Pemantauan Target**: Penyerang memantau traffic target secara pasif (via TAP backbone atau kolusi ISP).
2. **Deteksi Permintaan**: Ketika target melakukan HTTP request ke website tertentu, sistem otomatis mendeteksi.
3. **Injeksi Respons Palsu**: Penyerang mengirimkan HTTP response palsu (302 redirect atau halaman exploit) yang tiba lebih cepat dari respons server asli.
4. **Redirect atau Infeksi**: Target diarahkan ke server exploit (FOXACID-style) atau langsung menerima payload malware.

```
[Target] ── HTTP GET ──► [Website Sah]
   │                         │
   │                         ▼
   │                    [Server Sah]
   │                    (Response lambat: 200 OK)
   │
   └──► [Quantum Insert System] (monitor traffic target)
            │
            ▼
         [Deteksi GET ke target-website.com]
            │
            ▼
         [Generate Fake Response]
         (302 Redirect ke exploit server)
            │
            ▼
         [Kirim ke Target SEBELUM server sah]
            │
            ▼
         [Target menerima redirect, ke exploit server]
```
### Persyaratan
- **Akses backbone**: Harus berada di jalur traffic target (TAP fiber, IXP, atau kolusi ISP).
- **Kecepatan**: Respons palsu harus menang race condition (biasanya < 50ms).
- **Infrastruktur**: Server injeksi di titik strategis secara geografis.
- **Targeting**: Sistem harus bisa mengidentifikasi target di antara miliaran traffic (cookie, IP, fingerprint).
---
## 🛠️ Blackpearl — Unit 8200's Toolkit

Blackpearl dideskripsikan oleh Kaspersky (2015-2017) sebagai toolkit yang digunakan oleh **Unit 8200 Israel** dalam operasi siber ofensif. Nama ini muncul dalam laporan tentang serangan terhadap target di Timur Tengah, Eropa, dan Asia.

### Kemampuan

| Modul | Fungsi |
|-------|--------|
| **Network Interception** | Man-in-the-Middle via BGP hijack atau kolusi ISP lokal. |
| **DNS Spoofing** | Memalsukan respons DNS untuk mengarahkan target ke server palsu. |
| **HTTP Injection** | Menyuntikkan iframe, script, atau redirect ke traffic HTTP target. |
| **Exploit Delivery** | Mengintegrasikan dengan exploit server (mirip FOXACID). |
| **Credential Harvesting** | Halaman login palsu untuk mencuri kredensial. |
| **Persistence** | Menjatuhkan implant (RAT) untuk akses jangka panjang. |

### Target Terdokumentasi

- **Diplomat dan politisi** di negara-negara Timur Tengah.
- **Ilmuwan nuklir Iran** (bagian dari kampanye Stuxnet dan sekitarnya).
- **Perusahaan keamanan siber** (Kaspersky melaporkan menjadi target Blackpearl pada 2015).
- **Jurnalis dan aktivis** di Palestina dan Lebanon.

### Hubungan Quantum Insert ↔ Blackpearl

Meskipun dinamai berbeda, teknik dasarnya identik: **race condition injection**. Perbedaan utama:
- **Quantum Insert** (NSA) dioperasikan oleh AS/UK.
- **Blackpearl** dioperasikan oleh Israel (Unit 8200).
- Keduanya berbagi TTP dan kemungkinan berbagi infrastruktur (dalam kerangka Five Eyes + Israel).

---

## 🔬 Teknik Spesifik dalam Quantum Insert / Blackpearl

### 1. BGP Hijack untuk Interception

Penyerang mengumumkan rute BGP palsu untuk mengalihkan traffic target melalui server mereka. Ini memungkinkan:
- **Full Man-in-the-Middle** pada semua traffic target.
- **SSL stripping**: Mengubah HTTPS menjadi HTTP untuk membaca plaintext.
- **Injeksi malware** ke download software.

**Kasus Terkenal:**
- 2013: BGP hijack digunakan untuk mengalihkan traffic dari penyedia layanan keuangan.
- 2018: Serangan BGP ke MyEtherWallet (kemungkinan aktor lain, tapi teknik identik).

### 2. DNS Poisoning / Spoofing

Blackpearl sering menggunakan **DNS poisoning** untuk mengarahkan target ke server palsu:
- Target mengetik `mail.google.com` → diarahkan ke IP penyerang.
- Halaman login palsu mencuri kredensial.
- Setelah login, implant dijatuhkan.

### 3. HTTP 302 Redirect Injection

Teknik paling umum:
- Target mengunjungi website berita.
- Quantum Insert menyuntikkan `HTTP 302 Redirect` ke `exploit-server.com/payload`.
- Target browser otomatis mengikuti redirect ke server exploit.
- Exploit (0-day atau n-day) menginfeksi target.

### 4. Iframe Injection

Untuk target yang lebih stealth:
- Alih-alih redirect penuh, Quantum Insert menyuntikkan **iframe 1x1 pixel** ke halaman yang sedang dimuat.
- Iframe memuat halaman exploit tanpa terlihat oleh target.
- Exploit berjalan di background.

### 5. Targeted Malware Delivery via Software Update

Jika target mengunduh software (installer, update), Quantum Insert bisa mengganti file yang diunduh dengan versi berbahaya yang sudah dimodifikasi. Ini adalah teknik **supply chain attack real-time**.

---

## 🕵️‍♂️ Operasi Terdokumentasi

### Operasi Olympic Games (Stuxnet, 2010)

Meskipun Stuxnet sendiri dikirim via USB dan network propagation, intelijen yang mendukung operasi ini (lokasi fasilitas, konfigurasi centrifuge) dikumpulkan melalui teknik Quantum Insert dan Blackpearl untuk memata-matai jaringan Iran.

### Operasi Against Kaspersky (2015)

Kaspersky melaporkan bahwa mereka menjadi target Blackpearl. Serangan menggunakan injeksi HTTP untuk mengarahkan karyawan Kaspersky ke halaman login palsu, mencoba mencuri kredensial internal.

### Operasi Duqu 2.0 (2015)

Malware Duqu 2.0 (terkait Unit 8200) menyebar melalui jaringan internal Kaspersky dan target lainnya di Iran. Infeksi awal diduga menggunakan teknik Quantum Insert di tingkat ISP.

### Operasi Rocket Man (2017)

Symantec mendokumentasikan serangan terhadap target di Timur Tengah menggunakan teknik HTTP injection untuk menjatuhkan malware.

---

## 🛡️ Countermeasures & Deteksi

### 1. Deteksi Race Condition Injection

| Metode | Detail |
|--------|--------|
| **Monitor TTL Anomali** | Response palsu sering memiliki TTL berbeda dari server sah. |
| **Deteksi Duplicate Response** | Target menerima dua respons HTTP (satu asli, satu palsu). |
| **Analisis Latency** | Response yang tiba "terlalu cepat" (lebih cepat dari geografis memungkinkan) bisa jadi injection. |
| **Certificate Mismatch** | Jika SSL stripping terjadi, sertifikat akan berubah dari valid ke self-signed. |

### 2. Deteksi BGP Hijack

- **BGPMon**, **Qrator**, **RIPE RIS** — layanan yang memonitor anomali BGP global.
- **Prefix hijack alert**: Jika prefix IP Anda tiba-tiba diumumkan oleh AS lain, alerting otomatis.
- **RPKI (Resource Public Key Infrastructure)**: Validasi kriptografis untuk otentikasi rute BGP.

### 3. Mitigasi

| Lapisan | Tindakan |
|---------|----------|
| **Transport** | Gunakan **HTTPS only** dengan HSTS (HTTP Strict Transport Security). Preload HSTS di browser. |
| **DNS** | Gunakan **DNSSEC** untuk mencegah DNS spoofing. Gunakan **DNS over HTTPS (DoH)** atau **DNS over TLS (DoT)**. |
| **BGP** | Terapkan **RPKI** untuk memvalidasi rute. Monitor BGP anomali. |
| **Browser** | Aktifkan **Enhanced Safe Browsing**. Gunakan browser yang mendeteksi redirect mencurigakan. |
| **Endpoint** | Deploy EDR yang mendeteksi proses browser yang tiba-tiba mengunduh dan mengeksekusi file. |
| **Network** | Monitor traffic untuk respons HTTP duplikat atau redirect ke domain tidak dikenal. |

### 4. Indikator Kompromi (IOC)

| Artefak | Detail |
|---------|--------|
| **Redirect chain** | Browser history menunjukkan redirect dari website sah ke domain tidak dikenal. |
| **DNS logs** | Query DNS untuk domain exploit (sering domain pendek, TLD tidak biasa). |
| **Certificate logs** | Sertifikat TLS yang tidak cocok dengan domain sah. |
| **NetFlow** | Koneksi ke IP tidak dikenal segera setelah mengunjungi website tertentu. |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Intelijen Defensif         Kontra-Terorisme         Serangan Ofensif
│                          │                        │
Memantau traffic           Mengalihkan              Menginfeksi target
untuk deteksi              komunikasi teroris       dengan malware,
ancaman di jaringan        untuk pengawasan         mencuri kredensial,
sendiri                    │                        eksfiltrasi data
│                          │                        │
│                          │                        ▼
▼                          ▼                        Operasi spionase,
Network monitoring         Targeted operation       sabotase (Stuxnet),
(Packetbeat, Zeek)         (warrant-based)          targeted assassination
```

Quantum Insert / Blackpearl adalah puncak dari kemampuan **active network attack**. Tidak seperti pengawasan pasif, teknik ini secara aktif mengubah traffic target — menjadikannya senjata ofensif yang sangat presisi.

---

## 🔗 Koneksi dalam Vault

- [[upstream-and-tempora]] — Backbone interception pasif yang menjadi fondasi untuk Quantum Insert (harus bisa melihat traffic dulu sebelum bisa menyuntikkan).
- [[foxacid]] — Server exploit delivery yang menjadi tujuan redirect dari Quantum Insert.
- [[quantum]] — Program NSA untuk active network attack, saudara dari Quantum Insert.
- [[verint]] — Verint menyediakan hardware untuk pemantauan traffic yang bisa digunakan untuk mendeteksi target sebelum Quantum Insert.
- [[pegasus]] — Quantum Insert bisa digunakan untuk mengarahkan target ke server yang mengeksploitasi browser, menjatuhkan implant seperti Pegasus.
- [[muscular]] — Operasi NSA/GCHQ untuk mengintersep link internal data center; Quantum Insert bisa digunakan untuk mengalihkan traffic ke titik intersep.

---

## 📚 Referensi

- Snowden, E. (2013). *NSA Documents: QUANTUM and FOXACID Programs* (The Guardian, Der Spiegel).
- Kaspersky. *Blackpearl: Unit 8200's Active Network Attack Toolkit* (2015-2017).
- Symantec. *Rocket Man: Targeted Attacks in the Middle East* (2017).
- Cimpanu, C. (2018). *BGP Hijack Used to Redirect Traffic to Malicious Sites*. ZDNet.
- MITRE ATT&CK: T1583.004 (Acquire Infrastructure: Server), T1584.004 (Compromise Infrastructure: Server), T1189 (Drive-by Compromise).

---

*Quantum Insert & Blackpearl Deep Dive | Unit 8200 Active Network Attack | BGP Hijack & Race Condition Injection*