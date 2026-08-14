---
title: Attack Perspective — Desktop Security (Red Team)
tags:
- attack
- red-team
- desktop
- os
- persistence
- evasion
- hardening-bypass
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Desktop Security — Perspektif Penyerang

> Desktop = titik awal paling umum (phishing → user). Red team: initial access, persistence, defense evasion, credential access — semua di level endpoint.

## 1. Attack Surface Desktop

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **Phishing** | Email/attachment → payload | T1566 | Macro, HTML, LINK | User = weakest link | Email gateway = partial |
| **Browser** | Drive-by, extension abuse | T1189 | Exploit kit, malicious ext | User install | Browser sandbox = partial |
| **USB** | Auto-run, BadUSB | T1091 | Rubber Ducky, USB drop | Physical | USB policy = partial |
| **Persistence** | Registry, task, WMI, COM | T1543/T1546 | SharpStay, custom | WMI = legit | WMI audit = rare |
| **Credential** | LSASS, browser store, DPAPI | T1003 | Mimikatz, SharpDPAPI | Custom build | PPL = partial |
| **Defense Evasion** | AMSI patch, ETW kill, LOLBin | T1562 | Custom, certutil | Direct syscall | EDR hook = partial |
| **Lateral** | SMB, RDP, WinRM | T1021 | PsExec, evil-winrm | Legit protocol | Connection audit = rare |

## 2. Initial Access Chain

```
Phishing:
  ├── Email → macro/HTML (DONUT → shellcode)
  ├── Email → LINK (Evilginx → credential + session)
  ├── Email → attachment (malicious doc)
  └→ User opens → payload → beacon
    ↓
Drive-by:
  ├── Compromised site → exploit kit (browser)
  ├── Malicious ad → redirect → exploit
  └→ Sandbox escape → payload
    ↓
USB:
  ├── Rubber Ducky → keystroke inject → payload
  ├── BadUSB → HID attack → command
  └→ Drop USB → user curiosity → execute
    ↓
Result: User context → beacon → C2 → escalation
```

## 3. Persistence Methods

| Method | MITRE ID | Detection |
|--------|----------|-----------|
| Registry Run key | T1547.001 | Autoruns |
| Scheduled Task | T1053.005 | Task Scheduler audit |
| WMI Event Subscription | T1546.003 | WMI audit (rare) |
| COM Hijack | T1546.015 | Registry audit |
| DLL Search Order | T1574.001 | ProcMon |
| Service | T1543.003 | Service audit |
| Startup Folder | T1547.001 | Folder audit |
| Image File Options | T1546.012 | Registry audit |

## 4. Evasion Techniques

| Defender Control | Bypass | Tool |
|------------------|--------|------|
| AMSI | Patch AmsiScanBuffer | Custom |
| ETW | Patch EtwEventWrite | Custom |
| EDR hook | Direct syscall | SysWhispers3 |
| AppLocker | LOLBin, bypass technique | certutil, mshta |
| Defender | Custom packer, string encrypt | Custom |
| SmartScreen | Signed binary, mark-of-web bypass | Custom |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Evilginx2** | AiTM phishing |
| **DONUT** | In-memory loader |
| **Mimikatz** | Credential access |
| **SharpStay** | Persistence |
| **SysWhispers3** | Direct syscall |
| **Cobalt Strike / Sliver** | C2 |

## 6. Referensi
- LOLBAS — https://lolbas-project.github.io/
- MITRE T1543 — https://attack.mitre.org/techniques/T1543/
- Persistence Research — https://www.ired.team/offensive-security/persistence
- EDR Evasion — https://www.mdsec.co.uk/research/