---
title: Attack Perspective — Memory & Storage (Red Team)
tags: [attack,red-team,memory,storage,dump,anti-forensics,bitlocker,luks]
source: hierarchy-memory-storage.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Memory & Storage — Perspektif Penyerang

> Memory = credential goldmine (plaintext password, session token, API key). Storage = data target (exfil, ransomware). Red team: memory dump, disk encryption bypass, cold boot, swap exploitation.

## 1. Attack Surface Memory & Storage

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **RAM (process memory)** | LSASS dump, /proc/pid/mem, process memory scan | T1003.001 | Mimikatz, procdump, pypykatz | Custom build, PPL bypass | LSASS protection — tapi PPL bypass = dump |
| **RAM (full dump)** | Cold boot, DMA (Thunderbolt/PCIe), memory acquisition | T1003 | Win pmem, LiME, DMA attack | Physical access = no EDR | DMA = hardware, EDR blind |
| **Swap/Page File** | Swap file persistence, pagefile credential extraction | T1003.001 | Volatility, strings pagefile.sys | In-memory only (no swap) → no artifact | Swap audit jarang |
| **HDD/SSD** | Disk encryption bypass (BitLocker/luks), firmware implant | T1602 | BitLocker recovery key brute, UEFI implant | Firmware = survive disk wipe | Disk encryption audit jarang |
| **Hibernation file** | hiberfil.sys → memory dump → credential | T1003.001 | Volatility (hibernation) | Delete hiberfil.sys → no artifact | Hibernation audit jarang |
| **Volume Shadow Copy** | VSS snapshot → roll back → extract old data | T1490 | vssadmin, vshadowinfo | VSS = legit Windows feature | VSS abuse = legit operation |
| **TPM** | TPM extraction, attestation bypass, seal key recovery | T1552 | tpm2-tools, firmware glitch | TPM = hardware — glitch = transient | TPM audit = hardware only |
| **NVMe/SATA** | DMA read via PCIe, firmware modification | T1602 | PCIe DMA device, hdparm | DMA = hardware, no EDR | NVMe firmware audit jarang |

## 2. Credential Extraction Chain (Memory)

```
Initial Access: Phishing / exploit → SYSTEM/admin shell
 ↓
LSASS Dump (Windows):
 ├── Method 1: Mimikatz sekurlsa::logonpasswords (custom build — bypass PPL)
 ├── Method 2: procdump -ma lsass.exe → MiniDump → pypykatz
 ├── Method 3: comsvcs.dll MiniDump (LOLBin — no Mimikatz binary)
 ├── Method 4: direct syscall (NanoDump) → bypass EDR hook
 └── Method 5: Task Manager → Create dump file (GUI)
 ↓
Alternative Memory Sources:
 ├── pagefile.sys → strings → password/credential
 ├── hiberfil.sys → Volatility → memory dump → credential
 └── VSS snapshot → access old LSASS dump
 ↓
Parse:
 ├── pypykatz → NT hash, password, Kerberos ticket
 ├── secretsdump.py → NT hash, password, LM hash
 └── Volatility → hashdump, lsadump, mimikatz
 ↓
Post-Credential:
 ├── Pass-the-Hash (NT hash) → lateral movement
 ├── Kerberoasting (TGS) → offline crack
 ├── Golden Ticket (krbtgt hash) → forge TGT → persistence
 └── DCSync (DS-Replication) → replicate → dump all hash
```

## 3. Disk Encryption Bypass

| Encryption | Attack Vector | Tool / Teknik | Prerequisite |
|-----------|-------------|---------------|--------------|
| **BitLocker** | Recovery key brute, TPM extract, memory dump (FVEK) | bitlocker-brute, Volatility (bitlocker) | Physical access |
| **BitLocker (TPM-only)** | DMA attack (Thunderbolt/PCIe) → RAM → FVEK | PCIe DMA, Thunderbolt attack | Physical + DMA |
| **LUKS** | Header dump → offline brute, keyfile theft | luksHeaderDump, hashcat -m 14600 | Header access |
| **FileVault** | Recovery key brute, iCloud unlock abuse | halibut, hashcat | Physical + recovery |
| **VeraCrypt** | Header tamper → offline brute, keyfile theft | veracrypt2john, hashcat | Header access |
| **Cold Boot Attack** | RAM freezing → data retention → dump → key | RAM freeze (liquid N2) → DDR2/DDR3 | Physical + old RAM |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Mimikatz (custom)** | LSASS dump, Kerberos, DPAPI, ticket forge |
| **pypykatz** | Python LSASS parser (offline dump) |
| **procdump** (Sysinternals) | LSASS dump (MiniDump) |
| **NanoDump** | Direct syscall LSASS dump (EDR bypass) |
| **Volatility 3** | Memory forensics (hashdump, lsadump, mimikatz) |
| **secretsdump.py** (Impacket) | Offline hash dump (NTDS.dit, SAM) |
| **hashcat** | Offline hash crack (NT, BitLocker, LUKS, VeraCrypt) |
| **vssadmin / vshadow** | VSS snapshot access |

## 5. Referensi
- pypykatz — https://github.com/skelsec/pypykatz
- NanoDump — https://github.com/HelpSystems/NanoDump
- Volatility 3 — https://github.com/volatilityfoundation/volatility3
- Impacket — https://github.com/SecureAuthCorp/impacket
- hashcat — https://hashcat.net/
- Cold Boot Attack — https://citp.princeton.edu/research/memory/