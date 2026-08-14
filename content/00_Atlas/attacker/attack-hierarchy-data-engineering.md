---
title: Attack Perspective — Data Engineering (Red Team)
tags: [attack,red-team,data-engineering,etl,spark,kafka,data-lake,exfiltration]
source: hierarchy-data-engineering.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Data Engineering — Perspektif Penyerang

> Data engineering = ETL pipeline, data lake, Spark/Kafka, warehouse. Red team serang: pipeline inject (malicious data), data lake exfiltration, warehouse credential theft, Kafka intercept.

## 1. Attack Surface Data Engineering

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **ETL Pipeline** | Inject malicious data → warehouse poison | T1190 | Source compromise → ETL ingest → warehouse contaminate | ETL = trusted transformation | Data quality audit = rare |
| **Spark Cluster** | Driver compromise → cluster RCE → data exfil | T1222 | Spark UI (no auth) → submit job → RCE → cluster | Spark UI = default open | Spark audit = rare |
| **Kafka** | Topic intercept → credential theft in message | T1557 | Consumer group hijack → read all message | Kafka = no TLS default | Kafka audit = rare |
| **Data Lake (S3/HDFS)** | Public bucket → data exfiltration | T1530 | s3 sync → download all → exfil | Anonymous = no trace | S3 audit log = rare |
| **Data Warehouse (Snowflake/BigQuery)** | Credential theft → query → data dump | T1003 | Stored credential → query → dump | Query = legit operation | Query audit = delayed |
| **dbt (Transform)** | SQL injection in dbt model → warehouse RCE | T1190 | dbt macro inject → arbitrary SQL → warehouse | dbt = trusted transformation | dbt audit = rare |
| **Airflow (Orchestrator)** | DAG injection → arbitrary code execution | T1190 | DAG file write → Airflow scheduler → RCE | Airflow = code execution platform | Airflow audit = rare |

## 2. Data Pipeline Attack Chain

```
Recon: Identifikasi data stack (dashboard, API, leak)
 ├── BI dashboard (Tableau, PowerBI, Looker) → tech stack inference
 ├── ETL tooling (dbt, Airflow, Spark) → pipeline map
 └→ Data warehouse (Snowflake, BigQuery, Redshift) → type identification
 ↓
Initial Access:
 ├── Spark UI open (no auth) → submit job → RCE → cluster
 ├── Airflow DAG write → scheduler execute → RCE → airflow
 ├── Warehouse credential theft → direct query → data dump
 └→ S3/HDFS bucket public → anonymous → data download
 ↓
Exfiltration:
 ├── Warehouse: SELECT * → dump → cloud storage exfil (rclone)
 ├── Kafka: topic consumer → intercept all message → credential in payload
 └→ Data lake: s3 sync → bulk download → rclone → cloud exfil
 ↓
Persistence:
 ├── Spark/Airflow: scheduled job → periodic data exfil
 ├── Warehouse: stored proc → backdoor query → periodic dump
 └→ Data lake: lambda trigger → copy → attacker bucket
 ↓
Impact: Full data exfiltration (PII, financial, intellectual property)
```

## 3. Tool Stack

| Tool | Use |
|------|-----|
| **Apache Spark** | Cluster compute (if exposed → RCE) |
| **Apache Airflow** | DAG injection (if write access → RCE) |
| **rclone** | Cloud data exfiltration (multi-provider) |
| **aws s3** / **gsutil** | Cloud storage data dump |
| **snowsql** | Snowflake query (credential theft → dump) |
| **bq** (BigQuery CLI) | BigQuery query (credential theft → dump) |

## 5. Referensi
- Apache Spark Security — https://spark.apache.org/docs/latest/security.html
- Airflow Security — https://airflow.apache.org/docs/apache-airflow/stable/security/
- Snowflake Security — https://docs.snowflake.com/en/user-guide/security
- Kafka Security — https://kafka.apache.org/documentation/#security