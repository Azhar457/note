---
title: Attack Perspective — Compiler Design (Red Team)
tags:
- attack
- red-team
- compiler
- optimization
- jit
- rop
- cfi-bypass
- code-injection
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Compiler Design — Perspektif Penyerang

> Compiler = transformer source code → binary. Red team eksploitasi: optimization bug (undefined behavior → memory corruption), JIT spray (RWX code page), ROP gadget generation (ABI knowledge), CFI bypass (compiler-generated indirection).

## 1. Attack Surface Compiler

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **Optimization (UB)** | Undefined behavior → compiler removes check → memory corruption | T1205.002 | Exploit UB → buffer overflow → RCE | UB = silent → no runtime alert | Static analyzer = partial UB detection |
| **JIT Spray** | JIT compiled code → RWX page → embed shellcode | T1055 | JIT spray → shellcode in RWX page | RWX = legit JIT mechanism | JIT sandbox = partial |
| **ROP Gadget** | Compiler generates predictable code pattern → gadget | T1055.012 | ropper/ROPgadget → chain → bypass NX | ROP = use existing code → no shellcode | CFI = partial, partial bypass |
| **CFI Bypass** | Compiler-issued CFI → indirect branch check | T1205.002 | JOP (Jump-Oriented), COOP, data-only attack | CFI = pointer restriction → bypass via data | CFI = partial |
| **Stack Protector** | Compiler canary → leak → bypass | T1055.012 | printf format string → leak canary → use in payload | Canaries = static per process | Canary leak = trivial (format string) |
| **Relocation (RELRO)** | Partial RELRO → GOT overwrite | T1055.012 | GOT overwrite → redirect function → control | GOT = writable (partial RELRO) | Full RELRO = partial deploy |
| **PIC/PIE** | Position-Independent Executable → ASLR | T1055.012 | Info leak → calculate base → ROP | ASLR = random base → leak bypass | ASLR bypass = info leak (format string) |
| **Linker (LD_PRELOAD)** | Dynamic linker → library injection | T1574.006 | LD_PRELOAD → inject.so → hook function | LD_PRELOAD = legit env variable | Env audit = rare |

## 2. JIT Spray Attack Chain

```
Target: JIT engine (V8, SpiderMonkey, LuaJIT)
 ↓
Trigger: Attacker controlled JavaScript/Lua → JIT compile
 ↓
JIT Code Generation:
 ├── JIT compile function with embedded constant (float → IEEE 754)
 ├── Constant value = valid x86 shellcode (carefully chosen)
 ├── JIT allocate RWX page → write JIT code (contains shellcode as constant)
 └→ RWX page = executable → jump to shellcode embedded in constant
 ↓
Execute:
 ├── Trigger JIT function → JIT code page = RWX
 ├── Jump to shellcode offset → execute embedded shellcode
 └→ RCE (remote code execution)
 ↓
Modern Mitigation:
 ├── JIT sandbox (V8) → isolate JIT heap → no direct host memory
 ├── W^X (Write XOR Execute) → alternate RW and RX (not RWX)
 └→ Bypass: race condition (write during RW → flip to RX → execute)
```

## 3. ROP Chain Construction

```
Recon: Binary analysis (Ghidra/IDA) → identify gadgets
 ↓
Gadget Collection:
 ├── ropper / ROPgadget → search binary for `pop; ret` patterns
 ├── pwntools ROP() → auto gadget chain builder
 └→ Target: pop rdi; ret → address → execve args → syscall
 ↓
Chain Construction:
 ├── pop rdi; ret → address("/bin/sh")
 ├── pop rsi; ret → 0 (argv)
 ├── pop rdx; ret → 0 (envp)
 ├── pop rax; ret → 0x3b (execve syscall number)
 └→ syscall → execve("/bin/sh", 0, 0) → shell
 ↓
Bypass:
 ├── ASLR: info leak → base address → calculate gadget address
 ├── Stack canary: leak canary → place in payload before ret
 └→ NX/DEP: ROP = use existing code → no shellcode needed (bypass NX)
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **ropper** | ROP gadget finder |
| **ROPgadget** | Alternative ROP gadget finder |
| **pwntools** | Exploit framework (ROP builder, shellcode, leak) |
| **Ghidra/IDA** | Binary analysis → identify gadget, vuln |
| **GEF/pwndbg** | GDB plugin (ROP, memory, exploit dev) |
| **angr** | Symbolic execution → automatic exploit |

## 5. Referensi
- ropper — https://github.com/sashs/Ropper
- ROPgadget — https://github.com/JonathanSalwan/ROPgadget
- pwntools — https://docs.pwntools.com/
- angr — https://angr.io/
- JIT Spray — https://www.ieee-security.org/TC/SP2011/PAPERS/2011a.pdf