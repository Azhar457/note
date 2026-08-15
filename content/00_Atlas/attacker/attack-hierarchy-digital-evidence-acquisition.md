---
title: Attack Perspective — Digital Evidence Acquisition (Red Team Anti-Forensics)
tags:
- attack
- red-team
- anti-forensics
- evidence
- acquisition
- chain-of-custody
- DFIR
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Digital Evidence Acquisition — Perspektif Anti-Forensics (Red Team)

> Digital evidence acquisition (defender) = forensic imaging, memory dump, chain of custody, hash verification. Red team anti-forensics = **mastiin tidak ada evidence yang bisa di-acquire atau evidence yang di-acquire corrupted**.

## 1. Anti-Evidence Layer

| Tahap Evidence | Defender Teknik | Red Team Bypass | Tool / Teknik | Evasion |
|----------------|----------------|-----------------|---------------|---------|
| **Disk Image** | dd, ddrescue, FTK Imager, tabletop disk clone | Disk encryption (LUKS, BitLocker, FileVault) → image = encrypted blob | LUKS, BitLocker, VeraCrypt | Image = encrypted → no data tanpa key |
| **Memory Dump** | WinPmem, LiME, Volatility, Magnet RAM Capture | Memory wipe (process exit + memory zero) atau in-memory only (no swap) | Process exit → memory freed, in-memory payload | No RAM artifact |
| **Live Triage** | KAPE, Velociraptor, CyLR → collect artifact | Timestomp (T1070.006) → artifact timestamp = normal | timestomp (Metasploit), PowerShell Set-MAC | Timestamp = legit → timeline broken |
| **Network Log** | pcap, Zeek log, firewall log, proxy log | Log deletion, log rotation poison, ETW bypass | wevtutil cl, journalctl --vacuum, auditctl -e 0 | Log = gap, no timeline |
| **Cloud Log** | CloudTrail, Azure Activity Log, GCP Audit Log | Log tampering via cloud admin (disable logging), log export block | aws cloudtrail delete-trail, az logging config | Cloud audit = gap |
| **Log Integrity** | WORM storage, hash chain, digital signature | Log injection (inject fake entry → noise) atau log truncate | SQLi ke log DB, ELK injection | Fake entries = false leads |
| **Chain of Custody** | Hash verify (MD5/SHA256), timestamp, signature | Hash collision (theoretical SHA-1), evidence tamper (modify raw image) | rare — mostly practical defense | Hash mismatch = evidence inadmissible |

## 2. Anti-Forensic Kill Chain (Post-Operation Cleanup)

```
Operasi selesai / deteksi terdekat
 ↓
Step 1 — Memory: Kill C2 process → memory freed
 ├── Process exit → RAM freed → no dump artifact
 └── No swap/page file use (in-memory only)
 ↓
Step 2 — Disk: Secure delete payload, tools, temp
 ├── sdelete (Windows) — 7-pass overwrite
 ├── shred (Linux) — overwrite + rename + unlink
 └── cipher /w (Windows) — wipe free space
 ↓
Step 3 — Timestamp: Reset timestamp ke normal
 ├── timestomp (Metasploit) — modify MACE
 └── PowerShell Set-MAC — modify file time
 ↓
Step 4 — Log: Clear event log, syslog, audit
 ├── wevtutil cl System/Application/Security (Windows)
 ├── journalctl --vacuum-time=1d (Linux systemd)
 ├── auditctl -e 0 (Linux audit disable)
 └── ETW bypass (_patch EtwEventWrite)
 ↓
Step 5 — Prefetch/MFT: Delete execution evidence
 ├── delete C:\Windows\Prefetch\*.pf
 └── USN journal delete → no file creation history
 ↓
Step 6 — Network: Close C2 connection → no persistent TCP
 ├── Close HTTPS session → no keepalive
 └── Clear ARP cache, flush DNS
 ↓
Step 7 — Final: Full wipe staging directory → 7-pass overwrite
 ↓
Exit: Process exit → no trace
```

## 3. Tool Stack Anti-Evidence

| Tool | Platform | Use |
|------|----------|-----|
| **sdelete** (Sysinternals) | Windows | Secure delete (1-7 pass) |
| **shred** | Linux | Secure delete (overwrite + rename + unlink) |
| **timestomp** (Metasploit) | Windows | Modify MACE timestamp |
| **wevtutil** | Windows | Clear event log |
| **cipher /w** | Windows | Wipe free space (overwrite unused cluster) |
| **auditctl** | Linux | Disable audit logging |
| **ntfsinfo / nfi** | Windows | MFT analysis / USN journal delete |
| **VeraCrypt** | Cross | Full disk encryption — image = encrypted blob |

## 4. Forensic Recovery vs Anti-Forensics Gap

| Forensic Tool | Target | Anti-Forensic Bypass | Result |
|---------------|--------|---------------------|--------|
| **Volatility** | Memory dump → process, cred | In-memory only + process exit → memory freed | No RAM artifact |
| **Plaso (log2timeline)** | Timeline (MFT, log, prefetch) | Timestomp + log clear + prefetch delete | Timeline broken (gap) |
| **Autopsy** | Disk image → file history | Full disk encryption (LUKS/BitLocker) + MFT zero | Image = encrypted blob, no file history |
| **KAPE** | Windows artifact (registry, prefetch, SRUM, lnk) | Delete artifact (registry, prefetch, SRUM, lnk) | KAPE = empty output |
| **Wireshark (pcap)** | Network traffic → C2, exfil | TLS 1.3 encryption + domain fronting + traffic shaping | Pcap = encrypted, no C2 visible |
| **Magnet AXIOM** | Artifact enum (cloud artifact, mobile) | Cloud audit log disable + mobile factory reset | No cloud artifact, no mobile artifact |

## 5. Referensi
- Volatility 3 — https://github.com/volatilityfoundation/volatility3
- Plaso / log2timeline — https://plaso.readthedocs.io/
- The Sleuth Kit — https://www.sleuthkit.org/
- Velociraptor — https://github.com/Velocidex/velociraptor
- sdelete (Sysinternals) — https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete
---

audited
---
