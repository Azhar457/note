---
title: "Cyber Range and Adversary Emulation Hierarchy"
tags:
  - atlas
  - cyber-range
  - attack-defense
  - adversary-emulation
  - purple-team
  - red-team
aliases:
  - "hierarchy-cyber-range-adversary-emulation"
created: "2026-07-28"
updated: '2026-07-28'
status: pending
cssclasses:
  - wide-table
  
---


# ⚔️ HIERARCHY CYBER RANGE & ADVERSARY EMULATION — Dari VM Capture-the-Flag sampai Full-Scope Enterprise Adversary Simulation

> Cyber range dan adversary emulation adalah **satu-satunya cara realistis untuk menguji deteksi dan respons defender terhadap serangan nyata** tanpa risiko terhadap produksi. Berbeda dengan penetration testing (cari vulnerability statis), adversary emulation **meniru perilaku attacker persisten** (APT-style) — fokus pada chain TTP, bukan single exploit. Hirarki ini memetakan evolusi latihan dari **Level 0 (CTF box individual)** sampai **Level 6 (full-scope multi-tenant enterprise emulation)** — semua level **universal** dan tidak terikat event tertentu.

> [!info] Cara Baca
> Level 0–1 untuk pemula/individu belajar exploit chain. Level 2–3 untuk tim attack-defense di kompetisi atau training internal. Level 4+ untuk purple team profesional, SOC maturity assessment, atau compliance (TIBER-EU, CBEST). Setiap level mengukur **kesetiaan emulasi terhadap attacker nyata**. Untuk methodology konkret saat kompetisi Attack-Defense, lihat [[ctf-competition-methodology-strategy]]. Untuk tool arsenal, lihat [[ctf-tool-arsenal-universal]].

---

## Tabel Utama — Level 0 sampai Level 6

| ⚔️ Level | 🎯 Format | 🛡️ Defender Side | ☠️ Attacker Side | 🎯 Kompetensi yang Diukur | 🛠️ Contoh Platform / Event |
|---|---|---|---|---|---|
| **Level 0** — VM Box / Single-Host Capture-the-Flag | Satu VM Linux/Windows, attacker dapat foothold lalu root | Tidak ada defender aktif (offline analysis saja) | Recon → exploit → privilege escalation → baca flag | Enumeration, exploit chain dasar, privilege escalation, post-exploitation baca-flag | HackTheBox, TryHackMe, VulnHub, Proving Grounds |
| **Level 1** — Static Multi-Host Network Range | Multi-VM network statis, attacker harus pivot antar host | Tidak ada defender aktif | Pivot, lateral movement, AD exploitation, persistence | Multi-stage exploitation, Windows AD, internal recon, file transfer antar host | HackTheBox Pro Labs, OffSec PG Play, CyberDefenders, TCM Academy |
| **Level 2** — Attack-Defense CTF (Auto-Grader) | Setiap tim dapat identical server, saling serang, flag auto-injected | Tim bertahan: monitor service, patch bug, inject checker | Tim menyerang: exploit service sendiri-sendiri, curi flag | Service hardening, rapid patching, exploit reliability, flag injection, monitoring | RuCTF, iCTF, FAUST, RuCTFE, ENOWARS, A/D CTF |
| **Level 3** — Cooperative Range (Red vs Blue, Evaluator-Driven) | Tim red, tim blue, white cell evaluator dengan scoring rubric | Active defender (blue team) menjalankan SIEM/EDR/NDR | Active attacker (red team) dengan objectives | Communication to evaluator, IR procedure, detection engineering, TTP chaining | CCDC (US collegiate), Locked Shields (NATO), Cyber Coalition, regional purple team exercise |
| **Level 4** — Adversary Emulation (Threat-Informed) | Red team murni meniru TTP publik dari threat actor tertentu (APT29, FIN7, Lazarus) | Production-equivalent blue team dengan full SOC tooling | Adversary emulation dengan tools seperti Prelude Operator, Atomic Red Team | MITRE ATT&CK coverage, evasion, persistence under detection, intelligence-driven testing | Purple Team exercise internal, TIBER-EU lite, CBEST prep, SCYTHE/Outflank engagements |
| **Level 5** — Full-Scope Enterprise Adversary Simulation | Red team benar-benar menyerang production-like infra (replica), tanpa notice, dengan tujuan bisnis nyata | Real SOC analyst dengan prosedur IR lengkap | Nation-state-equivalent TTP: initial access → persistence → C2 → exfil → objective | Stealth, multi-week operation, decision under pressure, legal/ethical boundaries | TIBER-EU (EU central banks), CBEST (UK), AASE (Australia), iCAST (MAS Singapore) |
| **☠️ Level 6** — Multi-Tenant / Critical Infrastructure Range | National-scale exercise: ribuan user, multi-domain (cyber + comms + physical + decision) | Distributed blue teams + national CSIRT + CISO | Coordinated red team + insider scenarios + kinetic impact simulation | Crisis decision, cross-sector coordination, public communication, attribution | NATO Cyber Coalition, US Cyber Guard, GridEx (power grid), national CIRT drills |

---

## Peta Visual — Kesetiaan Emulasi vs Kompleksitas Operasional

```
Kesetiaan Emulasi ↑
                │  L6 ─ National Cyber Drill        ●●●●●●  Multi-sector
                │  L5 ─ Enterprise Adversary Sim    ●●●●●    Production replica
                │  L4 ─ Adversary Emulation         ●●●●     MITRE ATT&CK guided
                │  L3 ─ Cooperative Red vs Blue     ●●●        White cell eval
                │  L2 ─ Attack-Defense CTF          ●●          Auto-grader
                │  L1 ─ Multi-Host Range            ●            Single-team
                │  L0 ─ Single-Host Box            
                │       └─────────────────────────────────────→ Kompleksitas Operasional
                │
                └─────────────────────────────────────→ Resources Needed
```

---

## Kenapa Hirarki Ini Penting

### 1. Penetration Test ≠ Adversary Emulation

| Aspek | Pen Test | Adversary Emulation |
|-------|----------|---------------------|
| **Goal** | Cari vulnerability | Uji deteksi & respons |
| **Approach** | Covert, opportunistic | Covert to defender, explicit TTP chain |
| **Output** | Vulnerability list | Detection gap analysis, mean-time-to-detect |
| **Timeframe** | 1–4 minggu | 2–12 minggu |
| **Success metric** | # vulnerabilities found | # TTP undetected + MTTD/MTTR |
| **Stakeholder** | CISO, audit | SOC, IR, detection engineering |

**Jika defender tidak detect TTP publik dari APT29 dalam 24 jam, mereka belum ready untuk face real APT29.**

### 2. Setiap Level Butuh Infrastructure Berbeda

| Level | Infra Minimum | Budget Range | Skill Build |
|-------|---------------|--------------|-------------|
| L0 | 1 VM (8 GB RAM) | Gratis | Lab individual |
| L1 | 4–8 VM dalam 1 host | $0–200 | Multi-host pivot |
| L2 | Rack server di lab, shared dengan tim | $1k–5k | Team operation |
| L3 | Dedicated range (Azure/AWS GovCloud), SIEM full-stack | $10k–100k | Defender operation |
| L4 | Production-equivalent infra + threat intel subscription | $50k–250k | Threat-informed red |
| L5 | Custom infra + legal/insurance + comms with regulator | $200k–1M+ | Enterprise-grade |
| L6 | National CERT coordination + multi-agency | $1M+ | Whole-of-nation |

### 3. Detection Engineering adalah Output Utama L4+

Emulator (red team) menjalankan TTP dari ATT&CK matrix. Defender (blue team) harus:
- **Detect** TTP via log/SIEM/EDR
- **Triage** alert untuk tahu mana true positive
- **Contain** sebelum attacker pivot
- **Eradicate** persistence mechanism
- **Recover** tanpa data loss

**Metric kunci:** Mean-Time-To-Detect (MTTD), Mean-Time-To-Respond (MTTR), % ATT&CK technique covered.

---

## Kontrak Kompetensi Per Level

### Level 0 — Single-Host Box
**Attacker harus bisa:** Nmap scan, cari versi vulnerable, exploit publik (searchsploit), privilege escalation via SUID/kernel exploit, baca flag dari root home.
**Defender side:** Tidak ada — Anda main offline saja.

### Level 1 — Multi-Host Network Range
**Attacker harus bisa:** Pivot via SSH tunnel, exploit Windows AD (Kerberoasting, AS-REP Roasting, DCSync), baca SAM database, traverse trust boundary.
**Defender side:** Tidak ada — analisis post-mortem saja.

### Level 2 — Attack-Defense CTF
**Attacker harus bisa:** Tulis exploit reliable (bukan one-shot), adapt ke patch defender, monitor checker script (siapa yang inject flag?), anonymize attack vector agar tidak ditelusuri.
**Defender harus bisa:** Patch bug dalam menit, tulis checker script robust, monitor log service, hardening tanpa break functionality, sinkronisasi dengan anggota tim.

### Level 3 — Cooperative Red vs Blue
**Red:** Chain 3+ TTP, adapt ke detection defender, komunikasikan intent ke white cell.
**Blue:** Jalankan playbook IR, tulis detection rule real-time, triage alert, eskalasi sesuai severity.
**White cell:** Score rubric, facilitate debrief, capture metrics.

### Level 4 — Threat-Informed Adversary Emulation
**Red:** Pilih threat actor (APT29, FIN7, Lazarus), eksekusi TTP publik mereka sesuai ATT&CK mapping, document setiap step.
**Blue:** Setiap TTP harus menghasilkan alert + ticket IR. Gap analysis di akhir.

### Level 5 — Full-Scope Enterprise Simulation
**Red:** Objective-based (exfiltrate crown jewel data), bebas pilih vector, weeks-long operation, evasi detection.
**Blue:** Production IR procedure, executive communication, legal/regulatory compliance.
**Both:** Safety constraints (no destructive action, no real customer data).

### Level 6 — National Critical Infrastructure Drill
**Red+Blue+White:** Multi-domain coordination, kinetic-cyber convergence, public communication, decision under uncertainty.
**Outcome:** National policy input, sector-specific mitigation, international cooperation protocol.

---

## ATT&CK Coverage Matrix — Generic Threat Actor Mapping

| Threat Actor           | Origin                   | Top ATT&CK Techniques                                                                  | Use Case Emulation                |
| ---------------------- | ------------------------ | -------------------------------------------------------------------------------------- | --------------------------------- |
| **APT29 (Cozy Bear)**  | Russia SVR               | T1559 (IPC), T1078 (Valid Accounts), T1056 (Input Capture), T1573 (Encrypted C2)       | Diplomatic & government targeting |
| **FIN7**               | Russia/Ukraine financial | T1059 (Command Interpreter), T1027 (Obfuscation), T1567 (Exfil over web)               | Financial, retail, hospitality    |
| **Lazarus Group**      | North Korea DPRK         | T1561 (Disk Wipe), T1485 (Data Destruction), T1490 (Inhibit System Recovery)           | Banking, crypto, destructive      |
| **APT28 (Fancy Bear)** | Russia GRU               | T1078.004 (Cloud Accounts), T1110 (Brute Force), T1136 (Create Account)                | Government, military, election    |
| **Scattered Spider**   | US/UK cybercrime         | T1656 (Impersonation), T1078.004 (Cloud), T1213 (Data from Cloud)                      | Telecom, SaaS, social engineering |
| **Volt Typhoon**       | China PRC                | T1078 (Valid Accounts), T1133 (External Remote Services), T0855 (Unauthorized Command) | Critical infrastructure, OT       |

**Pemilihan threat actor** tergantung industry dan risk profile Anda. Bank → FIN7. Telecom → Scattered Spider. Energy → Volt Typhoon.

---

## Plot Twists

> [!danger] Plot Twist 1: Attack-Defense Lebih Keras dari CTF Statis
> Attack-Defense (L2) memerlukan **operation skill** yang tidak dilatih di jeopardy: monitoring, patching, teamwork under pressure. Banyak tim top-50 dunia di jeopardy ranking **gagal total** di attack-defense karena mental model mereka "solve" bukan "operate". Lompatan L2 → L3 (cooperative) bahkan lebih besar karena ada **tim blue yang aktif melawan Anda**.

> [!tip] Plot Twist 2: Adversary Emulation (L4+) Butuh Threat Intel Subscription
> Tanpa akses ke **MITRE ATT&CK + threat actor reporting** (Mandiant, CrowdStrike, Recorded Future, VulnCheck), Anda tidak bisa emulate dengan setia. Emulasi yang "asal pilih TTP" tanpa intelligence backing hanya jadi "advanced pen test" — bukan adversary emulation. **Threat intel adalah prerequisite, bukan nice-to-have.**

> [!info] Plot Twist 3: Detection Coverage ≠ Prevention Coverage
> WAF/IPS/EDR vendor akan klaim "coverage 95% ATT&CK". Realitanya: coverage hanya terhadap **signature-based detection**, bukan behavioral detection. Attacker yang pakai TTP publik tapi dikombinasikan dengan LOLBin (Living Off the Land Binaries) sering bypass 80% signature. **Behavioral detection** (process tree anomaly, parent-child relationship) butuh Sigma rules + UEBA — skill yang berbeda dari "install EDR".

> [!warning] Plot Twist 4: L5+ Butuh Legal Framework yang Matang
> Sebelum red team "masuk" ke production-like environment, Anda butuh:
> - **Rules of Engagement (RoE)** — apa yang boleh dan tidak
> - **Get-out-of-jail card** — kapan harus stop
> - **Liability insurance** — kalau ada kerusakan
> - **Communication protocol** — siapa yang harus tahu, kapan
> - **Deconfliction** — bagaimana kalau real attacker masuk saat Anda lagi operasi
> Tanpa ini, Anda **bisa kena tuntutan hukum** bahkan kalau Anda "berhasil". Ini kenapa L5+ biasanya disponsori regulator (TIBER-EU, CBEST) yang menyediakan kerangka legalnya.

---

## Cross-Link ke Atlas Lainnya

- **Cyber Kill Chain (TTTP chain detail)** → [[00_Atlas/hierarchy-cybersecurity-defense-architecture]]
- **Endpoint Defense (EDR detection)** → [[hierarchy-endpoint-security]]
- **Network Detection (NDR/SIEM)** → [[hierarchy-network-security]]
- **Threat Modeling (risk-based exercise design)** → [[hierarchy-threat-modeling]]
- **Master Index** → [[master-index]]

---

*Cyber Range & Adversary Emulation Hierarchy | Level 0 (Single Box) → Level 6 (National Drill) · Kesetiaan Emulasi Naik · ATT&CK Coverage + Detection Engineering = Output Utama*

audited
---
