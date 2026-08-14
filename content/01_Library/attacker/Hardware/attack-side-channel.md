---
title: Attack Perspective — Side Channel (Red Team Deepdive)
tags: [attack,red-team,side-channel,spectre,meltdown,rowhammer,timing,tempest]
source: side-channel-attacks.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Side Channel — Perspektif Penyerang (Deepdive)

> Side channel = bocor melalui efek sekunder (timing, power, EM, cache, sound). Tidak butuh bug di logic — exploit physics. Red team: cache timing (Spectre), DRAM bit-flip (Rowhammer), power analysis (ChipWhisperer), EM (Tempest), acoustic.

## 1. Side Channel Matrix

| Channel | Physical Effect | Attack | Tool | Evasion | Detection |
|---------|----------------|--------|------|---------|-----------|
| **Cache** | Timing difference load | Flush+Reload, Prime+Probe | Spectre PoC | No syscall anomaly | Cache partition = partial |
| **DRAM** | Bit-flip (row hammer) | Rowhammer → page table flip | rampage-test | No software signature | ECC RAM = mitigation |
| **Power** | Power consumption pattern | SPA/DPA → key extraction | ChipWhisperer | No signal | Shield = hardware |
| **EM** | Electromagnetic emission | Tempest → screen/key restore | HIRT (TempestSDR) | No signal | Shield room |
| **Timing** | Response time variation | Oracle timing → key/password | Remote timing attack | Network jitter | Statistical detect |
| **Acoustic** | Sound → key press pattern | Keyboard acoustic | Acoustic decrypt | No signal | Noise environment |
| **Thermal** | Heat residue (keyboard) | Thermal imaging → key order | Thermal camera | No signal | Physical |
| **Spectre (speculative)** | CPU speculation + cache | Cross-process kernel leak | CVE-2017-5754 | No syscall | Microcode fix |

## 2. Spectre Attack Chain

```
Prereq: Speculative execution + cache side channel
    ↓
Train:
  ├── Branch predictor → mispredict → speculative read
  ├── Speculative load → out-of-bounds → cache fill
  └→ Data in cache (not committed)
    ↓
Measure:
  ├── Time→cache access: cache hit = data bit
  ├── Repeat per bit → reconstruct secret
  └→ Cross-process kernel leak
    ↓
Victim:
  ├── Kernel memory (Meltdown)
  ├── Other process (Spectre)
  └→ Browser (Spectre v1)
    ↓
Mitigation: Retpoline, KPTI, microcode → partial
```

## 3. Rowhammer Chain

```
Prereq: Non-ECC DDR4/DDR5 (most consumer RAM)
    ↓
Target:
  ├── Page table → bit-flip → write access
  └→ Physical memory → privileged data
    ↓
Technique:
  ├── Row hammer (row activation stress)
  ├── Rowhammer attack → adjacent row bit flip
  ├── Flip page table entry → user write to kernel page
  └→ Privilege escalation (root)
    ↓
Modern: ECC RAM = mitigated (detection + correction)
  ├── Vendor Rowhammer mitigation (RFM, refresh)
  └→ Still: research terus (Half-Double, TRRespass)
```

## 4. Differential Power Analysis

```
Prereq: Physical device (smartcard, secure element, IoT)
    ↓
Setup: ChipWhisperer + target → power probe
    ↓
Capture:
  ├── Device encrypt known input
  ├── Power trace per operation (SPA)
  └→ Many traces → statistical (DPA)
    ↓
Analyze:
  ├── Correlation (DPA) → key guess
  ├── Template attack → model → identify
  └→ Key extraction → full crypto bypass
    ↓
Mitigation: Masking, constant-time, secure element
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **ChipWhisperer** | Power/EM side channel |
| **TempestSDR / HIRT** | EM capture (screen) |
| **rampage-test** | Rowhammer test |
| **Flush+Reload PoC** | Cache side channel |
| **Durandal** | DRAM attack framework |

## 6. Referensi
- Spectre/Meltdown — https://spectreattack.com/
- Rowhammer — https://rowhammer.tech/
- ChipWhisperer — https://chipwhisperer.readthedocs.io/
- Tempest — https://en.wikipedia.org/wiki/Tempest_(codename)
- Side Channel (power) — https://www.sidechannel-sec.com/