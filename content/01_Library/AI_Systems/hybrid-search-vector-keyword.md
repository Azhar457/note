---
title: "🔀 Hybrid Search — Vector + Keyword Fusion: RRF, Weighted, Dense→Sparse di vault-rag"
tags:
  - hybrid-search
  - rag
  - retrieval
  - fusion
  - bm25
  - library
aliases:
  - "hybrid-search-vector-keyword"
created: "2026-07-16"
updated: "2026-07-16"
status: operational
cssclasses:
  - wide-table
---

# 🔀 Hybrid Search — Vector + Keyword Fusion: RRF, Weighted, Dense→Sparse di vault-rag

> Dense retrieval (embedding) menangkap makna, BM25 (keyword) menangkap kecocokan literal. Masing-masing punya kelemahan: embedding kesusahan dengan istilah teknis langka (singkatan, kode error), BM25 kesusahan dengan sinonim dan konsep (tanpa kata kunci yang sama). Hybrid search menggabungkan keduanya. Dokumen ini membedah teknik fusion — Reciprocal Rank Fusion (RRF), weighted score, dense→sparse — dengan implementasi konkret dari vault-rag yang udah pake hybrid search sejak awal.

> [!info] Hubungan ke Vault
> vault-rag sudah menerapkan hybrid search: dense (cosine) × 0.7 + BM25 (FTS5) × 0.3. Catatan ini menjelaskan kenapa weight itu dipilih, alternatif fusion (RRF), dan sparse embedding BGE-M3. Terkait dengan [[vector-database-internals-optimization]] (dense index), [[advanced-chunking-strategies-deepdive]] (FTS5 index di child chunks), dan `../vault-rag/scripts/query.py` (implementasi `search_hybrid()`).

---

## Daftar Isi

- [[#1. Kenapa Hybrid?]]
- [[#2. Fusion Techniques]]
- [[#3. Sparse Embeddings]]
- [[#4. Implementasi vault-rag]]
- [[#5. Tuning Weight]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. Kenapa Hybrid?

### 1.1 Dense vs Sparse

| Aspek               | Dense (Vector)                                                             | Sparse (BM25/Keyword)                                |
| ------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------- |
| **Cocok untuk**     | Makna, sinonim, konsep                                                     | Istilah exact, kode, singkatan                       |
| **Gagal saat**      | Istilah langka, typo                                                       | Konsep tanpa kata kunci bersama                      |
| **Contoh berhasil** | "Cara hacker menyusup" → dapet artikel "Teknik post-exploitation"          | "CVE-2021-44228" → dapet artikel Log4j               |
| **Contoh gagal**    | "gRPC vs REST" → dapet artikel "API protocols" (kata gRPC/REST gak muncul) | "API protocol" — BM25 gak cocokin "gRPC" atau "REST" |

### 1.2 Gabungan = Lebih Baik

```python
# Query: "Cara fix SYN flood dengan SYN cookies"
# Dense  → dapet: artikel "SYN flood mitigation" (makna cocok)
# BM25   → dapet: artikel "SYN cookies implementation" (kata "SYN cookies" exact)
# Hybrid → dapet: artikel "TCP state machine detection" yang covers both
```

---

## 2. Fusion Techniques

### 2.1 Weighted Score (dipakai vault-rag)

```python
final_score = dense_score × 0.7 + bm25_score × 0.3
# Dense di-weight lebih besar karena menangkap makna lebih baik
# BM25 sebagai complementary — khusus untuk exact match
```

### 2.2 Reciprocal Rank Fusion (RRF)

RRF memberikan skor berdasarkan **ranking position**, bukan raw score:

```python
def rrf(dense_results, bm25_results, k=60):
    """
    k = smoothing constant (default 60).
    RRF score = 1 / (k + rank)
    """
    scores = {}
    for rank, doc in enumerate(dense_results):
        scores[doc["id"]] = 1 / (k + rank + 1)
    for rank, doc in enumerate(bm25_results):
        scores[doc["id"]] = scores.get(doc["id"], 0) + 1 / (k + rank + 1)
    return sorted(scores.items(), key=lambda x: x[1], reverse=True)
```

**Keunggulan RRF:**

- Tidak perlu normalize score (dense vs BM25 punya distribusi beda)
- Robust — satu hasil dominan gak menenggelamkan yang lain
- Parameter `k`: kecil = penekanan pada top rank, besar = distribusi lebih merata

**Kelemahan:** Ranking position buta terhadap seberapa _yakin_ model.

### 2.3 Dense→Sparse Fallback

Gunakan dense dulu. Kalo dense gagal (max score < threshold), fallback ke BM25:

```python
dense_results = search_dense(query)
if not dense_results or dense_results[0]["score"] < 0.5:
    return search_bm25(query)  # fallback ke keyword
return dense_results
```

### 2.4 Perbandingan

| Method           | Keunggulan                        | Kelemahan               | vault-rag?          |
| ---------------- | --------------------------------- | ----------------------- | ------------------- |
| **Weighted**     | Sederhana, interpretable          | Butuh normalize score   | ✅ **Sekarang**     |
| **RRF**          | Gak perlu normalize, robust       | Buta confidence         | 🟡 Bisa ditambahkan |
| **Dense→Sparse** | Cepat (gak perlu 2 search selalu) | Kehilangan hasil hybrid | ❌                  |

---

## 3. Sparse Embeddings

Sparse embedding = embedding yang menghasilkan vector **jarang** (kebanyakan 0). Contoh: SPLADE, BGE-M3 (mode sparse), UniCOIL.

```
Dense:  [0.23, -0.45, 0.0, 0.12, ..., -0.33]  — semua dimensi terisi
Sparse: [0, 0, 0, 0, 2.5, 0, 0, 0, 0, 1.3, 0, ...] — kebanyakan 0
```

Keunggulan sparse embedding:

- Bisa di-index pake **inverted index** (sama kaya BM25) — sangat cepat
- Gabungan dense representation learning + exact match capability
- BGE-M3 support dense + sparse dari satu model

---

## 4. Implementasi vault-rag

### 4.1 Saat Ini (Weighted Fusion)

```python
# scripts/query.py baris 93-129
def search_hybrid(query, query_emb, conn, top_k=40):
    dense = search_dense(query_emb, conn, 60)
    bm25 = search_bm25(query, conn, 20)
    # Weighted fusion
    final_score = dense_score * 0.7 + bm25_score * 0.3
```

### 4.2 Alternatif: RRF

Kalo mau ganti ke RRF:

```python
def search_hybrid_rrf(query, query_emb, conn, top_k=40):
    dense = search_dense(query_emb, conn, 60)
    bm25 = search_bm25(query, conn, 30)
    return rrf(dense, bm25, k=60)[:top_k]
```

---

## 5. Tuning Weight

### 5.1 Cara Test Weight Optimal

```python
test_queries = [
    ("query1", {"relevant_ids": [...]}),
    ("query2", {"relevant_ids": [...]}),
]

best_weight = 0.0
best_recall = 0.0

for w in [0.5, 0.6, 0.7, 0.8, 0.9]:
    results = hybrid_search(query, dense_weight=w)
    recall = compute_recall(results, expected["relevant_ids"])
    if recall > best_recall:
        best_recall = recall
        best_weight = w

print(f"Best weight: dense={best_weight}, BM25={1-best_weight}")
```

### 5.2 Rekomendasi

| Konten Vault             | Dense Weight | BM25 Weight |
| ------------------------ | ------------ | ----------- |
| Konseptual (makna)       | 0.8          | 0.2         |
| Teknis (istilah exact)   | 0.6          | 0.4         |
| **Campuran (vault ini)** | **0.7**      | **0.3**     |

---

## Koneksi ke Vault

- [[advanced-chunking-strategies-deepdive]] — FTS5 di child chunks untuk BM25 search
- [[embedding-model-selection-finetuning]] — Dense embedding untuk dense search
- [[vector-database-internals-optimization]] — Dense index (HNSW) + FTS5 index (BM25)
- `../vault-rag/scripts/query.py` — Implementasi `search_hybrid()` → `search_dense()` + `search_bm25()`

---

## References

1. RRF Paper. _G. Cormack et al. (2009)_. https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf
2. SPLADE. _T. Formal et al. (2021)_. https://arxiv.org/abs/2107.05720
3. BGE-M3. https://huggingface.co/BAAI/bge-m3
4. Elasticsearch. _Hybrid Search_. https://www.elastic.co/guide/en/elasticsearch/reference/current/hybrid-search.html

> [!tip] Bottom Line
> Hybrid search = dense (makna) + sparse (keyword). vault-rag pake **weighted fusion (dense×0.7 + BM25×0.3)** — sudah OK. Alternatif: **RRF** lebih fair karena gak perlu normalize score. Kalo mau upgrade: sparse embedding (BGE-M3 mode sparse) = BM25 + deep learning dalam satu model.
