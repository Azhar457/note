---
title: Attack Perspective — Endpoint Detection Playbook (Red Team)
tags: [attack,red-team,endpoint,edr,sysmon,sigma,detection-bypass]
source: endpoint-detection-playbook.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Endpoint Detection Playbook — Perspektif Penyerang

> Endpoint detection (EDR/AV/Sysmon) = lawan di endpoint. Red team: tahu rule yang dipakai (Sigma/Sysmon) → bypass. Playbook ini dari sisik penyerang: teknik, rule yang nge-trigger, dan bypass-nya.

## 1. Detection Rule vs Bypass

| Rule (Defender) | Trigger | MITRE ID | Bypass | Tool |
|-----------------|---------|----------|--------|------|
| Sysmon Event 1 (process) | New process | T1059 | Direct syscall, PPID spoof | SysWhispers3 |
| Sysmon Event 3 (network) | Connection | T1071 | Domain fronting, in-memory C2 | Redirector |
| Sysmon Event 11 (file create) | Dropped file | T1105 | In-memory download → no disk | DONUT |
| AMSI | Script scan | T1059 | AMSI patch | Custom |
| ETW | Telemetry | T1562 | ETW patch | Custom |
| Sigma rule (cmdline) | Command match | T1059 | Argument obfuscation | Custom |
| Microsoft Defender | Signature/behavior | T1027 | Custom packer | Custom |
| Behavior (beaconing) | Interval pattern | T1071 | Jitter + shaping | Malleable |

## 2. Bypass Chain

```
Payload (in-memory):
  ├── DONUT → shellcode from file (no payload on disk)
  ├── Beacon → reflective load (no exe file)
  └→ No file create → Sysmon 11 blank
    ↓
Execution:
  ├── Direct syscall (NtCreateProcess) → no EDR hook
  ├── PPID spoof (legit parent) → child-parent rule bypass
  └→ Callback → C2 (HTTPS, shaped) → below behavior threshold
    ↓
Post-exploit:
  ├── AMSI patch → PowerShell script → no scan
  ├── ETW patch → no telemetry
  ├── Custom build (mimikatz variant) → no signature
  └→ Timestomp → no timeline
    ↓
Result: All common detection rule → bypassed
```

## 3. Sigma Rule Analysis (Attacker View)

| Sigma Rule | Detection | Bypass |
|-----------|-----------|--------|
| Suspicious Process (rundll32, mshta) | Process name + cmdline | Use alternative LOLBin, custom loader |
| Mimikatz cmdline | "-sekurlsa" | Custom build (no CLI arg) |
| PowerShell encoded | "-enc" | Split, obfuscate, use unmanaged |
| Beaconing (interval) | Connection pattern | Jitter, random session |
| Suspicious DLL load | Loaded module | Reflective load (no disk) |
| Registry persistence | Autostart key | WMI, COM, service |
| Suspicious network | Known C2 IP | Domain fronting, flux |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **SysWhispers3** | Direct syscall |
| **DONUT** | In-memory shellcode |
| **Cobalt Strike Malleable** | Traffic shaping |
| **Custom packer** | AV evasion |
| **SharpUp/SharpHound** | Recon (post-exploit) |

## 5. Referensi
- SigmaHQ — https://github.com/SigmaHQ/sigma
- Sysmon — https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- EDR Evasion — https://www.outflank.nl/blog/2019/06/19/red-team-tactics-combatting-edr-solutions/
- iRed.Team evasion — https://www.ired.team/offensive-security/defense-evasion