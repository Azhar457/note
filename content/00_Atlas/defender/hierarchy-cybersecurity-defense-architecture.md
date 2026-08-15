---
title: Cybersecurity Defense Architecture — Blue Team Framework
tags:
- defense
- blue-team
- architecture
- framework
- nist
- mitre
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Cybersecurity Defense Architecture — Blue Team Framework

> Arsitektur pertahanan siber modern = layering People + Process + Technology. Inti: NIST CSF (Identify → Protect → Detect → Respond → Recover) + MITRE ATT&CK mapping untuk deteksi + zero trust untuk network + EDR untuk endpoint + SIEM untuk correlation.

## 1. Framework Mapping (Defense Stack)

| Framework | Scope | Fungsi | Tools |
|-----------|-------|--------|-------|
| **NIST CSF** | Enterprise | Lifecycle: ID-PR-DE-RS-RC | Assessment, gap analysis |
| **MITRE ATT&CK** | Detection | TTP mapping → rule coverage | Sigma, ATT&CK Navigator |
| **CIS Controls** | Implementation | 18 control prioritization | CIS-CAT, audit |
| **ISO 27001** | Governance | ISMS, risk management | Certification, audit |
| **Zero Trust** | Architecture | Never trust, always verify | ZTNA, mTLS, micro-seg |
| **SOC 2 / PCI** | Compliance | Audit, evidence | Vanta, Drata |

## 2. Defense Layer per NIST Function

### 2.1 Identify (ID)

```
Asset inventory → CMDB (ServiceNow/Jira)
  ├── Hardware (laptop, server, IoT)
  ├── Software (catalog, license)
  ├── Data (classification: public → restricted)
  └→ Risk assessment → prioritize
    ↓
Output: Asset register, risk register, supply chain map
```

### 2.2 Protect (PR)

| Layer | Control | Tool |
|-------|---------|------|
| Identity | MFA, SSO, least privilege | Okta, Entra ID, Keycloak |
| Network | Zero trust, firewall, segmentation | ZTNA, Palo Alto, iptables |
| Endpoint | EDR, hardening, patch management | CrowdStrike, SentinelOne |
| Data | Encryption (rest + transit), DLP | BitLocker, VeraCrypt, DLP agent |
| Application | SAST/DAST, RASP, WAF | Snyk, Burp, ModSecurity |
| Cloud | CSPM, posture management | Wiz, Prisma Cloud |

### 2.3 Detect (DE)

```
Data source → SIEM → Correlation → Alert
  ├── EDR telemetry (process, network, file)
  ├── Network (Zeek, Suricata)
  ├── Identity (IdP log, guest access)
  ├── Cloud (CloudTrail, Azure AD)
  └→ Email (Proofpoint, security gateway)
    ↓
Detection:
  ├── Signature (IoC, YARA, SNORT)
  ├── Behavioral (UEBA, anomaly)
  └→ TTP-based (MITRE ATT&CK → Sigma rule)
```

### 2.4 Respond (RS) & Recover (RC)

| Stage | Activity | Tool |
|-------|----------|------|
| Containment | Isolate host, block IP | EDR remote action, firewall |
| Eradication | Remove malware, close hole | Patch, rebuild |
| Recovery | Restore from backup | Immutable backup, DR |
| Lessons | Post-incident review | Retrospective, improve detection |

## 3. MITRE ATT&CK Detection Coverage

| Tactic | Detection Method | Coverage Gap |
|--------|-----------------|--------------|
| Initial Access | Email gateway, IDS | Zero-day |
| Execution | EDR, Sysmon | LOLBin, direct syscall |
| Persistence | Registry, task, WMI audit | WMI subscription |
| Lateral | Network, auth log | Pass-the-hash |
| Exfil | DLP, egress monitor | Covert channel |
| Impact | DoS detect, backup integrity | Wiper, encryption |

## 4. Tool Stack

| Tool | Layer | Use |
|------|-------|-----|
| **Splunk / Elastic SIEM** | DE | Log correlation, alert |
| **CrowdStrike / SentinelOne** | PR/DE | EDR, response |
| **Wiz / Prisma Cloud** | PR/DE | Cloud posture |
| **Okta / Entra ID** | PR | SSO, MFA, identity |
| **ModSecurity / Cloudflare** | PR | WAF |
| **Zeek / Suricata** | DE | Network IDS |
| **TheHive / Cortex** | RS | Case mgmt, SOAR |

## 5. Referensi
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
- Zero Trust (NIST 800-207) — https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf
- ISO 27001 — https://www.iso.org/standard/27001

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

audited
---
