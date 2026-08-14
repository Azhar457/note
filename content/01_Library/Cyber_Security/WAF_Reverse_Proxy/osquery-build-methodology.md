---
title: Osquery Build Methodology
tags:
  - osquery
  - monitoring
  - endpoint
  - sql
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
references:
  - [[ipv6-migration]]
  - [[logging-compliance-guide]]
related_notes:
  - [[WAF_Reverse_Proxy/osquery-build-methodology|Osquery Build Methodology]]
---

> Osquery = query OS seperti database. Artikel ini merangkum metodologi build, tabel kunci, dan praktik monitoring endpoint.

## 1. Ringkasan / Definisi
Osquery adalah framework endpoint visibility berbasis SQL. Ia mengekspos sistem operasi (Linux, macOS, Windows) sebagai tabel relasional yang bisa diquery secara real‑time (live query) maupun terjadwal (scheduled query). Cocok untuk threat hunting, compliance, dan incident response karena memungkinkan analisis sistem secara konsisten dan otomatis tanpa agen tradisional yang berat.

## 2. Tabel Kunci
| Table | Purpose |
|-------|---------|
| processes | Running apps & binary path |
| listening_ports | Network listeners aktif |
| socket_events | Network connections (dengan eBPF/audit) |
| file_events | File changes via FIM (File Integrity Monitoring) |
| users | User accounts |
| services | Running services (Windows) |
| osquery_schedule | Status query terjadwal |
| file | Metadata file (hash, permission, mtime) |

## 3. Contoh Query
```sql
-- Suspicious processes
SELECT * FROM processes 
WHERE path LIKE '/tmp/%' OR name LIKE '%mal%';

-- Unusual network listeners
SELECT * FROM listening_ports 
WHERE port NOT IN (80, 443, 22, 3306);

-- File integrity check (mis. file /etc baru dimodifikasi)
SELECT * FROM file WHERE path LIKE '/etc/%' AND mtime > 1690000000;
```

## 4. Langkah Build (Checklist)
- [ ] Install osquery (repo resmi, package manager, atau binary release).
- [ ] Konfigurasi `--flagfile` dan `--config_path` sesuai environment.
- [ ] Aktifkan hanya packs yang relevan: `osquery` default, `hardware`, `incident-response`.
- [ ] Uji live query: `osqueryi "SELECT * FROM processes LIMIT 5;"`.
- [ ] Setup daemon untuk scheduled queries & logging ke syslog/file.
- [ ] Integrasikan output ke SIEM (rsyslog, Fluentd, Splunk HEC, Kafka).
- [ ] Uji performa: resource usage < 5% CPU idle, memory stabil.
- [ ] Tetapkan version management (semver, rollback plan, changelog).
- [ ] Dokumentasikan query packs, interval eksekusi, dan owner monitoring.

> [!callout] ⚠️
> Hindari menjalankan query kompleks secara live di host produksi; gunakan scheduled query dengan interval wajar (60–300 detik) agar tidak memicu load spike atau mengganggu operasional.

## 5. Monitoring & Alerting

### Integrasi SIEM & Alert Rules
| SIEM | Log Ingestion Method | Typical Alert |
|------|---------------------|--------------|
| Splunk | `splunk_http_event_collector` | Suspicious process execution |
| Elastic | Filebeat -> Logstash | Unusual port listening |
| Graylog | GELF UDP | File integrity change |
| Azure Sentinel | Custom Connector | NDP spoofing detection |

### Checklist untuk Alerting
- [ ] Definisikan threshold untuk tiap query (mis. >10 proses `/tmp/` dalam 5 menit).
- [ ] Konfigurasikan alert channel (email, Slack, Opsgenie).
- [ ] Uji end‑to‑end flow: trigger query -> SIEM ingest -> alert.
- [ ] Dokumentasikan alert ID dan owner respon.
- [ ] Review alerts bulanan, hapus false positives.

## 5. Referensi
- Dokumentasi resmi: osquery.io — table reference & query packs.
- [[Network_Threats/ipv6-migration]] – kaitannya dengan monitoring jaringan pada stack IPv6.
- [[Network_Threats/logging-compliance-guide]] – integrasi log osquery ke framework compliance.
- Blog: "Threat Hunting with osquery" (tim Facebook/Osquery).
## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/

### FAQ & Catatan Tambahan

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori formal, blog industri untuk praktik terkini, CVE database untuk kerentanan konkret, video lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi?**
A: Audit terhadap checklist standar industri (NIST CSF, CIS Controls, OWASP Top 10). Penilaian berdasarkan: ada vs tidak ada kontrol, efektivitas (dapat ditembus atau tidak), dokumentasi (tercatat atau implicit), dan repeatable (dapat direplikasi).

### Glossary

| Istilah | Definisi |
|---------|----------|
| **Zero Trust** | Never trust, always verify |
| **MITRE ATT&CK** | Framework TTP serangan |
| **SIEM** | Security Information & Event Management |
| **EDR** | Endpoint Detection & Response |
| **SOAR** | Security Orchestration & Response |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
