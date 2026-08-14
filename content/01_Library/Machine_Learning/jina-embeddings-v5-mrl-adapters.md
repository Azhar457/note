---
tags:
  - machine-learning
  - deep-learning
  - embeddings
  - mrl
  - jina-ai
  - lora
  - rag
aliases:
  - Jina Embeddings v5 MRL Adapters
  - Jina Embeddings v5
  - Matryoshka Representation Learning
status: pending
created: 2026-07-21
updated: 2026-07-21
cssclasses:
  - wide-table
  - callout

---

# Jina Embeddings v5: Matryoshka Representation Learning & Task-Specific LoRA Adapters

> [!tip] Jina Embeddings v5 adalah model *frontier embedding* berbasis arsitektur LLM modern (Qwen3/DeepSeek backbone) dengan **32,768 token context window**. Model ini mengintegrasikan **Matryoshka Representation Learning (MRL)** untuk fleksibilitas dimensi vektor (1024 ke 512, 256, atau 128 dimensi tanpa kehilangan performa berarti) serta **LoRA Task Adapters** yang dioptimalkan untuk skenario *Retrieval*, *Code Search*, dan *Text Classification*.

---

## 1. Konsep Dasar & Evolusi Generasi Embedding Models

Perkembangan arsitektur *text embeddings* telah melewati tiga tahapan generasi utama:

```
  [ Gen 1: Fixed Small Models ]        [ Gen 2: BERT / Transformer Base ]      [ Gen 3: MRL + LLM Backbone (Jina v5) ]
   Word2Vec, GloVe (512 token)     ──>  BERT, RoBERTa (512 token)         ──>  LLM Backbone + MRL + LoRA Adapters
   Single static vector per word        Bi-Encoder fixed 768-dim vector        Flexible Dim (1024 -> 128) + 32K Context
```

### Masalah pada Vector Embedding Konvensional
1. **Fixed Dimension Rigidity**: Model konvensional memaksa ukuran vektor tetap (misal: 1536-dim pada OpenAI `text-embedding-ada-002`). Hal ini menyebabkan **pemborosan memori RAM & storage RAM/Disk 4x–8x lebih tinggi** pada indeks skala jutaan vektor.
2. **One-Size-Fits-All Failure**: Penggunaan matriks pembobotan yang sama untuk tugas yang berbeda (*Symmetric Query-Passage*, *Asymmetric Code Search*, *Short Fact Retrieval*) menghasilkan performa kompromis.
3. **Context Length Truncation**: Batasan 512 token pada model berbasis BERT memotong dokumen panjang dan kehilangan konteks menyeluruh.

---

## 2. Teori Matematika: Matryoshka Representation Learning (MRL)

Nama **Matryoshka** diambil dari boneka kayu Rusia yang bersarang di dalam satu sama lain. Dalam konteks machine learning, MRL melatih vektor embedding sehingga **sub-dimensi awal (misal: 128 dimensi pertama) sudah mengandung informasi paling padat dan paling kritis dari keseluruhan vektor (1024 dimensi)**.

```
Full Vector (1024 Dimensi): [ d1, d2, d3, d4, ..., d128 | d129, ..., d256 | d257, ..., d512 | d513, ..., d1024 ]
                           └─────────────┬─────────────┘
                                         ▼
                                 Slice 128-dimensi 
                         (Sudah 90%+ akurasi retrieval!)
```

### Formulasi Matematika Loss MRL

Secara konvensional, model Bi-Encoder dilatih menggunakan **InfoNCE Loss** (Contrastive Loss) pada dimensi penuh $D$:

$$\mathcal{L}_{\text{InfoNCE}}(z_q, z_p^+) = -\log \frac{\exp\left( \text{sim}(z_q, z_p^+) / \tau \right)}{\exp\left( \text{sim}(z_q, z_p^+) / \tau \right) + \sum_{j} \exp\left( \text{sim}(z_q, z_{p,j}^-) / \tau \right)}$$

Di mana $z_q$ adalah embedding query, $z_p^+$ adalah passage positif, $z_{p,j}^-$ adalah passage negatif, dan $\tau$ adalah temperature hyperparameter.

Pada Matryoshka Representation Learning, kita mendefinisikan sekelompok dimensi pemotongan $\mathcal{M} = \{d_1, d_2, \dots, d_K\}$ (misal: $\mathcal{M} = \{128, 256, 512, 1024\}$).

Untuk setiap dimensi $m \in \mathcal{M}$, kita mengambil slice vektor $z^{(m)} = z_{[:m]}$ dan melakukan normalisasi $\ell_2$:

$$\hat{z}^{(m)} = \frac{z_{[:m]}}{\|z_{[:m]}\|_2}$$

Loss total MRL adalah **penjumlahan terbobot dari InfoNCE Loss pada setiap slice dimensi**:

$$\mathcal{L}_{\text{MRL}} = \sum_{m \in \mathcal{M}} w_m \cdot \mathcal{L}_{\text{InfoNCE}}\left( \hat{z}_q^{(m)}, \hat{z}_p^{+(m)} \right)$$

Dengan meminimalkan $\mathcal{L}_{\text{MRL}}$, gradient backpropagation memaksa model untuk memusatkan informasi semantik paling dominan pada indeks dimensi yang lebih kecil ($1 \dots m$).

---

## 3. Arsitektur Task-Specific LoRA Adapters

Jina Embeddings v5 tidak hanya menggunakan satu set bobot statis, melainkan menggabungkan **Low-Rank Adaptation (LoRA)** yang dapat beralih tergantung jenis tugas (*task instruction*).

```
                            ┌─────────────────────────────────┐
                            │   Base LLM Backbone (Qwen3)     │
                            └────────────────┬────────────────┘
                                             │
               ┌─────────────────────────────┼─────────────────────────────┐
               ▼                             ▼                             ▼
    [ Adapter: retrieval.query ]  [ Adapter: retrieval.passage ]  [ Adapter: code.search ]
       (Symmetric / Dense)          (Asymmetric Document)           (Code & AST Signatures)
```

### Konsep LoRA pada Embedding Layer
Untuk matriks bobot dasar $W_0 \in \mathbb{R}^{d \times k}$, LoRA membekukan $W_0$ dan menambahkan pembaruan berpangkat rendah (*low-rank decomposition*):

$$W = W_0 + \Delta W = W_0 + B \cdot A$$

Di mana $B \in \mathbb{R}^{d \times r}$ dan $A \in \mathbb{R}^{r \times k}$ dengan rank $r \ll \min(d, k)$.

### 4 Mode Adaptasi Utama pada Jina v5
1. `retrieval.query`: Mengadaptasi vektor query pencarian pendek untuk mencocokkan dokumen panjang secara asimetris.
2. `retrieval.passage`: Mengadaptasi enkoding dokumen/passage agar optimal disandingkan dengan `retrieval.query`.
3. `separation` / `classification`: Dioptimalkan untuk mengelompokkan teks (*clustering*) atau pemisahan kelas (*linear probing*).
4. `code.search`: Dioptimalkan khusus untuk mencocokkan kueri bahasa alami (*natural language*) dengan sintaksis kode (*AST & function signatures*).

---

## 4. Perbandingan Performa & Truncation Efficiency

Grafik efisiensi retensi akurasi MRL pada Jina Embeddings v5:

| Dimensi Vektor ($m$) | Memory Footprint (per 1M Vectors) | Retensi Akurasi Retrieval (MTEB) | Kecepatan Simd Cosine |
|---|---|---|---|
| **1024 Dim (Full)** | **4.09 GB** | **100.0%** (Baseline SOTA) | 1.0x |
| **512 Dim** | **2.04 GB** (Hemat 50%) | **99.2%** | 1.9x |
| **256 Dim** | **1.02 GB** (Hemat 75%) | **97.6%** | 3.6x |
| **128 Dim** | **0.51 GB** (Hemat 87.5%) | **94.1%** | 6.8x |

> [!important] Dengan memangkas dimensi dari 1024 ke 512 dimensi, kita menghemat 50% penggunaan RAM dan kapasitas penyimpanan SQLite `sqlite-vec` atau PostgreSQL `pgvector`, dengan penurunan akurasi kurang dari 1%!

---

## 5. Implementasi Kode & REST API 9Router

### A. Penganggilan API via 9Router (Pilihan Dimensi 1024 / 512)

```bash
curl -X POST http://localhost:20128/v1/embeddings \
  -H "Authorization: Bearer YOUR_NINEROUTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "jina/jina-embeddings-v5-text-small",
    "input": [
      "Teknologi eBPF memungkinkan eksekusi sandboxed program di kernel Linux.",
      "Backpropagation menghitung gradien loss menggunakan aturan rantai."
    ],
    "dimensions": 512
  }'
```

### B. Integrasi Python SQLite `sqlite-vec` Storage

```python
import sqlite3
import sqlite_vec
import requests
import json

def get_jina_v5_embedding(text: str, dimensions: int = 512) -> list[float]:
    url = "http://localhost:20128/v1/embeddings"
    headers = {"Content-Type": "application/json"}
    payload = {
        "model": "jina/jina-embeddings-v5-text-small",
        "input": text,
        "dimensions": dimensions
    }
    resp = requests.post(url, headers=headers, json=payload)
    resp.raise_for_status()
    return resp.json()["data"][0]["embedding"]

# Inisialisasi Database SQLite-Vec
db = sqlite3.connect("vault_mrl.db")
db.enable_load_extension(True)
sqlite_vec.load(db)

# Buat tabel dengan dimensi MRL 512
db.execute("""
CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0(
    embedding float[512]
);
""")

# Simpan Vektor 512-dim
sample_text = "Jina v5 menggunakan Matryoshka Representation Learning untuk efisiensi penyimpanan."
vec = get_jina_v5_embedding(sample_text, dimensions=512)

db.execute("INSERT INTO vec_chunks(rowid, embedding) VALUES (?, ?)", (1, json.dumps(vec)))
db.commit()
print("✓ Berhasil menyimpan MRL 512-dim vector ke SQLite-Vec!")
```

---

## 6. Matrix Perbandingan Embedding Models

| Model | Dimensions | Context Window | Support MRL | Task Adapters | SOTA Score (MTEB) |
|---|---|---|---|---|---|
| **Jina Embeddings v5 Text Small** 👑 | **128 – 1024** | **32,768** | **Ya** | **Ya (LoRA)** | **SOTA (High)** |
| OpenAI `text-embedding-3-small` | 512 – 1536 | 8,191 | Ya | Tidak | High |
| BGE-M3 | 1024 | 8,192 | Tidak | Tidak | High |
| Qwen3-Embedding-8B | 4096 | 32,768 | Tidak | Tidak | SOTA (Very High) |
| Voyage-3 | 1024 | 32,768 | Tidak | Tidak | High |

---

## 🔗 Referensi & Catatan Terkait
- [[jina-reranker-v3-deepdive]] — Reranking Listwise Cross-Encoder untuk Precision Filtering
- [[semantic-search-pipeline]] — Arsitektur Pipeline Pencarian Semantik
- [[cosine-similarity-deepdive]] — Kalkulasi Jarak Vektor dan Metric Distance
- [[backpropagation-deepdive]] — Dasar Algoritma Backpropagation & Contrastive Loss