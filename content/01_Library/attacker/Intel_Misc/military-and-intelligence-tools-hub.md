---
title: Military and Intelligence Tools Hub
tags:
- library
- military-and-intelligence-tools
created: '2026-06-27'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout

---

## Military and Intelligence Tools Hub
### 1. Pendahuluan
Military and Intelligence Tools Hub adalah sebuah direktori komprehensif yang mencakup berbagai alat dan teknik yang digunakan dalam operasi militer dan intelijen. Direktori ini dibagi menjadi beberapa level, mulai dari Level 0 hingga Level 6, yang mencakup berbagai kategori alat dan teknik, seperti OSINT, pentest, post-exploitation, dan communications intelligence. 

### 2. Struktur Folder & Navigasi
```
military-and-intelligence-tools/
│
├── 📄 military-and-intelligence-tools-hub.md          ◄── ANDA DI SINI
│
├── 🗂️ 01-osint-and-reconnaissance/
│   ├── [[maltego]]
│   ├── [[shodan]]
│   └── [[google-dorks]]
│
├── 🗂️ 02-pentest-frameworks/
│   ├── [[metasploit]]
│   ├── [[bloodhound]]
│   └── [[burp-suite]]
│
├── 🗂️ 03-c2-and-post-exploitation/
│   ├── [[cobalt-strike]]
│   ├── [[havoc-c2]]
│   ├── [[empire]]
│   └── [[sliver]]
│
├── 🗂️ 04-commercial-surveillance-and-spyware/
│   ├── [[pegasus]]
│   ├── [[finspy]]
│   └── [[predator]]
│
├── 🗂️ 05-mobile-and-hardware-forensics/
│   ├── [[cellebrite-ufed]]
│   ├── [[graykey]]
│   ├── [[victoria-hdd]]
│   └── [[pc-3000]]
│
├── 🗂️ 06-communications-intelligence-(sigint)/
│   ├── [[verint]]
│   ├── [[prism]]
│   └── [[upstream-and-tempora]]
│
├── 🗂️ 07-nation-state-platforms/
│   ├── [[xkeyscore]]
│   ├── [[palantir-gotham]]
│   └── [[icreach]]
│
├── 📄 [[dual-use-spectrum-and-ethical-framework]]
└── 📄 [[countermeasure-stack]]
```
### 3. Level Hierarchy
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

### 4. Indeks Alat (A-Z)
| Alat | Level | Kategori | Ringkasan Satu Kalimat |
|------|-------|----------|-------------------------|
| [[bloodhound]] | 1 | Pentest | Analisis graf Active Directory untuk menemukan attack path tersembunyi. |
| [[burp-suite]] | 1 | Pentest | Platform proxy interception dan fuzzing untuk aplikasi web. |
| [[cellebrite-ufed]] | 4 | Forensics | Ekstraksi data forensik dari perangkat mobile (logical, filesystem, physical). |
| [[cobalt-strike]] | 2 | C2 | Adversary simulation platform dengan Malleable C2 dan sleep obfuscation. |
| [[empire]] | 2 | C2 | Framework post-exploitation berbasis PowerShell dan Python. |
| [[finspy]] | 3 | Spyware | Multi-platform spyware komersial (Windows, macOS, Linux, iOS, Android). |
| [[google-dorks]] | 0 | OSINT | Operator pencarian lanjutan Google untuk menemukan data terindeks. |
| [[graykey]] | 4 | Forensics | Hardware brute-force unlocker passcode iPhone via Secure Enclave. |
| [[havoc-c2]] | 2 | C2 | C2 open-source modern dengan sleep obfuscation dan indirect syscalls. |
| [[icreach]] | 6 | Nation-State | Mesin pencari metadata teleponi global NSA. |
| [[maltego]] | 0 | OSINT | Platform graph-based link analysis untuk OSINT dan entity correlation. |
| [[metasploit]] | 1 | Pentest | Framework modular untuk exploit delivery dan post-exploitation. |
| [[palantir-gotham]] | 6 | Nation-State | Platform data fusion dan analisis intelijen dari ribuan sumber. |
| [[pc-3000]] | 4 | Forensics | Sistem recovery data profesional dengan akses firmware HDD/SSD. |
| [[pegasus]] | 3 | Spyware | 0-click mobile spyware NSO Group untuk iOS dan Android. |
| [[predator]] | 3 | Spyware | Spyware komersial Intellexa via browser exploit dan phishing. |
| [[prism]] | 5 | SIGINT | Program NSA untuk pengumpulan data langsung dari perusahaan teknologi. |
| [[shodan]] | 0 | OSINT | Mesin pencari untuk perangkat, server, dan layanan yang terhubung internet. |
| [[sliver]] | 2 | C2 | C2 cross-platform open-source berbasis Go dengan dukungan WireGuard. |
| [[upstream-and-tempora]] | 5 | SIGINT | Program intersepsi backbone internet NSA (UPSTREAM) dan GCHQ (TEMPORA). |
| [[verint]] | 5 | SIGINT | Platform COMINT komersial untuk intersepsi dan analisis komunikasi. |
| [[victoria-hdd]] | 4 | Forensics | Alat diagnostik dan pre-imaging verification untuk HDD/SSD. |
| [[xkeyscore]] | 6 | Nation-State | "Google-nya NSA" — sistem pencarian dan analisis data internet global. |

### 5. Matriks Dual-Use Cepat

| Alat | Defense Use | Offense Use |
|------|-------------|-------------|
| **Maltego** | Brand protection, self-recon | Target profiling, doxing |
| **Shodan** | Asset discovery, vuln tracking | Target selection, mass exploitation |
| **Google Dorks** | Self-dorking, exposure audit | Credential hunting, data theft |
| **Burp Suite** | Dev security testing | Web app exploitation |
| **Metasploit** | Patch validation | Exploit delivery, ransomware |
| **BloodHound** | AD hardening | Attack path hunting |
| **Cobalt Strike** | Adversary simulation | Ransomware C2, espionage |
| **Havoc C2** | Adversary simulation | Data exfiltration |
| **Empire** | Purple team testing | Lateral movement, espionage |
| **Sliver** | Cross-platform simulation | APT operations |
| **Pegasus** | Law enforcement (warrant) | Journalist targeting, repression |
| **FinSpy** | Law enforcement (warrant) | Activist surveillance |
| **Predator** | Law enforcement (warrant) | Political opposition targeting |
| **Cellebrite UFED** | Evidence extraction | Unauthorized device unlock |
| **GrayKey** | Lawful device unlock | Warrantless access |
| **Victoria HDD** | Drive health, pre-imaging | Data destruction |
| **PC-3000** | Data recovery, forensics | Evidence tampering |
| **Verint** | Counter-terrorism | Mass surveillance |
| **PRISM** | Counter-terrorism | Global data collection |
| **UPSTREAM/TEMPORA** | Counter-terrorism | Undersea cable tapping |
| **XKEYSCORE** | Threat analysis | Global internet search |
| **ICREACH** | Contact tracing | Metadata mass surveillance |
| **Palantir Gotham** | Disaster response, intel | Predictive policing, ICE tracking |

### 6. Panduan Cepat untuk Defender

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

### 7. Implementasi Keselamatan
Berikut adalah contoh implementasi keselamatan menggunakan beberapa alat yang disebutkan di atas:
```python
import os
import sys

# Aktifkan EDR
def enable_edr():
    # Implementasi EDR
    pass

# Aktifkan PowerShell logging
def enable_powershell_logging():
    # Implementasi PowerShell logging
    pass

# Jalankan MVT berkala
def run_mvt():
    # Implementasi MVT
    pass

if __name__ == "__main__":
    enable_edr()
    enable_powershell_logging()
    run_mvt()
```
Dalam contoh di atas, kita menggunakan Python untuk mengaktifkan EDR, PowerShell logging, dan menjalankan MVT berkala.

### 8. Kesimpulan
Military and Intelligence Tools Hub adalah sebuah direktori komprehensif yang mencakup berbagai alat dan teknik yang digunakan dalam operasi militer dan intelijen. Direktori ini dapat membantu defender dan operator untuk meningkatkan keselamatan dan efektivitas operasi mereka. Dengan memahami prinsip-prinsip dasar keselamatan dan menggunakan alat-alat yang tepat, kita dapat meningkatkan kemampuan pertahanan dan serangan dalam operasi militer dan intelijen.

### 9. Referensi
- [[dual-use-spectrum-and-ethical-framework]] — Kerangka etis untuk penggunaan semua alat di vault ini.
- [[countermeasure-stack]] — Lapisan pertahanan lengkap Level 0–6.
- Setiap halaman deep dive memiliki koneksi silang ke alat terkait.

### 10. Pendalaman Lebih Lanjut
Untuk pendalaman lebih lanjut, silakan lihat dokumentasi masing-masing alat dan teknologi yang disebutkan di atas. Pastikan Anda memahami prinsip-prinsip dasar keselamatan dan menggunakan alat-alat yang tepat untuk meningkatkan efektivitas operasi Anda.
