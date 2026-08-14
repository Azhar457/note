---
title: 🚀 DevOps & CI/CD — Dari Developer ke Production
tags:
- hierarchy
- devops
- cicd
- pipeline
- gitops
- sre
- platform-engineering
aliases:
- DevOps Hierarchy
- CI/CD Pipeline Map
- From Code to Production
- DevOps Evolution Stack
created: 2026-07-23
updated: 2026-07-23
status: pending
cssclasses:
  - wide-table
---

# 🚀 DevOps & CI/CD — Dari Developer ke Production

> [!tip] DevOps adalah **budaya + praktik + tools** yang mempersingkat jarak antara "code committed" dan "code running in production". Catatan ini memetakan **6 tahap pipeline modern** dari commit hingga observability, perbandingan GitOps vs Push-based, deployment strategy (blue-green, canary, rolling), dan framework SRE. Folder DevOps/ di vault sudah punya 7 files tapi tidak ada hierarchy master.

---

## Daftar Isi

1. [[#1. Premise — DevOps = Developer + Operations]]
2. [[#2. Six-Stage CI/CD Pipeline]]
3. [[#3. Stage 1 — Version Control & Branching]]
4. [[#4. Stage 2 — Continuous Integration (CI)]]
5. [[#5. Stage 3 — Artifact & Image Registry]]
6. [[#6. Stage 4 — Continuous Delivery/Deployment (CD)]]
7. [[#7. Stage 5 — Deployment Strategy]]
8. [[#8. Stage 6 — Observability & Incident Response]]
9. [[#9. GitOps vs Push-based]]

---

## 1. Premise — DevOps = Developer + Operations

**DevOps is NOT a tool. DevOps is NOT a job title. DevOps is a culture.**

```
Before DevOps:
  [Dev] Write code → Throw over wall → [Ops] Deploy (panic)

After DevOps:
  [Dev + Ops] Code → Automated test → Automated deploy → Monitor → Feedback
```

**Three Ways of DevOps (Gene Kim):**
1. **Flow** — mempercepat aliran dari dev ke production
2. **Feedback** — mempercepat umpan balik dari production ke dev
3. **Continuous Learning** — budaya eksperimen dan perbaikan

**Key metrics (DORA, 2024):**
| Metric | Elite | High | Medium | Low |
|--------|:-----:|:----:|:------:|:---:|
| **Deploy frequency** | Multiple/day | Daily-weekly | Weekly-monthly | Monthly |
| **Lead time for change** | < 1 hour | < 1 day | < 1 week | > 1 week |
| **Change failure rate** | < 5% | < 10% | < 15% | > 15% |
| **Time to restore** | < 1 hour | < 1 day | < 1 week | > 1 week |

---

## 2. Six-Stage CI/CD Pipeline

| Stage | Nama | Output | Durasi |
|:-----:|------|--------|:------:|
| **S1** | Version Control | Branch + commit | detik |
| **S2** | CI (Build + Test) | Tested artifact | 1-30 menit |
| **S3** | Registry | Docker image / package | detik |
| **S4** | CD (Deploy) | Running application | 1-10 menit |
| **S5** | Release Strategy | Zero-downtime deploy | < 1 menit |
| **S6** | Observability | Metrics + logs + traces | Real-time |

---

## 3. Stage 1 — Version Control & Branching

### 3.1 Branching Strategy

| Strategy | Complexity | PR Quality | Hotfix | Cocok untuk |
|----------|:----------:|:----------:|:------:|-------------|
| **GitHub Flow** | Rendah | 🟡 | Mudah | Tim kecil, CI kuat |
| **Git Flow** | Tinggi | ✅ | Kompleks | Rilis terjadwal |
| **Trunk-based** | Sangat rendah | ❌ (pair review) | Mudah | Elite DORA, deploy banyak/hari |
| **GitLab Flow** | Sedang | ✅ | Mudah | Environment-based |

**GitHub Flow:**
```
main ── * ── * ── * ── * ──>
        ↑      ↑
        feat/  fix/hotfix
```

**Trunk-based + short-lived branches (< 1 hari):**
```
main ───── * ───── * ───── * ──>
             ↑       ↑
           user-    bugfix-
           login    header
```

### 3.2 Commit Conventions

| Convention | Format | Tools |
|------------|--------|-------|
| **Conventional Commits** | `type(scope): description` | commitlint, semantic-release |
| **Angular** | `feat(module): add user login` | cz-cli |
| **Gitmoji** | 🐛 fix login bug | gitmoji-cli |

---

## 4. Stage 2 — Continuous Integration (CI)

### 4.1 CI Pipeline Structure

```
[Trigger] → [Checkout] → [Deps] → [Lint] → [Build] → [Test] → [Test Coverage] → [Security Scan]
```

| Langkah | Tools | Durasi |
|---------|-------|:------:|
| **Trigger** | push, PR, schedule | instant |
| **Checkout** | git clone | 10-60s |
| **Deps install** | npm ci, pip, cargo fetch | 30s-5m |
| **Lint** | ESLint, ruff, clippy | 10s-2m |
| **Build** | tsc, cargo build, go build | 1-20m |
| **Unit test** | jest, pytest, cargo test | 1-10m |
| **Integration test** | Docker compose, testcontainers | 5-30m |
| **Coverage** | c8, coverage.py, tarpaulin | 1-5m |
| **Security scan** | trivy, snyk, semgrep | 1-10m |

### 4.2 CI Platform Comparison

| Platform | Hosted | Self-hosted | Pricing | Cache | Matrix |
|----------|:------:|:-----------:|---------|:-----:|:------:|
| **GitHub Actions** | ✅ | ✅ Runner | 2000 mnt/bulan gratis | ✅ | ✅ |
| **GitLab CI** | ✅ | ✅ Runner | 400 mnt/bulan | ✅ | ✅ |
| **CircleCI** | ✅ | ❌ | 6000 mnt/bulan | ✅ | ✅ |
| **Jenkins** | ❌ | ✅ Self-managed | Free | ❌ | ✅ |
| **Woodpecker** | ❌ | ✅ Self-managed | Free | ❌ | ✅ |

---

## 5. Stage 3 — Artifact & Image Registry

### 5.1 Jenis Artifact

| Type | Format | Registry Tool |
|------|--------|---------------|
| **Container image** | OCI (Docker) | Docker Hub, GHCR, ECR, GCR, Harbor |
| **JAR/WAR** | Java archive | Artifactory, Nexus, GitHub Packages |
| **npm package** | .tgz | npm registry, Verdaccio |
| **Python wheel** | .whl | PyPI, devpi |
| **Debian/RPM** | .deb/.rpm | Artifactory, Pulp |

### 5.2 Container Image Best Practices

| Praktik | Alasan |
|---------|--------|
| **Multi-stage build** | Pisahkan build env dari runtime — image kecil |
| **Distroless base** | Hapus shell + package manager → attack surface minim |
| **Pin base image tag** | Jangan `:latest` — gunakan `:sha256-xxx` |
| **Scan image** | Trivy, Grype — sebelum push |
| **Sign image** | cosign (Sigstore) — verifikasi authenticity |

---

## 6. Stage 4 — Continuous Delivery/Deployment (CD)

### 6.1 Continuous Delivery vs Continuous Deployment

| Aspek | Continuous Delivery | Continuous Deployment |
|-------|:------------------:|:--------------------:|
| **Manual gate** | ✅ Yes (click deploy) | ❌ No gate |
| **Risk** | Lebih terkontrol | Otomatis penuh |
| **Speed** | Menit-jam | Detik-menit |
| **Use case** | Enterprise, compliance | SaaS, internal tools |

### 6.2 CD Pipeline Structure

```
[Pull image] → [DB migration] → [Config injection] → [Health check] → [Traffic switch]
```

| Langkah | Tool | Check |
|---------|------|-------|
| **Pull image** | Kubernetes, Nomad, Docker | Image digest match |
| **DB migration** | Flyway, Prisma, Alembic | Idempotent |
| **Config injection** | Vault, Kubernetes secrets, SOPS | Encrypted |
| **Health check** | Readiness probe, curl | HTTP 200 |
| **Traffic switch** | Load balancer, service mesh | Gradual |

---

## 7. Stage 5 — Deployment Strategy

### 7.1 Strategi Deployment

| Strategi | Downtime | Rollback | Waktu | Traffic |
|----------|:--------:|:--------:|:-----:|:-------:|
| **Recreate** | ✅ Full (detik-menit) | Mudah | Tercepat | 0→100% |
| **Rolling update** | ❌ | Lambat (bertahap) | Bertahap | Per pod |
| **Blue-green** | ❌ (≤ 1 detik) | Instant (switch DNS) | 2× infra | 0→100% |
| **Canary** | ❌ | Instant (stop %) | Bertahap | 1%→5%→100% |
| **A/B testing** | ❌ | Instant | Routing-based | Per user segment |

### 7.2 Blue-Green Deployment

```
[Old (Blue)]  →  LB → Users
[New (Green)] →  LB (after DNS switch)
```

**Flow:**
1. Deploy Green (parallel) — users still hit Blue
2. Smoke test Green via internal URL
3. Switch LB from Blue → Green
4. Keep Blue as rollback target
5. Destroy Blue after N hours/days

### 7.3 Canary Release

**Kubernetes-style canary:**
```
9 pods (old) + 1 pod (new) → 10% traffic to canary
                              ↓
                  Monitor error rate + latency
                              ↓
   If OK: increment canary to 50% → 100%
   If not OK: drain canary pod → back to stable
```

---

## 8. Stage 6 — Observability & Incident Response

### 8.1 Observability Foundation

| Pillar | Data Type | Tools | Signal |
|--------|-----------|-------|--------|
| **Metrics** | Numeric time-series | Prometheus, VictoriaMetrics, Datadog | CPU, latency, error rate |
| **Logs** | Text events | Loki, ELK, CloudWatch | Detailed events |
| **Traces** | Request path | Jaeger, Tempo, Zipkin | Distributed tracing |
| **Profiling** | CPU/memory stack | pprof, Pyroscope | Performance hotspots |

### 8.2 SRE (Site Reliability Engineering)

**Key SRE concepts:**

| Konsep | Definisi |
|--------|----------|
| **SLO (Service Level Objective)** | Target: 99.9% uptime |
| **SLI (Service Level Indicator)** | Ukuran: latency p99 < 200ms |
| **SLA (Service Level Agreement)** | Kontrak dengan customer |
| **Error Budget** | 100% - SLO = Waktu boleh error |
| **Toil** | Manual, repetitive, automatable work |
| **Blameless postmortem** | Root cause → prevent recurrence |

### 8.3 Incident Response

```
Detect → Triage → Mitigate → Resolve → Postmortem
  ↓         ↓        ↓          ↓          ↓
 Alert    Severity  Rollback   Verified  Root cause
          P0/P1/P2  /Canary    /Fixed    + Action items
```

---

## 9. GitOps vs Push-based

### 9.1 GitOps (Pull-based)

**Prinsip:** Git = single source of truth. Cluster pulls desired state.

```
[Developer pushes to Git] → [GitOps operator watches] → [Applies to cluster]
```

| Tool | Operator | Auto Sync | Drift Detection |
|------|:--------:|:---------:|:---------------:|
| **Argo CD** | ✅ | ✅ | ✅ (3m default) |
| **Flux** | ✅ | ✅ | ✅ |
| **Jenkins X** | ✅ Tekton | ✅ | ✅ |
| **Rancher Fleet** | ✅ | ✅ | ✅ |

### 9.2 Push-based (CI-driven)

**Prinsip:** CI pipeline mendorong langsung ke cluster.

```
[CI pipeline builds] → [Pushes image to registry] → [Sends deploy command to cluster]
```

**Lebih sederhana, cocok untuk:**
- Single cluster, small team
- Developer langsung akses cluster
- Aplikasi stateless

### 9.3 GitOps vs Push-based

| Aspek | GitOps | Push-based |
|-------|:------:|:----------:|
| **Source of truth** | Git repository | CI/CD pipeline state |
| **Drift detection** | ✅ Automatic | ❌ Manual |
| **Rollback** | `git revert` | Re-run pipeline |
| **Audit trail** | Git history | Pipeline logs |
| **Complexity** | Higher (operator needed) | Lower |
| **Multi-cluster** | ✅ Natural | ❌ Complex |
| **Secret management** | Sops, SealedSecrets, External Secrets | CI variables |

---

## 10. Cross-Reference ke Vault

| Stage | Catatan Vault |
|:-----:|---------------|
| **S1** | [[hierarchy-programming-language]] — Language ecosystem tooling |
| **S2 (CI)** | [[00_Atlas/hierarchy-package-managers]] — Dependency management |
| **S3** | [[hierarchy-database-storage-systems]] — Container registry storage |
| **S4 (CD)** | [[00_Atlas/hierarchy-systems-architecture-evolution]] — Deployment patterns |
| **S5** | [[hierarchy-failure-modes-resilience]] — Rollback strategies |
| **S6** | [[00_Atlas/hierarchy-cybersecurity-defense-architecture]] — Security monitoring |
| **All** | [[hierarchy-abstraction-layers]] — DevOps as Layer L8 |

---

## References

1. Kim, G., Debois, P., Willis, J., Humble, J. *"The DevOps Handbook."* 2nd ed., IT Revolution, 2021.
2. Humble, J. & Farley, D. *"Continuous Delivery."* Addison-Wesley, 2010.
3. Beyer, B. et al. *"Site Reliability Engineering."* O'Reilly, 2016.
4. DORA. *"Accelerate State of DevOps Report."* Google Cloud, 2024.
5. Burns, B. et al. *"Kubernetes: Up and Running."* 3rd ed., O'Reilly, 2024.
6. Beedle, M. et al. *"The Agile Manifesto."* 2001.
7. Farcic, V. *"The DevOps 2.5 Toolkit: Monitoring, Logging, and Auto-Scaling."* 2019.
8. Argo CD. *"Argo CD Documentation."* CNCF, 2024.
9. Flux. *"Flux Documentation."* CNCF, 2024.
10. HashiCorp. *"Terraform: Infrastructure as Code."* 2024.
11. Newman, S. *"Building Microservices."* 2nd ed., O'Reilly, 2021.
