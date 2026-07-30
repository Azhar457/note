---
title: Cobalt Strike
tags:
- 03-c2-and-post-exploitation
- library
- military-and-intelligence-tools
created: '2026-06-27'
updated: '2026-07-01'
status: pending
cssclasses: ''
---

> [!warning] Konteks Etis & Legal
> Cobalt Strike adalah platform komersial berlisensi yang dirancang untuk adversary simulation dan red teaming. Seluruh informasi di bawah berasal dari dokumentasi publik, penelitian akademis, serta laporan reverse engineering oleh komunitas keamanan. Pembahasan ini murni **edukasional dan defensif**. Penggunaan Cobalt Strike tanpa lisensi resmi, atau penggunaan untuk menyerang sistem tanpa otorisasi tertulis, adalah pelanggaran hukum. Dokumen ini bertujuan membekali defender dengan pengetahuan mendalam untuk mendeteksi dan merespons ancaman berbasis Cobalt Strike.

---

## 🧬 Apa Itu Cobalt Strike Secara Teknis?

Cobalt Strike (CS) adalah **platform komersial untuk adversary simulation dan operasi red team** yang dikembangkan oleh Raphael Mudge (Strategic Cyber LLC, diakuisisi oleh HelpSystems). Tidak seperti Metasploit yang bersifat general-purpose, Cobalt Strike dirancang dari awal untuk mensimulasikan **advanced persistent threat (APT)** dengan fokus pada:

- **Command & Control (C2) fleksibel** dengan profil komunikasi yang dapat sepenuhnya disesuaikan (*Malleable C2*).
- **Post-exploitation kit** yang kaya: keylogging, screenshot, process injection, port scanning, lateral movement, pivoting.
- **Evasion canggih**: sleep mask, user-defined reflective loader (UDRL), indirect syscall, BOF (Beacon Object Files).
- **Kolaborasi multipengguna**: server tim (team server) dengan shared session, logging, dan reporting.

Komponen inti Cobalt Strike dapat digambarkan sebagai arsitektur klien-server yang terdistribusi:

```
┌──────────────────────────────────────────────────────────────┐
│                   Operator Workstation                        │
│  (Cobalt Strike Client - GUI / Aggressor Script)              │
└────────────────────────┬─────────────────────────────────────┘
                         │ (terenkripsi, biasanya via SSH tunnel)
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                      Team Server                              │
│  (Java-based, mengelola listener, sessions, database)         │
│  - Mendengarkan koneksi dari Beacon                           │
│  - Meneruskan perintah operator ke Beacon                    │
│  - Menyimpan kredensial, log, dan hasil penugasan             │
└────────────────────────┬─────────────────────────────────────┘
                         │ (melalui Malleable C2 profile)
                         ▼
┌──────────────────────────────────────────────────────────────┐
│               Beacon (Agent pada target)                      │
│  - Reflective DLL, in-memory, tanpa sentuh disk              │
│  - Komunikasi HTTP/HTTPS/DNS/SMB/TCP                         │
│  - Mendukung C2 via domain fronting, proxy, redirector       │
│  - Modul: keylogger, hashdump, screenshot, execute-assembly  │
└──────────────────────────────────────────────────────────────┘
```

### Team Server: Jantung Operasi

Team server adalah proses Java yang mengikat pada port (default 50050 untuk koneksi klien). Seluruh komunikasi antara operator dan team server dienkripsi menggunakan **AES-256 dengan pertukaran kunci RSA**. Team server tidak pernah menyimpan kunci pribadi RSA dalam file; ia dihasilkan setiap kali server dimulai, sehingga kompromi terhadap server mati tidak membongkar komunikasi historis (forward secrecy tidak penuh, tapi cukup).

Team server mengelola:
- **Beacon listeners** (satu atau lebih, masing-masing dengan profil C2 berbeda).
- **Database sessions**: setiap Beacon yang terkoneksi disimpan lengkap dengan metadata (IP, OS, user, last checkin).
- **Credential store**: password dan hash yang dicuri otomatis di-log.
- **Reporting engine**: log aktivitas operator untuk keperluan debriefing.

Operator berinteraksi menggunakan **Cobalt Strike Client** (GUI) atau melalui **aggressor script** (bahasa berbasis Sleep, mirip Perl) untuk otomatisasi. Contoh: auto-migrate ke proses `lsass.exe` saat sesi baru, auto-screenshot setiap 30 menit, atau auto-exfiltrate file tertentu.

---

## 🦠 Beacon: Payload Multi-Tahap yang Tidak Menyentuh Disk

Beacon adalah payload utama Cobalt Strike. Ia dirancang agar **tidak pernah menulis executable ke disk**. Siklus hidup Beacon:

### 1. Stager (Opsional)
- Untuk payload yang dikirim via exploit atau phishing, stager adalah shellcode kecil (~300-800 bytes) yang bertugas mengunduh Beacon penuh dari C2.
- Stager biasanya menggunakan WinINet API (`InternetConnectA`, `HttpOpenRequestA`, `InternetReadFile`) untuk melakukan GET ke URI yang ditentukan, lalu mengeksekusi payload yang diterima di memori.
- **Stagerless Beacon**: Opsi yang lebih stealth. Beacon lengkap dikirim langsung sebagai payload (misal dalam makro VBA, atau di dalam exploit buffer). Tidak ada permintaan HTTP tambahan yang mencurigakan.

### 2. Reflective DLL Injection
Beacon adalah DLL yang memuat dirinya sendiri di memori tanpa menggunakan Windows Loader resmi. Teknik ini, yang dipopulerkan oleh Stephen Fewer, memungkinkan DLL untuk:
- Mengalokasikan memori di proses target (atau dirinya sendiri jika dijalankan sebagai executable).
- Menyalin header PE dan section ke memori yang dialokasikan.
- Memproses relokasi dan tabel impor secara manual.
- Memanggil `DllMain` dari alamat baru.

Karena tidak ada pemanggilan `LoadLibrary`, DLL tidak terdaftar di module list (kecuali jika diinjection ke proses lain dan di-walk oleh EDR yang canggih). Struktur `PEB->Ldr` tidak berisi entri untuk Beacon.

### 3. C2 Initialization
Setelah Reflective DLL entry point dipanggil, Beacon akan:
- Membaca konfigurasi yang telah disematkan di dalam payload (terenkripsi XOR atau AES, kadang RC4).
- Konfigurasi mencakup: C2 server, port, URI untuk GET/POST, User-Agent, sleep time, jitter, public key untuk kriptografi session.
- Memulai loop komunikasi: tidur (sleep + jitter) → bangun → periksa task dari server → kirim respons → tidur lagi.

### 4. Session Cryptography
Beacon dan team server melakukan **pertukaran kunci berbasis RSA** (asymmetric) di awal untuk menghasilkan kunci sesi AES-256. Setelah itu, semua metadata dan task payload dienkripsi menggunakan AES dalam mode CBC atau CTR, lalu dienkodekan menjadi Base64 atau bentuk lain sesuai Malleable C2.

---

## 📜 Malleable C2: Jantung Stealth Cobalt Strike

Fitur yang benar-benar membedakan Cobalt Strike dari C2 lain adalah **Malleable C2 profile**. Profil ini adalah file teks dengan sintaks khusus yang mendeskripsikan bagaimana Beacon berkomunikasi dengan team server pada level protokol HTTP/HTTPS.

Malleable C2 memungkinkan operator untuk mengubah **setiap byte** di wire agar menyerupai lalu lintas aplikasi yang sah (misalnya: Microsoft Teams, Google APIs, Facebook, Dropbox, atau bahkan traffic kustom yang tidak terdeteksi).

### Anatomi File Malleable C2

File Malleable C2 biasanya memiliki ekstensi `.profile` dan terdiri dari beberapa blok:

```
# Contoh potongan profil untuk meniru Microsoft Teams
set sleeptime "45000";          # tidur 45 detik
set jitter    "37";             # variasi ±37% -> tidur antara 28s - 62s
set useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ... Teams/1.4.00.35564";
set host_stage "false";         # matikan stager staging via HTTP

http-get {
    set uri "/api/v1/teams/conversations";
    client {
        header "Accept" "application/json";
        header "X-Client-Version" "1.4.00.35564";
        parameter "auth" "token";
        metadata {
            base64url;
            prepend "Bearer ";
            header "Authorization";
        }
    }
    server {
        header "Content-Type" "application/json";
        output {
            # Task dari server akan dikirim dalam body JSON palsu
            print;
        }
    }
}

http-post {
    set uri "/api/v1/teams/messages";
    client {
        header "Content-Type" "application/json";
        id {
            base64url;
            parameter "messageId";
        }
        output {
            base64url;
            print;
        }
    }
    server {
        output {
            print;
        }
    }
}
```

**Penjelasan blok utama:**

| Blok | Fungsi | Contoh |
|------|--------|--------|
| `http-get` | Cara Beacon mengambil task (download) dari C2. | URI seperti `/api/v1/teams/conversations`, metadata diselipkan di header `Authorization` sebagai Bearer token. |
| `http-post` | Cara Beacon mengirim hasil eksekusi task (upload) ke C2. | URI `/api/v1/teams/messages`, data dikirim di body, dienkode, dengan parameter `messageId` sebagai ID. |
| `http-stager` | (Opsional) Konfigurasi untuk stager saat mengunduh Beacon penuh. | Dapat diatur terpisah, misalnya URI `/update/check`. |
| `metadata` | Blok di dalam `client` untuk transmisi informasi sesi Beacon (IP internal, user, PID, dll.) dalam setiap request. | Bisa dienkode base64url dan diletakkan di cookie, header, atau parameter URI. |
| `output` | Transformasi data output (task) dari server atau data hasil dari klien. | Bisa `base64url`, `base64`, `xor`, `netbios`, atau `print` untuk langsung. |
| `transforms` | Operasi modifikasi pada data sebelum dikirim: XOR dengan kunci, AES encrypt dengan kunci statis, mask, dll. | Blok `transforms { xor "mykey"; base64; }` |

### Parameter Penting dalam Profil

- **`sleeptime`**: Waktu tidur Beacon dalam milidetik. Default 60000 (60 detik). Semakin lama semakin stealth tetapi semakin lambat interaksi.
- **`jitter`**: Persentase variasi random pada `sleeptime`. Jitter 30% pada sleep 60 detik = Beacon akan tidur antara 42 detik sampai 78 detik. Ini menghindari deteksi pola interval tetap.
- **`useragent`**: User-Agent string yang digunakan Beacon. Harus konsisten dengan aplikasi yang ditiru.
- **`host_stage`**: Jika `true`, Beacon akan mencoba mengunduh stage dari C2 lain jika koneksi utama gagal. Menonaktifkan (`false`) mengurangi jejak jaringan.
- **`pipename`**: Nama named pipe untuk komunikasi SMB Beacon internal (pivoting).

### Contoh Profil Malware Nyata yang Ditiru

Cobalt Strike sering dikonfigurasi untuk meniru:
- **Microsoft Update**: `GET /msdownload/update/v3/static/trustedr/en/disallowedcertstl.cab`
- **Azure CDN**: `GET /azure/portal/update/...` dengan header khas Azure.
- **Google APIs**: `POST /calendar/v3/calendars/...`
- **Amazon CloudFront**: `GET /assets/css/main.css?version=...`

Setiap elemen — URI, header, body, parameter, enkoding — sepenuhnya di bawah kendali operator. Inilah mengapa deteksi berbasis signature statis (seperti Snort rule `alert tcp any any -> any 80 (content:"/api/v1/teams/conversations"; ...)`) sangat mudah dihindari.

---

## 🛠️ Post-Exploitation Kit yang Kaya

Setelah Beacon aktif, operator memiliki akses ke puluhan perintah built-in. Beberapa yang paling sering digunakan:

| Perintah | Fungsi | Teknik MITRE |
|----------|--------|---------------|
| `shell` | Eksekusi perintah via `cmd.exe /c` | T1059.003 |
| `powershell` | Jalankan skrip PowerShell (unmanaged PowerShell, tanpa powershell.exe) | T1059.001 |
| `execute-assembly` | Muat dan eksekusi .NET assembly di memori tanpa `execute` file | T1055.001, T1218 |
| `keylogger` | Mulai/matikan keylogger; hasil dikirim via C2 | T1056.001 |
| `screenshot` | Ambil screenshot desktop, bisa periodik | T1113 |
| `hashdump` | Dump hash NTLM dari SAM dan cache domain | T1003.002 |
| `logonpasswords` | Jalankan Mimikatz untuk ekstrak password plaintext, hash, kerberos ticket | T1003.001 |
| `steal_token` | Curi token akses proses lain untuk impersonasi | T1134.001 |
| `make_token` | Buat token logon dengan kredensial yang diketahui | T1134.003 |
| `portscan` | Port scanning internal via Beacon (TCP/SYN/ARP) | T1046 |
| `browser_pivot` | Pivot ke browser korban untuk mengakses aplikasi internal | T1185 |
| `psexec` / `wmi` / `winrm` | Lateral movement ke host lain | T1021.002 / T1047 / T1021.006 |
| `spawn` / `inject` | Suntikkan Beacon ke proses lain | T1055 |

### Execute-Assembly: .NET di Memori

Salah satu fitur paling kuat dan evasif adalah `execute-assembly`. Ini memungkinkan operator memuat executable .NET (seperti Seatbelt, Rubeus, atau SharpHound) sepenuhnya di dalam memori proses Beacon, **tanpa** memanggil `CreateProcess` atau menulis file ke disk. Teknik ini memanfaatkan CLR Hosting: Beacon memuat .NET runtime, memanggil assembly dari byte array, dan mengembalikan hasilnya melalui C2.

### BOF (Beacon Object Files)

BOF adalah mekanisme eksekusi kode C terkompilasi dalam Beacon secara aman. Tidak seperti `execute-assembly` yang memerlukan CLR penuh, BOF berjalan di thread Beacon sendiri. BOF ditulis sebagai C file yang mengekspor fungsi dengan signature `void go(char* args, int len)`. Setelah dikompilasi menjadi objek COFF, BOF diunggah ke Beacon dan dieksekusi. Ini sangat ringan dan tidak meninggalkan jejak proses terpisah.

---

## 🛡️ Teknik Evasion di Cobalt Strike

### 1. Sleep Mask
Saat Beacon tidur, ia harus menyimpan state di memori. Secara default, string dan data terenkripsi AES, tetapi kode Beacon itu sendiri tetap dalam plaintext di memori. **Sleep mask** adalah fitur yang mengaburkan kode Beacon saat tidur dengan cara:

- Mengalokasikan dua region memori: satu untuk kode Beacon, satu untuk stub yang berisi routine enkripsi/dekripsi.
- Saat akan tidur: Beacon mengenkripsi region kode Beacon dengan algoritma XOR atau RC4 menggunakan kunci acak, lalu menyimpan kunci di stub. Lalu ia melompat ke stub dan tidur.
- Saat bangun: stub mendekripsi kode Beacon, lalu melompat kembali ke Beacon.

Akibatnya, EDR yang melakukan memory scan pada saat tidur hanya akan menemukan kode terenkripsi atau stub kecil yang tidak signifikan.

**Konfigurasi Sleep Mask:**
```
set sleep_mask "true";
set sleep_mask_uri "/path/to/custom_sleep_mask.bin";
```

Cobalt Strike 4.7+ mengizinkan sleep mask kustom yang ditulis dalam C dan dikompilasi menjadi `.bin` (dengan tool `sleepmaskkit`). Ini memungkinkan operator merancang enkripsi sendiri.

### 2. User-Defined Reflective Loader (UDRL)
Reflective loader default Cobalt Strike sudah dikenal oleh EDR. UDRL memungkinkan operator mengganti cara DLL memuat dirinya sendiri. Misalnya, loader kustom dapat:
- Menghindari pemanggilan API tertentu yang dipantau EDR (misal: `VirtualAlloc` → `NtAllocateVirtualMemory` indirect syscall).
- Memuat dengan teknik berbeda (module stomping: menimpa DLL sah yang sudah dimuat, bukan alokasi baru).
- Mengaburkan header PE di memori.

### 3. Indirect Syscalls
Pada Windows 10/11, EDR sering mengaitkan (`hook`) fungsi `ntdll.dll` untuk memonitor panggilan system call. Cobalt Strike versi terbaru mendukung **indirect syscalls** di mana Beacon secara manual mengeksekusi instruksi `syscall` tanpa melewati `ntdll.dll` yang terpantau. Ia mengambil syscall number dan stub dari disk sendiri (dengan memparsing `ntdll.dll` dari disk di mode user, tapi memanggil syscall langsung). Ini mem-bypass banyak hook EDR.

### 4. Malleable C2 Prepend/Append & Transforms
Data Beacon bisa dimodifikasi sebelum transmisi untuk menghindari DPI (Deep Packet Inspection). Contoh:
```
transforms {
    xor "0xDEADBEEF";
    base64url;
    prepend "\x01\x00\x00\x00";
    append "\x0D\x0A";
}
```
Dengan teknik ini, signature byte statis pada payload menjadi tidak berguna.

---

## 🔍 Deteksi Cobalt Strike: Dari Jaringan hingga Memori

Meskipun sangat fleksibel, Cobalt Strike meninggalkan jejak yang dapat dideteksi dengan kombinasi analisis.

### 1. Deteksi Jaringan (Network Forensics)

**JA3 dan JARM Fingerprinting**
Beacon menggunakan library kriptografi yang dapat dikenali dari TLS handshake. JA3 hash dari TLS client (saat Beacon menghubungi C2 melalui HTTPS) akan mencerminkan cipher suite dan ekstensi TLS yang digunakan oleh Cobalt Strike. Bahkan dengan Malleable C2, sebagian operator lupa mengubah cipher suite atau ekstensi tertentu.

Contoh: Default Cobalt Strike 4.5 JA3: `a0e9f5d64349fb1319bc781f6f4e1e85`. Tetapi ini bisa diubah di profil via `https-certificate` dan konfigurasi JVM pada team server.

**JARM** adalah hash dari server TLS. Team server yang menjalankan Cobalt Strike tanpa penyesuaian mendalam akan memiliki JARM yang khas. Database JARM publik (seperti dari Salesforce) bisa digunakan untuk mencari server Cobalt di internet.

**Beaconing Interval Analysis**
Meskipun ada jitter, analisis statistik NetFlow dapat mengidentifikasi pola komunikasi periodik. Jika sebuah host mengirimkan paket ke IP yang sama dengan interval rata-rata 60 detik (±40%), itu patut dicurigai sebagai C2. Alat seperti **RITA** (Real Intelligence Threat Analytics) dari Black Hills Information Security dirancang khusus untuk mendeteksi beaconing.

**HTTP Header Anomalies**
- User-Agent yang tidak konsisten (misalnya, UA mobile tapi request ke URI desktop).
- Header yang tidak lazim: `Cookie: session=...` dengan nilai base64 yang sangat panjang (metadata Beacon).
- URI dengan parameter acak yang panjang tanpa referensi normal.

**Domain Fronting Detection**
Cobalt Strike mendukung domain fronting (mengirim SNI domain A, tapi HTTP Host header domain B). Ini bisa dideteksi dengan perbandingan SNI vs Host header di proxy SSL.

### 2. Deteksi Endpoint (Host Forensics)

**Memory Scanning (YARA Rules)**
YARA dapat memindai process memory untuk artefak Cobalt Strike. Namun, sleep mask dan UDRL mengurangi efektivitas signature statis. YARA rule publik (seperti dari Elastic, Florian Roth) mencari:
- Byte pattern dari Reflective Loader default.
- String "beacon" di konfigurasi (walau bisa di-offset).
- XOR key pattern tertentu.

**Contoh YARA Rule (disederhanakan):**
```
rule cobaltstrike_beacon_config {
    strings:
        $xor_key = { 69 ?? ?? ?? 69 ?? ?? ?? 00 } // pola umum
        $s1 = "beacon" nocase
        $s2 = "sleeptime"
    condition:
        $xor_key and ($s1 or $s2)
}
```

**Named Pipe**
SMB Beacon menggunakan named pipe untuk komunikasi lateral. Nama pipe dikonfigurasi di profil (`pipename`). Default: `msagent_` diikuti random. Deteksi: monitor pembuatan pipe dengan nama tidak wajar atau koneksi ke pipe dari proses mencurigakan.

**Process Injection Artifacts**
- `CobaltStrike` cenderung menginjeksi ke proses Windows seperti `rundll32.exe`, `svchost.exe`, atau `explorer.exe`.
- Monitor `Sysmon Event ID 8` (CreateRemoteThread) dan `Event ID 10` (ProcessAccess) untuk akses mencurigakan.
- Beacon yang diinjeksi ke `lsass.exe` adalah anomali besar — seharusnya hanya `lsass.exe` yang mengakses dirinya.

**Registry Persistence**
Cobalt Strike tidak memiliki modul persistence built-in, tapi operator sering menambahkan melalui skrip. Waspadai `Run` key, `Scheduled Tasks`, atau `WMI Event Subscriptions` yang menjalankan executable di `%APPDATA%` atau command line PowerShell berkode base64.

**Windows Event Log**
- `Event ID 4688`: proses creation dengan command line aneh (`cmd.exe /c echo ...`, `powershell -enc ...`).
- `Event ID 7045`: service baru diinstal (lateral movement via psexec).
- `Event ID 5140`: share access ke `C$` atau `ADMIN$` dari host tidak biasa.

### 3. Deteksi via Memory Forensics (Volatility)

Dengan Volatility, periksa:
- **Malfind**: cari hidden/injected code. Beacon biasanya akan terdeteksi sebagai code injection dengan `PAGE_EXECUTE_READWRITE`.
- **Dlllist**: lihat DLL yang tidak terkait proses. Reflective DLL tidak muncul di daftar, tetapi jika ada pemetaan memori mencurigakan, periksa modulenya.
- **Sockets**: lihat koneksi jaringan yang tidak biasa. Beacon akan memiliki socket terbuka ke IP eksternal, seringkali pada port 443 atau 80.

---

## 📊 Studi Kasus: Cobalt Strike di Tangan APT

### APT29 (Cozy Bear)
Kelompok yang terkait dengan SVR Rusia ini telah menggunakan Cobalt Strike selama bertahun-tahun. Mereka mengkustomisasi Beacon dengan profil yang meniru Microsoft OAuth dan Azure. Mereka menggunakan sleep 120-300 detik dengan jitter tinggi, serta UDRL yang menggabungkan beberapa teknik bypass. Beacon di-deliver melalui spear-phishing dan eksploitasi server.

### Ransomware Conti
Conti menggunakan Cobalt Strike sebagai primary C2 untuk lateral movement sebelum meluncurkan ransomware. Operator mereka membeli lisensi Cobalt Strike (atau menggunakan versi cracked) dan mengandalkan malleable profile untuk meniru traffic sah perusahaan target. Mereka sering menggunakan BOF untuk dump kredensial, lalu `psexec` untuk menyebar.

### Operasi Cobalt Strike Cracked
Versi cracked Cobalt Strike (disebut "cracked Strike") banyak beredar di forum underground. Crack ini sering kali mengandung backdoor atau beacon tambahan, sehingga membentuk ekosistem parasit. Peneliti keamanan menemukan lebih dari 10.000 server C2 Cobalt Strike aktif yang sebagian besar adalah versi cracked, tidak terkait dengan red team resmi.

---

## ↔️ Dual-Use Spectrum: Cobalt Strike sebagai Pisau Bermata Dua

```
DEFENSIVE ◄────────────────────────────────────────────────────► OFFENSIVE

Red Team Sah                   APT & Kriminal                  Negara
│                              │                               │
Simulasi serangan              C2 untuk eksfiltrasi            Digunakan oleh
untuk menguji deteksi           data, ransomware               unit ofensif
dan respons                     │                               (militer/intel)
│                              │                               │
Malleable C2 diganti           Malleable C2                   Kadang kustom
setiap engagement              sering di-recycle               framework sendiri
│                              antar korban                    tetapi mengadopsi
│                              │                               teknik serupa
│                              ▼
│                   Cobalt Strike cracked
│                   digunakan oleh siapa saja
│                   termasuk aktor rendah
│
└── Blue Team mempelajari
    profil untuk membuat
    deteksi yang lebih baik
```

Tidak seperti Metasploit yang memiliki banyak kontributor open-source, Cobalt Strike adalah produk tertutup. Namun, kenyataan bahwa versi cracked tersebar luas menjadikannya masalah serius bagi defender. Setiap organisasi harus mengasumsikan bahwa suatu saat mereka akan menghadapi Cobalt Strike di jaringan mereka.

---

## 🛡️ Countermeasures & Defensive Stack

| Lapisan | Tindakan | Alat/Bukti |
|---------|----------|------------|
| **Perimeter** | Blokir semua traffic mencurigakan; gunakan proxy SSL inspeksi untuk membandingkan SNI dengan Host header (deteksi domain fronting). | Firewall NGFW, Squid, Zscaler |
| **Network** | Analisis NetFlow untuk beaconing; gunakan JA3/JARM signature database; pantau koneksi ke IP unknown di port non-standar. | RITA, Zeek (Bro), Suricata dengan rules khusus JA3 |
| **Endpoint** | Monitor process creation, injection events, named pipe creation; gunakan YARA memory scan berkala. | Sysmon, Elastic EDR, Windows Defender ATP, SentinelOne |
| **Memory** | Lakukan memory forensics ad-hoc pada host mencurigakan; periksa anomali thread dan pemetaan memori. | Volatility, Rekall, Magnet Axiom |
| **Credential** | Terapkan Credential Guard, LAPS, managed service account untuk mempersulit hashdump dan pass-the-hash. | Microsoft Defender for Identity |
| **Response** | Siapkan playbook khusus untuk C2 discovery: isolasi host, block IOC, lakukan analisis memory capture sebelum restart. | - |
| **Deception** | Sebarkan honeypot internal (token palsu, service palsu) yang jika diakses akan trigger alert. | Canarytokens, Thinkst Canary |
| **Intelligence** | Konsumsi threat intel terkait Cobalt Strike C2 server publik; feed IOC ke SIEM. | MISP, OTX AlienVault |

Jika Cobalt Strike sudah terlanjur masuk, langkah respons yang tepat:
1. **Jangan restart host**. Lakukan memory dump (live forensics).
2. Identifikasi profil Malleable C2 dari artefak yang ada (URI, header, User-Agent).
3. Cari IOC di seluruh environment menggunakan EDR hunting.
4. Reset semua kredensial yang mungkin telah dicuri (terutama krbtgt jika domain admin pernah diakses).

---

## 🔗 Koneksi dalam Vault

- [[metasploit]] — Payload Cobalt Strike dapat di-deliver melalui modul exploit Metasploit (`generic/custom`). Sebaliknya, sesi Meterpreter bisa di-upgrade ke Beacon.
- [[bloodhound]] — Beacon sering menjalankan SharpHound (via execute-assembly) untuk mencari path ke Domain Admin.
- [[havoc-c2]] — Alternatif open-source untuk Cobalt Strike dengan fitur serupa (sleep obfuscation, indirect syscalls).
- [[empire]] — C2 berbasis PowerShell yang dulu sangat populer; sekarang Cobalt Strike lebih banyak dipakai untuk stealth yang lebih tinggi.
- **DARKCOMET** — RAT sederhana, kontras dengan kompleksitas Cobalt Strike.
- [[shodan]] — Dapat digunakan untuk mencari server C2 Cobalt Strike di internet publik berdasarkan JARM atau JA3.
- [[xkeyscore]] — Platform SIGINT global yang bisa mendeteksi traffic C2 Cobalt Strike berdasarkan pattern recognition di backbone internet; ini adalah ancaman bagi APT yang menggunakan Cobalt Strike karena NSA dapat melacak mereka.

---

## 📚 Referensi

- Mudge, R. (2015–2024). Cobalt Strike Documentation & User Manual.
- Elastic Security. *Detecting Cobalt Strike with Elastic*. (2021)
- Hessel, M., & S. (2023). *Cobalt Strike: A Pentester's Guide*. No Starch Press (upcoming).
- Unit 42, Palo Alto Networks. *Cobalt Strike: Analysis of a Modern C2 Framework*.
- MITRE ATT&CK: T1071.001 (Web Protocols), T1095 (Non-Application Layer Protocol), T1573 (Encrypted Channel).
- SentinelOne. *Deep Dive into Malleable C2 Evasion*. (2022)
- SpecterOps. *Cobalt Strike BOFs and UDRLs*.
- Black Hills Information Security. RITA (Real Intelligence Threat Analytics).

---

*Cobalt Strike Deep Dive | Advanced C2 & Adversary Simulation | Malleable C2 & Evasion Techniques*