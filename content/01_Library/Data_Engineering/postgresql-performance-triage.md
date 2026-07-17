---
title: "PostgreSQL Performance Triage & Query Diagnostics"
tags:
  - data-engineering
  - database
  - postgresql
  - performance
  - triage
  - monitoring
  - devops
aliases:
  - "PostgreSQL Triage"
  - "PG Performance Diagnostics"
  - "Slow Query Analysis"
created: "2026-07-15"
updated: "2026-07-15"
status: active
cssclasses: ""
---

# 🐘 PostgreSQL — Performance Triage & Query Diagnostics

> **Filosofi:** Sebelum optimasi, harus ada diagnosis. Jangan ubah config tanpa data. PG menyediakan view sistem yang cukup untuk triage 90% masalah performa — tanpa perlu restart atau install ekstensi.

---

## 📋 Daftar Isi

1. [Kapan Butuh Triage](#1-kapan-butuh-triage)
2. [Connection Diagnostics](#2-connection-diagnostics)
3. [Lock Contention](#3-lock-contention)
4. [Slow Query Detection](#4-slow-query-detection)
5. [Vacuum & Bloat](#5-vacuum--bloat)
6. [Query Termination](#6-query-termination)
7. [Quick Reference — Copy-Paste Commands](#7-quick-reference--copy-paste-commands)
8. [Monitoring Checklist](#8-monitoring-checklist)

---

## 1. Kapan Butuh Triage

| Gejala                          | Kemungkinan                              | Langkah Awal                                    |
| ------------------------------- | ---------------------------------------- | ----------------------------------------------- |
| App lambat, timeout             | Connection exhaustion / slow query       | `pg_stat_activity` → cek `state` + `wait_event` |
| Beberapa fitur hang, lainnya OK | Lock contention                          | Lock detection query                            |
| CPU 100%                        | Query berulang / full table scan         | `pg_stat_statements` (kalo aktif)               |
| Disk I/O tinggi                 | Vacuum / checkpoint / bloat              | `pg_stat_progress_vacuum`                       |
| Memory melonjak                 | Sort/hash di `work_mem` / connection太多 | `pg_stat_activity` → cek `query`                |

> [!tip] Golden Rule
> **Jangan restart PG untuk "bersihin" — itu symptom treatment, bukan root cause.** Selalu diagnose dulu.

---

## 2. Connection Diagnostics

> [!important] Aman di produksi
> View `pg_stat_activity` **read-only**. Gak ada risiko. Bisa dijalanin kapan aja.

### 2.1 — Snapshot Cepat (10 detik)

```sql
-- Semua koneksi aktif (non-idle)
SELECT pid, datname, usename, state,
       wait_event_type, wait_event,
       query_start, left(query, 100) as query_snippet,
       application_name, client_addr
FROM pg_stat_activity
WHERE state IS NOT NULL AND state != 'idle'
ORDER BY query_start;
```

**Output:**

| Kolom                           | Makna                                            | Triage                                   |
| ------------------------------- | ------------------------------------------------ | ---------------------------------------- |
| `state = 'active'`              | Lagi ngejalanin query                            | Normal — kalo banyak (>10) curiga        |
| `state = 'idle in transaction'` | 🔴 **Bahaya** — koneksi buka transaksi gak close | `SELECT pg_terminate_backend(pid)`       |
| `wait_event = 'IO'`             | Lagi nunggu disk                                 | Indikasi I/O bottleneck                  |
| `wait_event = 'ClientRead'`     | Lagi nunggu app kirim data                       | Normal                                   |
| `wait_event = 'Lock'`           | 🔴 Contention                                    | Lihat section [Lock](#3-lock-contention) |

### 2.2 — Hitung per State

```sql
SELECT state, count(*) as connections
FROM pg_stat_activity WHERE state IS NOT NULL
GROUP BY state ORDER BY connections DESC;
```

| State                 | Wajar | Alarm                            |
| --------------------- | ----- | -------------------------------- |
| `idle`                | 20-50 | >100 — connection pool oversized |
| `active`              | 2-10  | >20 — ada query berat            |
| `idle in transaction` | 0     | >0 🔴 — aplikasi bug             |

### 2.3 — Connection Pool Assessment

```sql
SELECT count(*) as total,
       count(*) FILTER (WHERE state = 'active') as active,
       count(*) FILTER (WHERE state = 'idle') as idle,
       count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_txn,
       count(*) FILTER (WHERE wait_event = 'Lock') as blocked
FROM pg_stat_activity;
```

> [!tip] Connection Pool (PgBouncer/App Level)
> Kalau `active < 5` tapi `total > 100` — app gak pake connection pool dengan bener. Setiap koneksi = ~10MB RAM.

### 2.4 — Last Query per Koneksi (termasuk idle)

```sql
SELECT pid, usename, datname,
       state,
       age(now(), query_start) as running_for,
       left(query, 150) as query
FROM pg_stat_activity
WHERE state IS NOT NULL
  AND pid != pg_backend_pid()
ORDER BY greatest(age(now(), query_start), '0'::interval) DESC
LIMIT 10;
```

> Berguna buat nemu koneksi yang udah "lama" (jam) tapi gak selesai.

---

## 3. Lock Contention

> **Penyebab:** Dua query berebut resource yang sama — satu nahan lock, satunya nunggu.

### 3.1 — Siapa Nahan Siapa (Blocking Tree)

```sql
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       substring(blocked_activity.query, 1, 80) AS blocked_query,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       substring(blocking_activity.query, 1, 80) AS blocking_query,
       age(now(), blocked_activity.query_start) AS blocked_duration
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity
  ON blocked_locks.pid = blocked_activity.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocked_locks.locktype = blocking_locks.locktype
 AND blocked_locks.database IS NOT DISTINCT FROM blocking_locks.database
 AND blocked_locks.relation IS NOT DISTINCT FROM blocking_locks.relation
 AND blocked_locks.page IS NOT DISTINCT FROM blocking_locks.page
 AND blocked_locks.tuple IS NOT DISTINCT FROM blocking_locks.tuple
 AND blocked_locks.virtualxid IS NOT DISTINCT FROM blocking_locks.virtualxid
 AND blocked_locks.transactionid IS NOT DISTINCT FROM blocking_locks.transactionid
 AND blocked_locks.classid IS NOT DISTINCT FROM blocking_locks.classid
 AND blocked_locks.objid IS NOT DISTINCT FROM blocking_locks.objid
 AND blocked_locks.objsubid IS NOT DISTINCT FROM blocking_locks.objsubid
JOIN pg_catalog.pg_stat_activity blocking_activity
  ON blocking_locks.pid = blocking_activity.pid
WHERE NOT blocked_locks.granted;
```

**Output:**

| blocked_pid | blocked_user | blocking_pid | blocking_user | blocked_duration |
| ----------- | ------------ | ------------ | ------------- | ---------------- |
| 12345       | app_user     | 12344        | admin_query   | 00:05:23         |

> 🔴 `blocking_pid` → ini yang perlu diterminate kalo darurat.

### 3.2 — Ringkasan Lock

```sql
SELECT pg_locks.locktype, pg_locks.mode,
       count(*) as locks
FROM pg_locks
JOIN pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid
WHERE pg_stat_activity.state != 'idle'
  AND pg_locks.granted = false
GROUP BY pg_locks.locktype, pg_locks.mode;
```

### 3.3 — Deadlock Detection

Deadlock otomatis dideteksi PG dan salah satu query di-terminate. Tapi kalo mau proaktif:

```sql
SELECT datname, usename, wait_event_type, wait_event,
       count(*) as waiters
FROM pg_stat_activity
WHERE wait_event_type = 'Lock'
  AND state = 'active'
GROUP BY datname, usename, wait_event_type, wait_event;
```

### 3.4 — Tabel dengan Lock Terbanyak

```sql
SELECT relname,
       count(*) FILTER (WHERE NOT granted) as blocked,
       count(*) FILTER (WHERE granted) as granted
FROM pg_locks l
JOIN pg_class c ON l.relation = c.oid
WHERE locktype = 'relation'
GROUP BY relname
ORDER BY blocked DESC
LIMIT 10;
```

---

## 4. Slow Query Detection

### 4.1 — Dengan `pg_stat_statements` (Wajib Enable)

> [!warning] Perlu Restart
> `pg_stat_statements` butuh `shared_preload_libraries` di `postgresql.conf` dan restart PG. Enable di **maintenance window**.

```sql
-- Enable (sekali):
-- ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
-- Restart PG, lalu:
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

**5 Query Termahal (Total Time):**

```sql
SELECT queryid,
       left(query, 100) AS query,
       calls,
       round(total_exec_time::numeric, 1) AS total_ms,
       round(mean_exec_time::numeric, 1) AS avg_ms,
       round((total_exec_time / sum(total_exec_time) OVER()) * 100, 1) AS percentage
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat%'
ORDER BY total_exec_time DESC
LIMIT 5;
```

**5 Query Paling Sering Dipanggil:**

```sql
SELECT left(query, 100) AS query, calls,
       round(mean_exec_time::numeric, 1) AS avg_ms,
       round(total_exec_time::numeric, 1) AS total_ms
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat%'
ORDER BY calls DESC
LIMIT 5;
```

**5 Query dengan I/O Tertinggi (blok baca):**

```sql
SELECT left(query, 100) AS query,
       calls,
       shared_blks_read + shared_blks_hit as total_blks,
       round(shared_blks_read * 100.0 / nullif(shared_blks_read + shared_blks_hit, 0), 1) as read_pct,
       round(shared_blks_hit * 100.0 / nullif(shared_blks_read + shared_blks_hit, 0), 1) as hit_pct
FROM pg_stat_statements
ORDER BY (shared_blks_read + shared_blks_hit) DESC
LIMIT 5;
```

> [!tip] Cache Hit Ratio
> `hit_pct < 95%` — data gak muat di `shared_buffers`. Naikkan `shared_buffers` atau optimasi query.

### 4.2 — Tanpa `pg_stat_statements` (Query Running Saat Ini)

```sql
-- Query yang lagi jalan >5 detik
SELECT pid, now() - pg_stat_activity.query_start AS duration,
       left(query, 120) AS query,
       usename, datname, wait_event_type, wait_event,
       state
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - pg_stat_activity.query_start > interval '5 seconds'
  AND pid != pg_backend_pid()
ORDER BY duration DESC;
```

### 4.3 — EXPLAIN ANALYZE (Manual)

```sql
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM "SensorTelemetry"
WHERE "timestamp" > now() - interval '1 day';
```

> [!tip] Cara Baca EXPLAIN
>
> - `Seq Scan on large_table` — perlu index
> - `Sort Method: external merge` — `work_mem` kurang
> - `Buffers: shared hit=10 read=1000` — 99% dari disk, bukan cache
> - `Actual Time` >> `Planning Time` — eksekusi lambat

---

## 5. Vacuum & Bloat

### 5.1 — Vacuum Progress

```sql
SELECT pid, datname, relid::regclass as table,
       phase, heap_blks_total, heap_blks_scanned,
       round(heap_blks_scanned * 100.0 / nullif(heap_blks_total, 0), 1) as progress_pct,
       age(now(), query_start) as running_for
FROM pg_stat_progress_vacuum
JOIN pg_stat_activity USING (pid);
```

> Kalau progress stuck di `scanning heap` >30 menit — mungkin bloat parah atau I/O penuh.

### 5.2 — Tabel Paling Butuh Vacuum

```sql
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup * 100.0 / nullif(n_live_tup + n_dead_tup, 0), 1) as dead_pct,
       last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 10;
```

| `dead_pct` | Tindakan                                                 |
| ---------- | -------------------------------------------------------- |
| <20%       | Normal — autovacuum handle                               |
| 20-50%     | ⚠️ Cek `last_autovacuum` — mungkin perlu `VACUUM` manual |
| >50%       | 🔴 Bloat berbahaya — `VACUUM (ANALYZE, VERBOSE)`         |

### 5.3 — Estimasi Bloat Per Tabel

```sql
SELECT schemaname || '.' || tablename as table_name,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
       pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as data_size,
       round(100 * (1 - pg_relation_size(schemaname||'.'||tablename) /
            nullif(pg_total_relation_size(schemaname||'.'||tablename), 0)), 1) as bloat_pct
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT LIKE 'pg_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

> **Catatan:** Estimasi kasar. Buat akurat, pake `pgstattuple` extension atau `pg_repack`.

---

## 6. Query Termination

### 6.1 — Cancel vs Terminate

| Perintah                    | Efek                                   | Kapan                                       |
| --------------------------- | -------------------------------------- | ------------------------------------------- |
| `pg_cancel_backend(pid)`    | Batalkan query — transaksi tetap jalan | Query lambat, gak critical                  |
| `pg_terminate_backend(pid)` | Putus koneksi — transaksi rollback     | 🔴 Darurat — koneksi zombie, lock gak lepas |

```sql
-- Cancel query
SELECT pg_cancel_backend(12345);

-- Force terminate
SELECT pg_terminate_backend(12345);

-- Terminate semua idle-in-transaction >30 menit
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - query_start > interval '30 minutes';
```

> [!warning] Jangan Sembarang Terminate
> `pg_terminate_backend` menyebabkan **rollback transaksi**. App harus handle reconnect. Buat darurat aja.

---

## 7. Quick Reference — Copy-Paste Commands

> Semua command ini **read-only** — aman di produksi.

### Check Cepat (30 detik)

```sql
-- 1. Koneksi per state
SELECT state, count(*) FROM pg_stat_activity
 WHERE state IS NOT NULL GROUP BY state;

-- 2. Query jalan >5 detik
SELECT pid, usename, now()-query_start AS dur,
  left(query,60) FROM pg_stat_activity
 WHERE state='active' AND now()-query_start > interval '5s'
   AND pid != pg_backend_pid();

-- 3. Lock contention
SELECT count(*) AS blocked FROM pg_locks WHERE NOT granted;
```

### Diagnostik Lengkap (2 menit)

```sql
-- Koneksi overview + lock + slow query — dalam 1 query
SELECT 'connections' AS check_name,
       jsonb_build_object(
         'total', count(*),
         'active', count(*) FILTER (WHERE state='active'),
         'idle_txn', count(*) FILTER (WHERE state='idle in transaction')
       ) AS result
FROM pg_stat_activity WHERE state IS NOT NULL
UNION ALL
SELECT 'long_running_queries',
       jsonb_build_object('count', count(*))
FROM pg_stat_activity
WHERE state='active' AND now()-query_start > interval '1 minute'
  AND pid != pg_backend_pid()
UNION ALL
SELECT 'locked_queries',
       jsonb_build_object('blocked', count(*))
FROM pg_locks WHERE NOT granted;
```

### Monitoring Recurring (Cron)

```bash
# Cek setiap jam → log ke file
psql -h localhost -U postgres -c "
SELECT now(), state, count(*) FROM pg_stat_activity
WHERE state IS NOT NULL GROUP BY state;
" >> /var/log/pg_connections.log 2>&1
```

---

## 8. Monitoring Checklist

### Setelah Deploy / Sebelum Migrasi

- [ ] `pg_stat_statements` di-enable?
- [ ] `log_min_duration_statement` di-set (e.g. 1000ms)?
- [ ] Connection pool size sesuai (cek `max_connections`)?
- [ ] `shared_buffers` udah 25% RAM?
- [ ] `random_page_cost` udah 1.1 (SSD)?
- [ ] Autovacuum jalan normal?
- [ ] Cek `longest running query > 1 hour`?

### Mingguan / Bulanan

- [ ] Review slow query dari `pg_stat_statements`
- [ ] Cek bloat di tabel terbesar
- [ ] Vacuum analyze tabel yang `dead_pct > 30%`
- [ ] Review connection pool usage pattern
- [ ] Cek `max_connections` vs peak usage

---

## 🔗 Lihat Juga

- [[postgresql-admin-backup|PostgreSQL Administrasi Backup]] — Backup & disaster recovery
- [[data-engineering|Data Engineering Roadmap]] — Posisi PG dalam pipeline data
- [[devops|DevOps Roadmap]] — Container deployment patterns
