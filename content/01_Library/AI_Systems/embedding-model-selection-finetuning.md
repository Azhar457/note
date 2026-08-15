---
title: 🧠 Embedding Model Selection & Fine-Tuning — Dari text-embedding-3-small ke
  Model Domain-Spesifik
tags:
- embedding
- rag
- fine-tuning
- retrieval
- library
created: '2026-07-16'
updated: '2026-07-16'
status: pending
cssclasses:
  - wide-table
  - callout

---

# 🧠 Embedding Model Selection & Fine-Tuning — Dari text-embedding-3-small ke Model Domain-Spesifik

> Embedding model adalah jantung semantic search — ia yang menentukan seberapa baik makna dokumen ditangkap dalam ruang vektor. Memilih model yang salah berarti chunk terbaik pun tidak akan ter-retrieve. Dokumen ini membedah spektrum embedding model dari yang proprietary (OpenAI, Cohere) hingga open-source (BGE, E5, Jina), konsep dimensi & Matryoshka embeddings, fine-tuning dengan LoRA untuk domain spesifik, dan strategi eval untuk memilih model yang tepat untuk vault ini.

> [!info] Hubungan ke Vault
> vault-rag saat ini menggunakan `text-embedding-3-small` via 9Router API. Catatan ini membahas alternatif (BGE, E5, Jina) dan kapan fine-tuning diperlukan. Terkait dengan [[advanced-chunking-strategies-deepdive]] (kualitas chunk = kualitas embedding), [[vector-database-internals-optimization]] (dimensi vector → performa index), `../vault-rag/scripts/index_vault.py` (implementasi embedding), dan [[rag-evaluation-framework]] (metric embedding quality).

---

## Daftar Isi

- [[#1. Embedding 101]]
- [[#2. Perbandingan Model]]
- [[#3. Matryoshka Embeddings]]
- [[#4. Fine-Tuning]]
- [[#5. Eval Embedding untuk Vault Ini]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## 1. Embedding 101

### 1.1 Cara Kerja

Embedding model mengubah teks menjadi vektor angka (float array) di ruang dimensi tetap. Prinsipnya: teks dengan makna serupa punya vektor yang berdekatan (cosine similarity tinggi).

```
"TCP handshake" → [0.23, -0.45, 0.12, ..., 0.89]  (1536 dimensi)
"SYN flood"     → [0.21, -0.42, 0.15, ..., 0.85]  (similarity: 0.95)
"resep nasi goreng" → [-0.12, 0.55, -0.33, ..., 0.01] (similarity: 0.12)
```

| Konsep | Penjelasan |
|--------|-----------|
| **Dimensi** | Panjang vector. Makin tinggi → makin detail (tapi makin mahal storage & compute) |
| **Pooling** | Cara model menggabungkan token embeddings jadi satu vector (CLS, mean, max) |
| **Normalization** | Vector dinormalisasi ke unit length (L2 norm) biar cosine similarity = dot product |
| **Context length** | Maks token yang bisa diproses sekaligus. > context length → truncation |

### 1.2 Context Length Penting buat Chunking

Kalo embedding model punya context length 512 token, chunk lo harus ≤512 token. Kalo lo pake model dengan 8192 token context (seperti `text-embedding-3-large`), chunk bisa lebih panjang. Tapi **lebih panjang ≠ lebih baik** — chunk panjang mencampur banyak topik → embedding jadi "rata-rata" dari semuanya → presisi turun.

---

## 2. Perbandingan Model

### 2.1 Model Matrix

| Model | Dimensi | Context | MTEB* | Harga | Open Source | Catatan Vault |
|-------|---------|---------|-------|-------|-------------|---------------|
| **text-embedding-3-small** | 1536 (dapat 256/512/1024) | 8191 | 62.3 | 💲 $0.02/1M token | ❌ | **Saat ini dipake vault-rag** |
| **text-embedding-3-large** | 3072 (dapat 256/512/1024/1536) | 8191 | 64.6 | 💲 $0.13/1M token | ❌ | Lebih akurat, 6.5x lebih mahal |
| **Cohere Embed v3** | 1024 | 512 | 62.0 | 💲 $0.10/1M | ❌ | Binary quantization built-in |
| **BGE-M3** | 1024 | 8192 | 64.0 | 🆓 Gratis | ✅ Multi-lingual | Bisa multi-vector (sparse + dense) |
| **BGE-large-en-v1.5** | 1024 | 512 | 63.0 | 🆓 Gratis | ✅ | Best open-source English |
| **E5-mistral-7b-instruct** | 4096 | 4096 | 66.6 | 🆓 Gratis | ✅ | Best overall, tapi butuh GPU 16GB+ |
| **Jina-embeddings-v3** | 1024 | 8192 | 64.2 | 🆓 Gratis | ✅ | Multi-lingual, task-specific LoRA |
| **GTE-Qwen2-7B** | 3584 | 8192 | 64.8 | 🆓 Gratis | ✅ | Best open-source China |
| **Snowflake Arctic-embed-m** | 768 | 512 | 61.0 | 🆓 Gratis | ✅ | Ringan, cocok buat produksi |

\*MTEB = Massive Text Embedding Benchmark (rata-rata dari 56 dataset). Makin tinggi = makin baik.

### 2.2 Trade-off untuk Vault Ini

| Skenario | Model Rekomendasi | Alasan |
|----------|------------------|--------|
| **Saat ini (9Router API)** | `text-embedding-3-small` (256d) | OK. Cukup untuk production. Turunin dimensi ke 256 via Matryoshka |
| **Local / offline** | `BGE-M3` atau `Snowflake Arctic-embed-m` | Open source, multilingual (BGE-M3), ringan |
| **Max akurasi (ada GPU)** | `E5-mistral-7b-instruct` atau `gte-Qwen2-7B` | Skor MTEB tertinggi |
| **Multi-lingual (EN+ID)** | `BGE-M3` atau `Jina-embeddings-v3` | Dukungan bahasa Indonesia |

---

## 3. Matryoshka Embeddings

### 3.1 Konsep

Matryoshka embedding = satu model bisa menghasilkan vector dengan dimensi **variabel** tanpa fine-tuning. Misal `text-embedding-3-small` mendukung 256, 512, 1024, atau 1536 dimensi — dari model yang SAMA.

```python
# OpenAI: pake dimensions parameter
import openai

response = openai.embeddings.create(
    model="text-embedding-3-small",
    input="TCP handshake",
    dimensions=256  # Matryoshka! 1536 → 256 tanpa loss signifikan
)
```

**Trade-off dimensi:**

| Dimensi | Ukuran Index (1M vektor) | Performa Search | Akurasi (relatif) |
|---------|-------------------------|-----------------|-------------------|
| 256 | ~200 MB | 🟢 Sangat cepat | 97% dari 1536 |
| 512 | ~400 MB | 🟢 Cepat | 99% |
| 1024 | ~800 MB | 🟡 Normal | 99.8% |
| 1536 | ~1.2 GB | 🟡 Normal | 100% |

**Untuk vault-rag:** Bisa turunin ke 256d tanpa kehilangan akurasi signifikan → index sqlite-vec lebih kecil, query lebih cepat.

---

## 4. Fine-Tuning

### 4.1 Kapan Perlu?

| Situasi | Fine-Tuning? | Contoh |
|---------|-------------|--------|
| Domain umum (Wikipedia, Reddit) | ❌ Tidak perlu | Vault ini masih tahap ini |
| Domain teknis sempit (hukum, medis) | 🟡 Mungkin | Kode hukum, terminologi medis |
| Bahasa/slang spesifik | 🟡 Mungkin | Bahasa Indonesia campur Inggris vault ini? Perlu test |
| Query-doc distribution mismatch | ✅ Ya | Query pendek → dokumen panjang. Atau sebaliknya |

**Untuk vault ini sekarang:** `text-embedding-3-small` sudah OK karena vault membahas topik mainstream (cybersecurity, networking, Linux). Fine-tuning baru perlu kalo vault mulai masuk ke niche teknis yang embedding model umum gak nangkep (misal: istilah lokal Indonesia, singkatan internal).

### 4.2 LoRA Fine-tuning dengan Sentence Transformers

```python
from sentence_transformers import SentenceTransformer, SentenceTransformerTrainer
from sentence_transformers.losses import CoSENTLoss
from datasets import Dataset

# 1. Load model
model = SentenceTransformer("BAAI/bge-large-en-v1.5")

# 2. Siapkan data (query, positive, negative)
train_data = [
    {"query": "TCP handshake", "positive": "Three-way handshake SYN-SYN-ACK", "negative": "HTTP status codes"},
    {"query": "buffer overflow", "positive": "Stack buffer overflow exploitation", "negative": "Race condition"},
]

dataset = Dataset.from_list(train_data)

# 3. LoRA config
from peft import LoraConfig, get_peft_model
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["query", "value"],  # LoRA pada attention layer
    lora_dropout=0.1,
)

# 4. Train (1 epoch biasanya cukup untuk domain adaptation)
trainer = SentenceTransformerTrainer(
    model=model,
    train_dataset=dataset,
    loss=CoSENTLoss(model),
    args=...,  # TrainingArguments
)
trainer.train()

# 5. Save
model.save_pretrained("./bge-finetuned-vault")
```

---

## 5. Eval Embedding untuk Vault Ini

```python
# Sederhana: test dengan query konkret vault
test_queries = [
    ("Apa itu TCP handshake?", {"related": ["networking-fundamentals-tcpip-bgp.md"]}),
    ("Cara detect SYN flood", {"related": ["networking-fundamentals-tcpip-bgp.md"]}),
    ("Apa itu LSASS?", {"related": ["active-directory-windows-security-deepdive.md"]}),
]

def eval_embedding(model_name, dimension=256):
    scores = []
    for query, expected in test_queries:
        q_vec = embed(query, model_name, dimension)
        # Search di vault-rag DB
        results = search_dense(q_vec, top_k=5)
        # Hitung recall@5: apakah file terkait muncul?
        related_files = set(results) & expected["related"]
        recall = len(related_files) / len(expected["related"])
        scores.append(recall)
    return sum(scores) / len(scores)
```

---

## Koneksi ke Vault

- [[advanced-chunking-strategies-deepdive]] — Kualitas chunk memengaruhi kualitas embedding. Chunk terlalu panjang → embedding jadi rata-rata
- [[vector-database-internals-optimization]] — Dimensi embedding → performa index HNSW → tuning
- [[hybrid-search-vector-keyword]] — Embedding + BM25 = hybrid search. Sparse embedding (BGE-M3) juga bahas di sini
- [[rag-evaluation-framework]] — Metric retrieval quality: recall@k, MRR, NDCG
- `../vault-rag/scripts/index_vault.py` — Implementasi embedding: `ollama_api.embed()` pake `text-embedding-3-small`

---

## References

1. MTEB Leaderboard. https://huggingface.co/spaces/mteb/leaderboard
2. OpenAI. *Embeddings API*. https://platform.openai.com/docs/guides/embeddings
3. BGE-M3. https://huggingface.co/BAAI/bge-m3
4. E5-mistral-7b-instruct. https://huggingface.co/intfloat/e5-mistral-7b-instruct
5. Jina Embeddings v3. https://huggingface.co/jinaai/jina-embeddings-v3
6. Sentence Transformers. *Training Overview*. https://www.sbert.net/docs/training/overview.html
7. Matryoshka Embeddings. *OpenAI Cookbook*. https://cookbook.openai.com/examples/vector_store/using_matteyoshka_embeddings

> [!tip] Bottom Line
> Embedding model menentukan kualitas semantic search. Buat vault ini: **`text-embedding-3-small` (256d via Matryoshka) sudah OK.** Open source alternatif: **BGE-M3** (multilingual, sparse support) atau **Snowflake Arctic-embed-m** (ringan). Fine-tuning belum diperlukan — vault belum cukup niche. Eval berkala dengan query riil vault untuk deteksi kapan butuh upgrade atau fine-tuning.
---

audited
---
