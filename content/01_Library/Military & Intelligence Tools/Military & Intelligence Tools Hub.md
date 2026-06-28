---
tags:
  - military-tools
  - intelligence
  - surveillance
  - sigint
  - pentest
  - forensics
  - osint
  - dual-use
  - apt
  - c2
aliases:
  - Military & Intelligence Tools Hierarchy
  - Shadow Arsenal
  - SIGINT & Surveillance Stack
  - Red Team / Blue Team Weapons
  - Commercial Surveillance Ecosystem
created: 2026-06-27
status: operational
cssclasses:
  - wide-table
---

> [!abstract] Map of Content
> Hub ini adalah **gerbang navigasi** ke seluruh dokumentasi Military & Intelligence Tools Hierarchy. Di bawah ini Anda akan menemukan peta lengkap Level 0 hingga Level 6, indeks alat, matriks dual-use, dan panduan cepat untuk defender maupun operator.

## 🧭 Struktur Folder & Navigasi

```
Military & Intelligence Tools/
│
├── 📄 Military & Intelligence Tools Hub.md          ◄── ANDA DI SINI
│
├── 🗂️ 01 OSINT & Reconnaissance/
│   ├── [[Maltego]]
│   ├── [[Shodan]]
│   └── [[Google Dorks]]
│
├── 🗂️ 02 Pentest Frameworks/
│   ├── [[Metasploit]]
│   ├── [[BloodHound]]
│   └── [[Burp Suite]]
│
├── 🗂️ 03 C2 & Post-Exploitation/
│   ├── [[Cobalt Strike]]
│   ├── [[Havoc C2]]
│   ├── [[Empire]]
│   └── [[Sliver]]
│
├── 🗂️ 04 Commercial Surveillance & Spyware/
│   ├── [[Pegasus]]
│   ├── [[FinSpy]]
│   └── [[Predator]]
│
├── 🗂️ 05 Mobile & Hardware Forensics/
│   ├── [[Cellebrite UFED]]
│   ├── [[GrayKey]]
│   ├── [[Victoria HDD]]
│   └── [[PC-3000]]
│
├── 🗂️ 06 Communications Intelligence (SIGINT)/
│   ├── [[Verint]]
│   ├── [[PRISM]]
│   └── [[UPSTREAM & TEMPORA]]
│
├── 🗂️ 07 Nation-State Platforms/
│   ├── [[XKEYSCORE]]
│   ├── [[Palantir Gotham]]
│   └── [[ICREACH]]
│
├── 📄 [[Dual-Use Spectrum & Ethical Framework]]
└── 📄 [[Countermeasure Stack]]
```

---

## 📊 Level Hierarchy — Ringkasan Visual

```
MILITARY & INTELLIGENCE TOOLS
─────────────────────────────────────────────────────────────────
Level 0  │ OSINT                  │ Maltego, Shodan, Google Dorks
Level 1  │ Pentest Frameworks     │ Metasploit, BloodHound, Burp Suite
Level 2  │ Post-Exploitation & C2 │ Cobalt Strike, Havoc, Empire, Sliver
Level 3  │ Commercial Spyware     │ Pegasus, FinSpy, Predator
Level 4  │ Hardware Forensics     │ Cellebrite UFED, GrayKey, Victoria, PC-3000
Level 5  │ Comms Intelligence     │ Verint, PRISM, UPSTREAM & TEMPORA
Level 6  │ Nation-State SIGINT    │ XKEYSCORE, Palantir Gotham, ICREACH

COUNTERMEASURE STACK
─────────────────────────────────────────────────────────────────
Level 0  │ Data Hygiene + Self-Dorking
Level 1  │ Patch Mgmt + EDR + WAF
Level 2  │ NTA + JA3 + PowerShell Logging + Deception
Level 3  │ Lockdown Mode + Strong Passphrase + MVT
Level 4  │ Full Disk Encryption + Physical Destruction
Level 5  │ E2EE + Tor/VPN + Metadata Obfuscation
Level 6  │ Legal Reform + Advocacy
```

---

## 🎯 Indeks Alat (A-Z)

| Alat                   | Level | Kategori     | Ringkasan Satu Kalimat                                                         |
| ---------------------- | ----- | ------------ | ------------------------------------------------------------------------------ |
| [[BloodHound]]         | 1     | Pentest      | Analisis graf Active Directory untuk menemukan attack path tersembunyi.        |
| [[Burp Suite]]         | 1     | Pentest      | Platform proxy interception dan fuzzing untuk aplikasi web.                    |
| [[Cellebrite UFED]]    | 4     | Forensics    | Ekstraksi data forensik dari perangkat mobile (logical, filesystem, physical). |
| [[Cobalt Strike]]      | 2     | C2           | Adversary simulation platform dengan Malleable C2 dan sleep obfuscation.       |
| [[Empire]]             | 2     | C2           | Framework post-exploitation berbasis PowerShell dan Python.                    |
| [[FinSpy]]             | 3     | Spyware      | Multi-platform spyware komersial (Windows, macOS, Linux, iOS, Android).        |
| [[Google Dorks]]       | 0     | OSINT        | Operator pencarian lanjutan Google untuk menemukan data terindeks.             |
| [[GrayKey]]            | 4     | Forensics    | Hardware brute-force unlocker passcode iPhone via Secure Enclave.              |
| [[Havoc C2]]           | 2     | C2           | C2 open-source modern dengan sleep obfuscation dan indirect syscalls.          |
| [[ICREACH]]            | 6     | Nation-State | Mesin pencari metadata teleponi global NSA.                                    |
| [[Maltego]]            | 0     | OSINT        | Platform graph-based link analysis untuk OSINT dan entity correlation.         |
| [[Metasploit]]         | 1     | Pentest      | Framework modular untuk exploit delivery dan post-exploitation.                |
| [[Palantir Gotham]]    | 6     | Nation-State | Platform data fusion dan analisis intelijen dari ribuan sumber.                |
| [[PC-3000]]            | 4     | Forensics    | Sistem recovery data profesional dengan akses firmware HDD/SSD.                |
| [[Pegasus]]            | 3     | Spyware      | 0-click mobile spyware NSO Group untuk iOS dan Android.                        |
| [[Predator]]           | 3     | Spyware      | Spyware komersial Intellexa via browser exploit dan phishing.                  |
| [[PRISM]]              | 5     | SIGINT       | Program NSA untuk pengumpulan data langsung dari perusahaan teknologi.         |
| [[Shodan]]             | 0     | OSINT        | Mesin pencari untuk perangkat, server, dan layanan yang terhubung internet.    |
| [[Sliver]]             | 2     | C2           | C2 cross-platform open-source berbasis Go dengan dukungan WireGuard.           |
| [[UPSTREAM & TEMPORA]] | 5     | SIGINT       | Program intersepsi backbone internet NSA (UPSTREAM) dan GCHQ (TEMPORA).        |
| [[Verint]]             | 5     | SIGINT       | Platform COMINT komersial untuk intersepsi dan analisis komunikasi.            |
| [[Victoria HDD]]       | 4     | Forensics    | Alat diagnostik dan pre-imaging verification untuk HDD/SSD.                    |
| [[XKEYSCORE]]          | 6     | Nation-State | "Google-nya NSA" — sistem pencarian dan analisis data internet global.         |

---

## 🔴🟢 Matriks Dual-Use Cepat

| Alat                 | Defense Use                    | Offense Use                         |
| -------------------- | ------------------------------ | ----------------------------------- |
| **Maltego**          | Brand protection, self-recon   | Target profiling, doxing            |
| **Shodan**           | Asset discovery, vuln tracking | Target selection, mass exploitation |
| **Google Dorks**     | Self-dorking, exposure audit   | Credential hunting, data theft      |
| **Burp Suite**       | Dev security testing           | Web app exploitation                |
| **Metasploit**       | Patch validation               | Exploit delivery, ransomware        |
| **BloodHound**       | AD hardening                   | Attack path hunting                 |
| **Cobalt Strike**    | Adversary simulation           | Ransomware C2, espionage            |
| **Havoc C2**         | Adversary simulation           | Data exfiltration                   |
| **Empire**           | Purple team testing            | Lateral movement, espionage         |
| **Sliver**           | Cross-platform simulation      | APT operations                      |
| **Pegasus**          | Law enforcement (warrant)      | Journalist targeting, repression    |
| **FinSpy**           | Law enforcement (warrant)      | Activist surveillance               |
| **Predator**         | Law enforcement (warrant)      | Political opposition targeting      |
| **Cellebrite UFED**  | Evidence extraction            | Unauthorized device unlock          |
| **GrayKey**          | Lawful device unlock           | Warrantless access                  |
| **Victoria HDD**     | Drive health, pre-imaging      | Data destruction                    |
| **PC-3000**          | Data recovery, forensics       | Evidence tampering                  |
| **Verint**           | Counter-terrorism              | Mass surveillance                   |
| **PRISM**            | Counter-terrorism              | Global data collection              |
| **UPSTREAM/TEMPORA** | Counter-terrorism              | Undersea cable tapping              |
| **XKEYSCORE**        | Threat analysis                | Global internet search              |
| **ICREACH**          | Contact tracing                | Metadata mass surveillance          |
| **Palantir Gotham**  | Disaster response, intel       | Predictive policing, ICE tracking   |

---

## 🧠 Panduan Cepat untuk Defender

1. **Mulai dari Level 0**: Self-dorking dan Shodan audit untuk menemukan eksposur Anda sendiri.
2. **Level 1–2**: Deploy EDR, aktifkan PowerShell logging, analisis JA3, dan pasang deception.
3. **Level 3**: Aktifkan Lockdown Mode, update perangkat, jalankan MVT berkala.
4. **Level 4**: Enkripsi penuh semua perangkat. Strong passphrase.
5. **Level 5**: Gunakan E2EE, Tor/VPN, pisahkan identitas digital.
6. **Level 6**: Dukung advokasi privasi dan reformasi hukum pengawasan.

> [!tip] Prinsip Utama
> **Defense-in-depth**: Jangan pernah bergantung pada satu lapisan pertahanan.  
> **Assume breach**: Desain sistem seolah-olah kompromi sudah terjadi.  
> **Least privilege**: Setiap entitas hanya memiliki akses minimum yang diperlukan.

---

## 🔗 Lihat Juga

- [[Dual-Use Spectrum & Ethical Framework]] — Kerangka etis untuk penggunaan semua alat di vault ini.
- [[Countermeasure Stack]] — Lapisan pertahanan lengkap Level 0–6.
- Setiap halaman deep dive memiliki koneksi silang ke alat terkait.

---

_Military & Intelligence Tools Hub | Shadow Arsenal Level 0–6 | Dual-Use Knowledge Base_
