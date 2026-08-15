---
title: Attack Perspective — Side Channel Analysis (Red Team)
tags:
- attack
- red-team
- side-channel
- spectre
- meltdown
- rowhammer
- tempest
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Side Channel — Perspektif Penyerang (Hardware-Level)

> Side-channel attack adalah **hardware-level exploit** — tidak ada syscall, tidak ada file, tidak ada network packet. EDR buta total. Red team pakai untuk: key extraction, kernel memory read, cross-VM leak.

## 1. Attack Surface Side-Channel

| Teknik | Target | Konkret | Mitre/CVE | Evasion | Detection Gap |
|--------|--------|---------|-----------|---------|----------------|
| **Spectre v1** (Bounds Check Bypass) | CPU speculative execution → kernel memory read | Mempodetect, Spectre PoC | CVE-2018-3693 (T1542) | Speculate → cache → measure → leak (no syscall) | Retpoline partial fix; EDR blind |
| **Spectre v2** (Branch Target Injection) | BTB poisoning → cross-process leak | Spectre v2 PoC, ret2usr_spec | CVE-2018-3693 (T1542) | No syscall, pure cache timing | IBRS partial fix; cross-VM = still possible |
| **Meltdown** (Rogue Data Cache Load) | Userland → kernel memory read | MeltDown PoC | CVE-2017-5754 (T1542) | Direct kernel read via speculative execution | KPTI fix; butApple/iOS = no KPTI |
| **Rowhammer** | DRAM bit flip → privilege escalation | Rowhammer.js, Blacksmith, Half-Double | CVE-2020-XXXX (T1542) | Bit flip via row activation — pure memory | ECC mitigate; but non-ECC consumer device = vulnerable |
| **Flush+Reload** | Cache covert channel → secret extraction | Flush+Reload PoC | T1542 (Covert Channel) | No syscall, pure cache timing | Cache partitioning partial; cloud colocation = shared cache |
| **Prime+Probe** | Cache occupancy → key extraction | Prime+Probe PoC | T1542 (Covert Channel) | No syscall, monitor cache occupancy | Cache partitioning; but L3 = shared, hard partition |
| **DPA/SPA** | Power analysis → AES key | ChipWhisperer | T1542 (Hardware) | Physical access + oscilloscope | Hardware audit jarang; consumer device = no protection |
| **TEMPEST** | EM emanation → screen content | RTL-SDR, custom antenna | T1542 (Exfiltration) | Passive EM — no interaction | Faraday cage rare; consumer device = no shielding |
| **Timing** | Keystroke timing → password recovery | Custom timing script | T1542 (Covert) | No syscall, pure timing | Constant-time implementation partial |

## 2. Side-Channel Attack Chain (Cloud Colocation)

```
Cloud Recon: Identify target cloud provider + region
 ↓
Colocation: Deploy VM di same physical host (same availability zone)
 ↓
Cache side-channel: Prime+Probe on L3 cache
 ↓
Extract: Co-resident VM keystroke, crypto key, process activity
 ↓
(Post-Quantum: Harvest-now → decrypt saat quantum aktif)
```

## 3. CVE Side-Channel (Aktif)

| CVE | Target | Impact | Fix | Bypass Fix |
|-----|--------|--------|-----|------------|
| CVE-2017-5754 (Meltdown) | Intel x86, some ARM | Kernel memory read from userland | KPTI | Apple iOS = no KPTI; some ARM = no fix |
| CVE-2018-3693 (Spectre v1) | All modern CPU | Cross-process memory leak | Retpoline + LFENCE | Speculative bypass still possible (training the branch predictor) |
| CVE-2018-3639 (Spectre v4) | Speculative Store Bypass | Speculative execution bypass | Speculative Store Bypass Disable | Performance overhead = sering disabled |
| CVE-2019-XXXX (ZombieLoad) | MDS (Microarchitectural Data Sampling) | Cross-VM data leak | Microcode + kernel patch | Patch imperfect; older CPU = no microcode |
| CVE-2020-0543 (LVI) | Load Value Injection | Revert Spectre fix → inject value | Complex patch | Performance hit = sering disabled |
| CVE-2022-XXXX (Retbleed) | Retpoline bypass | Retpoline itself = gadget | New retpoline (IBT) | Older CPU = no IBT support |

## 4. Tool Stack Side-Channel

| Tool | Use | Hardware Requirement |
|------|-----|---------------------|
| **Flush+Reload** | Cache covert channel — shared memory | Same physical host (cloud colocation) |
| **Prime+Probe** | L3 cache occupancy — no shared memory | Only co-resident (same host) |
| **Rowhammer.js** | Browser-based DRAM bit flip | Any device with DDR3/DDR4 (non-ECC) |
| **ChipWhisperer** | Power analysis + glitch | Physical access, $250-$3000 |
| **RTL-SDR** | RF emanation (TEMPEST) | $25, antenna, outdoor range |
| **Blacksmith** | Rowhammer DDR4 | DDR4 non-ECC, custom pattern |

## 5. Referensi
- Spectre & Meltdown — https://spectreattack.com/
- Flush+Reload — https://github.com/IAIK/flush_flush
- TEMPEST — https://en.wikipedia.org/wiki/TEMPEST)
- Google Project Zero (Side-Channel) — https://googleprojectzero.blogspot.com/

audited
---
