---
title: IPv6 Migration — Security Implications
tags:
  - ipv6
  - migration
  - dual-stack
  - networking
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
references:
  - [[covert-channel-encyclopedia]]
  - [[logging-compliance-guide]]
related_notes:
  - [[Network_Threats/ipv6-migration|IPv6 Migration Overview]]
---

> IPv6 migration sering mengaktifkan IPv6 tanpa monitoring, menciptakan blind spot pada jaringan yang sebelumnya hanya IPv4.

## 1. Ringkasan / Definisi
IPv6 memperkenalkan 128‑bit address space, autoconfiguration (SLAAC), serta mekanisme keamanan seperti IPsec dan privacy extensions. Namun transisi dari IPv4 ke IPv6 tidak otomatis meningkatkan postur keamanan — konfigurasi yang salah dapat membuka vektor baru: tunnel abuse, NDP spoofing, dan exposure layanan yang belum difilter firewall legacy. Kesalahan paling umum: tim jaringan menyalakan IPv6 di router/switch tanpa memperbarui aturan firewall, ACL, dan sistem logging.

## 2. Mekanisme Migrasi
| Metode | Deskripsi | Keamanan | Catatan Praktis |
|--------|-----------|----------|----------------|
| Dual‑stack | IPv4 & IPv6 berjalan bersamaan di interface yang sama. | Butuh kebijakan firewall ganda (IPv4 + IPv6). | Fase transisi paling aman jika kedua stack di-monitor. |
| 6to4 / Teredo / ISATAP | Tunneling otomatis melalui IPv4 network. | Rentan terhadap bypass firewall dan spoofing. | Non‑aktifkan jika tidak diperlukan. |
| NAT64/DNS64 | Translasi IPv6‑only ke layanan IPv4. | Menyembunyikan sumber IPv4 asli, tetap butuh filtering. | Berguna untuk lingkungan IPv6‑only. |
| DHCPv6 + SLAAC | Otomatisasi alamat dan prefix host. | Risiko rogue Router Advertisement. | Monitor RA/NDP dengan IDS/detection tool. |

## 3. Risiko Keamanan
> [!callout] ⚠️
> * **Blind spot IPv6** – banyak tim mematikan logging IPv6 sehingga serangan di segmen IPv6 tidak terdeteksi.
> * **Tunneling abuse** – 6to4/Teredo dapat melewati firewall tradisional dan membuka backdoor.
> * **NDP spoofing** – penyerang mengirim Router Advertisement (RA) palsu untuk menipu host memilih gateway attacker.
> * **Privacy extensions** – temporary address melindungi privasi user, tetapi mengganggu monitoring berbasis IP static.
> * **Extension header abuse** – IPv6 extension header bisa dimanfaatkan untuk evasion filter/IDS.

## 4. Praktik Terbaik (Checklist)
- [ ] **Audit inventaris** perangkat: pastikan router, switch, firewall mendukung IPv6 dengan firmware terbaru.
- [ ] **Disable tunnel otomatis**: matikan 6to4, Teredo, ISATAP kecuali memang dibutuhkan.
- [ ] **Firewall IPv6**: aturan inbound/outbound per interface — jangan sekadar menyalin aturan IPv4.
- [ ] **Enable logging**: aktifkan syslog/Netflow untuk paket IPv6 termasuk ICMPv6 (NDP, RA, NS/NA).
- [ ] **Monitor RA/NDP**: gunakan tool seperti `ndpmon`, `ramond`, atau Snort rule untuk deteksi rogue RA.
- [ ] **Segregasi jaringan**: pisahkan segmen IPv6 critical (server, SCADA) dari user via VLAN/SDN.
- [ ] **Dokumentasi transisi**: catat timeline, scope, dan owner tiap fase migrasi untuk audit.

## 5. Referensi
- RFC 8200 – IPv6 Specification; RFC 4941 – Privacy Extensions; RFC 4861 – Neighbor Discovery.
- NIST SP 800‑119 – Guidelines for the Secure Deployment of IPv6.
- [[Network_Threats/logging-compliance-guide]] – panduan logging yang wajib mencakup IPv6.
- [[covert-channel-encyclopedia]] – tunneling IPv6 sering dijadikan covert channel.
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
