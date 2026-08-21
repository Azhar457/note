---
title: "System Design: Database Internals and Architecture"
tags:
  - ai-systems
  - library
created: 2026-04-25
updated: 2026-07-01
status: pending
cssclasses:
  - wide-table
---
> Cara berpikir sistem besar. Database Internals menjawab "kenapa query-mu lambat dan bagaimana storage bekerja di level disk." Software Architecture menjawab "bagaimana membangun sistem yang tidak runtuh saat tumbuh 100x."

> [!info] Cara Baca
> Database Internals = fondasi sebelum pakai ORM/query optimizer dengan benar. Software Architecture = fondasi sebelum design sistem yang harus bertahan bertahun-tahun. Keduanya tentang **keputusan yang mahal untuk diubah nanti**.

---

## Sheet 1 — Database Internals: Dari Disk sampai Query Optimizer

| 🗄️ Level & Konsep | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian | 🔗 Koneksi ke Topik Lain |
|---|---|---|---|
| **Level 0** — Storage Engine & Page Layout *(heap file, page, slotted page, row vs column store)* | Data disimpan dalam page (biasanya 4KB atau 16KB). Heap file: page tidak terurut, insert cepat tapi scan lambat. Slotted page: array offset di awal page, data dari belakang — support variable-length row. Row store (OLTP): satu row disimpan bersama, bagus untuk point query. Column store (OLAP): satu kolom disimpan bersama, bagus untuk aggregate query. | Column store buruk untuk update single row (harus update banyak kolom file). Row store buruk untuk `SELECT AVG(salary)` yang scan jutaan row tapi hanya butuh satu kolom. | Koneksi ke Data Recovery (page forensik, carving), koneksi ke OS (filesystem page, mmap) |
| **Level 1** — Indexing *(B-tree, B+tree, hash index, bitmap, covering index, index selectivity)* | B+tree: semua data di leaf node, leaf node linked list → range scan efisien. Internal node hanya key untuk navigasi. Hash index: O(1) point lookup, tidak support range query. Covering index: index menyimpan semua kolom yang dibutuhkan query — tidak perlu balik ke heap. Index selectivity: rasio distinct value / total row — index pada kolom low selectivity (gender) tidak efektif. | Over-indexing: setiap write harus update semua index → write amplification. Index tidak dipakai jika: fungsi di kolom (`WHERE YEAR(date)=2024`), implicit cast, leading wildcard (`LIKE '%abc'`). | B+tree = aplikasi langsung dari Algoritma Level 2, koneksi ke Database Recovery (index reconstruction) |
| **Level 2** — Query Execution *(query parser, planner, optimizer, execution engine, vectorized execution)* | Query → parse → AST → logical plan → physical plan (optimizer pilih join order, index usage, execution strategy) → execution. Cost-based optimizer: estimasi cost berdasarkan statistik (cardinality, histogram). Vectorized execution (SIMD): proses batch kolom sekaligus, bukan row per row — ClickHouse, DuckDB. | Stale statistics → optimizer pilih plan buruk → query 100x lebih lambat. N+1 query problem: ORM yang generate satu query per row. | `EXPLAIN ANALYZE` adalah senjata wajib, koneksi ke OS (execution = syscall ke disk/memory) |
| **Level 3** — Transaction & Concurrency *(ACID, MVCC, isolation levels, 2PL, deadlock detection)* | ACID: Atomicity (all or nothing), Consistency (invariant terjaga), Isolation (transaksi tidak interference), Durability (commit survive crash). MVCC (Multi-Version Concurrency Control): setiap write buat versi baru, reader lihat snapshot lama → no read-write conflict. Isolation levels: Read Uncommitted < Read Committed < Repeatable Read < Serializable. 2PL: lock semua resource sebelum release → deadlock possible. | Phantom read terjadi di Repeatable Read. Long-running transaction di MVCC → version bloat (PostgreSQL vacuum). Deadlock: detect via wait-for graph, resolve via timeout atau victim selection. | Koneksi ke Distributed Systems (distributed transaction), koneksi ke OS (mutex, semaphore) |
| **Level 4** — Write-Ahead Log & Recovery *(WAL, redo log, undo log, checkpoint, ARIES)* | WAL: tulis ke log dulu sebelum modifikasi actual data page. Crash → replay log dari last checkpoint. Redo log: apa yang harus dilakukan ulang (committed transaction). Undo log: apa yang harus dibatalkan (uncommitted transaction). ARIES algorithm: Analysis → Redo → Undo. Checkpoint: batas mulai replay agar tidak dari awal. | Log volume besar pada write-heavy workload. Checkpoint terlalu jarang → recovery lama. fsync bottleneck: WAL harus fsync ke disk untuk Durability — tidak bisa diabaikan. | Koneksi langsung ke Data Recovery (WAL sebagai forensik artefak), koneksi ke OS (filesystem journaling = konsep serupa) |
| **Level 5** — Distributed Database *(replication, sharding, CAP theorem, consensus, two-phase commit)* | Replication: primary-replica (async) atau synchronous (lebih lambat, lebih aman). Sharding: partisi data ke node berbeda — range shard, hash shard, directory shard. CAP theorem: Consistency, Availability, Partition tolerance — pilih 2 dari 3 (partition selalu terjadi → pilih CA atau CP). Paxos/Raft: consensus algorithm untuk agree on single value di distributed system. 2PC: koordinasi atomic commit di multi-node. | Split-brain: dua node sama-sama kira dirinya primary → data conflict. 2PC blocking: coordinator crash → participant stuck. CAP sering disalahpahami — lebih tepatnya PACELC. | Koneksi ke Cloud Level 7 (Vitess, CockroachDB), koneksi ke Blockchain (consensus) |
| ☠️ **Level 6** — Storage Engine Internals *(LSM-tree, SSTable, compaction, bloom filter, write amplification)* | LSM-tree (Log-Structured Merge): tulis ke memtable (in-memory) → flush ke SSTable (immutable sorted file on disk) → compaction gabungkan SSTable. Write amplification: data ditulis berkali-kali selama compaction. Read amplification: scan banyak SSTable untuk satu key. Bloom filter: cek apakah key mungkin ada di SSTable sebelum disk read. Dipakai: RocksDB, Cassandra, LevelDB, HBase. | Write amplification bisa 10-30x pada workload random write. Compaction overhead bisa spike latency. Space amplification: data lama belum tercompact. | Koneksi ke Flash Drive Forensics (wear leveling mirip compaction concern), koneksi ke Algoritma (Bloom filter) |

---

## Sheet 2 — Software Architecture: Dari Monolith sampai Event-Driven

| 🏛️ Level & Pattern | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian | 🎯 Contoh Nyata |
|---|---|---|---|
| **Level 0** — Design Principles *(SOLID, DRY, KISS, YAGNI, separation of concerns)* | **S**ingle Responsibility, **O**pen/Closed, **L**iskov Substitution, **I**nterface Segregation, **D**ependency Inversion. DRY (Don't Repeat Yourself). KISS (Keep It Simple). YAGNI (You Aren't Gonna Need It). Separation of concerns: setiap modul punya satu alasan untuk berubah. | SOLID diterapkan berlebihan → over-abstraction, terlalu banyak interface untuk hal sederhana. DRY berlebihan → coupling tinggi antara modul yang seharusnya independen. | Prinsip ini ada di semua codebase yang bertahan > 5 tahun |
| **Level 1** — Design Patterns *(creational, structural, behavioral — GoF 23 patterns)* | Creational: Singleton, Factory, Abstract Factory, Builder, Prototype. Structural: Adapter, Bridge, Composite, Decorator, Facade, Proxy. Behavioral: Observer, Strategy, Command, Iterator, State, Template Method, Chain of Responsibility. Pattern = solusi yang sudah terbukti untuk masalah yang sering berulang. | Pattern bukan tujuan — solusi untuk masalah spesifik. Pattern yang dipaksakan pada masalah yang tidak cocok → complexity tanpa benefit. "If all you have is a hammer, everything looks like a nail." | Observer = Event listener di semua framework. Strategy = sort algorithm pluggable. Decorator = Python decorator |
| **Level 2** — Monolithic Architecture *(layered, modular monolith, MVC, clean architecture)* | Satu deployable unit. Layered: Presentation → Business Logic → Data Access. MVC: Model-View-Controller. Clean Architecture (Uncle Bob): dependency selalu mengarah ke dalam (domain tidak tahu framework). Modular monolith: monolith dengan batas modul yang jelas — langkah sebelum microservices. | Big ball of mud: monolith tanpa struktur → setiap perubahan bisa break hal lain. Scaling hanya bisa vertical (scale seluruh aplikasi, bukan hanya komponen yang bottleneck). | WordPress, Django app sederhana, awal semua startup |
| **Level 3** — Microservices *(service decomposition, API gateway, service discovery, circuit breaker)* | Dekomposisi berdasarkan business domain (Domain-Driven Design). Setiap service punya database sendiri (database per service pattern). API Gateway: single entry point, routing, rate limiting, auth. Service discovery: Consul, Kubernetes DNS. Circuit Breaker: hentikan request ke service yang failing agar tidak cascade failure. | Distributed monolith: microservices yang tightly coupled — dapat kompleksitas distributed system tanpa benefit. Overhead operasional besar. Debugging lintas service sangat sulit tanpa distributed tracing. | Netflix, Uber, Tokopedia di scale tertentu |
| **Level 4** — Event-Driven Architecture *(event sourcing, CQRS, message queue, Kafka, saga pattern)* | Event sourcing: simpan sequence of events, bukan current state — audit trail sempurna, bisa replay. CQRS (Command Query Responsibility Segregation): pisahkan write model (command) dari read model (query). Kafka: distributed event streaming, retention lama, consumer bisa replay. Saga: long-running distributed transaction via compensating transaction. | Eventual consistency bisa bingungkan user. Event schema evolution sulit (backward/forward compatibility). Debugging event-driven system kompleks — membutuhkan event correlation. | Gojek (order processing), bank (transaction log = event sourcing alami) |
| **Level 5** — Distributed System Patterns *(rate limiting, backpressure, bulkhead, sidecar, service mesh)* | Rate limiting: token bucket, leaky bucket, sliding window. Backpressure: producer tidak boleh lebih cepat dari consumer mampu proses. Bulkhead: isolasi failure — pool thread terpisah per service dependency. Sidecar: container terpisah yang handle cross-cutting concern (logging, tracing, mTLS). | Backpressure yang tidak diimplementasi → memory exhaustion. Rate limiting yang terlalu ketat → false throttling legitimate user. Cascading failure tanpa circuit breaker. | Istio (sidecar), Netflix Hystrix (circuit breaker), AWS API Gateway (rate limiting) |
| **Level 6** — Domain-Driven Design *(bounded context, aggregate, repository, domain event, ubiquitous language)* | Bounded Context: batas domain yang jelas — "Order" di Inventory berbeda dari "Order" di Shipping. Aggregate: cluster entity yang diperlakukan sebagai unit consistency. Ubiquitous Language: developer dan domain expert pakai terminologi yang sama. Domain Event: sesuatu yang terjadi di domain yang significant. Anti-corruption layer: terjemahan antar bounded context. | DDD over-engineering untuk domain sederhana (CRUD aplikasi tidak butuh DDD). Bounded context yang salah → tight coupling. | Fondasi cara decompose microservices yang benar |
| ☠️ **Level 7** — Resilience & Chaos Engineering *(chaos monkey, fault injection, SLA/SLO/SLI, error budget)* | Chaos engineering: sengaja inject failure ke production untuk uji resilience sebelum failure terjadi sendiri. Netflix Chaos Monkey: randomly terminate VM di production. SLI (Service Level Indicator): metrik konkret (latency P99). SLO (Objective): target SLI (P99 < 200ms). SLA (Agreement): kontrak dengan konsekuensi. Error budget: (1 - SLO) × time = "jatah gagal" yang bisa dipakai untuk ship fitur baru. | Chaos engineering tanpa observability yang baik = tidak bisa diagnose apa yang break. Error budget habis → freeze fitur baru sampai reliability pulih. | Google SRE book, Netflix Chaos Monkey, Gremlin |

---

## Peta Keputusan Arsitektur

```
MULAI PROYEK BARU
        │
        ▼
Berapa user? Seberapa kompleks domain?
        │
   Sederhana/kecil          Kompleks/besar
        │                        │
        ▼                        ▼
   [Monolith]            [Modular Monolith]
   Clean Architecture     DDD + Bounded Context
        │                        │
        │ Traffic grow           │ Team grow
        ▼                        ▼
   [Scale vertical]       [Microservices]
   atau tambah read        hanya jika needed
   replica                        │
                                  │ Event complexity tinggi
                                  ▼
                          [Event-Driven]
                          Kafka + CQRS + Saga
                                  │
                                  │ Multi-region
                                  ▼
                          [Distributed DB]
                          CockroachDB / Vitess
```

> [!tip] Aturan Martin Fowler soal Microservices
> *"Don't start with microservices. Start with a monolith, understand your domain, then extract services when you feel the pain of the monolith."*
> Mayoritas startup yang mulai dengan microservices di hari pertama akhirnya refactor ke modular monolith.

> [!warning] System Design Interview vs Realita
> System design interview mengajarkan cara **presentasi keputusan arsitektur**, bukan cara **membuat keputusan yang benar**. Di realita: mulai sederhana, ukur, optimasi berdasarkan data aktual — bukan asumsi di whiteboard.

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[computer-science-foundations|Computer Science Foundations]] — OS & memory sebagai fondasi database
- [[math-and-algorithms|Matematika & Algoritma]] — B-tree, hash table sebagai fondasi index
- [[cloud-infrastructure|Infrastruktur Cloud]] — deployment dari arsitektur ini
- [[research-methodology|Research Methodology]] — evaluasi tradeoff arsitektur

---

*System Design | Database Internals + Software Architecture · Dari Disk Page sampai Chaos Engineering*
---

audited
---
