---
title: "Data Engineering"
tags:
  - atlas
  - roadmap
aliases:
  - "data-engineering"
created: "2026-04-25"
updated: "2026-07-01"
status: active
cssclasses: ""
---

# 📊 Roadmap Data Engineering

> **Filosofi:** Kalau kamu cuma bisa query SQL, itu artinya kamu bisa ambil data. Tapi kalau kamu bisa design pipeline yang extract dari 5 source berbeda → transform dengan business logic → load ke warehouse → schedule otomatis → monitor data quality, itu artinya kamu bisa membangun data infrastructure — dan itu yang ditanya waktu interview. Rekruter akan tanya "oke, data masuk warehouse, terus gimana kalau source berubah schema?" Kalau kamu jawab "pipeline saya punya schema validation di ingestion layer, dead letter queue untuk data gagal, dan alerting kalau row count turun lebih dari 20%" — itu yang menutup pertanyaan.

> [!important] Salary Ceiling Paling Tinggi
> Data Engineering adalah jalur dengan **salary ceiling paling tinggi jangka panjang** di Indonesia. Senior Data Engineer di unicorn Indonesia: 30–60 juta/bulan. Di luar negeri (remote): $150–250k/tahun. Demand masih naik karena setiap perusahaan butuh data infrastructure.

---

## 🎯 Checkpoint Awal — Sebelum Mulai

```
Stack       : Local machine (Python + Docker) → Proxmox VM untuk services
Jalur       : Data Engineer → Senior Data Engineer → Data Architect
Spek        : i7 Gen7, 8GB RAM, GTX 1050
Target Karir: Junior DE → Mid DE → Senior DE / Data Architect

Urutan belajar:
  Fase 1 (fondasi wajib)    : SQL Advanced + Python + Linux + Docker
  Fase 2 (pipeline basics)  : ETL/ELT + Airflow + dbt + PostgreSQL/DuckDB
  Fase 3 (warehouse & lake) : Data Modeling + Spark/Polars + Cloud Storage
  Fase 4 (production)       : Streaming + Data Quality + Orchestration Advanced

Next step: Install Python, DuckDB, setup Docker Compose untuk PostgreSQL + Airflow
```

---

## Fase 1 — Fondasi: SQL, Python & Infrastructure (Minggu 1–8)

> **Goal:** SQL dan Python HARUS di level intermediate sebelum melangkah. Tidak ada shortcut.
> **RAM Impact:** Minimal — editor + terminal + database.

| Skill             | Yang Dipelajari                                                     | Combo A+B yang Membuktikan                                                          |
| ----------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **SQL Advanced**  | Window functions, CTEs, subqueries, EXPLAIN, indexing, partitioning | SQL + **complex analytical query** = kamu bisa jawab business question langsung     |
| **Python Data**   | pandas, polars, file I/O, API calls, error handling, typing         | Python + **data transformation pipeline** = kamu bisa process data programmatically |
| **Linux & Shell** | Bash scripting, cron, ssh, file system, process management          | Linux + **scheduled script** = kamu bisa automate tanpa UI                          |
| **Docker**        | Container, Compose, networking, volume mount, multi-service         | Docker + **local dev environment** = consistent setup everywhere                    |
| **Git**           | Branching, PR, versioning, .gitignore untuk data                    | Git + **versioned pipeline code** = kamu treat data pipeline seperti software       |

> [!tip] DuckDB Adalah Game Changer
> Untuk belajar SQL advanced, pakai **DuckDB** — analytical database yang jalan di local tanpa server. Import CSV/Parquet langsung, query secepat Spark untuk data <10GB. Zero setup, zero RAM overhead. Perfect untuk homelab.

**Proyek Portofolio Fase 1:**
`Analytical SQL Challenge` — ambil dataset publik (Kaggle), load ke DuckDB/PostgreSQL, tulis 20+ complex queries (window function, CTE recursive, pivot, performance comparison). Dokumentasikan dengan penjelasan bisnis per query. **Ini menunjukkan SQL kamu bukan cuma SELECT \* FROM.**

---

## Fase 2 — ETL/ELT Pipeline & Orchestration (Minggu 9–18)

> **Goal:** Bangun pipeline pertama yang extract → transform → load secara otomatis.
> **RAM Impact:** Airflow ~1-2GB. PostgreSQL ~500MB. Matikan service lain.

| Tool/Skill                | RAM    | Yang Dipelajari                                                       | Combo A+B yang Membuktikan                                                                 |
| ------------------------- | ------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **Apache Airflow**        | ~1.5GB | DAG-based orchestration, scheduling, dependency, retry, alerting      | Airflow + **custom DAG dengan error handling** = kamu bisa orchestrate production pipeline |
| **dbt (data build tool)** | ~200MB | SQL-based transformation, testing, documentation, lineage             | dbt + **tested models** = kamu bisa transform dan validate data di warehouse               |
| **PostgreSQL**            | ~500MB | Warehouse sederhana — schema design, materialized views, partitioning | PostgreSQL + **analytical schema** = kamu paham dimensional modeling                       |
| **API Extraction**        | —      | REST API, pagination, rate limiting, error handling, incremental load | API + **idempotent extraction** = kamu bisa build reliable ingestion                       |
| **File Formats**          | —      | CSV, JSON, Parquet, Avro — kapan pakai apa dan kenapa                 | Format + **performance comparison** = kamu paham storage optimization                      |

> [!warning] Airflow di 8GB RAM
> Pakai **Airflow standalone mode** (bukan CeleryExecutor). Set `AIRFLOW__CORE__PARALLELISM=4` dan `AIRFLOW__CORE__DAG_CONCURRENCY=2`. Cukup untuk belajar. Matikan Wazuh/Suricata kalau jalan bersamaan.

**Proyek Portofolio Fase 2:**
`End-to-End Data Pipeline` — Extract data dari 2-3 public API (weather, crypto, news) → Transform dengan dbt (clean, join, aggregate) → Load ke PostgreSQL → Schedule via Airflow (daily run) → dbt test untuk data quality. **Deploy di homelab, tunjukkan DAG graph dan data lineage.**

---

## Fase 3 — Data Warehouse & Big Data Processing (Minggu 19–28)

> **Goal:** Dari single database → proper data warehouse dengan modeling methodology.
> **RAM Impact:** Spark heavy. Pakai Polars untuk homelab (10x lebih ringan).

| Skill/Tool                | RAM        | Yang Dipelajari                                                      | Combo A+B yang Membuktikan                                                               |
| ------------------------- | ---------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Dimensional Modeling**  | —          | Star schema, snowflake schema, SCD Type 1/2, fact vs dimension table | Modeling + **implemented warehouse** = kamu bisa design data architecture                |
| **Polars / PySpark**      | ~500MB–2GB | DataFrame API, lazy evaluation, partitioning, join strategies        | Polars + **large dataset processing** = kamu bisa process data yang tidak muat di pandas |
| **Parquet / Delta Lake**  | —          | Columnar storage, schema evolution, time travel, ACID on files       | Parquet + **partitioned data lake** = kamu paham modern data storage                     |
| **MinIO (S3-compatible)** | ~500MB     | Object storage — data lake layer, lifecycle policies                 | MinIO + **partitioned storage** = kamu punya data lake di homelab                        |
| **Great Expectations**    | ~300MB     | Data quality — expectations, validation, profiling, docs             | GX + **automated testing** = kamu bisa prove data quality to stakeholders                |

> [!tip] Polars vs PySpark untuk Homelab
> **Pakai Polars.** PySpark butuh JVM + Spark cluster (~3GB minimum). Polars jalan native di Python, 10-100x lebih cepat dari pandas, dan API mirip Spark. Kalau interview tanya Spark, bilang "saya pakai Polars untuk local, konsep lazy evaluation dan partitioning sama — saya bisa switch ke Spark di cluster." Rekruter mengerti.

**Proyek Portofolio Fase 3:**
`Data Warehouse with Dimensional Modeling` — design star schema untuk domain bisnis (e-commerce atau sales), implement SCD Type 2 untuk dimension tables, build ELT pipeline (extract → raw layer → staging → marts), data quality checks via Great Expectations. **Tunjukkan ERD + data lineage diagram.**

---

## Fase 4 — Streaming, Quality & Cloud (Minggu 29–40)

> **Goal:** Real-time data processing dan production-grade data platform.
> **RAM Impact:** Kafka heavy (~2GB). Pelajari konsep dulu, jalankan hanya saat khusus belajar.

| Skill/Tool                | RAM    | Yang Dipelajari                                                            | Combo A+B yang Membuktikan                                            |
| ------------------------- | ------ | -------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **Apache Kafka**          | ~2GB   | Event streaming, topic/partition, consumer group, exactly-once             | Kafka + **streaming pipeline** = kamu bisa handle real-time data      |
| **Flink / Kafka Streams** | ~1GB   | Stream processing, windowing, stateful computation                         | Stream processing + **real-time dashboard** = kamu paham beyond batch |
| **Data Contracts**        | —      | Schema registry, backward/forward compatibility, breaking change detection | Contracts + **enforcement** = kamu bisa manage schema evolution       |
| **Cloud Provider**        | Cloud  | BigQuery / Redshift / Snowflake — managed warehouse                        | Cloud + **cost optimization** = kamu bisa migrate on-prem ke cloud    |
| **Metadata / Catalog**    | ~500MB | DataHub / Amundsen — data discovery, lineage, ownership                    | Catalog + **searchable data** = kamu bisa scale data org              |

> [!warning] Kafka di 8GB RAM
> Kafka butuh ~2GB (broker + ZooKeeper). **Matikan SEMUA service lain.** Atau: pakai **Redpanda** — Kafka-compatible, single binary, butuh cuma ~500MB. API sama, performance lebih baik untuk single node.

**Proyek Portofolio Fase 4:**
`Real-Time Data Platform` — Kafka (atau Redpanda) → stream processing → real-time dashboard (Grafana/Metabase) + batch processing → warehouse → dbt marts. Dual pipeline (lambda architecture). **Ini proyek yang membuat data team lead bilang "kamu paham."**

---

## Roadmap Visual — Timeline 10 Bulan

```
Bulan 1-2         Bulan 3-5         Bulan 6-7         Bulan 8-10
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ FASE 1        │ │ FASE 2        │ │ FASE 3        │ │ FASE 4        │
│               │ │               │ │               │ │               │
│ SQL Advanced  │ │ Airflow       │ │ Dim Modeling  │ │ Kafka         │
│ Python Data   │ │ dbt           │ │ Polars/Spark  │ │ Streaming     │
│ Linux/Shell   │ │ PostgreSQL WH │ │ Parquet/Delta │ │ Data Contracts│
│ Docker        │ │ API Extract   │ │ MinIO (Lake)  │ │ Cloud WH      │
│ Git           │ │ File Formats  │ │ Data Quality  │ │ Catalog       │
│               │ │               │ │               │ │               │
│ ► SQL         │ │ ► E2E         │ │ ► Data WH     │ │ ► Real-Time   │
│   Challenge   │ │   Pipeline    │ │   Star Schema │ │   Platform    │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
```

---

## Sertifikasi yang Cocok per Fase

| Fase           | Sertifikasi                                              | Kenapa                                    |
| -------------- | -------------------------------------------------------- | ----------------------------------------- |
| Setelah Fase 1 | **Google Data Analytics Certificate** (Coursera, gratis) | Fondasi analytics thinking                |
| Setelah Fase 2 | **dbt Analytics Engineering Certification** (gratis)     | Industry standard transformation tool     |
| Setelah Fase 3 | **Google Professional Data Engineer**                    | Comprehensive — design + build + optimize |
| Setelah Fase 4 | **Databricks Data Engineer Associate/Professional**      | Modern lakehouse standard                 |

---

## Stack Comparison — Mana yang Dipilih?

| Komponen           | Pilihan Homelab (Gratis) | Pilihan Cloud (Production)      | Notes                                                  |
| ------------------ | ------------------------ | ------------------------------- | ------------------------------------------------------ |
| **Orchestrator**   | Airflow (Docker)         | Airflow / Dagster / Prefect     | Airflow = industry standard, tapi Dagster lebih modern |
| **Transformation** | dbt Core (CLI)           | dbt Cloud                       | dbt Core gratis dan feature-complete                   |
| **Warehouse**      | PostgreSQL / DuckDB      | BigQuery / Snowflake / Redshift | PostgreSQL cukup untuk belajar konsep                  |
| **Storage**        | MinIO (S3-compatible)    | AWS S3 / GCS                    | MinIO API identical dengan S3                          |
| **Processing**     | Polars (local)           | PySpark (cluster)               | Konsep sama, scale beda                                |
| **Streaming**      | Redpanda (single node)   | Kafka (managed)                 | Redpanda = Kafka API, less resource                    |
| **Quality**        | Great Expectations       | Monte Carlo / Soda              | GX gratis dan powerful                                 |

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[system-design|System Design]] — Database Internals & Architecture patterns
- [[math-and-algorithms|Matematika & Algoritma]] — Linear Algebra untuk ML pipeline
- [[computer-science-foundations|Computer Science Foundations]] — OS Internals yang mendukung distributed systems
- [[devops|DevOps Roadmap]] — CI/CD dan container orchestration overlap
- [[software-engineering|Roadmap_Software_Engineering]] — Backend skill = fondasi Data Engineering
- [[agentic-ai-mcp-roadmap|Agentic AI & MCP Roadmap]] — Jalur karir engineering AI agents
- [[ai-engineering-stack-roadmap|AI Engineering Stack Roadmap]] — Jalur karir MLOps / LLMOps
- [[infrastructure-administrator|IT Systems Engineer Roadmap]] — Jalur karir systems & infrastructure engineering

---

_Roadmap Data Engineering | Fase 1 (SQL/Python) → Fase 4 (Streaming) · 10 Bulan_
