---
title: Attack Perspective — Reverse Engineering (Red Team)
tags: [attack,red-team,re,reverse-engineering,malware,exploit]
source: hierarchy-reverse-engineering.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Reverse Engineering — Perspektif Penyerang

> RE bukan hanya untuk malware analysis (defender) — red team pakai RE untuk: analisis target binary (cari bug), bypass anti-cheat/DRM, ekstrak credential dari binary, dan modifikasi firmware.

## 1. Attack Use Case RE

| Use Case | Goal | Tool Stack | Mitre / CVE |
|----------|------|------------|-------------|
| **Bug hunting** | Cari vulnerability di target binary (0-day) | Ghidra, IDA Pro, Binary Ninja, radare2 | T1190 (Exploit Public App) |
| **Malware modifikasi** | Modifikasi malware existing → bypass signature | x64dbg, Cutter, HxD, PE-bear | T1027 (Obfuscation) |
| **Firmware RE** | Ekstrak firmware, cari hardcoded creds, modify boot chain | binwalk, Factory Flash Tools, Ghidra | T1542 (Pre-OS Boot) |
| **Bypass DRM/anti-cheat** | Hapus license check, bypass game anti-cheat | Cheat Engine, Scylla, x64dbg | T1562 (Impair Defenses) |
| **Credential ekstrak** | Ekstrak API key, password, token dari binary | strings, FLOSS, Ghidra decompiler | T1552 (Unsecured Credentials) |
| **Protocol RE** | Reverse proprietary protocol → C2 mimicry | Wireshark + Ghidra, custom dissector | T1071 (Application Layer Protocol) |

## 2. RE Tool Chain (Red Team Workflow)

```
Static Analysis:
 file → entropy → packing detection (UPX, custom packer)
 strings / FLOSS → ekstrak string (URL, IP, credential, config)
 Ghidra/IDA → decompile → identify vuln pattern (strcpy, sprintf, malloc)
 CAPA → capability analysis → YARA match

Dynamic Analysis:
 x64dbg / GDB → debug → breakpoint at vuln function
 Frida → hook function → intercept argument → bypass check
 strace/ltrace → syscall trace → identify behavior (C2, file access, exfil)
 BPF target → inject payload → test exploit reliability

Firmware:
 binwalk → extract → filesystem → credentials → modify → repack → flash
 CHIPSEC → audit SPI flash → UEFI module analysis → inject
```

## 3. Anti-Reverse Engineering (Target Side → Red Team Bypass)

| Proteksi Target | Bypass Teknik | Tool |
|-----------------|---------------|------|
| **ASLR** | Info leak → KASLR/address leak → calculate base | pwntools (leak helper) |
| **Stack canary** | Leak canary via printf format string / buffer overread | pwntools (canary leak) |
| **DEP/NX** | ROP chain (ropper, ROPgadget) → ret2libc / ret2syscall | pwntools + ropper |
| **CFI (Control Flow Integrity)** | JOP (Jump-Oriented Programming), COOP, data-only attack | Custom chain — limited gadget |
| **Packing (UPX/custom)** | Unpack: dump dari memory (x64dbg dump), UPX -d, custom unpacker | x64dbg, Scylla (IAT rebuild) |
| **Anti-debug** | IsDebuggerPresent bypass (patch), hardware breakpoint clear, NtGlobalFlag clear | x64dbg (ScyllaHide plugin), Frida |
| **Code signing** | Strip signature / fake cert / cert injection | sigthief, CodeSign bypass |

## 4. CVE dari RE Workflow

| CVE | Ditemukan via RE | Impact | Red Team Value |
|-----|-----------------|--------|----------------|
| CVE-2021-3156 | RE sudo binary → heap overflow di set_cmnd | Local root — sudo, widespread | High |
| CVE-2023-4911 | RE glibc → tunable_files buffer overflow | Local root — glibc, semua Linux dengan GLIBC < 2.37 | High |
| CVE-2024-1086 | RE nf_tables kernel module → UAF | Local root — Linux kernel 5.14+ | High |
| CVE-2022-0847 | RE Linux kernel pipe code → write to read-only page | Local root — kernel 5.8-5.16 | High |
| CVE-2022-26923 | RE AD CS → template misconfig -> DA cert | Domain admin via cert | Critical |

## 5. Referensi
- Ghidra (NSA) — https://ghidra-sre.org/
- IDA Pro — https://hex-rays.com/
- Binary Ninja — https://binary.ninja/
- x64dbg — https://x64dbg.com/
- Frida (Dynamic Instrumentation) — https://frida.re/
-_pwntools — https://docs.pwntools.com/
- binwalk (Firmware RE) — https://github.com/ReFirmLabs/binwalk
- CAPA (Capability Analysis) — https://github.com/mandiant/capa
- FLOSS (String Extraction) — https://github.com/mandiant/flare-floss