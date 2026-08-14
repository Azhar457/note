---
title: — Systems Architecture & Attack Surface
tags:
- vault
- note
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---


cssclasses:
  - wide-table
  - callout

## Deepdive — Systems Architecture & Attack Surface

| Komponen | Attack | CVE/Tool | Detection |
|----------|--------|----------|-----------|
| **CPU Speculative** | Spectre/Meltdown | CVE-2018-3693 | Retpoline partial |
| **Kernel (syscall)** | nf_tables UAF | CVE-2024-1086 | Kernel patch lag |
| **Virtual Memory** | ASLR bypass, heap | pwntools | ASLR partial |
| **DMA** | PCIe read/write | PCILeech | DMA = no EDR |
| **Firmware** | UEFI implant | BlackLotus | CHIPSEC |

### Kernel Exploit Chain (Linux 6.x)

```
nf_tables UAF (CVE-2024-1086):
  1. Trigger UAF → double-free → tcache poison
  2. Arbitrary kernel write → modprobe_path overwrite
  3. Trigger modprobe → root shell
    ↓
Bypass: SMEP (ROP), SMAP (ROP), KASLR (leak), KPTI (userland ROP)
```

## Referensi
- Spectre/Meltdown — https://spectreattack.com/
- CVE-2024-1086 — https://nvd.nist.gov/vuln/detail/CVE-2024-1086

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

## Konsep Dasar — Cloud → Edge → AI Infrastructure

### Cloud Service Model

| Model | Tanggung Jawab Cloud | Sisa = Customer |
|-------|---------------------|-----------------|
| **IaaS** (EC2, VM) | Hardware, virtualization | OS, app, data |
| **PaaS** (App Engine, Lambda) | Hardware, OS, runtime | App, data |
| **SaaS** (Gmail, Salesforce) | Everything | Data + access |

### Edge Computing Pattern

| Pattern | Tool | Use |
|---------|------|-----|
| **CDN Edge** | Cloudflare, Akamai | Cache + compute di POP |
| **Function Edge** | Cloudflare Workers, Vercel Edge | JS/WASM runtime |
| **IoT Edge** | AWS Greengrass, Azure IoT Edge | Local compute + sync |
| **Mobile Edge** | 5G MEC, device | Low latency compute |

### Multi-Cloud & Portability

```
Vendor lock-in challenge:
  AWS Lambda (event-driven) ≠ Azure Function ≠ GCP Cloud Function
  S3 API ≠ GCS API
  DynamoDB ≠ CosmosDB
    ↓
Strategy: Container (Docker) + IaC (Terraform) → portable
  ├── Kubernetes = common denominator
  ├── PostgreSQL (RDS/Cloud SQL) = portable DB
  └→ S3-compatible API = portable storage (MinIO)
```

### AI Infrastructure Era (2024+)

```
GPU Cluster (NVIDIA H100/B100):
  ├── Interconnect: NVLink, InfiniBand
  ├── Storage: parallel FS (Lustre, WekaIO)
  ├── Scheduler: SLURM, Kubernetes + GPU operator
  └→ Framework: PyTorch DDP, DeepSpeed, Megatron-LM
    ↓
Security: what's different?
  ├── Model registry = new artifact store → supply chain
  ├── Data pipeline = attack surface (poisoning)
  └→ Inference API = new surface (prompt injection, extraction)
```

## Referensi Tambahan
- Cloud Native Computing Foundation — https://www.cncf.io/
- Kubernetes — https://kubernetes.io/
- AI Infrastructure (NVIDIA) — https://docs.nvidia.com/

## Konsep Dasar & Implementasi Praktis

### Arsitektur & Komponen Utama

Sistem ini terdiri dari beberapa komponen yang saling berinteraksi. Setiap komponen punya peran spesifik dan attack surface tersendiri. Pemahaman arsitektur end-to-end penting untuk red team maupun blue team: tanpa peta lengkap, gap tidak terlihat.

### Workflow & Data Flow

```
Input: sumber data mentah
  ↓ Preprocessing: validate, transform, enrich
  ↓ Processing: core logic, decision, model inference
  ↓ Output: result, alert, action, persist
  ↓ Feedback: monitor, audit, improve
    ↓
Loop: setiap output → feedback → improve input processing
```

### Tradeoff & Decision Matrix

Setiap pilihan teknis punya tradeoff: performance vs security, convenience vs control, cost vs reliability. Tabel berikut merangkum tradeoff utama:

| Dimension | Option A | Option B | Decision Factor |
|-----------|----------|----------|-----------------|
| **Speed** | Optimized, less safe | Safe, slower | Risk tolerance |
| **Memory** | In-memory, fast | Disk-backed, slow | Scale vs data size |
| **Security** | Minimal validate | Strict validate | Context (internal vs public) |
| **Cost** | Cloud managed (expensive) | Self-host (cheaper, more work) | Team size, budget |
| **Reliability** | Single instance (SPOF) | Distribute + redundancy | Uptime requirement |

### Implementation Checklist (Production)

- [ ] Authentication: rate limit, MFA, session timeout
- [ ] Authorization: RBAC, least privilege, audit
- [ ] Encryption: TLS transit, AES rest, key rotation
- [ ] Logging: structured, immutable, centralized
- [ ] Monitoring: latency, error, saturation, traffic
- [ ] Backup: test restore, immutable copy, offsite
- [ ] Patch: automated scan, SLA, CVE alert
- [ ] Incident: runbook, contact, tabletop exercise
- [ ] Compliance: data classification, retention, audit
- [ ] Performance: load test, bottleneck profiling, capacity plan

### Common Pitfall (Sering Ditemui)

1. **SPOF (Single Point of Failure)**: Satu komponen mati → sistem down. Fix: redundancy, health check, failover.
2. **No rate limit**: Abuse → DoS. Fix: nginx limit_req, WAF, API gateway.
3. **Secret in code**: Token/password di repo → exposure. Fix: env var, secret manager.
4. **No audit log**: Incident → tidak bisa investigate. Fix: structured log, immutable, SIEM.
5. **Over-privileged service**: Service punya admin scope → privesc. Fix: scoped IAM, least privilege.

## Tool Stack

| Tool | Use |
|------|-----|
| **Monitoring** | Prometheus + Grafana |
| **Logging** | ELK / Loki |
| **Tracing** | Jaeger / OpenTelemetry |
| **Secret** | Vault / SOPS |
| **Scan** | Trivy / Snyk |
| **Deploy** | ArgoCD / Helm |

## Referensi
- MITRE ATT&CK — https://attack.mitre.org/
- NIST CSF — https://www.nist.gov/cyberframework
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- CIS Controls — https://www.cisecurity.org/controls/
- Cloud Native (CNCF) — https://www.cncf.io/
- SLSA — https://slsa.dev/
- Zero Trust (NIST 800-207) — https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf
