---
title: Threat Modeling STRIDE DREAD
tags: [security, threat-modeling]
aliases: [threat-modeling-stride-dread]
---
# Threat Modeling: STRIDE & DREAD

Threat modeling adalah proses identifikasi, kuantifikasi, dan mitigasi risiko ancaman pada sistem. Popular: Microsoft STRIDE (kategorisasi) + DREAD (skoring risiko). Dipakai di awal desain (shift-left) — bukan setelah insiden.

## STRIDE — Kategorisasi Threat

| Akronim | Threat | Contoh | Kontrol |
|---------|--------|--------|---------|
| **S**poofing | Pemalsuan identitas | Phishing, session hijack, fake device | MFA, mutual TLS, authentication |
| **T**ampering | Modifikasi data | SQL injection, man-in-the-middle, file tampering | Integrity check, signing, parameterized query |
| **R**epudiation | Penyangkalan aksi | User membantah transaksi | Audit log, digital signature |
| **I**nformation Disclosure | Kebocoran data | Data breach, misconfig S3, verbose error | Encryption, access control, redaction |
| **D**enial of Service | Gangguan layanan | DDoS, resource exhaustion, logic bomb | Rate limit, auto-scaling, redundancy |
| **E**levation of Privilege | Naik hak akses | PrivEsc, admin bypass, root | Least privilege, RBAC, sandboxing |

## Tahapan Threat Modeling

1. **Definisikan scope & asumsi** — sistem apa, boundary, data, trust level.
2. **Buat Data Flow Diagram (DFD)** — proses, data store, external entity, trust boundary.
3. **Identifikasi threats per elemen** — STRIDE per elemen (proses, store, flow).
4. **Prioritaskan** — DREAD scoring (atau CVSS-style).
5. **Mitigasi** — kontrol yang sesuai; residual risk diterima.
6. **Dokumentasi & review** — living document; update saat arsitektur berubah.

### DFD Elements & STRIDE Mapping
- **External Entity** (user, partner): Spoofing paling relevan.
- **Process** (app logic): semua STRIDE — fokus Tampering, EoP, DoS.
- **Data Store** (DB, file): Tampering, Info Disclosure.
- **Data Flow** (API, message): Tampering (in-transit), Info Disclosure.

## DREAD — Skoring Risiko

| Kriteria | Skor 0-10 (10 = terburuk) |
|----------|---------------------------|
| **D**amage potential | Seberapa besar kerusakan jika dieksploitasi |
| **R**eproducibility | Seberapa mudah mereproduksi serangan |
| **E**xploitability | Seberapa mudah mengeksploitasi (skill, tooling) |
| **A**ffected users | Berapa banyak user/asset terdampak |
| **D**iscoverability | Seberapa mudah menemukan vuln |

Total = (D+R+E+A+D)/5 → Risiko: 0-3 Low, 4-6 Medium, 7-10 High.
Catatan: DREAD subjektif; pelengkap CVSS bila perlu. Tim beda bisa skor beda — diskusikan & konsisten.

## Contoh Penerapan

**Sistem: E-commerce dengan payment gateway**

DFD: User (external) → Web App (process) → DB (store) → Payment API (external).

| Threat | STRIDE | DREAD Total | Mitigasi |
|--------|--------|-------------|----------|
| User login spoof | Spoofing | 8 | MFA, rate limit login |
| SQLi di search | Tampering+Disclosure | 9 | Parameterized query, WAF |
| Order tampering via API | Tampering | 7 | Sign request, idempotency key |
| Payment data leak | Disclosure | 10 | Tokenization, PCI DSS, encryption |
| DDoS checkout | DoS | 6 | CDN, rate limit, auto-scale |
| Admin privEsc | EoP | 9 | RBAC, audit, zero trust |

## Metodologi Lain

- **PASTA** (Process for Attack Simulation & Threat Analysis) — attack-centric, 7 tahap, cocok untuk aplikasi besar.
- **LINDDUN** — privasi (Linkability, Identifiability, Non-repudiation, Detectability, Disclosure, Unawareness, Non-compliance).
- **Attack Trees** — grafik serangan berjenjang (root = goal attacker).
- **CVSS-based** — scoring formal untuk vuln (efektif untuk risk assessment).
- **OCTAVE** — organisasi, bukan teknis (risk tolerance).

## Tools

- **Microsoft Threat Modeling Tool** — DFD + STRIDE templates, generates threats.
- **OWASP Threat Dragon** — open-source, drag-drop DFD, STRIDE.
- **IriusRisk** — platform komersial, risk-driven, integrasi CI.
- **SecuriCAD / SD Elements** — automated threat modeling (komersial).
- Manual: draw.io + spreadsheet.

## Integrasi dengan SDLC

- Design review wajib threat modeling untuk fitur baru (security champion).
- CI: scan dependensi + SAST di tiap commit; threat model update saat arsitektur berubah.
- Retro: setelah insiden — apakah threat model menangkap vektor ini? Update.
- Red team output → input threat model berikutnya.

## Checklist

- [ ] DFD ada untuk semua komponen critical?
- [ ] Trust boundary jelas (network, host, data)?
- [ ] Threat teridentifikasi per elemen (STRIDE)?
- [ ] Scoring konsisten (DREAD/CVSS)?
- [ ] Mitigasi di-track dengan owner & deadline?
- [ ] Review berkala (kuartal / saat perubahan arsitektur)?



## Trust Boundaries — Pengertian & Contoh

Trust boundary adalah garis pemisah antara zona dengan tingkat kepercayaan berbeda. Karakteristik di masing-masing boundary:

| Boundary | Contoh | Threat Khas |
|----------|--------|-------------|
| User ↔ Web App | Internet ke server | Spoofing, injection |
| Web App ↔ DB | Server ke database | Injection, credential leak |
| App ↔ 3rd party | Payment, email API | Tampering (request), data leak |
| Host ↔ Host | Service mesh internal | Lateral movement |
| Data at rest | Disk penyimpanan | Physical theft, misconfig |

Setiap data yang melewati boundary harus: otentikasi sumbernya, integritas (sign), enkripsi (jika sensitif), dan di-audit.

## Red Team Integration

Threat model adalah peta serangan untuk red team:
1. Ambil DFD + threat list → pilih target dengan DREAD tinggi.
2. Uji mitigasi yang diklaim (bypass attempt).
3. Laporkan gap: threat yang ada di model tapi tidak ter-mitigasi = finding.
4. Validasi asumsi (trust boundary yang salah = temuan besar).

Blue team sebaliknya: pastikan mitigasi ter-deploy, monitoring aktif, dan deteksi memetakan ke threat.

## Studi Kasus: Serverless / Lambda Threat Modeling

- Spoofing: event source injection (SNS/SQS message palsu), IAM role confusion.
- Tampering: event payload manipulation (event dari user-controlled source), dependency tampering.
- Disclosure: env variables (AWS_SECRET_ACCESS_KEY) di logs; verbose error via API Gateway.
- DoS: cost explosion (unbounded recursion, huge payload), cold start flood.
- EoP: over-permissive IAM policies, lambda role escalation, confused deputy.

Template mikro: setiap fungsi lambda = process + data flow (event) — STRIDE per fungsi; fokus pada IAM boundary.

## Threat Model Document Template

```markdown
# Threat Model: <System>
## Scope & Asumsi
## DFD (gambar/diagram)
## Trust Boundaries
## Threat Register
| ID | Elemen | STRIDE | Deskripsi | Skor | Mitigasi | Status |
|----|--------|--------|-----------|------|----------|--------|
## Residual Risk & Keputusan
## Review Log
```
Simpan di folder security docs; update tiap sprint/kuartal.

---

  audited
---