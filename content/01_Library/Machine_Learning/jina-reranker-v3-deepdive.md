---
tags:
  - machine-learning
  - deep-learning
  - rag
  - reranking
  - jina-ai
  - cross-encoder
aliases:
  - Jina Reranker v3 Deepdive
  - Jina Reranker v3
  - Listwise Reranker
status: pending
created: 2026-07-21
updated: 2026-07-21
---

# Jina Reranker v3: Arsitektur Listwise Cross-Encoder untuk Precision-Critical RAG Pipeline

> [!tip] Jina Reranker v3 adalah model **Listwise Cross-Encoder SOTA** yang dirancang untuk mengatasi kelemahan mendasar Bi-Encoder Embedding dalam RAG pipeline. Dengan context window hingga **131,072 token**, dukungan multibahasa (termasuk Bahasa Indonesia), pencarian kode (_code search_), serta _task-specific adapters_, model ini memangkas noise kandidat retrieval hingga 90% sebelum diumpankan ke LLM.

---

## 1. Problem Statement: Kelemahan Two-Stage Retrieval & Bi-Encoder Limit

Dalam arsitektur Retrieval-Augmented Generation (RAG) modern, _retrieval stage_ biasanya dibagi menjadi dua fase:

```
[ Full Knowledge Base / Corpus ]
               │
               ▼  (Stage 1: High Recall, Low Precision)
    ┌──────────────────────┐
    │  Bi-Encoder Vector / │ ──> Mengambil 40 - 100 kandidat chunk
    │     BM25 Hybrid      │
    └──────────┬───────────┘
               │
               ▼  (Stage 2: High Precision, Re-ordering)
    ┌──────────────────────┐
    │  Listwise Cross-     │ ──> Menyaring menjadi Top 3 - 5 chunk
    │  Encoder Reranker    │     paling relevan secara presisi
    └──────────┬───────────┘
               │
               ▼
    [ LLM Context Window ]
```

### Kelemahan Bi-Encoder (Dense Retrieval)

1. **Independent Embedding Constraint**: Bi-Encoder mengompresi query $q$ dan dokumen $d$ secara terpisah menjadi vektor tunggal ($v_q, v_d \in \mathbb{R}^D$). Tidak ada _cross-attention_ antara token query dan token dokumen selama proses encoding.
2. **Semantic Blurring & Jargon Failure**: Istilah spesifik seperti kode error (`E4021`), identifier API, atau klausa hukum sering kali terdistorsi saat dipetakan ke dalam ruang vektor kontinu.
3. **Loss of Fine-Grained Interaction**: Informasi posisi dan asosiasi kata tingkat token hilang saat disederhanakan menjadi satu operasi Cosine Similarity $S(q, d) = \frac{v_q \cdot v_d}{\|v_q\| \|v_d\|}$.

### Fenomena "Lost in the Middle" & Context Contamination

Ketika 20+ chunk mentah langsung dimasukkan ke LLM tanpa reranking:

- **Attention Degradation**: LLM cenderung mengabaikan informasi yang terletak di tengah-tengah context window (_Lost in the Middle_ phenomenon).
- **Hallucination Risk**: Chunk yang sedikit relevan tetapi memuat kata kunci mirip dapat mengontaminasi penalaran LLM, memicu halusinasi.

---

## 2. Taksonomi Arsitektur Reranking

Untuk memahami keunggulan Jina Reranker v3, kita harus membandingkan 4 paradigma arsitektur reranking:

```
  (A) Bi-Encoder         (B) Pointwise Cross-Encoder    (C) Pairwise Cross-Encoder     (D) Listwise Cross-Encoder
     [Query] [Doc]              [Query + Doc]                [Query + DocA vs DocB]           [Query + List[Doc1..N]]
        │       │                      │                               │                                 │
     [Enc]   [Enc]                 [Cross-Attn]                    [Cross-Attn]                      [Listwise Attn]
        │       │                      │                               │                                 │
     (Vector Dot)             (Score P(Relevance))               (Binary Preference)              (Sorted Permutation)
```

### A. Bi-Encoder (Vector Similarity)

- **Komputasi**: $O(1)$ saat query time (menggunakan indeks ANN seperti HNSW).
- **Kelemahan**: Akurasi terendah untuk kueri kompleks karena tidak ada _joint attention_.

### B. Pointwise Cross-Encoder

- **Komputasi**: $O(N)$ di mana $N$ adalah jumlah kandidat dokumen.
- **Mekanisme**: Menggabungkan query dan dokumen tunggal $[ \text{CLS} ] + q + [ \text{SEP} ] + d$, lalu menghitung skor independen $S(q, d) \in [0, 1]$.
- **Kelemahan**: Menilai setiap dokumen secara terisolasi tanpa melihat kandidat dokumen lain sebagai pembanding relatif.

### C. Pairwise Cross-Encoder

- **Komputasi**: $O(N^2)$ pasangan dokumen.
- **Mekanisme**: Membandingkan pasangan dokumen $(d_i, d_j)$ terhadap query $q$ untuk menentukan mana yang lebih relevan.
- **Kelemahan**: Skalabilitas buruk jika $N > 20$ karena ledakan kombinatorial.

### D. Listwise Cross-Encoder (Jina Reranker v3)

- **Komputasi**: $O(N)$ dengan pengolahan konkurensi daftar sekaligus.
- **Mekanisme**: Memproses query $q$ bersamaan dengan seluruh daftar kandidat $[d_1, d_2, \dots, d_N]$ dalam satu _pass_ perhatian (_joint listwise attention_).
- **Keunggulan**: Memungkinkan model membandingkan tingkat relevansi antar-dokumen secara relatif (_global context ranking_), menghasilkan urutan peringkat yang jauh lebih konsisten.

---

## 3. Formulasi Matematika & Objective Loss Function

### A. Joint Cross-Attention Matrix

Diberikan sequence token query $Q = (q_1, q_2, \dots, q_m)$ dan token dokumen $D = (d_1, d_2, \dots, d_n)$, representasi gabungan $X = [Q; D]$ diumpankan ke dalam transformer layers.

Matriks Atensi Multi-Head dihitung dengan:

$$\text{Attention}(K, Q, V) = \text{softmax}\left( \frac{QK^T}{\sqrt{d_k}} \right) V$$

Di mana token-token query $q_i$ dapat beratensi langsung ke setiap token dokumen $d_j$ pada seluruh _hidden layers_, memungkinkan ekstraksi hubungan semantik tingkat rendah (_fine-grained token interaction_).

### B. Listwise Ranking Loss (Plackett-Luce Model)

Jina Reranker v3 menggunakan variasi dari **ListNet Loss** yang berbasis pada distribusi probabilitas Plackett-Luce. Diberikan ground-truth relevance scores $y = (y_1, y_2, \dots, y_N)$ dan skor prediksi model $s = (s_1, s_2, \dots, s_N)$:

Probabilitas softmax dari dokumen $d_i$ menduduki peringkat teratas didefinisikan sebagai:

$$P_s(d_i) = \frac{\exp(s_i)}{\sum_{j=1}^N \exp(s_j)}$$

$$P_y(d_i) = \frac{\exp(y_i)}{\sum_{j=1}^N \exp(y_j)}$$

Loss fungsi Listwise Cross-Entropy dihitung dengan Kullback-Leibler (KL) Divergence antara distribusi ground-truth dan prediksi:

$$\mathcal{L}_{\text{Listwise}} = -\sum_{i=1}^N P_y(d_i) \log \left( P_s(d_i) \right)$$

Fungsi rugi ini memaksa model untuk memprioritaskan perbedaan skor antara dokumen teratas (_top ranks_) daripada mencemaskan dokumen berkategori skor rendah di papan bawah.

### C. Metrik Evaluasi: NDCG@K & MRR

Efektivitas reranking diukur menggunakan **Normalized Discounted Cumulative Gain (NDCG@K)**:

$$\text{DCG}@K = \sum_{i=1}^K \frac{2^{y_i} - 1}{\log_2(i + 1)}$$

$$\text{NDCG}@K = \frac{\text{DCG}@K}{\text{IDCG}@K}$$

Di mana $\text{IDCG}@K$ adalah skor Ideal DCG yang diurutkan secara sempurna.

---

## 4. Fitur Utama & Spesifikasi Teknis Jina Reranker v3

| Parameter / Fitur        | Spesifikasi Jina Reranker v3                                                   |
| ------------------------ | ------------------------------------------------------------------------------ |
| **Context Window**       | **131,072 Tokens** (131K)                                                      |
| **Parameter Count**      | 597 Million (597M)                                                             |
| **Output Type**          | Relevance Scores ($[0.0, 1.0]$ / Logits) & Sorted Ranks                        |
| **Multilingual Support** | 100+ Bahasa (Termasuk Indonesia, Jawa, Sunda, Inggris, Mandarin, Jerman, dll.) |
| **Domain Adaptation**    | Task Adapters untuk _Code Search_, _QA_, _Retrieval_, _Fact-Checking_          |
| **Latency Benchmark**    | $\approx 25 - 45\text{ ms}$ per 30 kandidat chunks                             |
| **API Endpoint**         | `POST https://api.jina.ai/v1/rerank` atau via 9Router Gateway                  |

---

## 5. Implementasi Kode & Integrasi Pipeline

### A. Penganggilan Langsung via REST API (cURL)

```bash
curl -X POST https://api.jina.ai/v1/rerank \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JINA_API_KEY" \
  -d '{
    "model": "jina-reranker-v3",
    "query": "Bagaimana arsitektur RRF menggabungkan skor BM25 dan Dense Vector?",
    "top_n": 3,
    "documents": [
      "BM25 menggunakan frekuensi term terbobot dengan length normalization untuk pencarian leksikal.",
      "Reciprocal Rank Fusion (RRF) menjumlahkan kebalikan dari posisi ranking dokumen dari beberapa metode pencarian.",
      "Vector embeddings memetakan teks ke dalam ruang kontinu high dimensional."
    ],
    "return_documents": true
  }'
```

#### Sample Response JSON:

```json
{
  "model": "jina-reranker-v3",
  "object": "list",
  "usage": {
    "total_tokens": 142
  },
  "results": [
    {
      "index": 1,
      "relevance_score": 0.9421,
      "document": {
        "text": "Reciprocal Rank Fusion (RRF) menjumlahkan kebalikan dari posisi ranking dokumen dari beberapa metode pencarian."
      }
    },
    {
      "index": 0,
      "relevance_score": 0.4182,
      "document": {
        "text": "BM25 menggunakan frekuensi term terbobot dengan length normalization untuk pencarian leksikal."
      }
    },
    {
      "index": 2,
      "relevance_score": 0.1054,
      "document": {
        "text": "Vector embeddings memetakan teks ke dalam ruang kontinu high dimensional."
      }
    }
  ]
}
```

### B. Integrasi Python di Pipeline Vault RAG (`scripts/query.py`)

```python
import os
import requests

def rerank_with_jina_v3(query: str, candidates: list[dict], top_n: int = 5) -> list[dict]:
    """
    Rerank candidate chunks using Jina AI Reranker v3 API.
    """
    if not candidates:
        return []

    api_key = os.getenv("JINA_API_KEY")
    if not api_key:
        print("[Warning] JINA_API_KEY tidak ditemukan. Menggunakan urutan asli.")
        return candidates[:top_n]

    url = "https://api.jina.ai/v1/rerank"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    # Ekstrak teks kandidat
    docs_text = [c.get("text", "") for c in candidates]

    payload = {
        "model": "jina-reranker-v3",
        "query": query,
        "top_n": min(top_n, len(candidates)),
        "documents": docs_text,
        "return_documents": False
    }

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        results = response.json().get("results", [])

        reranked_chunks = []
        for r in results:
            idx = r["index"]
            score = r["relevance_score"]
            chunk = candidates[idx].copy()
            chunk["rerank_score"] = round(score, 4)
            reranked_chunks.append(chunk)

        return reranked_chunks
    except Exception as e:
        print(f"[Fallback Error] Gagal melakukan rerank Jina v3: {e}")
        return candidates[:top_n]
```

---

## 6. Matrix Perbandingan SOTA Rerankers

| Model Reranker          | Paradigm                      | Context Window | Bahasa                  | Size / Params | Best Use Case                            |
| ----------------------- | ----------------------------- | -------------- | ----------------------- | ------------- | ---------------------------------------- |
| **Jina Reranker v3** 👑 | **Listwise Cross-Encoder**    | **131,072**    | **100+ (Multilingual)** | **597M**      | **SOTA RAG, Multilingual, Long Context** |
| Cohere Rerank v3.5      | Pointwise Cross-Encoder       | 4,096          | Multilingual            | Proprietary   | Corporate RAG API                        |
| BGE-Reranker-Large      | Pointwise Cross-Encoder       | 512            | En / Zh                 | 560M          | Self-hosted local CPU/GPU                |
| Jina Reranker v2        | Pointwise Cross-Encoder       | 1,024          | Multilingual / Code     | 278M          | Code search & Function Calling           |
| ColBERT v2              | Late-Interaction Multi-Vector | 512            | En                      | 110M          | Sub-5ms Vector Multi-Index               |

---

## 7. Production Best Practices & Optimization Techniques

1. **Optimal Two-Stage Sizing Ratio**:
   - Stage 1 (Hybrid BM25 + Dense Retrieval): Targetkan **$30 - 50$ kandidat chunks**.
   - Stage 2 (Jina Reranker v3): Filter menjadi **$3 - 5$ chunks teratas** untuk disuntikkan ke LLM Prompt.
2. **Handling Token Budget & Thresholding**:
   - Tetapkan ambang batas relevansi minimum (_score thresholding_): Hilangkan chunk dengan `relevance_score < 0.20` untuk mencegah noise menginfeksi konteks LLM.
3. **Caching Layer for Frequent Queries**:
   - Simpan hasil reranking untuk query umum dalam `Redis` atau `SQLite` menggunakan cache key `hash(query + chunk_ids)` untuk menghemat latensi dan kuota API.

---

## 🔗 Referensi & Catatan Terkait

- [[semantic-search-pipeline]] — Arsitektur Dua-Tahap Search & Retrieval
- [[jina-embeddings-v5-mrl-adapters]] — Embeddings Vector dengan Matryoshka Representation
- [[cosine-similarity-deepdive]] — Mengapa Cosine Distance Punya Limitasi pada Relevansi Teks
- [[backpropagation-deepdive]] — Konsep Dasar Training & Optimization Loss Function
