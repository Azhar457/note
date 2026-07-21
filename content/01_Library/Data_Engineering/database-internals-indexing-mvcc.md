---
title: "Database Internals: Indexing, MVCC & Query Planning"
tags:
  - database
  - postgresql
  - indexing
  - mvcc
  - query-optimization
  - internals
  - library
aliases:
  - db-indexing-deepdive
  - query-planning-execution
  - mvcc-concurrency-control
created: "2026-07-15"
updated: "2026-07-15"
status: draft
cssclasses:
  - wide-table
---

# 🗄️ Database Internals: Indexing, MVCC & Query Planning

> Vault udah punya [[postgresql-admin-backup]] dan [[postgresql-performance-triage]] — dua-duanya fokus ke operasional: backup, restore, troubleshooting slow query. Tapi belum ada yang bedah **apa yang terjadi di dalam database** ketika lo jalanin `CREATE INDEX`, `UPDATE`, atau `EXPLAIN ANALYZE`. Catatan ini adalah layer fundamental yang ngejelasin kenapa index B-Tree cocok untuk range query tapi jelek untuk JSONB, kenapa UPDATE lebih mahal dari INSERT (akibat MVCC), dan bagaimana query planner milih antara Nested Loop, Hash Join, atau Merge Join. Tanpa ini, lo cuma bisa bilang "query lambat, bikin index" tanpa ngerti index mana yang tepat untuk workload lo.

> [!info] Posisi di Vault
> Ini adalah **teori di belakang** [[postgresql-admin-backup]] dan [[postgresql-performance-triage]]. Baca ini untuk paham kenapa operasional PostgreSQL bekerja seperti itu. Juga terhubung dengan [[ddia-kleppmann]] (Part II — storage & retrieval) dan [[data-engineering]] (pipeline data).

---

## Daftar Isi

- [[#1. Storage Models — Heap vs LSM vs B-Tree]]
- [[#2. Indexing Deep Dive — B-Tree GiST GIN BRIN]]
- [[#3. Query Planning & Execution]]
- [[#4. Join Strategies — Nested Loop vs Hash Join vs Merge Join]]
- [[#5. MVCC — Mekanisme Concurrency di PostgreSQL]]
- [[#6. Isolation Levels & Race Conditions]]
- [[#7. Vacuum, Bloat & Autovacuum Tuning]]
- [[#8. Query Optimization Patterns]]
- [[#9. Tools untuk Database Internals]]
- [[#🔗 Koneksi ke Catatan Lain]]
- [[#✅ Checklist]]
- [[#Roadmap Belajar]]

---

## 1. Storage Models — Heap vs LSM vs B-Tree

### 1.1 Heap Storage (PostgreSQL)

PostgreSQL menggunakan **heap storage** — data disimpan dalam blok (8KB default), tanpa urutan tertentu. Index adalah struktur terpisah yang menunjuk ke heap:

```
Relation (table):
  ┌──────┬──────┬──────┬──────┬──────┬──────┐
  │Block0│Block1│Block2│Block3│Block4│Block5│...
  └──┬───┴──┬───┴──┬───┴──┬───┴──┬───┴──┬───┘
     │      │      │      │      │      │
  ┌──▼──┐┌─▼───┐┌─▼───┐┌─▼───┐┌─▼───┐┌─▼───┐
  │Row1 ││Row2 ││Row3 ││Row4 ││Row5 ││Row6 │
  │Row2 ││Row5 ││     ││     ││     ││     │  ← bisa ada free space
  │     ││     ││     ││     ││     ││     │
  └─────┘└─────┘└─────┘└─────┘└─────┘└─────┘

Index (B-Tree):
  [Key → (Block, Offset)]
  [1 → (0,0)] [2 → (0,1)] [3 → (1,0)] [4 → (1,1)] [5 → (2,0)] [6 → (2,1)]
```

**Konsekuensi:**

- INSERT cepat — tulis di blok mana aja yang ada free space
- UPDATE mahal — mark row as dead (xmax), tulis row baru di blok lain
- Sequential scan — baca semua blok, filter yang visible (via MVCC)
- Index scan — cari di index, fetch dari heap via TID (tuple ID = Block + Offset)

### 1.2 LSM-Tree (LevelDB, RocksDB, Cassandra)

LSM-Tree = Log-Structured Merge Tree. Write-optimized dengan mengorbankan read performance:

```
Write Path:
  MemTable (in-memory, sorted) → immutable → flush to SSTable Level 0
                                                      ↓
                                        Levels 1, 2, 3... (major compaction)

Read Path:
  Check MemTable → Level 0 SSTables → Level 1, 2, 3... (merge)

Compaction:
  Minor: flush MemTable ke SSTable (cepat)
  Major: merge SSTable level N dengan N+1 (lambat, I/O intensive)
```

| Aspek               | B-Tree (PostgreSQL)                 | LSM-Tree (Cassandra)            |
| ------------------- | ----------------------------------- | ------------------------------- |
| Write throughput    | 🟡 Random I/O ke heap               | 🟢 Sequential write ke SSTable  |
| Read (point lookup) | 🟢 O(log N) via index               | 🟡 Check multiple SSTables      |
| Read (range scan)   | 🟢 B-Tree leaf node linked list     | 🟡 Bloom filter + merge         |
| Space amplification | 🟡 Pages dengan dead tuples (bloat) | 🟢 SSTable immutable, compacted |
| Write amplification | 🟢 Minimal (update langsung)        | 🟡 Compaction I/O               |

### 1.3 Kapan Pilih Yang Mana?

```
B-Tree → OLTP, banyak UPDATE/DELETE, range query penting
LSM-Tree → Write-heavy workloads, time-series data, log ingestion
Columnar → Analytical queries (OLAP), aggregasi, read-only historis
```

---

## 2. Indexing Deep Dive — B-Tree, GiST, GIN, BRIN

### 2.1 B-Tree — Default PostgreSQL Index

**Struktur:**

```
Root Page (1 page):
  [50, 100]
  /    |    \
Internal Pages:
  [10, 30]  [60, 80]  [110, 130]
  /    |    /   |    /    |    \
Leaf Pages (doubly linked):
  [1,5,10] ↔ [15,20,25,30] ↔ [35,40,45,50] ↔ ...
```

**Karakteristik penting:**

- **Height = 3-4** untuk tabel dengan miliaran baris (karena branching factor tinggi)
- **Leaf nodes** adalah doubly linked list — range scan pindah dari leaf ke leaf via pointer (gak perlu balik ke root)
- **Page size**: 8KB default. Branching factor ≈ (page_size - header) / (key_size + pointer_size) ≈ 200-300 untuk key 32 byte
- **Write amplification**: INSERT trigger page split jika leaf page penuh. Split = 1 page → 2 pages + update parent pointer (≈ 3-4 pages I/O)

```sql
-- Melihat struktur index
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT
);

-- Index B-Tree otomatis untuk PRIMARY KEY
-- Index tambahan:
CREATE INDEX idx_users_email ON users(email);

-- Cek ukuran index
SELECT
    pg_size_pretty(pg_relation_size('users')) AS table_size,
    pg_size_pretty(pg_relation_size('users_pkey')) AS pk_index_size,
    pg_size_pretty(pg_relation_size('idx_users_email')) AS email_index_size;

-- Melihat page-level statistik
SELECT * FROM pageinspect.bt_metap('users_pkey');
SELECT * FROM pageinspect.bt_page_stats('users_pkey', 1);
```

### 2.2 Composite Index — Multicolumn

```sql
CREATE INDEX idx_users_lastname_firstname ON users(last_name, first_name);

-- Query yang bisa pake index ini:
SELECT * FROM users WHERE last_name = 'Smith';                    -- ✅ Prefix
SELECT * FROM users WHERE last_name = 'Smith' AND first_name = 'J'; -- ✅ Full
SELECT * FROM users WHERE last_name LIKE 'Smi%';                  -- ✅ Range pada prefix
SELECT * FROM users WHERE first_name = 'J';                       -- ❌ Bukan prefix (gak efisien)

-- Index on expression:
CREATE INDEX idx_users_lower_email ON users(LOWER(email));
SELECT * FROM users WHERE LOWER(email) = 'admin@example.com';     -- ✅ Pake index
```

**Ponytail:** Index `last_name, first_name, middle_name` bisa serve query yang filter di `last_name`, `last_name + first_name`, atau ketiganya. Tapi gak bisa serve yang filter `first_name` aja atau `first_name + middle_name`. Pahami **leftmost prefix rule**.

### 2.3 Partial Index — Index Hanya untuk Data Tertentu

```sql
-- Index yang cuma mencakup baris dengan status = 'active'
CREATE INDEX idx_orders_active ON orders(order_date)
    WHERE status = 'active';

-- Berguna untuk:
-- 1. 99% query hanya akses orders active
-- 2. Index jadi jauh lebih kecil
-- 3. INSERT/UPDATE ke orders non-active gak kena index maintenance

-- Query yang bisa:
SELECT * FROM orders WHERE status = 'active' AND order_date > '2026-01-01';  -- ✅
SELECT * FROM orders WHERE status = 'pending';                                -- ❌ (status != 'active')
```

### 2.4 GiST, GIN, BRIN — Specialized Index

**GiST (Generalized Search Tree):**

```sql
-- Full-text search
CREATE INDEX idx_articles_fts ON articles USING GIN(to_tsvector('english', body));
SELECT * FROM articles
WHERE to_tsvector('english', body) @@ to_tsquery('english', 'database & indexing');

-- Geometri (PostGIS)
CREATE INDEX idx_locations ON places USING GIST(location);
SELECT * FROM places
WHERE location <@ box '(10,10,20,20)';  -- Points within a box
```

**GIN (Generalized Inverted Index):**

```sql
-- JSONB indexing
CREATE TABLE events (data JSONB);
CREATE INDEX idx_events_gin ON events USING GIN(data);

-- Query yang bisa pake GIN index:
SELECT * FROM events WHERE data @> '{"type": "login"}';   -- ✅ contains
SELECT * FROM events WHERE data ? 'ip_address';             -- ✅ key exists
SELECT * FROM events WHERE data ?| ARRAY['email', 'phone']; -- ✅ any key exists

-- Lebih efisien dengan jsonb_path_ops:
CREATE INDEX idx_events_gin_ops ON events USING GIN(data jsonb_path_ops);
-- 2-3x lebih kecil, tapi hanya support @> operator
```

**BRIN (Block Range Index) — untuk time-series:**

```sql
-- BRIN index — ideal untuk data yang berurutan (time-series)
CREATE INDEX idx_logs_created_at ON logs USING BRIN(created_at)
    WITH (pages_per_range = 32);  -- 32 blocks per range

-- Ukuran: BRIN ≈ 0.1% dari ukuran table
-- B-Tree ≈ 30% dari ukuran table
-- Untuk logs table 100GB: BRIN = 100MB vs B-Tree = 30GB

-- Query yang efisien dengan BRIN:
SELECT * FROM logs WHERE created_at >= '2026-07-01' AND created_at < '2026-07-02';
```

### 2.5 Perbandingan Index Types

| Type       | Ukuran              | Write Overhead | Query Types                                | Use Case                    |
| ---------- | ------------------- | -------------- | ------------------------------------------ | --------------------------- |
| **B-Tree** | 30% dari table      | Moderate       | =, <, >, BETWEEN, ORDER BY, LIKE 'prefix%' | General purpose (90% kasus) |
| **Hash**   | Kecil               | Rendah         | = only                                     | Sama jarang dipake di PG    |
| **GiST**   | Besar               | Tinggi         | Full-text, geometri, range overlap         | Spatial, FTS                |
| **GIN**    | Besar               | Tinggi         | JSONB contains, array overlap, tsvector    | JSONB, full-text, arrays    |
| **BRIN**   | Sangat kecil (0.1%) | Sangat rendah  | Range scan (data correlated)               | Time-series, logs           |

---

## 3. Query Planning & Execution

### 3.1 Query Lifecycle

```
SQL Query → Parser → Rewriter → Planner → Executor → Result
              ↓          ↓          ↓         ↓
           Parse tree  Rewritten   Plan tree  Execution
                        tree        (costs)   (loops)
```

### 3.2 EXPLAIN Plan — Cara Baca

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT * FROM orders
    JOIN customers ON orders.customer_id = customers.id
    WHERE orders.total > 1000
    ORDER BY orders.created_at DESC
    LIMIT 10;

-- Output (simplified):
--                                                                      QUERY PLAN
-- ────────────────────────────────────────────────────────────────────────────────────────────
-- Limit  (cost=12.34..45.67 rows=10 width=120) (actual time=0.123..0.456 rows=10 loops=1)
--   ->  Sort  (cost=12.34..45.67 rows=1000 width=120) (actual time=0.123..0.456 rows=10 loops=1)
--         Sort Key: orders.created_at DESC
--         Sort Method: top-N heapsort  Memory: 25kB
--         ->  Hash Join  (cost=8.90..42.10 rows=1000 width=120) (actual time=0.050..0.200 rows=1000 loops=1)
--               Hash Cond: (orders.customer_id = customers.id)
--               ->  Seq Scan on orders  (cost=0.00..30.40 rows=1000 width=80) (actual time=0.010..0.100 rows=1000 loops=1)
--                     Filter: (total > 1000)
--                     Rows Removed by Filter: 4000
--               ->  Hash  (cost=6.40..6.40 rows=200 width=40) (actual time=0.020..0.020 rows=200 loops=1)
--                     ->  Seq Scan on customers  (cost=0.00..6.40 rows=200 width=40) (actual time=0.005..0.015 rows=200 loops=1)
```

**Cara membaca:**

- Baca dari **dalam ke luar** (children → parent)
- `cost=12.34..45.67` = estimated start-up..total cost (unit = arbitrary, biasanya page I/O + CPU)
- `actual time=0.123..0.456` = real execution time (ms)
- `rows=10` vs `rows=1000` — estimated vs actual. Gap besar = planner statistics outdated
- `loops=1` — berapa kali node ini di-execute (penting untuk Nested Loop!)
- `Buffers: shared hit=42 read=8` — page cache hit vs disk read

### 3.3 Plan Node Types

| Node                 | Ketika Muncul                                                                           |
| -------------------- | --------------------------------------------------------------------------------------- |
| **Seq Scan**         | Full table scan — biasanya karena gak ada index, atau selectivity terlalu rendah (< 5%) |
| **Index Scan**       | Pake index → fetch dari heap. Cepat kalo selectivity tinggi                             |
| **Index Only Scan**  | Semua data ada di index (covering index) — tanpa fetch heap. Paling cepat               |
| **Bitmap Heap Scan** | Kombinasi index + bitmap. Berguna untuk kombinasi beberapa index                        |
| **Nested Loop**      | Untuk join kecil. O(n * m) — bagus kalo salah satu tabel kecil                          |
| **Hash Join**        | Hash satu tabel → probe. O(n + m) — bagus untuk equi-join                               |
| **Merge Join**       | Sort + merge. O(n log n + m log m) — bagus untuk data yang sudah sorted                 |
| **Sort**             | ORDER BY / DISTINCT / Merge Join                                                        |

### 3.4 Statistik Planner

```sql
-- Cek statistik tabel
SELECT
    relname,
    n_live_tup,        -- jumlah row visible
    n_dead_tup,        -- jumlah row dead (bloat indicator)
    last_analyze,      -- kapan terakhir ANALYZE
    last_autovacuum,   -- kapan terakhir autovacuum
    seq_scan,          -- berapa kali sequential scan
    seq_tup_read,      -- total row dibaca via seq scan
    idx_scan,          -- berapa kali index scan
    idx_tup_fetch      -- total row diambil via index
FROM pg_stat_user_tables
WHERE relname = 'orders';

-- Update statistik
ANALYZE orders;

-- Set target statistik (default 100)
ALTER TABLE orders ALTER COLUMN total SET STATISTICS 1000;
-- Lebih tinggi = lebih akurat (tapi ANALYZE lebih lambat)
```

---

## 4. Join Strategies — Nested Loop vs Hash Join vs Merge Join

### 4.1 Nested Loop Join

```pseudo
for each row in outer_table:
    for each row in inner_table:
        if match condition:
            emit row

Cost: O(n * m) — worst case
      O(n * log m) — dengan index di inner table
```

**Kapan efektif:**

- Satu tabel sangat kecil (< 100 baris)
- Ada index unik di inner table yang bisa di-index lookup
- Query dengan LIMIT yang kecil

```sql
-- PostgreSQL akan pake Nested Loop secara otomatis
-- Contoh: 10 customers × 1000 orders (with index on orders.customer_id)
EXPLAIN (ANALYZE)
SELECT * FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 42;
-- Output: Nested Loop → Index Scan on orders (by customer_id)
```

### 4.2 Hash Join

```pseudo
1. Hash inner table → build hash table (in memory)
2. For each row in outer table:
       probe hash table → if match, emit row

Cost: O(n + m) — linear, more predictable
      Memory: cukup untuk hold hash table di memory
```

**Kapan efektif:**

- Equi-join (`=`) — tidak bekerja untuk range join
- Salah satu tabel cukup kecil untuk hash table di memory
- Data tidak sorted (tidak perlu expensive sort)

```sql
-- Pilih hash join secara eksplisit (jarang perlu)
SET enable_nestloop = off;
EXPLAIN SELECT * FROM orders JOIN customers ON orders.customer_id = customers.id;
```

### 4.3 Merge Join

```pseudo
1. Sort both tables by join key
2. Merge like merge sort: iterate both, advance pointer of smaller
   → single pass if both already sorted

Cost: O(n log n + m log m) — sorting dominant
      O(n + m) — jika sudah sorted
```

**Kapan efektif:**

- Data sudah sorted (misal oleh ORDER BY yang sama)
- Range join (`>` , `<`, `BETWEEN`)
- Large tables yang bisa di-sort dalam memory

### 4.4 Perbandingan Join Strategies

| Join            | Best Case         | Worst Case             | Memory               | Use Case                         |
| --------------- | ----------------- | ---------------------- | -------------------- | -------------------------------- |
| **Nested Loop** | O(n) via index    | O(n*m)                 | Minimal              | One small table, index available |
| **Hash Join**   | O(n+m)            | O(n+m) + disk spilling | Hash table in memory | Equi-join, mid-size tables       |
| **Merge Join**  | O(n+m) pre-sorted | O(n log n + m log m)   | Sort buffer          | Range join, large sorted tables  |

---

## 5. MVCC — Mekanisme Concurrency di PostgreSQL

### 5.1 Bagaimana MVCC Bekerja

PostgreSQL MVCC (Multiversion Concurrency Control) = **setiap transaksi melihat snapshot data di titik waktu tertentu**. Bukan "lock data", tapi "create version baru":

```
Heap Page:
  ┌──────────────────────────────────────────────────┐
  │ [Tuple 1] xmin=100 xmax=200 [data: "Alice"]      │ ← visible untuk txid 100-199
  │ [Tuple 2] xmin=101 xmax=0    [data: "Bob"]        │ ← visible dari txid 101+
  │ [Tuple 3] xmin=200 xmax=0    [data: "Charlie"]    │ ← visible dari txid 200+ (baru di-INSERT)
  │ [Tuple 4] xmin=201 xmax=202  [data: "Diana"]      │ ← visible untuk txid 201 saja
  │ [Free Space]                                       │
  └──────────────────────────────────────────────────┘
```

**Bagaimana UPDATE bekerja:**

```
Step 1: UPDATE users SET name = 'Alice Updated' WHERE id = 1;
  - Original row: xmin=100, xmax=CURRENT_TXID  ← "dead" untuk txid berikutnya
  - New row:      xmin=CURRENT_TXID, xmax=0     ← visible hanya untuk txid ini sampai commit

Step 2: COMMIT;
  - Snapshot baru lihat row baru
  - Row lama tetap ada (dead tuple) sampai VACUUM membersihkannya
```

### 5.2 Snapshot Isolation

Setiap transaksi mendapatkan **snapshot** — daftar transaksi aktif saat first query:

```sql
-- Lihat snapshot yang aktif
SELECT txid_current(), txid_snapshot_xmin(txid_current_snapshot()),
       txid_snapshot_xmax(txid_current_snapshot());
```

**Visibility rules:**

- xmin < txid_snapshot_xmin → visible (sudah committed sebelum snapshot)
- xmin in snapshot → NOT visible (masih running saat snapshot)
- xmax < txid_snapshot_xmin → deleted (tidak visible)
- xmax in snapshot → visible (delete belum committed)

### 5.3 Hot Standby & Conflicts

PostgreSQL streaming replication menggunakan MVCC untuk Hot Standby:

```
Primary: INSERT INTO users VALUES (1, 'Alice');  -- txid 100
Secondary: SELECT * FROM users WHERE id = 1;      -- txid 100 masih in-progress → skip (gak visible)

Setelah txid 100 commit di primary:
Secondary: SELECT * FROM users WHERE id = 1;      → visible (xmin < snapshot)
```

**Conflict scenarios:**

- `VACUUM` di primary → remove dead tuples
- `VACUUM` di secondary → wait for queries to finish
- Long-running query di secondary = blokir vacuum

---

## 6. Isolation Levels & Race Conditions

### 6.1 Definisi Isolation Levels

| Level            | Dirty Read | Non-Repeatable Read | Phantom Read                        | Serialization Anomaly |
| ---------------- | ---------- | ------------------- | ----------------------------------- | --------------------- |
| Read Uncommitted | Mungkin    | Mungkin             | Mungkin                             | Mungkin               |
| Read Committed   | ✅ Tidak   | Mungkin             | Mungkin                             | Mungkin               |
| Repeatable Read  | ✅ Tidak   | ✅ Tidak            | Mungkin di SQL std., ✅ Tidak di PG | Mungkin               |
| Serializable     | ✅ Tidak   | ✅ Tidak            | ✅ Tidak                            | ✅ Tidak              |

**Catatan PostgreSQL:** Read Uncommitted = Read Committed (PG gak support dirty read).

### 6.2 Race Conditions — Contoh Real

**Lost Update:**

```sql
-- Session A                          -- Session B
BEGIN;                                BEGIN;
SELECT balance FROM accounts          SELECT balance FROM accounts
  WHERE id = 1; -- balance = 100        WHERE id = 1; -- balance = 100
                                      UPDATE accounts SET balance = 200
                                        WHERE id = 1;
UPDATE accounts SET balance = 150     COMMIT;
  WHERE id = 1; -- based on old 100!
COMMIT;
-- Result: balance = 150 (kehilangan update B → 200)
```

**Solusi dengan `SELECT ... FOR UPDATE`:**

```sql
BEGIN;
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;  -- Lock baris!
-- Session B akan menunggu sampai session A commit
UPDATE accounts SET balance = balance + 50 WHERE id = 1;
COMMIT;
```

**Write Skew (Paling Subtle):**

```sql
-- Dua dokter on-call, aturan: minimal satu harus available
-- Session A                          -- Session B
BEGIN;                                BEGIN;
SELECT count(*) FROM on_call          SELECT count(*) FROM on_call
  WHERE available = true;               WHERE available = true;
  -- count = 2                           -- count = 2
UPDATE on_call SET available = false  UPDATE on_call SET available = false
  WHERE doctor_id = 1;                  WHERE doctor_id = 2;
COMMIT;                               COMMIT;
-- Result: no doctor available! (keduanya lihat count=2)
```

**Solusi: Serializable isolation + retry logic:**

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Akan detect write skew → salah satu transaksi dapat:
-- ERROR: could not serialize access due to read/write dependencies
-- Lalu retry
```

### 6.3 When to Use Which

| Isolation       | Latency | Correctness | Use Case                    |
| --------------- | ------- | ----------- | --------------------------- |
| Read Committed  | Rendah  | Lemah       | Dashboard read-only, logs   |
| Repeatable Read | Sedang  | Moderate    | Reporting, analytics        |
| Serializable    | Tinggi  | Guaranteed  | Financial, inventory, kuota |

---

## 7. Vacuum, Bloat & Autovacuum Tuning

### 7.1 Dead Tuples & Bloat

Setiap UPDATE/DELETE meninggalkan dead tuple. Tanpa VACUUM, tabel membengkak:

```
Before VACUUM:
  ┌────────────────────────────────┐
  │ [Alice (dead)] [Bob (dead)]    │
  │ [Charlie] [Diana]              │
  │ [Eve (dead)]                   │
  └────────────────────────────────┘
  Table size: 4 pages (dengan 3 dead)

After VACUUM:
  ┌────────────────────────────────┐
  │ [Charlie] [Diana] [Free]       │
  │ [Free] [Free] [Free]           │
  └────────────────────────────────┘
  Table size: 2 pages (space tidak dikembalikan ke OS!)
```

**Space reclamation:** VACUUM hanya menandai free space dalam table file. Ukuran file tidak berkurang. Gunakan `VACUUM FULL` (table-level lock) atau `pg_repack` untuk return space ke OS.

### 7.2 Autovacuum Configuration

```sql
-- Default settings (cek dengan SHOW)
SHOW autovacuum_vacuum_threshold;        -- 50 (base threshold)
SHOW autovacuum_vacuum_scale_factor;      -- 0.2 (20% dari row count)
SHOW autovacuum_vacuum_cost_limit;        -- -1 (pakai vacuum_cost_limit)
SHOW autovacuum_naptime;                  -- 1min

-- Untuk tabel besar, scale factor 0.2 = 20% dari 100M rows = 20M dead tuples baru trigger vacuum
-- Ini terlalu lambat! Sesuaikan per tabel:

ALTER TABLE orders SET (autovacuum_vacuum_scale_factor = 0.01,   -- 1%
                        autovacuum_vacuum_threshold = 1000,      -- base 1000
                        autovacuum_vacuum_cost_limit = 1000);    -- lebih agresif
```

### 7.3 Monitoring Bloat

```sql
-- Estimasi bloat per tabel
SELECT
    schemaname || '.' || relname AS table_name,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    n_dead_tup,
    n_live_tup,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup, 0), 2) AS dead_pct,
    last_autovacuum,
    vacuum_count
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;

-- Tabel yang butuh VACUUM segera:
-- dead_pct > 20% dan n_dead_tup > 100000
```

---

## 8. Query Optimization Patterns

### 8.1 Index Maintenance

```sql
-- Rebuild index (tanpa lock, concurrent)
REINDEX INDEX CONCURRENTLY idx_orders_customer_id;

-- Cek index size vs table size
SELECT
    i.relname AS index_name,
    pg_size_pretty(pg_relation_size(i.oid)) AS index_size,
    pg_size_pretty(pg_relation_size(t.oid)) AS table_size,
    ROUND(100.0 * pg_relation_size(i.oid) / NULLIF(pg_relation_size(t.oid), 0), 2) AS ratio
FROM pg_class i
JOIN pg_index ix ON i.oid = ix.indexrelid
JOIN pg_class t ON ix.indrelid = t.oid
WHERE t.relname = 'orders';
```

### 8.2 Common Optimization Patterns

**Pattern 1: Covering Index**

```sql
-- Query: SELECT id, name, email FROM users WHERE status = 'active';
-- Create index yang cover semua kolom:
CREATE INDEX idx_users_status_covering ON users(status) INCLUDE (name, email);
-- Index Only Scan → tanpa fetch heap
```

**Pattern 2: Partial Index untuk Queue Pattern**

```sql
-- Process queue: SELECT * FROM jobs WHERE status = 'pending' ORDER BY created_at;
CREATE INDEX idx_jobs_pending ON jobs(created_at) WHERE status = 'pending';
-- Index cuma berisi baris pending → kecil, cepat
```

**Pattern 3: Partitioning untuk Time-Series**

```sql
-- Partition by month
CREATE TABLE orders_partitioned (LIKE orders INCLUDING ALL)
    PARTITION BY RANGE (created_at);

CREATE TABLE orders_2026_07 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE orders_2026_08 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

-- Query planner bisa pruning: hanya scan partition yang relevan
-- Berguna untuk data yang di-DELETE/di-ARCHIVE per bulan
```

### 8.3 Query Tuning Workflow

```
1. Temukan slow query (pg_stat_statements, slow query log)
2. EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
3. Identifikasi node paling mahal (Seq Scan? Nested Loop?)
4. Cek:
   - Apakah index ada? (missing index?)
   - Statistik outdated? (perlu ANALYZE?)
   - Parameter binding vs literal? (bind variable?)
5. Buat/ubah index
6. Test dengan EXPLAIN
7. Repeat

Gunakan [[postgresql-performance-triage]] untuk checklist troubleshooting.
```

---

## 9. Tools untuk Database Internals

| Tool                   | Fungsi                                         |
| ---------------------- | ---------------------------------------------- |
| `pg_stat_statements`   | Tracking query performance historis            |
| `pg_stat_user_tables`  | Statistik tabel (live/dead tuples, scan count) |
| `pg_stat_user_indexes` | Index usage (scan count, tuple fetch)          |
| `pageinspect`          | Melihat page-level data (blok, tuple)          |
| `pg_buffercache`       | Melihat shared buffer cache                    |
| `pg_repack`            | Online table rebuild (tanpa lock, Hapus bloat) |
| `explain.depesz.com`   | Visual EXPLAIN analyzer                        |
| `pgMustard`            | EXPLAIN analyzer dengan saran index            |
| `pganalyze`            | Performance monitoring SaaS                    |

---

## 🔗 Koneksi ke Catatan Lain

- [[postgresql-admin-backup]] — backup/restore, operasional sehari-hari
- [[postgresql-performance-triage]] — troubleshooting slow query, praktik
- [[ddia-kleppmann]] — Part II storage & retrieval = teori database internals
- [[data-engineering]] — pipeline data, butuh paham indexing untuk performance
- [[software-engineering]] — application design yang butuh database optimization
- [[csapp-bryant-ohallaron]] — memory hierarchy (cache, disk) mempengaruhi database performance

---

## ✅ Checklist

- [ ] Paham B-Tree vs LSM-Tree trade-off buat workload yang beda
- [ ] Bisa jelasin MVCC: bagaimana UPDATE, DELETE, dan VACUUM bekerja
- [ ] Bisa baca EXPLAIN (ANALYZE) dan identifikasi bottleneck
- [ ] Paham kapan Nested Loop better dari Hash Join dan sebaliknya
- [ ] Bisa bedain index scan vs bitmap heap scan vs seq scan
- [ ] Paham isolation levels + race conditions (lost update, write skew)
- [ ] Bisa setup autovacuum tuning untuk tabel besar
- [ ] Paham perbedaan B-Tree, GIN, GiST, BRIN — kapan pake yang mana
- [ ] Bisa design composite index berdasarkan pola query

---

## Roadmap Belajar

```
HARI 1: Storage & Indexing
  - Baca dokumen ini sampai selesai
  - Setup tabel dengan berbagai tipe index, bandingkan size
  - Test EXPLAIN untuk query sederhana vs kompleks

HARI 2: MVCC & Concurrency
  - Simulasi race condition dengan 2 session
  - Test isolation levels, lihat perbedaan behavior
  - Monitor dead tuples di pg_stat_user_tables

HARI 3: Query Optimization
  - Ambil slow query dari pg_stat_statements
  - Analisa dengan EXPLAIN, buat index yang tepat
  - Ukur improvement (execution time, buffer hits)

HARI 4: Advanced Indexing
  - Setup BRIN untuk time-series data
  - Test partial index untuk queue pattern
  - Setup GIN index untuk JSONB, test query performance

HARI 5: Bloat & Vacuum
  - Simulasi bloat dengan UPDATE/DELETE massal
  - Tuning autovacuum
  - Test pg_repack untuk online table rebuild
```

> [!warning] Bottom Line
> Database internals bukan sekadar teori akademik — ini **determines query performance** di production. Index B-Tree yang salah bisa bikin query yang tadinya 1ms jadi 10 detik. MVCC bloat bisa bikin tabel 10GB membengkak jadi 100GB tanpa data baru. Query planner yang pake Nested Loop saat seharusnya Hash Join bisa bikin server collapse. Lo gak perlu jadi DBA, tapi lo perlu paham dasar-dasar ini agar bisa debugging slow query tanpa trial-and-error.

> [!tip] Lanjutan
> Catatan ini belum mencakup distributed databases (Cassandra, CockroachDB, Spanner), vector databases untuk AI embeddings, dan query optimization untuk data warehouse (columnar, materialized aggregates). Baca [[ddia-kleppmann]] untuk distributed database theory.
