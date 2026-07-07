---
title: "Computer Systems: A Programmer's Perspective (CS:APP)"
tags:
  - computer-systems
  - assembly
  - memory-hierarchy
  - architecture
  - performance
aliases:
  - "CS:APP"
  - "Bryant & O'Hallaron"
  - "Computer Systems"
created: 2026-07-05
updated: 2026-07-05
status: active
---

# 🖥 Computer Systems: A Programmer's Perspective

> Randal E. Bryant & David R. O'Hallaron — 2003 (3rd ed 2015)

**Tesis:** Programmer yang paham _bagaimana kodenya jalan di mesin_ → bikin code yang lebih cepat, lebih aman, lebih bisa di-debug. Bukan soal jadi expert arsitektur — soal _jembatani gap_ antara high-level language dan hardware.

---

## 📌 Kenapa Penting

- Buku yang menjawab: "kenapa C code ini lambat padahal algoritma udah optimal?"
- Performance optimization bukan trik — ilmu tentang memori hierarchy, pipelining, branching
- Debugging segfault / buffer overflow → paham stack layout, calling convention

## 🎯 Key Takeaways

**1. Representasi Data — Bits, Bytes, Integers**

- Little Endian vs Big Endian — penting buat networking
- Two's complement — overflow behavior
- Floating point — IEEE 754 — kenapa 0.1 + 0.2 != 0.3

**2. Machine-Level Code — Assembly (x86-64)**

- Register, stack, calling convention (System V ABI)
- **Paling berguna buat debugging:** baca disassembly waktu crash
- Control flow: conditional, loop, switch — gimana compiler optimize

**3. Memory Hierarchy**

- **CPU → L1 → L2 → L3 → RAM → Disk** — urutan kecepatan (1000x gap)
- **Cache Locality** — spatial + temporal — bedanya 10-100x performance
  - Loop order matters: row-major > column-major
- Cache miss = stall pipeline = CPU nganggur

**4. Linking**

- Symbol resolution + relocation — kenapa linker errors
- Static vs dynamic linking — trade-off size, security, startup time
- Library interpositioning — LD_PRELOAD

**5. Exceptional Control Flow**

- Interrupt, trap, fault, abort — bedanya
- Context switch — proses scheduler preempt your code
- Signals — asynchronous handling

**6. Virtual Memory**

- Page table — address translation via TLB
- **MMU mismatch = performance killer** — TLB miss
- mmap — memory-mapped files
- COW (Copy-On-Write) — fork() efficient

**7. System-Level I/O**

- Unix file descriptors, buffer management
- Non-blocking I/O, select, epoll

**8. Concurrency**

- Threads vs processes — sharing vs isolation
- Mutex, semaphore, deadlock
- Cache coherence — false sharing (performance killer)

## 📖 Bab Penting

| Bab | Judul                          | Mengapa                                     |
| --- | ------------------------------ | ------------------------------------------- |
| 3   | Machine-Level Programming      | Assembly + debugging — **wajib**            |
| 5   | Optimizing Program Performance | Loop optimization, branch prediction, cache |
| 6   | Memory Hierarchy               | **Kunci performance** — cache matters       |
| 9   | Virtual Memory                 | Soal kenapa RAM gak cukup → swap, mmap      |
| 12  | Concurrent Programming         | Threads, locks, deadlock                    |

## ⚠️ Tantangan

- **Butuh C knowledge** — contoh kode semuanya C
- Fokus x86-64 — gak cover ARM (tapi konsep transferable)
- Lab (Bomb Lab, Attack Lab, Shell Lab) — bagian paling bagus tapi butuh setup

## 🚦 Strategi Baca

1. **Ch 1-3**: bits, assembly, debugging — pain point immediate
2. **Ch 5-6**: performance optimization + cache — _biggest bang for buck_
3. **Ch 9**: virtual memory — paham kenapa proses terisolasi
4. **Ch 12**: concurrency
5. Lab resources di **csapp.cs.cmu.edu** — Bomb Lab highly recommended

## 🔗 Koneksi

- [[ostep-three-easy-pieces]] — OS bagian dari CS:APP, OSTEP cover lebih detail
- [[clrs-introduction-to-algorithms]] — algoritma _logical_, CS:APP _mechanical_
- [[clean-code-robert-martin]] — clean code gak cukup kalo gak paham hardware impact

## ✅ Checklist

- [ ] Baca assembly output dari compiler — `objdump -d` atau Godbolt
- [ ] Profile 1 fungsi — cache misses, branch mispredictions (perf stat)
- [ ] Optimize 1 loop — transpose loop order, test speedup
- [ ] Debug 1 segfault — pake GDB + backtrace (paham stack frame)
