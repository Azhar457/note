---
title: Attack Perspective — Recursive Ring Deepdive (Red Team)
tags: [attack,red-team,recursive-ring,kernel,hypervisor,uefi,hardware-persistence]
source: hierarchy-recursive-ring-deepdive.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Recursive Ring Deepdive — Perspektif Penyerang (Persistence per Layer)

> Recursive ring = ekspansi model Ring (Ring 3 → Ring 0 → Ring -1 → Ring -2 → Ring -3). Setiap ring lebih dalam = persistence lebih kuat, detection lebih sulit. Red team target: red team najav lebih dalam untuk survive rebuild + reinstall.

## 1. Persistence Strength per Ring

| Ring | Persistence Method | Survive Disk Wipe? | Survive Firmware Flash? | EDR Detect? | Red Team Priority |
|------|-------------------|--------------------|-----------------------|-------------|--------------------|
| **Ring 3** | Registry, scheduled task, WMI, COM | Tidak | Tidak | Ya (behavioral) | Low (trivial detect) |
| **Ring 0** | Kernel module, rootkit, driver | Tidak | Tidak | Ya (kernel callback — partial) | Medium (BYOVD bypass) |
| **Ring -1** | Hypervisor backdoor (BluePill) | Tidak (VM) | Tidak | Tidak (hypervisor audit = rare) | High (stealth) |
| **Ring -2** | UEFI/BIOS implant, bootkit | **Ya** | Tergantung (SPI flash) | **Tidak** (EDR = blind) | **Critical** (survive reinstall) |
| **Ring -3** | Intel ME/AMD PSP, hardware implant | **Ya** | **Ya** (unless physical flash) | **Tidak** (EDR = blind) | **Critical** (survive firmware flash) |
| **Ring -4** | Silicon-level (custom IC, FPGA) | **Ya** | **Ya** | **Tidak** | Black swan (nation-state) |

## 2. Deep Persistence Chain (Ring 3 → Ring -2)

```
Ring 3 (Initial RCE):
 ├── Phishing → payload → user shell (Ring 3)
 └→ Process inject → C2 beacon → establish foothold
 ↓
Ring 0 (Privilege Escalation):
 ├── CVE-2024-1086 (nf_tables) → kernel root
 ├── BYOVD → signed driver load → kernel write
 └→ eBPF rootkit (CVE-2021-3490) → hide process
 ↓
Ring -2 (Firmware Persistence):
 ├── Method 1: UEFI implant (BlackLotus pattern)
 │ ├── Exploit CVE-2022-0001 (Boot Guard bypass)
 │ ├── Write SPI flash → UEFI module → bootkit
 │ └→ Survive disk wipe + reinstall → persistent C2
 ├── Method 2: BIOS rootkit
 │ ├── Flash BIOS → malicious module → boot-time C2
 │ └→ Survive OS reinstall → firmware-level persistence
 └→ Method 3: Bootkit (boot sector)
 ├── Overwrite bootloader → load malicious driver before OS
 └→ Survive OS reinstall (but not disk wipe)
 ↓
Persistence Verification:
 ├── Wipe disk → reinstall OS → UEFI implant → C2 beacon → verify
 └→ Proof: device survive reinstall → persistent access
```

## 3. Intel ME / AMD PSP (Ring -3)

```
Target: Intel Management Engine (ME) / AMD Platform Security Processor (PSP)
 ↓
Attack Surface:
 ├── Intel ME = separate microcontroller (MINIX) → always on → ring -3
 ├── ME has network access (AMT) → out-of-band management
 └→ ME vulnerability → ring -3 code execution → full control
 ↓
CVE ME:
 ├── CVE-2017-5705 (Intel ME) → buffer overflow → ring -3 RCE
 ├── CVE-2019-11091 (Intel ME) → privilege escalation
 └→ NSFog (2017) → ME disable → but if enabled → exploit
 ↓
Attack:
 ├── Network: AMT exposed → ME → ring -3 → host control
 ├── Firmware: SPI flash → ME firmware → backdoor
 └→ Persistence: ME = always on → survive OS power off → persistent
 ↓
Detection:
 ├── EDR = blind (ring -3 = below OS)
 ├── ME audit = rare (Intel MT audit tool)
 └→ Mitigation: disable ME (NSA?) → but many feature depend on ME
```

## 4. CVE Persistence

| CVE | Ring | Target | Impact | Persistence |
|-----|------|--------|--------|-------------|
| CVE-2022-0001 | Ring -2 | Intel Boot Guard | Secure Boot bypass | Survive reinstall |
| CVE-2017-5705 | Ring -3 | Intel ME | ME RCE | Survive OS power down |
| CVE-2024-38041 (BlackLotus) | Ring -2 | Windows UEFI | UEFI bootkit | Survive reinstall |
| CVE-2024-21626 | Ring -1 | runc (container) | Container escape | VM persistence |

## 5. Referensi
- BlackLotus UEFI Bootkit — https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/
- Intel ME Vulnerability — https://www.ptsecurity.com/ww-en/about/news/ip-2018-exploiting-intel-management-engine/
- BluePill Hypervisor Rootkit — https://en.wikipedia.org/wiki/BluePill_(software)
- NSA "Intel ME Disable" — https://www.nsa.gov/Portals/70/...
- AMS Logic Flaw (ring -3) — https://www.blackhat.com/docs/us-17/thursday/...