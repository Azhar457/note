---
title: Attack Perspective — SIEM & Detection Bypass (Red Team)
tags: [attack,red-team,siem,detection,bypass,log-tampering,correlation,splunk]
source: siem-detection-bypass.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# SIEM & Detection Bypass — Perspektif Penyerang

> SIEM = correlation engine atas log. Red team bypass: log tampering (delete/alter), noise injection (alert flood), correlation window gap, unmapped TTP, EVTX disable.

## 1. Attack Surface SIEM

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **Event Log** | wevtutil clear, ETW patch, audit disable | T1070.001 | wevtutil cl, auditpol, ETW patch | Log gap = no evidence | Log forwarding = WORM only (jarang) |
| **Sysmon** | Sysmon disable, config bypass | T1070.001 | sc config Sysmon start= disabled | Sysmon = service → stop | SIEM = blind (no feed) |
| **Correlation** | Below threshold, spread across window | T1070 | Slow attack, multi-host fragment | No single correlation window | Correlation = window-based |
| **Noise Injection** | Alert flood → analyst fatigue | T1562.001 | Mass false positive (scan, proxy) | Noise = legit volume | Analyst = overwhelmed |
| **Unmapped TTP** | Technique tanpa detection rule | T1562.006 | Sub-technique variant, new tool | No rule = no alert | Rule coverage gap |
| **Log Source** | SecLog deletion, WMI clear | T1070.001 | Delete specific entries | Selective delete = targeted | Backup log = rare |
| **Time** | Timestamp manipulation | T1070.006 | timestomp → wrong timeline | Timeline = broken | Timeline integrity = rare |

## 2. Log Tampering Chain

```
Access Log Server / Endpoint:
  ├── SYSTEM → event log access
  ├── SIEM agent → log source
  └→ DB → log store
    ↓
Windows:
  ├── wevtutil cl Security → clear Security log
  ├── wevtutil cl System → clear System log
  ├── wevtutil cl Application → clear App log
  ├── auditpol /clear → disable audit policy
  └→ ETW patch (EtwEventWrite → ret) → no telemetry
    ↓
Linux:
  ├── journalctl --vacuum-time=1d → delete old journal
  ├── rm /var/log/auth.log → delete auth log
  ├── auditctl -e 0 → disable audit
  └→ truncate -s 0 /var/log/syslog → empty
    ↓
Selective:
  ├── Search: event ID 4624 (logon), 4688 (process)
  ├── Delete entry by timestamp → targeted
  └→ timestomp → modify timestamp
    ↓
Result: SIEM correlation = blind (feed = empty)
```

## 3. Noise Injection (Alert Fatigue)

```
Goal: Overwhelm SIEM alert queue → analyst ignore / tune down
    ↓
Method 1 — Mass Scan:
  ├── Port scan → IDS alert flood (thousands/h)
  ├── Slow scan → spread → sustained alert
  └→ Impact: analyst tune threshold → attacker exploit gap
    ↓
Method 2 — False Positive:
  ├── Proxy connect to random domains → DLP alert
  ├── Search for credentials in legit files → false DLP
  └→ Noise = legit volume → tune down
    ↓
Method 3 — Payload Injection (if log access):
  ├── Inject fake event → decoy alert
  ├── Inject fake login failure → brute force decoy
  └→ Analyst chase decoy → attacker operate
    ↓
Result: Detection pipeline = overwhelmed → real attack noise
```

## 4. Detection Rule Bypass (Sigma/Splunk)

| Rule Pattern | Bypass |
|--------------|--------|
| Process name match (powershell.exe) | Rename binary, LOLBin alternative |
| Command line match (mimikatz) | Custom build, argument obfuscation |
| Parent-child match (word → cmd) | PPID spoofing, WMI |
| Network connection (C2 IP) | Domain fronting, redirector chain |
| Hash match | Custom packer, polymorphic |
| Behavioral (beacon interval) | Jitter, traffic shaping |
| Registry match (persistence) | WMI, COM, alternate persistence |
| Event ID match (4688) | Direct syscall → no process event |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **wevtutil** | Event log clear/query |
| **auditpol** | Audit policy modify |
| **timestomp** | Timestamp manipulation |
| **PowerShell** | Log manipulation (MinEventLog) |
| **SysWhispers3** | Direct syscall (no process event) |
| **ETW patcher** | Telemetry disable |

## 6. Referensi
- MITRE T1070 (Indicator Removal) — https://attack.mitre.org/techniques/T1070/
- Evil-WinRM log evasion — https://github.com/Hackplayers/evil-winrm
- Sigma Rules — https://github.com/SigmaHQ/sigma
- Log Tampering Research — https://www.ired.team/offensive-security/defense-evasion