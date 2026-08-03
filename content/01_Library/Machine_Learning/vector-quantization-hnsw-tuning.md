---
tags:
  - machine-learning
  - vector-database
  - quantization
  - hnsw
  - semantic-search
  - rag
aliases:
  - Vector Quantization and HNSW Tuning
  - HNSW Parameters
  - Vector Compression
status: pending
created: 2026-07-21
updated: 2026-07-21
---

# Vector Quantization & HNSW Tuning: Kompresi Representasi Vektor dan Akselerasi Index RAG

> [!tip] **Vector Quantization (VQ)** adalah teknik kompresi ruang vektor berkelanjutan ($\mathbb{R}^d$) menjadi representasi diskrit berukuran kecil guna mereduksi memori RAM hingga 90% pada database vektor. Penggabungan VQ dengan indeks **Hierarchical Navigable Small World (HNSW)** mempercepat latensi pencarian pencarian terdekat (*Approximate Nearest Neighbor*) ke tingkat sub-10 milidetik pada miliaran dokumen.

---

## 1. Problem Statement: Memori RAM & Bottleneck Database Vektor

Pada pencarian semantik skala industri, jutaan chunk teks diwakili oleh vektor *high-dimensional* (misal: 1024-dimensi bertipe `float32`).

### Tantangan Konsumsi Memori RAM
Setiap bilangan `float32` membutuhkan **4 byte** memori. 
Maka untuk menyimpan 1 juta vektor berukuran 1024 dimensi:

$$\text{Memori} = 1,000,000 \times 1024 \times 4 \text{ bytes} \approx 4.09 \text{ GB}$$

Ini baru ukuran mentah representasi vektor, belum termasuk struktur graf indeks pencarian HNSW yang membutuhkan tambahan $\approx 1.5\times - 2\times$ kapasitas RAM untuk pointer antar-simpul graf.
Ketika database membengkak hingga puluhan juta vektor, biaya infrastruktur RAM menjadi sangat mahal.

### Tantangan Latensi I/O
Pencarian brute-force (K-NN) membandingkan query terhadap setiap vektor di database dengan menghitung jarak Euclidean atau Cosine. Pada jutaan data, operasi perkalian matriks ini memicu bottleneck pada CPU/GPU dan bus memori.

---

## 2. Taksonomi Kompresi Vektor (Vector Quantization)

Untuk mengatasi konsumsi RAM, database vektor menerapkan kompresi melalui **Quantization** (mengubah angka desimal presisi tinggi `float32` menjadi angka integer presisi rendah `int8` atau klaster kode biner).

```
   Raw Vector (1024x float32) ───[ Scalar Quantization (SQ8) ]───> Compact Vector (1024x int8) - RAM Hemat 75%
   
   Raw Vector (1024x float32) ───[ Product Quantization (PQ) ]────> Array Sub-vectors (Centroids Index) - RAM Hemat 90%+
```

### A. Scalar Quantization (SQ8)
SQ mengompresi setiap koordinat vektor secara independen dari `float32` ke `int8` ($8\text{-bit}$).
*   **Mekanisme**: Menghitung rentang minimum ($min$) dan maksimum ($max$) nilai koordinat pada seluruh dataset, lalu membagi rentang tersebut ke dalam 256 tingkatan ($2^8$ untuk $8\text{-bit}$ integer).
*   **Formula Kuantisasi**:

    $$q = \text{round}\left( 255 \times \frac{x - min}{max - min} \right)$$

*   **Rasio Kompresi**: **$4\times$ hemat RAM** (dari 4 byte menjadi 1 byte per dimensi). Kehilangan akurasi retensi sangat minim ($\approx 0.5\% - 1\%$).

### B. Product Quantization (PQ)
PQ membagi vektor berdimensi $D$ menjadi $M$ sub-vektor yang lebih kecil, lalu mengelompokkan setiap sub-vektor ke dalam cluster centroid.

```
Vektor Asli (D = 8):    [ 0.12,  0.89, -0.45,  0.67,  0.11, -0.09,  0.88, -0.12 ]
                        └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
Sub-vektor (M = 4):        Sub1        Sub2        Sub3        Sub4
Centroid ID terdekat:      #21         #104        #2          #89
```

*   **Mekanisme**:
    1.  Vektor dimensi $D$ dipotong menjadi $M$ bagian (di mana $d = D/M$ adalah dimensi sub-vektor).
    2.  Lakukan algoritma *k-means clustering* pada seluruh dataset sub-vektor untuk menghasilkan $K^*$ centroids (biasanya $K^* = 256$, sehingga tiap centroid dapat diwakili oleh 1 byte `uint8`).
    3.  Setiap vektor asli kini hanya disimpan sebagai barisan ID indeks centroid berukuran $M$-byte.
*   **Rasio Kompresi**: **$10\times - 20\times$ hemat RAM** (vektor 1024-dimensi dapat direpresentasikan hanya dengan $M=64$ atau $M=32$ byte).
*   **Efek Samping**: Penurunan akurasi pencarian $\approx 3\% - 8\%$ karena kesalahan kuantisasi (*quantization noise*).

---

## 3. Optimasi Indeks HNSW (Hierarchical Navigable Small World)

HNSW adalah algoritma graf terstruktur berlapis (*Hierarchical Graph*) yang terinspirasi dari struktur *skip list*.

```
Lapisan 2 (Sparse)      NodeA ───────────────────────────────> NodeD
                         │                                     │
Lapisan 1 (Medium)      NodeA ─────────> NodeB ──────────────> NodeD ──────────> NodeF
                         │               │                     │                │
Lapisan 0 (Dense)       NodeA ──> NodeC ──> NodeB ──> NodeE ──> NodeD ──> NodeG ──> NodeF
```

### Parameter Kunci HNSW & Cara Tuning
Untuk mendapatkan hasil optimal pada RAG pipeline, Anda harus menyeimbangkan performa pencarian (*Recall*) versus latensi pembuatan indeks (*Build Time*) menggunakan tiga parameter utama HNSW:

#### 1. $M$ (Maximum Connections per Node)
*   **Definisi**: Jumlah tautan bidirectional maksimum yang dimiliki oleh setiap simpul dalam graf pada Lapisan 0.
*   **Dampak**:
    *   $M$ kecil ($8 - 16$): Menghemat penggunaan memori RAM, mempercepat pencarian, tetapi menurunkan akurasi pencarian (*Recall*) pada dataset dengan variasi tinggi.
    *   $M$ besar ($32 - 64$): Meningkatkan akurasi pencarian kueri kompleks, namun memperlambat waktu indeksasi dan memakan lebih banyak RAM.
*   **Rekomendasi RAG**: Gunakan $M = 16$ untuk teks dokumen standar, dan $M = 32$ atau $M = 64$ untuk pencarian repositori kode (*codebase search*).

#### 2. `efConstruction` (Exploration Depth during Index Build)
*   **Definisi**: Menentukan ukuran antrian dinamis (*dynamic candidate list*) untuk mengevaluasi titik terdekat saat membangun graf indeks baru.
*   **Dampak**:
    *   `efConstruction` besar ($200 - 400$): Memperlama waktu indeksasi awal, tetapi menghasilkan kualitas graf yang optimal (tetap presisi saat pencarian).
    *   **Penting**: Nilai ini tidak berdampak pada latensi query real-time, hanya pada waktu insersi awal.

#### 3. `efSearch` (Exploration Depth during Query Search)
*   **Definisi**: Ukuran antrian dinamis untuk mengevaluasi titik terdekat selama proses kueri berjalan pada Layer 0.
*   **Dampak**:
    *   `efSearch` kecil ($32 - 64$): Latensi sangat cepat ($< 5\text{ ms}$), tetapi ada risiko melewatkan tetangga terdekat yang sebenarnya (*recall drop*).
    *   `efSearch` besar ($128 - 256$): Meningkatkan akurasi retensi pencarian hingga mendekati 100% brute-force, tetapi waktu kueri meningkat secara logaritmik.
*   **Rekomendasi RAG**: Pasang `efSearch = 128` untuk pencarian kueri presisi tinggi.

---

## 4. Implementasi Tuning HNSW di Database (Vector DB Codes)

### A. Tuning Parameter HNSW di pgvector (PostgreSQL)

```sql
-- Buat indeks HNSW pada kolom embedding dengan dimensi 1024 (Jina v5)
-- Menggunakan operator cosine_ops, M=16, ef_construction=128
CREATE INDEX ON vault_chunks USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 128);

-- Sebelum melakukan query pencarian, atur parameter ef_search
-- Menyetel kedalaman eksplorasi pencarian ke tingkat presisi tinggi
SET hnsw.ef_search = 128;

-- Lakukan K-NN Query Semantik
SELECT id, text, 1 - (embedding <=> $1) AS similarity
FROM vault_chunks
ORDER BY embedding <=> $1
LIMIT 5;
```

### B. Konfigurasi Quantization di SQLite `sqlite-vec` (Python)

```python
import sqlite3
import sqlite_vec
import json

db = sqlite3.connect(":memory:")
db.enable_load_extension(True)
sqlite_vec.load(db)

# sqlite-vec mendukung kompresi bit-level (int8) melalui type casting
# Vektor 512 dimensi bertipe int8 dikonfigurasi menggunakan bitwise virtual table
db.execute("""
CREATE VIRTUAL TABLE vec_index USING vec0(
    embedding float[512]
);
""")

# Input query dengan normalisasi L2 vector sebelum insersi 
# guna mengoptimalkan jarak Cosine ke Dot Product (kecepatan pencarian maksimum)
```

---

## 🔗 Referensi & Catatan Terkait
- [[jina-embeddings-v5-mrl-adapters]] — Embeddings Vector dengan MRL
- [[jina-reranker-v3-deepdive]] — Reranker Listwise Cross-Encoder untuk Precision Filtering
- [[cosine-similarity-deepdive]] — Jarak Euclidean vs Cosine Similarity
- [[model-context-protocol-specification]] — Spesifikasi Komunikasi Host Agent ke MCP DB Server
