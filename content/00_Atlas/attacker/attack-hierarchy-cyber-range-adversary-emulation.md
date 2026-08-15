---
title: Attack Perspective — Cyber Range & Adversary Emulation
tags:
- attack
- red-team
- adversary-emulation
- mitre-attack
- purple-team
- cyber-range
source: hierarchy-cyber-range-adversary-emulation.md
status: complete
created: '2026-08-14'
updated: '2026-08-14'
cssclasses:
  - wide-table
  
---


# 🔴 Attack Perspective: Cyber Range & Adversary Emulation

> **Standar deepdive:** Setiap Level (0–6) dipetakan ke **konkret TTP chain, CVE eksploitasi, evasion teknik, detection gap, dan operasional tool**. Ini bukan teori range — ini **playbook red team** dengan perspektif defender detection gap.

---

## 1. Threat Model — Red Team Operator Per Level

| Level | Capability | Time Budget | Detection Evasion Requirement | CVE Dependency |
|-------|-----------|-------------|------------------------------|---------------|
| **L0** CTF Box | Script kiddie → Tool operator | 1-8 jam | Tidak perlu | Exploit publik, SUID |
| **L1** Multi-Host | Manual exploiter | 1-3 hari | Minimal | AD exploit (Kerberoasting, DCSync) |
| **L2** A/D CTF | Tool operator + team ops | 4-8 jam (per match) | Basic (monitor checker, anonymize) | Service-specific RCE |
| **L3** Cooperative | Manual exploiter + comms | 1-3 minggu | Active (evasion saat blue detect) | Real-world CVE chain |
| **L4** Adversary Emul | PrivEsc + AD specialist | 2-8 minggu | **Behavioral evasion wajib** | Threat-informed, custom |
| **L5** Enterprise Sim | C2 operator | 4-12 minggu | **Full stealth** (memory-only, no IoC) | Zero-day atau N-day strategic |
| **L6** National Drill | APT simulator | 3-6 bulan | Multi-vector, kinetic-cyber convergence | Custom implant, supply chain |

---

## 2. Per-Level Attack Chain (MITRE ATT&CK Mapped)

### L0 — Single-Host CTF (Recon → Exploit → Root → Flag)

**Standard Chain:**
1. **Recon** (T1595.001, T1592.002) — Nmap + searchsploit
2. **Initial Access** (T1190) — Public exploit (CVE-2019-5736 runc, CVE-2021-3156 sudo)
3. **Execution** (T1059) — Shell via exploit payload
4. **Privilege Esc** (T1053, T1548.003) — SUID binary abuse, kernel exploit
5. **Credential Access** (T1003.001) — /etc/shadow, SAM dump
6. **Collection** (T1005) — Read flag file (root home, hidden directory)

**Evasion:** Tidak perlu. Defender = offline. Target: kecepatan.

**CVE Toolkit L0:**
- CVE-2021-3156 (Baron Samedit) — sudo heap overflow → root
- CVE-2019-5736 (runc) — container escape (jika VM = container host)
- CVE-2022-0847 (Dirty Pipe) — kernel 5.8-5.16 local root
- CVE-2023-4911 (Looney Tunables) — glibc buffer overflow (perangkat Linux umum)

---

### L1 — Multi-Host Network Range (Pivot + AD Exploitation)

**Standard Chain:**
1. **Recon** — Nmap + LLMNR/NBT-NS poisoning (Responder)
2. **Initial Access** — Phishing / Exploit web app (jika ada)
3. **Execution** — Metasploit / custom payload
4. **Persistence** — Scheduled task / Service (T1053, T1543)
5. **Privilege Esc** — Kerberoasting (Rubeus) / AS-REP Roasting
6. **Credential Access** — DCSync (T1003.006), LSASS dump (T1003.001)
7. **Discovery** — BloodHound / SharpHound (T1087, T1484)
8. **Lateral Movement** — SMB (PsExec) / WMI / WinRM / SSH tunnel (T1021)
9. **Collection** — SAM database, AD database (NTDS.dit) extraction
10. **Impact** — Domain dominance (DA access), data exfil

**Evasion L1:**
- Randomize scan timing (jitter 30-300s)
- Gunakan port umum (443, 80) untuk C2
- Encrypt payload (AES-256-GCM)

---

### L2 — Attack-Defense CTF (Operation Under Pressure)

**Red Team Requirements:**
- **Exploit Reliability:** Tidak one-shot. Harus adapt ke patch defender dalam menit.
- **Monitoring:** Monitor checker script (siapa inject flag? Kapan defender patch?)
- **Anonymization:** Gunakan TOR / VPN / burnt accounts — defender akan trace IP
- **Rapid Adaptation:** Defender patch service dalam menit — red team harus pivot ke vector baru

**Blue Team Requirements:**
- **Rapid Patching:** Patch bug tanpa break service (butuh rollback)
- **Checker Script:** Robust (tidak false positive, tidak bisa dipalsukan)
- **Log Monitoring:** Monitor akses service, file access, network connections
- **Hardening:** Service isolation, firewall, rate limiting

**Attack-Defense Gap:**
- Defender yang fokus "solve bug" tapi tidak **monitor** akan gagal total.
- Red team yang fokus "get flag" tapi tidak **adapt ke patch** akan kehilangan semua akses dalam menit pertama.

---

### L3 — Cooperative Red vs Blue (White Cell Evaluation)

**Red Team Contract:**
- Chain 3+ TTP (MITRE ATT&CK mapping wajib)
- Dokumentasi setiap step (intent, technique, outcome)
- Adaptasi saat defender detect (evasion wajib)
- Komunikasi ke white cell (bukan "surprise attack")

**Blue Team Contract:**
- Playbook IR dijalankan real-time
- Detection rule ditulis dan deploy saat operasi
- Triage alert → severity → containment → eradication
- Post-mortem dalam 24 jam

**White Cell Metrics:**
- MTTD (Mean Time to Detect) per TTP
- MTTR (Mean Time to Respond)
- % ATT&CK technique covered (detection + prevention)
- False positive rate

---

### L4 — Adversary Emulation (Threat-Informed, MITRE ATT&CK Driven)

**Red Team Requirement: Threat Intel Subscription**

Tanpa akses ke:
- MITRE ATT&CK Enterprise + Sub-techniques
- Threat Actor Reports (Mandiant M-Trends, CrowdStrike Global Threat Report, Recorded Future Intelligence)
- CVE Intelligence (NVD, MITRE, vendor advisories)
- Atomic Red Team (test case library)

Emulasi hanya akan jadi "advanced pen test" — bukan **adversary emulation**.

**Standard Chain L4 (APT29 / Cozy Bear Example):**
1. **Initial Access** — T1190 (Exploit Public-Facing App) / T1566.002 (Spearphishing Link)
2. **Execution** — T1059.001 (PowerShell) — download cradle
3. **Persistence** — T1546.003 (WMI Event Subscription) — `__EventFilter`
4. **Privilege Esc** — T1078.004 (Cloud Accounts) — valid cloud admin credentials
5. **Defense Evasion** — T1562.001 (Impair Defenses: AMSI Bypass) — memory patch
6. **Credential Access** — T1550.002 (Pass-the-Hash) — NTLM relay
7. **Discovery** — T1018 (Remote System Discovery) — PowerView
8. **Lateral Movement** — T1550.003 (Pass-the-Ticket) — Kerberos delegation
9. **Collection** — T1005 (Data from Local System) — staged archive
10. **Exfiltration** — T1041 (Exfiltration over C2 Channel) — HTTPS with domain fronting
11. **Impact** — T1486 (Data Encrypted for Impact) — selective ransomware (optional)

**Evasion L4 Wajib (Behavioral):**
- **Direct Syscalls** (T1055.012) — SysWhispers3, HellsGate
- **AMSI/ETW Bypass** (T1562.001) — Memory patch, indirect syscalls
- **Module Stomping / Process Hollowing** (T1055) — Custom loader, DONUT
- **LOLBins** (T1218) — certutil, mshta, rundll32 — signed Microsoft binaries
- **Traffic Shaping** — Jitter 30-300s, business hours, low bandwidth, JA3 spoof
- **Encrypted Payload** — AES-256-GCM + custom framing, key rotation per session

---

### L5 — Full-Scope Enterprise Adversary Simulation (Objective-Based, Multi-Week)

**Objective (Business-Driven, Bukan Technical Only):**
- "Exfiltrate crown jewel data (database X / file server Y) dalam 30 hari"
- "Dapatkan akses domain admin dan deploy ransomware ke 20% workstation dalam 60 hari"
- "Compromise supply chain: inject malicious artifact ke CI/CD pipeline dan deploy ke production"

**Safety Constraints (RoE — Rules of Engagement):**
- No destructive action (tidak wipe semua data)
- No real customer data exfil (hanya mock data / synthetic)
- Stop saat defender escalate ke executive / legal
- Get-out-of-jail card saat red team kehilangan kontrol
- Liability insurance aktif
- Communication protocol: siapa harus tahu, kapan, bagaimana

**OpSec Stack L5:**

| Layer | Implementation |
|-------|---------------|
| **Infrastructure** | Dedicated redirector (nginx/Caddy) per campaign, burner domains, cloud VPS |
| **C2 Framework** | Havoc / Sliver / Mythic — custom Malleable profile, BOF support, encrypted |
| **Payload Delivery** | In-memory (BOF, DONUT, sRDI), no disk touch, direct syscalls |
| **Lateral Movement** | SMB (CrackMapExec) + WMI + RDP hijack + SSH tunnel — multi-vector |
| **Credential Access** | LSASS (Mimikatz build custom) + DPAPI + Browser cookies |
| **Persistence** | WMI Event Subscription + COM Hijacking + Registry — multi-layer |
| **Evasion** | AMSI/ETW patch + Module Stomping + Indirect Syscalls + Timestamp manipulation |
| **Exfiltration** | Chunked (1MB chunks), encrypted (AES-256-GCM), DNS + HTTPS dual-channel |
| **Logging** | Structured JSON ke C2, tidak ada stdout/stderr ke disk |
| **Cleanup** | Scheduled task otomatis hapus artifacts saat exit/crash |

---

### L6 — National Critical Infrastructure Drill (Multi-Domain, Kinetic-Cyber Convergence)

**Scope:**
- Multi-domain: Cyber + Communications + Physical Security + Decision-Making
- Multi-sector: Energy, Telecom, Finance, Healthcare, Government
- National CERT coordination + International cooperation protocol
- Public communication + Crisis management simulation

**Red Team:** Coordinated multi-vector attack (cyber + social engineering + physical simulation)
**Blue Team:** Distributed SOC analysts + National CSIRT + Executive decision makers
**White Cell:** Multi-agency evaluation + Policy recommendation

**Attack Vector L6 (Coordinated):**
1. **Cyber:** Supply chain poison (CI/CD) + C2 deployment
2. **Social Engineering:** Insider threat + credential theft
3. **Physical:** Device drop (BadUSB) + physical access simulation
4. **Kinetic Impact:** Power grid simulation, telecom disruption (simulated)
5. **Public Comms:** Crisis communication test — disclosure timeline, public trust

---

## 3. Detection Gap Analysis (Purple Team Output)

### L4+ Detection Engineering Requirement

Setiap TTP yang dieksekusi red team harus menghasilkan:
- **Detection Rule** (Sigma / KQL / Splunk SPL / Elastic Query)
- **Log Source Mapping** (Event ID, Sysmon, Zeek, CloudTrail, EDR telemetry)
- **Testing** (Historical data replay + live simulation via Atomic Red Team)
- **Tuning** (Baseline untuk mengurangi FP, adjust threshold)
- **Deployment** (SIEM/EDR/WAF/NDR)
- **Monitoring** (Alert performance + periodic review)
- **Feedback** (Post-mortem → adjust detection gaps)

**Contoh Sigma Rule L4 (Suspicious PowerShell Download Cradle):**
```yaml
title: Suspicious PowerShell Download Cradle
id: 7c8d9e0f-1a2b-3c4d-5e6f-7a8b9c0d1e2f
status: experimental
description: Mendeteksi pola download PowerShell dari URL — sering digunakan oleh post-exploitation tools (Cobalt Strike, Havoc, custom)
logsource:
  product: windows
  category: ps_script
  definition: 'Requires PowerShell Script Block Logging (EnableScriptBlockLogging)'
detection:
  selection_download:
    ScriptBlockText|contains:
      - 'System.Net.WebClient'
      - 'Invoke-WebRequest'
      - 'Invoke-RestMethod'
      - 'Start-BitsTransfer'
  selection_bypass:
    ScriptBlockText|contains:
      - 'Bypass'
      - '-ExecutionPolicy'
      - 'EncodedCommand'
  condition: selection_download and selection_bypass
level: high
falsepositives:
  - 'Admin menggunakan PowerShell untuk legitimate download (rare)'
  - 'Software update scripts (rare, needs baseline tuning)'
```

---

## 4. References & Tooling Deep Links

- MITRE ATT&CK Enterprise v15+ — https://attack.mitre.org/
- Atomic Red Team (Red Canary) — https://github.com/redcanaryco/atomic-red-team
- Prelude Operator (TTP Automation) — https://github.com/preludeorg/
- SCYTHE (Adversary Emulation Platform) — https://scythe.io/
- TIBER-EU Framework — European Central Bank
- CBEST Framework — Bank of England
- CVE Intelligence — NVD (https://nvd.nist.gov/), MITRE CVE (https://cve.mitre.org/)
- The DFIR Report — https://thedfirreport.com/
- Red Canary Threat Detection Report — https://redcanary.com/threat-detection-report/
- SpecterOps (AD Security) — https://posts.specterops.io/
- Black Hills Information Security — https://www.blackhillsinfosec.com/
- HAVOC C2 Documentation — https://havocframework.com/
- SLIVER C2 Documentation — https://sliver.sh/
- MYTHIC C2 — https://mythic-c2.net/
- BloodHound / SharpHound — https://bloodhound.readthedocs.io/
---

audited
---
