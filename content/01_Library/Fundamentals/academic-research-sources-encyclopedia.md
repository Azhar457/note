---
title: Academic Research Sources Encyclopedia
tags:
  - fundamentals
  - research
  - library
  - academic
  - open-access
  - sources
created: "2026-08-02"
updated: "2026-08-02"
status: pending
cssclasses: ""
---

> [!abstract] Definisi
> Pemetaan komprehensif sumber pengetahuan ilmiah yang valid di luar arXiv — dari preprint servers, publisher repositories, open-access aggregators, repositori nasional, sampai grey literature. Dokumen ini menjawab: "Di mana menemukan paper/jurnal/research terpercaya ketika arXiv tidak mencukupi?" Ini melengkapi research-methodology.md (yang nyebut arXiv/IEEE/ACM sekilas) dan menjadi titik masuk utama untuk navigasi ekosistem publikasi akademik.

---

## 📑 Daftar Isi

1. [[#1. Arsitektur Bukan Lagi arXiv]]
2. [[#2. Preprint Servers]]
3. [[#3. Publisher Repositories & Digital Libraries]]
4. [[#4. Open-Access Aggregators & Discovery]]
5. [[#5. Repositori Nasional & Institusional]]
6. [[#6. Grey Literature & Technical Reports]]
7. [[#7. Jurnal Terbuka & Anti-Predatory]]
8. [[#8. Open Science & Tren Akses Terbuka]]
9. [[#9. Metrik Kualitas Sumber]]
10. [[#10. Strategi Pencarian Lintas Sumber]]
11. [[#11. Citation & Reference Management]]
12. [[#12. Referensi & Cross-link]]

---

## 1. Arsitektur Bukan Lagi arXiv

arXiv dominan untuk fisika, matematika, dan komputer — tapi bukan satu-satunya, dan bukan untuk semua disiplin. Biologi punya bioRxiv, ekonomi punya SSRN, hukum punya SSRN juga, dan kedokteran punya medRxiv. Strategi yang benar: **gunakan preprint server untuk kecepatan, jurnal untuk validasi, dan aggregator untuk penemuan.**

> [!tip] Kapan pakai apa
>
> - **State-of-the-art terbaru:** preprint server dengan cepat.
> - **Klaim yang perlu kepastian:** peer-reviewed journal.
> - **Penemuan lintas publisher:** aggregator (OpenAlex, CORE).
> - **Data & metadata:** OpenAlex / Semantic Scholar.

---

## 2. Preprint Servers

Preprint adalah versi paper sebelum peer review. Bebas dibaca, cepat, tapi belum divalidasi.

| Server                        | Bidang                      | Ciri                          |
| ----------------------------- | --------------------------- | ----------------------------- |
| arXiv                         | Fisika, Math, CS            | 2.4M+ paper, standar de facto |
| bioRxiv                       | Biologi                     | Praktik standar biologi       |
| medRxiv                       | Kedokteran                  | Preprint medis                |
| SSRN                          | Ekonomi, Hukum, Ilmu Sosial | Elsevier-owned                |
| ResearchSquare                | Multi-disiplin              | Review terintegrasi           |
| Zenodo                        | Data & code                 | CERN-owned, DOI permanen      |
| OSF (Center for Open Science) | Multi-disiplin              | Preprints + data + registrasi |

> [!warning]
> Preprint **belum divalidasi**. Kutip untuk riset terbaru, bukan untuk klaim yang butuh kepastian.

---

## 3. Publisher Repositories & Digital Libraries

Rumah utama paper yang sudah dikonsep & dipublikasikan secara formal.

| Publisher / Repositori           | Fokus                        | Akses                |
| -------------------------------- | ---------------------------- | -------------------- |
| IEEE Xplore                      | Engineering, CS, electronics | Paywall (banyak OA)  |
| ACM Digital Library              | Computer science             | Paywall              |
| SpringerLink                     | Multi (tech, medis)          | Partial OA           |
| Elsevier ScienceDirect           | Multi-disiplin               | Paywall, sebagian OA |
| Wiley Online Library             | Multi-disiplin               | Paywall              |
| Taylor & Francis                 | Social science               | Paywall              |
| Nature Portfolio                 | Sci, med                     | Partial OA           |
| PLOS (Public Library of Science) | Multi                        | Full OA              |
| ACS (American Chemical Society)  | Kimia                        | Paywall              |
| APS (American Physical Society)  | Fisika                       | Paywall              |
| SIAM                             | Matematika terapan           | Paywall              |
| JSTOR                            | Humanities, social science   | Paywall              |

**Repositori disiplin-spesifik (sering lebih lengkap dari arXiv):**

| Disiplin             | Repositori         | Catatan                      |
| -------------------- | ------------------ | ---------------------------- |
| Fisika energi tinggi | INSPIRE-HEP        | Literature + data HEP        |
| CS (bibliografi)     | DBLP               | Metadata paper CS terlengkap |
| Biologi              | Europe PMC         | Full-text biologi/biomedis   |
| Kimia                | ChemRxiv           | Preprint kimia               |
| Ekonomi              | RePEc / EconPapers | Working paper ekonomi        |
| Hukum                | SSRN               | Preprint hukum               |
| Medis                | PubMed / MEDLINE   | Indeks medis resmi           |

> [!info]
> **IEEE Xplore** dan **ACM DL** wajib untuk riset engineering & CS — plus di tempat arXiv kadang cuma versi draft. Untuk verifikasi final paper, kunjungi publisher-nya.

---

## 4. Open-Access Aggregators & Discovery

Layer penemuan yang menyatukan paper lintas publisher dan sering gratis.

| Tools            | Fungsi                  | Catatan                                                      |
| ---------------- | ----------------------- | ------------------------------------------------------------ |
| OpenAlex         | Metadata 250M+ karya    | Pengganti modern Scopus/Web of Science, API gratis & terbuka |
| CORE             | 300M+ paper             | Aggregator OA terbesar                                       |
| Unpaywall        | Peta DOI ke akses legal | Extension browser, DOAJ/CORE support                         |
| Semantic Scholar | 200M+ paper, AI TLDR    | Citation graph + semantic relevance                          |
| DOAJ             | Whitelist jurnal OA     | Anti-predatory                                               |
| ResearchGate     | Sharing paper           | Social network & repository                                  |
| Lens.org         | Patent + scholarly      | Hybrid OA                                                    |

> [!important] OpenAlex lebih deskriptif
> OpenAlex menggantikan Scopus & Web of Science sebagai API discovery yang **gratis**. Fetch paper, author, institution, journal impact — segalanya via REST API tanpa key.
>
> ```bash
> # Cari paper dengan keyword
> curl "https://api.openalex.org/works?search=quantum+computing&per-page=5"
> # Ambil metadata satu paper
> curl "https://api.openalex.org/works/W2741809807"
> # Filter paper per tahun untuk topik
> curl "https://api.openalex.org/works?filter=publication_year:2024"
> ```

---

## 5. Repositori Nasional & Institusional

Arsip kampus dan negara — tempat thesis, skripsi, dan riset lokal.

| Repositori          | Wilayah   | Catatan                                 |
| ------------------- | --------- | --------------------------------------- |
| Garuda              | Negara    | Portal jurnal nasional terakreditasi    |
| SINTA               | Negara    | Indeks sitasi peneliti Indonesia        |
| e-Repository kampus | Indonesia | Skripsi/thesis full-text (UI, ITB, UGM) |
| OpenAIRE            | Uni Eropa | Riset pendanaan Horizon                 |
| CORE                | Inggris   | Aggregator + repositori UK              |
| NDLTD               | Global    | Thesis & dissertation                   |

> [!tip] Untuk TA / Skripsi
> SINTA dan Garuda wajib untuk riset berbahasa Indonesia. Banyak temuan lokal hanya ada di repositori nasional — tidak muncul di arXiv atau Scopus.

---

## 6. Grey Literature & Technical Reports

Literatur non-komersial: RFC, NIST SP, whitepaper, standar — bagian vital riset terapan.

| Jenis               | Contoh              | Sumber               |
| ------------------- | ------------------- | -------------------- |
| Technical report    | RFC (IETF), NIST SP | rfc-editor.org, NIST |
| Policy brief        | World Bank, UN      | iLibrary resmi       |
| Whitepaper industri | Cloud security, AI  | Situs vendor         |
| Standar             | ISO, IEEE std       | iso.org, IEEE SA     |
| Thesis              | S2/S3 dissertation  | ProQuest, repositori |

> [!warning] Grey literature
> Tidak direview, tapi kadang satu-satunya untuk teknologi baru. Kutip dengan label, jelaskan konteks sebagai "dokumen teknis, bukan peer-reviewed".

---

## 7. Jurnal Terbuka & Anti-Predatory

Predatory jurnal menjebak peneliti muda. Kenali & hindari.

| Tanda Predatory                     | Sehat                                      |
| ----------------------------------- | ------------------------------------------ |
| Conference email tak profesional    | Publisher mapan (Elsevier, IEEE, Springer) |
| Cepat publish tanpa review (24 jam) | Review bervariasi & substansial            |
| Biaya tinggi & tak jelas            | Biaya di depan, transparan                 |
| Bebas dari indexing                 | Terindeks di DOAJ, Scopus, WoS             |
| Klaim "peer reviewed" tanpa bukti   | DOI & metadata lengkap                     |

> Cek **DOAJ** (Directory of Open Access Journals) untuk whitelist jurnal OA sehat. Cek **Scopus/WoS** untuk jurnal mapan. Selalu verifikasi indeksasi sebelum submit atau cite.

**Cara cepat verifikasi jurnal:**

1. **Cek DOAJ** — apakah terindeks di whitelist OA?
2. **Cek Scopus/WoS** — apakah terindeks di database mapan?
3. **Cek publisher** — apakah rumah publisher terkenal (Elsevier, IEEE, Springer, Wiley, Taylor & Francis, SAGE)?
4. **Cek biaya** — APC transparan? Atau email "urgent publication" mencurigakan?
5. **Cek dewan editor** — siapa editor-in-chief? Apakah orang sungguhan?
6. **Cek DOI** — DOI valid via Crossref? Metadata lengkap?

---

## 8. Open Science & Tren Akses Terbuka

Ekosistem sumber pengetahuan sedang bergeser menuju akses terbuka (Open Access).

| Gerakan                  | Deskripsi                                  | Dampak                              |
| ------------------------ | ------------------------------------------ | ----------------------------------- |
| **Plan S (cOAlition S)** | Wajibkan publikasi OA untuk riset terdanai | Publikasi paywall makin ditekan     |
| **Green OA**             | Versi accepted manuscript di repositori    | Akses gratis via repositori         |
| **Gold OA**              | Artikel langsung OA di jurnal              | APC dibayar penulis/institusi       |
| **Diamond OA**           | OA tanpa APC sama sekali                   | Model paling adil, tapi kurang umum |
| **Open Data**            | Data mentah dipublikasikan                 | Reproduksibilitas meningkat         |
| **Pre-registration**     | Hipotesis didaftarkan sebelum eksperimen   | Kurangi p-hacking                   |

> [!info]
> Konsekuensi praktis: **hampir semua paper modern punya versi OA legal** — di repositori institusi, preprint server, atau versi accepted manuscript. Unpaywall memetakan ini otomatis. "Paywall" bukan lagi alasan untuk tidak membaca.

**Cara mengecek apakah preprint sudah dipublikasikan resmi:**

1. Cari judul di Google Scholar — versi jurnal (dengan DOI) akan muncul.
2. Cek di OpenAlex / Crossref — DOI menunjuk ke versi final.
3. Bandingkan isi — preprint vs published kadang berbeda setelah review.
4. Saat mengutip, **kutip versi final** (dengan DOI), bukan preprint — kecuali versi preprint punya konten unik.

> [!tip]
> Aturan praktis: preprint untuk **kecepatan** (state-of-the-art), versi final untuk **kutipan** (validasi & DOI permanen).

---

## 9. Metrik Kualitas Sumber

Kalau masih ragu tentang sumber, rujuk metrik berikut.

| Metrik            | Definisi                               | Keterbatasan                |
| ----------------- | -------------------------------------- | --------------------------- |
| Impact Factor     | Rata-rata sitasi per artikel (2 tahun) | Bias discipline, manipulasi |
| CiteScore         | Scopus: sitasi / dokumen               | Publikasi, terbatas         |
| h-index           | Produktivitas x dampak                 | Biasa untuk peneliti        |
| Downloads/Reads   | Popularitas                            | Bukan kualitas              |
| Peer review venue | A*, A tier                             | Heuristik kualitas kuat     |

> [!tip] Para standard
> Untuk CS/Security, _*venue A* (USENIX, IEEE S&P, NeurIPS)_* adalah sinyal kualitas kuat, berkali lebih kuat daripada citation count gadget. Lihat [[research-methodology]] untuk daftar venue.

---

## 10. Strategi Pencarian Lintas Sumber

Mixed sources adalah kunci riset menyeluruh.

| Urutan | Langkah                             | Tools                                |
| ------ | ----------------------------------- | ------------------------------------ |
| 1      | Discovery: keyword di search engine | Google Scholar, OpenAlex             |
| 2      | Konfirmasi venue                    | CORE, Semantic Scholar               |
| 3      | Akses full-text                     | Unpaywall, publisher, eigen OCR      |
| 4      | Sitasi & cocok                      | Semantic Scholar, OpenAlex citations |
| 5      | Data ekstrak                        | Crossref, OpenAlex metadata          |
| 6      | Tinggal masukan data                | Mendeley/Zotero                      |

```
Search Kata Kunci
  → OpenAlex API (metadata gratis)
  → KLIK "Unpaywall" → dapat PDF legal
  → Simpan di Zotero ▸ bibtex
  → Sitasi & data ke paper
```

**Strategi akses paper paywall secara legal:**

| Metode                   | Cara                                              | Efektivitas |
| ------------------------ | ------------------------------------------------- | ----------- |
| **Unpaywall**            | Extension browser → cari versi OA legal           | ★★★★★       |
| **Email penulis**        | Minta preprint langsung ke penulis (praktik umum) | ★★★★☆       |
| **Google Scholar**       | Banyak versi preprint terindeks                   | ★★★★☆       |
| **Open Access Button**   | Tool pencari akses gratis                         | ★★★☆☆       |
| **Repository institusi** | Cek repositori kampus penulis                     | ★★★☆☆       |
| **Interlibrary loan**    | Via perpustakaan kampus                           | ★★★☆☆       |

> [!warning] Jangan pakai Sci-Hub
> Sci-Hub melanggar hak cipta dan berisiko hukum. Selalu gunakan jalur legal: Unpaywall, repositori OA, email penulis, atau akses institusi.

---

## 11. Citation & Reference Management

Mengelola ratusan sumber butuh alat — bukan folder berantakan.

| Tools                           | Kelebihan                                 | Kekurangan                                     |
| ------------------------------- | ----------------------------------------- | ---------------------------------------------- |
| **Zotero**                      | Gratis, open-source, plugin browser, sync | UI agak padat                                  |
| **Mendeley**                    | Integrasi Word, cloud sync                | Proprietary (Elsevier), fitur premium berbayar |
| **EndNote**                     | Standar institusi, fitur lengkap          | Berbayar                                       |
| **JabRef**                      | BibTeX native, ringan                     | Kurva belajar                                  |
| **Obsidian + Citations plugin** | Integrasi vault, knowledge graph          | Butuh setup                                    |

> [!tip] Untuk TA/Skripsi
> **Zotero** adalah pilihan terbaik: gratis, plugin browser untuk capture paper langsung dari IEEE/ACM/Springer, export BibTeX/Word citation, dan sync lintas device. Integrasi dengan Obsidian via Citations plugin memungkinkan linking paper ke catatan.

**Workflow manajemen referensi:**

1. Capture paper langsung dari browser (Zotero connector).
2. Organisir dalam koleksi per topik.
3. Attach PDF + highlight penting.
4. Export citation ke Word/LaTeX saat menulis.
5. Backup library (Zotero sync / WebDAV).

---

## 12. Referensi & Cross-link

- [[research-methodology]] — literatur review, IMRaD, venue tier, sitasi
- [[academic-research-sources-encyclopedia]] — panduan sumber akademik ini
- [[intelligence-reporting-sources-and-tradecraft]] — sumber intelijen operasional
- [[primary-sources-and-archival-research]] — bukti primer, arsip, declassified
- [[hierarchy-intelligence-sources-ecosystem]] — peta hierarki seluruh sumber
- [[osint-resource-index]] — sumber intelijen nasional

**Metadata**

- **Tags:** research sources academic open-access arxiv alternative library
- **Related:** [[research-methodology]], [[hierarchy-intelligence-sources-ecosystem]]
- **Last Updated:** 2026-08-02
