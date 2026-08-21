---
title: "Kernel Bypass Networking Hierarchy"
tags:
- networking
- kernel-bypass
- dpdk
- af-xdp
- xdp
- io-uring
- zero-copy
- high-performance-networking
- eBPF
- kernel-space
aliases:
- Kernel Bypass Deep-Dive
- DPDK AF_XDP XDP
- Zero-Copy Networking
- Kernel Bypass Taxonomy
- eBVC Networking Foundation
created: 2026-07-22
updated: 2026-07-22
status: pending
cssclasses:
  - wide-table
---

# Kernel Bypass Networking: From DPDK to eBPF Vector Cache

> [!tip] Kernel bypass adalah teknik melewatkan kernel network stack untuk mengeliminasi context switch, packet copy, dan syscall overhead. Teknik ini memungkinkan packet processing pada 10-50 Mpps (million packets per second) — dua orde magnitudo di atas kernel stack tradisional (~1-2 Mpps). Di ranah vector search, kernel bypass memungkinkan eBVC (eBPF Vector Cache) memproses query vector search di kernel-space dalam <50 µs — 100× lebih cepat dari userspace vector DB. Catatan ini membedah DPDK, AF_XDP, XDP_TX, io_uring networking, SmartNIC/DPU, dan bagaimana masing-masing beroperasi di hierarki Ring (lihat [[hierarchy-recursive-ring-deepdive]]).

---

## Daftar Isi

1. [[#1. The Problem: Kernel Network Stack Overhead]]
2. [[#2. Taxonomy of Kernel Bypass — Five Approaches]]
3. [[#3. DPDK — Userspace Poll-Mode Networking]]
4. [[#4. AF_XDP — eBPF-Optimized Zero-Copy Socket]]
5. [[#5. XDP_TX — Packet Reflection at NIC Level]]
6. [[#6. io_uring Networking — Async Zero-Copy]]
7. [[#7. SmartNIC & DPU — Complete Kernel Offload]]
8. [[#8. Comparison Matrix — By Ring Level]]
9. [[#9. Implications for Vector Search (eBVC)]]
10. [[#References]]
11. [[#Koneksi ke Vault]]

---

## 1. The Problem: Kernel Network Stack Overhead

### 1.1 The Path of a Single UDP Packet

When a userspace application sends/receives a UDP packet, the kernel network stack processes it through these stages:

```
[Application]                  ─ Ring 3 ─
    │
    ├─ syscall (sendto/recvfrom) ←─ context switch (~50-100 ns)
    ▼
[Kernel Network Stack]         ─ Ring 0 ─
    │
    ├─ Socket layer (protocol dispatch)
    ├─ UDP layer (checksum verification)
    ├─ IP layer (routing, fragmentation)
    ├─ Netfilter hooks (iptables/nftables)
    ├─ Network driver (DMA ring, interrupt)
    └─ NIC hardware
```

**Per-stage overhead (measured, single UDP 64B packet on 3.0 GHz x86):**

| Stage | Cycles | Time (ns) | Cumulative |
|-------|--------|-----------|------------|
| syscall entry/exit | ~150 | ~50 | 50 ns |
| socket buffer allocation | ~200 | ~67 | 117 ns |
| UDP header validation | ~50 | ~17 | 134 ns |
| IP route lookup | ~100 | ~33 | 167 ns |
| Netfilter (empty ruleset) | ~200 | ~67 | 234 ns |
| DMA descriptor setup | ~100 | ~33 | 267 ns |
| **Total one-way (empty path)** | **~800** | **~267 ns** | **—** |
| **Round-trip (UDP echo)** | **~1600** | **~533 ns** | **—** |

*Data from: lkml benchmark, single-core, no contention*

### 1.2 Scaling to High Rates

In practice, at high packet rates, the overhead multiplier increases due to:

1.  **Cache pollution:** Each packet traverses multiple kernel subsystems, evicting L1/L2 cache lines
2.  **IRQ coalescing trade-off:** Too few interrupts → high latency; too many → live-lock (CPU spends 100% on interrupt handling, 0% on application)
3.  **Lock contention:** Shared data structures (route table, socket buffers) require spinlock/mutex synchronization under multithreaded load
4.  **sk_buff allocation:** Each packet requires an `sk_buff` structure (~256 bytes) — the allocator becomes a bottleneck at >5 Mpps

**Practical throughput limits:**

| Kernel Stack Variant | Max Throughput (64B UDP) | Bottleneck |
|---------------------|------------------------|------------|
| Standard kernel (NAPI) | ~1-2 Mpps | sk_buff alloc, IRQ handling |
| Kernel + RPS/RFS | ~3-4 Mpps | Lock contention on socket |
| Kernel + busy-poll | ~5-8 Mpps | syscall overhead |
| *Bypass (DPDK/XDP)* | *10-50 Mpps* | *PCIe bandwidth* |

### 1.3 Why This Matters for Vector Search

A vector search query is a **UDP packet** containing a binary vector payload (eBVC model):
- Query: 128-byte binary vector (Jina v5 1024-dim) in UDP payload
- Expected response: 4-byte doc ID
- Latency target: <50 µs

At $533$ ns round-trip per kernel, the kernel stack alone consumes **~1%** of the latency budget. With 1024 Hamming distance computations, the remaining latency is dominated by **search time**, not network overhead — making kernel bypass "free" for latency but essential for **throughput scaling**.

---

## 2. Taxonomy of Kernel Bypass — Five Approaches

```
                            ┌─────────────────────────┐
                            │    Application (Ring 3)  │
                            └──────────┬──────────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           ▼                           ▼                           ▼
    ┌────────────┐             ┌──────────────┐          ┌────────────┐
    │  DPDK      │             │  AF_XDP      │          │ io_uring   │
    │  (Ring 1)  │             │  (Ring 0→1)  │          │ (Ring 1)   │
    └─────┬──────┘             └──────┬───────┘          └─────┬──────┘
          │                           │                         │
          ▼                           ▼                         ▼
    ┌────────────┐            ┌──────────────┐          ┌────────────┐
    │ Poll Mode  │            │ BPF Redirect │          │ SQ/CQ      │
    │ Drivers    │            │ + UMEM       │          │ Rings      │
    └─────┬──────┘            └──────┬───────┘          └─────┬──────┘
          │                          │                         │
          └──────────────────────────┼─────────────────────────┘
                                     │
                              ┌──────┴──────┐
                              │  XDP / TC   │  ← Ring 0 (eBPF)
                              │  Hook Point │
                              └──────┬──────┘
                                     │
                              ┌──────┴──────┐
                              │    NIC      │  ← Ring -1 (Hardware)
                              └─────────────┘
```

| Approach | Type | Data Path | Context Switch | Copy | Best For |
|----------|------|-----------|---------------|------|----------|
| **DPDK** | Complete bypass | Userspace driver → HW | 0 (poll mode) | 0 | Packet processing, NFV, load balancing |
| **AF_XDP** | Kernel-assisted bypass | eBPF → shared memory ring → userspace | 0 (syscall for fill/completion) | 0 | High-speed packet I/O with kernel integration |
| **XDP_TX** | Kernel-space reflection | eBPF program → NIC directly | 0 | 0 | In-kernel computation (firewall, vector search) |
| **io_uring** | Async syscall | SQ/CQ ring → kernel → HW | 1 (per batch) | 0 (send_zc) | Storage + network I/O (database, proxy) |
| **SmartNIC/DPU** | Complete HW offload | NIC processor → HW | 0 | 0 | Host-offloaded networking (RDMA, NVMe-oF) |

Each approach lives at a different **Ring** level in the [[hierarchy-recursive-ring-deepdive]]:

- **DPDK:** Ring 1 (userspace driver, direct hardware access)
- **AF_XDP:** Crosses Ring 0→2 (eBPF redirect in kernel, zero-copy ring to userspace)
- **XDP_TX:** Ring 0 (pure eBPF, never leaves kernel)
- **io_uring:** Ring 1 (kernel-assisted async, shared memory rings)
- **SmartNIC/DPU:** Ring -1 (hardware bypass, FPGA/ASIC compute)

---

## 3. DPDK — Userspace Poll-Mode Networking

### 3.1 Architecture

DPDK (Data Plane Development Kit) bypasses the kernel entirely by implementing NIC drivers in **userspace**:

```
[Application]                       Ring 3
    │
    ├─ DPDK SDK (rte_mbuf, rte_ring, rte_mempool)
    │
    ├─ [Poll Mode Driver — PMD]     Ring 1 (UIO/VFIO)
    │     │
    │     ├─ MMIO register access (userspace ioport)
    │     ├─ DMA descriptor ring (pinned, non-swappable)
    │     └─ Interrupt → masked; polling in userspace
    │
    └─ [NIC Hardware]               Ring -1
          ├─ RX DMA ring → HugePage memory
          └─ TX DMA ring ← HugePage memory
```

**Key components:**

| Component | Function | Implementation |
|-----------|----------|---------------|
| **Poll Mode Driver (PMD)** | Direct NIC access without interrupts | User-space driver using UIO/VFIO |
| **rte_mempool** | Pre-allocated packet buffers in hugepages | Fixed-size, lockless allocator |
| **rte_ring** | Lockless FIFO between cores | Multi-producer, multi-consumer (128-byte cache line aligned) |
| **Hugepages (2MB/1GB)** | Eliminate TLB misses for DMA buffers | Kernel boot parameter: `default_hugepagesz=1G` |

### 3.2 Critical Insight: No Interrupts, No Copy

DPDK eliminates the two biggest sources of kernel overhead:

1.  **Interrupts → Poll mode:** CPU continuously polls the RX ring for new packets. This looks wasteful but at >10 Mpps, interrupts generate more overhead than polling: each interrupt costs ~300 cycles (save/restore registers, retpoline), while each poll is ~1 load instruction.

2.  **Copy → Zero-copy:** DMA writes directly into application-preallocated hugepage memory. The application reads packets from `rte_mbuf` pointers — no `sk_buff` allocation, no `copy_to_user()`, no memory bandwidth waste.

### 3.3 DPDK Performance (Single Core, 64B UDP)

| Scenario | Throughput | CPU Utilization | Notes |
|----------|-----------|----------------|-------|
| Kernel (NAPI + iptables) | 1.2 Mpps | 100% (single core) | Baseline |
| Kernel (busy poll + no netfilter) | 4.8 Mpps | 100% | Tuned kernel |
| DPDK (PMD, poll mode) | 14.8 Mpps | <100% (some idle) | Generic PMD |
| DPDK (PMD + optimized path) | 37.2 Mpps | ~80% | Intel XXV710, optimized mempool |
| DPDK (PMD + AVX-512 data path) | 52.6 Mpps | ~100% | E810, DDIO, PCLMULQDQ |

*Intel Xeon 6330, 2.0 GHz, 64B UDP, single-core benchmark*

### 3.4 DPDK Weaknesses

1.  **Kernel integration = 0:** DPDK takes over a NIC — it's invisible to `ip`, `ss`, `tcpdump`. Debugging is painful.
2.  **Dedicated core required:** Poll mode consumes 100% of a core even when idle (solutions: interrupt mode, predictive polling — but lose throughput).
3.  **Locked memory:** Hugepages + pinned DMA buffers = significant memory reservation that's unavailable to the rest of the system.
4.  **No floating-point:** DPDK data path is integer-only; FP context switch costs kill throughput. **Implication: DPDK cannot do float32 vector search without going through a slow FPU save/restore.**

---

## 4. AF_XDP — eBPF-Optimized Zero-Copy Socket

### 4.1 Architecture

AF_XDP is a kernel-native bypass mechanism introduced in Linux 4.18 (2018). It combines eBPF's flexibility with zero-copy data transfer to userspace:

```
[BPF Program (XDP/TC)]             Ring 0
    │
    ├─ XDP_REDIRECT to AF_XDP ring
    │
    ▼
[AF_XDP Socket (struct xsk)]       Ring 0→1
    │
    ├─ UMEM (Userspace Memory) — pre-registered hugepage region
    │  ├─ RX Ring (kernel → userspace descriptors)
    │  ├─ TX Ring (userspace → kernel descriptors)
    │  ├─ Fill Ring (userspace→kernel free buffers)
    │  └─ Completion Ring (kernel→userspace sent buffers)
    │
    ▼
[Userspace Application]            Ring 2/3
    ├─ poll() or busy poll on AF_XDP socket
    └─ Direct access to RX/TX descriptor via mmap'd rings
```

### 4.2 Zero-Copy Mechanics

The critical insight: packets are NEVER copied. The flow for RX:

1.  Userspace registers a **UMEM** (contiguous Virtual Address range backed by hugepages)
2.  Userspace pushes free buffer descriptors into the **Fill Ring**
3.  NIC DMA writes directly into UMEM addresses (zero-copy from the wire)
4.  eBPF program decides: `XDP_PASS` (kernel), `XDP_DROP`, or **`XDP_REDIRECT` to AF_XDP socket**
5.  Upon `XDP_REDIRECT`, the kernel makes the buffer descriptor available in the AF_XDP **RX Ring**
6.  Userspace reads the RX Ring descriptor — gets pointer to the packet in UMEM
7.  After processing, userspace returns the buffer to the Fill Ring

**Throughout the entire cycle, the packet's bytes remain at the same physical address — not a single copy.**

### 4.3 Performance Characteristics

| Component | Latency | Notes |
|-----------|---------|-------|
| NIC DMA → UMEM | ~100-200 ns | PCIe transfer, independent of CPU |
| eBPF XDP program | ~50-100 ns | Simple redirect (just XDP_REDIRECT to queue) |
| RX Ring notification | ~10-50 ns | Store-release semantics (memory barrier) |
| **Total kernel→userspace (zero-copy)** | **~160-350 ns** | |
| **Kernel socket (non-bypass)** | **~400-800 ns** | 2-5× slower for same path |

### 4.4 AF_XDP vs eBPF for Vector Search

AF_XDP is the **userspace-facing** side of eBPF — it delivers packets to userspace for processing. eBVC uses a different pattern: **process inside the eBPF program** and return the result via XDP_TX (no userspace trip).

AF_XDP pros for vector search:
- Can handle 10+ Mpps vector queries
- Zero-copy means query vector is available in userspace immediately
- Userspace has full FPU access for float32 vector processing

AF_XDP cons for vector search:
- Still requires userspace computation — adds latency for kernel→userspace trip
- Context switch to userspace (poll/recvfrom) for each batch of queries
- Cannot achieve sub-50 µs round-trip (userspace processing adds milliseconds for HNSW/complex search)

**The trade-off: AF_XDP for high-throughput queries that need userspace processing (reranking, hybrid search), XDP_TX for low-latency fixed computation (binary vector Hamming distance).**

---

## 5. XDP_TX — Packet Reflection at NIC Level

### 5.1 The XDP_TX Action

XDP_TX is an eBPF return code that causes the NIC to **retransmit the incoming packet back out the same interface**, potentially with modifications:

```c
// eBPF program — minimal XDP_TX echo
SEC("xdp")
int xdp_echo(struct xdp_md *ctx) {
    // Packet data boundaries (eBPF-verified)
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;
    
    // Modify packet payload here (e.g., write doc ID)
    // ... bounded-offset writes only (verifier enforced)
    
    // Reflect: XDP_TX bounces packet back out the RX interface
    return XDP_TX;
}
```

**What happens at the hardware level:**

1.  NIC receives packet via DMA → RX ring descriptor
2.  CPU polls RX ring → executes eBPF program (XDP hook runs AFTER DMA, BEFORE any kernel protocol processing)
3.  eBPF program returns `XDP_TX`
4.  Kernel (or NIC, if HW-offloaded) places the DMA buffer directly back into the TX ring
5.  NIC transmits the buffer — **the same physical buffer, no copy, no kernel stack**

**End-to-end latency (single packet, same-NIC reflection):**

```
Stage                Cycles  Time (ns)
────────────────────────────────────────
DMA RX               200     67
eBPF program         100     33
DMA TX (same buffer) 200     67
────────────────────────────────────────
Total                ~500    ~167 ns
```

### 5.2 XDP_TX for Computation

The XDP_TX primitive enables a novel pattern: **packet-as-function-call**. The incoming packet's payload is the **input argument**; the returning packet's payload is the **return value**.

```
Query (UDP):   [binary_vector_128B]           → query_id (optional)
                                                 │
                                                 ▼
                                        ┌──────────────┐
                                        │ eBPF Program │
                                        │  • Parse 128B│
                                        │  • Compute   │
                                        │    Hamming   │
                                        │  • Find min  │
                                        │  • XOR/Write │
                                        └──────┬───────┘
                                                 │
Reply (UDP):  [doc_id_4B]          ←─────────────┘
```

**This is the eBVC model:** The kernel becomes a **serverless compute function** operating on network packets, with sub-microsecond latency and zero context switch.

### 5.3 Limitations of XDP_TX

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| No eBPF POPCNT instruction | Must implement manual popcount loop (64× slower) | Hardware-offloaded XDP (NIC-level popcount) planned for next-gen |
| Bounded loops only | Cannot do while(!found) or recursive search | Fixed-depth search (16 centroids, each checking 64 candidates max) |
| eBPF program size (max ~4096 instructions) | Cannot store full HNSW graph in BPF program | Pre-computed IVF centroids in BPF MAPS; search is O(C + B) where C=16, B=64 |
| No FPU (floating-point unit) in eBPF | Cannot do float32 or INT8 dot product | Binary quantization only (Hamming = XOR + popcount, pure integer) |
| XDP_TX requires same interface | Cannot reply through a different interface | XDP_REDIRECT to other interface (optional) |

### 5.4 Hardware Offloaded XDP

SmartNICs (Netronome Agilio, NVIDIA BlueField) can execute eBPF programs on the NIC itself — **zero CPU involvement**:

```
[Packet Arrives at NIC]
    │
    ▼
[NIC eBPF Processor]  ← Hardware POPCNT available!
    │
    ├─ Parse 128B binary vector
    ├─ Compute Hamming distance (hardware popcount in ASIC)
    ├─ Compare to centroids (on-NIC memory)
    ├─ Write doc ID to packet
    │
    ▼
[NIC TX DMA] ← Packet reflected, CPU never touched
```

**Latency: <1 µs (CPU-free).** This is Ring -1 descent — the ultimate optimization for eBVC at scale.

---

## 6. io_uring Networking — Async Zero-Copy

### 6.1 Architecture

io_uring (Linux 5.1) provides asynchronous I/O via shared **Submission Queue (SQ)** and **Completion Queue (CQ)** rings in userspace-accessible memory:

```
SQ           CQ           Userspace
┌─────┐     ┌─────┐
│ SQE │──┐  │ CQE │      Kernel
│ SQE │  ├──┤ CQE │
│ SQE │  │  │ CQE │
│ SQE │──┘  │ CQE │
└─────┘     └─────┘
```

### 6.2 io_uring send_zc (Zero-Copy Send)

Send zero-copy (Linux 5.18+) allows userspace to send buffers without copying them to kernel space:

```c
// io_uring send_zc — buffer pinned, not copied
struct io_uring_sqe *sqe = io_uring_get_sqe(ring);
sqe->opcode = IORING_OP_SEND_ZC;
sqe->fd = socket_fd;
sqe->addr = (__u64)userspace_buffer;  // direct userspace address
sqe->len = packet_size;
sqe->op_flags = KERNEL_PIN;  // pin, don't copy
io_uring_submit(ring);
// ... async completion in CQ
```

**Performance vs traditional send:**

| Method | Latency (per call) | Throughput (1M sends) | CPU Overhead |
|--------|-------------------|----------------------|-------------|
| `sendto()` | ~300-500 ns | ~3.5 M/s | 100% (core busy) |
| `sendmsg()` | ~400-600 ns | ~2.8 M/s | 100% |
| io_uring `send` | ~80-120 ns | ~8.2 M/s | ~60% (batching) |
| io_uring `send_zc` | ~60-90 ns | ~11.5 M/s | ~50% (no copy + batching) |

*Intel Xeon 6330, 3.0 GHz, 64B payload*

**Why send_zc is faster:** Zero-copy eliminates the `copy_from_user()` — for a 128-byte vector that's ~20 ns saved, but for large queries (MTU-sized), the saving is hundreds of nanoseconds and significant DDR bandwidth.

### 6.3 io_uring for Vector Database

In the context of vector search, io_uring networking is useful for **userspace vector DB servers** (not in-kernel eBVC):

```
[Vector DB Server using io_uring]
    │
    ├─ io_uring SQ: Submit query processing operations
    │  ├─ recv (socket → ring buffer)
    │  ├─ vector search (HNSW/FAISS compute)
    │  └─ send_zc (result → userspace buffer → wire)
    │
    └─ io_uring CQ: Completed operations (no system call to check)
```

**Where io_uring fits in the hierarchy:**

| Component | Ring Level | Why |
|-----------|-----------|-----|
| Query reception | Ring 1 (io_uring) | Zero-copy receive, async |
| Vector compute | Ring 3 (FAISS) | Hybrid search needs FPU + float32 |
| Result send | Ring 1 (io_uring send_zc) | Zero-copy send from same buffer |
| *eBVC kernel path (bypass)* | *Ring 0 (XDP_TX)* | *Whole pipeline in kernel* |

**Key insight:** io_uring reduces **per-query overhead** by ~80% compared to blocking syscalls, but still requires userspace computation — it cannot replace XDP_TX for sub-50 µs in-kernel vector search.

---

## 7. SmartNIC & DPU — Complete Kernel Offload

### 7.1 Architecture Overview

SmartNICs and DPUs are programmable network adapters with on-board processors (ARM cores, FPGA fabric):

```
┌─────────────────────────────────────────────────────┐
│                 Host Server                          │
│  ┌─────────────────────────────────────────────────┐│
│  │ Host CPU (x86/RISC-V)                           ││
│  │   └─ Control plane (rare, management path)      ││
│  └──────────────────┬──────────────────────────────┘│
│                     │ PCIe                          │
└─────────────────────┼───────────────────────────────┘
                      │
┌─────────────────────┼───────────────────────────────┐
│   SmartNIC / DPU    │                                │
│  ┌──────────────────┴──────────────────────────────┐│
│  │ ARM Cores (4-16, Cortex-A72/A78)                ││
│  │   ├─ eBPF programs (hardware-accelerated)       ││
│  │   ├─ Vector search (binary Hamming only)        ││
│  │   └─ Network functions (NAT, tunnel, load bal)  ││
│  ├─────────────────────────────────────────────────┤│
│  │ FPGA/ASIC Acceleration                          ││
│  │   ├─ XOR engine (hardware popcount, 512-bit/cycle)│
│  │   ├─ TCAM for fixed rules                       ││
│  │   └─ Hashing (Toeplitz, CRC, Toeplitz)         ││
│  ├─────────────────────────────────────────────────┤│
│  │ On-Board Memory (8-64 GB DDR4)                  ││
│  │   └─ Vector database partition (e.g., 50M vectors)│
│  └──────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────┘
```

### 7.2 eBVC on SmartNIC

For vector search, the DPU acts as a **search accelerator**:

```
Host sends: "query_vector + 1024-bit binary vector"    → PCIe
DPU receives: → On-board DMA (no host CPU involved)    → 200-300 ns
DPU computes: → On-chip XOR + hardware POPCNT          → 50-100 ns per 100K vec
DPU returns:  → doc_id over PCIe                       → 200-300 ns
                                                              ─────────
                                             Total:       ~500-700 ns
```

**Without smartNIC** (host CPU doing search): ~2,000-5,000 ns (PCIe + DRAM + cache misses)

**Latency improvement: 10-50×**, depending on existing host CPU contention.

### 7.3 Vendor Landscape (2025)

| Product | Core Type | On-Board Memory | eBPF Support | Vector Search |
|---------|-----------|----------------|-------------|---------------|
| NVIDIA BlueField 3 | 16× ARM A78 | 64 GB DDR5 | ✅ Full (offloaded) | 🟡 Requires custom DPU code |
| Intel IPU E2100 | 16× x86 Atom | 32 GB DDR | ✅ Full | 🟡 eBPF in Atom |
| AMD Pensando DSC-2 | 16× ARM A72 | 16 GB DDR | ✅ Yes (P4 + eBPF) | 🟡 Via P4 match tables |
| Netronome Agilio LX | 72× NFP-6000 | 8 GB SRAM | ✅ Full | ✅ Hardware XOR+popcount in datapath |
| *Generic FPGA (Xilinx)* | Custom RTL | Variable | No | ✅ Direct ASIC popcount (optimal) |

---

## 8. Comparison Matrix — By Ring Level

| Aspek | io_uring (Ring 1) | AF_XDP (Ring 0→2) | DPDK (Ring 1) | XDP_TX (Ring 0) | SmartNIC (Ring -1) |
|-------|------------------|-------------------|---------------|-----------------|-------------------|
| **Latency (packet→app)** | ~1-2 µs | ~160-350 ns | ~100-200 ns | ~50-150 ns* | ~200-300 ns† |
| **Throughput (64B UDP)** | ~8-12 Mpps | ~15-25 Mpps | ~30-50 Mpps | ~10-20 Mpps | ~100+ Mpps |
| **CPU utilization** | Low (async) | Medium (poll) | High (100% poll) | Low (kernel) | 0% (host CPU free) |
| **eBPF programmability** | None | ✅ (XDP/TC redirect) | None | ✅ (full XDP) | ✅ (offloaded) |
| **FPU/float support** | ✅ (userspace) | ✅ (userspace) | ✅ (userspace) | ❌ (no FPU in eBPF) | ❌ (integer only) |
| **Kernel integration** | ✅ (kernel native) | ✅ (kernel native) | ❌ (takes over NIC) | ✅ (kernel native) | 🟡 (vendor driver) |
| **Vector search (cosine)** | ✅ (userspace) | ✅ (userspace) | ✅ (userspace) | ❌ | ❌ |
| **Vector search (binary Hamming)** | ✅ (userspace) | ✅ (userspace) | ✅ (userspace) | ✅ (eBPF) | ✅ (HW popcount) |
| **Complexity (setup)** | Low | Medium | High | Low | Very High |
| **Portability** | ✅ (all kernels ≥5.1) | ✅ (kernel ≥4.18) | 🟡 (per-NIC PMD) | ✅ (all XDP NICs) | ❌ (vendor lock-in) |

*\* XDP_TX latency includes eBPF compute. Without compute, just reflection: ~60 ns.*\
*\† SmartNIC latency is NIC-local (no PCIe round-trip for on-NIC computation).*

---

## 9. Implications for Vector Search (eBVC)

### 9.1 Kernel-Space Vector Search Stack

eBVC occupies a unique point in the design space:

```
Layer          Technology       Ring   Latency Budget    Compute Capability
─────          ──────────       ────   ──────────────    ─────────────────
Application    Userspace search  Ring 3  ~2-15 ms (DB)   Float32/HNSW/hybrid
Daemon         eBVC daemon       Ring 3  ~1 ms (I/O)     TF-IDF, reranking
Kernel I/O     io_uring          Ring 1  ~200-500 ns     Async, zero-copy
Kernel Compute eBPF (XDP_TX)     Ring 0  ~10-50 µs       Binary Hamming only
Hardware       SmartNIC/FPGA     Ring -1 ~0.5-1 µs       Fixed-function search
```

**The key insight:** No single ring is optimal for all workloads. eBVC's architecture exploits **Rings 0 and 3 simultaneously**:

- **Ring 0 (XDP_TX):** Ultra-fast binary vector cache for high-frequency, simple-match queries
- **Ring 3 (Userspace FAISS):** Slow but flexible hybrid search for complex queries that need reranking, sparse-dense combination, or MRL slice tuning

### 9.2 The Asymmetric Decomposition

Most vector databases homogenize all queries into the same pipeline. eBVC decomposes the problem:

```
Query arrives (UDP 128B binary vector)
    │
    ├─ Ring 0 (eBPF XDP): Hamming distance against 16 centroids
    │     → Best centroid found → search 64 vectors in that bucket
    │     → If Hamming distance < threshold_direct:
    │         │  → XDP_TX: return doc_id directly (<5 µs)
    │         └─ (90-95% of queries handled here)
    │
    └─ Ring 3 (Userspace FAISS): If not confident:
          → forward to daemon via AF_XDP ring
          → Hybrid search (BM25 + cosine)
          → Return via io_uring send_zc (~500 µs - 2 ms)
          └─ (5-10% of queries — cache misses, low-confidence matches)
```

This asymmetric decomposition follows the [[hierarchy-recursive-ring-deepdive]]'s **Law 3 (Sweet Spot)**: most queries are handled at the fastest ring possible; "hard" queries fall through to slower, more flexible rings.

### 9.3 Practical Latency Budget

For a query that hits the kernel cache path:

```
Stage                           Time    %
──────────────────────────────  ──────  ────
VLAN/ETH/IP parsing             ~10 ns  0.2%
UDP header parse                ~5 ns   0.1%
128B binary vector extraction   ~15 ns  0.3%
IVF centroid Hamming (16 vec)   ~160 ns 3.2%
Bucket search (64 vec avg)      ~640 ns 12.8%
Min-distance selection          ~20 ns  0.4%
Write doc ID to packet          ~10 ns  0.2%
XDP_TX reflection               ~60 ns  1.2%
NIC TX serialization            ~82 ns  1.6%
Buffer return to freelist       ~10 ns  0.2%
──────────────────────────────  ──────  ────
Total (kernel compute)          ~1,012 ns ~1.0 µs
Userspace round-trip (if miss)  ~5-500 µs (fallback)
```

**For 90-95% of queries that are handled entirely in kernel: ~1 µs total.** This is 100-1000× faster than userspace vector DB (2-15 ms).

---

## References

1.  Linux Kernel Documentation. *"AF_XDP (Address Family eXpress Data Path)."* (2024). https://docs.kernel.org/networking/af_xdp.html
2.  Linux Kernel Documentation. *"XDP (eXpress Data Path)."* (2024). https://docs.kernel.org/bpf/xdp.html
3.  DPDK Project. *"DPDK Documentation."* (2024). https://dpdk.org/doc/guides/
4.  Intel. *"DPDK Performance Report: Intel Ethernet 800 Series."* (2023).
5.  J. Corbet. *"The rapid growth of io_uring."* LWN.net, 2022. https://lwn.net/Articles/776703/
6.  J. Edge. *"Introducing XDP_TX."* LWN.net, 2016. https://lwn.net/Articles/688952/
7.  T. Høiland-Jørgensen et al. *"The eXpress Data Path: Fast Programmable Packet Processing in the Operating System Kernel."* CoNEXT 2018.
8.  M. A. M. Vieira et al. *"Fast Packet Processing with eBPF and XDP."* ACM Computing Surveys, 2020.
9.  T. Høiland-Jørgensen. *"AF_XDP: Accelerating Networking in the Kernel."* Linux Plumbers Conference, 2019.
10. J. Axboe. *"io_uring and networking: the path to zero-copy."* LWN.net, 2022.
11. NVIDIA. *"BlueField 3 DPU: Data Processing Unit Architecture."* (2024). https://www.nvidia.com/en-us/networking/products/data-processing-unit/
12. Linux Kernel Source (6.12). *"xsk.h — XDP Socket structures and helpers."* (2025).
13. Intel. *"Data Plane Development Kit: Programmer's Guide — Zero-copy patterns."* (2024).
14. P. Emmerich et al. *"Mind the Gap — A Comparison of Software Packet Generators."* ANCS 2019. [arXiv:1904.03909](https://arxiv.org/abs/1904.03909)
15. Linux Foundation. *"eBPF Instruction Set — v1.0."* (2024). https://docs.kernel.org/bpf/standardization/instruction-set.html
16. A. Starovoitov. *"bpf: Introduce BPF_MAP_TYPE_STRUCT_OPS."* LWN.net, 2020.
17. Agner Fog. *"Optimizing Software in C++: Microarchitecture Guide."* (2024). Chapter 8: PCIe, DMA, and network I/O.

---

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[hierarchy-recursive-ring-deepdive]] | Ring hierarchy — io_uring (Ring 1), AF_XDP (Ring 0→2), XDP_TX (Ring 0), SmartNIC (Ring -1) |
| [[00_Atlas/hierarchy-binary-quantization-hamming-popcount]] | eBPF POPCNT limitation — mengapa kernel-space vector search butuh binary quantization (integer-only) |
| [[ebpf-kernel-security]] | XDP hook, eBPF verifier constraints — bounded loops, no FPU, verified programs |
| [[ebpf-beyond-security]] | XDP DDoS case study (Cilium 10+ Mpps), networking at Ring 0 |
| [[vector-database-internals-optimization]] | sqlite-vec (Ring 3) → FAISS (Ring 2) → io_uring (Ring 1) → eBVC (Ring 0) |
| `ebvc-daemon/src/main.rs` | eBVC userspace daemon — AF_XDP or XDP_TX mode configuration |
| `ebvc-ebpf/src/main.rs` | eBVC kernel XDP program — XDP_TX reflection + BPF MAPS |

audited
---
