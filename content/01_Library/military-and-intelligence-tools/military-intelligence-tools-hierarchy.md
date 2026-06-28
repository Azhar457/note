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
  - military-and-intelligence-tools Hierarchy
  - Shadow Arsenal
  - SIGINT & Surveillance Stack
  - Red Team / Blue Team Weapons
  - Commercial Surveillance Ecosystem
created: 2026-06-27
---

# ☠️ MILITARY & INTELLIGENCE TOOLS — The Shadow Arsenal Hierarchy

> Hierarki alat-alat yang dipakai oleh aktor state-level, law enforcement, APT groups, dan red teamer. Sama seperti Cheat Engine, semua tool di sini bersifat **dual-use**: tool yang identik dipakai untuk defense (penetration testing, forensics, counter-terrorism) dan offense (mass surveillance, targeted espionage, APT campaigns). Memahami cara kerjanya adalah prasyarat untuk membangun pertahanan.

> [!warning] Konteks Etis & Legal
> Semua tool di bawah didokumentasikan secara publik melalui: Snowden leaks (2013), Citizen Lab reports, EFF investigations, academic forensics literature, dan vendor documentation. Pembahasan ini bersifat **edukasional dan defensive**. Penggunaan tanpa otorisasi pada sistem milik orang lain adalah ilegal di hampir semua yurisdiksi.

---

## Sheet 1 — The Shadow Arsenal: Dari OSINT sampai Nation-State SIGINT

| 🎯 Level & Ekosistem                                                                                                 | ⚡ Cara Kerja & Sweet Spot                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | ☠️ Tembok & Deteksi                                                                                                                                                                                                                                                                                    | 🔵 Operator Resmi                                                                                                                        | 🔴 Operator Ilegal / APT                                                                                                |
| -------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Level 0** — OSINT & Reconnaissance _(Maltego, Shodan, Google Dorks, theHarvester)_                                 | **Maltego**: link analysis & entity correlation dari data publik (DNS, social media, WHOIS, passive DNS). **Shodan**: search engine untuk device IoT, server, industrial control system yang terexpose. **Google Dorks**: operator lanjut (`inurl:`, `filetype:`, `intitle:`) untuk menemukan dokumen internal yang terexpose. Zero exploit — 100% data publik.                                                                                                                                                             | Tidak ada deteksi teknis karena tidak ada interaksi agresif. Counter: data hygiene (menghapus metadata, restrict robots.txt, takedown), OSINT monitoring terhadap brand sendiri.                                                                                                                       | Jurnalis investigasi (Bellingcat), Red Team recon, bug bounty hunter, law enforcement (trafficker tracking), corporate security          | APT29 (Cozy Bear) recon awal, ransomware gang target selection, stalker, doxxer                                         |
| **Level 1** — Pentest Frameworks _(Metasploit, BloodHound, Burp Suite, Nmap)_                                        | **Metasploit**: framework modular untuk exploit delivery, payload generation, post-exploitation. **BloodHound**: ingest Active Directory data (LDAP, session, ACL) → graph database Neo4j → visualisasi attack path shortest route ke Domain Admin. **Burp Suite**: intercept & modify HTTP/S traffic untuk web app testing.                                                                                                                                                                                                | Deteksi: IDS/IPS signature, EDR behavioral analysis (Meterpreter in-memory), AD anomaly detection (BloodHound ingest pattern), WAF rule.                                                                                                                                                               | Red Team (internal), bug bounty, security consultant, militer (CYBERCOM training)                                                        | APT28 (Fancy Bear), APT41, ransomware operator (Conti, LockBit)                                                         |
| **Level 2** — Post-Exploitation & C2 _(Cobalt Strike, Empire, Havoc C2, DARKCOMET, Sliver)_                          | **Cobalt Strike**: commercial adversary simulation platform. Malleable C2 profile → traffic blend dengan legitimate (mimikari.com, Azure CDN). Sleep mask, UDRL (User Defined Reflective Loader), BOF (Beacon Object File). **Havoc C2**: open-source alternative dengan sleep obfuscation, x64 return address spoofing, indirect syscalls. **Empire**: PowerShell/Python agent. **DARKCOMET**: legacy RAT dengan keylogger, webcam capture, reverse shell.                                                                 | EDR: behavioral AI (Cobalt Strike default config terdeteksi — tapi malleable C2 bisa bypass). YARA rules, memory forensics (find injected beacon), network traffic analysis (C2 beaconing pattern: jitter, fixed interval). Network detection: JA3 fingerprint TLS, domain generation algorithm (DGA). | Red Team, adversary simulation (Breach & Attack Simulation), NATO cyber exercise                                                         | APT29 (Cozy Bear — Cobalt Strike), APT41 (Havoc), criminal RAT operator, ransomware affiliate (DARKCOMET era 2012–2016) |
| **Level 3** — Commercial Surveillance / Spyware _(Pegasus NSO Group, FinFisher/FinSpy, Predator Intellexa, Candiru)_ | **Pegasus**: 0-click exploit via iMessage/WhatsApp (FORCEDENTRY, KISMET) → jailbreak silen → kernel privilege escalation → install agent. Persistence via dylib injection, network injection (fake OTA update). **FinSpy**: multi-platform (iOS, Android, Windows, macOS, Linux). Infeksi via fake update, social engineering, 0-day/n-day. **Predator**: similar to Pegasus, dipakai oleh klien Intellexa.                                                                                                                 | Mobile: Lockdown Mode (Apple), Google Play Protect, MTP/MDM restriction, network traffic anomaly (C2 ke server known-bad). Forensic: iMazing, MVT (Mobile Verification Toolkit) dari Amnesty International. Deteksi Pegasus: **iShutdown** (analisis shutdown.log), **MVT** (backup analysis).         | Law enforcement (dengan warrant — teoretis), intelligence agency (Israel, UAE, Saudi, Mexico, India — terdokumentasi via Citizen Lab)    | Targeted espionage terhadap jurnalis, aktivis, politik oposisi, diplomat. Pegasus target: 50.000+ nomor (Amnesty 2021). |
| **Level 4** — Mobile & Hardware Forensics _(Cellebrite UFED, GrayKey, Victoria, PC-3000, Oxygen Detective)_          | **Cellebrite UFED**: physical extraction (bootloader exploit, JTAG, chip-off) + logical extraction. Bypass passcode via brute-force hardware (GrayKey: box kecil yang plug-in iPhone → crack 4-digit/6-digit PIN dalam jam). **Victoria**: HDD/SSD surface scan, SMART analysis, remap sector — digunakan untuk forensik media sebelum imaging. **PC-3000**: akses firmware controller langsung untuk recovery data dari drive yang tidak terdeteksi OS.                                                                    | Counter: strong passphrase (alphanumeric >12 char), FileVault/BitLocker full disk encryption, USB Restricted Mode (Apple), Secure Enclave rate limiting, physical destruction (degaussing, shredding).                                                                                                 | Law enforcement (FBI, Interpol, local police), digital forensics lab, corporate IR (insider threat investigation), data recovery service | Criminal forensics lab (kartel, organized crime), black market data recovery untuk destroy evidence                     |
| **Level 5** — Communications Intelligence _(Verint Systems, PRISM, UPSTREAM, TEMPORA)_                               | **Verint**: intercept platform untuk voice (PSTN, VoIP, mobile), metadata analysis, link analysis. **PRISM**: program NSA untuk koleksi data "directly from the servers" of Microsoft, Yahoo, Google, Facebook, PalTalk, YouTube, Skype, AOL, Apple (Snowden 2013). **UPSTREAM**: tap pada fiber optic backbone (undersea cable, internet exchange point). **TEMPORA**: GCHQ equivalent — 3 days content buffer, 30 days metadata buffer.                                                                                   | E2EE (Signal, WhatsApp, Session), onion routing (Tor), VPN layering, decentralized communication. Legal: GDPR, Fourth Amendment (US).                                                                                                                                                                  | NSA (PRISM, UPSTREAM, XKEYSCORE), GCHQ (TEMPORA), Verint klien: intelligence agencies & telecom provider global                          | — (level ini hanya state-level, tidak ada aktor non-state yang operasional)                                             |
| ☠️ **Level 6** — Nation-State SIGINT Platforms _(XKEYSCORE, Palantir Gotham, ICREACH, MARINA)_                       | **XKEYSCORE**: "Google untuk data intercept NSA" — query keyword, email address, phone number, cookies, MAC address, activity across the internet. Snowden: "Could watch anyone, anywhere, anytime." **Palantir Gotham**: data fusion platform — ingest structured & unstructured data (SIGINT, HUMINT, OSINT, financial, geospatial) → link analysis, pattern detection, predictive policing. **ICREACH**: NSA internal search engine untuk metadata teleponi (DNI/DNR). **MARINA**: internet metadata storage & analysis. | Tidak ada counter teknis individual. Counter: minimize digital footprint, avoid predictable patterns, use Tor + E2EE + compartmentalization. Legal/political: FOIA, whistleblower protection, encryption advocacy.                                                                                     | NSA, GCHQ, CIA, FBI, DHS, Five Eyes + extended partners. Palantir: also LAPD, ICE, military, healthcare, finance                         | — (state monopoly)                                                                                                      |

---

## Sheet 2 — Dual-Use Spectrum: Siapa yang Pakai Tool yang Sama?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DUAL-USE SPECTRUM                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  DEFENSE ◄────────────────────────────────────────────────► OFFENSE       │
│                                                                             │
│  Blue Team              Red Team              APT Group              Nation-State
│  ──────────             ────────              ─────────              ───────────
│  Maltego (brand         Maltego (target      Maltego (target        Palantir (target
│  protection)             recon)               profiling)              population)
│                                                                             │
│  Metasploit (patch       Metasploit (exploit  Metasploit (initial    XKEYSCORE
│  validation)              delivery)            access)               (mass surveillance)
│                                                                             │
│  BloodHound (AD          BloodHound (attack   Cobalt Strike (pivot,   PRISM
│  hardening)               path hunting)        persistence)          (upstream collection)
│                                                                             │
│  Cellebrite (victim       Cellebrite (evidence  FinSpy (covert        Verint
│  device recovery)         extraction)         surveillance)         (comm intercept)
│                                                                             │
│  Cobalt Strike (BAS)     Cobalt Strike (red    DARKCOMET (criminal   Pegasus
│  (Breach & Attack        team engagement)      RAT)                 (0-click spyware)
│  Simulation)                                                                │
│                                                                             │
│  Victoria (HDD health    Victoria (pre-         PC-3000 (evidence      GrayKey
│  check)                  imaging forensics)     recovery)           (passcode brute)
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!tip] Framework Evaluasi Dual-Use
> Sebelum menggunakan tool apapun dari sheet ini, tanyakan:
>
> 1. **Apakah saya punya otorisasi eksplisit** (written, scope-defined) untuk target sistem?
> 2. **Apakah tujuannya defensive** (patch, harden, recover, investigate) atau offensive (exploit, surveil, destroy)?
> 3. **Apakah ada oversight & akuntabilitas** (legal review, IRB, chain of custody)?
> 4. **Apakah data hasil penggunaan dilindungi** (encryption at rest, need-to-know, retention limit)?

---

## Sheet 3 — Anatomi Teknis: Bagaimana Tool Level Tertinggi Bekerja

### XKEYSCORE: Arsitektur Query Mass Surveillance

```
[Internet Backbone] ──► [TAP / Fiber Split] ──► [UPSTREAM Collection]
                              │
                              ▼
                    ┌─────────────────────┐
                    │  XKEYSCORE Nodes    │  ← Distributed di seluruh world
                    │  (Narus / Boeing)   │     ~700 server (estimasi Snowden)
                    └─────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  DNI/DNR Database   │  ← Deep Packet Inspection
                    │  (MARINA, MAINWAY)  │     Metadata + Content selector
                    └─────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  Analyst Query UI   │  ← "Show me all activity of
                    │  (XKEYSCORE)        │     person X in last 30 days"
                    └─────────────────────┘
                              │
                              ▼
                    [Analyst Workstation]
                    (Thin client, query logged,
                     but Snowden: "no audit trail
                     yang efektif untuk abuse")
```

> **Snowden Quote (2013):** _"I could see anyone, anywhere, anytime. I could pull up your email, your passwords, your phone records, your credit cards, your text messages. I could see your communications with your accountant, your lawyer, your doctor. And I could do this sitting at my desk."_

### Pegasus: 0-Click Kill Chain (FORCEDENTRY / KISMET)

```
[Target Phone Number]
         │
         ▼
┌──────────────────────┐
│  iMessage / WhatsApp │  ← Malicious attachment / message preview
│  (0-click = no user    │     trigger exploit saat notifikasi muncul
│   interaction needed)  │
└──────────────────────┘
         │
         ▼
┌──────────────────────┐
│  Memory Corruption   │  ← Stage 1: JBIG2 exploit (FORCEDENTRY)
│  in Image Parser     │     Stage 2: Integer overflow → arbitrary code
└──────────────────────┘
         │
         ▼
┌──────────────────────┐
│  Jailbreak / Root    │  ← Stage 3: Kernel privilege escalation
│  (Silent, no reboot) │     Patch kernel → disable code signing
└──────────────────────┘
         │
         ▼
┌──────────────────────┐
│  Agent Installation  │  ← Stage 4: Daemon persistence
│  (Dylib injection,    │     Keylogger, mic record, camera,
│   network injection)   │     GPS tracking, file exfiltration
└──────────────────────┘
         │
         ▼
    [C2 Server]
    (NSO Group infrastructure,
     front company, cloud provider)
```

> **Citizen Lab Finding (2021):** Pegasus menggunakan **"network injection"** — saat target browsing web biasa, traffic di-redirect ke exploit server. Ini memerlukan akses ke ISP level atau BGP hijack capability.

### Cobalt Strike: Malleable C2 & EDR Evasion

```
[Target Network]
      │
      ▼
┌──────────────────────────────┐
│  Beacon (in-memory DLL)      │  ← Reflective DLL injection
│  - Sleep mask (encrypt self  │     Sleep 60s → wake → check C2
│    saat idle)                │     Jitter: 10-30% variance
│  - UDRL (custom loader)      │     Malleable C2: HTTP GET/POST
│  - BOF (in-memory execution) │     yang mimic legitimate app
└──────────────────────────────┘
      │
      ▼
[Legitimate-looking HTTPS]
      │  (mimic Microsoft Update, Azure CDN, Google API)
      ▼
[C2 Team Server]
      │
      ▼
[Operator Console]
```

> **Key Insight:** Cobalt Strike bukan malware — ini adalah **"adversary simulation platform"** yang dipakai Red Team. Tapi lisensi yang bocor + cracked version menjadikannya tool #1 untuk ransomware operator (Conti, LockBit, BlackCat).

---

## Sheet 4 — Hardware Forensics: Victoria & PC-3000 dalam Konteks Militer

| Tool                | Fungsi Forensik                                                            | Fungsi Militer/Intel                                                                                                   | Overlap dengan Cheat Engine                    |
| ------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **Victoria**        | Surface scan HDD/SSD, remap bad sector, SMART analysis, HPA/DCO detection. | Pre-imaging verification: pastikan drive tidak ada hidden area (HPA/DCO) sebelum clone.                                | Level 5 DMA: PC-3000 juga akses hardware-level |
| **PC-3000**         | Akses firmware controller langsung (PCB-level), bypass OS untuk recovery.  | Recovery data dari drive yang "dihancurkan" (firmware corruption, controller failure). Identik dengan teknik DMA card. | Level 5 Cheat Engine: PCIe DMA bypass software |
| **Cellebrite UFED** | Physical & logical extraction dari mobile device.                          | Bypass lock screen, decrypt backup, extract deleted data.                                                              | —                                              |
| **GrayKey**         | Brute-force passcode iPhone via hardware box (USB connection).             | Law enforcement: unlock device confiscated dalam hitungan jam.                                                         | —                                              |

> [!note] Victoria dalam Konteks Vault
> Victoria sudah ada di vault dalam konteks **data recovery & service tools**. Di dokumen ini, Victoria dimasukkan dalam konteks **pre-forensic verification**: sebelum imaging forensik, investigator menggunakan Victoria untuk verifikasi integritas media dan deteksi hidden area (HPA/DCO) yang mungkin disembunyikan aktor.

---

## Peta Posisi Semua Level

```
MILITARY & INTELLIGENCE TOOLS
Level 0  │ OSINT (Maltego, Shodan)      → Publik, legal, zero exploit
Level 1  │ Pentest Framework            │ Metasploit, BloodHound, Burp
Level 2  │ Post-Exploitation & C2       │ Cobalt Strike, Havoc, Empire, DARKCOMET
Level 3  │ Commercial Spyware           │ Pegasus, FinSpy, Predator — 0-click mobile
Level 4  │ Hardware Forensics           │ Cellebrite, GrayKey, Victoria, PC-3000
Level 5  │ Comms Intelligence           │ Verint, PRISM, UPSTREAM, TEMPORA
Level 6  │ Nation-State SIGINT          │ XKEYSCORE, Palantir, ICREACH, MARINA

COUNTERMEASURE STACK (Bottom-up defense)
Level 0  │ Data Hygiene + OpSec         → Minimize footprint
Level 1  │ Patch Management + EDR       │ Detect exploit delivery
Level 2  │ Network Detection + Behavioral│ Beaconing, JA3, DGA analysis
Level 3  │ Mobile Hardening             │ Lockdown Mode, E2EE, MVT scan
Level 4  │ Encryption + Physical Sec    │ FDE, Secure Enclave, destruction
Level 5  │ E2EE + Decentralized Comms   │ Signal, Session, Tor
Level 6  │ Political + Legal            │ FOIA, encryption advocacy, policy
```

---

## Koneksi: Military Tools ↔ Cheat Engine ↔ Dark Web

```
Cheat Engine Level 3 (BYOVD Kernel Driver)
        │
        └──► Cobalt Strike (Level 2) menggunakan teknik kernel
             untuk bypass EDR. BYOVD juga dipakai ransomware.

Cheat Engine Level 5 (DMA PCIe)
        │
        └──► PC-3000 (Level 4 Forensics) dan Victoria
             menggunakan konsep identik: bypass software layer,
             akses hardware langsung via controller/DMA.

Dark Web Level 3 (Tor .onion)
        │
        └──► Pegasus C2 (Level 3) dan Cobalt Strike C2
             sering menggunakan infrastructure yang sama:
             bulletproof hosting, onion routing, cryptocurrency payment.

Dark Web Level 8 (Nation-State SIGINT)
        │
        └──► XKEYSCORE (Level 6) memantau traffic Tor
             via exit node monitoring dan correlation attack.
             Tor tidak melindungi dari global passive adversary (NSA).
```

---

## Struktur Folder

```
military-and-intelligence-tools/
├── 📄 military-and-intelligence-tools-hub.md         ← yg sekarang, di-strip jadi ringkasan + navigasi
├── 🗂️ 01-osint-and-reconnaissance/
│   ├── maltego.md
│   ├── shodan.md
│   └── google-dorks.md
├── 🗂️ 02-pentest-frameworks/
│   ├── metasploit.md
│   ├── bloodhound.md
│   └── burp-suite.md
├── 🗂️ 03-c2-and-post-exploitation/
│   ├── cobalt-strike.md
│   ├── havoc-c2.md
│   ├── empire.md
│   └── sliver.md
├── 🗂️ 04-commercial-surveillance-and-spyware/
│   ├── pegasus.md
│   ├── finspy.md
│   └── predator.md
├── 🗂️ 05-mobile-and-hardware-forensics/
│   ├── cellebrite-ufed.md
│   ├── graykey.md
│   ├── victoria-hdd.md
│   └── pc-3000.md
├── 🗂️ 06-communications-intelligence-(sigint)/
│   ├── verint.md
│   ├── prism.md
│   └── upstream-and-tempora.md
├── 🗂️ 07-nation-state-platforms/
│   ├── xkeyscore.md
│   ├── palantir-gotham.md
│   └── icreach.md
├── 📄 dual-use-spectrum-and-ethical-framework.md
└── 📄 countermeasure-stack.md
```

## 🔗 Lihat Juga

- [[underground-knowledge]] — Cheat Engine Level 0–6 + Dark Web Level 0–8
- [[cyber-security]] — Blue Team vs Red Team defensive stack
- [[hardware-hacking-re]] — PC-3000, Victoria, dan teknik akses hardware-level
- [[network-security|OSI Layer Hierarchy]] — Where UPSTREAM/TEMPORA live (Layer 1–2)
- [[cryptography-biometrics|Biometrik Levels]] — Passcode vs biometric vs FDE
- [[hierarchy-osint-rf]] — OSINT complement untuk Level 0

---

_military-and-intelligence-tools Hierarchy | Shadow Arsenal Level 0–6 | Dual-Use Knowledge Base_
