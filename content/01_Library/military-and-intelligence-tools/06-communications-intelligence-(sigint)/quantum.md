---
title: Quantum
tags:
  - 06-communications-intelligence-(sigint)
  - library
  - military-and-intelligence-tools
created: "2026-06-28"
updated: "2026-07-01"
status: pending
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> QUANTUM adalah program ofensif jaringan aktif milik NSA yang diungkap oleh Edward Snowden pada 2013. Informasi di bawah berasal dari dokumen yang bocor, analisis forensik oleh peneliti keamanan, serta laporan threat intelligence. Pembahasan ini murni **edukasional dan defensif**. Tidak ada instruksi atau advokasi untuk melakukan serangan serupa. Tujuan: membekali defender dengan pemahaman tentang ancaman injeksi jaringan tingkat negara.

---

## 🧬 Apa Itu QUANTUM?

QUANTUM adalah **program ofensif jaringan aktif NSA** yang memungkinkan agen untuk **mengalihkan, mencegat, dan memanipulasi traffic internet secara real-time**. Ini adalah salah satu program paling rahasia NSA yang diungkap oleh Edward Snowden, dan merupakan fondasi teknis dari banyak operasi mata-mata digital AS.

Jika UPSTREAM dan TEMPORA adalah pengawasan pasif (mendengarkan), QUANTUM adalah **pengawasan ofensif** — ia **mengubah** traffic yang sedang berjalan untuk mengarahkan target ke server exploit (FOXACID) atau menyuntikkan malware langsung ke sesi browsing mereka.

### QUANTUM vs QUANTUM Insert

Sering ada kebingungan antara istilah ini:

| Istilah               | Makna                                                      |
| --------------------- | ---------------------------------------------------------- |
| **QUANTUM (program)** | Program NSA secara keseluruhan untuk network attack aktif. |
| **QUANTUM Insert**    | Teknik spesifik: HTTP race condition injection.            |
| **QUANTUM Theory**    | Teknik BGP hijack untuk mengalihkan traffic.               |
| **QUANTUM DNS**       | DNS poisoning/spoofing untuk mengarahkan ulang target.     |

QUANTUM adalah **payung besar**, sedangkan QUANTUM Insert, QUANTUM Theory, dan QUANTUM DNS adalah teknik-teknik di bawahnya.

---

## 🏗️ Arsitektur QUANTUM

QUANTUM bergantung pada **posisi strategis di backbone internet**. NSA menempatkan server QUANTUM di titik-titik pertukaran internet (IXP) utama dan di dalam jaringan operator telekomunikasi besar (AT&T, Verizon, dll. melalui program FAIRVIEW dan STORMBREW).

### Komponen Utama

| Komponen                | Fungsi                                                                                  |
| ----------------------- | --------------------------------------------------------------------------------------- |
| **QUANTUM Server**      | Server yang memonitor traffic backbone secara real-time dan menyuntikkan respons palsu. |
| **QUANTUM BGP Engine**  | Untuk mengumumkan rute BGP palsu dan mengalihkan traffic target.                        |
| **QUANTUM DNS Engine**  | Untuk melakukan DNS spoofing terhadap permintaan target.                                |
| **Target Database**     | Berisi selector (IP, cookie, username) dari target yang telah diidentifikasi.           |
| **FOXACID Integration** | Integrasi langsung dengan server exploit delivery FOXACID.                              |
| **TURBINE Integration** | Integrasi dengan sistem manajemen implant otomatis.                                     |

### Arsitektur Alur Serangan

```
[Target] ── HTTP/DNS Request ──► [Internet] ──► [Server Asli]
   │                                │
   │                                ▼
   │                     [QUANTUM Server di Backbone]
   │                     (Monitor traffic, cocokkan
   │                      dengan Target Database)
   │                                │
   │                     ┌──────────┼──────────┐
   │                     ▼          ▼          ▼
   │              [Match!]    [No Match]   [Error]
   │                     │
   │                     ▼
   │              [QUANTUM Action]
   │         (Pilih teknik terbaik:
   │          - Race condition injection
   │          - BGP hijack
   │          - DNS poisoning)
   │                     │
   └─────────────────────┘
                         │
                         ▼
                [Target menerima respons palsu]
                         │
                         ▼
                [Target diarahkan ke FOXACID
                 atau langsung menerima malware]
```

---

## 🔬 Teknik Serangan QUANTUM

### 1. QUANTUM Insert (HTTP Race Condition Injection)

Ini adalah teknik paling umum dan sudah dibahas secara mendalam di dokumen [[quantum-insert-and-blackpearl]].

**Ringkasan:**

- QUANTUM memonitor traffic HTTP target.
- Ketika target melakukan GET ke website tertentu, QUANTUM mengirimkan respons HTTP 302 Redirect palsu.
- Respons palsu harus menang **race condition** dengan respons server asli (QUANTUM lebih dekat ke target secara jaringan).
- Target diarahkan ke server FOXACID.

**Keunggulan:**

- Cepat (milidetik).
- Tidak memerlukan BGP hijack.
- Bekerja pada traffic yang tidak terenkripsi (HTTP) atau jika SSL bisa di-bypass.

### 2. QUANTUM Theory (BGP Hijack)

Teknik ini jauh lebih kuat dan memungkinkan pengalihan **semua traffic target**, bukan hanya HTTP.

**Cara Kerja:**

1. NSA memiliki akses ke router BGP di beberapa ISP besar (melalui program FAIRVIEW/STORMBREW).
2. Untuk mengalihkan traffic target, NSA mengumumkan **BGP prefix yang lebih spesifik** untuk IP server yang menjadi tujuan target.
3. Karena prefix yang lebih spesifik menang dalam routing BGP, traffic target dialihkan melalui router NSA.
4. NSA sekarang menjadi **Man-in-the-Middle** penuh — bisa melihat, memodifikasi, atau mengalihkan traffic.

**Contoh:**

- Target ingin mengakses `mail.google.com` (IP: 142.250.185.206).
- NSA mengumumkan prefix `142.250.185.206/32` (lebih spesifik dari /24 milik Google).
- Traffic dialihkan ke server NSA.
- NSA bisa menyajikan halaman login palsu, mengintersep kredensial, atau mengalihkan ke FOXACID.

**Keunggulan:**

- Bisa mengintersep traffic terenkripsi (HTTPS) jika target menerima sertifikat palsu.
- Tidak bergantung pada race condition.
- Bisa menarget semua protokol (HTTP, HTTPS, SMTP, FTP, dll.).

**Kelemahan:**

- Lebih mudah terdeteksi (BGP monitoring).
- Memerlukan akses ke router BGP besar.
- Hanya bisa dilakukan untuk waktu singkat (menit/jam) sebelum terdeteksi.

### 3. QUANTUM DNS (DNS Poisoning / Spoofing)

Teknik ini mengalihkan target dengan memalsukan respons DNS.

**Cara Kerja:**

1. QUANTUM memonitor permintaan DNS target.
2. Ketika target meminta resolusi `www.target-website.com`, QUANTUM mengirimkan respons DNS palsu dengan IP server FOXACID/NSA.
3. Browser target terhubung ke IP palsu, mengira itu adalah website asli.

**Keunggulan:**

- Tidak perlu race condition di layer HTTP.
- Bisa mengalihkan seluruh domain, bukan hanya satu halaman.

**Kelemahan:**

- Hanya berfungsi jika permintaan DNS tidak terenkripsi (DNSSEC dan DoH/DoT mempersulit).
- Cache DNS di resolver lokal bisa menyimpan respons asli.

---

## 🧠 QUANTUM + FOXACID + TURBINE: Trio Serangan Otomatis

QUANTUM tidak beroperasi sendiri. Ia adalah bagian dari **triad serangan otomatis NSA**:

```
[Target] ────► [QUANTUM] ────► [FOXACID] ────► [TURBINE]
  │                │                │                │
  │                │                │                └── Manajemen implant
  │                │                └── Payload delivery      otomatis
  │                └── Redirect/Traffic hijack
  └── Target browsing internet
```

1. **QUANTUM** mendeteksi dan mengalihkan traffic target.
2. **FOXACID** menerima target, melakukan fingerprinting, dan mengirimkan exploit.
3. **TURBINE** mengelola implant yang berhasil ditanamkan — menyediakan C2, mengumpulkan data, dan memungkinkan operator mengakses target.

Ketiganya terintegrasi secara real-time: QUANTUM mendeteksi target dalam milidetik, FOXACID menginfeksi dalam detik, TURBINE mengonfirmasi infeksi dalam menit.

---

## 📊 Skala Operasi QUANTUM

Dokumen Snowden mengungkapkan skala QUANTUM yang masif:

| Metrik                    | Angka (Estimasi 2012-2013)                                 |
| ------------------------- | ---------------------------------------------------------- |
| **Server QUANTUM global** | Puluhan (di lokasi strategis)                              |
| **Target per hari**       | Ribuan                                                     |
| **Jenis target**          | Diplomat, militer, ilmuwan, jurnalis, administrator sistem |
| **Infrastruktur**         | FAIRVIEW (AT&T), STORMBREW (Verizon), mitra Five Eyes      |
| **Negara target**         | China, Rusia, Iran, Korea Utara, Venezuela, dan lainnya    |

QUANTUM digunakan untuk:

- **Mata-mata diplomatik**: Menginfeksi kedutaan dan misi diplomatik.
- **Kontra-terorisme**: Mengalihkan komunikasi teroris ke server NSA.
- **Spionase ekonomi**: Mengintersep komunikasi perusahaan asing.
- **Penegakan sanksi**: Memata-matai entitas yang melanggar sanksi internasional.

---

## 🔍 Deteksi & Countermeasures

### 1. Deteksi QUANTUM Insert (Race Condition)

| Metode                 | Detail                                                                        |
| ---------------------- | ----------------------------------------------------------------------------- |
| **TTL Analysis**       | Response palsu sering memiliki TTL berbeda dari server asli.                  |
| **Duplicate Response** | Target menerima dua respons HTTP (302 redirect + 200 OK asli).                |
| **Network Timing**     | Response yang tiba "terlalu cepat" (lebih cepat dari geografis memungkinkan). |

### 2. Deteksi BGP Hijack (QUANTUM Theory)

| Metode              | Alat                                                                                |
| ------------------- | ----------------------------------------------------------------------------------- |
| **BGP Monitoring**  | BGPMon, Qrator, RIPE RIS — alert jika prefix Anda tiba-tiba diumumkan oleh AS lain. |
| **RPKI Validation** | Resource Public Key Infrastructure — memvalidasi otorisasi rute BGP.                |
| **Latency Spike**   | Rerouting traffic melalui NSA akan menambah latency.                                |

### 3. Deteksi DNS Spoofing

| Metode                | Alat                                                               |
| --------------------- | ------------------------------------------------------------------ |
| **DNSSEC Validation** | Memvalidasi respons DNS dengan tanda tangan kriptografis.          |
| **Response Mismatch** | DNS respons dari IP yang tidak dikenal (bukan resolver tepercaya). |

### 4. Countermeasures Umum

| Lapisan                 | Tindakan                                                                |
| ----------------------- | ----------------------------------------------------------------------- |
| **HTTPS + HSTS**        | Mencegah HTTP race condition injection. Preload HSTS.                   |
| **DoH/DoT**             | DNS over HTTPS / DNS over TLS mencegah DNS spoofing.                    |
| **RPKI**                | Operator jaringan harus menerapkan RPKI untuk mencegah BGP hijack.      |
| **VPN/Tor**             | Menyembunyikan IP target dan mengenkripsi traffic, mempersulit QUANTUM. |
| **Certificate Pinning** | Mencegah MITM dengan sertifikat palsu.                                  |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Kontra-Terorisme          Intelijen Luar Negeri     Serangan ofensif
│                         │                        │
Mengalihkan traffic       Memata-matai             Menanamkan implant
teroris untuk             musuh asing              untuk sabotase
pengawasan                                        atau perang siber
│                         │                        │
│                         │                        ▼
▼                         ▼                        QUANTUM Theory
Operasi sah               Spionase                 (BGP hijack) adalah
(dengan warrant)          (kontroversial)          pelanggaran serius
                                                   kedaulatan internet
```

QUANTUM, terutama QUANTUM Theory (BGP hijack), adalah eskalasi ofensif yang sangat kontroversial. Mengumumkan rute BGP palsu adalah tindakan yang melanggar norma internet global dan dianggap sebagai **serangan terhadap infrastruktur internet itu sendiri**.

---

## 🔗 Koneksi dalam Vault

- [[foxacid]] — QUANTUM adalah trigger redirect; FOXACID adalah payload delivery. Keduanya adalah satu kesatuan.
- [[quantum-insert-and-blackpearl]] — Dokumen tersebut membahas teknik QUANTUM Insert secara mendalam; dokumen ini fokus pada program QUANTUM secara keseluruhan.
- [[upstream-and-tempora]] — Backbone interception pasif yang menjadi fondasi untuk QUANTUM (harus bisa melihat traffic sebelum bisa mengalihkan).
- [[muscular]] — Intersep internal data center; QUANTUM digunakan untuk mengalihkan traffic ke titik MUSCULAR.
- `BGP Hijack` — QUANTUM Theory adalah implementasi BGP hijack yang paling canggih.
- [[drfm]] — DRFM meniru sinyal radar; QUANTUM meniru respons jaringan. Prinsip spoofing yang identik di domain berbeda.

---

## 📚 Referensi

- Snowden, E. (2013). _NSA Documents: QUANTUM, FOXACID, and TURBINE_ (The Guardian, Der Spiegel).
- Gallagher, R. (2014). _How the NSA Plans to Infect Millions of Computers with Malware_. The Intercept.
- Cimpanu, C. (2018-2023). _BGP Hijack Incidents: Analysis and Attribution_. ZDNet.
- MITRE ATT&CK: T1583.004 (Acquire Infrastructure: Server), T1189 (Drive-by Compromise), T1557 (Man-in-the-Middle).

---

_QUANTUM (NSA) Deep Dive | Active Network Attack & BGP Hijack Program | SIGINT Offensive Operations_
