---
title: Attack Perspective — Programming Language (Red Team)
tags:
- attack
- red-team
- programming-language
- memory-corruption
- abi
- jit
- type-confusion
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Programming Language — Perspektif Penyerang

> Setiap bahasa punya model memori sendiri. Red team eksploitasi: memory corruption (C/C++), type confusion (C++/Rust unsafe), JIT bug (V8/SpiderMonkey), deserialization (Java/.NET), injection (PHP/Python).

## 1. Attack Surface per Paradigma

| Paradigma | Bahasa | Vektor Utama | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|-----------|--------|-------------|----------|------------|---------|----------------|
| **Manual Memory** | C, C++ | Buffer overflow, UAF, double-free, type confusion | T1205.002 | pwntools, CVE-2023-4911 | ASLR bypass via leak → ROP chain | ASLR/DEP/CFI partial |
| **Managed Runtime** | Java, C# | Deserialization, JIT spray, class loader abuse | T1190 | ysoserial, CVE-2017-5638 | Gadget chain → RCE | SAST jarang detect gadget |
| **Interpreted** | Python, Ruby, PHP | Injection, pickle RCE, eval, template injection | T1190 | SSTImap, pickle exploit | Eval = arbitrary code → subprocess | WAF jarang detect template injection |
| **JIT Compiled** | JavaScript (V8), LuaJIT | JIT spray, type confusion, bounds removal | T1190 | V8 exploit, CVE-2024-XXXX JIT bug | JIT code page = RWX → shellcode | V8 sandbox partial |
| **Rust (unsafe)** | Rust | unsafe block → UAF, raw pointer deref | T1205.002 | CVE-2024-XXXX (unsafe Rust) | unsafe bypass borrow checker | Memory safety = safe block only |
| **Go** | Go | Goroutine race, interface{} type assertion panic | T1205.002 | Race condition → UAF | Race = non-deterministic, hard detect | Go race detector = runtime only |
| **Nim** | Nim | Memory corruption (C-backend), FFI abuse | T1205.002 | Custom exploit, FFI → libgc | Nim = rare → EDR no signature | Rare language = low detection |
| **Assembly** | x86/ARM | Shellcode, ROP gadget, syscall | T1055 | pwntools, ropper, ROPgadget | Custom shellcode → no signature | EDR syscall hook → direct syscall bypass |

## 2. Memory Corruption Chain (C/C++)

```
Recon: Identifikasi input yang menuju buffer (strcpy, memcpy, sprintf)
 ↓
Vulnerability: Stack overflow / heap overflow / UAF / type confusion / off-by-one
 ↓
Proteksi Bypass:
 ├── ASLR: info leak (format string, buffer overread) → leak base address
 ├── Stack canary: leak canary (printf %x, buffer overread) → place di payload
 ├── NX/DEP: ROP chain (ropper/ROPgadget) → ret2libc / ret2syscall
 ├── CFI: JOP (Jump-Oriented), COOP, data-only attack (modify data, bukan control)
 └── RELRO: partial RELRO → overwrite GOT entry
 ↓
Exploit: ROP chain → execve("/bin/sh") atau mprotect+shellcode
 ↓
Payload: In-memory loader (DONUT/sRDI) → load beacon
 ↓
Evasion: direct syscall → bypass EDR hook, no new process
```

## 3. V8 / JIT Exploit Chain (JavaScript)

```
Recon: Browser target + V8 version (Chrome version mapping)
 ↓
Bug Type:
 ├── Type confusion: JIT optimizes type assumption → wrong type → OOB
 ├── Bounds removal: JIT removes bounds check (range analysis error)
 ├── JIT spray: generate RWX code page → embed shellcode di JIT code
 └── UAF: JIT compiled code holds stale reference → UAF
 ↓
Exploit:
 ├── Trigger bug → OOB read/write → arbitrary memory access
 ├── Leak object addr → forge object → type confusion → arbitrary R/W
 ├── Overwrite WASM RWX page → shellcode
 └── Execute shellcode → sandbox escape atau RCE
 ↓
Sandbox Bypass (V8 Sandbox 2024+):
 ├── V8 sandbox = isolate V8 heap → no direct host memory access
 ├── Bypass: corrupt sandbox internal object → escape
 └── Alternative: V8 bug → renderer → sandbox escape (Mojo IPC → browser)
```

## 4. CVE per Bahasa (2024-2026)

| CVE | Bahasa | Target | Impact | Red Team Value |
|-----|--------|--------|--------|----------------|
| CVE-2023-4911 | C (glibc) | Linux glibc | Local root | High — all GLIBC < 2.37 |
| CVE-2024-1086 | C (Linux kernel) | nf_tables | Local root | High — common kernel |
| CVE-2024-XXXX | Rust (unsafe) | Various | UAF → RCE | Medium — unsafe block |
| CVE-2021-44228 | Java (Log4j) | Log4Shell | RCE via JNDI | Critical — everywhere |
| CVE-2017-5638 | Java (Struts) | Apache Struts OGNL | RCE via OGNL injection | Historical — Equifax |
| CVE-2024-XXXX | V8 (Chrome) | JIT type confusion | RCE → sandbox escape | High — browser exploit |

## 5. Tool Stack

| Tool | Bahasa | Use |
|------|--------|-----|
| **pwntools** | C/C++ | Exploit framework (ROP, shellcode, leak helper) |
| **ropper / ROPgadget** | C/C++ | ROP gadget finder |
| **ysoserial** | Java | Deserialization payload generator |
| **ysoserial.net** | C# |.NET deserialization payload |
| **PHPGGC** | PHP | PHP deserialization payload |
| **SSTImap** | Python/Java | SSTI exploitation |
| **d8 / V8 standalone** | JavaScript | V8 exploit development |
| **Turbofan/lgnition** | JavaScript | V8 JIT debugger (d8 --trace-turbo) |

## 6. Referensi
- pwntools — https://docs.pwntools.com/
- ysoserial — https://github.com/frohoff/ysoserial
- V8 Exploit — https://v8.dev/docs/build
- ROPgadget — https://github.com/JonathanSalwan/ROPgadget
- LiveOverflow (Binary Exploit) — https://www.youtube.com/@LiveOverflow
---

audited
---
