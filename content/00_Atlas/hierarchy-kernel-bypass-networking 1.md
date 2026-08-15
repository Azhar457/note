---
title: — Kernel Bypass Networking
tags:
- vault
- note
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---
## Deepdive — Kernel Bypass Networking

| Teknik | Mekanisme | Tool | Use Case |
|--------|-----------|------|----------|
| **DPDK** | User-space driver, no kernel | DPDK | High-throughput networking |
| **XDP (eBPF)** | Kernel hook, NIC driver | XDP, libbpf | DDoS mitigation, firewall |
| **RDMA** | Direct memory access, no copy | RoCE, InfiniBand | HPC, storage |
| **io_uring** | Async I/O, no syscall | liburing | High IOPS |
| **TUN/TAP** | Virtual interface, user-space | OpenVPN, WireGuard | VPN |

### XDP Attack (Red Team)

```
XDP hook → inspect/drop/modify packet di NIC driver (pre-kernel)
  ├── DDoS: blok malicious IP di NIC level → 0 CPU
  ├── Rate limit: per-IP throttle → no kernel overhead
  └→ Red team: intercept + modify packet before kernel → stealth MITM
```

## Referensi
- DPDK — https://www.dpdk.org/
- XDP — https://xdp-project.org/
- io_uring — https://unixism.net/loti/

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

Setiap pilihan teknis punya tradeoff: performance vs security, convenience vs control, cost vs reliability.

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

## FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian dilakukan berdasarkan: ada vs tidak ada kontrol, efektivitas (dapat ditembus atau tidak), dan dokumentasi (tercatat atau подразумевается).

## Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Model keamanan: never trust, always verify |
| **Supply Chain** | Serangan ke rantai dependency dan tooling |
| **MITRE ATT&CK** | Framework TTP untuk klasifikasi serangan |
| **SIEM** | Security Information and Event Management |
| **EDR** | Endpoint Detection and Response |
| **SOAR** | Security Orchestration, Automation and Response |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **PQC** | Post-Quantum Cryptography |
| **HNDL** | Harvest-Now-Decrypt-Later |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **ABAC** | Attribute-Based Access Control |
| **GitOps** | Infrastructure as Code via Git |
| **OIDC** | OpenID Connect (identity layer) |
| **PKCE** | Proof Key for Code Exchange (OAuth) |
---

audited
---
