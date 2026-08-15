---
title: Vector Similarity Learning Roadmap — Cosine, Euclidean, and Dot Product Search
  Engine
tags:
- machine-learning
- vector-search
- mathematics
- numpy
- roadmap
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Mengukur kesamaan antar-vektor adalah operasi paling mendasar di dalam sistem pencarian semantik (RAG) dan LLM. Catatan ini menyediakan peta jalan belajar dari implementasi matematika dasar hingga pembuatan sistem pencarian kustom, menjadi pasangan praktis dari berkas teoritis [[cosine-similarity-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Fondasi Matematika Vektor & Perkalian Titik](#2-fase-1-fondasi-matematika-vektor--perkalian-titik)
3. [Fase 2: Menulis Fungsi Kesamaan Kustom di Python & NumPy](#3-fase-2-menulis-fungsi-kesamaan-kustom-di-python--numpy)
4. [Fase 3: Mengapa Sudut Lebih Penting daripada Magnitudo](#4-fase-3-mengapa-sudut-lebih-penting-daripada-magnitudo)
5. [Fase 4: Membangun Sistem Pencarian Dokumen (Vector Search Engine)](#5-fase-4-membangun-sistem-pencarian-dokumen-vector-search-engine)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini menuntun Anda dari aljabar linier dasar hingga mesin pencari semantik:

```
[Fase 1: Aljabar Linier] ──> [Fase 2: Custom Similarity] ──> [Fase 3: Geometri Vektor] ──> [Fase 4: Vector Search]
- Vektor & Magnitudo         - Pure Python Sim               - Efek Normalisasi          - KNN Search Engine
- Perkalian Dot Product      - NumPy Vectorization           - Cosine vs Euclidean       - FAISS comparison
```

---

## 2. Fase 1: Fondasi Matematika Vektor & Perkalian Titik

Diberikan dua vektor $A$ dan $B$ berdimensi $n$:
$$A = [a_1, a_2, \dots, a_n], \quad B = [b_1, b_2, \dots, b_n]$$

- **Dot Product (Perkalian Titik)**:
  $$A \cdot B = \sum_{i=1}^{n} a_i b_i$$
- **Magnitudo Vektor (L2 Norm)**:
  $$\|A\| = \sqrt{\sum_{i=1}^{n} a_i^2}$$
- **Cosine Similarity**:
  $$\text{Cosine Sim}(A, B) = \cos(\theta) = \frac{A \cdot B}{\|A\| \|B\|}$$

Nilai Cosine Similarity berkisar antara $[-1, 1]$. Untuk representasi teks (embedding), nilainya biasanya berada di rentang $[0, 1]$ karena bobot fitur bernilai non-negatif.

---

## 3. Fase 2: Menulis Fungsi Kesamaan Kustom di Python & NumPy

### 3.1 Implementasi Pure Python (Tanpa Pustaka Eksternal)
Berguna untuk memahami logika kalkulasi di balik abstraksi library:
```python
import math

def dot_product(a, b):
    return sum(x * y for x, y in zip(a, b))

def magnitude(a):
    return math.sqrt(sum(x * x for x in a))

def custom_cosine_similarity(a, b):
    mag_a = magnitude(a)
    mag_b = magnitude(b)
    if mag_a == 0 or mag_b == 0:
        return 0.0
    return dot_product(a, b) / (mag_a * mag_b)
```

### 3.2 Implementasi NumPy (Vektorisasi SIMD)
NumPy mempercepat komputasi dengan memanggil instruksi paralel prosesor:
```python
import numpy as np

def numpy_cosine_similarity(a, b):
    # a, b: numpy arrays
    dot = np.dot(a, b)
    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)
```

---

## 4. Fase 3: Mengapa Sudut Lebih Penting daripada Magnitudo

Pertimbangkan masalah **Pencarian Teks**:
- Dokumen 1: *"keamanan siber"* (panjang: 2 kata).
- Dokumen 2: *"keamanan siber keamanan siber keamanan siber"* (panjang: 6 kata).

Kedua dokumen memiliki fokus topik yang sama persis.
- **Euclidean Distance**: Akan menilai kedua dokumen sangat **berjauhan** (karena Dokumen 2 memiliki magnitudo frekuensi kata yang jauh lebih besar).
- **Cosine Similarity**: Menghasilkan nilai **1.0** (kesamaan sempurna) karena arah sudut vektornya sejajar, mengabaikan perbedaan panjang dokumen (*invarian terhadap panjang teks*).

---

## 5. Fase 4: Membangun Sistem Pencarian Dokumen (Vector Search Engine)

Berikut adalah implementasi sistem K-Nearest Neighbors (KNN) kustom untuk mencari dokumen berdasarkan nilai kesamaan kosinus terdekat.

```python
import numpy as np

class VectorSearchEngine:
    def __init__(self, dimension):
        self.dimension = dimension
        self.database = [] # Menyimpan data dokumen teks
        self.vectors = None # Menyimpan matriks embedding (N x D)

    def add_document(self, doc_text, vector):
        assert len(vector) == self.dimension, "Dimensi vektor tidak cocok"
        self.database.append(doc_text)
        
        # Normalisasi vektor terlebih dahulu (L2 normalize)
        normalized_vector = vector / np.linalg.norm(vector)
        
        if self.vectors is None:
            self.vectors = np.array([normalized_vector])
        else:
            self.vectors = np.vstack([self.vectors, normalized_vector])

    def search(self, query_vector, k=3):
        if self.vectors is None:
            return []
            
        # 1. Normalisasi kueri input
        q_norm = query_vector / np.linalg.norm(query_vector)
        
        # 2. Karena data di DB sudah ternormalisasi, Cosine Sim cukup dihitung dengan Dot Product perkalian matriks!
        # Rumus: Scores (N x 1) = Vectors (N x D) * Q_norm (D x 1)
        scores = np.dot(self.vectors, q_norm)
        
        # 3. Urutkan dari nilai tertinggi ke terendah
        top_indices = np.argsort(scores)[::-1][:k]
        
        results = []
        for idx in top_indices:
            results.append({
                "document": self.database[idx],
                "score": float(scores[idx])
            })
        return results
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Diberikan tiga vektor berikut:
- Kueri $Q = [1.0, 0.0]$
- Dokumen $A = [1.0, 1.0]$
- Dokumen $B = [0.0, 5.0]$
Hitunglah:
1. Cosine similarity antara $Q$ dengan $A$ dan $B$.
2. Euclidean distance antara $Q$ dengan $A$ dan $B$.
3. Berdasarkan hasil di atas, dokumen mana yang lebih dekat dengan kueri jika menggunakan Cosine vs Euclidean?

**Solusi**

Kalkulasi Cosine Similarity:
- $\text{Cos}(Q, A) = \frac{1(1) + 0(1)}{\sqrt{1}\sqrt{2}} = \frac{1}{\sqrt{2}} \approx 0.707$
- $\text{Cos}(Q, B) = \frac{1(0) + 0(5)}{\sqrt{1}\sqrt{25}} = 0.0$
- *Hasil Cosine*: Dokumen A lebih mirip dengan Q daripada Dokumen B.

Kalkulasi Euclidean Distance:
- $\text{Dist}(Q, A) = \sqrt{(1-1)^2 + (0-1)^2} = \sqrt{1} = 1.0$
- $\text{Dist}(Q, B) = \sqrt{(1-0)^2 + (0-5)^2} = \sqrt{1 + 25} = \sqrt{26} \approx 5.099$
- *Hasil Euclidean*: Dokumen A lebih dekat dengan Q daripada Dokumen B.

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[cosine-similarity-deepdive]] | Teori dasar, pembuktian matematis formula kosinus, dan analisis performa. |
| [[cosine-vs-euclidean-vs-dot]] | Perbandingan komprehensif metrik jarak untuk sistem RAG. |
| [[embedding-model-selection-finetuning]] | Pemilihan model penghasil vektor representasi (embedding) untuk pencarian semantik. |
---

audited
---
