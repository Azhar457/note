---
title: "Distributed Systems — CAP, Consensus, Replication & Fault Tolerance"
tags:
  - distributed-systems
  - consensus
  - cap-theorem
  - fault-tolerance
  - library
aliases:
  - "distributed-systems-deepdive"
  - "ds-consensus-protocols"
  - "cap-theory-guide"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
cssclasses:
  - wide-table
---

# 🌐 Distributed Systems — CAP, Consensus, Replication & Fault Tolerance

> Vault udah punya catatan [[system-design]], [[cloud-infrastructure]], dan [[ddia-kleppmann]] yang nyentuh distributed systems dari sisi arsitektur dan aplikasi. Tapi belum ada yang bedah **fondasi teoritis** di baliknya: kenapa CAP theorem itu bukan trilemma beneran, bagaimana Raft dan Paxos bikin node sepakat dalam jaringan yang gak bisa dipercaya, apa beda gossip protocol sama SWIM, dan gimana Cassandra/etcd/Spanner menerjemahkan teori ke implementasi. Catatan ini mengisi celah itu — dari formal model sampai mekanisme nyata yang jalan di production.

> [!info] Posisi di Vault
> Catatan ini adalah **foundation layer** yang menghubungkan [[database-internals-indexing-mvcc]] (replication & partitioning theory), [[ddia-kleppmann]] (DDIA Part II — distributed data), [[system-design]] (arsitektur skala besar), [[cloud-infrastructure]] (infra distribusi), dan [[api-protocols-deepdive]] (gRPC/RPC untuk komunikasi antar node).

---

## Daftar Isi

- [[#1. Definisi & Karakteristik Distributed System]]
- [[#2. CAP Theorem — Bukti, Mitos, Trade-off Nyata]]
- [[#3. Consistency Models — Kapan Pake Yang Mana]]
- [[#4. Consensus Protocols — Paxos, Raft, Zab, VR]]
- [[#5. Clock & Ordering — Lamport, Vector Clock, TrueTime]]
- [[#6. Replication Patterns — Leader, Multi-Leader, Leaderless]]
- [[#7. Sharding & Partitioning — Consistent Hashing, Rebalancing]]
- [[#8. Distributed Transactions — 2PC, 3PC, Saga]]
- [[#9. Failure Detection — Gossip, SWIM, Phi-Accrual]]
- [[#10. Distributed Observability — Tracing, Logging, Metrics]]
- 🔗 Koneksi ke Catatan Lain
- ✅ Checklist
- Roadmap Belajar

---

## 1. Definisi & Karakteristik Distributed System

Distributed system adalah kumpulan komputer independen yang tampak sebagai satu sistem tunggal bagi pengguna. Definisi ini dari Tanenbaum, dan intinya ada dua kata kunci: **independen** (setiap node punya memory sendiri) dan **tampak satu** (abstraksi menyembunyikan kompleksitas).

### Karakteristik yang Membuat Distributed System Susah

| Karakteristik | Deskripsi | Implikasi |
|:-------------|-----------|-----------|
| **Partial failure** | Sebagian node bisa mati sementara yang lain hidup | Sistem harus detect + recover tanpa block total |
| **Network partition** | Jaringan terputus antara dua grup node | Pilihan: tetap serve (risiko inkonsistensi) atau stop (risiko unavailable) |
| **Clock skew** | Setiap node punya jam sendiri yang drift | Urutan event jadi ambigu — butuh logical clock |
| **No shared memory** | Komunikasi via message passing saja | Latensi, packet loss, duplikasi, reordering |
| **Concurrency** | Multiple node akses state yang sama | Race condition, deadlock, starvation |
| **Non-determinism** | Urutan eksekusi gak bisa diprediksi | Testing jadi sulit — butuh fault injection (Chaos Engineering) |

### Fallacies of Distributed Computing (L. Peter Deutsch)

Delapan asumsi yang salah kaprah:

```
1. Jaringan itu reliable           ❌ — Packet loss, latency spike, partition
2. Latensi itu nol                 ❌ — Cross-datacenter bisa 100ms+
3. Bandwidth itu tak terbatas      ❌ — Serialization bottleneck
4. Jaringan itu aman               ❌ — Man-in-the-middle, eavesdrop
5. Topologi jaringan gak berubah   ❌ — Node naik/turun, routing berubah
6. Hanya ada satu administrator    ❌ — Multi-tenant, multi-team
7. Transport cost itu nol          ❌ — Serialization/deserialization mahal
8. Jaringan itu homogen            ❌ — OS, version, library berbeda
```

**Ponytail:** Fallacies ini bukan sekadar teori — lo bakal nemu tiap fallacy sebagai incident di production. Chaos Engineering lahir dari sini.

---

## 2. CAP Theorem — Bukti, Mitos, Trade-off Nyata

### 2.1 Definisi Formal

CAP theorem (Brewer, 2000 — dibuktikan Gilbert & Lynch, 2002) menyatakan bahwa dalam sistem terdistribusi, hanya dua dari tiga properti berikut yang bisa dipenuhi secara simultan saat terjadi **network partition**:

| Properti | Definisi |
|:---------|----------|
| **C**onsistency | Semua node melihat data yang sama pada waktu bersamaan (linearizability) |
| **A**vailability | Setiap request yang sampai ke node non-gagal mendapat response (bukan error/timeout) |
| **P**artition tolerance | Sistem tetap berfungsi meskipun message antar node hilang/delay |

### 2.2 Bukti Informal

```
Anggap ada 2 node (N1, N2) dengan value awal v=0.
Terjadi partition — message dari N1 ke N2 hilang.

Client tulis v=1 ke N1.
Client baca dari N2.

       ┌─────┐         partition         ┌─────┐
       │ N1  │ ←───────────────────────── │ N2  │
       │v=1  │                            │v=0  │
       └─────┘                            └─────┘

Pilihan:
- Kalau N2 return v=0 → konsisten (tapi N2 harus stop serve = gak available)
- Kalau N2 tetap respon → available (tapi data basi = gak konsisten)
```

### 2.3 Mitos CAP

**Mitos 1: CAP adalah trilemma — pilih 2 dari 3.**
Fakta: CAP cuma relevan **saat partition terjadi**. 99.9% waktu sistem bisa CP + CA penuh. Trade-off cuma aktif selama partition — sisanya sistem menjalankan consistency model normal.

**Mitos 2: "CP system mengorbankan availability."**
Fakta: Saat gak ada partition, CP system tetap available penuh. Saat partition, CP memilih konsistensi dengan **menahan response dari sisi yang terisolasi**.

**Mitos 3: Konsistensi = konsistensi kuat = linearizability.**
Fakta: Ada gradasi — eventual, causal, read-after-write, monotonic read. CAP cuma bicara tentang linearizability (consistency kuat), bukan model lainnya.

### 2.4 PACELC — Perbaikan CAP

PACELC (Abadi, 2012) memperbaiki CAP dengan menambahkan dimensi **saat tidak ada partition**:

```
         ┌── Partition terjadi? ──┐
         │                        │
        YES                       NO
         │                        │
    P + A/C                   E + L/C
         │                        │
    Trade-off:              Trade-off:
    Availability vs         Latency vs
    Consistency             Consistency
```

**Contoh PACELC di sistem nyata:**

| Sistem | Saat Partition | Saat Normal |
|--------|---------------|-------------|
| Cassandra | PA (available, eventual) | EL (low latency, eventual) |
| MongoDB | PC (consistency > availability) | EC (strong consistency, higher latency) |
| DynamoDB | PA | EL |
| Spanner | PC | EC (dengan TrueTime) |

---

## 3. Consistency Models — Kapan Pake Yang Mana

### 3.1 Hierarchy Model

```
                    Strong Consistency (Linearizability)
                               │
                    Sequential Consistency
                               │
                    Causal Consistency
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
   Read-After-Write     Monotonic Read     Monotonic Write
          │                    │                    │
                    Eventual Consistency
```

### 3.2 Setiap Model Dijelaskan

| Model | Jaminan | Performa | Contoh Sistem |
|-------|---------|----------|---------------|
| **Linearizability** | Operasi terlihat terjadi dalam urutan real-time yang sama | Paling lambat | Spanner, etcd, ZooKeeper |
| **Sequential** | Urutan operasi tiap client konsisten, antar client bebas | Lebih cepat | Database traditional |
| **Causal** | Operasi yang berhubungan cause-effect terlihat berurutan | Sedang | COPS, SwiftNoSQL |
| **Read-After-Write** | Client selalu lihat tulisannya sendiri | Sedang | Session consistency di CDN |
| **Monotonic Read** | Client gak akan lihat data yang "lebih lama" setelah lihat data baru | Sedang | DNS propagation |
| **Eventual** | Semua node converge ke nilai yang sama — tanpa jaminan kapan | Paling cepat | Cassandra, DynamoDB, S3 |

### 3.3 Kapan Pilih Yang Mana

```text
Financial transaction (transfer uang)?
  → Linearizability — butuh jaminan

Social media feed (like post)?
  → Eventual consistency — gak masalah telat 1 detik

Shopping cart?
  → Read-After-Write — user harus lihat barang yang baru dimasukin

DNS record?
  → Eventual — propagation butuh waktu, gak kritis

Distributed lock?
  → Linearizability — etcd/ZooKeeper

IoT sensor reading?
  → Causal — urutan event penting, timing gak penting
```

---

## 4. Consensus Protocols — Paxos, Raft, Zab, VR

Consensus = protocol untuk membuat N node setuju pada satu nilai. Ini adalah **fondasi** dari replicated state machine, leader election, dan distributed coordination.

### 4.1 Formal Definition

```
Properties:
  - Agreement:   Hanya satu nilai yang bisa dipilih
  - Validity:    Nilai yang dipilih harus diusulkan oleh suatu node
  - Termination: Semua node akhirnya memilih suatu nilai
  - Integrity:  Node gak bisa memilih dua kali

Tanpa termination = FLP impossibility (Fischer, Lynch, Paterson 1985):
  Dalam sistem asinkron dengan satu node yang bisa crash,
  tidak ada algoritma konsensus deterministic yang bisa menjamin termination.
  → Solusi: failure detector, timeout, randomisasi
```

### 4.2 Paxos

Classic Paxos (Leslie Lamport, 1998) terkenal sangat sulit dipahami — Lamport sendiri nulis paper "The Part-Time Parliament" dengan setting Yunani kuno yang bikin bingung.

**Cara Kerja:**

```
Phase 1a (Prepare):
  Proposer → Acceptors: "Prepare(N)" 
  Acceptors → Promises: jika N > balik_N, janji gak terima proposal < N

Phase 1b (Promise):
  Acceptor janji + kirim nilai yang udah diterima (jika ada)

Phase 2a (Accept):
  Proposer → Acceptors: "Accept(N, value)"
  Value = nilai dari acceptor dengan balik_N tertinggi, atau value sendiri

Phase 2b (Accepted):
  Acceptor accept jika N >= promised_N
  Kalau majority accept → VALUE IS CHOSEN!

Multi-Paxos:
  - Satu proposer jadi leader (stable)
  - Skip Phase 1 untuk proposal berikutnya
  - O(1) round trip per nilai
  - Digunakan di: Google Chubby, Spanner
```

**Kelemahan Paxos:**
- Sangat sulit dipahami & diimplementasi dengan benar
- Banyak implementasi yang subtle bug (Raft paper menyebut "Paxos is notoriously difficult to understand")
- Leader election tidak built-in — harus add-on

### 4.3 Raft

Raft (Diego Ongaro, 2013) dirancang explicit sebagai **alternative teachable** untuk Paxos. Bukan invent algoritma baru, tapi restrukturisasi consensus jadi komponen yang lebih jelas.

**Tiga Subproblem:**

```
1. Leader Election    — satu node jadi leader
2. Log Replication    — leader replicate log ke followers
3. Safety             — kalau node mengaku committed, log-nya pasti ada di majority
```

**Leader Election:**

```text
Setiap node punya timeout random (150-300ms):
  - Denger heartbeat dari leader → reset timer
  - Timer expire → jadi Candidate
  - Candidate minta vote ke semua node
  - Dapet majority → jadi leader untuk term baru

Raft menjamin:
  - Hanya satu leader per term (safety)
  - Leader crash → otomatis elect baru setelah timeout
  - Split vote → timeout + retry dengan random baru
```

**Log Replication:**

```text
Client → Leader:
  1. Leader append log entry ke local log
  2. Leader kirim AppendEntries RPC ke semua follower
  3. Follower append ke log, balik OK
  4. Leader terima majority OK → commit → apply ke state machine
  5. Leader inform followers di heartbeat berikutnya

Log matching property:
  - Kalau dua log punya entry dengan index + term yang sama,
    maka entry itu identik DAN semua entry sebelumnya identik
```

**Perbandingan dengan Paxos:**

| Aspek | Paxos | Raft |
|:------|-------|------|
| Complexity | Tinggi (kabur, ambiguous) | Rendah (modular, explicit) |
| Leader election | Add-on (separate) | Built-in (first-class) |
| Log management | Implicit | Explicit (log matching) |
| Cluster change | Tidak dibahas | Joint consensus (explicit) |
| Adopsi industri | Google (Chubby, Spanner) | etcd, Consul, TiKV, CockroachDB |

### 4.4 Zab (ZooKeeper)

ZooKeeper Atomic Broadcast — protocol di belakang ZooKeeper. Mirip Raft tapi mayoritas perbedaan:

- **Dynamic leader election**: ZXID (ZooKeeper Transaction ID) = epoch + counter
- **Phase**: Discovery → Synchronization → Broadcast
- Tidak ada log matching property seperti Raft — Zab fokus ke reliable broadcast, bukan replicated state machine secara general

### 4.5 VR (Viewstamped Replication)

Salah satu consensus protocol tertua (Oki & Liskov, 1988). Lebih tua dari Paxos! Mirip Raft:
- **View** = term (Raft)
- **Primary** = leader
- **View change** = leader election

**Kenapa VR kurang populer:** Gak ada paper yang accessible kayak Raft. Tapi implementasi di sistem nyata ada — terutama di Microsoft research projects.

### 4.6 Perbandingan Consensus Protocol

| Protocol | Tahun | Kompleksitas | Failure Model | Adopsi |
|:---------|:-----:|:------------|:--------------|:-------|
| VR | 1988 | Sedang | Crash-fail | Riset |
| Paxos | 1998 | Tinggi | Crash-fail | Google infra |
| Multi-Paxos | ~2006 | Tinggi | Crash-fail | Spanner, Chubby |
| Zab | 2008 | Sedang | Crash-fail | ZooKeeper (Yahoo, Kafka) |
| Raft | 2013 | Rendah | Crash-fail | etcd, Consul, TiDB |
| PBFT | 1999 | Sangat Tinggi | Byzantine | Hyperledger, Zilliqa |

---

## 5. Clock & Ordering — Lamport, Vector Clock, TrueTime

### 5.1 Masalah Waktu di Sistem Terdistribusi

| Problem | Sebab | Akibat |
|:--------|:------|:-------|
| Clock drift | Crystal oscillator gak presisi | Dua node punya waktu berbeda |
| NTP sync error | Network latency, asymmetry | Walaupun sync, masih ada offset |
| Leap second | Earth rotation gak konstan | Time jump (2012: Cloudflare, Reddit down) |
| Monotonic vs wall clock | Kernel bedain waktu absolut vs relatif | timeout algorithm failure |

### 5.2 Lamport Logical Clock

Lamport (1978) — cara paling sederhana untuk mengurutkan event tanpa clock fisik:

```
Aturan:
  - Setiap node punya counter (LC) mulai 0
  - Setiap event internal: LC += 1
  - Setiap send message: LC += 1, attach LC ke message
  - Setiap receive message: LC = max(LC, msg.LC) + 1

Keterbatasan:
  - C → D (causal relation): LC(C) < LC(D)    ✅
  - LC(A) < LC(B) → A → B (causality)?        ❌
  Bisa false positive — gak bisa deteksi concurrent events
```

### 5.3 Vector Clock

Solusi untuk concurrent event detection:

```
Setiap node punya vector [V1, V2, ..., Vn]

Update rule:
  - Internal: increment Vi milik sendiri
  - Send: increment Vi, attach vector
  - Receive: element-wise max(self, msg), lalu increment Vi

Perbandingan:
  V(A) <= V(B) → A happens-before B
  V(A) || V(B) → A concurrent dengan B
```

**Masalah Vector Clock:** Ukuran = O(n) — mahal untuk sistem dengan ribuan node. Solusi: **Dotted Version Vectors** (Dynamo), **Interval Tree Clocks**, **Hybrid Logical Clocks**.

### 5.4 Hybrid Logical Clock (HLC)

Kombinasi NTP + Logical Clock (Kulkarni, 2014):

```
NTP memberi wall time (T)
Lamport memberi ordering (L)

HLC = (T, L)
  - Ketika wall time naik: pakai T
  - Ketika wall time stagnant (drift): pakai L + 1
  
Hasil: bounded clock error + causal ordering
```

### 5.5 Google TrueTime

Digunakan di Spanner — memberikan ** bounded clock uncertainty ** bukan waktu absolut:

```
TrueTime(TT) = [earliest, latest]
  - earliest = waktu terkecil yang mungkin
  - latest   = waktu terbesar yang mungkin
  - uncertainty (ε) = latest - earliest

Spanner menjamin linearizability dengan:
  - Saat commit transaksi: tunggu sampai ε lewat
  - "Commit wait" = ε (biasanya 1-7ms)
  - Ini memastikan bahwa commit timestamp benar-benar di masa lalu

Kenapa ini penting:
  - Without TrueTime: distributed transactions butuh 2PC + Paxos
  - With TrueTime: Spanner bisa external consistency tanpa 2PC overhead
  - Trade-off: Commit wait nambah latency 1-7ms
```

---

## 6. Replication Patterns — Leader, Multi-Leader, Leaderless

### 6.1 Single-Leader (Master-Slave)

```
Client → Leader (read + write)
                │
        ┌───────┼───────┐
        │       │       │
     Follower Follower Follower (read-only)
        │       │       │
        └───────┼───────┘
              Backup (async/sync)
```

**Karakteristik:**
- Semua write lewat leader → no conflict
- Read bisa dari follower → scalability read
- Sync replication: follower confirm sebelum leader ack → durability tinggi, latency tinggi
- Async replication: leader ack dulu → latency rendah, risk data loss saat failover

**Synchronous vs Asynchronous:**

| Mode | Durability | Latency | Failover Risk |
|:-----|:----------:|:-------:|:-------------:|
| Sync | ✅ No data loss | Tinggi (wait semua) | Rendah |
| Async | ❌ Mungkin loss | Rendah | Tinggi |
| Semi-sync | 🟡 Satu follower confirm | Sedang | Sedang |

**Semi-sync = standard di production:**
```sql
-- PostgreSQL
ALTER SYSTEM SET synchronous_standby_names = 'FIRST 1 (standby1, standby2)';
```

### 6.2 Multi-Leader

```
       ┌──────────┐
  ┌───→│ Leader A │←───┐
  │    └────┬─────┘    │
  │         │          │
  │   Replicate (async)│
  │         │          │
  │    ┌────▼─────┐    │
  └────│ Leader B │←───┘
       └──────────┘
```

**Use case:**
- Multi-datacenter deployment
- Offline-first apps (CouchDB, MongoDB Realm)
- Collaborative editing (Google Docs, CRDT)

**Masalah:**
- **Write conflict** — dua leader edit data sama
- **Conflict resolution:**
  - Last-Write-Wins (LWW) — risk data loss
  - CRDT (Conflict-free Replicated Data Types)
  - Custom merge logic (OT untuk collaborative editing)

### 6.3 Leaderless (Dynamo-style)

```
      Client
      │  │  │
      │  │  │  (write ke semua replica)
      ▼  ▼  ▼
    ┌──┐┌──┐┌──┐
    │R1││R2││R3│
    └──┘└──┘└──┘
      │  │  │
      │  │  │  (read dari semua, pilih yang terbaru)
      ▼  ▼  ▼
      Client
```

**Quorum:**
- N = total replica
- W = write quorum (minimal node yang harus confirm write)
- R = read quorum (minimal node yang harus di-read)

| Quorum | Konsistensi | Performa |
|:-------|:-----------|:---------|
| W+R > N | **Strong** (pasti ada overlap) | Lebih lambat |
| W+R <= N | Eventual | Lebih cepat |
| W=1, R=N | Write cepat, read lambat | Heavy read |
| W=N, R=1 | Write lambat, read cepat | Heavy write |

**Hinted Handoff:** Kalau node temporary down, node lain terima write proxy → saat node balik, replay.

**Read Repair:** Saat read mendeteksi versi beda, node out-of-date langsung diperbaiki.

**Anti-entropy:** Background process yang bandingkan Merkle tree antar replica untuk deteksi divergensi.

---

## 7. Sharding & Partitioning — Consistent Hashing, Rebalancing

### 7.1 Partitioning Strategies

**Range-based:**
```text
Users A-M → Shard 0
Users N-Z → Shard 1

✅: Range scan efisien (BETWEEN, ORDER BY)
✅: Prefix query bisa diarahkan
❌: Hotspot — data gak merata (Z lebih banyak dari Q)
❌: Resharding mahal (split data besar)
```

**Hash-based:**
```text
hash(user_id) % 4 → Shard 0-3

✅: Distribusi merata
✅: Simple, mudah dipahami
❌: Range scan jadi scatter (baca semua shard)
❌: Add/remove shard = redistribusi penuh (hash remap)
```

**Consistent Hashing (Dynamo, Cassandra):**
```text
Hash ring: [0, 2^64 - 1]
  Node A: posisi hash("A")
  Node B: posisi hash("B")
  Node C: posisi hash("C")

Range query:
  key → hash(key) → jalan clockwise → node pertama

Add node D:
  - Cuma data di range adjacent yang pindah
  - Gak perlu remap semua

Problem: distribusi gak merata
  → Virtual nodes (tiap node punya 100-200 posisi di ring)
```

### 7.2 Rebalancing Challenges

```text
Goal: distribusi data merata saat node ditambah/dihapus

Challenge 1: Rebalancing pakai bandwidth
  - Kalau terlalu cepat → degrade production
  - Kalau terlalu lambat → data gak merata

Challenge 2: Consistency during rebalancing
  - Data yang dipindah harus tetap bisa diakses
  - Client harus tau shard mana yang perlu di-query

Strategi:
  Fixed partitioning   → jumlah partisi tetap, partisi pindah antar node
  Dynamic partitioning → partisi split/merge otomatis (HBase)
  Consistent hashing   → minimal data movement
```

---

## 8. Distributed Transactions — 2PC, 3PC, Saga

### 8.1 Two-Phase Commit (2PC)

```
Coordinator                    Participants
     │                              │
     ├── Prepare ──────────────────→│
     │                              │
     │←─────────────── Yes/No ─────┤
     │                              │
     ├── Commit (if all Yes) ─────→│
     │     atau Rollback           │
     │                              │
     │←─────────────── Ack ────────┤
```

**Masalah 2PC:**
- **Blocking:** Coordinator crash di prepare → participant tunggu forever
- **Single point of failure:** Coordinator gak bisa direcover sempurna
- **Performance:** Mahal — 2 RTT + log writes

### 8.2 Three-Phase Commit (3PC)

```
Phase 1: CanCommit (cek feasibility)
Phase 2: PreCommit (prepare — tapi belum commit)
Phase 3: DoCommit (actual commit)

Keuntungan: Non-blocking — participant bisa timeout dan abort
Kerugian: Masih gak tahan network partition
```

### 8.3 Saga Pattern

Saga = urutan local transaksi, tiap langkah punya **compensating action**:

```
Order Saga:
  1. Create Order           → compensate: Cancel Order
  2. Reserve Inventory      → compensate: Release Inventory
  3. Charge Payment         → compensate: Refund Payment
  4. Send Notification      → compensate: none (fire-and-forget)
```

**Coordinator Saga:**
```
Orchestration-based:
  Saga Manager → langkah A → langkah B → langkah C
  Kalau gagal di C → compensating A, compensating B

Choreography-based:
  Service A → event → Service B → event → Service C
  Masing-masing publish event compensating kalau gagal
```

**Kapan pake:**

| Pendekatan | Isolation | Throughput | Kompleksitas | Use Case |
|:-----------|:---------:|:----------:|:------------:|:---------|
| 2PC | Serializable | Rendah | Sedang | Financial (transfer) |
| 3PC | Serializable | Sangat Rendah | Tinggi | Legacy system |
| Saga (orchestrated) | Read Uncommitted | Tinggi | Sedang | Microservices |
| Saga (choreo) | Read Uncommitted | Tertinggi | Tinggi | Event-driven |

---

## 9. Failure Detection — Gossip, SWIM, Phi-Accrual

### 9.1 Gossip Protocol

Setiap node periodic share state dengan beberapa node random:

```
Setiap T detik:
  Pilih f node random
  Kirim state (atau delta) ke mereka

Properties:
  - O(log N) rounds untuk propagation
  - Throttle: fan-out f = 2-4 biasanya cukup
  - Sangat resilient — gak perlu centralized monitor
```

**Failure Detection via Gossip (Cassandra):**
```
Tiap node track heartbeat dari node lain:
  - Absence of heartbeat > timeout → suspect
  - Multi-node suspicion → confirmed dead
```

### 9.2 SWIM (Scalable Weakly-consistent Infection-style Membership)

SWIM memisahkan dua fungsi:
1. **Failure detection** — ping/ping-req
2. **Membership dissemination** — gossip

```
Ping target: pilih random → ping → timeout? → ping-req(f, target)
Kalau semua gagal → suspect target → gossip suspicion ke cluster

Keunggulan dari gossip murni:
  - Detection latency: O(1) — langsung ping
  - False positive rendah — cross-check via ping-req
```

### 9.3 Phi-Accrual Failure Detector

Tidak pakai timeout fixed — pakai **historical sampling**:

```
Phi = -log10(P(heartbeat arrival > current gap))
  Phi = 0:   yakin node hidup
  Phi = 1:   ~10% chance node dead
  Phi = 8:   >99.99% chance node dead

Keuntungan:
  - Threshold bisa diset per aplikasi (phi=8 untuk critical)
  - Otomatis adapt ke network condition — latency spike gak langsung trigger failover
  - Cassandra dan Akka pake ini
```

---

## 10. Distributed Observability — Tracing, Logging, Metrics

### 10.1 Three Pillars

| Pillar | Fungsi | Tool |
|:-------|--------|:----:|
| **Tracing** | Track request antar service | OpenTelemetry, Jaeger, Zipkin |
| **Logging** | Event log per node | ELK, Loki, Fluentd |
| **Metrics** | Numeric aggregate per node/request | Prometheus, Grafana |

### 10.2 Distributed Tracing

**Masalah:** Di monolith, lo bisa trace request dari log sequence number. Di distributed system, request melalui 10-50 service — korelasinya butuh context propagation.

```
Context Propagation:
  - Setiap service inject context (trace_id, span_id) ke header request
  - Network call: inject via gRPC metadata / HTTP header
  - Async/queue: inject via message header

W3C Trace Context:
  traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
  └version┘ └─────────── trace_id ──────────┘ └─── span_id ───┘└flags┘
```

### 10.3 Logging Correlation

Setiap log entry di tiap node harus punya:
```json
{
  "timestamp": "2026-07-19T12:00:00.123Z",
  "node_id": "pod-abc-123",
  "trace_id": "0af7651916cd43dd8448eb211c80319c",
  "span_id": "b7ad6b7169203331",
  "service": "order-service",
  "level": "WARN",
  "message": "Retry attempt 2/3 for payment service"
}
```

Dengan `trace_id` di semua log, lo bisa `grep` lintas service.

---

## 🔗 Koneksi ke Catatan Lain

| Catatan | Koneksi |
|:--------|:--------|
| [[ddia-kleppmann]] | DDIA Part II — distributed data, replication, partitioning |
| [[database-internals-indexing-mvcc]] | Replication & queries di database — foundation theory |
| [[system-design]] | Arsitektur skala besar — distributed systems sebagai fondasi |
| [[cloud-infrastructure]] | Cloud platform — distributed systems dalam praktik |
| [[api-protocols-deepdive]] | gRPC/RPC — komunikasi antar node |
| [[kubernetes-architecture-deepdive]] | K8s sebagai distributed system coordinator |
| [[observability-stack-prometheus-grafana]] | Observability untuk distributed system |
| [[platform-technologies-overview]] | Platform yang dibangun di atas distributed systems |

---

## ✅ Checklist

- [ ] Paham CAP theorem, PACELC, dan implikasi nyata di production
- [ ] Bisa jelasin perbedaan Paxos dan Raft — kenapa Raft lebih populer
- [ ] Paham perbedaan consistency models dan kapan pake masing-masing
- [ ] Tau beda single-leader vs multi-leader vs leaderless replication
- [ ] Bisa jelasin consistent hashing dan kenapa virtual nodes penting
- [ ] Paham kapan 2PC tepat dan kapan Saga lebih cocok
- [ ] Tau cara kerja gossip protocol dan phi-accrual failure detector
- [ ] Bisa setup distributed tracing dengan OpenTelemetry
- [ ] Paham FLP impossibility dan kenapa consensus butuh failure detector
- [ ] Bisa bedain logical clock (Lamport, Vector) vs wall clock (NTP, TrueTime)

---

## Roadmap Belajar

```
HARI 1: Fondasi
  - Baca catatan ini sampai selesai
  - Simulasi CAP: 2 node dengan network partition (tools: toxiproxy)
  - Test: apa yang terjadi saat partition di database single-leader?

HARI 2: Consensus
  - Implementasi Raft sederhana (referensi: raft.github.io)
  - Baca Raft paper (Ongaro, 2013)
  - Test: etcd cluster, crash leader, lihat election

HARI 3: Replication & Sharding
  - Setup PostgreSQL streaming replication
  - Setup Cassandra cluster, test consistent hashing
  - Benchmark: single-leader vs leaderless write throughput

HARI 4: Distributed Transactions
  - Implementasi Saga pattern (orchestrated) untuk e-commerce
  - Compare: 2PC vs Saga — test with failure injection
  - Baca Spanner paper (TrueTime + Paxos)

HARI 5: Observability & Production
  - Setup OpenTelemetry collector + Jaeger
  - Inject fault (Chaos Mesh / Litmus) dan trace propagation
  - Baca production incident report dari large-scale distributed systems
```

> [!warning] Bottom Line
> Distributed systems bukan topik yang bisa dipelajari sekali lalu selesai. Setiap pola punya **trade-off yang konteks-dependent**: Raft great untuk coordination (etcd), tapi gak cocok untuk data plane (Cassandra). Consistent hashing solves sharding, tapi bikin range scan impossible. CAP itu bukan trilemma — cuma relevan saat partition. Kunci sebenarnya ada di **memahami failure model sistem lo** dan **memilih trade-off dengan sengaja**, bukan karena kebetulan pake tool populer.

> [!tip] Lanjutan
> Distributed systems adalah **keluarga besar** — catatan ini fokus ke theory dan mekanisme inti. Lanjutan yang bisa dieksplor:
> - [[kubernetes-operations-helm-gitops]] — distributed system coordinator di production
> - [[database-schema-sharding-replication]] — praktik sharding + replication di database
> - [[database-internals-indexing-mvcc]] — storage engine sebagai distributed system component
> - DDIA (Designing Data-Intensive Applications) — bacaan wajib untuk distributed systems
---

audited
---
