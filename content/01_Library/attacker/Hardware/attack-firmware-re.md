---
title: Attack Perspective — Firmware RE (Red Team)
tags:
- attack
- red-team
- firmware
- binwalk
- uefi
- spi-flash
- backdoor
- extraction
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Firmware RE — Perspektif Penyerang

> Firmware = code yang jalan sebelum OS — perfect untuk persistence tersembunyi. Red team: firmware extraction (SPI flash), hardcoded credential mining, backdoor injection, UEFI implant, secure boot bypass.

## 1. Attack Surface Firmware

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **SPI Flash** | Firmware dump → creds → modify → reflash | T1602 | CH341A, flashrom | Physical dump = no trace | Firmware audit = rare |
| **UEFI/BIOS** | Bootkit implant, secure boot bypass | T1542.003 | BlackLotus, CHIPSEC | Pre-OS = survive reinstall | Firmware verify = rare |
| **Bootloader** | Bootkit, kernel hook before OS | T1542.001 | Custom bootloader | Pre-OS = below EDR | Bootloader audit = rare |
| **SoC ROM** | Boot ROM exploit → early code exec | T1542 | Custom exploit | ROM = trusted | ROM audit = none |
| **Option ROM** | GPU/NIC firmware backdoor | T1542 | Option ROM inject | Hardware = trusted | Option ROM audit = rare |
| **IPMI/BMC** | Server management firmware → OOB access | T1546 | IPMI exploit, BMC backdoor | OOB = separate CPU | BMC audit = rare |
| **Hardcoded Secret** | Credential in firmware → network device access | T1552 | strings, binwalk extract | Secret = valid access | Secret audit = rare |

## 2. Firmware Extraction Chain

```
Physical Access / Vendor Download:
  ├── CH341A + SOIC8 clip → SPI flash read
  ├── Vendor update file → download
  ├── JTAG → memory dump
  └→ UART → shell → flash dump
    ↓
Extract:
  ├── binwalk -Me firmware.bin → auto extract
  ├── Identify: filesystem (squashfs, jffs2, ubifs, cramfs)
  ├── Extract FS: binwalk -e → unsquashfs → filesystem
  └→ Structure: kernel, rootfs, bootloader, config
    ↓
Mine:
  ├── strings → URL, IP, credential, SSH key
  ├── grep -r "password\|secret\|token" → config
  ├── Shadow/passwd → hash → crack
  └→ Identify: default creds, hardcoded API key
    ↓
Modify:
  ├── Add backdoor → repack → reflash
  ├── Remove auth check → bypass
  ├── Change C2 endpoint → redirect
  └→ UEFI module → bootkit
```

## 3. UEFI Implant (Bootkit)

```
Prereq: Admin/SYSTEM + secure boot bypass (CVE-2022-0001)
    ↓
Implant:
  ├── Write UEFI module ke SPI flash
  ├── Hook boot process (BeforeExitBootServices)
  └→ Load malicious driver → kernel hook → C2
    ↓
Stealth:
  ├── Pre-OS = EDR blind
  ├── Survive disk wipe + reinstall
  ├── Secure Boot = bypass (CVE-2022-0001)
  └→ Verification: vendor tools only (rare)
    ↓
Persistence: UEFI = flash → survive everything
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **binwalk** | Firmware extraction |
| **flashrom** | SPI flash read/write |
| **CH341A + SOIC8** | Physical flash access |
| **Ghidra** | Firmware RE (binary analysis) |
| **CHIPSEC** | UEFI/BIOS security audit |
| **UEFITool** | UEFI module extract/insert |
| **strings / FLOSS** | String/credential mining |
| **QEMU** | Firmware emulation (dynamic analysis) |

## 5. Referensi
- binwalk — https://github.com/ReFirmLabs/binwalk
- flashrom — https://flashrom.org/
- UEFITool — https://github.com/LongSoft/UEFITool
- CHIPSEC — https://github.com/chipsec/chipsec
- Firmware RE (Attify) — https://www.attify.com/firmware-analysis-toolkit
- BlackLotus — https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/

## Konkret — Firmware Extraction (Testable)

### Binwalk Extraction

```bash
# Scan firmware image
binwalk firmware.bin
# Output: lokasi kernel, filesystem, header

# Extract semua bagian
binwalk -Me firmware.bin
# -M recursive, -e extract

# Check filesystem type
binwalk -A firmware.bin
```

### U-Boot / UEFI Analysis

```bash
# U-Boot environment (konfigurasi boot)
strings firmware.bin | grep -i "bootcmd\|bootargs"
# bootargs berisi console=ttyS0, root=... → info boot

# UEFI firmware (insyde/ami/award)
# UEFITool → extract FFS volumes
# 1. UEFITool firmware.rom → parse → export sections
# 2. Cari DXE driver, NVRAM var
# 3. ifme_xtract → ME (Intel Management Engine) firmware
```

### Firmware Backdoor Patterns

```bash
# 1. Hardcoded credentials
strings firmware.bin | grep -E "password|admin|root|telnet"
# 2. Telnet/SSH hidden service
strings firmware.bin | grep -E "telnetd|dropbear|sshd"
# 3. Update server URL (update hijack)
strings firmware.bin | grep -i "update\|download.*bin"
# 4. Magic bytes / known signature
binwalk firmware.bin | grep -E "LZMA|gzip|JFFS2|SquashFS|cramfs"
```

### SPI Flash Dump (Hardware)

```bash
# 1. Connect flashrom ke chip (SOIC8 clip)
flashrom -p linux_spi:dev=/dev/spidev0.0 -r firmware.bin
# 2. Chip-off: read via SPI programmer
flashrom -p ch341a_spi -r firmware.bin
# 3. Identify chip: flashrom --list-supported
```

### UART / JTAG

```bash
# UART console (3.3V, 115200 baud default)
screen /dev/ttyUSB0 115200
# Prompt muncul → boot shell, login via busybox

# JTAG (debug port) — OpenOCD
openocd -f interface/jlink.cfg -f target/nrf52.cfg
# dump flash via debug probe → extract firmware
```
---

audited
---
