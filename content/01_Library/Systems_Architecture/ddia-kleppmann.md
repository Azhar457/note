---
title: "Designing Data-Intensive Applications (DDIA)"
tags:
  - distributed-systems
  - databases
  - architecture
  - scalability
  - replication
  - consistency
aliases:
  - "DDIA"
  - "Kleppmann"
  - "designing-data-intensive-applications"
created: 2026-07-05
updated: 2026-07-05
status: active
---

# 🌐 Designing Data-Intensive Applications

> Martin Kleppmann — 2017

**Tesis:** Buku paling penting soal **sistem backend modern**. Data is at the center — storage, replication, partitioning, transactions, consistency, batch/stream processing. Bukan hype-driven — _fundamental trade-offs_ yang tetep relevan kapanpun.

---

## 📌 Kenapa Penting

- Jawab kenapa database no-SQL muncul, kenapa CAP theorem gak sederhana
- **Trade-offs** > silver bullets — Kleppmann nunjukkin konsekuensi tiap pilihan arsitektur
- Referensi #1 untuk system design interview

## 🎯 Key Takeaways

**1. Storage Engines**

- **LSM-Trees** (LevelDB, Cassandra, RocksDB) vs **B-Trees** (MySQL, Postgres)
  - LSM: write-optimized, compaction overhead
  - B-Tree: read-optimized, stable performance
- **Row-oriented vs Column-oriented** — analytics vs OLTP

**2. Replication**

- **Single-leader** — standard, but failover tricky
- **Multi-leader** — conflict resolution pain (CRDTs help)
- **Leaderless** (Dynamo-style) — quorum reads/writes, but stale reads
- **Synchronous vs Asynchronous** — durability vs latency trade-off

**3. Partitioning (Sharding)**

- By key range — hotspot risk
- By hash of key — even distribution, but range queries suffer
- Rebalancing — jangan pake hash mod N (pakai consistent hashing)

**4. Transactions — the Truth**

- ACID is a spectrum, not a binary switch
- **Isolation levels:**
  - Read Committed (default Postgres/Oracle)
  - Snapshot Isolation / Repeatable Read
  - Serializable — hardest, slowest, but correct
- **Race conditions:** dirty reads, dirty writes, read skew, lost updates, write skew, phantom reads

**5. Distributed Transactions**

- Two-Phase Commit (2PC) — coordinator = single point of failure, blocking
- **Linearizability vs Eventual Consistency** — trade-off real di distributed systems
- CAP: Choose 2 of 3 — tapi realitanya lebih nuanced (partition tolerance gak optional)

**6. Batch Processing (MapReduce)**

- MapReduce + Spark: "Bring computation to data, not data to computation"
- **Join strategies:** sort-merge, broadcast hash, partitioned hash

**7. Stream Processing**

- Kafka, Flink, Samza — unbounded data, processing with state
- **Exactly-once semantics** — achievable but complex
- Stream-table joins — materialized views real-time

**8. Consistency Models**

- **Strong consistency** → correct, slow
- **Eventual consistency** → fast, but stale reads possible
- **Causal consistency** → sweet spot (what CRDTs give)
- **Linearizability** → gold standard, expensive

## 📖 Bab Penting

| Bab | Judul                                | Mengapa                                            |
| --- | ------------------------------------ | -------------------------------------------------- |
| 2   | Data Models and Query Languages      | Relational vs Document vs Graph — kapan pilih apa  |
| 5   | Replication                          | **Wajib** — paling sering ditanya interview        |
| 6   | Partitioning                         | Kapan, gimana, rebalancing                         |
| 7   | Transactions                         | Isolation levels + race conditions                 |
| 8   | The Trouble with Distributed Systems | Clock, crashes, network — _things always go wrong_ |
| 10  | Batch Processing                     | MapReduce + Spark fundamentals                     |
| 11  | Stream Processing                    | Kafka, Flink, exactly-once                         |

## ⚠️ Tantangan

- Tebal 600+ hal — dense, but clearer dari textbook akademik
- Butuh dasar distributed systems (kalo fresh, baca OSTEP Part OS dulu)
- Contoh-contoh konkret (Cassandra, MongoDB, Kafka, Postgres, etc.) — tapi gak perlu hafal implementasi detail

## 🔗 Koneksi

- [[ostep-three-easy-pieces]] — concurrency + OS fundamentals untuk distributed systems
- [[systems-design-interview-alex-xu]] — ringkasan praktis, DDIA adalah _deep theory_-nya
- [[sre-google]] — SRE = run system di buku DDIA di production

## ✅ Checklist

- [ ] Paham B-Tree vs LSM-Tree bedanya apa
- [ ] Bisa jelasin kapan pilih single-leader vs leaderless replication
- [ ] Isolation levels: definisiin + kasus race condition tiap level
- [ ] Konsistensi model: eventual → causal → linearizable
- [ ] Gampang2nya system design interview pakai konsep dari buku ini
