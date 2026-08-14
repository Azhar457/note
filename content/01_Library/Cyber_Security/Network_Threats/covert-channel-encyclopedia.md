---
title: Covert Channel Encyclopedia
tags:
  - covert-channel
  - data-exfiltration
  - steganography
  - detection
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
references:
  - [[semantic-search-pipeline]]
  - [[Network_Threats/ipv6-migration]]
related_notes:
  - [[Network_Threats/covert-channel-encyclopedia|Covert Channel Encyclopedia]]
---

> Covert channels menyembunyikan komunikasi dalam traffic legitimate. Artikel ini membahas kategori, mekanisme deteksi, dan langkah mitigasi.

## 1. Ringkasan / Definisi
Covert channel adalah jalur komunikasi tersembunyi yang tidak dirancang oleh protokol atau sistem. Ia memanfaatkan field tidak terpakai, timing paket, atau payload yang terlihat normal untuk mengirim data — sering digunakan untuk data exfiltration, command & control (C2), atau bypass monitoring.

## 2. Kategori Covert Channel
| Kategori | Contoh | Keterangan |
|----------|--------|------------|
| Storage Channel | Header manipulation (IP ID, TCP SEQ, HTTP headers) | Menyisipkan data pada field yang jarang diperiksa. |
| Storage Channel | ICMP payload (ping tunnel) | Kirim data pada payload ICMP echo request/reply. |
| Storage Channel | DNS payload (txt record, NS lookup) | Exfiltrasi via DNS queries — sulit terdeteksi. |
| Timing Channel | Inter-packet delay modulation | Encode data dalam jeda antar paket. |
| Timing Channel | Packet reordering | Manipulasi urutan paket yang tampak acak. |
| Protocol Abuse | HTTP headers/cookies/URL | Menyembunyikan data dalam atribut HTTP. |
| Protocol Abuse | HTTPS TLS padding size | Data disembunyikan pada ukuran padding TLS. |
| Protocol Abuse | SSH channel stuffing | Menyisipkan data dalam channel SSH yang sah. |

## 3. Deteksi
> [!callout] ⚠️
> Steganografi dan covert channel sulit dideteksi — perlu kombinasi analisis statistik, anomaly detection, dan pemantauan traffic baseline.

**Teknik deteksi:**
- **Shannon entropy analysis**: Deteksi lonjakan entropi pada field yang biasanya polos (mis. IP ID, DNS TXT).
- **Protocol field anomaly detection**: Pantau nilai field yang tidak konsisten dengan spesifikasi protokol.
- **Time-series analysis**: Deteksi pola timing yang tidak wajar (mis. inter-packet delay reguler pada traffic yang seharusnya acak).
- **Deep packet inspection (DPI)**: Parsing payload dan header secara mendalam.
- **Behavioral analytics**: Deteksi sink hole DNS, frekuensi query abnormal, atau pola beaconing.

## 4. Checklist Mitigasi
- [ ] Aktifkan logging DNS dan kategori DNS tunneling.
- [ ] Terapkan firewall stateful dengan aturan egress ketat.
- [ ] Monitor volume query DNS per host (threshold anomaly).
- [ ] Lakukan audit berkala terhadap field header IP/TCP.
- [ ] Gunakan IDS/IPS berbasis machine learning untuk traffic anomaly.
- [ ] Batasi komunikasi ICMP kecuali diperlukan.
- [ ] Dokumentasikan baseline traffic normal untuk perbandingan berkala.

## 5. Referensi
- RFC 4949 – Internet Security Glossary (definisi covert channel)
- Buku: *Silent Spreadsheet* / paper "Covert Channels in the TCP/IP Protocol Suite"
- [[Network_Threats/ipv6-migration]] – Risiko terkait tunneling yang bisa jadi covert channel.
- [[semantic-search-pipeline]] – Teknik analisis vektor untuk anomaly detection.
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
