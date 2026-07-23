---
tags:
  - hierarchy
  - cross-cutting
  - concurrency
  - consensus
  - distributed-systems
  - parallelism
aliases:
  - Concurrency and Consensus Hierarchy
  - Parallelism Model Map
  - From Thread to Paxos
  - Concurrency Abstraction Stack
status: seedling
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🔄 Concurrency & Consensus Hierarchy — Dari Thread ke Distributed Agreement

> [!tip] Concurrency bukan hanya tentang multi-threading — ia adalah **6 lapisan model** dari thread di OS hingga consensus global di blockchain. Catatan ini memetakan evolusi model concurrency (multiprocessing, multithreading, async/await, actor, consensus protocol) dengan trade-off matrix, failure mode (deadlock, race, byzantine), dan analogi lintas domain.

---

## Daftar Isi

1. [[#1. Premise — Concurrency Adalah Norma, Bukan Fitur]]
2. [[#2. Six-Layer Concurrency Hierarchy]]
3. [[#3. Layer C0 — Physical Parallelism]]
4. [[#4. Layer C1 — Process/Thread]]
5. [[#5. Layer C2 — Lock-Based Synchronization]]
6. [[#6. Layer C3 — Lock-Free & Wait-Free]]
7. [[#7. Layer C4 — Async/Await & Event Loop]]
8. [[#8. Layer C5 — Actor Model]]

---

## 1. Premise — Concurrency Adalah Norma, Bukan Fitur

CPUs tidak menjadi lebih cepat (clock speed plateau ~5 GHz sejak 2010). Mereka menjadi lebih banyak (multi-core). Jika kode tidak concurrent, ia hanya menggunakan 1/N core.

**Hukum:**

- Amdahl: Speedup = 1 / (1 - P + P/N) — diminishing return
- Gustafson: scaled speedup = N + (1 - N) × s — better scaling dengan problem size

**Klasifikasi concurrency:**

```
┌──────────────┬─────────────────────┐────────────────────────┐
│              │ Single instruction  │ Multiple instruction   │
├──────────────┼─────────────────────┼────────────────────────┤
│ Single data  │ SISD (serial)       │ MISD (redundant)       │
│ Multiple dat │ SIMD (vector)       │ MIMD (multi-core)      │
└──────────────┴─────────────────────┴────────────────────────┘
```

---

## 2. Six-Layer Concurrency Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ C5 │ Consensus Protocol (Paxos, Raft, BFT)                 │ ← global agreement
├────────────────────────────────────────────────────────────┤
│ C4 │ Actor Model (Erlang, Akka, Orleans)                   │
├────────────────────────────────────────────────────────────┤
│ C3 │ Async/Await & Event Loop (JS, Rust, Python asyncio)   │
├────────────────────────────────────────────────────────────┤
│ C2 │ Lock-Free & Wait-Free (atomic, CAS)                   │
├────────────────────────────────────────────────────────────┤
│ C1 │ Lock-Based (mutex, semaphore, RWLock)                 │
├────────────────────────────────────────────────────────────┤
│ C0 │ Process/Thread (OS-level parallelism)                 │ ← hardware
└────────────────────────────────────────────────────────────┘
```

---

## 3. Layer C0 — Physical Parallelism & OS Thread

#### Hardware Context

| Platform         | Threads/Time | Model                                     |
| ---------------- | :----------: | ----------------------------------------- |
| Single-core      |      1       | Time-sharing                              |
| Multi-core (2-8) |     2-8      | Symmetric multiprocessing (SMP)           |
| Many-core (8-64) |     8-64     | Non-uniform memory access (NUMA)          |
| GPU (CUDA)       |     10K+     | SIMT (Single Instruction Multiple Thread) |
| Array (SIMD)     | 256/512 bits | Vectorized instructions (AVX-512)         |

#### Kernel vs User Threads

| Model            | Description                         | Example                         |
| ---------------- | ----------------------------------- | ------------------------------- |
| 1:1 (kernel)     | Every user thread → kernel thread   | Linux pthreads, Windows         |
| N:1 (user-space) | Many user threads → 1 kernel thread | Green threads (old Java)        |
| M:N (hybrid)     | M user → N kernel                   | Go goroutines, Erlang processes |

---

## 4. Layer C1 — Lock-Based Synchronization

#### Primitives

| Primitive          | Semantics             | Typical Uses             |
| ------------------ | --------------------- | ------------------------ |
| Mutex              | Mutual exclusion      | Protect critical section |
| Semaphore          | Counted signaling     | Resource pool            |
| RWLock             | Readers–writer        | Read-heavy workloads     |
| Condition Variable | Block until predicate | Producer–consumer        |
| Barrier            | Wait for N threads    | Parallel phase           |

#### Deadlock Prevention

Four necessary conditions (Coffman, 1971):

1. Mutual exclusion
2. Hold and wait
3. No preemption
4. Circular wait

Break any one to prevent. Practical approach: lock ordering (hierarchical locking).

---

## 5. Layer C2 — Lock-Free & Wait-Free

| Level            | Guarantee                                 | Technique                |
| ---------------- | ----------------------------------------- | ------------------------ |
| Obstruction-free | Guaranteed to complete if no contention   | CAS loop                 |
| Lock-free        | System makes progress even if thread dies | CAS + retry              |
| Wait-free        | Every thread completes in bounded steps   | Read, copy, update (RCU) |

#### Hardware Atomics

| Operation                             | Example                                |
| ------------------------------------- | -------------------------------------- |
| CAS (Compare-And-Swap)                | `cmpxchg` (x86), `LDREX`/`STREX` (ARM) |
| FAA (Fetch-And-Add)                   | `lock xadd` (x86)                      |
| LL/SC (Load-Linked/Store-Conditional) | ARM, PowerPC                           |
| Transactional Memory                  | Intel TSX (buggy), HTM in POWER8+      |

---

## 6. Layer C3 — Async/Await & Event Loop

```
┌──────────────────────────────────────────────┐
│ Application Code                             │
│   async fn fetch_data(url) → Result<Data>    │
│       await http::get(url)                   │
├──────────────────────────────────────────────┤
│ Runtime (Executor)                           │
│   ├─ Event loop (epoll/kqueue/IOCP)          │
│   ├─ Task scheduler (work-stealing)          │
│   └─ Timer wheel (timeout, delay)            │
├──────────────────────────────────────────────┤
│ OS (I/O multiplexing)                        │
│   └─ epoll (Linux), kqueue (macOS),          │
│      IOCP (Windows), io_uring (Linux 5.1+)   │
└──────────────────────────────────────────────┘
```

#### Runtime Comparison

| Runtime         | Language   | Model                      | Throughput  |
| --------------- | ---------- | -------------------------- | :---------: |
| Node.js (libuv) | JavaScript | Single-threaded event loop |  50K req/s  |
| asyncio         | Python     | Event loop + thread pool   |  10K req/s  |
| Tokio           | Rust       | Work-stealing multi-thread | 100K+ req/s |
| Zio             | Scala      | Fiber-based                | 200K+ req/s |

---

## 7. Layer C4 — Actor Model

| Feature                   | Description                                |
| ------------------------- | ------------------------------------------ |
| **Actor**                 | Primitive unit: state + behavior + mailbox |
| **Communicate**           | Only via asynchronous messages             |
| **Create**                | Spawn new actors                           |
| **Supervision**           | Parent monitors children                   |
| **Location Transparency** | Actors can be local or remote              |

#### Platforms

| Platform             | Language       | Key Features                                               |
| -------------------- | -------------- | ---------------------------------------------------------- |
| BEAM (Erlang/Elixir) | Erlang, Elixir | Per-actor heap, preemptive scheduler                       |
| Akka                 | Scala/Java     | JVM-based, typed actors                                    |
| Orleans              | C#             | Virtual actors (grains)                                    |
| Pony                 | Pony           | Reference capability system (no data race by compile time) |
| Proto.Actor          | .NET, Go       | Multi-language actor framework                             |

---

## 8. Layer C5 — Consensus Protocol

| Protocol            |    Fault Tolerance    |  Performance   | Use Case                                          |
| ------------------- | :-------------------: | :------------: | ------------------------------------------------- |
| 2PC                 | Crash (non-Byzantine) |      Low       | Distributed transaction                           |
| Paxos               |     Crash (N/2+1)     |      High      | State machine replication (Google Spanner, Kafka) |
| Raft                |     Crash (N/2+1)     | High (simpler) | etcd, Consul, TiKV                                |
| PBFT                |   Byzantine (N/3+1)   | Medium (O(n²)) | Blockchain, Hyperledger                           |
| HotStuff            |   Byzantine (N/3+1)   |  High (O(n))   | Diem/Libra                                        |
| Snowman (Avalanche) |       Byzantine       |      High      | Avalanche subnet                                  |
| Tendermint          |   Byzantine (N/3+1)   |     Medium     | Cosmos chain                                      |

---

## 9. Trade-off Matrix

|     Layer      | Complexity |         Scaling         |    Failure Model    | Typical Latency |
| :------------: | :--------: | :---------------------: | :-----------------: | :-------------: |
|  C0 (Thread)   |    Low     |       Core count        |    Process crash    |     Sub-µs      |
|   C1 (Lock)    |   Medium   | Degrade with contention |      Deadlock       |       µs        |
| C2 (Lock-Free) |    High    |          Good           |     Starvation      |      ns-µs      |
|   C3 (Async)   |   Medium   |     10K-100K tasks      |   Runtime failure   |      µs-ms      |
|   C4 (Actor)   |    High    |   1M+ actors per node   | Supervisor restart  |      µs-ms      |
| C5 (Consensus) | Very high  |      Network bound      | Partition tolerance |      ms-s       |

---

## 10. Analogi Lintas Domain

| Layer | Analogi Kimia                              | Analogi Hukum                                     |
| :---: | ------------------------------------------ | ------------------------------------------------- |
|  C0   | Reaksi paralel                             | Sidang majelis hakim (3 hakim concurrent)         |
|  C1   | Katalisator (locks onto substrate)         | Eksklusivitas paten                               |
|  C2   | Katalis enzim tanpa inhibitor              | Self-executing treaty                             |
|  C3   | Katalis heterogen (menunggu permukaan)     | Sidang adjourn (menunggu saksi)                   |
|  C4   | Sel biologi independen (komunikasi sinyal) | Otonomi daerah (message = regulation)             |
|  C5   | Reaksi rantai (chain reaction)             | Pengadilan internasional (consensus antar negara) |

---

## 11. Cross-Reference ke Vault

|   Layer   | Catatan Vault Terkait                                           |
| :-------: | --------------------------------------------------------------- |
|  **C0**   | [[hierarchy-operating-systems]] — Process scheduling            |
| **C1-C2** | [[hierarchy-programming-language]] — Language concurrency       |
|  **C3**   | [[hierarchy-kernel-bypass-networking]] — io_uring async pattern |
|  **C4**   | [[hierarchy-llm-ai-systems]] — Agent orchestration              |
|  **C5**   | [[hierarchy-database-storage-systems]] — Consensus in DB        |
|  **All**  | [[hierarchy-abstraction-layers]] — Foundation layers            |

---

## References

1. Herlihy, M. & Shavit, N. _"The Art of Multiprocessor Programming."_ Morgan Kaufmann, 2012.
2. Goetz, B. et al. _"Java Concurrency in Practice."_ Addison-Wesley, 2006.
3. Hewitt, C. et al. _"A Universal Modular ACTOR Formalism for Artificial Intelligence."_ 1973.
4. Armstrong, J. _"Programming Erlang."_ Pragmatic Bookshelf, 2007.
5. Lamport, L. _"Time, Clocks, and the Ordering of Events in a Distributed System."_ CACM 1978.
6. Lamport, L. _"The Part-Time Parliament (Paxos)."_ ACM TOCS 1998.
7. Ongaro, D. & Ousterhout, J. _"In Search of an Understandable Consensus Algorithm (Raft)."_ USENIX 2014.
8. Castro, M. & Liskov, B. _"Practical Byzantine Fault Tolerance."_ OSDI 1999.
9. Hoare, C.A.R. _"Communicating Sequential Processes (CSP)."_ 1978.
10. Wait, D. _"lock-free linked lists."_ 2003.
11. McKenney, P. _"RCU (Read-Copy-Update)."_ Linux Foundation.
