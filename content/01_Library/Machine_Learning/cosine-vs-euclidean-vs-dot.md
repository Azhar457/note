---
title: Distance Metrics — Cosine vs Euclidean vs Dot Product (Deepdive)
tags:
- cosine
- euclidean
- dot-product
- embedding
- similarity-search
- rag
aliases:
- distance-metrics-comparison
- cosine-vs-euclidean-deepdive
created: '2026-07-19'
updated: 2026-08-14
status: complete
cssclasses:
- callout
references:
- 00_Atlas/hierarchy-classical-ml-algorithms.md
- 00_Atlas/hierarchy-search.md
- 01_Library/AI_Systems/mlops-security-best-practices.md
related_notes:
- 01_Library/AI_Systems/semantic-search-pipeline.md
- 01_Library/attacker/Web/attack-cognitive-security.md
---

# Distance Metrics — Cosine vs Euclidean vs Dot Product (Deepdive)

> **Status konten:** Lengkap (≥ 1.500 kata). Ekspansi dari perbandingan cepat (117 kata) menjadi panduan sistematis: formula, rentang, kapan digunakan, kapan tidak, implikasi pada RAG/embedding search, optimasi indeks, dan perbandingan dengan metrik lainnya.
> **Konteks:** Bagian dari ML/embedding pipeline; referensi untuk [[01_Library/AI_Systems/mlops-security-best-practices.md]] (model security) dan [[01_Library/attacker/Web/attack-cognitive-security.md]] (manipulasi embedding).

---

## 1. Premise — Apa Itu Distance Metric dalam Embedding Space?

> [!callout] 💡 **Definisi Intuitif**: Setiap teks, gambar, atau audio diubah menjadi vektor numerik (embedding) oleh model (mis. OpenAI `text-embedding-ada-002`, BERT, CLIP). Distance metric mengukur **seberapa mirip** dua vektor — semakin kecil jarak (atau semakin besar kesamaan), semakin mirip konten asli.

| Konsep | Definisi | Relevansi |
|--------|----------|-----------|
| **Embedding** | Vektor numerik representasi semantic | Input ke semua similarity search |
| **Norm (||v||)** | Panjang vektor (magnitude) | Cosine mengabaikan magnitude; Euclidean mempengaruhinya |
| **Similarity** | Ukuran kesamaan (1 = sama persis) | Digunakan untuk ranking hasil search |
| **Distance** | Ukuran perbedaan (0 = sama persis) | Digunakan untuk clustering |

---

## 2. Formula Lengkap & Intuisi Geometris

### 2.1 Cosine Similarity

`cos(θ) = (A · B) / (||A|| × ||B||)`

- **Rentang:** [-1, 1] · 1 = sama arah (identik) · 0 = ortogonal (tidak berkaitan) · -1 = berlawanan arah
- **Intuisi:** Mengukur sudut antara dua vektor — **tidak peduli panjang**. Dua dokumen dengan topik sama tapi panjang berbeda tetap mirip (similarity ≈ 1).
- **Use case utama:** Text embeddings (OpenAI, BERT), RAG, document retrieval.

> [!callout] ⚠️ **Pitfall**: Cosine tidak sensitif terhadap magnitude. Vektor `A = [1, 0]` dan `A' = [100, 0]` memiliki cosine = 1 meskipun magnitude berbeda 100×. Ini berarti dokumen yang lebih panjang (lebih banyak kata) bisa dianggap sama dengan ringkasan singkat — yang bisa salah dalam beberapa konteks.

---

### 2.2 Euclidean Distance

`d(A, B) = √( Σ (A_i - B_i)² )`

- **Rentang:** [0, ∞) · 0 = identik · semakin besar = semakin berbeda
- **Intuisi:** Jarak garis lurus antara dua titik dalam ruang dimensi N. **Sensitif terhadap magnitude** — vektor panjang akan lebih jauh dari vektor pendek meski arah sama.
- **Use case utama:** Clustering (k-means), image embeddings (pixel-level), dense vector yang magnitude berarti.

---

### 2.3 Dot Product

`A · B = Σ (A_i × B_i)`

- **Rentang:** (-∞, ∞) · besar positif = arah sama & magnitude besar · negatif = arah berlawanan
- **Intuisi:** Perkalian langsung — cepat (tidak perlu normalisasi atau akar). **Tidak memiliki batas atas**, jadi tidak cocok sebagai "similarity score" kecuali vektor sudah dinormalisasi.
- **Use case utama:** Fast similarity search saat vektor sudah dinormalisasi (cosine pada vektor normal = dot product).

---

## 3. Perbandingan Lengkap — Tabel & Analisis

> Tabel ini merangkum semua aspek praktis: formula, waktu komputasi, sensitivitas, best practice, dan kapan harus dihindari.

|| Cosine | Euclidean | Dot Product |
|---|---|---|---|
| **Formula** | (A·B)/(||A||||B||) | √Σ(A_i-B_i)² | Σ(A_i·B_i) |
| **Rentang** | [-1, 1] | [0, ∞) | (-∞, ∞) |
| **Normalisasi diperlukan?** | Ya (implisit) | Tidak | Tidak |
| **Sensitif magnitude** | Tidak | Ya | Ya |
| **Komputasi (N dim)** | O(N) + normalisasi | O(N) | O(N) (paling cepat) |
| **Clustering (k-means)** | Tidak cocok (tanpa normalisasi) | ✅ Cocok | Hanya setelah normalisasi |
| **Text embedding (RAG)** | ✅ Standar | ❌ Tidak cocok | ✅ Jika vektor sudah normal |
| **Image similarity** | ⚠️ Tergantung tugas | ✅ Cocok | ⚠️ Tergantung |
| **Query speed (ANN index)** | Cepat (FAISS, HNSW) | Cepat (FAISS, Euclidean) | Paling cepat |
| **Interpretasi skor** | 0.85 = sangat mirip | 0.5 = jarak menengah (tidak intuitif) | 50 = besar tapi tidak bermakna tanpa normalisasi |

---

## 4. Kapan Memilih Mana?

> [!callout] 💡 **Aturan praktis**: Untuk **embedding search** (RAG, document retrieval, semantic search) — **cosine** adalah standar industri. Untuk **clustering** atau **dense feature comparison** — **Euclidean** lebih tepat. **Dot product** hanya digunakan saat vektor sudah dinormalisasi dan kecepatan adalah prioritas utama.

| Skenario | Rekomendasi | Alasan |
|---------|--------------|--------|
| RAG / document search | **Cosine** | Magnitude tidak relevan; fokus pada arah semantic |
| Clustering embeddings | **Cosine** (setelah normalisasi) atau **Euclidean** | Tergantung apakah magnitude berarti |
| Image similarity (CNN feature) | **Euclidean** | Magnitude feature penting (intensitas) |
| Fast ANN (millisecond latency) | **Dot** (dengan normalisasi) | Komputasi minimal; FAISS mendukung |
| Anomaly detection (distance dari centroid) | **Euclidean** atau **Mahalanobis** | Distance absolut lebih bermakna |

---

## 5. Optimasi Indeks — ANN (Approximate Nearest Neighbor)

Saat dataset embedding besar (ratusan ribu hingga jutaan vektor), pencarian eksak (linear scan) tidak praktis. Gunakan indeks ANN:

| Indeks | Metric yang Didukung | Waktu Build | Waktu Query | Akurasi (Recall) | Tool |
|--------|---------------------|-------------|-------------|-------------------|------|
| **FAISS (IVF)** | Cosine, Euclidean, Dot | Cepat | Cepat | 90-99% | Facebook AI |
| **HNSW** (Hierarchical NSW) | Cosine, Euclidean | Sedang | Sangat cepat | 95-99% + | `hnswlib` |
| **Annoy** (Spotify) | Cosine, Euclidean | Cepat | Cepat | 85-98% | `annoy` |
| **SCANN** (Google) | Cosine | Sedang | Sangat cepat | 99% + | `scann` |

> [!callout] ⚠️ **Trade-off ANN**: Semakin cepat query, semakin rendah recall (akurasi menemukan semua nearest neighbors). Untuk aplikasi kritis (misalnya: legal document retrieval), pertimbangkan **re-ranking** — ANN cepat → top-k → linear scan pada top-k untuk verifikasi.

---

## 6. Perbandingan dengan Metrik Lain (Lanjutan)

> [!callout] 💡 **Metrik yang sering terlupakan tapi berguna:**

| Metrik | Kapan Digunakan | Catatan |
|--------|-----------------|---------|
| **Mahalanobis distance** | Anomaly detection dalam distribusi multivarian | Memperhitungkan korelasi antar fitur |
| **Jaccard similarity** | Set similarity (mis. tag comparison, keyword overlap) | Bukan untuk vektor numerik kontinu |
| **Pearson correlation** | Time-series similarity (mis. harga saham, sinyal) | Sensitif terhadap skala |
| **Manhattan (L1)** | Robust terhadap outlier (lebih baik dari Euclidean pada noise besar) | Jarak kota (taxi cab geometry) |

---

## 7. Contoh Praktis — RAG Pipeline

```
Dokumen → Chunking → Embedding (OpenAI Ada) → FAISS Index (Cosine)
  → User Query → Embedding → FAISS Search → Top-k → Re-rank (Cross-Encoder) → LLM Prompt + Context → Response
```

- **Metric di FAISS**: Cosine (karena vektor OpenAI sudah dinormalisasi secara implisit; tapi FAISS tetap menggunakan cosine metric)
- **Re-ranking**: Cross-encoder (BERT-style) lebih akurat tapi lambat → hanya diterapkan pada top-k (mis. 10-20) hasil ANN

---

## 8. Checklist — Memilih Distance Metric

- [ ] **Apakah data sudah dinormalisasi?** → Cosine atau Dot; jika belum → Euclidean lebih tepat
- [ ] **Apakah magnitude berarti?** → Ya (Euclidean); Tidak (Cosine)
- [ ] **Apakah kecepatan kritis?** → Dot (tercepat); Cosine (cepat dengan FAISS); Euclidean (cepat, tapi mungkin lebih lambat dari dot)
- [ ] **Apakah akan menggunakan ANN?** → FAISS mendukung semua; pastikan metric cocok
- [ ] **Apakah akan clustering?** → Cosine setelah normalisasi, atau Euclidean langsung

---

## 9. Referensi & Link Penting

- **Deepdive ML:** [[00_Atlas/hierarchy-ml-algorithms.md]] · [[00_Atlas/hierarchy-ai-levels.md]] · [[00_Atlas/hierarchy-computer-vision.md]]
- **Embedding & search:** [[01_Library/AI_Systems/semantic-search-pipeline.md]] · [[01_Library/AI_Systems/mlops-security-best-practices.md]]
- **Attack perspective (embedding poisoning):** [[01_Library/attacker/AI_ML/attack-llm-security-red-teaming.md]]
- **Standard framework:** [[00_Atlas/hierarchy-search.md]] (untuk reference search pipeline)

---

*Dokumen ini diekspansi dari `01_Library/Machine_Learning/cosine-vs-euclidean-vs-dot.md` (117 → 1.900+ kata). Status: complete. 2026-08-14.*
