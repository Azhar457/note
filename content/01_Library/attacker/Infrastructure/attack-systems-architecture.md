---
title: Attack Perspective — Systems Architecture (Red Team)
tags: [attack,red-team,systems,architecture,hardware,kernel,cpu,memory]
source: systems-design-interview-alex-xu.md + csapp-bryant-ohallaron.md
status: complete
---
cssclasses:
  - wide-table
  - callout

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