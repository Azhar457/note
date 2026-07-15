---
title: "Database Internals: Indexing, MVCC & Query Planning"
tags:
  - database
  - postgresql
  - indexing
  - mvcc
  - query-optimization
  - internals
aliases:
  - "database-internals"
  - "db-indexing-mvcc"
  - "query-planning-deepdive"
created: "2026-07-15"
updated: "2026-07-15"
status: draft
cssclasses:
  - wide-table
---

> [!abstract] Lebih Dalam dari Sekadar `CREATE INDEX`
> Vault udah punya [[postgresql-administrasi-backup]] dan [[postgresql-performance-triage]] — tapi dua-duanya fokus ke operasional. Catatan ini bedah **apa yang terjadi di dalam database** waktu lo bikin index, ngejalanin query, atau nulis data. Tanpa ini, lo cuma bisa bilang "query lambat, bikin index" tanpa ngerti index mana yang tepat.

---

## 📚 1. Indexing — Bukan Sekadar B-Tree

### 1.1 B-Tree (Default)

```
Root: [50, 100]
     /    |     \
[10,30] [60,80] [110,130]
```

**Karakteristik:**

- Balanced tree — height log(n), typical 3-4 level untuk jutaan row
- Leaf nodes = doubly linked list → range scan O(1) antar leaf
- Write amplification: setiap INSERT bisa trigger page split

**Kapan pake:** Range query, equality, ORDER BY. 90% kasus.

### 1.2 Hash Index

- O(1) lookup, tapi **gak support range query**
- Berguna cuma untuk `=` comparison
- Di PostgreSQL: hash index sekarang WAL-logged (sejak PG10), tapi jarang dipake

### 1.3 GiST, GIN, BRIN

| Type     | Use Case                         | Contoh                     |
| -------- | -------------------------------- | -------------------------- |
| **GiST** | Full-text search, geometric data | `tsvector`, `point`        |
| **GIN**  | Array/JSONB inverted index       | `jsonb_path_ops`           |
| **BRIN** | Data berurutan (time-series)     | Log table dengan timestamp |

**Ponytail:** BRIN underused di banyak infra — untuk time-series data, BRIN 100x lebih kecil dari B-tree.

---

## 🔄 2. MVCC — Kenapa UPDATE Gak Beneran Update

### 2.1 Mekanisme Dasar

PostgreSQL MVCC = setiap transaksi liat **snapshot** data di titik waktu tertentu.

```
INSERT → tuple baru dengan xmin = current_xid
UPDATE → mark old tuple as dead (xmax), insert new tuple
DELETE → mark tuple as dead (xmax)
```

**Konsekuensi:**

- UPDATE = INSERT + DELETE (mark) → bloat
- VACUUM = bersihin dead tuples
- Long-running transaction = bloat gak kevacuum

### 2.2 Isolation Levels & Anomalies

| Level            | Dirty Read | Non-Repeatable Read | Phantom Read |
| ---------------- | ---------- | ------------------- | ------------ |
| Read Uncommitted | ❌         | ❌                  | ❌           |
| Read Committed   | ✅         | ❌                  | ❌           |
| Repeatable Read  | ✅         | ✅                  | ❌           |
| Serializable     | ✅         | ✅                  | ✅           |

**PostgreSQL default:** Read Committed. Tapi buat financial transaction, pake Serializable.

### 2.3 Query Planning 101

```
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT ...
```

**Yang dicari:**

- **Seq Scan** — tanda gak ada index, atau query selectivity rendah
- **Index Scan** — pake index, balikin row langsung
- **Bitmap Heap Scan** — kombinasi multiple index → bitmap AND/OR
- **Nested Loop vs Hash Join vs Merge Join** — beda O(n²) vs O(n log n)

**Ponytail:** Catatan ini belum bahas partitioning, sharding, dan replication internals. Tambahin kalau udah deploy multi-node PostgreSQL.

---

## 🔗 Koneksi

- [[postgresql-administrasi-backup]] — operasional, catatan ini teori di belakangnya
- [[postgresql-performance-triage]] — praktik troubleshooting, catatan ini explain kenapa
- [[ddia-kleppmann]] — part II (storage & retrieval) = teori database internals
- [[data-engineering]] — pipeline data, butuh paham indexing buat performance
