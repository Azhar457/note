---
title: "🗄️ Vector Database Internals & Optimization — HNSW, IVF, PQ, dan Performa Search di vault-rag"
tags:
  - vector-database
  - hnsw
  - indexing
  - optimization
  - rag
  - library
aliases:
  - "vector-database-internals-optimization"
created: "2026-07-16"
updated: "2026-07-16"
status: operational
cssclasses:
  - wide-table
---

# 🗄️ Vector Database Internals & Optimization — HNSW, IVF, PQ, dan Performa Search di vault-rag

> Vector database adalah engine yang membuat semantic search mungkin dalam milidetik — bukan dengan membandingkan query ke semua dokumen (brute force), tapi dengan struktur index yang cerdas. Dokumen ini membedah arsitektur index vector: HNSW (Hierarchical Navigable Small World), IVF (Inverted File Index), Product Quantization (PQ), scalar quantization, dan bagaimana sqlite-vec (yang dipake vault-rag) bekerja di bawah hood. Plus: strategi tuning untuk performa search vs akurasi.

> [!info] Hubungan ke Vault
> vault-rag menggunakan **sqlite-vec** dengan cosine search (brute force — karena ukuran data masih kecil). Catatan ini membahas scaling: kapan perlu HNSW, trade-off akurasi vs latency, dan optimasi index. Terkait dengan [[embedding-model-selection-finetuning]] (dimensi → performa index), [[hybrid-search-vector-keyword]] (dense + sparse === dua index berbeda), dan `../vault-rag/scripts/index_vault.py` (sqlite-vec integration).

---

## Daftar Isi

- [[#1. Brute Force vs Indexed Search]]
- [[#2. HNSW]]
- [[#3. IVF]]
- [[#4. Quantization]]
- [[#5. sqlite-vec Internals]]
- [[#6. Kapan Pake Apa]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. Brute Force vs Indexed Search

### 1.1 Kompleksitas

| Method                 | Search Complexity | Memory               | Akurasi        | Cocok untuk                                 |
| ---------------------- | ----------------- | -------------------- | -------------- | ------------------------------------------- |
| **Brute Force (flat)** | O(n×d)            | Rendah               | 100%           | Dataset < 10K vektor                        |
| **HNSW**               | O(log n)          | Tinggi (1.5-2x)      | ~99% recall@10 | Dataset > 10K, butuh latency rendah         |
| **IVF**                | O(√n)             | Rendah               | ~95% recall    | Dataset besar, akurasi bukan prioritas      |
| **IVF+PQ**             | O(√n)             | Sangat rendah (0.2x) | ~90% recall    | Dataset sangat besar (>1M), memory terbatas |

**Posisi vault-rag:** Saat ini <10K chunks → **brute force sudah cukup.** Kalo vault tumbuh >50K chunks, baru perlu pindah ke HNSW.

### 1.2 Trade-off

```
Akurasi (%)
   100│  ● Brute Force
       │
    99 │     ● HNSW
       │
    95 │           ● IVF
       │
    90 │                ● IVF+PQ
       │
       └──────────────────────────→ Latency (ms)
         1ms    10ms    100ms
```

---

## 2. HNSW (Hierarchical Navigable Small World)

### 2.1 Cara Kerja

HNSW membangun **multi-layer graph**. Layer paling atas = "jalan tol" (few nodes, long jumps). Layer paling bawah = "jalan lokal" (all nodes, nearest neighbors).

```
Layer 3 (2 nodes)     ○ ←─────────────────── ○
                       │                       │
Layer 2 (8 nodes)    ○─○─○  ←───────────  ○─○─○
                       │  │                  │  │
Layer 1 (32 nodes)   ○─○─○─○─○─○─○─○  ○─○─○─○─○─○
                       │  │  │  │  │  │  │  │  │  │
Layer 0 (all)        ○─○─○─○─○─○─○─○─○─○─○─○─○─○─○
```

**Search:** Mulai dari layer teratas → cari node terdekat → turun layer → refine → sampe layer 0 dapet nearest neighbor sejati.

### 2.2 Parameter

| Parameter               | Default        | Rendah                     | Tinggi                                |
| ----------------------- | -------------- | -------------------------- | ------------------------------------- |
| **M** (max connections) | 16             | Index kecil, recall turun  | Index besar, recall naik, memory naik |
| **ef_construction**     | 200            | Index building cepat       | Index building lambat, recall naik    |
| **ef_search**           | 50 (per query) | Search cepat, recall turun | Search lambat, recall naik            |

### 2.3 Implementasi

```python
# Contoh: HNSW dengan FAISS
import faiss
import numpy as np

d = 256  # dimensi embedding
index = faiss.IndexHNSWFlat(d, M=32)  # M = 32 connections per node
index.hnsw.efConstruction = 200       # build quality
index.add(embeddings)                 # add vectors

# Search
index.hnsw.efSearch = 64              # search quality
distances, indices = index.search(query_vector, k=10)

# Simpan & load
faiss.write_index(index, "hnsw.index")
index = faiss.read_index("hnsw.index")
```

---

## 3. IVF (Inverted File Index)

### 3.1 Cara Kerja

IVF membagi ruang vektor menjadi **N cluster** (via k-means). Search: cari cluster terdekat → search hanya di dalam cluster itu.

```
Ruang Vektor:
┌──────────┬──────────┬──────────┐
│ Cluster  │ Cluster  │ Cluster  │
│ 0        │ 1        │ 2        │
│ ○ ○ ○    │ ○ ○      │ ○ ○ ○ ○  │
├──────────┼──────────┼──────────┤
│ Cluster  │ ● Query  │ Cluster  │
│ 3        │          │ 4        │
│ ○ ○      │          │ ○ ○      │
├──────────┼──────────┼──────────┤
│ Cluster  │ Cluster  │ Cluster  │
│ 5        │ 6        │ 7        │
│ ○ ○ ○ ○  │ ○ ○ ○    │ ○ ○      │
└──────────┴──────────┴──────────┘
→ Cari cluster terdekat (cluster 3 & 4)
→ Search hanya di cluster 3 & 4
→ Skip cluster 0, 1, 2, 5, 6, 7
```

### 3.2 Parameter

| Parameter                   | Default | Efek                                      |
| --------------------------- | ------- | ----------------------------------------- |
| **nlist** (jumlah cluster)  | 100     | Makin banyak → search cepat, recall turun |
| **nprobe** (cluster dicari) | 1       | Makin banyak → recall naik, search lambat |

---

## 4. Quantization

Quantization = mengurangi presisi angka untuk menghemat memory & mempercepat search.

### 4.1 Scalar Quantization (SQ)

```python
# Float32 → int8 (4x lebih kecil, sedikit akurasi turun)
# SQ: setiap dimensi di-kuantisasi ke 8-bit integer
# Sebelum: 1536 dimensi × 4 byte = 6144 byte per vektor
# Sesudah: 1536 × 1 byte = 1536 byte per vektor (4x lebih kecil)

faiss.IndexScalarQuantizer(d, qtype=faiss.ScalarQuantizer.QT_8bit)
```

### 4.2 Product Quantization (PQ)

PQ memecah vektor jadi **sub-vektor** dan mengkuantisasi MASING-MASING:

```
Vektor 256d: [0.23, -0.45, 0.12, ..., 0.89, -0.33, 0.67]
               ├─────── M=4 sub-vektor ────────┤
               [0.23, ..., 0.12]     [0.89, ..., 0.67]
                     ↓                        ↓
              Code: 42                   Code: 127
                     ↓                        ↓
            PQ code: [42, 127, 8, 95]  (hanya 4 byte!)
```

| PQ Config     | Bitrate    | Compression | Recall @10 |
| ------------- | ---------- | ----------- | ---------- |
| M=8, nbits=8  | 64 bit/dim | 4x          | 95%        |
| M=16, nbits=8 | 32 bit     | 8x          | 92%        |
| M=32, nbits=8 | 16 bit     | 16x         | 87%        |

### 4.3 Binary Quantization

Cohere & Jina support binary embedding: vektor jadi bit (0/1). Satu vektor 1024d = 128 bytes. Search pake Hamming distance (XOR + popcount) — **sangat cepat**, bisa 100x lebih cepat dari cosine.

---

## 5. sqlite-vec Internals

sqlite-vec adalah yang dipake vault-rag. Ini dia cara kerjanya:

### 5.1 Virtual Table vec0

```sql
-- sqlite-vec membuat virtual table dengan kolom:
-- rowid (integer) — implicit
-- embedding (float[N]) — vector column

CREATE VIRTUAL TABLE vec_chunks USING vec0(
    embedding float[256]  -- 256 = dimensi
);
```

Search dengan `MATCH`:

```sql
SELECT rowid, distance FROM vec_chunks
WHERE embedding MATCH ?
ORDER BY distance LIMIT 10;
```

### 5.2 Tentang Index

sqlite-vec **tidak membangun HNSW/IVF**. Search dilakukan dengan **brute force** — membandingkan query dengan semua vektor. Ini OK untuk dataset < 100K vektor.

**Kinerja:**

| Vektor | Latency (256d, brute force) |
| ------ | --------------------------- |
| 1K     | ~1ms                        |
| 10K    | ~5ms                        |
| 100K   | ~50ms                       |
| 1M     | ~500ms                      |

### 5.3 Scaling

Kalo vault-rag > 100K chunks (vault tumbuh), strategi:

1. **sqlite-vec + partial index** — filter dulu pake metadata (tahun, kategori), baru vector search
2. **FAISS HNSW** — export embedding ke FAISS → HNSW search → ambil rowid → JOIN ke SQLite
3. **LanceDB** — vector DB native yang pake SQLite + HNSW built-in

---

## 6. Kapan Pake Apa

| Dataset Size  | Recommended              | Alasan                                               |
| ------------- | ------------------------ | ---------------------------------------------------- |
| < 10K vectors | sqlite-vec (brute force) | Sederhana, zero overhead. **Ini vault-rag sekarang** |
| 10K - 100K    | HNSW via FAISS           | Latency <10ms, akurasi 99%                           |
| 100K - 1M     | IVF+PQ via FAISS         | Memory 4-8x lebih kecil dari HNSW                    |
| > 1M          | HNSW + PQ                | Best trade-off latency/akurasi/memory                |

---

## Koneksi ke Vault

- [[embedding-model-selection-finetuning]] — Dimensi embedding menentukan ukuran & performa index
- [[hybrid-search-vector-keyword]] — Dense index + FTS5 index = dua index berbeda untuk fusion
- [[advanced-chunking-strategies-deepdive]] — Jumlah chunk → performa index
- `../vault-rag/scripts/index_vault.py` — sqlite-vec integration: `CREATE VIRTUAL TABLE vec_chunks`
- `../vault-rag/scripts/query.py` — Cosine search via `WHERE embedding MATCH ?`

---

## References

1. FAISS. _Documentation_. https://faiss.ai/
2. HNSW Paper. _Y. Malkov, D. Yashunin (2016)_. https://arxiv.org/abs/1603.09320
3. sqlite-vec. https://github.com/asg017/sqlite-vec
4. Product Quantization. _H. Jegou et al. (2011)_. https://arxiv.org/abs/1007.1022
5. LanceDB. https://lancedb.github.io/lancedb/
6. Cohere Binary Embeddings. https://txt.cohere.com/introducing-binary-embeddings/

> [!tip] Bottom Line
> Vector database adalah tentang **trade-off**. vault-rag dengan sqlite-vec + brute force sudah cukup untuk dataset sekarang. Monitoring: kalo query latency > 100ms, saatnya pindah ke HNSW. Formula: **(< 50K vektor) → sqlite-vec. (> 50K) → FAISS HNSW. (> 1M) → IVF+PQ.** Jangan optimasi sebelum waktunya — YAGNI.
