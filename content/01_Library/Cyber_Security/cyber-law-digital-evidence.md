---
title: Cyber Law & Digital Evidence — Legal Frameworks for Security Operations
tags:
  - cyber-law
  - digital-evidence
  - chain-of-custody
  - gdpr
  - legal
  - forensics
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Forensik tanpa basis hukum menghasilkan bukti yang tidak dapat dipakai di pengadilan. Catatan ini melengkapi [[incident-response-framework]] dan [[forensic-imaging-analysis]] dengan dimensi legal: chain of custody, admissibility, dan kerangka peraturan yang menjadikan bukti "court‑ready".
>
> **Domain:** Cyber Security / Legal
> **Tags:** #cyber-law #digital-evidence #chain-of-custody #gdpr #forensics

## 1. Ringkasan Eksekutif
Digital evidence lifecycle memerlukan prosedur yang ketat mulai dari **collection** hingga **presentation** di pengadilan. Tanpa dokumentasi chain of custody yang lengkap, bukti dapat dianggap **inadmissible** atau bahkan menjadi **self‑incriminating**. Kerangka hukum internasional (GDPR, EU e‑Privacy, UU ITE, CFAA) mengatur hak subjek data, notifikasi breach, dan konsekuensi kriminal bagi pelaku. Tim forensik harus menyeimbangkan **preservasi integritas** dengan **kewajiban pelaporan** dalam batas waktu regulasi.

## 2. Threat Model / Konteks
| Aspek | Detail |
|-------|--------|
| **Target** | Media penyimpanan (SSD, HDD, cloud storage) yang mengandung data pribadi atau rahasia perusahaan |
| **Actor** | Penyerang eksternal, insider, agen penegak hukum |
| **Vektor** | Disk imaging, memory dump, jaringan packet capture |
| **Dampak** | Pelanggaran privasi, kerugian finansial, sanksi regulator |
| **Regulasi** | GDPR (EU), UU ITE (Indonesia), CFAA (US), PCI DSS, HIPAA |

## 3. Langkah‑Langkah Teknik Detail
| # | Tahap | Aktivitas Utama | Artefak / Output |
|---|-------|----------------|-----------------|
| 1 | **Collection** | Gunakan write‑blocker hardware, `dd` atau `dcfldd` dengan hash (`sha256sum`) | Image bit‑for‑bit, hash SHA‑256, log tanggal/waktu |
| 2 | **Preservation** | Simpan image pada media write‑once (WORM) atau offline storage, duplikat untuk analisis | Salinan read‑only, checksum kedua |
| 3 | **Analysis** | Mount image dengan `mount -o ro`, gunakan `sleuthkit`, `autopsy` untuk ekstraksi, catat setiap perintah | Laporan temuan, hash tambahan pada file artefak |
| 4 | **Documentation** | Buat Chain of Custody (CoC) elektronik, tanda tangan digital, sertakan witness | Formulir CoC terstandarisasi (PDF/MD) |
| 5 | **Presentation** | Siapkan *expert report* dengan metodologi, verifikasi hash, dan keterangan legal | Dokumen expert testimony, sertifikat integritas |

### Contoh Python – Chain of Custody Record
```python
CHAIN_OF_CUSTODY = {
    "case_id": "IR-2026-001",
    "evidence_id": "EVD-001",
    "description": "Samsung SSD 870 EVO 500GB - suspect laptop",
    "acquisition": {
        "date": "2026-07-15T14:22:00+07:00",
        "method": "dd if=/dev/sda of=/mnt/evd/EVD-001.img bs=4M status=progress",
        "hash_sha256": "a1b2c3d4e5f6...",
        "investigator": "Azhar Muttaqien",
        "witness": "Security Team Lead"
    },
    "transfers": [
        {"from": "Scene of Crime", "to": "Forensics Lab", "date": "2026-07-15T15:30:00+07:00", "reason": "Chain transfer", "signature": "John Doe / Jane Smith"}
    ]
}
```

## 4. Contoh Praktis
```bash
# Imaging dengan dcfldd (hash + log)
sudo dcfldd if=/dev/sdb of=/mnt/evd/laptop.img hash=sha256 hashlog=/mnt/evd/laptop.sha256 log=/mnt/evd/laptop.log

# Verifikasi hash pada workstation analisis
sha256sum -c /mnt/evd/laptop.sha256
```

## 5. Checklist Mitigasi Legal
- [ ] Pastikan **write‑blocker** fisik terpasang sebelum imaging
- [ ] Rekam **hash SHA‑256** pada _both_ source dan image
- [ ] Dokumentasikan **Chain of Custody** dengan tanda tangan digital dan saksi
- [ ] Pertimbangkan **GDPR breach notification** deadline (72 jam) jika data pribadi terlibat
- [ ] Simpan bukti di **WORM** atau media offline dengan kontrol akses
- [ ] Lakukan **legal hold** sebelum menghapus atau memodifikasi data
- [ ] Sinkronkan prosedur dengan **policy internal** dan **ISO 27037**

## 6. Referensi Lintas
- [[incident-response-framework]]
- [[forensic-imaging-analysis]]
- [[digital-privacy-anonymity]]
- [[threat-modeling-stride-dread]]
- [[security-economics-cost-of-breach]]

---

### 📚 Referensi
1. NIST SP 800‑86: Guide to Integrating Forensic Techniques into Incident Response
2. ISO 27037: Guidelines for Identification, Collection, Acquisition and Preservation of Digital Evidence
3. "Digital Forensics and Cyber Law" — ACME Publications
4. GDPR Recital 78, Article 33 (Data Breach Notification)
5. UU ITE (Indonesia) Pasal 27‑37

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
