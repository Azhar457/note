---
title: Side-Channel Analysis — Power, Timing, Cache & Fault Injection
tags:
- side-channel
- power-analysis
- timing-attack
- cache-attack
- fault-injection
- hardware-security
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Side-channel attacks mengeksploitasi **implementasi fisik** dari kriptografi, bukan algoritma matematisnya. Catatan ini melengkapi [[hardware-hacking-re]] dengan offensive techniques (power analysis, glitching) dan [[cryptography-biometrics]] dengan attack vector yang mengancam implementasi crypto di dunia nyata.
>
> **Domain:** Cyber Security / Hardware Security
> **Tags:** #side-channel #power-analysis #timing-attack #cache-attack #fault-injection #cpa #dpa

## Daftar Isi

1. [Side-Channel Classification](#1-side-channel-classification)
2. [Power Analysis](#2-power-analysis)
3. [Timing Attack](#3-timing-attack)
4. [Electromagnetic Analysis](#4-electromagnetic-analysis)
5. [Cache Attacks](#5-cache-attacks)
6. [Fault Injection](#6-fault-injection)
7. [Defenses](#7-defenses)
8. [Koneksi ke Vault](#8-koneksi-ke-vault)

## 1. Side-Channel Classification

### 1.1 Taxonomy

```
Side-Channel Attacks
├── Physical
│   ├── Power (SPA, DPA, CPA)
│   ├── EM (Electromagnetic)
│   ├── Acoustic (fan, coil whine, printer)
│   ├── Thermal (temperature difference)
│   └── Photonic (pixel photon emission)
├── Microarchitectural
│   ├── Cache (Prime+Probe, Flush+Reload)
│   ├── Branch predictor (BranchScope)
│   ├── TLB (address translation timing)
│   └── DRAM (Rowhammer → bit flip)
└── Network/Logical
    ├── Timing (network latency)
    ├── Remote timing (SSH padding)
    ├── Error oracle (padding oracle attack)
    └── Compression (CRIME/BREACH)
```

### 1.2 Attack Difficulty & Equipment Cost

| Attack | Equipment Cost | Difficulty | Key Recovery |
|--------|---------------|------------|--------------|
| **Timing (network)** | $0 | Low | Partial/Full |
| **Cache (Flush+Reload)** | $0 | Medium | Full |
| **Power (SPA)** | $200-2000 (oscilloscope) | Low | Partial |
| **Power (DPA/CPA)** | $500-5000 | Medium | Full |
| **EM Analysis** | $1000-5000 (probe + LNA) | Medium | Full |
| **Acoustic** | $100-500 (mic) | High | Partial |
| **Voltage Glitch** | $50-500 | Low | Bypass auth |
| **Clock Glitch** | $50-300 | Low | Instruction skip |
| **EMFI** | $500-5000 | High | Instruction skip |
| **Laser Fault** | $5000-50000 | Very High | Bit flip |

## 2. Power Analysis

### 2.1 SPA — Simple Power Analysis

SPA membaca power trace untuk **melihat operasi yang sedang dijalankan**.

```
Power trace untuk AES:
┌──────────────────────────────────────────┐
│  10 rounds AES-128                        │
│  ┌────┐ ┌────┐ ┌────┐     ┌────┐        │
│  │ R1 │ │ R2 │ │ R3 │ ... │ R10│        │
│  └────┘ └────┘ └────┘     └────┘        │
│     ↑         ↑               ↑          │
│  Power spike during SubBytes (S-box lookup)│
└──────────────────────────────────────────┘
```

**Key insight:** Setiap round AES punya pola power distinct. SPA bisa reveal:
- Number of rounds → AES-128 (10) vs AES-256 (14)
- Branch points (if/else → different power)
- S-box access timing → leak key byte

### 2.2 DPA — Differential Power Analysis

DPA menggunakan **statistical analysis** untuk recover key dari power traces.

```python
import numpy as np
from scipy.stats import pearsonr

def cpa_attack(traces, plaintexts, key_byte_pos):
    """
    CPA attack to recover one AES key byte
    traces: np.array (N_traces × N_samples)
    plaintexts: np.array (N_traces × 16)
    """
    best_key = None
    best_corr = 0
    
    for guessed_key in range(256):
        # 1. Compute hypothetical intermediate value
        # AES S-box output for guessed key
        intermediate = sbox[plaintexts[:, key_byte_pos] ^ guessed_key]
        
        # 2. Hamming weight model
        power_model = np.array([bin(x).count('1') for x in intermediate])
        
        # 3. Pearson correlation at each time sample
        correlations = np.array([
            pearsonr(power_model, traces[:, t])[0]
            for t in range(traces.shape[1])
        ])
        
        # 4. Track max correlation
        max_corr = np.max(np.abs(correlations))
        
        if max_corr > best_corr:
            best_corr = max_corr
            best_key = guessed_key
    
    return best_key, best_corr

# AES S-box
sbox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5,
    0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    # ... (full 256-byte S-box)
]
```

### 2.3 CPA — Correlation Power Analysis

CPA meningkatkan DPA dengan **Pearson correlation coefficient**:

```
For each guessed key k:
  H = HammingWeight(Sbox(plaintext ^ k))     # Power model
  ρ = correlation(H, power_trace)            # Pearson r
  If ρ > threshold → k is likely correct key
```

**Tooling:** [ChipWhisperer](https://www.newae.com/chipwhisperer) — low cost ($200-500) CPA device.

## 3. Timing Attack

### 3.1 Timing Oracle

```c
// VULNERABLE: timing depends on password length + content
int check_password(const char *input, const char *expected) {
    for (int i = 0; i < strlen(expected); i++) {
        if (input[i] != expected[i]) {  // Early exit on mismatch!
            return 0;
        }
    }
    return 1;
}

// Timing leak:
// 1st char wrong:  ~10ns
// 2nd char wrong:  ~20ns
// 10th char wrong: ~100ns
// Attacker: measure timing per position → recover password char by char!
```

### 3.2 Network Timing Attack (SSH)

```python
import time
import socket

def timing_attack(host, port, username, password_prefix):
    """Timing-based password oracle for SSH"""
    for c in "abcdefghijklmnopqrstuvwxyz0123456789":
        test_password = password_prefix + c
        start = time.perf_counter()
        
        sock = socket.socket()
        sock.connect((host, port))
        # Send SSH auth attempt
        sock.send(f"ssh-userauth {username} {test_password}".encode())
        sock.recv(1024)
        sock.close()
        
        elapsed = time.perf_counter() - start
        
        # If timing > threshold → password correct so far!
        if elapsed > avg_time * 1.5:
            return timing_attack(host, port, username, test_password)
    
    return password_prefix
```

### 3.3 Constant-Time vs Variable-Time Operations

| Operation | Constant-Time | Notes |
|-----------|--------------|-------|
| String comparison | `memcmp` (variable) | Use `crypto_memcmp` |
| Memory copy | `memcpy` (variable) | Use `memmove` or constant |
| Branch (if/else) | Variable | Use bitmask |
| S-box lookup | Variable (cache) | Use bitslicing |
| Table lookup | Variable (cache) | Use `vpshufb` SIMD |
| Multiplication | Usually constant | Beware of HW multiplier |
| Division | Variable | Avoid |
| Modulo by variable | Variable | Use Barrett/constant-time ops |

## 4. Electromagnetic Analysis

### 4.1 EM Side-Channel

Setiap perubahan tegangan di chip memancarkan EM field. Near-field probe bisa capture:

```
CPU → EM radiation → near-field H-probe → LNA (30dB) → oscilloscope
```

**Hardware:**
- Lang/TEM cell (far-field, whole device)
- Near-field H-probe (localized EM, select chip)
- LNA (Low Noise Amplifier, 30-40dB gain)
- Oscilloscope (2+ GS/s, 1 GHz bandwidth)

### 4.2 EM vs Power

| Aspect | Power Analysis | EM Analysis |
|--------|---------------|-------------|
| **Contact** | Direct (shunt resistor) | Non-contact (probe) |
| **Localization** | Whole chip | Single die/region |
| **Bandwidth** | Limited by shunt/PSU | >10 GHz possible |
| **Noise** | Power supply noise | Probe positioning critical |
| **Cost** | $200+ | $500+ (probe + LNA) |

## 5. Cache Attacks

### 5.1 Cache Timing — The Root of Spectre/Meltdown

CPU cache is **shared** between processes. Access time difference:

```
L1 cache hit:   ~4 cycles
L2 cache hit:   ~12 cycles
L3 cache hit:   ~40 cycles
RAM (DRAM):    ~200+ cycles
```

Attacker measures access time to detect victim's memory access pattern.

### 5.2 Prime+Probe

```
Phase 1: PRIME
  Fill cache set with attacker's data
Phase 2: WAIT
  Victim runs — may access some cache lines
Phase 3: PROBE
  Time to reload cache set
  Slow = victim accessed (evicted our line)
  Fast = victim didn't access

Victim accessed secret[index]? 
  probe[cache_set_of(secret[index])] > threshold → YES!
```

**Use case:** Detect keystroke timing, crypto key schedule.

### 5.3 Flush+Reload

```
Phase 1: FLUSH
  clflush(shared_memory[offset])
Phase 2: WAIT
  Victim runs — may access memory
Phase 3: RELOAD  
  time = measure_read(shared_memory[offset])
  if time < threshold → VICTIM ACCESSED!

Can differentiate instruction-level granularity!
```

**Use case:** Extract RSA private key from victim process, detect which RSA operation is running.

### 5.4 Cache Attack Comparison

| Method | Requires | Granularity | Detection |
|--------|----------|-------------|-----------|
| **Prime+Probe** | Shared cache only | Cache line (64B) | Cache set timing |
| **Flush+Reload** | Shared memory (same phys page) | **Byte-level** | Cache line timing |
| **Evict+Reload** | No clflush needed | Cache line (64B) | Cache eviction timing |
| **Evict+Time** | Shared cache | Operation-level | Total execution time |

## 6. Fault Injection

### 6.1 Voltage Glitching

Drop VCC momentarily → CPU executes faulty instruction.

```
Normal VCC:    ┌────┐    ┌────┐    ┌────┐
               │    │    │    │    │    │
               └────┘    └────┘    └────┘
               
Voltage Glitch: ┌────┐          ┌────┐
               │    │  ─────── │    │
               └────┘ ↑VCC drop└────┘
                      glitch
```

**Effect:** CPU skips instruction (NOP-like). Use: bypass password check.

```python
# ChipWhisperer: voltage glitch to bypass bootloader auth
import chipwhisperer as cw

scope = cw.scope()
target = cw.target(scope)

scope.glitch.output = "glitch_only"
scope.glitch.repeat = 10
scope.glitch.ext_offset = 100

for offset in range(100, 500, 10):
    scope.glitch.ext_offset = offset
    target.simpleserial_write('p', b'wrong_password')
    response = target.simpleserial_read('r', 10)
    if b"access_granted" in response:
        print(f"Bypassed at glitch offset {offset}!")
        break
```

### 6.2 Clock Glitching

Inject extra/short clock cycle → instruction corrupted.

```
Normal clock: ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐
              │  ││  ││  ││  ││  ││  │
              └──┘└──┘└──┘└──┘└──┘└──┘

Glitch clock: ┌──┐┌──┐┌┐┌──┐┌──┐┌──┐
              │  ││  ││││  ││  ││  │
              └──┘└──┘└┘└──┘└──┘└──┘
                    ↑glitch (short pulse)
```

### 6.3 EMFI — Electromagnetic Fault Injection

Menggunakan near-field EM probe untuk inject eddy current → bit flip.

```
EMFI Probe (high-voltage pulse generator)
    ↓
H-coil (near-field probe on chip)
    ↓
Eddy current → voltage in internal node → bit flip

Equipment: ChipSHOUTER ($500) or DIY
```

### 6.4 Techniques Summary

| Method | Equipment | Precision | Repeatability |
|--------|-----------|-----------|---------------|
| Voltage glitch | MOSFET + pulse gen | ±1-10ns | High |
| Clock glitch | FPGA-based | ±0.5ns | High |
| EMFI | HV coil + capacitor | ~100μm spot | Medium |
| Laser | Microscope + laser diode | ~1μm spot | Very High |

## 7. Defenses

### 7.1 Taxonomy of Defenses

```
Defenses
├── Algorithmic
│   ├── Constant-time implementation
│   └── Masking (boolean, arithmetic)
├── Hardware
│   ├── Dual-rail logic (WDDL)
│   ├── Glitch detection (voltage/clock monitors)
│   └── Shield layers (EM shield on die)
├── Software
│   ├── Random delay insertion
│   ├── Operation shuffling
│   └── Dummy instruction insertion
└── System
    ├── Cache partitioning (CAT)
    ├── Flush on context switch
    └── SMAP/SMEP/KPTI
```

### 7.2 Constant-Time Implementation

```c
// Variable-time (BAD):
int compare(const char *a, const char *b, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (a[i] != b[i]) return 0;  // EARLY EXIT → timing leak!
    }
    return 1;
}

// Constant-time (GOOD):
int constant_compare(const char *a, const char *b, size_t n) {
    int result = 0;
    for (size_t i = 0; i < n; i++) {
        result |= a[i] ^ b[i];  // Always loop full length
    }
    return result == 0;
}
```

## 8. Koneksi ke Vault

| Note | Hubungan |
|------|----------|
| [[hardware-hacking-re]] | Hardware attack surface, chip analysis, fault injection |
| [[cryptography-biometrics]] | Crypto implementations vulnerable to side-channel |
| [[exploit-development]] | Timing oracle → exploit primitive, glitching → auth bypass |
| [[fuzzing-vulnerability-research]] | Hardware fuzzing + fault injection |
| [[ics-scada-security]] | PLC safety systems — fault injection bisa bypass safety |
| [[automotive-can-bus-security]] | ECU glitching, timing analysis untuk key fob crypto |

---

### 📚 Referensi

1. "The Hardware Hacker" — Bunnie Huang
2. ChipWhisperer: [https://chipwhisperer.readthedocs.io/](https://chipwhisperer.readthedocs.io/)
3. "Power Analysis Attacks" — Mangard, Oswald, Popp
4. Flush+Reload: Yarom, Falkner (USENIX 2014)
5. Prime+Probe: Osvik (2006)
6. "A Practical Guide to Fault Injection" — Colin O'Flynn
7. Spectre/Meltdown papers (2018)