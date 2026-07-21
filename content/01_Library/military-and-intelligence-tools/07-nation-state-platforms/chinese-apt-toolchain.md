---
title: Chinese Apt Toolchain
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
> Dokumentasi ini merangkum informasi publik dari laporan threat intelligence (Mandiant, CrowdStrike, Kaspersky, Recorded Future), analisis malware, serta dokumen pengadilan (DOJ indictments). Semua alat yang dibahas digunakan oleh aktor negara Tiongkok untuk spionase dan pengumpulan intelijen. Pembahasan ini murni **edukasional dan defensif**. Tidak ada instruksi pembuatan atau penggunaan. Tujuan: membantu defender memahami TTP, IOC, dan membangun pertahanan.

---

## 🧬 Gambaran Umum Ekosistem APT Tiongkok

Ekosistem Advanced Persistent Threat (APT) Tiongkok bukanlah kumpulan operasi terisolasi, melainkan **toolchain terpadu** yang dikembangkan dan dioperasikan oleh unit-unit di bawah **Ministry of State Security (MSS)** dan **People's Liberation Army (PLA)**. Unit-unit terkenal meliputi:

| Unit | Nama Publik | Fokus Target | Tools Utama |
|------|-------------|--------------|-------------|
| **PLA Unit 61398** | APT1 / Comment Crew | Intellectual property, aerospace, tech | PlugX, Poison Ivy, Gh0st RAT |
| **PLA Unit 61486** | APT3 / Gothic Panda | Industri pertahanan, pemerintahan | Winnti, ShadowPad, PlugX |
| **MSS** | APT27 / Emissary Panda | Perusahaan teknologi, telekomunikasi | PlugX, Gh0st RAT |
| **PLA Unit 68020** | APT10 / Stone Panda | Managed service providers, cloud | PlugX, RedLeaves, Quarian |
| **MSS** | APT17 / Deputy Dog | Industri penerbangan, legal | BlackCoffin, PlugX |
| **PLA Strategic Support Force** | APT40 / Leviathan | Maritim, energi, pemerintahan | Winnti, PlugX, China Chopper |

Meskipun banyak alat digunakan, **PlugX** adalah benang merah yang menghubungkan hampir semua operasi — sering disebut sebagai "Swiss Army knife" APT Tiongkok.

---

## 🦠 1. PlugX — Universal Backdoor & Post-Exploitation Framework

### Sejarah & Evolusi

PlugX muncul sekitar 2008 dan terus dikembangkan. Awalnya dideteksi sebagai backdoor sederhana, kini menjadi **modular RAT** dengan kemampuan:

- **Keylogging** dan **screen capture**
- **File exfiltration** terjadwal
- **Reverse shell** (cmd.exe, PowerShell)
- **Port forwarding** dan **SOCKS proxy** untuk pivoting
- **Modular plugin system** — operator bisa menambah plugin sesuai target

PlugX sering di-deliver melalui spear-phishing (lampiran .doc/.xls dengan exploit) atau **watering hole** yang menginfeksi website yang sering dikunjungi target.

### Arsitektur Teknis

```
[Target] ◄── [C2 via HTTP/HTTPS/DNS]
   │
   ├── PlugX Core DLL (Side-loaded via legitimate app)
   │      └── Menggunakan DLL side-loading: file sah + PlugX DLL
   │             Contoh: Kaspersky Antivirus + mfc42loc.dll (PlugX)
   │
   └── Modul PlugX:
          ├── Keylogger (log tersimpan terenkripsi di %APPDATA%)
          ├── Screen Capture (screenshot periodik)
          ├── File Browser (upload/download file)
          ├── Reverse Shell (cmd.exe)
          ├── Network Pivot (SOCKS5 proxy, port forward)
          └── Custom Plugin (operator bisa upload plugin baru)
```

**Teknik Evasion:**
- **DLL Side-Loading**: Memanfaatkan aplikasi sah yang memuat DLL dari direktori kerjanya. PlugX menaruh DLL jahat di direktori yang sama, sehingga aplikasi sah tanpa sadar memuatnya.
- **Komunikasi C2**: HTTP dengan request seperti `GET /status?id={random}`. Data dikompresi (zlib) dan dienkripsi (XOR dengan kunci statis atau RC4).
- **Persistence**: Scheduled task, registry Run key, atau service.

### Varian Modern: PlugX RAT 3.x

Versi terbaru (2021-2024) memiliki:
- **Domain Generation Algorithm (DGA)** untuk fallback C2
- **HTTPS dengan sertifikat palsu** untuk kamuflase
- **Reflective DLL loading** — tidak butuh file di disk
- **Integrasi dengan Cobalt Strike** — PlugX sebagai initial access, lalu deploy Beacon

---

## 🧬 2. Winnti — Modular Malware for Targeted Espionage

### Gambaran Umum

Winnti adalah keluarga malware yang pertama kali terdeteksi pada 2011 ketika digunakan untuk menyerang perusahaan game online. Sejak itu, Winnti telah digunakan oleh banyak grup APT Tiongkok (APT17, APT41, Winnti Group) untuk spionase jangka panjang.

### Karakteristik Teknis

| Fitur | Detail |
|-------|--------|
| **Delivery** | Spear-phishing, supply chain compromise (misal: CCleaner insiden 2017) |
| **Persistence** | Kernel driver (ditandatangani dengan sertifikat curian) atau service |
| **Komunikasi C2** | TCP/HTTP dengan enkripsi kustom (XOR + AES) |
| **Payload** | DLL yang diinjeksi ke proses sah (lsass.exe, svchost.exe) |
| **Modul** | Keylogger, file browser, reverse shell, port scanner |

### Kill Chain Winnti

1. **Initial Access**: Spear-phishing dengan makro berbahaya atau exploit CVE-2012-0158 (MSCOMCTL).
2. **Execution**: Makro menjalankan PowerShell yang mengunduh Winnti DLL.
3. **Persistence**: Driver kernel diinstal sebagai service (`Winnti` atau nama samaran).
4. **C2**: Koneksi TCP ke IP hardcoded, autentikasi dengan sertifikat kustom.
5. **Actions on Objective**: Eksfiltrasi dokumen, database, email.

### Varian Terkenal

- **Winnti 2.0 (2015)**: Menambahkan modul port scanning dan lateral movement.
- **Winnti for Linux (2018)**: Menyerang server Linux dengan binary ELF.
- **Winnti 4.0 (2021)**: Reflective loading, HTTPS, DGA.

---

## 🍂 3. RedLeaves — Plugin-Based Reconnaissance Tool

### Gambaran Umum

RedLeaves pertama kali didokumentasikan oleh Kaspersky pada 2016 sebagai alat yang digunakan oleh APT10 (Stone Panda). Nama ini diambil dari string "RedLeaves" yang ditemukan di dalam kode. RedLeaves sering digunakan **setelah** PlugX berhasil menginfeksi target, sebagai alat reconnaissance tambahan.

### Fungsi Utama

RedLeaves adalah **implant modular** yang fokus pada:

- **Enumerasi sistem**: OS, domain, user, proses, service, software terinstal.
- **Enumerasi jaringan**: IP, subnet, domain controller, share.
- **File browsing**: Direktori spesifik (Desktop, Documents, Shared folders).
- **Eksekusi command**: cmd.exe atau PowerShell.

Berbeda dengan PlugX yang berfungsi penuh sebagai backdoor, RedLeaves lebih merupakan **"recon agent"** yang mengumpulkan informasi sebelum operator memutuskan langkah selanjutnya.

### Arsitektur

RedLeaves biasanya berupa file DLL yang disisiplkan (side-loaded) oleh executable sah, mirip PlugX. Ia menggunakan komunikasi HTTP sederhana dengan enkripsi XOR. Konfigurasi C2 sering disimpan di resource section DLL (RC4 terenkripsi).

---

## 🦊 4. TibetanFox — Targeted Tool for Tibetan/HK Activist Monitoring

### Gambaran Umum

TibetanFox adalah **RAT modular** yang digunakan oleh aktor Tiongkok untuk menargetkan **aktivis Tibet, Uyghur, dan Hong Kong**. Nama ini diberikan oleh peneliti keamanan karena target awalnya adalah diaspora Tibet. TibetanFox memiliki kemampuan yang mirip dengan PlugX tetapi lebih kecil dan lebih sulit dideteksi.

### Kemampuan

- **Keylogging**
- **Screen capture**
- **File exfiltration**
- **Audio recording** (dari mikrofon)
- **Webcam capture**
- **Reverse shell**

### Vektor Infeksi

- Spear-phishing email dengan lampiran berbahaya.
- **Fake apps** (misalnya: aplikasi chat palsu untuk komunitas Tibet).
- **Watering hole** di website diaspora Tibet.

### C2

TibetanFox menggunakan HTTP/HTTPS untuk komunikasi. Data dienkripsi dengan XOR sederhana dan dikompresi. Beberapa varian menggunakan **DNS tunneling** untuk eksfiltrasi lambat tapi stealth.

---

## 🔗 Integrasi Ekosistem: Dari PlugX ke Winnti ke Exfiltration

Alur operasi APT Tiongkok sering mengikuti pola ini:

1. **Initial Recon**: OSINT & spear-phishing target selection.
2. **Initial Access**: PlugX di-deliver via email atau watering hole.
3. **Lateral Movement**: PlugX digunakan untuk pivot ke server internal (via SMB, WMI, PSExec).
4. **Domain Escalation**: Winnti di-deploy ke domain controller untuk DCSync dan dump NTDS.dit.
5. **Exfiltration**: Data dikumpulkan, dikompresi, dan diunggah ke server C2 atau via email (data exfiltration via SMTP).

**Toolchain Saling Melengkapi:**

```
PlugX        → Initial foothold, persistence, lateral movement
RedLeaves    → Deep reconnaissance, asset discovery
Winnti       → Privilege escalation, domain dominance
TibetanFox   → Surveillance (mic, webcam), specific targeting
```

---

## 🛡️ Deteksi & Countermeasures

### IOC Umum APT Tiongkok

| Artefak | Indikator |
|---------|-----------|
| **File** | Nama file DLL yang tidak cocok dengan aplikasi (misal: `mfc42loc.dll` di folder Kaspersky). |
| **Registry** | Key di `HKLM\SYSTEM\CurrentControlSet\Services` untuk driver Winnti. |
| **Network** | Koneksi HTTP ke IP/domain dengan pola `/status?id=...` (PlugX). |
| **DNS** | Query DNS dengan subdomain acak untuk DGA (PlugX 3.x). |
| **Certificate** | Driver kernel ditandatangani dengan sertifikat curian (misal: D-Link, Realtek). |

### YARA Rule Contoh (PlugX)

```
rule plugx_dll_side_loading {
    strings:
        $s1 = "PlugX" nocase
        $s2 = "mfc42loc.dll" nocase
        $xor_key = { 69 ?? ?? ?? 69 ?? ?? ?? }
    condition:
        $xor_key and ($s1 or $s2)
}
```

### Countermeasures

| Lapisan | Tindakan |
|---------|----------|
| **Email** | Blokir lampiran .docm, .xlsm, .iso, .img. Gunakan sandbox untuk detonasi. |
| **Endpoint** | Monitor DLL side-loading (Sysmon Event ID 7, image load dari path tidak standar). |
| **Network** | Blokir IOC APT Tiongkok di proxy/firewall. Monitor beaconing ke IP tidak dikenal. |
| **AD** | Terapkan tiered access, LAPS, Credential Guard. Deteksi DCSync (Event ID 4662). |

---

## 📚 Referensi

- Mandiant, *APT1: Exposing One of China's Cyber Espionage Units* (2013).
- CrowdStrike, *Global Threat Report: China Adversaries* (2021).
- Kaspersky, *Winnti: More than just a game* (2013).
- Recorded Future, *Chinese State-Sponsored Cyber Operations* (2023).
- MITRE ATT&CK: T1071.001 (Web Protocols), T1055.001 (Process Injection), T1003.001 (OS Credential Dumping).

---

*Chinese APT Toolchain Deep Dive | PlugX, Winnti, RedLeaves, TibetanFox | Nation-State Cyber Ecosystem*