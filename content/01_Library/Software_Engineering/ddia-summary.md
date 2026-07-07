---  
title: "DDIA — Designing Data‑Intensive Applications (Martin Kleppmann)"  
tags:  
  - distributed‑systems  
  - databases  
  - architecture  
  - scalability  
  - consistency  
  - read‑heavy‑vs‑write‑heavy  
created: 2026‑07‑05  
updated: 2026‑07‑05  
status: active  

# TL;DR  
DDIA is the *reference* for building modern data‑centric services. It teaches you to **think in trade‑offs** (CAP, latency, durability) and to pick the right pattern for the job, not a one‑size‑fits‑all solution.

## 1️⃣ Core Concepts (≈ 1 hour read)

| Theme | What to Remember |
|-------|------------------|
| **Storage Engines** | • **B‑Tree** → fast point‑lookups, good for OLTP. <br>• **LSM‑Tree** → write‑optimized, excellent for log‑style ingestion. <br>• Column‑store → analytical scans; Row‑store → transactional updates. |
| **Replication** | • **Leader‑based** (Raft, Paxos) → simple, but single point of failure. <br>• **Multi‑leader / Leaderless** → eventual consistency; use CRDTs or quorum reads. |
| **Partitioning (Sharding)** | • **Hash‑based** + **Virtual Nodes** → even distribution, easy scaling. <br>• **Range‑based** → good for ordered key traversal, but hot spots can appear. |
| **Consistency** | • **Linearizable** → strongest guarantee, expensive (needs TrueTime). <br>• **Causal** → respects cause‑effect, cheaper (vector clocks). <br>• **Eventual** → fast & highly available; fix stale reads with read‑repair. |
| **Transactions** | • ACID is a *spectrum*; snapshot isolation (SI) is the sweet spot for many DBs. <br>• 2PC is **blocking** – prefer Saga pattern for long‑running workflows. |
| **Batch vs Stream** | • **Map‑Reduce** → heavy data, offline processing. <br>• **Stream** (Kafka/Flink) → low‑latency, exactly‑once, stateful windows. |

## 2️⃣ The Trade‑Off Matrix (Quick Decision Guide)

| Decision | Question to Ask | Typical Choice |
|----------|-----------------|----------------|
| **Replication Model** | Do you need *strong* reads or can tolerate eventual? | Leader‑based + synchronous ACK for strong; Multi‑leader/leaderless for high‑scale writes. |
| **Sharding Key** | What query patterns dominate? | Hash key for point lookups; range key for time‑series. |
| **Consistency Level** | Is any stale read fatal? | Linearizable for financial ops; eventual for recommendation feeds. |
| **Processing Paradigm** | Is data *static* or *continuous*? | Batch (Spark) → offline reports; Stream (Kafka/Flink) → real‑time alerts, dashboards. |

## 3️⃣ Practical Checklist (Implement‑today)

- [ ] **Measure** write/read latency & QPS of your primary workload.  
- [ ] **Identify** hot keys → decide between hash vs range partitioning.  
- [ ] **Set up monitoring** for replication lag (target < 5 s).  
- [ ] **Enable read‑repair** on eventual systems (query ≥ 2 replicas, compare timestamps).  
- [ ] **Write a saga** for any workflow that spans multiple services.  
- [ ] **Benchmark** compaction settings (level‑compaction vs tiered) based on storage cost.  
- [ ] **Document** your “trade‑off rationale” in an ADR (Architecture Decision Record).

## 4️⃣ Frequently‑Asked Interview Nuggets

1. **CAP → “pick 2 of 3”** is a *simplification*. Real systems often need **P + C** (i.e., avoid partitions) or **P + A** (accept eventual).  
2. **Explain the difference** between *linearizable* and *snapshot isolation* with a simple banking transfer example.  
3. **When to use CRDTs?** For data types that are *commutative* (counters, sets, LWW‑elem‑set).  
4. **Why use LSM‑Tree?** Because appending is cheap; compaction writes are sequential, great for high ingest.  
5. **How to design sharding for time‑series?** Partition by *day* or *hour* bucket; use *consistent hashing* on a 64‑bit hash of the timestamp bucket.

## 5️⃣ Must‑Read Companion Books

| Book | Relation to DDIA |
|------|------------------|
| **[design-patterns-gof]** | Shows concrete patterns (Factory, Strategy, Observer) used to implement DDIA concepts. |
| **[the-pragmatic-programmer]** | Mindset of responsibility, DRY, and knowledge‑portfolio that underlies building scalable systems. |
| **[refactoring-martin-fowler]** | Broken‑window and refactor mindset → keep the codebase healthy while you evolve partitions/replication. |
| **[systems-design-interview-alex-xu]** | Practical interview‑style summarization of DDIA topics, ready‑to‑talk points. |

## 6️⃣ One‑Page Reference Diagram (Paste into your vault)

```
          +-------------------+
          |   Data Store      |
          | (LSM / B‑Tree)    |
          +--------+----------+
                   |
            Replication (Leader / Leaderless)
                   |
          +--------+----------+
          |   Partitioning    |
          +--------+----------+
                   |
            Consistency Model (Linearizable / Causal / Eventual)
                   |
            Processing (Batch vs Stream)
```

## 7️⃣ TL;DR Summary (≤ 150 words)

DDIA teaches that *every* data‑intensive system is a series of **trade‑offs**. Pick the right storage engine (LSM vs B‑Tree), replication strategy (leader‑based vs leaderless), and partitioning key (hash vs range) based on **your workload’s latency, durability, and consistency requirements**. Understand **ACID isolation levels**, apply **saga** for long‑running transactions, and choose **batch vs stream** processing according to whether you need *historical reports* or *real‑time alerts*. Always monitor **replication lag**, **compaction health**, and **hot‑spot** distribution. Finally, internalise the **trade‑off matrix** and keep an ADR to document why you chose a pattern over another. This mental model is the core of DDIA and the key to acing system‑design interviews and building production‑grade services.

---
