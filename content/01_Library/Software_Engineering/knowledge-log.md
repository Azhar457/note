---
title: Knowledge Log — Weekly Tracker
tags:
  - knowledge-log
  - weekly
  - productivity
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
references:
  - [[semantic-search-pipeline]]
  - [[computer-vision-deepdive]]
related_notes:
  - [[Software_Engineering/knowledge-log|Knowledge Log Overview]]
---

> Knowledge log adalah weekly reflection tool yang membantu menelusuri kemajuan belajar dan membangun koneksi antar topik.

## 1. Ringkasan / Definisi
Knowledge log (atau growth log) adalah catatan berkala (mingguan) yang merekam apa yang dipelajari, apa yang berhasil, apa yang membingungkan, serta langkah selanjutnya. Ia berfungsi sebagai umpan balik terhadap kebiasaan belajar dan bahan untuk membangun second brain berbasis Obsidian. Log ini bukan hanya catatan aktivitas — ia adalah alat untuk mendeteksi pola belajar, mengidentifikasi topik yang terhambat, dan memastikan setiap pengetahuan baru terhubung dengan vault yang sudah ada.

## 2. Template Standar
```markdown
# Knowledge Log - Week XX

## Achievements
- [ ] Topic 1: Learned X -> selesai/exercise/belum
- [ ] Topic 2: Built Y -> selesai/exercise/belum

## Reflection
- What clicked?
- What was confusing?
- Connection to vault: [[related-note]]

## Next Week
- Topic A (continued)
- Topic B (new)
```

## 3. Struktur Log Detail
Setiap entri mingguan sebaiknya memiliki struktur berikut:
- **Header**: Minggu, tanggal mulai/selesai, fokus utama minggu ini.
- **Achievements**: 3–5 bullet point minimal, dengan status checkbox (`[ ]` belum, `[x]` selesai, `[~]` dalam proses).
- **Reflection**: 2–3 kalimat tentang apa yang berhasil dan apa yang membingungkan.
- **Connection to Vault**: Setiap achievement harus memiliki minimal satu wikilink `[[...]]` ke note vault yang relevan.
- **Next Week**: 2–3 topik yang akan dipelajari atau diselesaikan.
- **Metrics Opsional**: jumlah jam belajar, jumlah note baru, jumlah revisi.

## 4. Tips & Best Practices
- Minimal 3 bullet points per minggu untuk menjaga momentum.
- Link setiap achievement ke note vault dengan `[[wikilink]]`.
- Gunakan status checkbox agar mudah disaring di Dataview atau query manual.
- Jangan overthinking — tulis apa adanya, rapikan belakangan.
- Review log bulanan untuk mengidentifikasi pola (topik apa yang sering bolong, berapa lama waktu rata‑rata menyelesaikan topik tertentu).
- Gunakan template ini sebagai basis, tetapi sesuaikan dengan gaya belajar pribadi (visual, auditori, kinestetik).

> [!callout] 💡
> Integrasikan knowledge log dengan [[semantic-search-pipeline]] agar pencarian insight antar minggu lebih efisien. Gunakan embedding query untuk menemukan koneksi tersembunyi antar note.

## 5. Checklist Mingguan
- [ ] Selesaikan 3 bullet point achievement.
- [ ] Refleksi kesulitan dan pencapaian dalam 2–3 kalimat.
- [ ] Kaitkan minimal 1 note vault baru dengan `[[wikilink]]`.
- [ ] Perbarui status "Next Week".
- [ ] (Opsional) Buat summary bulanan dengan grafik kemajuan.
- [ ] (Opsional) Ekspor log ke file markdown arsip per bulan.

## 6. Referensi Cross-Note
- [[Machine_Learning/semantic-search-pipeline]] – untuk mencari insight dalam vault menggunakan semantic search.
- [[AI_Systems/computer-vision-deepdive]] – contoh deep‑dive note yang bisa dilog sebagai achievement mingguan.
- [[Machine_Learning/deepfake-detection]] – studi kasus topik yang bisa direfleksikan dalam log.

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
