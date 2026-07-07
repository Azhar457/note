---
title: "Pegasus"
tags:
  - 04-commercial-surveillance-and-spyware
  - library
  - military-and-intelligence-tools
aliases:
  - "pegasus"
created: "2026-06-27"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] KONTEKS ETIS & LEGAL
> Seluruh informasi di bawah bersumber dari publikasi terbuka: Citizen Lab, Amnesty International, Google Project Zero, Apple security updates, dan dokumen forensik publik. Pembahasan ini murni **edukasional dan defensif**. Penulisan ini tidak mendorong, mengajarkan, atau memfasilitasi pembuatan, distribusi, atau penggunaan spyware. Penggunaan teknologi serupa tanpa otorisasi eksplisit adalah ilegal di hampir seluruh yurisdiksi. Deteksi yang dijelaskan bertujuan untuk melindungi individu yang menjadi target.

## 🧬 Arsitektur Modular Pegasus

Pegasus bukan sekadar satu malware, melainkan **platform modular** dengan komponen terpisah:

| Komponen                         | Fungsi                                                                                                                          | Karakteristik                                                                                         |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Exploit Delivery**             | Mengirim 0-click exploit via iMessage, WhatsApp, FaceTime, SMS, atau network injection.                                         | Zero-interaction; korban tidak perlu membuka apapun.                                                  |
| **Stage 1 – “Finder”**           | Mengambil alih proses media (IMTranscoderAgent/SpringBoard) dan mengeksekusi shellcode via arbitrary code execution.            | Dipicu saat notifikasi pesan masuk memproses attachment (JBIG2, PDF, GIF).                            |
| **Stage 2 – “Jailbreak”**        | Eksploitasi kernel untuk privilege escalation ke root, melewati kode signing (AMFI), sandbox, dan KPP/KTRR.                     | Sering menggunakan bug di XNU kernel, IOKit, atau kelemahan PAC bypass.                               |
| **Stage 3 – “Agent Injector”**   | Memuat payload utama ke dalam proses tepercaya (trustd, CommCenter, SpringBoard) via dylib injection atau `dlopen` dari memori. | Menggunakan entitlement abuse (com.apple.security.iokit-user-client-class) untuk menghindari deteksi. |
| **Agent Core**                   | Modul permanen: keylogger, mic/camera capture, GPS tracking, kontak, message, email, file exfiltration, live calls.             | Berjalan sebagai daemon tersembunyi, berkomunikasi dengan C2 via TLS dengan domain fronting.          |
| **C2 Infrastructure**            | Server relay di cloud (AWS, Azure, Google) dan di negara dengan regulasi lemah.                                                 | Menggunakan protokol seperti XMPP, HTTP dengan header mimikri, dan kadang terowongan VPN.             |
| **Network Injection (Opsional)** | Memaksa target mengunduh exploit melalui BGP hijack atau kolusi ISP, bahkan tanpa mengirim pesan.                               | Memerlukan akses ke backbone atau ISP lokal.                                                          |

---

## 💀 Kill Chain Tahap Demi Tahap: FORCEDENTRY (CVE-2021-30860)

### 1. Vektor Awal: iMessage 0-Click

- Penyerang mengirim pesan iMessage yang mengandung **attachment JBIG2**.
- Pesan tidak perlu dibuka. Saat iOS menerima notifikasi, proses `IMTranscoderAgent` (yang berjalan di luar sandbox dengan hak tinggi) secara otomatis mem-parsing attachment untuk menghasilkan thumbnail.
- Parsing JBIG2 dilakukan oleh library `CoreGraphics` (atau komponen terkait) yang menangani gambar.

### 2. Eksploitasi Memori pada JBIG2 Decoder

- JBIG2 adalah format kompresi untuk gambar hitam-putih. Standar ini memiliki fitur “segmented decoding” dengan **operator aritmatika yang kompleks** dan **symbol dictionary**.
- Kerentanan CVE-2021-30860 terjadi karena pengelolaan **buffered stream** yang salah dalam implementasi Apple. Data input yang dibuat khusus menyebabkan **out-of-bounds write** pada heap.
- Secara teknis: decoder JBIG2 mempertahankan sebuah **context-state table** untuk adaptive binary arithmetic coding (QM coder). Dengan memanipulasi **symbol segment** yang direferensikan, penyerang dapat menimpa pointer fungsi di heap (misalnya dalam struktur `JBIG2Bitmap` atau `JBIG2Segment`). Overflow terjadi saat menyalin pixel data ke bitmap yang dialokasikan dengan ukuran yang tidak memadai.

```
Tahapan eksploitasi JBIG2:
1. Baca header JBIG2 -> segment 0 (symbol dictionary).
2. Crafted segment mengklaim ukuran bitmap kecil (misal 1x1), tapi mendekode jumlah pixel besar.
3. Penulisan piksel melampaui batas, menimpa metadata heap chunk berikutnya.
4. Korban menimpa 'vtable' atau 'function pointer' dalam struktur lain → redirect eksekusi ke shellcode.
```

- **Shellcode** yang diinjeksi berukuran kecil (~500 byte), melakukan ROP/JOP untuk bypass pointer authentication (PAC) jika ada, lalu menjalankan `os_thread_set_policy` dan `mach_msg` untuk memanggil kernel.

### 3. Privilege Escalation: Dari Non-root ke Kernel

- Setelah kode berjalan dalam konteks `IMTranscoderAgent` (yang sudah punya `com.apple.security.iokit-user-client-class`, `com.apple.private.skip-library-validation`, dan entitlement lain), penyerang mengeksploitasi kernel untuk mendapatkan root.
- Pada varian 2021, digunakan **CVE-2021-1782** (race condition di `IOSurfaceAccelerator`) atau **CVE-2021-30883** (memory corruption di `IOMobileFrameBuffer`). Keduanya memungkinkan arbitrary kernel read/write.
- Dengan akses kernel, mereka:
  - Menambahkan kredensial proses ke `kr_cred` root.
  - Menonaktifkan pemaksaan code signing dengan memodifikasi flag `csflags` pada slot proc.
  - Mem-bypass **KTRR** (Kernel Text Read-only Region) pada perangkat A12 ke atas dengan cara memodifikasi tabel halaman atau menggunakan hardware debug register jika tersedia (teknik serupa checkra1n).

### 4. Injeksi Agen dan Persistensi

- Pada tahap ini, executable agen (biasanya nama samaran seperti `jailbreakd`, `gssd`, atau `sysdiagnose`) ditulis ke `/private/var/root/` atau `/System/Library/`.
- Persistensi dicapai dengan dua metode:
  - **Launch Daemon**: Menulis file `.plist` ke `/System/Library/LaunchDaemons/` dengan `RunAtLoad` true. Ini hanya mungkin jika SIP (System Integrity Protection) dinonaktifkan, tetapi setelah jailbreak SIP sering kali sudah diretas.
  - **Process Injection**: Menyuntikkan dylib ke proses yang berjalan lama seperti `SpringBoard`, `CommCenter`, atau `trustd` dengan memanfaatkan `DYLD_INSERT_LIBRARIES` (biasanya diblokir oleh AMFI, namun setelah kernel exploit AMFI sudah dipatch). Selain itu, menggunakan `posix_spawn` dengan atribut `POSIX_SPAWN_START_SUSPENDED` dan task_for_pid untuk memodifikasi register dan memuat library.

- Agen lalu memuat modul-modul sesuai konfigurasi C2. Modul disimpan sebagai file `.dat` terenkripsi di `/private/var/db/uuidtext/` atau lokasi acak. Setiap boot, agen memeriksa keberadaan file tersebut.

### 5. Komunikasi C2 & Infrastruktur

- C2 server menerapkan **domain fronting**: traffic HTTPS ke CDN besar (Azure, CloudFront) dengan header Host yang berbeda sehingga tampak seperti traffic ke layanan umum.
- Protokol bisa berbasis **XMPP dengan framing khusus** atau **HTTP POST** dengan payload bzip2+AES. Heartbeat dikirim dalam interval yang diacak dengan jitter ±40%.
- Varian mutakhir memanfaatkan **TCP over WebRTC** atau bahkan **ICMP tunneling** saat jaringan seluler.
- **Network Injection**: Untuk menginfeksi tanpa mengirim pesan, NSO menggunakan teknik MITM di level ISP atau BGP. Saat target mengunjungi website apapun, traffic di-redirect ke server exploit yang menyajikan halaman berisi exploit Safari atau WebKit (0-click, saat render halaman). Ini membutuhkan kolaborasi dengan operator telekomunikasi atau peretasan router infrastruktur.

---

## 🔍 Deteksi Forensik: Mengidentifikasi Jejak Pegasus

### iShutdown.log – Detektor Cepat

Setelah infeksi, saat iPhone dimatikan, iOS menulis log ke `/private/var/db/diagnostics/shutdown.log`. Pada perangkat yang terinfeksi, sering muncul entri dari proses aneh yang gagal dimatikan atau melakukan re-spawn:

```
Perhatikan baris seperti:
"SIGTERM failed to terminate <Process X>"
"process (jailbreakd) is still running"
"dyld: Library not loaded: @executable_path/..."
```

Amnesty International mencatat **iShutdown** sebagai alat scanning yang memanfaatkan indikator tersebut. Pengguna cukup mengecek log setelah restart paksa.

### MVT (Mobile Verification Toolkit) – Analisis Backup iOS

MVT (dikembangkan Amnesty) membandingkan konten backup (enkripsi atau iTunes/Finder) dengan **STIX Indicators of Compromise (IOC)** yang dipublikasikan. Indikator utama:

1. **Indikator File System**:
   - Keberadaan file di lokasi tak biasa: `/private/var/root/Library/Preferences/com.apple.wifid.plist` yang dimodifikasi.
   - Folder `/private/var/wireless/Library/Databases/` berisi file `.db` dengan schema tak standar (misal: `DataUsage.db` ada tabel `netstats`).
   - `/private/var/protected/com.apple.CommCenter/` – modifikasi bisa mengindikasikan penyadapan panggilan.
   - Keberadaan executable tak dikenal di `/System/Library/LaunchDaemons/` atau `/Library/LaunchDaemons/` dengan nama samaran (misal: `com.apple.gssd.plist` padahal normalnya tidak ada).

2. **Analisis SMS/iMessage Attachment**:
   - MVT mengekstrak semua lampiran dari `chat.db` dan menghitung hash SHA-256. Cocokkan dengan database IOC untuk **payload JBIG2/PDF exploit** (misal hash file: `89f7c...`).
   - Pesan yang masuk dari nomor tak dikenal dengan attachment yang tidak diminta adalah red flag.

3. **Basis Data DataUsage**:
   - File `/private/var/wireless/Library/Databases/DataUsage.db` menyimpan riwayat pemakaian data per proses. Proses yang mencurigakan seperti `jailbreakd`, `gssd`, atau `sysdiagnose` yang memakan data signifikan meski bukan proses biasa.
   - Query: `SELECT * FROM ZLIVEUSAGE WHERE ZPROCESSNAME = 'gssd';` (nama bisa bervariasi).

4. **Lokasi dan Cache**:
   - `Cache.sqlite` di `/private/var/mobile/Library/Caches/com.apple.locationd/` mungkin menyimpan koordinat yang diambil oleh agen secara periodik.
   - Modifikasi pada `/private/var/mobile/Library/Preferences/com.apple.locationd.plist` yang mengaktifkan GPS meskipun dinonaktifkan oleh pengguna.

### Analisis Langsung (Jika Perangkat Dapat di-Jailbreak)

- **Lihat proses berjalan**: `ps aux | grep -E 'jailbreakd|gssd|sysdiagnose|dropbear'`
- **Periksa library yang diinjeksi ke proses sistem**: `vmmap SpringBoard | grep dylib` atau `otool -L /System/Library/CoreServices/SpringBoard.app/SpringBoard` untuk melihat `@rpath/agent.dylib`.
- **Memeriksa mount point**: Beberapa varian membuat ramdisk untuk menyembunyikan file. Cek `mount` untuk device yang tidak normal.
- **Koneksi jaringan**: `lsof -i -n -P` akan mengungkap koneksi ke IP aneh meski tidak ada aplikasi berjalan, biasanya ke port 443 dengan nama domain acak.

### Indikator Jaringan dan IOC

Citizen Lab mempublikasikan ribuan IOC: domain, IP, sertifikat TLS, dan JA3 hash. Beberapa domain yang pernah digunakan:

- `*.icloud-analysis.com`
- `*.whitepacket.com`
- `*.net-fx.info`
- IP range milik server cloud provider yang disewa NSO secara tidak langsung.

**JA3 fingerprint** dari TLS client juga bisa menjadi deteksi network-based. Konfigurasi Pegasus menggunakan cipher suite dan elliptic curve yang spesifik karena menggunakan library custom (bukan CFNetwork).

---

## 🛡️ Lockdown Mode vs Pegasus

Apple memperkenalkan **Lockdown Mode** (iOS 16+) sebagai perlindungan khusus untuk individu berisiko tinggi. Fitur yang mematikan banyak vektor serangan Pegasus:

- Menonaktifkan **thumbnail otomatis** di iMessage: pesan diproses tanpa decoding gambar secara langsung. Ini menghilangkan permukaan eksploitasi JBIG2 karena parser tidak dipanggil saat notifikasi.
- Memblokir **sebagian besar attachment iMessage** kecuali gambar tertentu yang sudah di-render aman.
- Menonaktifkan **kompleksitas WebKit**: JIT JavaScript dimatikan, pemrosesan font, dan WebGL. Network injection exploit modern sangat bergantung pada rendering kompleks.
- Memblokir **koneksi kabel** saat perangkat terkunci (USB Restricted Mode lebih agresif), sehingga GrayKey tidak berguna.
- Menonaktifkan **undangan FaceTime** jika penelepon tidak ada di kontak.

Lockdown Mode secara drastis memperkecil kill chain, tetapi tidak menjamin 100% karena exploit baru mungkin menghindari blokade ini.

---

## 📜 Sejarah Operasi dan Penyalahgunaan

- **2016** – Trident (CVE-2016-4655/4656/4657) digunakan terhadap aktivis UEA, Ahmed Mansoor. Citizen Lab menemukan 0-click via SMS.
- **2019** – WhatsApp menyampaikan bahwa NSO menggunakan bug panggilan WhatsApp untuk mengirim Pegasus ke ~1,400 orang.
- **2021** – Proyek Pegasus: konsorsium 17 media melaporkan 50.000 nomor terpilih, termasuk jurnalis, oposisi, diplomat. Digunakan secara luas oleh pemerintah otoriter.
- **2022** – Citizen Lab mendokumentasikan penggunaan FORCEDENTRY pada iOS 15 tanpa Lockdown Mode; Apple memperbaiki CVE-2021-30860.
- **2023-2024** – Muncul varian baru yang mengeksploitasi “Find My” network (KISMET) dan HomeKit; belum ada rincian teknis publik.

---

## ↔️ Dual-Use Context

Pegasus dipasarkan oleh NSO Group sebagai alat **law enforcement dan intelijen** untuk memberantas terorisme dan kriminalitas berat. Namun, penyalahgunaan yang meluas membuatnya secara de facto menjadi **alat represi**. Dari perspektif defensive, memahami mekanismenya memungkinkan pembangunan perlindungan (Lockdown Mode, MVT) dan forensik. Bagi red team atau peneliti keamanan, studi exploit ini mendorong penambalan dan arsitektur OS yang lebih aman.

---

## 🔗 Koneksi ke Tool Lain dalam Vault

- [[xkeyscore]] — Pegasus C2 traffic bisa terdeteksi oleh platform SIGINT global; namun NSO menggunakan domain fronting untuk menghindarinya.
- [[cellebrite-ufed]] / [[graykey]] — Digunakan law enforcement untuk unlock perangkat setelah spyware gagal diekstraksi; hierarki forensik yang sama.
- [[cobalt-strike]] — Perbandingan antara surveillance malware mobile (Pegasus) dan C2 untuk desktop/server; sama-sama modular dan membutuhkan malleable profile.
- [[verint]] — Intercept komunikasi suara; Pegasus juga bisa merekam panggilan langsung dari baseband processor.
- [[victoria-hdd|Victoria]] — Forensik HDD tidak relevan di mobile, tetapi konsep pre-imaging verification mirip: forensik digital sebelum analisis.
- **OSINT Hierarchy** — OSINT berguna untuk mencari infrastruktur C2 Pegasus melalui Shodan, Maltego, dan analisis DNS.

---

## 📚 Referensi & Bacaan Lanjut

- Citizen Lab, _Pegasus Project_ (2021–2023)
- Google Project Zero, _FORCEDENTRY: Sandbox Escape & 0-Click iMessage_ (CVE-2021-30860) – Ian Beer & Samuel Groß
- Amnesty International, _Forensic Methodology Report: Detecting Pegasus with MVT_
- Apple Security Engineering, _Lockdown Mode Technical Brief_ (2022)
- Siguza, _iOS Kernel Exploitation: Advanced PAC Bypass_ (2023)
- NSO Group, _Transparency Report_ (hanya klaim legal, tidak ada detail teknis)

---

_Pegasus Spyware Deep Dive | FORCEDENTRY Kill Chain | Mobile Surveillance Defensive Framework_
