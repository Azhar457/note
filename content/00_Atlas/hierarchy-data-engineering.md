---
title: 📊 Data Engineering — Dari Ingestion ke Data Product
tags:
- hierarchy
- data
- pipeline
- etl
- lakehouse
- big-data
- streaming
aliases:
- Data Engineering Hierarchy
- Data Pipeline Stack
- From Ingestion to Serving
- Data Architecture Map
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# 📊 Data Engineering — Dari Ingestion ke Data Product

> [!tip] Data engineering adalah disiplin yang **mengubah data mentah menjadi aset yang dapat dianalisis**. Catatan ini memetakan **7 lapisan pipeline data** dari ingestion hingga data product serving, perbandingan batch vs streaming, lakehouse architecture (Iceberg/Delta/Parquet), dan decision framework. Dengan 327 hits di vault, data engineering adalah **domain terbanyak kedua** yang dirujuk tapi belum memiliki hierarchy master sama sekali.

---

## Daftar Isi

1. [[#1. Premise — Data Engineering Adalah Tulang Punggung AI]]
2. [[#2. Seven-Layer Data Pipeline]]
3. [[#3. Layer 0 — Data Source & Ingestion]]
4. [[#4. Layer 1 — Storage & Lakehouse]]
5. [[#5. Layer 2 — Processing: Batch & Stream]]
6. [[#6. Layer 3 — Transformation (ETL/ELT)]]
7. [[#7. Layer 4 — Orchestration & Scheduling]]
8. [[#8. Layer 5 — Serving Layer]]
9. [[#9. Layer 6 — Observability & Governance]]
10. [[#10. Batch vs Streaming: Decision Framework]]
11. [[#11. Lakehouse Architecture (Iceberg + Delta + Parquet)]]

---

## 1. Premise — Data Engineering Adalah Tulang Punggung AI

Tanpa data engineering yang baik, model AI hanyalah teorema yang tidak bisa diimplementasikan:

```
[Source Systems] → [Ingestion] → [Storage] → [Processing] → [Serving]
                        ↓              ↓            ↓
                   CDC/Kafka        Lakehouse    Batch/Stream
```

**Mengapa ini penting:**
- 80% waktu data scientist = data preparation (bukan modeling)
- Data pipeline yang buruk → GIGO (Garbage In, Garbage Out)
- Data lake tanpa governance → data swamp
- Feature store menjembatani engineering dan ML

---

## 2. Seven-Layer Data Pipeline

| Layer | Fungsi | Tools Khas | Failure Mode |
|:-----:|--------|-----------|--------------|
| **L0** | Source & Ingestion | Kafka, Debezium, Fivetran, Airbyte | Schema drift, CDC lag |
| **L1** | Storage & Lake | S3/MinIO, HDFS, Iceberg/Delta/Parquet | Corruption, cost explosion |
| **L2** | Processing | Spark, Flink, dbt, Ray | Shuffle skew, OOM |
| **L3** | Transformation | dbt, Spark SQL, Airflow | Lineage lost, dependency hell |
| **L4** | Orchestration | Airflow, Prefect, Dagster, Temporal | DAG failure cascade |
| **L5** | Serving | Trino, Druid, Pinot, ClickHouse | Query latency, index miss |
| **L6** | Observability | Datahub, Marquez, Great Expectations | Data quality silent failure |

---

## 3. Layer 0 — Data Source & Ingestion

### 3.1 Sumber Data

| Type | Contoh | Volume | Velocity |
|------|--------|:------:|:--------:|
| **OLTP DB** | PostgreSQL, MySQL, SQL Server | GB-TB | Perubahan per detik |
| **SaaS API** | Salesforce, HubSpot, Stripe | MB-GB | Per jam |
| **Logs** | Application, server, CDN | GB-TB/s | Stream |
| **IoT** | Sensor, device telemetry | TB-PB | High frequency |
| **Clickstream** | Web/mobile events | TB-PB | Real-time |

### 3.2 CDC (Change Data Capture)

Teknik capture perubahan database tanpa query polling:

| CDC Type | Mekanisme | Latency | Overhead |
|----------|-----------|:-------:|:--------:|
| **Log-based** | Baca WAL (Write-Ahead Log) | ms | Minimal |
| **Trigger-based** | DB trigger → audit table | ms | Signifikan |
| **Query-based** | `WHERE updated_at > last_poll` | s-min | Tinggi |
| **XMIN** (Postgres) | System column XMIN | s | Rendah |

**Tool:** Debezium (Kafka Connect), AWS DMS, Fivetran, Airbyte

---

## 4. Layer 1 — Storage & Lakehouse

### 4.1 File Format Comparison

| Format | Compression | Schema Evolution | Splittable | Use Case |
|--------|:-----------:|:----------------:|:----------:|----------|
| **CSV/JSON** | ❌ | ❌ | ✅ | Ad-hoc, small data |
| **Avro** | ✅ Moderate | ✅ | ✅ | Row-oriented, Kafka |
| **Parquet** | ✅ Excellent | ✅ | ✅ | **Analytics** (columnar) |
| **ORC** | ✅ Excellent | ✅ | ✅ | Hive/Spark (columnar) |
| **Iceberg** | ✅ (Parquet) | ✅ (Full DDL) | ✅ | ✅ **Lakehouse** |
| **Delta Lake** | ✅ (Parquet) | ✅ (Full DDL) | ✅ | ✅ **Lakehouse** |

### 4.2 Lakehouse Table Format — Iceberg vs Delta

| Fitur | Apache Iceberg | Delta Lake |
|-------|---------------|------------|
| **Open source** | ✅ Apache | ❌ LF AI (but open) |
| **Time travel** | ✅ Snapshot isolation | ✅ Version log |
| **ACID** | ✅ Row-level | ✅ Row-level |
| **Partition evolution** | ✅ (hidden partitioning) | ❌ (must rewrite) |
| **Catalog** | REST, Hive, Glue, Nessie | Unity Catalog, Hive |
| **Engine support** | Spark, Flink, Trino, Presto, Dremio, Snowflake, Athena | Spark, Flink, Trino, Presto, Databricks |
| **Z-ordering** | ✅ Sort order | ✅ Z-order by column |
| **Merge** | ✅ MERGE INTO | ✅ MERGE INTO |

### 4.3 Lakehouse Architecture

```
┌───────────────────────────────────────────────────┐
│ [Serving Layer] Trino, Spark, Snowflake, Athena    │
├───────────────────────────────────────────────────┤
│ [Table Format] Iceberg / Delta Lake                │
│   ├─ Snapshot isolation (time travel)              │
│   ├─ ACID transactions                             │
│   └─ Schema evolution                              │
├───────────────────────────────────────────────────┤
│ [Storage] Object Store (S3, MinIO, GCS, HDFS)      │
│   ├─ Parquet columnar data                         │
│   ├─ Manifest / metadata files                     │
│   └─ Compaction (optimize small files)             │
└───────────────────────────────────────────────────┘
```

---

## 5. Layer 2 — Processing: Batch & Stream

### 5.1 Batch Processing

| Framework | Model | Skala | Latensi |
|-----------|-------|:-----:|:-------:|
| **Spark** | DAG (in-memory) | 1-1000 node | menit-jam |
| **MapReduce** (legacy) | Disk-based | masif | jam |
| **Hive/Spark SQL** | SQL declarative | 1-1000 node | menit-jam |
| **dbt** | SQL + templating | Single node | menit |
| **Pandas/Polars** | Single-node | < 1 node | detik-menit |

### 5.2 Stream Processing

| Framework | Model | Semantics | State? |
|-----------|-------|:---------:|:------:|
| **Apache Flink** | True streaming | Exactly-once | ✅ RocksDB |
| **Kafka Streams** | Library (embedded) | Exactly-once | ✅ Local |
| **Spark Streaming** | Micro-batch | At-least-once | ✅ State store |
| **RisingWave** | Streaming SQL | Exactly-once | ✅ Internal |
| **Materalize** | Streaming SQL | Exactly-once | ✅ DuckDB |
| **ksqlDB** | Streaming SQL | At-least-once | ✅ Kafka |

**Benchmark:**
```
Technology         Latency         Throughput
Flink              <100ms          1M+ events/s
Kafka Streams      <10ms           500K events/s
Spark Streaming    1-10s           1M+ events/s
RisingWave         <1s             100K events/s
```

---

## 6. Layer 3 — Transformation (ETL/ELT)

### 6.1 ETL vs ELT

| Aspek | ETL (Extract-Transform-Load) | ELT (Extract-Load-Transform) |
|-------|:----------------------------:|:----------------------------:|
| **Transform location** | Transform engine (Spark) | Target data warehouse |
| **Schema** | On-write schema | On-read schema |
| **Raw data** | Not preserved | Preserved |
| **Latency to insight** | Lebih lambat | Lebih cepat |
| **Tool modern** | dbt, Spark, Airflow | dbt + Snowflake/BigQuery |

### 6.2 dbt (Data Build Tool)

**Arsitektur dbt:**
```
SQL Model (*.sql) → dbt → Compiled SQL → Run on Warehouse
                           ├─ Lineage graph
                           ├─ Data quality tests
                           └─ Documentation generation
```

**Model tiers (dbt convention):**
| Tier | Nama | Konten |
|:----:|------|--------|
| **Staging** | stg_* | Raw → clean types, rename columns |
| **Intermediate** | int_* | Joins, aggregations, business logic |
| **Marts** | dim_*, fct_* | Kimball: dimension + fact tables |
| **Metrics** | metrics.yml | Business metrics layer |

---

## 7. Layer 4 — Orchestration & Scheduling

### 7.1 Orchestrator Comparison

| Tool | DAG Definition | Scheduler | Backend | Retry |
|------|---------------|-----------|---------|:-----:|
| **Airflow** | Python | Time-based | Celery/K8s | ✅ |
| **Prefect** | Python | Events + time | Serverless | ✅ |
| **Dagster** | Python | Assets + time | K8s | ✅ |
| **Temporal** | Code (Go/Java/Python) | Timer + events | DB | ✅ |
| **Kestra** | YAML | Events + time | K8s | ✅ |
| **Digdag** | YAML | Time-based | DB | ✅ |

### 7.2 Airflow DAG Internals

```
DAG: data_pipeline_v2
├── extract_from_postgres (PostgresOperator)
│   └── load_raw_to_s3 (S3UploadOperator)
├── process_with_spark (SparkSubmitOperator)
│   └── [sensor] await_spark_completion
├── dbt_run_staging (BashOperator)
├── dbt_run_marts (BashOperator)  ← depends on dbt_run_staging
└── dbt_test (BashOperator)
```

---

## 8. Layer 5 — Serving Layer

### 8.1 OLAP Query Engines

| Engine | Architecture | Query Latency | Concurrency | Index |
|--------|-------------|:-------------:|:-----------:|:-----:|
| **Trino/Presto** | Distributed (MPP) | 1-30s | High | ❌ |
| **ClickHouse** | Columnar (MPP) | <1s | Very High | ✅ |
| **Druid** | Pre-aggregation | <1s | High | ✅ |
| **Pinot** | Pre-aggregation | <100ms | Very High | ✅ |
| **Snowflake** | Cloud MPP | 1-30s | High | ❌ |
| **BigQuery** | Serverless | 1-30s | Unlimited | ❌ |

### 8.2 Feature Store

Konsep kunci untuk ML — menjembatani data engineering dan ML engineering:

| Feature Store | Offline Store | Online Store | Point-in-time |
|---------------|:-------------:|:------------:|:-------------:|
| **Feast** | Spark, BigQuery | Redis | ✅ |
| **Tecton** | Snowflake, Spark | DynamoDB | ✅ |
| **Hopsworks** | HopsFS | MySQL Cluster | ✅ |
| **Vertex AI Feature Store** | BigQuery | Online store | ✅ |

**Online vs Offline:**
- **Offline:** Training dataset — big batch, historical features
- **Online:** Model inference — low-latency, latest feature values

---

## 9. Layer 6 — Observability & Governance

### 9.1 Data Quality

| Tool | Checks | Freshness | Schema |
|------|--------|:---------:|:------:|
| **Great Expectations** | ✅ Expectations | ❌ | ✅ |
| **dbt tests** | ✅ Built in | ❌ | ✅ |
| **Soda** | ✅ SQL checks | ✅ | ✅ |
| **Deequ** (AWS) | ✅ Scala/Spark | ❌ | ❌ |

### 9.2 Data Catalog

| Tool | Lineage | Discovery | Governance |
|------|:-------:|:---------:|:----------:|
| **Datahub** | ✅ | ✅ | ✅ Tags, glossary |
| **Amundsen** (Lyft) | ❌ | ✅ | ❌ |
| **Apache Atlas** | ✅ | ✅ | ✅ |
| **Marquez** | ✅ | ❌ | ❌ |
| **dbt Docs** | ✅ Lineage graph | ✅ | ❌ |

---

## 10. Batch vs Streaming: Decision Framework

### 10.1 Pilih Berdasarkan

```
Latency need?
├─ Real-time (< 1s) → Stream processing (Flink/Kafka Streams)
├─ Near real-time (< 1m) → Micro-batch (Spark Streaming)
├─ Minutes → Batch (Spark, dbt)
└─ Hours/days → Scheduled batch

Data volume?
├─ > 100 TB/day → Streaming (Kafka + Flink) atau Incremental batch
├─ 1-100 TB/day → Spark batch
└─ < 1 TB/day → dbt + warehouse

Source pattern?
├─ Continuous (logs, events) → Stream
├─ Scheduled (ERP, nightly) → Batch
└─ CDC (DB changes) → Stream via Debezium
```

### 10.2 Lambda vs Kappa Architecture

| Aspek | Lambda | Kappa |
|-------|--------|-------|
| **Batch path** | ✅ Seperate | ❌ Tidak ada |
| **Stream path** | ✅ Real-time | ✅ All-stream |
| **Complexity** | 2× (batch + stream) | 1× (stream only) |
| **Consistency** | Reconciliation needed | Single source |
| **Use case** | Legacy, batch-heavy | Greenfield, stream-native |

---

## 11. Cross-Reference ke Vault

| Layer | Catatan Vault |
|:-----:|---------------|
| **L0** | [[hierarchy-abstraction-layers]] — Data layer L8 |
| **L1** | [[hierarchy-database-storage-systems]], [[hierarchy-memory-storage]] — Tier 5-7 |
| **L2** | [[hierarchy-concurrency-consensus]] — Distributed processing |
| **L3** | [[advanced-chunking-strategies-deepdive]] — Document chunking |
| **L4** | [[00_Atlas/hierarchy-devops-cicd]] — Pipeline orchestration |
| **L5** | [[00_Atlas/hierarchy-llm-ai-systems]] — ML serving + RAG |
| **L6** | [[00_Atlas/hierarchy-cybersecurity-defense-architecture]] — Data governance L3 |

---

## References

1. Kleppmann, M. *"Designing Data-Intensive Applications."* O'Reilly, 2017.
2. Kimball, R. & Ross, M. *"The Data Warehouse Toolkit."* 3rd ed., Wiley, 2013.
3. Narkhede, N., Shapira, G., Palino, T. *"Kafka: The Definitive Guide."* O'Reilly, 2017.
4. Armbrust, M. et al. *"Lakehouse: A New Generation of Open Platforms."* CIDR 2021.
5. Apache Iceberg. *"Iceberg Table Spec v3."* (2024).
6. Delta Lake. *"Delta Lake Protocol."* (2024).
7. Carbone, P. et al. *"Apache Flink: Stream and Batch Processing."* VLDB 2015.
8. Zaharia, M. et al. *"Apache Spark: A Unified Engine for Big Data Processing."* CACM 2016.
9. dbt Labs. *"dbt Documentation."* (2024).
10. Marx, R. *"The Data Engineering Cookbook."* 2020.
11. Hueske, F. & Kalavri, V. *"Stream Processing with Apache Flink."* O'Reilly, 2019.
