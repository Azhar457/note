---
title: Database and Storage Systems Hierarchy — From Flat Files to Distributed Lakehouses
tags:
  - database
  - storage-systems
  - systems-architecture
  - data-engineering
created: 2026-07-19
updated: 2026-07-19
status: complete
cssclasses:
  - wide-table
  - callout
---


> [!abstract] Ringkasan & Hubungan ke Vault
> Memahami bagaimana data disimpan, diindeks, dan ditarik kembali adalah pilar fundamental rekayasa sistem. Catatan ini memetakan tingkatan evolusi sistem penyimpanan data dari format paling sederhana (Level 0) hingga arsitektur terdistribusi skala planet (Level 7), melengkapi pembahasan [[hierarchy-operating-systems]] dan [[data-engineering]].

## Daftar Isi

1. [Matriks Hierarki Database & Penyimpanan](#1-matriks-hierarki-database--penyimpanan)
2. [Level 0 s.d Level 3: Sistem Berkas & Database Tradisional](#2-level-0-sd-level-3-sistem-berkas--database-tradisional)
3. [Level 4 s.d Level 7: Terdistribusi, Cloud-Scale, dan Analytical Storage](#3-level-4-sd-level-7-terdistribusi-cloud-scale-dan-analytical-storage)
4. [Aspek Keamanan & Vektor Serangan Per Level](#4-aspek-keamanan--vektor-serangan-per-level)
5. [Koneksi ke Vault](#5-koneksi-ke-vault)

---

## 1. Matriks Hierarki Database & Penyimpanan

Tabel berikut memetakan evolusi penyimpanan berdasarkan kompleksitas abstraksi, performa latensi, dan throughput penulisan data (*write throughput*):

| Level | Kategori Teknologi | Karakteristik Latensi | Throughput Penulisan | Contoh Implementasi |
|-------|--------------------|-----------------------|----------------------|---------------------|
| **L7** | Distributed Lakehouse / NewSQL | Sedang-Tinggi (10ms - 5s) | Ekstrem (Petabyte/day) | Snowflake, Databricks (Delta Lake), CockroachDB, Google Spanner |
| **L6** | Big Data / Distributed DSS | Sedang (50ms - 2s) | Sangat Tinggi (GB/s) | Apache Spark, ClickHouse, Apache Hadoop HDFS, AWS S3 |
| **L5** | Distributed NoSQL | Sangat Rendah (1ms - 10ms) | Tinggi | Cassandra, ScyllaDB, Amazon DynamoDB, MongoDB Cluster |
| **L4** | In-Memory & Cache | Sub-Milidetik (<1ms) | Sangat Tinggi | Redis, Memcached, Aerospike, KeyDB |
| **L3** | Relational Database (RDBMS) | Rendah (2ms - 15ms) | Sedang | PostgreSQL, MySQL, Oracle Database, Microsoft SQL Server |
| **L2** | Embedded Database | Sangat Rendah (1ms - 5ms) | Rendah | SQLite, LevelDB, RocksDB, DuckDB (embedded OLAP) |
| **L1** | Structured Files | N/A (Tergantung disk) | Rendah | JSON, XML, CSV, Parquet, Protocol Buffers (protobuf) |
| **L0** | Raw Text / Flat Files | N/A (Tergantung OS/hardware) | Sangat Rendah | Plain TXT, raw bytes stream, `/dev/urandom` |

---

## 2. Level 0 s.d Level 3: Sistem Berkas & Database Tradisional

### Level 0 — Raw Text / Flat Files
- **Konsep**: Penyimpanan data biner mentah tanpa struktur formal di atas sistem berkas.
- **Mekanisme**: Penulisan langsung ke sektor disk menggunakan standard library OS (seperti kernel call `write`). Tidak ada indeks, transaksi, atau validasi tipe data.
- **Kelemahan**: Pencarian membutuhkan pemindaian linear penuh (*Full Scan* / $O(N)$ complexity).

### Level 1 — Structured Files
- **Konsep**: Data disusun menggunakan format data pertukaran terstruktur.
- **Mekanisme**: File serialize/deserialize (seperti JSON, Parquet biner, atau Protobuf).
- **Penggunaan**: Parquet sangat populer di analisis big data karena format kolomnya (*columnar format*) yang mendukung kompresi tinggi dan *projection pushdown* (hanya membaca kolom yang di-query).

### Level 2 — Embedded Database
- **Konsep**: Engine database berjalan di dalam ruang memori proses aplikasi yang sama (*in-process*), meniadakan latensi komunikasi antar-proses (IPC) atau soket jaringan.
- **Mekanisme**:
  - **SQLite**: Menyediakan engine SQL relasional penuh berbasis file tunggal.
  - **RocksDB**: Engine Key-Value super cepat menggunakan struktur data *Log-Structured Merge-tree* (LSM-tree) untuk mengoptimalkan penulisan pada media SSD.

### Level 3 — Relational Database (RDBMS)
- **Konsep**: Penggunaan model data relasional (tabel, kolom, baris) dengan kepatuhan penuh terhadap jaminan **ACID** (Atomicity, Consistency, Isolation, Durability) secara tersentralisasi.
- **Mekanisme**: Komunikasi melalui soket TCP/IP klien-server. Menggunakan struktur indeks **B-Tree** atau **B+ Tree** untuk meminimalkan operasi I/O disk saat pencarian data.
- **Contoh Kunci**: PostgreSQL (mendukung MVCC - *Multi-Version Concurrency Control* untuk konkurensi tinggi tanpa memblokir pembacaan selama proses penulisan).

---

## 3. Level 4 s.d Level 7: Terdistribusi, Cloud-Scale, dan Analytical Storage

### Level 4 — In-Memory & Cache
- **Konsep**: Penyimpanan data murni di memori volatile (RAM) untuk meminimalkan latensi eksekusi hingga taraf sub-milidetik.
- **Mekanisme**: Penyimpanan struktur data Key-Value (seperti Hash, List, Set pada Redis). Persistensi ke disk dijalankan secara asinkron menggunakan snapshot RDB (Redis Database) atau AOF (Append-Only File).

### Level 5 — Distributed NoSQL
- **Konsep**: Database non-relasional yang dirancang untuk skala horizontal (*horizontal scaling*) dengan mengorbankan konsistensi demi ketersediaan data (*CAP Theorem* - AP/CP).
- **Mekanisme**:
  - **Cassandra/ScyllaDB**: Menggunakan arsitektur *Ring* terdistribusi tanpa master tunggal (*masterless*), berbasis *Consistent Hashing* untuk mendistribusikan data ke seluruh node.
  - **MongoDB**: Database dokumen dengan replikasi *Replica Set* otomatis untuk *failover* cepat.

### Level 6 — Big Data / Distributed DSS (Decision Support Systems)
- **Konsep**: Penyimpanan dan pemrosesan data analitis (OLAP) berdimensi masif secara terdistribusi.
- **Mekanisme**:
  - **ClickHouse**: Database kolom (column-oriented) yang dirancang untuk query agregasi instan pada miliaran baris data log.
  - **HDFS / AWS S3**: Object storage berbiaya rendah yang menyimpan data dalam chunk terdistribusi di ribuan server murah (*commodity hardware*).

### Level 7 — Distributed Lakehouse / NewSQL
- **Konsep**: Konvergensi arsitektur yang menggabungkan kemampuan transaksi ACID dari RDBMS tradisional dengan skalabilitas big data dari data lake.
- **Mekanisme**:
  - **NewSQL (CockroachDB/Spanner)**: Menyediakan SQL relasional terdistribusi secara global dengan transaksi ACID penuh menggunakan protokol konsensus **Raft** atau **Paxos**, dibantu sinkronisasi jam fisik (*TrueTime API* menggunakan jam atomik dan GPS).
  - **Lakehouse (Delta Lake)**: Menambahkan lapisan transaksi ACID berbasis log transaksi (Parquet + JSON metadata) langsung di atas penyimpanan objek murah (S3/GCS).

---

## 4. Aspek Keamanan & Vektor Serangan Per Level

Setiap level memiliki kelemahan unik yang harus dimitigasi di level arsitektur:

| Level | Vektor Serangan Utama | Mekanisme Serangan | Strategi Mitigasi / Defense |
|-------|------------------------|---------------------|-----------------------------|
| **L7/L6** | Data Lake Exfiltration / Poisoning | Akses tidak sah ke S3 bucket, manipulasi data Parquet analitis | IAM policies yang ketat, enkripsi sisi server (SSE-KMS), WAF API boundary |
| **L5** | NoSQL Injection | Injeksi operator query (misal: payload `$gt` MongoDB) | Skema validasi tipe data (Zod/JSON Schema), sanitasi input |
| **L4** | Cache Poisoning / Memory Leak | Eksekusi perintah `FLUSHALL` via port terekspos, kehabisan RAM | Autentikasi Redis ACL, matikan perintah berbahaya via config, batasan `maxmemory-policy` |
| **L3** | SQL Injection (SQLi) | Manipulasi string query SQL mentah via input form | Parameterized queries, ORM, WAF deep inspection (ModSecurity/WAF kustom) |
| **L2/L1** | Local File Inclusion (LFI) / Write-over | Penyerang menimpa file SQLite lokal atau file konfigurasi JSON | Isolasi hak akses proses OS (Sandbox/Docker), input path sanitization |
| **L0** | Path Traversal / Arbitrary Write | Penyerang memanipulasi parameter file path (`../../etc/passwd`) | Path normalization, chroot jail, AppArmor/SELinux profiles |

---

## 5. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[postgresql-performance-triage]] | Taktik optimasi performa dan penanganan transaksi ACID pada Level 3 RDBMS. |
| [[database-internals-indexing-mvcc]] | Arsitektur detail penyimpanan indeks B+ Tree dan LSM Tree untuk optimasi indexing. |
| [[api-security-deep-dive]] | Cara memitigasi kebocoran kredensial akses database di level API Gateway. |
| [[unified-threat-ontology]] | Penyelarasan kerentanan database (SQLi, NoSQLi) pada Layer 7 (Application). |

audited
---
