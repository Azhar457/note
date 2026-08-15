---
title: Attack Perspective — Data Recovery (Red Team Anti-Forensics)
tags:
- attack
- red-team
- data-recovery
- anti-forensics
- wipe
- timestomp
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Data Recovery — Perspektif Anti-Forensics (Red Team)

> Data recovery (defender) = ekstrak data dari media rusak. Red team pakai anti-forensics = **mastiin data tidak bisa di-recover** setelah operasi selesai.

## 1. Anti-Forensics Layer

| Layer | Defender Teknik | Red Team Bypass | Tool | Evasion |
|-------|----------------|----------------|------|---------|
| **File deletion** | Recuva, TestDisk, PhotoRec | Secure wipe (sdelete, shred, dd if=/dev/zero) | sdelete (Sysinternals), shred (Linux), dd | Overwrite 3-7 pass → no recovery |
| **Disk format** | Full format → recover dengan TestDisk | Zero-fill seluruh disk (dd if=/dev/zero of=/dev/sda) | dd, DBAN, blkdiscard | Full overwrite = no file table = no recovery |
| **SSD/TRIM** | SSD wear-leveling = data masih ada di block yang tidak ter-TRIM | Force TRIM (fstrim) + ATA secure erase | hdparm, fstrim | TRIM = SSD controller hapus block = hardware-level |
| **File slack space** | Ekstrak data dari slack space (file slack, file system slack) | Overwrite slack space (slacker) atau pake small file fill | slacker (The Sleuth Kit) | Slack space = area antara EOF dan cluster boundary |
| **Timestamp** | Timeline analysis via MACB (Modified, Accessed, Changed, Birth) | Timestomp (T1070.006) — modify MACB to normal time | timestomp (Metasploit), PowerShell Set-MAC | Timestomp = delete forensic timeline |
| **Log** | Event log, syslog, audit log | Clear log (wevtutil), disable audit (auditctl -e 0), ETW bypass | wevtutil, journalctl --vacuum, auditctl | Log clear = no timeline |
| **Memory** | Volatility, RAM dump → process, credential, key | Memory wipe (process exit + memory zero) atau in-memory only (no swap) | winpmem (dump prevention), custom | In-memory = no disk artifact |
| **MFT** | MFT analysis → file history, deleted file | MFT zero (NirSoft MFT flush) atau USN journal delete | ntfsinfo, nfi, USN journal delete | MFT clean = no file history |
| **Prefetch** | Prefetch analysis → execution history | Delete prefetch files (C:\Windows\Prefetch\*.pf) | cmd del, Remove-Item | Prefetch delete = no execution evidence |

## 2. Anti-Forensics Kill Chain (Post-Operation Cleanup)

```
Operasi selesai / deteksi terdekat
 ↓
Memory: Kill C2 process → memory freed → no dump artifact
 ↓
Disk: Delete payload, tools, temp file → sdelete (3-pass overwrite)
 ↓
Timestomp: Reset timestamp file legitimate ke waktu normal
 ↓
Log: Clear event log (wevtutil cl System/Aurity/Application)
 ↓
Prefetch: Delete C:\Windows\Prefetch\*.pf
 ↓
MFT: USN journal delete → no file creation history
 ↓
Network: Close C2 connection → no persistent TCP session
 ↓
Final: sdelete seluruh staging directory → 7-pass overwrite
 ↓
Exit: Process exit → memory freed → no trace
```

## 3. Tool Stack Anti-Forensics

| Tool | Platform | Use |
|------|----------|-----|
| **sdelete** (Sysinternals) | Windows | Secure delete (1-7 pass overwrite) |
| **shred** | Linux | Secure delete (overwrite + rename + unlink) |
| **dd if=/dev/zero** | Linux | Full disk zero-fill |
| **DBAN** | Bootable | Full disk wipe (Darik's Boot and Nuke) |
| **timestomp** (Metasploit) | Windows | Modify MACE timestamp (Modified/Accessed/Changed/Entry) |
| **wevtutil** | Windows | Clear event log |
| **auditctl** | Linux | Disable/enable auditd |
| **ntfsinfo / nfi** | Windows | MFT analysis / delete USN journal |
| **cipher /w** | Windows | Wipe free space (overwrite unused cluster) |

## 4. Forensic Recovery vs Anti-Forensics (Gap Table)

| Forensic Teknik | Target Recover | Anti-Forensics Bypass | Detection |
|-----------------|---------------|----------------------|-----------|
| **TestDisk** | Deleted partition | dd if=/dev/zero = full overwrite = no partition table | Recovery failed (no partition) |
| **PhotoRec** | File cartridge (photo, doc) | sdelete 7-pass = file content overwritten | Recovery failed (content = zero) |
| **Volatility** | Memory dump (process, cred) | In-memory only (no swap, no page file) → process exit = memory freed | No dump artifact |
| **Plaso (log2timeline)** | Timeline (MFT, log, prefetch) | Timestomp + log clear + prefetch delete = no timeline | Timeline broken (gap, inconsistency) |
| **Autopsy** | Disk image → file history | MFT zero + USN journal delete = no file history | File history = empty |
| **KAPE (Kroll Artifact Parser)** | Windows artifact (registry, prefetch, SRUM, lnk) | Delete artifact → KAPE = empty | Artifact missing |

## 5. Referensi
- sdelete (Sysinternals) — https://docs.microsoft.com/en-us/sysinternals/downloads/sdelete
- TestDisk — https://www.cgsecurity.org/wiki/TestDisk
- The Sleuth Kit (Forensic) — https://www.sleuthkit.org/
- Volatility 3 — https://github.com/volatilityfoundation/volatility3
- Plaso (log2timeline) — https://plaso.readthedocs.io/
---

audited
---
