---
title: Attack Perspective — Threat Modeling (Red Team / Adversary View)
tags:
- attack
- red-team
- threat-modeling
- stride
- pasta
- mitre-attack
- dual-use
source: hierarchy-threat-modeling.md
status: complete
created: '2026-08-14'
updated: '2026-08-14'
---

cssclasses:
  - wide-table
  - callout

# 🔴 Attack Perspective: Threat Modeling

> **Standar deepdive:** Setiap Level (0–5) dipetakan ke **attacker goal, concrete TTP, CVE exploitation, evasion strategy, dan defender detection gap**. Perspektif dual-use: defender menggunakan STRIDE/PASTA untuk menemukan ancaman; red team menggunakan framework yang sama untuk menemukan **kontrol defender paling lemah**.

---

## 1. Dual-Use Threat Model: Defender vs Red Team

| Aspek | Defender POV | Red Team POV |
|-------|-------------|-------------|
| **Goal STRIDE** | Identifikasi ancaman → mitigasi | Identifikasi kontrole → bypass |
| **Attack Tree** | Jalur serangan → prioritas mitigasi | Jalur serangan → pilih cost terendah |
| **PASTA (7-Stage)** | Risk register → kontrol alokasi | Risk profile → target weakest asset |
| **Formal Verification (L5)** | Bukti properti aman | Cari properti yang belum terbukti → exploit gap |

---

## 2. Attack Tree — Red Team Perspective (Cost/Skill Indicators)

```
GOAL: Domain Admin / Crown Jewel Data Exfiltration
│
├── [COST: LOW] Initial Access via Phishing (T1566) → Success Rate: 15-30%
│   ├── Sub-node: Spearphishing Link (T1566.002) — CVE: tidak perlu (user click)
│   │   └── Bypass: WAF bypass URL encoding, domain reputation spoof
│   └── Sub-node: Malicious Attachment (T1566.001) — CVE: Office macro (CVE-2017-0199, CVE-2021-40444)
│       └── Bypass: Protected View bypass (CVE-2023-36884)
│
├── [COST: MEDIUM] Exploit Public App (T1190) → Success Rate: 20-40% (tergantung CVE)
│   ├── Web App RCE (CVE-2023-38646 Metabase, CVE-2023-22515 Confluence) → Pre-auth
│   └── VPN/Gateway RCE (CVE-2024-3400 PAN-OS, CVE-2023-20273 Cisco) → High impact
│
├── [COST: LOW-MEDIUM] Valid Accounts / Credential Theft (T1078) → Success Rate: 60-80%
│   ├── Phishing Credentials (T1566.002) → No CVE needed
│   ├── Brute Force (T1110) → Slow, noisy, detectable
│   ├── Credential Stuffing → Need breached database (T1589)
│   └── Kerberoasting (T1558.003) → RC4_HMAC, offline crack → High success jika weak pass
│
├── [COST: MEDIUM-HIGH] Privilege Escalation (T1053, T1548)
│   ├── Local: Kernel Exploit (CVE-2023-4911 Looney Tunables) → Root, common Linux
│   ├── Local: Service Abuse (Unquoted Service Path, DLL Hijack) → System
│   ├── Domain: DCSync (T1003.006) — Need DA/EA rights → Full AD dump
│   ├── Domain: Golden Ticket (T1558.001) — Forge TGT → Invisible for 10 years
│   ├── Domain: AD CS Abuse (CVE-2022-26923 Certifried, ESC1-14) → DA cert
│   └── Cloud: IMDSv1 (T1590.005) → Instance creds → IAM escalation
│
├── [COST: HIGH] Persistence Under Detection (T1546)
│   ├── WMI Event Subscription (T1546.003) — No file, registry only, stealthy
│   ├── COM Hijacking (T1546.015) — InprocServer32 redirect → Explorer load
│   ├── Registry Run Key (T1547.001) — Obvious, easy to detect
│   └── Boot/Logon Autostart (T1547.004) — Scheduled Task / Service
│
├── [COST: HIGH] Lateral Movement (T1021) — Multi-vector
│   ├── SMB (PsExec, smbexec) — T1021.002 — Loud, EDR detects
│   ├── WMI (wmiexec, Invoke-WMIMethod) — T1021.003 — Less loud
│   ├── WinRM (evil-winrm) — T1021.006 — Uses legit port 5985
│   ├── RDP (tscon, session hijack) — T1021.001 — No new process creation
│   ├── SSH (Linux) — T1021.004 — Tunnel, agent forwarding
│   ├── DCOM (SharpDCOM) — T1021.003 — MMC20.Application, ShellWindows
│   └── NTLM Relay (T1557.001) — MitM + relay → No creds needed if relay works
│
└── [COST: MEDIUM] Collection & Exfiltration (T1041, T1537)
    ├── Internal Staging — Compress + encrypt (AES-256-GCM) — Low detection
    ├── Exfil over HTTPS C2 — Chunked, jitter, domain fronting — Blend with legit
    ├── Exfil over DNS (dnscat2) — High entropy, slow, hard to block
    ├── Exfil over Cloud API (rclone) — Legit service, encrypted
    └── Physical Exfil — USB / Bluetooth — Only if air-gap
```

**Red Team Strategy:**
- **Minimum Cost Path:** Phishing (COST LOW) → Valid Creds (COST LOW) → PrivEsc via known CVE (COST MEDIUM) → Lateral via WMI/WinRM (lower noise) → Exfil via HTTPS C2 (blend with traffic)
- **Avoid High-Detection Nodes:** SMB PsExec (EDR detects easy), Registry Run Key (obvious), Direct LSASS dump (Sysmon 10 detects)
- **Prioritize Hidden Nodes:** WMI Event Sub, COM Hijack, RDP Session Hijack (T1021.001 — tscon tidak membuat new process, EDR tidak detect), NTLM Relay (tidak butuh creds)

---

## 3. STRIDE — Attacker Perspective Per Category

Defender menggunakan STRIDE untuk menemukan ancaman. Red team menggunakan STRIDE untuk menemukan **mitigasi yang paling lemah**.

| STRIDE | Attacker TTP | Defender Control | Red Team Bypass Strategy | CVE Example |
|--------|--------------|-----------------|------------------------|-------------|
| **S**poofing | T1078 (Valid Accounts) — Credential Phishing, T1656 (Impersonation) | MFA, FIDO2, SPN validation | Bypass MFA via Adversary-in-the-Middle (AiTM) — CVE: tidak perlu (phishing proxy) | CVE-2024-27198 — bypass auth jika auth flow lemah |
| **S**poofing | T1550.002 (Pass-the-Hash) — Lateral via SMB | NTLMv2 signing, SMB signing, EPA | NTLM Relay (ntlmrelayx) — MitM + relay ke LDAP/SMB/HTTP — No signing enforcement bypass | CVE-2021-42287 (noPac) — SAM spoof → relay |
| **T**ampering | T1055 (Process Injection) — Shellcode, DLL injection | EDR userland hooks, AMSI | Direct Syscalls (SysWhispers3) — Bypass hooks — Memory-only payload | CVE-2024-21626 — container escape (tamper runc) |
| **T**ampering | T1546.003 (WMI Persistence) — Registry/EventFilter | WMI auditing, ETW | WMI event sub tidak memerlukan file — Hanya registry — ETW bypass (patch EtwEventWrite) | T1055.012 — Direct syscall |
| **R**epudiation | T1562.001 (Impair Defenses) — Log clear, event log disable | Audit logging, SIEM, tamper-resistant logs | Event Log clear (wevtutil) — Auditpol disable — ETW bypass — Log tampering via admin rights | T1562.001 — Clear Windows Event Logs |
| **I**nformation Disclosure | T1003.001 (LSASS dump) — Credentials from memory | PPL (Protected Process Light), EDR, LSA Protection | PPL bypass (CVE-2024-21410) — Direct syscall + memory read — Custom build Mimikatz | CVE-2023-4911 — kernel read → bypass userland |
| **I**nformation Disclosure | T1555.003 (Browser Cookies) — Chrome/Firefox/Edge cookies | Encryption (DPAPI), browser isolation | DPAPI master key extraction (SharpDPAPI) — Decrypt cookies — Need user context | T1552.001 — Key/Token extraction |
| **D**enial of Service | T1486 (Data Encryption) — Ransomware | Backup, offline backup, ransomware protection, behavioral detection | Selective encryption (hanya crown jewel) — Ransomware + exfil (double extortion) — Backup encryption (jika akses) | T1486 — Impact: Data Encrypted for Impact |
| **E**levation of Privilege | T1055.012 (Process Injection) — Code injection | EDR, ASR rules, application control | Module Stomping + Process Hollowing + Indirect Syscalls — Memory-only execution | T1055.012 — Process Injection: Thread Execution Hijacking |
| **E**levation | T1558.003 (Kerberoasting) — Service ticket request | Service account monitoring, RC4 detection, strong password policy | Request RC4_HMAC (lemah) — Offline crack (Hashcat) — Use weak password service account | T1558.003 — Kerberoasting |
| **E**levation | T1558.005 (Shadow Credentials) — msDS-KeyCredentialLink | AD CS auditing, 5136 monitoring, msDS-KeyCredentialLink audit | Write msDS-KeyCredentialLink → PKINIT — No password needed — Certificate-based auth | T1558.005 — Shadow Credentials |
| **E**levation | T1098 (Account Manipulation) — ACL modification | AD auditing, ACL monitoring, privileged access management | WriteDACL — ForceChangePassword — GenericAll — Take ownership of AD object | T1098 — Account Manipulation: Account Access Control |

---

## 4. PASTA 7-Stage — Red Team Adaptation

Defender menggunakan PASTA untuk analisis risiko sistematis. Red team menggunakan PASTA untuk **menemukan asset yang paling rentan dan paling berharga**.

**PASTA Stage — Attacker Mapping:**

| Stage | Defender Action | Red Team Action | Output untuk Red Team |
|-------|----------------|----------------|----------------------|
| 1. **Business Objective** | Identifikasi tujuan bisnis (finansial, operasional) | Identifikasi crown jewel (data/uang/akses/domain) | Target asset prioritization |
| 2. **Technical Scope** | Pemetaan sistem (network, app, data, infra) | Pemetaan attack surface (port, service, API, endpoint) | Attack surface map |
| 3. **App Decomposition** | DFD, komponen, trust boundary | Data flow analysis — mana yang bisa dimanipulasi? | Injection point identification |
| 4. **Threat Analysis** | STRIDE + CVE mapping | CVE + MITRE ATT&CK mapping — mana yang belum di-patch? | Exploitation path |
| 5. **Vuln Analysis** | Pen test, SAST/DAST, CVE scan | Exploit reliability test — mana CVE yang stabil? | Weaponization plan |
| 6. **Attack Simulation** | Red team emulation (L4+) | TTP execution — evasion effectiveness test | Detection gap identification |
| 7. **Risk & Impact** | Risk register + kontrol alokasi | Impact estimation — exfil volume, downtime cost, brand damage | Objective prioritization |

---

## 5. Attack Tree Quantification (Cost/Probability Indicators)

**Contoh Attack Tree — Domain Admin via AD CS (Certifried):**

```
GOAL: Domain Admin (DA) via AD CS Abuse
│
├── [COST: LOW] Certifried Prerequisites
│   ├── ESC1 Template — Any purpose + Enroll (No approval needed) → Success: 80%
│   ├── ESC8 (Relay) — NTLM Relay ke AD CS Web Enrollment → Success: 60% (jika relay berhasil)
│   └── Domain User + Valid Cert Template → Success: 90%
│
├── [COST: MEDIUM] Certificate Request & Forgery
│   ├── Request Certificate (Web Enrollment / RPC) → Success: 95% (jika prereq terpenuhi)
│   ├── Forge PAC + Ticket (Golden/Silver) → Success: 85%
│   └── Injection ke AD / Service → Success: 70%
│
└── [COST: HIGH] Persistence + Evasion
    ├── Certificate Persistence — Tidak terdeteksi (no log event 4769) → Evasion: 90%
    ├── WMI Event Sub + Certificate Auth → Multi-layer persistence → Evasion: 85%
    └── Lateral via RDP/SMB dengan DA Cert → Full domain dominance → Impact: 100%
```

**Red Team Decision:**
- Jika ESC1 tersedia → **Pilih ESC1** (cost terendah, success rate tinggi)
- Jika ESC8 (relay) tersedia tapi tidak ESC1 → **Pilih ESC8** tapi butuh NTLM relay setup
- Jika tidak ada AD CS vulnerability → **Pivot ke Kerberoasting → DCSync** (lebih lama tapi stabil)

---

## 6. Threat Modeling — Zero-Day / Unknown Threat

**Level 5 Formal Verification:**
- ProVerif, Tamarin, Alloy — Formal proof bahwa properti aman berlaku untuk semua state
- **Red Team Use Case:** Cari properti yang belum terbukti (gap dalam proof) → exploit gap tersebut
- **Contoh:** Protokol kripto baru — jika proof tidak mencakup timing attack / side-channel → attacker bisa exploit timing difference
- **Contoh Nyata:** TLS 1.3 — formal verification (ProVerif) membuktikan handshake aman — tapi Spectre/Meltdown (side-channel pada CPU) bypass proof karena bukan bagian dari model formal

**Red Team Strategy L5:**
- Target sistem dengan formal proof → Cari komponen **di luar scope proof** (CPU, memory, hardware, physical access)
- Target protokol baru (WireGuard, Signal Protocol baru) → Cari gap dalam proof sebelum proof lengkap
- Supply chain: Compromise library/komponen yang digunakan oleh sistem yang terbukti aman → Bypass proof via dependency

---

## 7. References

- STRIDE — https://docs.microsoft.com/en-us/previous-versions/msp-n-p/ff648644(v=pandp.10)
- PASTA — https://verspritech.com/pasta/
- MITRE ATT&CK — https://attack.mitre.org/
- OWASP Threat Modeling — https://owasp.org/www-community/Threat_Modeling
- OWASP Threat Dragon — https://owasp.org/www-project-threat-dragon/
- Attack Tree Methodology — Bruce Schneier, "Attack Trees" (Dr. Dobb's Journal, 1999)
- ProVerif — https://prosecco.gforge.inria.fr/personal/bblanche/proverif/
- Tamarin Prover — https://tamarin-prover.com/
- Alloy Analyzer — https://alloytools.org/
- CVE Intelligence — NVD, MITRE CVE
- Red Team / Adversary Emulation — MITRE CALDERA, Atomic Red Team, Prelude Operator
- Threat Intel — Mandiant M-Trends, CrowdStrike Global Threat Report, Recorded Future
