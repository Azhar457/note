---
title: — Military & Intel Tool Capability Tier
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
  

## Deepdive — Military & Intel Tool Capability Tier

| Level | Capability | Tool | Sumber |
|-------|-----------|------|--------|
| L0 | OSINT | Maltego, Shodan | Public |
| L1 | Pentest | Metasploit, Nmap | Commercial |
| L2 | C2/Post-exploit | Cobalt Strike, Sliver | Mixed |
| L3 | Commercial spyware | Pegasus (NSO), Predator (Cytrox) | Commercial |
| L4 | SIGINT platform | XKEYSCORE, PRISM (NSA) | Nation-state |
| L5 | Active exploitation | FoxAcid, QUANTUMINSERT | NSA TAO |
| L6 | Hardware implant | ANT Catalog (COTTONMOUTH) | NSA TAO |

### Pegasus (NSO Group) — Zero-click iOS

```
Vector: iMessage zero-click → kernel exploit → persist
Target: journalist, activist, political opposition
Detection: Citizen Lab forensic (post-fact) → MITRE T1542.003
```

### ANT Catalog Hardware Implant

| Implant | Target | Fungsi |
|---------|--------|--------|
| COTTONMOUTH-I | USB | RF C2 + exfil |
| IRATEMONK | HDD firmware | Survive format |
| GOURMETTROUGH | BIOS | Boot persistence |

## Referensi
- ANT Catalog — https://www.spiegel.de/international/world/
- Pegasus (Citizen Lab) — https://citizenlab.ca/2021/07/
- XKEYSCORE — https://en.wikipedia.org/wiki/XKeyscore

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

## Konsep Dasar — Capability Tier Detail

### L0-L1: Open Source Intelligence

| Teknik | Tool | Output |
|--------|------|--------|
| **DNS enum** | subfinder, amass | Subdomain list |
| **Cert transparency** | crt.sh | Domain history |
| **Shodan/Censys** | Scan internet | Exposed service |
| **Google dork** | Google | Sensitive file |
| **Social media** | Maltego | Network analysis |

### L2: C2 & Post-Exploitation

| Tool | Fitur | Stealth |
|------|-------|---------|
| **Cobalt Strike** | Malleable C2, BOF | High (custom profile) |
| **Sliver** | Go C2, DNS/HTTPS/mTLS | High |
| **Havoc** | C2 + Demon implant | High |
| **Mythic** | Plugin agent | Medium |
| **Metasploit** | Exploit + payload | Low (known signature) |

### L3: Commercial Spyware

| Spyware | Vendor | Target | Teknik | Detection |
|---------|--------|--------|--------|-----------|
| **Pegasus** | NSO Group | iOS/Android | Zero-click iMessage | Citizen Lab (post-fact) |
| **Predator** | Cytrox | iOS/Android | 1-click link | Post-fact |
| **FinSpy** | FinFisher | Multi-platform | Trojan bundle | RE by academia |
| **Hermit** | RCS Lab | iOS/Android | Custom implant | Post-fact |

### L4-L5: SIGINT & Active Exploitation (NSA)

| Program | Teknik | Target |
|---------|--------|--------|
| **XKEYSCORE** | Passive filter | Global traffic |
| **PRISM** | Tech company data (Google, Apple, FB) | User data |
| **UPSTREAM** | Fiber tap | Undersea cable |
| **FoxAcid** | Exploit server → MITM redirect | Targeted |
| **QUANTUMINSERT** | TCP race inject | Targeted |
| **MUSCULAR** | Cloud fiber intercept | Google/Yahoo DC |

### L6: Hardware Implant (ANT Catalog)

| Code Name | Target | Fungsi |
|-----------|--------|--------|
| COTTONMOUTH-I | USB | RF C2 + exfil |
| COTTONMOUTH-III | USB hub | Network tap |
| IRATEMONK | HDD firmware | Survive format |
| GOURMETTROUGH | BIOS | Boot persistence (UEFI) |
| FEEDTROUGH | Router/switch | Network persistence |
| RAGBULL | Ethernet cable | RF tap |

## Referensi Tambahan
- Snowden Docs — https://en.wikipedia.org/wiki/Global_surveillance_disclosures
- NSO Group Research — https://citizenlab.ca/
- Electronic Frontier Foundation — https://www.eff.org/

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
---

audited
---
