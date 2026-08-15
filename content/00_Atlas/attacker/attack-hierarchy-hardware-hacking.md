---
title: Attack Perspective — Hardware Hacking (Red Team)
tags:
- attack
- red-team
- hardware
- uart
- jtag
- side-channel
- fault-injection
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Hardware Hacking — Perspektif Penyerang

> Hardware hacking = akses fisik ke device → ekstrak credential, flash firmware, bypass secure boot, tap komunikasi. Red team pakai untuk: IoT exploitation, embedded device credential extraction, firmware modification.

## 1. Attack Surface Hardware

| Interface | Attack Vector | Tool | Mitre / CVE | Evasion |
|-----------|--------------|------|-------------|---------|
| **UART** | Debug console → root shell (IoT/router/camera) | USB-TTL (FT232, CP2102), minicom, picocom | T1542 (Pre-OS Boot) | Tidak perlu — UART = debug interface, no auth |
| **JTAG** | Boundary scan → memory read/write → firmware dump | JLink, OpenOCD, busblaster | T1602 (Device Configuration Dump) | JTAG sering disabled (fuse) — bypass via fuse bypass atau glitch |
| **SPI Flash** | Firmware dump → extracted creds → modify → reflash | CH341A, flashrom,clip SOIC8 | T1542 (Pre-OS Boot) | SPI dump = full firmware → hardcoded creds, keys |
| **I2C** | EEPROM read → config dump → modification | i2cdetect, i2cdump | T1552 (Unsecured Creds) | EEPROM sering tidak terenkripsi |
| **Side-channel** | Power/EM/timing analysis → ekstrak key | ChipWhisperer, PicoScope, custom | T1542 (Exfiltration) | Side-channel = no software trace, pure physical |
| **Fault injection** | Voltage/clock glitch → bypass secure boot/checksum | ChipWhisperer, custom glitcher | T1542 (Pre-OS Boot) | Glitch = transient, no persistent artifact |

## 2. IoT/Embedded Attack Chain

```
Physical access (device obtain)
 ↓
Visual recon → identify chip (SoC, flash, RAM)
 ↓
UART test → solder/clip → baudrate scan → root shell?
 ├── Ya → dump config, extract creds, install backdoor
 └── Tidak → JTAG test → boundary scan → firmware dump
 ↓
SPI flash dump (flashrom + CH341A)
 ↓
binwalk extract → filesystem → hardcoded credentials, API keys, SSH keys
 ↓
Firmware modification → add backdoor → reflash
 ↓
Return device → pasif collection (C2, credential exfil)
```

## 3. Side-Channel & Fault Injection Deepdive

| Teknik | Target | Konkret | Hasil |
|--------|--------|---------|-------|
| **SPA (Simple Power Analysis)** | Smartcard → AES key | ChipWhisperer → capture trace → visual DPA → key recovery | AES-128 key dalam ~50 trace |
| **DPA (Differential)** | Hardware crypto → key | Differential analysis → key recovery | AES key dalam ~5000 trace |
| **CPA (Correlation)** | Hardware → key | Correlation analysis → key recovery | AES key dalam ~1000 trace |
| **Voltage glitch** | Secure boot bypass | Glitch saat boot check → bypass signature verify | Boot unsigned firmware |
| **Clock glitch** | bypass checksum/jump | Glitch clock saat jump instruction → skip check | Bypass license/auth check |
| **EM injection** | Memory corruption | RF energy → bit flip in SRAM → bypass check | Transient — no persistent artifact |
| **Rowhammer** | DRAM bit flip (software) | Rowhammer.js, Blacksmith → flip bit → privilege escalation | CVE-2020-XXXX (ZombieLoad variant) |

## 4. Tool Stack Hardware

| Tool | Use | Harga (approx) |
|------|-----|----------------|
| **CH341A + SOIC8 clip** | SPI flash read/write | $5 |
| **FT232 / CP2102** | USB-TTL untuk UART | $3 |
| **JLink / ST-Link** | JTAG/SWD debug | $20 (clone) - $500 (original) |
| **logic analyzer** | SPI/I2C/UART capture | $10 (8ch) - $150 (16ch) |
| **ChipWhisperer** | Power analysis + glitch | $250 (Lite) - $3000 (Pro) |
| **flashrom** | SPI flash tool (software) | Free |
| **binwalk** | Firmware extraction (software) | Free |
| **OpenOCD** | JTAG debug (software) | Free |

## 5. Referensi
- Ray.permissiondenied.netnotes (Hardware Hacking) — https://github.com/_PERMISSIONDENIED
- flashrom — https://flashrom.org/
- binwalk — https://github.com/ReFirmLabs/binwalk
- OpenOCD — https://openocd.org/
- Joe Grand (Hardware Hacking) — https://www.grandideastudio.com/
---

audited
---
