---
title: "Database Engineering — Schema Design, Sharding, Replication & Data Modeling"
tags:
  - database
  - schema-design
  - sharding
  - replication
  - data-modeling
  - library
aliases:
  - "database-engineering-guide"
  - "schema-sharding-replication"
  - "db-design-patterns"
created: "2026-07-19"
updated: "2026-07-19"
status: draft
cssclasses:
  - wide-table
---

# 🗄️ Database Engineering — Schema Design, Sharding, Replication & Data Modeling

> Vault udah punya [[database-internals-indexing-mvcc]] (storage engine & indexing internals), [[postgresql-admin-backup]] (operasional backup/restore), dan [[postgresql-performance-triage]] (slow query debugging). Tapi belum ada yang cover **sisi engineering dari database — bagaimana mendesain schema, kapan normalisasi vs denormalisasi, strategi sharding dan replication yang tepat, serta data modeling patterns untuk berbagai use case**. Catatan ini adalah jembatan antara teori database internals dan praktik production engineering.

> [!info] Posisi di Vault
> Ini adalah **engineering layer** di atas [[database-internals-indexing-mvcc]] (teori) dan [[postgresql-admin-backup]] (ops). Terkait juga dengan [[distributed-systems]] (replication & partitioning theory), [[data-engineering]] (pipeline & warehouse), [[ddia-kleppmann]] (distributed data), dan [[software-engineering]] (application-level database patterns).

---

## Daftar Isi

- [[#1. Normalisasi — 1NF sampai 6NF, Kapan Berhenti]]
- [[#2. Data Modeling Patterns — Inheritance, Tree, Graph]]
- [[#3. Sharding Strategies — Hash, Range, Directory]]
- [[#4. Replication Topologies — Leader, Multi-Leader, Leaderless]]
- [[#5. Index Design — Covering, Partial, Expression, Functional]]
- [[#6. Constraint & Validation — DB vs App Level]]
- [[#7. Migration Strategies — Zero-Downtime Schema Change]]
- [[#8. Time-Series Data Modeling]]
- [[#9. Multi-Tenant Schema — Isolasi per Tenant]]
- [[#10. Versioning Data — SCD, Event Sourcing]]
- [[🔗 Koneksi ke Catatan Lain]]
- [[✅ Checklist]]
- [[Roadmap Belajar]]

---

## 1. Normalisasi — 1NF sampai 6NF, Kapan Berhenti

### 1.1 Definisi Formal

Normalisasi adalah proses menghilangkan **data redundancy** dan **anomaly** (insertion, update, deletion) melalui dekomposisi relation yang dijamin **lossless join**. Dasar matematisnya adalah **functional dependency** (FD) theory dari E.F. Codd (1970).

### 1.2 Normal Forms Progression

```
1NF: Atomic values — setiap kolom punya satu nilai
2NF: 1NF + semua non-key kolom fully dependent pada seluruh primary key
3NF: 2NF + no transitive dependency (non-key → non-key)
BCNF: 3NF + setiap determinant adalah candidate key
4NF: BCNF + no multi-valued dependency
5NF: 4NF + every join dependency implied by candidate keys
6NF: 5NF + no nontrivial join dependencies at all (decompose sampai irreducible)
```

### 1.3 Tabel Anomali per Normal Form

| NF   | Problem yang Disolve              | Contoh                                                                           |
| :--- | :-------------------------------- | :------------------------------------------------------------------------------- |
| 1NF  | Repeated group, non-atomic        | Column `phone_numbers` berisi comma-separated                                    |
| 2NF  | Partial dependency (composite PK) | `(order_id, product_id) → product_name` — nama produk dependen ke product_id aja |
| 3NF  | Transitive dependency             | `employee_id → department_id → department_name`                                  |
| BCNF | Overlapping candidate keys        | Dua candidate key saling bertumpuk                                               |
| 4NF  | Multi-valued fact                 | Satu entity punya dua fakta independent (skill + language)                       |
| 5NF  | Join dependency cycle             | Tiga tabel yang selalu perlu di-join balik                                       |

### 1.4 Kapan Berhenti Normalisasi?

```
3NF/BCNF → Default untuk 95% aplikasi OLTP
  4NF → Hanya kalau ada multi-valued dependencies nyata
  5NF/6NF → Analytical/data warehouse (hampir gak pernah di OLTP)

Denormalisasi dilakukan dengan sengaja, bukan karena males normalize:
  - Performance: report query butuh JOIN yang terlalu mahal
  - Read-heavy workload: cache redundancy (redundan dengan sadar)
  - Time-series: flat table lebih efisien untuk range scan
```

### 1.5 Contoh Praktik: E-commerce

```sql
-- Unnormalized (avoid)
CREATE TABLE orders_unnormalized (
    order_id INT PRIMARY KEY,
    customer_name TEXT,
    customer_email TEXT,
    product_names TEXT,            -- comma-separated
    product_prices TEXT,
    order_total DECIMAL
);

-- 3NF / BCNF (recommended for OLTP)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_total DECIMAL NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE order_items (
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL,
    unit_price DECIMAL NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

-- Denormalized for reporting (OLAP)
CREATE TABLE order_summary_mv (
    order_id INT,
    customer_name TEXT,
    product_count INT,
    first_product TEXT,
    total DECIMAL
);
```

**Ponytail:** Jangan normalize sampe 5NF di OLTP — join complexity gak sebanding. 3NF/BCNF itu stop point. Denormalisasi cuma kalau ada **data terbukti** (benchmark) bahwa query lambat karena normalization.

---

## 2. Data Modeling Patterns — Inheritance, Tree, Graph

### 2.1 Table Inheritance Patterns (Polymorphic Data)

| Pattern                      | Implementasi                                         | Kelebihan                          | Kekurangan                               |
| :--------------------------- | :--------------------------------------------------- | :--------------------------------- | :--------------------------------------- |
| **Single Table Inheritance** | Satu tabel dengan semua kolom + `type` discriminator | Simple, no JOIN                    | Banyak kolom NULL, constraint sulit      |
| **Class Table**              | Base table + subclass tables with FK                 | Normalized, constraint enforceable | JOIN untuk query subclass                |
| **Concrete Table**           | Setiap subclass punya tabel sendiri                  | No NULL, independent               | Duplikasi kolom, UNION untuk query semua |

```sql
-- Single Table Inheritance
CREATE TABLE assets (
    asset_id INT PRIMARY KEY,
    type TEXT CHECK (type IN ('server', 'network', 'license')),
    hostname TEXT,
    ip_address INET,
    os_version TEXT,
    switch_ports INT,
    license_key TEXT,
    expiry_date DATE,
    -- type-specific kolom lainnya....
);

-- Class Table (recommended)
CREATE TABLE assets_base (
    asset_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    acquired_date DATE
);

CREATE TABLE servers (
    asset_id INT PRIMARY KEY REFERENCES assets_base(asset_id),
    hostname TEXT NOT NULL,
    ip_address INET,
    os_version TEXT
);

CREATE TABLE network_devices (
    asset_id INT PRIMARY KEY REFERENCES assets_base(asset_id),
    switch_ports INT,
    firmware_version TEXT
);
```

### 2.2 Tree/Hierarchy Patterns

| Pattern               | Query Anak    | Query Parent | Write Cost          | Use Case                |
| :-------------------- | :------------ | :----------- | :------------------ | :---------------------- |
| **Adjacency List**    | Recursive CTE | Direct FK    | Rendah              | Simple parent-child     |
| **Nested Sets**       | Range WHERE   | Range WHERE  | Tinggi (rebalance)  | Read-heavy, static tree |
| **Materialized Path** | LIKE prefix   | LIKE prefix  | Sedang              | URL path, categories    |
| **Closure Table**     | JOIN closure  | JOIN closure | Tinggi (banyak row) | Complex graph           |

```sql
-- Adjacency List (paling umum)
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id INT REFERENCES categories(category_id)
);

-- Query subtree: WHERE path LIKE 'electronics/%'
-- PostgreSQL: recursive CTE
WITH RECURSIVE cat_tree AS (
    SELECT * FROM categories WHERE category_id = 1  -- root
    UNION ALL
    SELECT c.* FROM categories c JOIN cat_tree ct ON c.parent_id = ct.category_id
)
SELECT * FROM cat_tree;

-- Materialized Path: path = 'root/electronics/computers/laptops'
CREATE TABLE categories_mp (
    category_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT NOT NULL
);
CREATE INDEX idx_cat_mp ON categories_mp USING gin(path gin_trgm_ops);
-- Query: WHERE path LIKE 'root/electronics/%'
```

---

## 3. Sharding Strategies — Hash, Range, Directory

### 3.1 Ketika Sharding Diperlukan

Sharding (horizontal partitioning) diperlukan saat **satu node gak muat data atau write throughput**. Tanda-tanda:

```
1. Write throughput > kemampuan single leader
2. Dataset > 5TB (backup/restore terlalu lama)
3. Index rebuild takes hours
4. Connection pool exhaustion dari aplikasi
```

### 3.2 Strategi Sharding

| Strategy               | Cara Kerja                   | Kelebihan                           | Kekurangan                                 |
| :--------------------- | :--------------------------- | :---------------------------------- | :----------------------------------------- |
| **Hash-based**         | `hash(shard_key) % N`        | Distribusi merata                   | Range query mahal, resharding susah        |
| **Range-based**        | `shard_key BETWEEN A AND B`  | Range scan efisien                  | Hotspot, distribusi gak merata             |
| **Directory-based**    | Lookup table → shard mapping | Fleksibel, resharding mungkin       | Single point of failure (lookup)           |
| **Consistent Hashing** | Hash ring, minimal movement  | Add/remove node minimal data pindah | Distribusi gak selalu merata (butuh vnode) |

### 3.3 Sharding Key Selection

```text
Good shard key:
  - High cardinality (banyak nilai unik)
  - Distribusi merata
  - Stabil (jarang berubah)
  - Query pattern mostly by this key

Bad shard key:
  - Boolean/status (cuma 2 nilai → cuma 2 shard)
  - Timestamp monotonik (hotspot di shard terakhir)
  - NULL-heavy

PostgreSQL example (Citus):
  SELECT create_distributed_table('orders', 'customer_id');

MongoDB example:
  sh.shardCollection("shop.orders", { customer_id: "hashed" })

Vitess (MySQL):
  VSchema: shard by customer_id hash
```

### 3.4 Resharding Challenge

```text
Old: hash(customer_id) % 4 → [shard0, shard1, shard2, shard3]
New: hash(customer_id) % 6 → [shard0..shard5]

Problem: 100% data perlu dipindah karena hash function berubah!
Solusi:
  1. Consistent hashing — cuma 1/N data pindah
  2. Double write — tulis ke old + new, migrate gradual
  3. Read old, write new — data pindah background

Production pitfall:
  - Resharding = I/O intensive = mempengaruhi production
  - Butuh throttle + monitoring
```

---

## 4. Replication Topologies — Leader, Multi-Leader, Leaderless

### 4.1 Single-Leader (Master-Slave)

```
write → Leader → WAL → Follower(s)
read  → Follower(s)

Advantages:
  - Simple, no conflict resolution
  - Linearizable writes via leader

Disadvantages:
  - Write bottleneck (single node)
  - Failover complexity (promote + catch up)
  - Replication lag → stale reads

PostgreSQL Streaming Replication:
  synchronous_standby_names = 'FIRST 1 (s1, s2)'
  → At least 1 sync standby before ack
```

### 4.2 Multi-Leader

```
write → Leader A → async replicate → Leader B → write
write → Leader B → async replicate → Leader A

Use cases:
  - Multi-DC (leader per DC)
  - Offline-first apps
  - CMS with multiple editors

Write conflict resolution:
  1. LWW (Last-Write-Wins) — risk data loss
  2. CRDT — merge automatically
  3. Custom merge logic (app-level)

CRDT types:
  - G-Counter: increment-only counter
  - PN-Counter: increment + decrement
  - LWW-Register: last-write-wins register
  - OR-Set: observed-remove set
```

### 4.3 Leaderless (Dynamo-Style)

```
write ke N node, read dari R node
W + R > N → strong consistency

Cassandra:
  N=3, W=2, R=2 → strong
  N=3, W=1, R=1 → eventual

Read repair: perbaiki node out-of-date saat read
Hinted handoff: node down → proxy write → replay
Anti-entropy: background Merkle tree comparison
```

---

## 5. Index Design — Covering, Partial, Expression

### 5.1 Indexing Trade-off Matrix

| Index Type         |       Read Speed       | Write Cost  | Disk Size  | Use Case                 |
| :----------------- | :--------------------: | :---------: | :--------: | :----------------------- |
| B-Tree             |      🟢 O(log N)       | 🟡 Moderate | 30% table  | General purpose          |
| Covering (INCLUDE) |  🟢🟢 Index-only scan  | 🟡 Moderate | 35% table  | SELECT with few columns  |
| Partial (WHERE)    |   🟢🟢 Smaller index   |   🟢 Low    | <5% table  | Filtered queries         |
| Expression         | 🟢🟢 No function scan  | 🟡 Moderate | 30% table  | `LOWER()`, `(col + col)` |
| GIN                |           🟡           |  🔴 Heavy   | 50%+ table | JSONB, full-text, array  |
| GiST               |           🟡           |  🔴 Heavy   |   Besar    | Geometry, full-text      |
| BRIN               | 🟢🟢🟢 Extremely small | 🟢 Very Low | 0.1% table | Time-series, correlated  |

### 5.2 Contoh Advanced Index

```sql
-- Covering index (index-only scan)
CREATE INDEX idx_orders_list ON orders(created_at DESC)
    INCLUDE (customer_id, total, status);

-- Partial index (cuma untuk active orders)
CREATE INDEX idx_orders_active ON orders(created_at)
    WHERE status = 'active' AND deleted_at IS NULL;

-- Expression index
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- Partial + Expression + Include (all combined!)
CREATE INDEX idx_active_users_domain ON users(LOWER(email))
    INCLUDE (name, last_login)
    WHERE status = 'active' AND email_verified = true;
```

---

## 6. Migration Strategies — Zero-Downtime Schema Change

### 6.1 Expand-Migrate-Contract Pattern (PostgreSQL)

```text
Phase 1 — Expand:
  ALTER TABLE orders ADD COLUMN new_status TEXT;
  → App mulai tulis ke old + new column
  → Index baru dibikin CONCURRENTLY

Phase 2 — Migrate:
  UPDATE orders SET new_status = status::TEXT;
  → Background batch, batched per 10K rows
  → Cek pg_stat_progress untuk progress

Phase 3 — Contract:
  ALTER TABLE orders DROP COLUMN status;
  RENAME COLUMN new_status TO status;
  → App update query ke column baru
  → Drop old index
```

### 6.2 Online Schema Change Tools

| DB         | Tool                    | Method                             |
| :--------- | :---------------------- | :--------------------------------- |
| PostgreSQL | pg_repack               | Triggers + shadow table            |
| PostgreSQL | pgroll (2024)           | Expand-contract with safety checks |
| MySQL      | gh-ost (GitHub)         | Binlog-based, triggerless          |
| MySQL      | pt-online-schema-change | Triggers + chunk iteration         |
| Vitess     | Online DDL              | Vitess scheduler                   |

---

## 🔗 Koneksi ke Catatan Lain

| Catatan                              | Koneksi                               |
| :----------------------------------- | :------------------------------------ |
| [[database-internals-indexing-mvcc]] | Storage engine & indexing theory      |
| [[postgresql-admin-backup]]          | Operasional sehari-hari               |
| [[postgresql-performance-triage]]    | Slow query troubleshooting            |
| [[data-engineering]]                 | Pipeline & warehouse                  |
| [[distributed-systems]]              | CAP, replication, partitioning theory |
| [[ddia-kleppmann]]                   | Part II — distributed data storage    |
| [[software-engineering]]             | Application-level patterns            |

---

## ✅ Checklist

- [ ] Paham 1NF sampai BCNF dan tau kapan berhenti
- [ ] Bisa milih table inheritance pattern yang tepat
- [ ] Bisa milih sharding strategy berdasarkan query pattern
- [ ] Paham trade-off single-leader vs multi-leader vs leaderless
- [ ] Bisa design covering + partial + expression index combination
- [ ] Paham zero-downtime migration pattern (expand-migrate-contract)
- [ ] Tau kapan pake time-series partitioning vs normal table
- [ ] Bisa design multi-tenant schema yang sesuai dengan isolasi requirement

---

## Roadmap Belajar

```
HARI 1: Normalisasi & Data Modeling
  - Baca catatan ini sampai selesai
  - Ambil schema project nyata, audit normalisasinya
  - Redesign 1 table ke 3NF, implement di PostgreSQL

HARI 2: Sharding & Partitioning
  - Setup Citus/shndb, test hash vs range sharding
  - Benchmark: insert 1M rows ke sharded vs single node
  - Cek query pattern: mana yang cross-shard vs single-shard

HARI 3: Index Design Workshop
  - Ambil slow query dari pg_stat_statements
  - Design covering + partial index
  - Test: explain (analyze, buffers) sebelum vs sesudah

HARI 4: Migration Strategy
  - Setup pg_repack di test environment
  - Simulasi expand-migrate-contract
  - Test rollback migration

HARI 5: Multi-Tenant & Versioning
  - Implementasi shared table + RLS vs separate schema
  - Setup SCD Type 2 untuk historical tracking
  - Benchmark: query performance per isolation level
```

> [!warning] Bottom Line
> Database engineering bukan cuma soal "bikin tabel". Setiap keputusan — normalized vs denormalized, hash vs range shard, sync vs async replication — adalah **trade-off antara consistency, performance, dan operational complexity**. 90% aplikasi cukup pake 3NF + single-leader + B-Tree index. Jangan over-engineer dengan sharding kalau data masih <1TB. Dan jangan pernah skip migration testing — schema change yang salah bisa bikin downtime lebih parah dari aplikasi crash.

> [!tip] Lanjutan
> Catatan terkait: [[database-internals-indexing-mvcc]] (teori storage), [[distributed-systems]] (teori distribusi), [[postgresql-performance-triage]] (debugging). Untuk bacaan lanjutan: DDIA Part II (Kleppmann), "Database Design for Mere Mortals" (Hernandez).
