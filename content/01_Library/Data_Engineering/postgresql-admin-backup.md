---
title: PostgreSQL Administrasi Backup
tags:
- data-engineering
- database
- postgresql
- backup
- devops
aliases:
- PG Backup Restore
created: '2026-07-11'
updated: '2026-07-11'
status: active
cssclasses: ''
---

# 🐘 PostgreSQL — Administrasi & Disaster Recovery

> **Filosofi:** PostgreSQL bukan MySQL yang bisa `mysqldump` tiap jam tanpa mikir. PG punya arsitektur MVCC, WAL, replication slots — backup yang salah bisa korup replication atau bloat disk.

---

## Arsitektur Dasar

```
┌──────────┐      ┌──────────────┐      ┌────────────┐
│  Client  │─────▶│  Postmaster  │─────▶│   Shared   │
│          │      │  (PID 1)     │      │  Buffers   │
└──────────┘      └──────┬───────┘      └────────────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
        ┌─────────┐ ┌─────────┐ ┌─────────┐
        │ WAL     │ │ Check-  │ │ Archive │
        │ Writer  │ │ pointer │ │ (optional)│
        └─────────┘ └─────────┘ └─────────┘
```

| Komponen | Fungsi |
|----------|--------|
| **WAL (Write-Ahead Log)** | Semua perubahan ditulis ke WAL dulu sebelum data page. Ini jaminan crash recovery |
| **Checkpoint** | Flush dirty buffers ke disk. Frekuensi diatur `checkpoint_timeout` (default 5 menit) |
| **Autovacuum** | Membersihkan dead tuples — MVVC遗产. Kalau mati → bloat |
| **Replication Slot** | Menjamin WAL gak dihapus sebelum replica menerimanya |

---

## Backup Strategy — 3 Lapisan

> [!important] Aturan Emas
> Backup is useless unless you've verified restore. Selalu test restore di environment terpisah.

### Lapisan 1 — Logical Backup (`pg_dump` / `pg_dumpall`)

| Tool | Untuk | Kelemahan |
|------|-------|-----------|
| `pg_dump` | 1 database | Lambat untuk DB >50GB |
| `pg_dumpall` | Semua DB + global objects (roles, tablespaces) | Output campur aduk, butuh filtering |

**Command aman:**
```bash
# Single DB
pg_dump -h localhost -U postgres -d mydb \
  --no-owner --no-acl \
  | gzip > mydb_$(date +%F).sql.gz

# All DBs (PG14+)
pg_dumpall -h localhost -U postgres \
  -c  # include DROP/CREATE DB
  | grep -v '^\\\\restrict' \  # ⚠️ PG16+ issue
  | gzip > full_$(date +%F).sql.gz
```

> [!warning] `\restrict` Trap
> `pg_dumpall -c` di PG14 menghasilkan `\restrict` lines yang **gak dikenal PG16+**. Filter dengan `grep -v '^\\\\restrict'` sebelum restore.

### Lapisan 2 — Physical Backup (pg_basebackup)

Untuk replica setup atau PITR (Point-In-Time Recovery):

```bash
pg_basebackup -h primary -U replicator \
  -D /backup/pg_base \
  -X stream --progress --verbose
```

| Metode | Recovery Point | Ukuran | Kecepatan Restore |
|--------|---------------|--------|------------------|
| `pg_dump` | Saat eksekusi | Kecil (SQL) | Lambat (replay SQL) |
| `pg_basebackup` | + WAL archive | Besar (binary) | Cepat (copy file) |

### Lapisan 3 — WAL Archiving (Continuous Archiving)

Untuk PITR ke detik tertentu:

```conf
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal/%f'
```

**Restore PITR:** Stop PG → restore base backup → buat `recovery.signal` → atur `restore_command` → start.

---

## Container Deployment (Podman/Docker)

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgis/postgis:16-3.4  # PG16 + PostGIS
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backup:/backup
    environment:
      POSTGRES_PASSWORD: ${PG_PASSWORD}
    ports:
      - "5432:5432"
```

> [!tip] PG16 + PostGIS
> Image `postgis/postgis` sudah include PostGIS extension. Gak perlu install manual. Tapi pull-nya ~500MB — siapin bandwidth.

### Version Migration (PG14 → PG16)

| Step | Command | Catatan |
|------|---------|--------|
| 1. Dump old | `pg_dumpall -c \| gzip > old.sql.gz` | Di PG14 |
| 2. Spin up new | Container PG16 + volume kosong | |
| 3. Adjust dump | `zcat old.sql.gz \| grep -v '^\\\\' > clean.sql` | Buang `\restrict` |
| 4. Restore | `psql -f clean.sql postgres` | Error toleran |
| 5. Verify | `\dt+`, row count sample | Jangan percuma |

---

## Performance Tuning Dasar

| Parameter | Default | Recommended | Notes |
|-----------|---------|-------------|-------|
| `shared_buffers` | 128MB | 25% RAM | Buffer cache PG |
| `effective_cache_size` | 4GB | 75% RAM | Estimasi OS cache |
| `work_mem` | 4MB | 8-16MB | Per sort operation |
| `maintenance_work_mem` | 64MB | 10% RAM | Untuk VACUUM, index |
| `max_connections` | 100 | 20-50 | Setiap koneksi makan RAM |
| `random_page_cost` | 4.0 | 1.1 (SSD) | Biar PG prefer index scan |
| `autovacuum` | ON | ON | Jangan matikan |

---

## Common Failures & Fixes

| Gejala | Penyebab | Fix |
|--------|----------|-----|
| Connection refused | Port gak terbuka / service mati | `systemctl status postgresql` atau `podman logs` |
| Too many connections | `max_connections` penuh | Kurangi pool size di app, atau naikkan `max_connections` |
| WAL full (disk 100%) | Archive gagal / replication lag | Cek `pg_stat_replication`, bersihin WAL dengan `pg_archivecleanup` |
| Bloat besar | Autovacuum gak jalan | `SELECT pg_stat_progress_vacuum`; `VACUUM VERBOSE` |
| Role does not exist | Backup tanpa `--no-owner` di env beda | Restore dengan `--no-owner` atau create role dulu |

---

---

## 🧠 Berpikir — Metodologi Penyusunan Catatan

Catatan ini disusun melalui proses berpikir terstruktur sebagai berikut:

### 1. Thinking Type yang Digunakan

| Type | Kenapa | Bagian |
|------|--------|--------|
| **Analytical Thinking** | Memecah backup strategy jadi 3 lapis (logical, physical, WAL), membandingkan tradeoff tiap opsi | Backup Strategy, Performance Tuning |
| **Systems Thinking** | Memetakan interaksi komponen PG — WAL→checkpoint→archive, bagaimana satu kegagalan (archive gagal) menyebabkan WAL full | Arsitektur Dasar, Common Failures |
| **Concrete Thinking** | Menyusun command exact untuk backup, restore, migrasi — step-by-step tanpa asumsi | Container Deployment, Migration Steps |
| **Critical Thinking** | Mempertanyakan asumsi umum — "backup is useless unless verified", `\\restrict` trap PG14→16 | Aturan Emas, Migration warnings |

### 2. Background Knowledge (Pra-Penulisan)

- **PG page structure**: MVCC, WAL segments (16MB default), checkpoint distance, autovacuum triger
- **pg_dump internals**: `-c` flag produces `DROP DATABASE` + `CREATE DATABASE` + `\\connect` — di PG14 output includes `\\restrict` (PG16 gak kenal)
- **PostGIS container**: image `postgis/postgis:16-3.4` sudah bundle ekstensi + pgvector mulai support
- **Memory tuning**: `shared_buffers` 25% RAM adalah sweet spot — >40% malah hurt karena PG pake OS page cache juga
- **Failed experience**: restoration failure karena missing role, tablespace path beda — ditangkap di Common Failures

### 3. RAG Vault — Dokumen yang Dikonsultasi

| Dokumen | Kontribusi |
|---------|-----------|
| [[cicd-guide|CI/CD Pipeline Guide]] | PG + Podman deployment context, environment variables pattern |
| [[devops|DevOps Roadmap]] | Container deployment patterns, Docker Compose structure |
| [[data-engineering|Data Engineering Roadmap]] | Posisi PG dalam pipeline data secara umum |
| [[infrastructure-administrator|Infrastructure Administrator]] | Server layout — PG jadi salah satu service |

### 4. Sintesis — Bagaimana Bagian Bergabung

```
Background Knowledge (first principles)
    │
    ▼
RAG Vault (konteks vault existing)
    │
    ▼
Analytical:  Backup → 3 layers → compare physical vs logical
    │
    ▼
Systems:     Arsitektur PG → WAL → checkpoint → failure cascade → tuning
    │
    ▼
Concrete:    Exact commands → Migration steps → Container YAML
    │
    ▼
Critical:    Warning traps → `\\restrict` → verify restore → performance limits
```

### 5. Sequential Thinking Steps

```
Thought 1 (Cognitive):  "PG architecture = WAL + MVCC. Gak bisa disamakan dgn MySQL."
Thought 2 (Analytical): "Backup harus 3 layer. Logical untuk portability, physical untuk speed, WAL untuk PITR."
Thought 3 (Critical):   "Tapi guarantee backup cuma valid kalau dites restore. Banyak org skip ini."
Thought 4 (Systems):    "WAL bisa full kalau archive gagal. Replication slot bikin WAL gak dihapus. Ini cascade."
Thought 5 (Concrete):   "Command: pg_dumpall -c | grep -v '^\\restrict' | gzip. Step by step."
Thought 6 (Analytical): "Migrasi PG14→16 — apa yang beda? \restrict, default parameter, extension version."
Thought 7 (Convergent): "Filter 5 parameter tuning paling impactful: shared_buffers, effective_cache_size, work_mem, random_page_cost, max_connections."
```

---

## 🔗 Lihat Juga

- [[cicd-guide|CI/CD Pipeline Guide]] — PG sebagai bagian pipeline
- [[devops|DevOps Roadmap]] — Container deployment patterns
- [[data-engineering|Data Engineering Roadmap]] — ETL & data pipeline
- [[infrastructure-administrator|Infrastructure Administrator]] — Server ops context
