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
  - [[osquery-build-methodology|Osquery Build Methodology]]
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
- [[ipv6-migration]] – kaitannya dengan monitoring jaringan pada stack IPv6.
- [[logging-compliance-guide]] – integrasi log osquery ke framework compliance.
- Blog: "Threat Hunting with osquery" (tim Facebook/Osquery).
---

audited
---
