---
title: Attack Perspective — Abstraction Layers (Red Team)
tags:
- attack
- red-team
- abstraction-layers
- ring
- model
- kernel
- hardware
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Abstraction Layers — Perspektif Penyerang

> Setiap abstraction layer (Ring 3 → Ring 0 → Ring -1 → Ring -2 → Ring -3) punya boundary yang bisa di-bypass. Red team eksploitasi: cross-ring escape, layer boundary violation, hypervisor/UEFI implant.

## 1. Attack Surface per Ring

| Ring | Layer | Privilege | Attack Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|------|-------|-----------|---------------|----------|------------|---------|----------------|
| **Ring 3** | Userland | User | Process inject, shellcode, ROP | T1055 | pwntools, DONUT | In-memory → no disk | EDR periodic scan |
| **Ring 0** | Kernel | System | Kernel exploit, rootkit, driver load | T1068 | CVE-2024-1086, BYOVD | Kernel = EDR callback bypass | PatchGuard partial |
| **Ring -1** | Hypervisor | VM Control | VM escape, side-channel (co-location) | T1611 | CVE-2024-21626 (runc), Spectre | Co-location = cache side-channel | Hypervisor audit = rare |
| **Ring -2** | UEFI/BIOS | Firmware | Bootkit, Secure Boot bypass, UEFI implant | T1542 | BlackLotus, CVE-2022-0001 | Pre-OS = survive reinstall | Firmware audit = rare |
| **Ring -3** | Hardware/CPU/ME | Silicon | Intel ME exploit, DMA, JTAG, side-channel | T1542 | Intel ME vuln, ChipWhisperer | Hardware-level = no EDR | Hardware audit = very rare |
| **Ring 4** | VM/App (sandbox) | Restricted | Sandbox escape, JVM exploit, sandbox bypass | T1611 | V8 sandbox escape, JVM RCE | Sandbox = partial isolation | Sandbox audit = moderate |

## 2. Cross-Ring Escape Chain

```
Ring 3 (Userland RCE):
 ├── Phishing → payload → user shell (Ring 3)
 ├── Web exploit → browser RCE → shellcode (Ring 3)
 └→ Process inject → in-memory loader → C2 beacon (Ring 3)
 ↓
Ring 3 → Ring 0 (Privilege Escalation):
 ├── Kernel exploit: CVE-2024-1086 (nf_tables UAF) → root
 ├── SUID binary abuse → GTFOBins → root
 ├── BYOVD (Bring Your Own Vulnerable Driver) → kernel write → root
 └→ eBPF rootkit (CVE-2021-3490) → hide process → stealth root
 ↓
Ring 0 → Ring -1 (VM Escape):
 ├── CVE-2024-21626 (runc) → container → host root
 ├── Hypervisor bug (VMware, KVM, Xen) → guest → host
 └→ Side-channel (Spectre/Meltdown) → co-VM memory read
 ↓
Ring -1 → Ring -2 (Firmware Persistence):
 ├── UEFI implant (BlackLotus) → survive disk wipe + reinstall
 ├── SPI flash write → bootkit → persistent
 └→ Secure Boot bypass (CVE-2022-0001) → load unsigned bootloader
 ↓
Ring -2 → Ring -3 (Hardware Implant):
 ├── Intel ME vulnerability → ring -3 code execution
 ├── DMA (Thunderbolt/PCIe) → memory read → key extraction
 └→ Hardware implant (ANT catalog) → persistent → no software detect
```

## 3. Persistence per Ring

| Ring | Persistence Metode | Survive Reinstall? | EDR Detect? |
|------|-------------------|-------------------|-------------|
| Ring 3 | Registry, scheduled task, WMI sub | Tidak | Ya (behavioral) |
| Ring 0 | Kernel module, rootkit, driver | Tidak | Ya (kernel callback) — partial |
| Ring -1 | Hypervisor backdoor, VM fork | Tidak (VM) | Tidak (hypervisor audit = rare) |
| Ring -2 | UEFI implant, bootkit | **Ya** (survive disk wipe) | **Tidak** (EDR = blind to firmware) |
| Ring -3 | Intel ME, hardware implant, DMA | **Ya** (survive firmware flash) | **Tidak** (hardware = no EDR) |

## 4. Referensi
- BlackLotus UEFI Bootkit — https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/
- Intel ME Vulnerability — https://www.ptsecurity.com/ww-en/about/news/ip-2018-exploiting-intel-management-engine/
- CVE-2024-21626 (runc) — https://nvd.nist.gov/vuln/detail/CVE-2024-21626
- Ring Model (Wikipedia) — https://en.wikipedia.org/wiki/Protection_ring
- Spectre/Meltdown — https://spectreattack.com/