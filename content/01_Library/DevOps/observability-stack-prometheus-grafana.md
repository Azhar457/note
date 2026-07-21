---
title: 'Observability Stack: Prometheus, Grafana & Logging Pipeline'
tags:
- observability
- prometheus
- grafana
- monitoring
- logging
- devops
- library
aliases:
- prometheus-grafana-setup-deepdive
- logging-pipeline-loki-vector
- monitoring-stack-homelab
created: '2026-07-15'
updated: '2026-07-15'
status: draft
cssclasses:
- wide-table
---

# 📊 Observability Stack: Prometheus, Grafana & Logging Pipeline

> Vault punya [[site-reability-engineering]] yang bahas SRE secara konseptual (SLO, error budget, toil) dan [[cicd-guide]] untuk pipeline deployment. Tapi gak ada catatan yang bahas **toolkit observability secara konkret**: Prometheus buat metrics, Grafana buat dashboard, Loki/Vector buat logs, Tempo/Jaeger buat tracing. Catatan ini jembatin teori SRE ke implementasi — dari setup exporter, query PromQL, dashboard design, sampe logging pipeline yang scalable. Tanpa observability, lo operasi sistem dalam kegelapan.

> [!info] Posisi di Vault
> Ini adalah **implementasi konkret** dari konsep SRE di [[site-reability-engineering]]. Juga terhubung dengan [[cicd-shiftleft-shiftright]] (shift-right = observability di production), [[devops]] (prinsip DevOps), [[container-kubernetes-security-deepdive]] (monitoring container), dan [[waf-reverse-proxy-deepdive]] (WAF metrics & alerting).

---

## Daftar Isi

- [[#1. Observability vs Monitoring — Bedanya?]]
- [[#2. Prometheus — Metrics & Alerting]]
- [[#3. PromQL — Query Language untuk Engineer]]
- [[#4. Exporters — Cara Kerja & Setup]]
- [[#5. Grafana — Dashboard yang Efektif]]
- [[#6. Logging Pipeline — Vector, Loki, Elasticsearch]]
- [[#7. Distributed Tracing — Jaeger, Tempo, OpenTelemetry]]
- [[#8. Alerting — Alertmanager, On-Call, Runbooks]]
- [[#9. Service Level Objectives — SLI, SLO, Error Budget]]
- [[#10. Perbandingan Tools]]
- [[#🔗 Koneksi ke Catatan Lain]]
- [[#✅ Checklist]]
- [[#Roadmap Belajar]]

---

## 1. Observability vs Monitoring — Bedanya?

```
Monitoring = "Is the system working?"
  → Tanya: uptime, CPU, memory, disk
  → Output: dashboard hijau/merah, alert on/off

Observability = "Why is the system not working?"
  → Tanya: high cardinality, distributed tracing, structured logging
  → Output: root cause dari interaksi complex systems
```

**Tiga pilar observability:**
1. **Metrics** — angka yang bisa di-aggregate (Prometheus)
2. **Logs** — event diskrit, immutable, timestamped (Vector → Loki/ES)
3. **Traces** — end-to-end request flow antar service (Jaeger, Tempo)

| Aspek | Monitoring | Observability |
|-------|-----------|---------------|
| Scope | Known unknowns | Unknown unknowns |
| Data | CPU, memory, disk | High-cardinality, request-level |
| Debug | "Apa yang mati?" | "Kenapa lambat?" |
| Approach | Reactive (alert → fix) | Proactive (explore → understand) |
| Tools | Nagios, Zabbix | Prometheus, Grafana, Loki |

---

## 2. Prometheus — Metrics & Alerting

### 2.1 Arsitektur

```
[Node Exporter] ─── scrape /metrics ──→ [Prometheus Server]
[Postgres Exp.] ────┘                        │
[Blackbox Exp.] ─────┘                       │
[Custom Exporter] ───┘                       │
                                             ├──→ [Grafana] (visualization)
                                             ├──→ [Alertmanager] (alerts)
                                             │       └──→ [Telegram/PagerDuty]
                                             └──→ [PromQL API] (ad-hoc query)
```

**Komponen:**
- **Prometheus Server** — pull model: scrape /metrics endpoint tiap interval
- **Exporters** — expose metrics dari berbagai service (node, postgres, nginx)
- **Pushgateway** — untuk job batch yang lifespan pendek (push model)
- **Alertmanager** — alert routing, silencing, inhibition
- **Service Discovery** — file_sd, consul_sd, kubernetes_sd

### 2.2 Metric Types

**Counter (hanya naik):**

```
http_requests_total{method="GET", status="200"} 1024
http_requests_total{method="POST", status="500"} 42
# Hanya naik, reset ketika restart
# Query rate: rate(http_requests_total[5m])
```

**Gauge (naik-turun):**

```
node_memory_MemAvailable_bytes 8589934592
node_cpu_usage_percent 45.2
# Snapshot immediate value
```

**Histogram (distribusi bucket):**

```
http_request_duration_seconds_bucket{le="0.1"} 500    # 500 request < 100ms
http_request_duration_seconds_bucket{le="0.5"} 800    # 800 request < 500ms
http_request_duration_seconds_bucket{le="1.0"} 950    # 950 request < 1s
http_request_duration_seconds_bucket{le="+Inf"} 1000  # 1000 total
http_request_duration_seconds_sum 450.0               # total duration
http_request_duration_seconds_count 1000               # total count
# Query p99: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

**Summary (sama tapi pre-computed quantile):**

```
rpc_duration_seconds{quantile="0.5"} 0.05   # median
rpc_duration_seconds{quantile="0.99"} 0.5   # p99
rpc_duration_seconds_sum 450.0
rpc_duration_seconds_count 1000
# Summary pre-compute di application — lebih mahal CPU
# Histogram compute di query — lebih fleksibel
```

### 2.3 Instrumentasi Aplikasi

```python
# Python Prometheus client
from prometheus_client import Counter, Histogram, generate_latest, start_http_server
import time

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests',
                        ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'Request latency',
                             ['method', 'endpoint'],
                             buckets=[0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0])

@REQUEST_DURATION.labels(method='GET', endpoint='/api/users').time()
def handle_request():
    time.sleep(0.1)  # simulate work
    REQUEST_COUNT.labels(method='GET', endpoint='/api/users', status='200').inc()

# Expose /metrics endpoint
start_http_server(8000)  # Prometheus scrape di :8000/metrics
```

### 2.4 Storage & Retention

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

storage:
  tsdb:
    # Default: 15d di local disk
    retention.time: 30d
    # Max block size: 512MB
    # Total space ≈ rate(ingested_samples) × 2 bytes × retention

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

**Keterbatasan Prometheus:**
- **Single node** — tidak HA secara native (Thanos/Cortex/Mimir untuk HA)
- **Not for logs** — Prometheus bukan log storage
- **Not for events** — gak cocok untuk event dengan cardinality sangat tinggi
- **Local storage** — perlu remote write untuk long-term retention

---

## 3. PromQL — Query Language untuk Engineer

### 3.1 Instant Vector vs Range Vector

```promql
# Instant vector — nilai saat ini
node_memory_MemAvailable_bytes

# Range vector — nilai dalam rentang waktu (5 menit)
node_memory_MemAvailable_bytes[5m]
```

### 3.2 Rate, Increase, dan Derivative

```promql
# Rate per detik (rata-rata over 5m)
rate(http_requests_total[5m])

# Total increase dalam 1 jam
increase(http_requests_total[1h])

# Perubahan per detik (gauge)
deriv(node_memory_MemAvailable_bytes[30m])
```

### 3.3 Aggregation Operators

```promql
# By label
sum by(instance) (rate(http_requests_total[5m]))

# Without label
sum without(job) (rate(http_requests_total[5m]))

# Quantile (untuk histogram)
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Top/Bottom
topk(3, rate(http_requests_total[5m]))
bottomk(3, rate(http_requests_total[5m]))
```

### 3.4 Useful Queries

```promql
# Node CPU usage %
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage %
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk space remaining %
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100

# Request error rate (5xx / total)
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Service Health SLO compliance — 99.9% uptime over 30d
(1 - (sum(increase(http_requests_total{status=~"5.."}[30d])) / sum(increase(http_requests_total[30d])))) * 100

# Kubernetes pod CPU
sum by(pod) (rate(container_cpu_usage_seconds_total{pod!=""}[5m]))
```

---

## 4. Exporters — Cara Kerja & Setup

### 4.1 Node Exporter

```yaml
# docker-compose.yml
services:
  node-exporter:
    image: prom/node-exporter:latest
    command:
      - '--path.rootfs=/host'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - '9100:9100'
    volumes:
      - '/:/host:ro,rslave'
```

**Metrics yang disediakan:**
- `node_cpu_seconds_total` — CPU time by mode
- `node_memory_MemAvailable_bytes` — available memory
- `node_disk_io_time_seconds_total` — disk I/O
- `node_network_receive_bytes_total` — network throughput
- `node_filesystem_avail_bytes` — disk space
- `node_load1`, `node_load5`, `node_load15` — system load

### 4.2 Blackbox Exporter

```yaml
# Untuk probing endpoint eksternal (HTTP/HTTPS/TCP/ICMP)
services:
  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    command: '--config.file=/config/blackbox.yml'
    ports:
      - '9115:9115'
    volumes:
      - './blackbox.yml:/config/blackbox.yml'

# prometheus.yml tambahan:
scrape_configs:
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://example.com
        - https://app.internal.company.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115
```

### 4.3 Postgres Exporter

```yaml
services:
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    environment:
      DATA_SOURCE_NAME: "postgresql://monitor:password@localhost:5432/postgres?sslmode=disable"
    ports:
      - '9187:9187'
```

**Metrics penting:**
- `pg_stat_database_xact_commit` / `pg_stat_database_xact_rollback` — transaction rate
- `pg_stat_database_blks_hit` / `pg_stat_database_blks_read` — cache hit ratio
- `pg_stat_replication` — replication lag
- `pg_stat_user_tables` — live/dead tuples, seq scan vs idx scan

---

## 5. Grafana — Dashboard yang Efektif

### 5.1 Dashboard Design Principles

```
1. Satu dashboard = satu pertanyaan
   ❌ "System Overview" (CPU + DB + Network + App + Error rate)
   ✅ "Application Latency" (p50/p95/p99, error rate, request rate)

2. Top-down: Overview → Detail → Raw
   Row 1: Service health (4 singlestat: availability, latency, error rate, throughput)
   Row 2: Latency breakdown (graph: p50, p95, p99)
   Row 3: Error details (table: top 5 error endpoints)
   Row 4: Raw logs (Loki: last 50 error logs)

3. Gunakan template variables
   - $instance: pilih instance yang mau dilihat
   - $job: pilih service type
   - $env: production / staging

4. Annotations → overlay event
   - Deploy events (dari CI/CD pipeline)
   - Config changes
   - Alert firings
```

### 5.2 Variables & Templating

```ini
# Variable: instance
Name: instance
Type: Query
Query: label_values(node_cpu_seconds_total, instance)

# Variable: job
Name: job
Type: Query
Query: label_values(node_cpu_seconds_total, job)

# Variable: env (manual)
Name: env
Type: Custom
Values: production, staging, development

# Query menggunakan variable
100 - (avg by(instance) (
    rate(node_cpu_seconds_total{mode="idle", instance=~"$instance", job=~"$job"}[5m])
) * 100)
```

### 5.3 Panel Types

| Panel | Use Case | Data Format |
|-------|----------|-------------|
| **Time series** | Trendlines (CPU, latency, rate) | Time series |
| **Stat** | Single value (uptime, error rate) | Single query result |
| **Gauge** | Threshold-based (disk > 80%) | Single value + thresholds |
| **Table** | Detail data (slowest endpoints) | Table (multi-column) |
| **Bar chart** | Comparison (CPU by instance) | Categorical |
| **Heatmap** | Distribution (latency over time) | Histogram |
| **Logs** | Raw log viewer (Loki) | Log lines |
| **Traces** | Trace viewer (Tempo) | Trace spans |

### 5.4 Alert Rules di Grafana

```yaml
# alerting/rule.yaml
groups:
  - name: node_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Instance {{ $labels.instance }} CPU > 80%"
          description: "CPU usage at {{ $value }}% for 5 minutes"
          runbook_url: "https://runbooks.internal/cpu-saturation"

      - alert: CriticalCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} CPU > 95%"
```

---

## 6. Logging Pipeline — Vector, Loki, Elasticsearch

### 6.1 Arsitektur Logging

```
[Journald/Syslog] → [Vector Agent] → [Vector Aggregate] → [Loki/Elasticsearch]
                        │                     │                  │
                    File tail               Transform          Storage
                    Kubernetes logs         Buffer (disk)      Index
                    Docker logs             Routing by label   Grafana/Kibana
```

### 6.2 Vector — Modern Log Collector

**Kenapa Vector bukan Logstash/Fluentd?**
- Rust-based → memory safe, performa tinggi
- Resource usage 5-10x lebih rendah dari Logstash
- Satu binary, satu config language (TOML/VCL)
- Buffer di disk untuk durability

```toml
# vector.toml
[sources.journald]
type = "journald"
current_boot_only = true

[sources.nginx_logs]
type = "file"
include = ["/var/log/nginx/access.log"]

[transforms.parse_nginx]
type = "remap"
inputs = ["nginx_logs"]
source = '''
. = parse_regex!(.message, r'^(?P<client_ip>\S+) - - $$(?P<timestamp>[^$$]+)\] "(?P<method>\S+) (?P<path>\S+) \S+" (?P<status>\d+) (?P<size>\d+)')
.timestamp = parse_timestamp!(.timestamp, format: "%d/%b/%Y:%H:%M:%S %z")
'''

[sinks.loki]
type = "loki"
inputs = ["parse_nginx", "journald"]
endpoint = "http://loki:3100"
encoding.codec = "json"
labels.job = "vector"
```

### 6.3 Loki — Log Aggregation ala Prometheus

Loki berbeda dari Elasticsearch: **label-based, bukan full-text index**.

```yaml
# docker-compose.yml
services:
  loki:
    image: grafana/loki:latest
    command: -config.file=/etc/loki/loki-config.yaml
    ports:
      - '3100:3100'
    volumes:
      - ./loki-config.yaml:/etc/loki/loki-config.yaml
      - ./data/loki:/loki

  promtail:  # alternative to Vector (lighter, Grafana-native)
    image: grafana/promtail:latest
    command: -config.file=/etc/promtail/promtail-config.yaml
    volumes:
      - /var/log:/var/log
      - ./promtail-config.yaml:/etc/promtail/promtail-config.yaml
```

**LogQL — query language Loki:**

```logql
# Cari log dengan label job="nginx"
{job="nginx"}

# Filter dengan log content
{job="nginx"} |= "error"
{job="nginx"} |~ "5[0-9][0-9]"  # regex match 5xx
{job="api"} != "healthcheck"

# Log rate
rate({job="nginx"} |= "error"[5m])

# Aggregate
sum by(instance) (rate({job="nginx"} |~ "5.."[5m]))
```

### 6.4 Elasticsearch — Full-Text Search

Pilih Elasticsearch ketika butuh: full-text search, complex aggregations, atau sudah punya investasi ELK.

```yaml
# Minimal ES + Kibana
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.x
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - '9200:9200'

  kibana:
    image: docker.elastic.co/kibana/kibana:8.x
    ports:
      - '5601:5601'
```

### 6.5 Perbandingan Log Backend

| Aspek | Loki | Elasticsearch |
|-------|------|---------------|
| Storage model | Label + chunks | Full-text inverted index |
| Query language | LogQL (label-first) | DSL (JSON query) |
| Resource usage | Ringan (20% dari ES) | Berat (heap-heavy) |
| Scalability | Simple (distributed by label) | Complex (shards, replicas) |
| Retention | Efficient (chunk compression) | Space-intensive |
| Integration | Grafana native | Kibana |
| Use case | Kubernetes logs, infra logs | Application logs, SIEM |

---

## 7. Distributed Tracing — Jaeger, Tempo, OpenTelemetry

### 7.1 Kenapa Tracing?

```
Service A → Service B → Service C → Database
    |            |           |          |
  50ms         200ms       1.2s       5ms      → total response time = 1.45s
                                                  (tapi dari mana yang lambat?)
```

Tanpa tracing: "semuanya lambat." Dengan tracing: "Service C yang query DB-nya slow."

### 7.2 OpenTelemetry — Standard API

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import time

# Setup tracer
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="http://tempo:4317"))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# Trace a request
with tracer.start_as_current_span("handle_request") as span:
    span.set_attribute("http.method", "GET")
    span.set_attribute("http.url", "/api/users")
    
    with tracer.start_as_current_span("query_database") as db_span:
        time.sleep(0.1)  # simulate DB query
        db_span.set_attribute("db.system", "postgresql")
        db_span.set_attribute("db.statement", "SELECT * FROM users")
```

### 7.3 Tempo vs Jaeger

| Aspek | Jaeger | Grafana Tempo |
|-------|--------|---------------|
| Storage | Cassandra/ES/Badger | S3/GCS (object store) |
| Query | Jaeger UI | Grafana (Tempo datasource) |
| Schema | Modeled spans | Trace by ID + search by tags |
| Cost | Mahal (full index) | Murah (object storage) |
| Integration | Standalone UI | Grafana native |

---

## 8. Alerting — Alertmanager, On-Call, Runbooks

### 8.1 Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/...'

route:
  receiver: 'default'
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      repeat_interval: 1h
    - match:
        severity: warning
      receiver: 'slack-warning'

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#alerts'
        title: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: '...'
        severity: critical

  - name: 'slack-warning'
    slack_configs:
      - channel: '#alerts-warning'
        title: '[WARN] {{ .GroupLabels.alertname }}'
```

### 8.2 Alert Design Principles

```
❌ Bad alert: "CPU > 80%" (lo tahu tapi gak bisa action)
✅ Good alert: "Nginx connection pool exhausted — 503 errors > 1%"

Aturan:
1. Actionable → ada runbook yang jelas
2. Reliable → false positive < 5%
3. Urgent → perlu di-wake-up tengah malam?
4. Firing → for: 5m (jangan alert dari spike 1 menit)
5. Resolved → auto-resolve dalam 5 menit setelah metric normal
```

### 8.3 Runbook Template

```markdown
# Runbook: HighErrorRate

## Symptoms
- Grafana panel "Error Rate" > 1%
- Users complain "site error"
- PagerDuty alert fired

## Checklist
1. Cek Grafana dashboard "Service Latency" — apakah error rate naik di semua instance?
2. Cek log: `{job="nginx"} |= "5[0-9][0-9]"`
3. Cek recent deploy: apakah ada perubahan dalam 1 jam terakhir?
4. Cek upstream: apakah database/API masih hidup?
5. Rollback jika perlu

## Resolution
- Jika database: restart connection pool
- Jika deploy: rollback ke versi sebelumnya
- Jika traffic spike: scale up instances
```

---

## 9. Service Level Objectives — SLI, SLO, Error Budget

### 9.1 Definisi

```
SLI (Service Level Indicator): metric yang diukur
  → "Proportion of requests served under 500ms"
  → dalam PromQL: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

SLO (Service Level Objective): target SLI
  → "95% of requests under 500ms over 30 days"

Error Budget: 100% - SLO
  → Jika SLO = 99.9%, error budget = 0.1% = 43 menit/bulan
  → Error budget habis → stop feature releases → fokus reliability
```

### 9.2 Implementasi di Prometheus + Grafana

```promql
# SLI: latency p95 per 5m
histogram_quantile(0.95, sum by(le) (rate(http_request_duration_seconds_bucket[5m])))

# Error budget consumption (30d)
(1 - (sum(increase(http_requests_total{status=~"5.."}[30d]))
      / sum(increase(http_requests_total[30d])))) * 100
```

---

## 10. Perbandingan Tools

### Metrics Backend

| Aspek | Prometheus | Thanos | Mimir | VictoriaMetrics |
|-------|-----------|--------|-------|-----------------|
| HA | ❌ (single) | ✅ | ✅ | ✅ |
| Long-term storage | Local disk | S3/GCS | S3/GCS | S3/GCS |
| Query federation | ❌ | ✅ | ✅ | ✅ |
| Complexity | Rendah | Sedang | Tinggi | Rendah |
| Downsampling | ❌ | ✅ | ✅ | ✅ (auto) |
| Use case | Starter | Mid-scale | Large-scale | High-performance |

### Observability Stack

| Stack | Metrics | Logs | Traces | Complexity |
|-------|---------|------|--------|------------|
| **Prometheus + Loki + Tempo** | Prometheus | Loki | Tempo | Sedang |
| **Elastic (ELK)** | ❌ (APM) | Elasticsearch | APM | Tinggi |
| **Datadog** | ✅ SaaS | ✅ SaaS | ✅ SaaS | Rendah ($) |
| **Grafana Cloud** | ✅ SaaS | ✅ SaaS | ✅ SaaS | Rendah ($) |
| **Self-hosted LGTM** | Loki | Grafana | Tempo | Mimir | Tinggi |

---

## 🔗 Koneksi ke Catatan Lain

- [[site-reability-engineering]] — SRE butuh observability, catatan ini toolkit-nya
- [[cicd-guide]] — pipeline deployment butuh monitoring
- [[devops]] — observability = pilar utama DevOps
- [[cicd-shiftleft-shiftright]] — shift-right = observability di production
- [[container-kubernetes-security-deepdive]] — monitoring container = Prometheus ecosystem
- [[waf-reverse-proxy-deepdive]] — WAF metrics & alerting integration
- [[infrastructure-administrator]] — admin infra sehari-hari, butuh observability
- [[ebpf-beyond-security]] — Tetragon/eBPF untuk security observability

---

## ✅ Checklist

- [ ] Paham perbedaan Counter, Gauge, Histogram, Summary
- [ ] Bisa nulis PromQL query: rate, increase, histogram_quantile, topk
- [ ] Setup Prometheus + Node Exporter + Grafana di docker
- [ ] Bisa design dashboard yang efektif (overview → detail → raw)
- [ ] Setup Vector → Loki pipeline for structured logging
- [ ] Paham LogQL: label filter + content filter + aggregation
- [ ] Bisa setup Alertmanager + alert routing rules
- [ ] Paham SLI/SLO/Error Budget dan implementasinya
- [ ] Paham distributed tracing: trace → span → context propagation

---

## Roadmap Belajar

```
HARI 1: Metrics Fundamentals
  - Baca dokumen ini
  - Setup Prometheus + Node Exporter + Grafana (docker-compose)
  - Explore Grafana: import Node Exporter Full dashboard

HARI 2: PromQL & Alerting
  - Latihan PromQL: rate, increase, histogram_quantile
  - Setup alert rules + Alertmanager → Telegram/Slack
  - Simulasi: matikan service, lihat alert flow

HARI 3: Logging Pipeline
  - Setup Loki + Vector
  - Kirim nginx logs ke Loki
  - Query LogQL: filter error rate, aggregate by instance

HARI 4: Advanced Observability
  - Setup OpenTelemetry + Tempo untuk tracing
  - Instrumentasi aplikasi Python/Go
  - Trace request dari frontend → backend → database

HARI 5: SLO & On-Call
  - Definisikan SLI untuk service lo
  - Setup SLO dashboard + error budget alert
  - Setup PagerDuty integration
  - Tulis runbook untuk top 5 alerts
```

> [!warning] Bottom Line
> Observability bukan sekadar "pasang Prometheus, lihat dashboard hijau." Observability adalah **ability to ask new questions without deploying new code**. Kalau lo masih SSH ke server buat cek log, atau masih nanya "ada yang error ga?" — lo belum observability. Investasi di metrics + logs + tracing adalah force multiplier untuk velocity dan reliability. Tanpa ini, lo cuma punya monitoring — tahu bahwa sesuatu mati, tapi gak tahu kenapa.

> [!tip] Ponytail
> Catatan ini belum mencakup OpenTelemetry Collector pipeline (receivers, processors, exporters), custom instrumentation untuk Go/Rust/Java, profiling (continuous profiling via Pyroscope/Phlare), dan eBPF-based observability (Cilium Hubble, Tetragon). Baca [[ebpf-beyond-security]] untuk eBPF observability.
