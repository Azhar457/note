---
title: — Quantum Cryptography Stack
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
  

## Deepdive — Quantum Cryptography Stack

| Layer | Teknologi | Status | Threat |
|-------|-----------|--------|--------|
| **QKD (Quantum Key Distribution)** | BB84, E91 | Commercial deploy | Finite-key, side-channel |
| **PQC (Post-Quantum Crypto)** | ML-KEM (Kyber), ML-DSA (Dilithium) | NIST FIPS 203/204 | Implementation bug |
| **Hybrid (Classic + PQC)** | X25519 + Kyber | Browser deploy 2024 | Component downgrade |
| **HNDL** | Passive TLS recording | Active threat NOW | No detection |

### HNDL (Harvest-Now-Decrypt-Later)

```
Sekarang: passive TLS recording → store → 0 day quantum
2030+: Shor's → RSA/ECC mati → decrypt stored traffic → historical data exposed
```

## Referensi
- NIST PQC — https://csrc.nist.gov/projects/post-quantum-cryptography
- FIPS 203 — https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf

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

## Konsep Dasar — Quantum Computing Threat

### Shor's Algorithm (Ancaman ke RSA/ECC)

```
Input: N = p × q (RSA modulus)
  ↓
Shor's: period finding (quantum Fourier transform)
  ↓
Output: p, q (faktor) → private key recovered
    ↓
Complexity: O(log N³) → polynomial → RSA mati saat quantum cukup besar
```

### Grover's Algorithm (Ancaman ke Symmetric)

```
Input: hash/symmetric key search
  ↓
Grover: quadratic speedup → 2^256 → 2^128 (untuk SHA-256)
    ↓
Impact: AES-128 → 64-bit (weak), AES-256 → 128-bit (still safe)
    ↓
Recommendation: AES-256, SHA-384/512
```

### PQC Standar NIST

| Standard | Algoritma | Tipe | Key Size | Status |
|----------|-----------|------|----------|--------|
| **FIPS 203** | ML-KEM (Kyber) | KEM | 1568 bytes | Final 2024 |
| **FIPS 204** | ML-DSA (Dilithium) | Signature | 1312 bytes | Final 2024 |
| **FIPS 205** | SLH-DSA (SPHINCS+) | Signature | 7856 bytes | Final 2024 |
| **FIPS 206** | Falcon | Signature | 617 bytes | Pending |

### Hybrid Deployment (Browser)

```
TLS 1.3 + Hybrid (X25519 + Kyber768):
  Client → ClientHello: key_share = X25519 + Kyber768
  Server → ServerHello: key_share = X25519 + Kyber768
  Shared secret = SHA256(X25519_secret || Kyber_secret)
    ↓
Security: salah satu tetap aman → hybrid aman. Jika quantum ada → Kyber amankan.
```

## Referensi Tambahan
- NIST PQC — https://csrc.nist.gov/projects/post-quantum-cryptography
- Cloudflare PQ — https://blog.cloudflare.com/pq-2024/
- liboqs — https://github.com/open-quantum-safe/liboqs

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
