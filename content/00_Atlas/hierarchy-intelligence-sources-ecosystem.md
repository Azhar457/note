---
title: Hierarchy Intelligence Sources Ecosystem
tags:
  - atlas
  - intelligence
  - osint
  - research
  - sources
created: '2026-08-02'
updated: '2026-08-02'
status: pending
---

> [!tip] Abstract
> Peta hierarki ekosistem sumber pengetahuan dan intelijen — dari lapisan akademik formal (peer review) sampai lapisan operasional (HUMINT/SIGINT) dan lapisan arsip. Setiap level menjawab pertanyaan berbeda dan punya trade-off kecepatan, validasi, dan akses. Dokumen ini adalah peta konseptual untuk navigasi lintas dokumen sumber di vault: academic-research-sources-encyclopedia, intelligence-reporting-sources-and-tradecraft, primary-sources-and-archival-research, dan osint-resource-index.

## Daftar Isi

1. Level 0 — Peer-Reviewed Literature (Journals & Conferences)
2. Level 1 — Preprint Servers
3. Level 2 — Open-Access Aggregators & Discovery Layers
4. Level 3 — Institutional & National Repositories
5. Level 4 — Grey Literature & Technical Reports
6. Level 5 — Think Tanks & Policy Research
7. Level 6 — Declassified Records & Government Archives
8. Level 7 — OSINT & Open-Source Collection
9. Level 8 — SIGINT, HUMINT & GEOINT (Operational Intelligence)
10. Appendix A — Trade-off Matrix Antar Level
11. Appendix B — Navigasi Berdasarkan Kebutuhan
12. Lihat Juga

---

## Level 0 — Peer-Reviewed Literature

Lapisan paling divalidasi: paper yang melewati peer review di journal atau conference.

| Karakteristik | Detail |
|---|---|
| Akses | Paywall (IEEE, ACM, Elsevier) atau Open Access |
| Validasi | Peer review formal |
| Kecepatan | Lambat (6 bulan - 3 tahun) |
| Contoh | IEEE S&P, USENIX Security, Nature |

> [!important]
> Venue A* (USENIX, IEEE S&P, NeurIPS) punya acceptance rate 15-25% — publikasi di sini adalah sinyal kualitas kuat. Lihat [[research-methodology]] untuk tier venue.

---

## Level 1 — Preprint Servers

Versi awal paper sebelum peer review. Cepat, gratis, tapi belum divalidasi.

| Server | Bidang | Ciri |
|---|---|---|
| arXiv | Fisika, Math, CS | Terbesar, 2.4M+ paper |
| bioRxiv / medRxiv | Biologi / Kedokteran | Standar de facto biologi |
| SSRN | Ekonomi, Hukum | Elsevier-owned |
| ResearchSquare | Multi-disiplin | Review terintegrasi |

> [!warning]
> Preprint bisa mengandung error yang baru ketahuan setelah review. Kutip untuk state-of-the-art terbaru, bukan untuk klaim yang butuh kepastian.

---

## Level 2 — Open-Access Aggregators & Discovery Layers

Layer yang menjembatani paywall dan menemukan paper lintas publisher.

| Tools | Fungsi | Catatan |
|---|---|---|
| OpenAlex | Metadata 250M+ karya | Pengganti modern Scopus/WoS, API gratis |
| CORE | 300M+ paper | Aggregator OA terbesar |
| Unpaywall | Mapper DOI ke versi legal | Extension browser |
| Semantic Scholar | 200M+ paper | AI TLDR, citation graph |
| Google Scholar | Discovery terluas | Tanpa filter kualitas |
| DOAJ | Whitelist jurnal OA | Anti-predatory |

---

## Level 3 — Institutional & National Repositories

Repositori kampus dan negara — rumah thesis, skripsi, dan riset lokal.

| Repositori | Wilayah | Catatan |
|---|---|---|
| Garuda | Indonesia | Portal jurnal nasional terakreditasi |
| SINTA | Indonesia | Indeks sitasi peneliti Indonesia |
| e-Repository kampus | Indonesia | Skripsi/thesis full-text (UI, ITB, UGM) |
| OpenAIRE | Uni Eropa | Riset pendanaan Horizon |
| CORE | Inggris | Aggregator + repositori UK |

> [!info] Untuk TA/Skripsi
> SINTA dan Garuda wajib untuk riset berbahasa Indonesia. Banyak temuan lokal hanya ada di repositori nasional — tidak muncul di arXiv atau Scopus.

---

## Level 4 — Grey Literature & Technical Reports

Literatur non-komersial: RFC, NIST SP, whitepaper, standar, policy brief.

| Jenis | Contoh | Sumber |
|---|---|---|
| Technical report | RFC, NIST SP | rfc-editor.org, NIST |
| Policy brief | World Bank, UN, OECD | iLibrary resmi |
| Whitepaper industri | Cloud security, AI safety | Situs vendor |
| Standar | ISO, IEEE std | Iso.org, IEEE SA |
| Thesis | S2/S3 dissertation | ProQuest, repositori kampus |

> [!warning]
> Grey literature tidak direview — tapi sering satu-satunya sumber untuk teknologi baru. Kutip dengan label eksplisit.

---

## Level 5 — Think Tanks & Policy Research

Analisis kebijakan dan keamanan dari lembaga riset independen.

| Think Tank | Fokus | Output |
|---|---|---|
| RAND | Pertahanan, teknologi | Reports 50-100 halaman |
| CSIS | Geopolitik, siber | Commentary, reports |
| IISS | Kekuatan militer | Military Balance |
| Brookings | Kebijakan luar negeri | Policy papers |
| Chatham House | Kebijakan global (UK) | Expert commentary |
| RUSI | Pertahanan UK | Occasional papers |
| SIPRI | Senjata, konflik | SIPRI Yearbook |

> [!note]
> Daftar lengkap situs ada di [[osint-resource-index]] section 14. Dokumen ini memetakan *posisi* mereka dalam hierarki: setelah akademik (validasi) tapi sebelum OSINT operasional (kecepatan).

---

## Level 6 — Declassified Records & Government Archives

Sumber primer sejarah intelijen dan pemerintahan — dokumen yang pernah rahasia kini terbuka.

| Sumber | Isi | Akses |
|---|---|---|
| CIA FOIA Reading Room | Intel reports | Gratis online |
| NSA Declassification | SIGINT histories | Gratis online |
| FBI Vault | File kasus | Gratis online |
| NARA | Arsip federal AS | Gratis |
| UK National Archives | File MI5/MI6 (30-year rule) | Gratis |
| ANRI | Arsip negara Indonesia | anri.go.id |

> [!danger]
> Declassified ≠ transparent. Dokumen di-redact dan dipilih untuk dibuka. Sadari seleksi + redaction.

---

## Level 7 — OSINT & Open-Source Collection

Pengumpulan dari sumber terbuka: web, media, publikasi, data publik.

| Tools | Fungsi |
|---|---|
| Shodan | Perangkat terhubung internet |
| Maltego | Graph link analysis |
| Google Dorks | Operator pencarian lanjut |
| Wayback Machine | Snapshot historis |
| Bellingcat | Investigasi open-source |

> [!note]
> Ini ranah [[hierarchy-osint-rf]] dan [[hierarchy-search]] — detail tools ada di sana. Dalam hierarki ini, OSINT adalah lapisan *collection*, bukan *analisis*.

---

## Level 8 — SIGINT, HUMINT & GEOINT (Operational Intelligence)

Disiplin intelijen operasional — di luar jangkauan riset akademik biasa.

| Disiplin | Sumber | Kekuatan |
|---|---|---|
| SIGINT | Komunikasi, emisi | Volume besar, real-time |
| HUMINT | Manusia, informan | Konteks, intent |
| GEOINT | Citra satelit, geodata | Visual, kontekstual |
| MASINT | Sensor fisik | Deteksi tersembunyi |

> [!warning]
> Pengumpulan sinyal komunikasi privat ilegal di hampir semua jurisdiksi. Riset intelijen yang etis berhenti di Level 7 — Level 8 adalah ranah organisasi berwenang.

---

## Appendix A — Trade-off Matrix Antar Level

| Level | Validasi | Kecepatan | Akses | Biaya |
|---|---|---|---|---|
| 0 Peer-Review | ★★★★★ | ★☆☆☆☆ | ★★☆☆☆ | ★★☆☆☆ |
| 1 Preprint | ★★☆☆☆ | ★★★★☆ | ★★★★★ | ★☆☆☆☆ |
| 2 Aggregator | ★★★☆☆ | ★★★★☆ | ★★★★★ | ★☆☆☆☆ |
| 3 Repositori | ★★★☆☆ | ★★★☆☆ | ★★★★★ | ★☆☆☆☆ |
| 4 Grey Lit | ★★☆☆☆ | ★★★★☆ | ★★★★☆ | ★☆☆☆☆ |
| 5 Think Tank | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★☆☆☆☆ |
| 6 Declassified | ★★★★☆ | ★☆☆☆☆ | ★★★☆☆ | ★☆☆☆☆ |
| 7 OSINT | ★★☆☆☆ | ★★★★★ | ★★★★★ | ★☆☆☆☆ |
| 8 Operasional | ★★★★★ | ★★★★★ | ☆☆☆☆☆ | ★★★★★ |

## Appendix B — Navigasi Berdasarkan Kebutuhan

| Kebutuhan | Mulai Dari |
|---|---|
| State-of-the-art terbaru | Level 1 (preprint) + Level 2 (aggregator) |
| Klaim yang butuh kepastian | Level 0 (peer-reviewed) |
| Riset lokal Indonesia | Level 3 (Garuda, SINTA) |
| Teknologi baru tanpa paper | Level 4 (whitepaper vendor) |
| Analisis kebijakan & geopolitik | Level 5 (think tank) |
| Sejarah intelijen | Level 6 (declassified) |
| Investigasi target spesifik | Level 7 (OSINT tools) |

---

## Lihat Juga

- [[academic-research-sources-encyclopedia]] — detail Level 0-4
- [[intelligence-reporting-sources-and-tradecraft]] — detail Level 5-8
- [[primary-sources-and-archival-research]] — detail Level 6 + metode
- [[osint-resource-index]] — daftar situs per negara
- [[hierarchy-search]] — peta akses informasi (web → dark web → SIGINT)
- [[hierarchy-osint-rf]] — peta OSINT & RF collection
- [[research-methodology]] — proses riset dari observasi ke publikasi

**Metadata**

- **Tags:** atlas intelligence sources hierarchy research osint
- **Related:** [[academic-research-sources-encyclopedia]], [[intelligence-reporting-sources-and-tradecraft]], [[osint-resource-index]]
- **Last Updated:** 2026-08-02
