---
title: "Operating Systems: Three Easy Pieces (OSTEP)"
tags:
  - operating-systems
  - virtualization
  - concurrency
  - persistence
  - file-systems
aliases:
  - "OSTEP"
  - "Three Easy Pieces"
  - "Arpaci-Dusseau"
created: 2026-07-05
updated: 2026-07-05
status: active
---

# 🧵 Operating Systems: Three Easy Pieces

> Remzi H. Arpaci-Dusseau & Andrea C. Arpaci-Dusseau — 2018

**Tesis:** OS dibagi 3 pilar — **Virtualization** (CPU+memory), **Concurrency** (threads+locks), **Persistence** (file systems+disks). Dengan paham 3 ini, kamu paham gimana komputer kerja dari OS perspective.

**Akses: Free online → https://pages.cs.wisc.edu/~remzi/OSTEP/**

---

## 📌 Kenapa Penting

- OS textbook yang readable — gak kaya textboook kebanyakan
- Paham OS = paham _kenapa_ code kamu lambat, crash, atau kehabisan memory
- Disk scheduling, FAT vs ext4 vs NTFS, RAID — langsung relevan buat system design

## 🎯 Key Takeaways

### Part 1: Virtualization

**CPU Virtualization — Scheduling**

- Metrics: turnaround time, response time, fairness
- **FIFO** (simple, bad for short jobs)
- **SJF** (optimal turnaround, starvation)
- **Round Robin** (good response time, bad turnaround)
- **MLFQ** (blend — used in real OS) — multiple levels, priority boost, time slice

**Memory Virtualization**

- Address translation: base & bounds → segmentation → paging
- **TLB** (Translation Lookaside Buffer) — performance critical
- Page tables: multi-level (saves memory for sparse address space)
- Swapping: eviction policies (LRU ≈ optimal, FIFO simplest, Clock algorithm ≈ LRU-like)

### Part 2: Concurrency

- **Thread vs Process** — shared address space vs isolated
- **Locks:** test-and-set, compare-and-swap, fetch-and-add
- **Spin locks** vs **Mutex** (sleeping locks)
- **Condition Variables** — signaling between threads
- **Semaphores** — generalization of locks + CVs (bounded buffer → producer-consumer)
- **Deadlock:** Coffman conditions (all 4 must hold) + prevention strategies

### Part 3: Persistence

- **Disks:** seek + rotation + transfer — _I/O time dominated by seek_
- **RAID 0, 1, 4, 5, 6** — redundancy vs capacity vs performance trade-offs
- **File Systems:**
  - FFS (Unix Fast File System) — cylinder groups, block groups
  - ext2 → ext3 (journaling) → ext4 (extents)
  - **Journaling (WAL):** atomicity — write intent log first
  - **LFS (Log-structured FS):** treat disk as log — Netflix's approach
- **Flash-based SSDs:** erase before write → wear leveling, FTL, TRIM

## 📖 Bab Penting

| Bab   | Judul                 | Mengapa                                   |
| ----- | --------------------- | ----------------------------------------- |
| 4-8   | CPU Scheduling        | MLFQ — bagaimana OS manage your processes |
| 13-16 | Memory Virtualization | Paging, TLB — **wajib**                   |
| 26-31 | Concurrency & Locks   | Threads, semaphore, deadlock — **wajib**  |
| 36-40 | File Systems          | ext3 journal, LFS, WAFL                   |
| 41    | Flash SSD             | —                                         |
| 47-51 | Distribution          | NFS, AFS — distributed filesystems        |

## ⚠️ Tantangan

- **Projects in C** — gak ada yang nyelametin dari pointer arithmetic
- Soal latihan butuh simulator Python yang disediain (beres)
- Cover to cover ≈ 500 hal — readable tapi tetap butuh waktu

## 🔗 Koneksi

- [[csapp-bryant-ohallaron]] — CS:APP = programmer perspective, OSTEP = OS designer perspective
- [[ddia-kleppmann]] — distributed systems butuh OS fundamentals
- [[sre-google]] — reliability juga soal OS level (OOM, I/O scheduling)

## ✅ Checklist

- [ ] Simulasi MLFQ scheduler — bandwidth pakenya?
- [ ] Paging simulation: multi-level page table savings
- [ ] Concurrency: solve producer-consumer + reader-writer pake semaphores
- [ ] Implementasi simple filesystem simulator (inode + data block)
- [ ] Baca soal RAID — kapan pilih RAID 0, 1, 5, 6, 10?
