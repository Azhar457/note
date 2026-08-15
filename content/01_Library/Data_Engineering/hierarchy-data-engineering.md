---
title: — Data Engineering Attack Surface
tags:
- vault
- note
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---


cssclasses:
  - wide-table
  

## Deepdive — Data Engineering Attack Surface

| Komponen | Vektor | Tool | Impact |
|----------|--------|------|--------|
| **ETL Pipeline** | Source poisoning (bad data inject) | Airflow DAG | Model drift, bad decision |
| **Kafka / Stream** | Message injection | kafka producer | Data corruption |
| **Data Lake (S3)** | Public bucket, ACL | aws s3 ls | Data leak |
| **Spark** | Code injection UDF | spark submit | RCE on cluster |
| **Warehouse** | SQL injection BI tool | dbt, Metabase | Data exfil |

## Referensi
- Spark Security — https://spark.apache.org/docs/latest/security.html
- Kafka Security — https://kafka.apache.org/documentation/#security

## Data Engineering — Pipeline, Warehouse & Attack Surface

### Pipeline Arsitektur

| Stage | Tool | Fungsi |
|-------|------|--------|
| **Ingest** | Kafka, Pulsar, CDC | Streaming ingest |
| **Transform (ETL)** | Spark, dbt, Airflow | Clean, join, enrich |
| **Store (Warehouse)** | Snowflake, BigQuery, Redshift | Analytics store |
| **Store (Lake)** | S3, GCS, HDFS | Raw + processed |
| **Serve (BI)** | Metabase, Looker, Superset | Query + visualize |
| **Orchestrate** | Airflow, Prefect, Dagster | DAG scheduling |

### Attack Vector per Komponen

| Komponen | Attack | Impact | Tool |
|----------|--------|--------|------|
| **Kafka** | Topic injection | Data flood, corrupt stream | kafka-console-producer |
| **Spark** | UDF code injection | RCE on cluster | spark-submit |
| **Airflow** | DAG injection | RCE, data tamper | Airflow REST API |
| **S3/Data Lake** | Public bucket, ACL abuse | Data leak | aws s3 ls |
| **BI (Metabase)** | SQL injection | Data exfil, lateral | Manual |
| **Warehouse (Snowflake)** | Over-privileged role | Data exfil | Snowflake SQL |
| **CDC (Debezium)** | Stream tamper | Data corruption | Topic hijack |

### Data Exfiltration via Pipeline

```
Red Team Scenario:
  1. Compromise Airflow worker (SSRF, RCE)
  2. Inject DAG → query warehouse → exfil to S3 attacker
  3. Or: compromise Spark cluster → UDF → read production data → write to S3 attacker
    ↓
Result: Production data → attacker S3 → no SIEM alert (looks like legit ETL job)
```

### Data Quality & Poisoning Attack

| Attack | Teknik | Impact |
|--------|--------|--------|
| **Label flip** | Flip labels in training data | Model accuracy drop |
| **Feature injection** | Add malicious feature | Model bias manipulation |
| **Data drift** | Shift input distribution | Model performance degradation |
| **Pipeline tamper** | Modify ETL transformation | Downstream corruption |

## Referensi
- Apache Kafka Security — https://kafka.apache.org/documentation/#security
- Apache Spark Security — https://spark.apache.org/docs/latest/security.html
- Airflow Security — https://airflow.apache.org/docs/apache-airflow/stable/security/
- OWASP Data Engineering — https://owasp.org/www-project-web-security-testing-guide/

## Koneksi ke Vault & Cross-Reference

| Catatan | Hubungan |
|---------|----------|
| Zero Trust | Network segment untuk infra |
| Supply Chain | Pipeline security overlap |
| Cloud IAM | Privilege escalation path |
| Endpoint Security | Runner compromise path |

## Best Practices & Pitfall

1. **GitOps**: Infrastructure config (manifest) ada di Git — versioned, reviewed, auditable. Tetapi Git token = attack surface → rotate, scoped.
2. **Immutable Artifact**: Setiap build = image/untouched hash. Signature verification di deploy. Realitas: banyak still manual deploy.
3. **Least Privilege CI**: Runner token punya scope minimal — bukan global admin. Realitas: `repo:*` scope masih common di setup.
4. **Network Isolation**: Runner segment terpisah production → securitas blance. Tetapi: many org simplify by same VPC → risk.
5. **Audit Log**: Semua CI/CD action di-log dan immutable. Realitas: log retention pendek, alerting belum sentral.
6. **Provenance (SLSA)**: Setiap artifact terlampir provenance (build manifest + source hash). Realitas: adopsi masih rendah di 2025.

## Pitfall Nyata yang Sering Ditemui

- **Leaked token di git history**: git log → credential exposure → scanner attacker → compromise. Fix: BFG repo-cleaner + token rotation.
- **Runner has persistent secrets**: Runner VM menyimpan `~/.aws/credentials` atau `.docker/config.json` → next user can access. Fix: ephemeral runner, no persistent state.
- **Default branch is `main`**: CI jalan di `main`. PR branch dapat trigger → secret exposed. Fix: `pull_request_target` only trusted contributors.
- **Trusted Action pins tag not SHA**: Tag `actions/checkout@v4` → bisa di-hijack jika maintainer compromised. Fix: pin SHA.
- **No SBOM**: Artifact jadi → no manifest → maka after compromised, tidak tahu apa yang affected. Fix: `syft` generate SBOM pada build.

## Tool Stack Lengkap

| Tool | Stage | Use |
|------|-------|-----|
| **GitHub Actions / GitLab CI** | Build | Pipeline |
| **ArgoCD / Flux** | Deploy | GitOps continuous delivery |
| **Trivy / Grype** | Scan | Image + dep vuln scan |
| **Syft** | Scan | SBOM generation |
| **Cosign / Sigstore** | Sign | Artifact signing |
| **Open Policy Agent (OPA)** | Enforce | Policy as code |
| **HashiCorp Vault** | Secret | Secret management |
| **Prometheus + Grafana** | Monitor | Metrics + dashboard |

## Konsep Dasar — Data Lifecycle

### Data Lifecycle Stage

```
Generate → Ingest → Store → Transform → Analyze → Serve → Archive
  ↓         ↓        ↓         ↓          ↓         ↓        ↓
Source   Kafka    S3/Lake   Spark/ETL  Warehouse   BI   Glacier
```

### Batch vs Stream Processing

| Aspek | Batch | Stream |
|-------|-------|--------|
| **Latency** | Menit/jam | Detik/milidetik |
| **Volume** | Big volume | Continuous |
| **Tool** | Spark, Hadoop | Kafka Streams, Flink |
| **Use** | Daily report | Real-time alert |
| **Complexity** | Lower | Higher (windowing, state) |

### Warehouse Architecture (Redshift/Snowflake)

```
Storage Commissioner:
  ├── Compute node (CPU + cache)
  ├── Storage (S3 → compute via cache)
  └→ Network → query route

Query: SQL → optimizer → executor → result
  ├── MPP (Massively Parallel Processing) → split across nodes
  ├── Columnar storage → efficient scan
  └→ Materialized view → pre-computed
```

### Data Governance & Security Control

| Control | Tool | Scope |
|---------|------|-------|
| **Access (RBAC)** | Snowflake GRANT, BigQuery IAM | Who can query |
| **Row-level security** | Policy | Per-user row filter |
| **Column-level security** | Masking/tag | PII column hidden |
| **Audit** | Snowflake ACCESS_HISTORY | Query log |
| **Lineage** | OpenLineage, Amundsen | Track data flow |
| **PII detection** | AWS Macie, GCP DLP | Auto-classify |

## Referensi Tambahan
- Snowflake Security — https://docs.snowflake.com/en/user-guide/security
- Kafka Streams — https://kafka.apache.org/36/documentation/streams/
- OpenLineage — https://openlineage.io/
---

audited
---
