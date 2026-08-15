---
title: Attack Perspective — CTF Competition Framework (Red Team Training)
tags:
- attack
- red-team
- ctf
- pwn
- web
- crypto
- forensics
- reverse
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# CTF Framework — Perspektif Penyerang (Skill Transfer)

> CTF = lab terbaik untuk red team skill development. Setiap kategori CTF = attack technique yang applicable ke real-world. Red team pakai CTF untuk: melatih exploit development, bypass tecnique, tool mastery.

## 1. CTF Category → Real-World Mapping

| Kategori CTF | Skill yang Dikembangkan | Transfer ke Real Red Team | Tool Stack |
|-------------|------------------------|---------------------------|------------|
| **Pwn** | Binary exploit (stack, heap, format string) | CVE reproduction → custom exploit → 0-day hunting | pwntools, gdb, ghidra, ropper |
| **Web** | SQLi, XSS, SSRF, SSTI, deserialization | Web pentest → app exploit → API abuse | Burp Suite, sqlmap, ffuf, SSTImap |
| **Crypto** | Classical + modern (RSA, AES, lattice, PQC) | Crypto implementation bug → key extraction | SageMath, pyCryptodome, hashcat |
| **Forensics** | Disk/memory/network → artifact recovery | DFIR → artifact analysis → anti-forensics | Volatility, Autopsy, Wireshark, KAPE |
| **Reverse** | Binary RE → key extraction → patch | Malware RE → firmware RE → protocol RE | Ghidra, IDA, x64dbg, Frida |
| **Misc** | OSINT, stego, scripting, physical | Recon → social engineering → creative attack | stegsolve, exiftool, custom script |

## 2. Pwn → Real-World Exploit Chain

```
CTF Pwn Training:
 ├── Stack overflow → canary leak → ROP → shellcode
 ├── Heap exploitation → tcache poison → UAF → arbitrary write
 ├── Format string → leak + write → GOT overwrite → control
 └── Kernel pwn → ret2usr → modprobe_path → root
 ↓
Transfer ke Real World:
 ├── Identifikasi target binary (server daemon, SUID, client app)
 ├── RE → find vulnerability (buffer overflow, UAF, type confusion)
 ├── Bypass proteksi: ASLR (leak) → canary (leak) → NX (ROP) → CFI (JOP)
 ├── Build exploit: pwntools → ROP chain → execve/mprotect + shellcode
 └── Deliver: remote trigger → shell → C2 beacon
```

## 3. Web → Real-World Pentest Chain

```
CTF Web Training:
 ├── SQLi → dump → RCE (INTO OUTFILE / xp_cmdshell)
 ├── XSS → cookie theft → session hijack
 ├── SSRF → internal scan → cloud metadata (IMDS)
 ├── SSTI → RCE (Jinja2 MRO → subprocess)
 └── Deserialization → gadget chain → RCE
 ↓
Transfer ke Real World:
 ├── Recon: ffuf → directory → endpoint → parameter
 ├── Enumerasi: Burp Proxy → parameter → injection test
 ├── Exploit: sqlmap / manual → data dump atau RCE
 ├── Privilege: SQLi → admin → lateral → domain
 └── Persistence: Webshell → periodic callback
```

## 4. Tool Stack CTF → Red Team

| Tool | Kategori CTF | Real Red Team Use |
|------|-------------|-------------------|
| **pwntools** | Pwn | Exploit development (ROP, shellcode) |
| **gdb / pwndbg / GEF** | Pwn | Debug + exploit verification |
| **Ghidra / IDA** | Reverse | Binary analysis → vuln identification |
| **ropper / ROPgadget** | Pwn | ROP gadget finder |
| **Burp Suite** | Web | Proxy + intercept + scan |
| **sqlmap** | Web | Automated SQLi |
| **SageMath** | Crypto | Mathematical crypto analysis |
| **Volatility** | Forensics | Memory forensics |
| **Wireshark** | Forensics/Network | Packet capture analysis |
| **Frida** | Reverse/Mobile | Dynamic instrumentation |

## 5. Platform Training

| Platform | Fokus | Level |
|----------|-------|-------|
| **HackTheBox** | Active boxes (Windows/Linux) | Beginner → Expert |
| **TryHackMe** | Guided learning path | Beginner → Intermediate |
| **PentesterLab** | Web exploit → badge | Beginner → Advanced |
| **CTFtime** | CTF event tracker | All level |
| **picoCTF** | Beginner-friendly CTF | Beginner |
| **pwn.college** | Binary exploitation | Intermediate → Expert |
| **CrackMes.one** | Reverse engineering | All level |

## 6. Referensi
- pwn.college — https://pwn.college/
- HackTheBox — https://www.hackthebox.com/
- CTFtime — https://ctftime.org/
- pwntools — https://docs.pwntools.com/
- pwndbg — https://github.com/pwndbg/pwndbg

audited
---
