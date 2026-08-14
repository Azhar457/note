# Incident Response Framework

Kerangka standar untuk *incident response* (IR) di lingkungan organisasi. Mengacu pada NIST SP 800-61 Rev. 2, ISO 27035, dan praktik industri.

## 1. Persiapan (Preparation)
- Tim IR (CSIRT/SOC): roles, escalation matrix, komunikasi.
- Playbook per tipe insiden: malware, phishing, ransomware, insider threat, supply chain.
- Tooling: SIEM (Wazuh, Splunk), EDR (Velociraptor, Osquery), forensik (Volatility, Autopsy), sandbox (CAPE, Joe Sandbox).
- Logging: central log (Loki/ELK), auditd, Sysmon, Zeek, Suricata.
- Threat intel feed: MISP, OTX, Abuse.ch, MITRE ATT&CK.
- Komunikasi aman: Signal, Matrix, PGP.

## 2. Deteksi & Analisis (Detection & Analysis)
- Sumber: alert SIEM, user report, threat intel, threat hunting, DFIR.
- Triage: severity (Critical/High/Medium/Low), scope (host/network/cloud), IOC.
- Enrichment: VirusTotal, URLhaus, AlienVault, PassiveTotal, Shodan.
- Korelasi: MITRE ATT&CK mapping, kill chain phase.
- Evidence preservation: chain of custody, hash (SHA256), imaging (FTK Imager, dd).

## 3. Penghentian, Penghapusan, Pemulihan (Containment, Eradication, Recovery)
| Fase | Tindakan |
|------|----------|
| **Short-term containment** | Isolasi jaringan (VLAN quarantine), block IOC di firewall/WAF, disable akun kompromi. |
| **Long-term containment** | Patch vuln, rotate kredensial, rebuild sistem bersih, implementasi mitigasi sementara. |
| **Eradication** | Hapus malware/persistensi, hapus backdoor, revoke sertifikat kompromi, verifikasi keamanan supply chain. |
| **Recovery** | Restore dari backup terverifikasi, monitoring tinggi (30 hari), validasi integritas data. |

## 4. Pasca-Insiden (Post-Incident Activity)
- Lessons learned meeting (max 2 minggu setelah closure).
- Root cause analysis (5 Whys, Fishbone).
- Update playbook, detection rule, hardening.
- Metrics: MTTR, MTTD, false positive rate, coverage ATT&CK.

## Referensi
- NIST SP 800-61 Rev. 2
- ISO/IEC 27035
- MITRE ATT&CK Navigator
- SANS Incident Handler's Handbook

---
cssclasses:
  - wide-table
  - callout

*Generated automatically by Hermes Agent.*

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

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian dilakukan berdasarkan: ada vs tidak ada kontrol, efektivitas, dan dokumentasi.

### Glossary

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
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **OIDC** | OpenID Connect (identity layer) |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/

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

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
