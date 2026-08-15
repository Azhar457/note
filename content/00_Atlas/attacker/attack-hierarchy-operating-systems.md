---
title: Attack Perspective — Operating Systems (Red Team)
tags:
- attack
- red-team
- os
- kernel
- linux
- windows
- privilege-escalation
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Operating Systems — Perspektif Penyerang

> OS adalah medan perang utama. Red team harus paham OS internals untuk: privilege escalation, persistence, defense evasion, dan anti-forensics di Windows dan Linux.

## 1. Attack Surface OS per Komponen

| Komponen OS | Vektor Serangan | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|-------------|----------------|----------|------------|---------|----------------|
| **Process** | Process injection, hollowing, BOF | T1055 | DONUT, sRDI, Cobalt Strike BOF | In-memory, no disk artifact | EDR periodic scan, bukan real-time |
| **Virtual Memory** | Memory protection bypass, page permission modification | T1055.012 | VirtualAllocEx, WriteProcessMemory | Change protection → write → restore | Memory scan miss jika restore cepat |
| **Syscall** | Direct syscall, indirect syscall | T1055.012 | SysWhispers3, HellsGate | Bypass NTDLL hook | EDR userland hook = blind |
| **VFS** | File hide, alternate data stream | T1027.009 | NTFS ADS, Linux overlayfs | ADS = hidden in legit file | File scan jarang cek ADS |
| **IPC** | Named pipe, shared memory, COM | T1559 | COM hijack, named pipe impersonation | IPC = legit OS mechanism | IPC monitoring jarang |
| **Kernel Module** | Rootkit, driver load (BYOVD) | T1068 | CVE-2023-4911, vulnerable signed driver | Kernel = full control, EDR callback bypass | PatchGuard, EDR kernel callback — tapi BYOVD = bypass |
| **Hypervisor** | VM escape, nested ring | T1611 | CVE-2024-21626 (runc) | Guest → host = full control | Hypervisor audit jarang |
| **Credentials** | LSASS dump, /etc/shadow, Kerberos | T1003 | Mimikatz, secretsdump.py | Custom build, PPL bypass (CVE-2024-21410) | LSASS protection — tapi PPL bypass = dump |
| **Scheduling** | Timer manipulation, delay execution | T1497 | Sleep obfuscation, timer callback | Delay = below behavioral threshold | EDR timeout = scan selesai sebelum payload |
| **Persistence** | Service, scheduled task, WMI, COM | T1543/T1546/T1053 | SharpStay, custom | WMI = no file, COM = registry only | WMI auditing jarang di-enable |

## 2. Linux Privilege Escalation Chain

```
Initial Access: Web shell / RCE / phishing → user shell (Ring 3)
 ↓
Recon: LinPEAS / LinEnum / linux-smart-enumeration
 ├── SUID binary? → abuse (T1548.001)
 ├── Kernel exploit? → CVE-2023-4911 (Looney Tunables), CVE-2022-0847 (Dirty Pipe)
 ├── Cron job with writable script? → inject (T1053)
 ├── Sudo misconfig? → sudo -l → GTFOBins
 ├── Capabilities? → cap_setuid+ep → /usr/bin/python → root
 └── NFS root squashing? → mount + suid binary
 ↓
Root: Kernel exploit / SUID / sudo / capabilities → root shell (Ring 0)
 ↓
Persistence: Crontab, systemd service, LD_PRELOAD, backdoor SSH key
 ↓
Anti-forensics: shred tools, clear /var/log, timestomp, in-memory only
 ↓
Lateral: SSH key pivot, network scan, exploit other host
```

## 3. Windows Privilege Escalation Chain

```
Initial Access: Phishing / exploit → user shell (Ring 3)
 ↓
Recon: WinPEAS / Seatbelt / PowerUp
 ├── Unquoted service path? → write malicious.exe (T1574.009)
 ├── Service with weak permission? → modify binPath (T1543.003)
 ├── AlwaysInstallElevated? → msi payload (T1547.001)
 ├── Credential in memory? → LSASS dump (T1003.001)
 ├── AD environment? → BloodHound → attack path (T1087)
 └── Kernel exploit? → CVE-2023-4911 (jika WSL), BYOVD
 ↓
SYSTEM: Service abuse / token manipulation / kernel exploit / BYOVD
 ↓
Persistence: WMI Event Sub (T1546.003), COM Hijack (T1546.015), Scheduled Task (T1053.005)
 ↓
Credential: Mimikatz (sekurlsa::logonpasswords), DCSync (T1003.006), DPAPI (SharpDPAPI)
 ↓
Lateral: SMB (PsExec), WMI (wmiexec), WinRM (evil-winrm), RDP (tscon)
```

## 4. CVE OS Prioritas (2024-2026)

| CVE | OS | Impact | Red Team Value |
|-----|----|--------|----------------|
| CVE-2024-1086 | Linux kernel (nf_tables) | Local root via UAF | High — common kernel, reliable |
| CVE-2023-4911 | Linux (glibc) | Local root via buffer overflow | High — all GLIBC < 2.37 |
| CVE-2022-0847 | Linux kernel 5.8-5.16 | Local root via Dirty Pipe | High — stable, old kernel |
| CVE-2021-3156 | Linux (sudo) | Local root via heap overflow | High — legacy sudo |
| CVE-2024-21410 | Windows (Exchange) | NTLM relay → DA | Critical — domain compromise |

## 5. Tool Stack OS Red Team

| Tool | OS | Use |
|------|-----|-----|
| **LinPEAS** | Linux | Privilege escalation enum (automated) |
| **WinPEAS** | Windows | Privilege escalation enum (automated) |
| **BloodHound / SharpHound** | Windows AD | Attack path analysis |
| **Mimikatz (custom)** | Windows | LSASS, DPAPI, Kerberos, ticket forge |
| **Impacket** | Cross | wmiexec, smbexec, secretsdump, ntlmrelayx |
| **SysWhispers3** | Windows | Direct syscall stub generation |
| **CrackMapExec** | Windows | SMB/WMI/WinRM lateral |
| **evil-winrm** | Windows | WinRM remote shell |
| **Seatbelt** | Windows | Security audit + enum (C# tool) |

## 6. Referensi
- GTFOBins — https://gtfobins.github.io/
- LOLBAS — https://lolbas-project.github.io/
- LinPEAS — https://github.com/peass-ng/PEASS-ng/tree/master/linPEAS
- WinPEAS — https://github.com/peass-ng/PEASS-ng/tree/master/winPEAS
- HackTricks — https://book.hacktricks.xyz/
---

audited
---
