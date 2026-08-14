---
title: Semantic Search Pipeline
tags:
  - semantic-search
  - embedding
  - retrieval
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
  - code-wrap
references:
  - [[knowledge-log]]
  - [[computer-vision-deepdive]]
related_notes:
  - [[Machine_Learning/semantic-search-pipeline|Semantic Search Pipeline]]
---

> Semantic search menggunakan meaning (embedding) bukan keyword matching, sehingga mampu menangkap intent dan konteks.

## 1. Ringkasan / Definisi
Semantic search adalah teknik retrieval yang merepresentasikan dokumen dan query sebagai vektor numerik (embedding) dalam ruang multidimensi. Dokumen dengan makna mirip akan berdekatan secara kosinus, memungkinkan pencarian berdasarkan arti, sinonim, dan konteks, berbeda dengan lexical search (BM25) yang hanya mencocokkan token. Pipeline ini penting untuk sistem RAG (Retrieval‑Augmented Generation), pencarian dokumen, dan analisis konten besar.

## 2. Arsitektur Pipeline
```
Query -> Embedding -> Vector Search -> Rerank -> Response
                BM25 (keyword fallback)
```

## 3. Komponen
| Component | Tool | Purpose |
|-----------|------|---------|
| Embedding | text-embedding-3-small, BGE, E5 | Convert query & doc ke vektor |
| Vector Search | sqlite-vec, FAISS, Qdrant | ANN (approximate nearest neighbor) |
| Keyword Search | BM25, Tantivy, SQLite FTS5 | Exact match fallback |
| Fusion | RRF (Reciprocal Rank Fusion) | Hybrid ranking merge |
| Rerank | Cohere, cross-encoder | Rerank top‑K hasil |
| Ingestion | chunking + metadata | Persiapan dokumen & indexing |

## 4. Langkah Implementasi (Checklist)
- [ ] Pilih model embedding (ukuran dimensi, bahasa, budget).
- [ ] Normalisasi teks: strip HTML, lower‑case, tokenisasi.
- [ ] Chunking dokumen (500–1000 token, overlap 10–20%).
- [ ] Simpan metadata (source, timestamp, tags) untuk filter.
- [ ] Build index vektor + FTS index untuk hybrid search.
- [ ] Implementasikan RRF untuk menggabungkan skor vektor dan BM25.
- [ ] Tambahkan reranker cross‑encoder pada top‑K (20–50).
- [ ] Evaluasi dengan retrieval metrics (recall@k, MRR, NDCG).
- [ ] Monitor performa query latency; target < 200ms untuk 1000 dokumen.
- [ ] Integrasikan dengan aplikasi frontend atau API.

> [!callout] ⚠️
> Tanpa chunking yang benar dan metadata yang kaya, hasil semantic search bisa kehilangan konteks dokumen panjang dan sulit di-filter. Pastikan setiap chunk memiliki konteks cukup untuk interpretasi mandiri.

## 5. Use Case & Manfaat
- **RAG (Retrieval‑Augmented Generation)**: meningkatkan akurasi LLM dengan fakta terkini dari vault.
- **Pencarian internal**: menemukan dokumen berdasarkan makna, bukan hanya judul.
- **Rekomendasi**: menyarankan artikel atau produk berdasarkan preferensi pengguna.
- **Forensik & audit**: mencari dokumen yang memiliki makna mirip meskipun tidak menggunakan kata kunci yang sama.

## 6. Referensi
- [[Software_Engineering/knowledge-log]] – alur pencatatan insight yang bisa dicari semantik.
- [[AI_Systems/computer-vision-deepdive]] – perbandingan arsitektur (transformer) yang mirip di domain vision.
- Paper: "Dense Passage Retrieval" (Karpukhin et al., 2020).
- Dokumentasi FAISS & sqlite‑vec.

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
