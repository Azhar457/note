---
title: "Observability Stack: Prometheus, Grafana & Logging Pipeline"
tags:
  - observability
  - prometheus
  - grafana
  - monitoring
  - logging
  - devops
aliases:
  - "observability-stack"
  - "prometheus-grafana-setup"
  - "logging-pipeline"
created: "2026-07-15"
updated: "2026-07-15"
status: draft
cssclasses:
  - wide-table
---

> [!abstract] Metrics → Logs → Traces → Action
> Vault punya [[site-reability-engineering]] yang bahas SRE secara konseptual, dan [[cicd-guide]] buat pipeline. Tapi gak ada catatan yang bahas **toolkit observability** secara konkret: Prometheus buat metrics, Grafana buat dashboard, Loki/ELK buat logs, Tempo/Jaeger buat tracing. Catatan ini jembatin teori SRE ke implementasi.

---

## 📊 1. Metrics — Prometheus & Exporters

### 1.1 Arsitektur Prometheus

```
[Exporters] → [Prometheus Server] → [Grafana]
    |                |
  Node_exporter    Alertmanager
  Postgres_exp       |
  Blackbox_exp    [PagerDuty/Telegram]
```

**Komponen:**

- **Pull model** — Prometheus scrape endpoint `/metrics` tiap interval
- **Push model** — Pushgateway untuk job batch yang umurnya pendek
- **Service Discovery** — file_sd, consul_sd, kubernetes_sd

### 1.2 Metric Types

| Type          | Behavior         | Contoh                           |
| ------------- | ---------------- | -------------------------------- |
| **Counter**   | Hanya naik       | `http_requests_total`            |
| **Gauge**     | Naik-turun       | `memory_usage_bytes`             |
| **Histogram** | Distribusi nilai | `request_duration_seconds`       |
| **Summary**   | Sama + quantile  | `request_duration_seconds` (p99) |

### 1.3 Alerting Rules

```yaml
groups:
  - name: node
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
```

---

## 📊 2. Grafana — Dashboard yang Efektif

**Prinsip:**

- Satu dashboard = satu pertanyaan. Jangan campur CPU + DB + Network dalam satu panel.
- Gunakan **variables** (`$instance`, `$job`) biar dashboard reusable.
- **Annotations** — overlay deploy/incident di timeline.

---

## 📝 3. Logging Pipeline

### 3.1 Arsitektur

```
[App/System] → [Vector/Fluentd] → [Loki/Elasticsearch] → [Grafana/Kibana]
     |                  |
  journald          Buffer (Kafka)
  filebeat          Dead letter queue
```

**Stack pilihan:**

- **Loki** — log aggregation ala Prometheus (label-based, gak full-text index). Cocok buat infra yang udah pake Prometheus.
- **ELK** — Elasticsearch + Logstash + Kibana. Lebih berat tapi full-text search lebih powerful.
- **Vector** — Rust-based, lebih ringan dari Logstash, bisa jadi sidecar container.

---

## 🔗 Koneksi

- [[site-reability-engineering]] — SRE butuh observability, catatan ini toolkit-nya
- [[cicd-guide]] — pipeline deployment butuh monitoring
- [[devops]] — top-level, observability = pilar DevOps
- [[cicd-shiftleft-shiftright]] — shift-right = observability di production
- [[container-kubernetes-security-deepdive]] — monitoring container = Prometheus ecosystem
