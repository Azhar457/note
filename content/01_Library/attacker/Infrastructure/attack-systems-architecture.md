---
title: Attack Perspective — Systems Architecture (Red Team)
tags:
- attack
- red-team
- systems
- architecture
- hardware
- kernel
- cpu
- memory
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Systems Architecture — Perspektif Penyerang

> Architecture = interaksi hardware ↔ kernel ↔ software. Red team eksploitasi: CPU side-channel (cache, speculative), kernel bug (syscall, driver), memory model (heap, DMA), hardware boundary (firmware, ME).

## 1. Attack Surface per Komponen

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **CPU (Cache)** | Side-channel (Flush+Reload, Prime+Probe) | T1542 | Spectre/Meltdown PoC | Hardware = no syscall | Cache partitioning = partial |
| **CPU (Speculative)** | Speculation bypass (Spectre v1/v2) | T1542 | CVE-2018-3693, CVE-2017-5754 | Speculate → leak → measure | Retpoline = partial fix |
| **Kernel** | Syscall exploit, driver bug | T1068 | CVE-2024-1086 (nf_tables) | Kernel RCE → root | Kernel patch = lag |
| **Virtual Memory** | ASLR bypass, heap grooming | T1055.012 | Info leak → ROP chain | Leak → chain → exec | ASLR = partial fix |
| **DMA** | PCIe DMA → memory read/write | T1552 | PCILeech, Thunderbolt attack | Hardware = bypass CPU | DMA = no EDR |
| **Firmware** | UEFI implant, ME exploit | T1542 | BlackLotus, CVE-2017-5705 | Pre-OS = survive | Firmware audit = rare |
| **I/O** | MMIO side-channel, interrupt flood | T1490 | Custom timing attack | Hardware = no software signal | I/O audit = none |
| **Microcode** | CPU microcode exploit/update | T1542 | Microcode injection | Hardware = trusted | Microcode verify = rare |

## 2. Memory Model Attack

```
Kernel Heap:
  ├── UAF (CVE-2024-1086) → arbitrary write
  ├── Heap overflow → object corruption → privilege
  └→ nf_tables → root
    ↓
Userland Heap:
  ├── Tcache poison → arbitrary write
  ├── Fastbin dup → overlapping chunk
  └→ __free_hook → one_gadget → RCE
    ↓
Stack:
  ├── Stack overflow → RIP control
  ├── Canary leak → bypass
  └→ ROP → execve
    ↓
Cross-Boundary:
  ├── Kernel → userland (ret2usr, SMEP bypass)
  ├── VM → host (hypervisor bug)
  ├── Container → host (runc CVE-2024-21626)
  └→ DMA → physical memory (PCILeech)
```

## 3. CPU Side-Channel Exploit

```
Spectre v1 (bounds check bypass):
  ├── Train branch predictor → mispredict
  ├── Speculative read → out-of-bounds → cache
  ├── Measure cache → recover data
  └→ Kernel data leak (cross-process)
    ↓
Meltdown (rogue data cache load):
  ├── Userland → speculative kernel read
  ├── Cache side-channel → recover
  └→ Kernel memory dump (KPTI = partial fix)
    ↓
Rowhammer (DRAM):
  ├── Row activation → bit flip adjacent row
  ├── Flip page table → privilege escalation
  └→ Non-ECC RAM = vulnerable
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **pwntools** | Exploit dev (ROP, heap) |
| **Ghidra/IDA** | Kernel/binary RE |
| **PCILeech** | DMA memory access |
| **ChipWhisperer** | Hardware side-channel |
| **BPF/bcc** | Kernel tracing (attack target) |
| **QEMU** | Kernel debug (attack dev) |

## 5. Referensi
- Spectre/Meltdown — https://spectreattack.com/
- CVE-2024-1086 — https://nvd.nist.gov/vuln/detail/CVE-2024-1086
- Rowhammer — https://rowhammer.tech/
- PCILeech — https://github.com/ufrisk/pcileech
- Systems Architecture (CS:APP) — https://csapp.cs.cmu.edu/

## Konkret — Hardware/Kernel Exploit (Testable)

### CPU Microcode (Intel ME)

```bash
# 1. Intel Management Engine (ME) co-processor
#    Ring -3 → dapat kontrol saat BIOS boot
# 2. ME firmware exploit (CVE-2017-12188)
#    HAP (High Assurance Platform) → disable ME
# 3. Intel-SA-00086 detection:
 intel-metool
# Output: vulnerable / patched
# 4. mei-amt-check:
 python3 amt_check.py
```

### SMM (System Management Mode)

```bash
# SMM ring -2 → semua stop (kernel punya lebih rendah prioritas)
# 1. lokasi: SMRAM (System Management RAM)
#    Kernel tidak bisa baca (TSEG / SMRAM lock)
# 2. Exploit: BIOS bug → write ke SMI handler → god mode
# 3. CHIPSET SMM lock bypass (legacy):
#    < CONFIG_SMM > → some vendor tidak kunci
#    Open /dev/mem → write SMRAM → SMM code inject → root
```

### DMA Attack (Direct Memory Access)

```bash
# 1. Hardware: Thunderbolt / PCIe → DMA directly ke RAM (no CPU)
# 2. Bypass kernel (OS tidak ada peran)
# 3. Attack: dump RAM → extract key / hash / password
# 4. Fix: IOMMU (Intel VT-d / AMD-Vi) → restrict DMA

# Tool: Inception / PCILeech
# Hardware: FPGA PCIe card
./pcileech dump_memory
# Atau:
./pcileech search -pattern "NTLM"
```
---

audited
---
