---
tags:
  - deep-learning
  - nlp
  - embedding
  - similarity
  - metric-learning
aliases:
  - Cosine Similarity
  - Similaritas Kosinus
  - Semantic Similarity
status: pending
created: 2026-07-11
updated: 2026-07-11
---

# Cosine Similarity: Mengukur Kedekatan Vektor

> [!tip] Cosine similarity mengukur sudut antara dua vektor — seberapa "searah" mereka terlepas dari panjang/ magnitude-nya. Rentang [-1, 1]. 1 = identik arah, 0 = ortogonal, -1 = berlawanan.

---

## 1. Kenapa Butuh Ukuran Kemiripan?

Di ML, kita sering representasi data sebagai vektor (embedding):

- "Kucing" → `[0.2, -0.5, 0.8, ...]`
- "Kucing besar" → `[0.3, -0.4, 0.7, ...]`
- "Mobil" → `[-0.6, 0.1, -0.3, ...]`

Kita perlu cara ngitung **seberapa mirip** dua vektor — secara semantik, bukan karakter literal.

Cosine similarity cocok untuk:

- **Semantic search**: cari dokumen yang topiknya mirip query
- **Recommendation**: user A mirip user B → rekomendasi silang
- **Clustering**: kelompokkan vektor yang searah
- **Face recognition**: embedding wajah → cocokkan dengan database

---

## 2. Formula & Geometri

### Definisi Matematis

```
cos(θ) = (A · B) / (||A|| × ||B||)
```

- `A · B` = dot product = Σᵢ(Aᵢ × Bᵢ)
- `||A||` = magnitude/Euclidean norm = √Σᵢ(Aᵢ²)
- `θ` = sudut antara vektor A dan B di ruang dimensi-dimensi

### Dalam Bentuk Komponen

Untuk vektor 3D sebagai ilustrasi:

```
A = [a₁, a₂, a₃]
B = [b₁, b₂, b₃]

cos(θ) = (a₁b₁ + a₂b₂ + a₃b₃) / (√(a₁²+a₂²+a₃²) × √(b₁²+b₂²+b₃²))
```

### Visualisasi Geometrik

Bayangkan dua vektor di bidang 2D:

- `A = [1, 0]` (kanan)
- `B = [0, 1]` (atas)

`cos(θ) = (1·0 + 0·1) / (1 × 1) = 0` → tegak lurus → tidak mirip.

- `A = [1, 0]`, `C = [0.8, 0.6]`
- `cos(θ) = (0.8 + 0) / (1 × 1) = 0.8` → sudut ~37° → cukup mirip

### Kenapa Bukan Euclidean Distance?

| Metrik             | Rentang | Sensitif terhadap     | Cocok untuk                            |
| ------------------ | ------- | --------------------- | -------------------------------------- |
| Cosine Similarity  | [-1, 1] | Arah, bukan magnitude | Embedding sparse, dokumen panjang beda |
| Euclidean Distance | [0, ∞)  | Magnitude             | Data terpusat/normalized               |
| Dot Product        | (-∞, ∞) | Arah × magnitude      | Attention score (scaled)               |

Contoh: dokumen "A" 1000 kata, dokumen "B" 100 kata, topik sama.

- Euclidean: besar karena magnitudo beda
- Cosine: ~1.0 karena arahnya sama

**Kapan cosine gagal:** Semua vektor di kuadran positif (embedding ReLU-activated) — cosine antara dua vektor positif selalu ≥ 0, kehilangan informasi negasi.

---

## 3. Cosine Similarity vs Dot Product vs Euclidean

### Dot Product = Unnormalized Cosine

```
A · B = ||A|| × ||B|| × cos(θ)
```

Kalau vektor sudah **dinormalisasi** (||A||=||B||=1):

```
cos(θ) = A · B
```

Ini yang terjadi di attention mechanism: Q·K^T pakai dot product, karena embedding udah normalized secara implisit via layer norm + softmax.

### Hubungan dengan Euclidean

```
||A - B||² = 2 - 2·cos(θ)      (untuk unit vector)
```

Artinya: cosine similarity 1 → Euclidean 0. Cosine 0 → Euclidean √2. Tapi ini cuma berlaku untuk vektor yang sudah di-normalize ke unit length.

---

## 4. Implementasi Praktis

### Python — Manual

```python
import numpy as np

def cosine_similarity(A, B):
    dot = np.dot(A, B)
    norm_a = np.linalg.norm(A)
    norm_b = np.linalg.norm(B)
    return dot / (norm_a * norm_b) if norm_a > 0 and norm_b > 0 else 0.0

# Batch: semua pair antara matriks X dan Y
def cosine_similarity_matrix(X, Y):
    # X: (n, d), Y: (m, d)
    X_norm = X / np.linalg.norm(X, axis=1, keepdims=True)
    Y_norm = Y / np.linalg.norm(Y, axis=1, keepdims=True)
    return X_norm @ Y_norm.T   # (n, m) — semua pair sekaligus
```

### Python — sklearn

```python
from sklearn.metrics.pairwise import cosine_similarity

sim = cosine_similarity(query_embedding, document_embeddings)
top_k = sim.argsort(axis=1)[:, ::-1][:, :5]
```

### Python — PyTorch (untuk training loop)

```python
import torch.nn.functional as F

def contrastive_loss(anchor, positive, negative, margin=0.3):
    # anchor-positive: harus mirip
    # anchor-negative: harus beda

    pos_sim = F.cosine_similarity(anchor, positive)  # (batch,)
    neg_sim = F.cosine_similarity(anchor, negative)  # (batch,)

    # triplet loss: margin - (pos_sim - neg_sim)
    loss = torch.clamp(margin - pos_sim + neg_sim, min=0)
    return loss.mean()
```

### Edge Cases

```python
# Zero vector: tidak bisa dihitung
A = [0, 0, 0], B = [0.5, 0.3, -0.1]
# → division by zero. Return 0 atau handle via epsilon.

# Numerical stability
epsilon = 1e-8
sim = dot / (norm_a * norm_b + epsilon)
```

---

## 5. Aplikasi: Semantic Search

### Pipeline Klasik

```
Query: "cara training neural network"

1. Encode query → embedding (768-d)
2. Hitung cosine similarity ke semua 1M dokumen
3. Sort descending → top-10 hasil

Waktu: 1M × 768 dot ≈ 1ms di GPU.
```

### Approximate Nearest Neighbor (ANN)

Kalau 1M dokumen × 1000 query/second — brute force O(n) gak cukup.

Solusi: **ANN index** — korbankan dikit akurasi untuk kecepatan:

| Library     | Algoritma                | Kecepatan (QPS) | Recall@10 |
| ----------- | ------------------------ | --------------- | --------- |
| FAISS (IVF) | Inverted File + HNSW     | 10K+            | ~95%      |
| ScaNN       | Anisotropic quantization | 15K+            | ~97%      |
| Annoy       | Random projection tree   | 5K              | ~90%      |

```python
import faiss

d = 768  # dimensi embedding
index = faiss.IndexFlatIP(d)  # Inner Product = cosine di normalized vector
# atau IndexIVFFlat — lebih cepat untuk >100K

index.add(normalized_docs)  # (N, d)
scores, indices = index.search(normalized_query, k=10)
```

**Kapan ANN gagal:** Dataset dengan distribusi cluster yang tidak seragam. IVF punya asumsi data tercluster. Kalau embedding tersebar random (misal random init), performa drop.

---

## 6. Cosine dalam Loss Functions

### Contrastive Loss

```python
L = (1-y) × d(A,P)² + y × max(0, margin - d(A,N))²
```

- `y=0`: positive pair → tarik berdekatan
- `y=1`: negative pair → dorong > margin

Kalau pake cosine: `d(A,P) = 1 - cos(A,P)` → range [0, 2].

### Triplet Loss

```python
L = max(0, cos(A,N) - cos(A,P) + margin)
```

- Goal: anchor-positive lebih mirip dari anchor-negative minimal sebesar margin.
- Digunakan di: FaceNet, SBERT, DPR (Dense Passage Retrieval).

### CosFace / ArcFace

Evolusi loss dengan cosine untuk face recognition:

```
L = -log(exp(s·cos(θ_y+m)) / (exp(s·cos(θ_y+m)) + Σⱼ≠ᵧ exp(s·cos(θⱼ))))
```

- `s` = scale factor
- `m` = margin angular
- Memaksa embedding face dari kelas sama berkerumun di hypersphere

### Kapan Cosine Loss Gagal

| Kasus                           | Masalah                                 | Alternatif          |
| ------------------------------- | --------------------------------------- | ------------------- |
| Embedding sparse (banyak 0)     | Cosine meaningless — banyak overlap nol | Jaccard / Tversky   |
| Magnitude penting (mis: rating) | Cosine ignore magnitude                 | Euclidean           |
| Outlier vektor besar            | Dominasi komponen besar                 | Normalize dulu      |
| Low-dimensional (<10)           | Semua vektor hampir ortogonal           | Gunakan correlation |

---

## 7. Cosine vs Metrik Lain

### Tabel Perbandingan Lengkap

| Metrik              | Range   | Translasi-Invarian | Skala-Invarian | Kompleksitas | Kapan Pilih                         |
| ------------------- | ------- | :----------------: | :------------: | ------------ | ----------------------------------- |
| Cosine Similarity   | [-1, 1] |         Ya         |     **Ya**     | O(d)         | Embedding, dokumen, semantic        |
| Euclidean           | [0, ∞)  |         Ya         |     Tidak      | O(d)         | Data terpusat, clustering k-means   |
| Manhattan (L1)      | [0, ∞)  |         Ya         |     Tidak      | O(d)         | High-dim sparse, robust outlier     |
| Chebyshev           | [0, ∞)  |         Ya         |     Tidak      | O(d)         | Grid-based distance                 |
| Pearson Correlation | [-1, 1] |         Ya         |       Ya       | O(d)         | Time series, rating user            |
| Hamming             | [0, d]  |         —          |       —        | O(d)         | Binary vectors, hash                |
| Jaccard             | [0, 1]  |         —          |       —        | O(set)       | Set overlap, sparse binary          |
| Mahalanobis         | [0, ∞)  |         Ya         |       Ya       | O(d²)        | Data berkorelasi, anomaly detection |
| Dot Product         | (-∞, ∞) |       Tidak        |     Tidak      | O(d)         | Attention (dengan scale)            |
| KL Divergence       | [0, ∞)  |       Tidak        |     Tidak      | O(d)         | Distribusi probabilitas             |
| Wasserstein         | [0, ∞)  |         Ya         |       Ya       | O(d³logd)    | Distribusi dengan support berbeda   |

**Catatan:** Pearson correlation bisa dihitung dari cosine yang sudah di-mean-center:

```
Pearson(A,B) = cos(A - mean(A), B - mean(B))
```

Jadi kalau data sudah di-normalize, cosine ≈ Pearson.

---

## 8. Cosine Similarity di Transformer

### Scaled Dot-Product Attention

```
Attention(Q,K,V) = softmax(Q·K^T / √dₖ) · V
```

Di sini:

- `Q·K^T` = dot product ≈ unnormalized cosine
- Scaling `√dₖ` penting: makin besar dₖ, dot product makin besar (akumulasi dₖ terms). Tanpa scale, softmax masuk region gradien sangat kecil → training stagnan.

### Self-Attention vs Cosine

Kenapa transformer pake dot product langsung, bukan cosine?

1. **Dot product preserve magnitude information** — beberapa token emang lebih "penting"
2. **Yang penting beda relatif, bukan absolut** — softmax normalize kok
3. **Implementation efficiency** — satu matmul, bukan dua (normalize + matmul)

Tapi ada arsitektur yang eksplisit pake cosine attention (CosFormer, cosine-similarity-based attention) untuk:

- Stabilize training di model extra deep
- Biar attention distribution lebih smooth

---

## 9. Best Practices

### Normalize Sebelum Cosine

```python
# Selalu normalize embedding dulu
embed = embed / torch.norm(embed, dim=-1, keepdim=True)
sim = embed_a @ embed_b.T  # = cosine karena sudah unit vector
```

Kalau gak di-normalize, hasilnya dot product biasa — terpengaruh magnitude.

### Batasi Eksposur ke Data Negative

Training dengan cosine loss sering collapse: semua embedding jadi sama (konvergen ke titik tunggal). Trik:

- **Hard negative mining**: pilih negative yang paling "mirip" (paling susah dibedakan)
- **Gradient scaling**: jangan terlalu kuat mendorong negative
- **Margin yang kecil**: margin 0.1-0.3 biasanya cukup

### Dimensionality Curse

Di dimensi tinggi (>500), distribusi dot product:

- Mean ~0
- Variance makin besar → cosine similarity antara vektor random ~N(0, 1/√d)
- Praktis: semua vektor random punya cosine ~0 → sulit bedakan random vs mirip

Fix: **dimensi embedding jangan kebesaran**. 768 sudah cukup untuk BERT. 128 untuk retrieval (DPR). 512 untuk CLIP.

---

## 10. Cosine in Information Retrieval Systems

### Two-Stage Retrieval

Production semantic search almost never uses cosine alone. Standard:

1. **Stage 1 (Retrieval):** Query embedding → cosine search via ANN → top-100 candidates
2. **Stage 2 (Reranking):** Cross-encoder (full attention, not cosine) → top-10

Why two stages? Cosine is fast but imprecise — it captures "topic similarity" but misses nuanced relevance.

```python
def search(query, corpus):
    # Stage 1: Dense retrieval via cosine ANN
    q_vec = normalize(embed(query))
    candidate_ids, cos_scores = faiss_index.search(q_vec, k=100)

    # Stage 2: Cross-encoder reranking
    pairs = [(query, corpus[i]) for i in candidate_ids[0]]
    rerank_scores = cross_encoder.predict(pairs)
    top_k = [candidate_ids[0][i] for i in np.argsort(rerank_scores)[::-1][:10]]
    return [(corpus[i], rerank_scores[i]) for i in top_k]
```

### Hybrid Retrieval: Sparse + Dense

Dense (cosine) excels at semantic matching. Sparse (BM25) excels at exact keyword match. Neither is sufficient alone:

```python
score = α · BM25(q, d) + (1-α) · cos(Eq, Ed)
```

α tuning:

- General corpus: α=0.3 (favor semantics)
- Technical/legal/medical: α=0.7 (keywords matter)
- Code search: α=0.5

### Chunking Strategy

Document chunking directly impacts cosine quality:

| Strategy                  | Description                                      | Cosine Impact                       | Best For       |
| ------------------------- | ------------------------------------------------ | ----------------------------------- | -------------- |
| Fixed window (256 tokens) | Equally sized chunks, overlap 20%                | Stable embedding per chunk          | General QA     |
| Semantic chunking         | Split at paragraph/sentence boundaries           | Embedding captures coherent concept | Long docs      |
| Recursive split           | Hierarchical chunks (section→paragraph→sentence) | Multi-granularity cosine            | Nested content |
| Late chunking             | Encode full doc, chunk KV pairs                  | Best embedding quality, expensive   | High-accuracy  |

---

## 11. Dimensionality Effects — Curse and Cure

### Why High-Dim Cosine Breaks

For two random vectors in ℝᵈ:

- Mean dot product = 0
- Variance = d · σ⁴
- Cosine similarity variance = 1/d

At d=768 (typical BERT embedding), random cosine std ≈ 0.036. Nearly all pairs score ~0. Collapsed discrimination.

### Intrinsic Dimensionality

Effective dimensionality of BERT embedding is ~20-60, not 768. PCA confirms: top-50 components explain >90% variance.

### Fixes for High-Dim

1. **Mean-centering:** Subtract corpus mean from all embeddings before cosine
2. **Whitening:** Apply PCA→whiten→reduce to 128-256 dim
3. **Normalized cosine** (already unit vector): just dot product
4. **Quantization-aware training:** Force embedding into lower intrinsic dim

### Isotropy vs Anisotropy

Good embedding space should be isotropic — uniform in all directions. Anisotropic space causes:

- All embeddings cluster together → cosine between any two sentences > 0.95
- Poor discrimination
- Underperforming retrieval

**Solutions:**

- Contrastive learning (SimCSE, SBERT) — inherently isotropizes
- Post-processing: `embed = embed - mean(embed)` (remove dominant component)
- Normalization + temperature scaling

---

## 12. Advanced Training with Cosine Loss

### Multiple Negative Ranking Loss

```python
# For each query: 1 positive doc, N negative docs
scores = cosine_similarity(q_emb, all_doc_embs)  # (batch, N+1)
# Softmax over N+1 — maximize positive score relative to negatives
loss = cross_entropy(scores, labels)  # labels: 0 (positive is first)
```

More negatives → better discrimination. But limited by GPU memory.

### Cross-Batch Negatives

Use embeddings from OTHER batches as negatives — effectively N × batch_size negatives:

```python
all_q = all_gather(q_emb)  # gather from all GPUs
all_d = all_gather(d_emb)
# Now each GPU sees batch × num_gpus examples
scores = cosine_similarity(all_q, all_d)  # (b, b*g)
```

### Hard Negative Mining

Random negatives are too easy (cosine already low). Model doesn't learn to discriminate similar-looking negatives.

| Negative Type | Definition                      | Effort            | Impact    |
| ------------- | ------------------------------- | ----------------- | --------- |
| Random        | Any other doc from corpus       | None              | Baseline  |
| Batch         | Other docs in same batch        | Automatic         | Good      |
| Hard          | Top-100 by cos but not relevant | Requires ANN      | Best      |
| In-batch hard | Hardest negative in batch       | Automatic (SBERT) | Excellent |

### SBERT Fine-tuning Recipe

```python
# Cosent loss (cross-entropy on cosine scores)
model = SentenceTransformer('distilbert-base-nli-mean-tokens')
train_loss = losses.CoSentLoss(model)
model.fit(train_objectives=[(train_dataloader, train_loss)], epochs=3, warmup_steps=500)
```

Key hyperparameters:

- Batch size: 32-64 (larger = better negatives)
- Margin: 0.3-0.5 for triplet, 0.1-0.3 for cosine contrastive
- Learning rate: 2e-5 (Adam)
- Pooling: CLS token → better than mean pooling for retrieval

---

## 13. Similarity Evaluation Metrics

| Metric   | What It Measures                         | Formula      | Range |
| -------- | ---------------------------------------- | ------------ | ----- |
| Recall@k | Fraction of relevant docs found in top-k | TP / (TP+FN) | [0,1] |
| MRR      | Reciprocal rank of first relevant doc    | 1/rank_avg   | (0,1] |
| NDCG     | Graded relevance × position discount     | DCG/IDCG     | [0,1] |
| MAP      | Average precision across recall levels   | Σ P(k)·ΔR(k) | [0,1] |
| Hit Rate | Did any relevant doc appear in top-k?    | binary       | [0,1] |

Cosine threshold tuning does NOT optimize for these metrics — it optimizes for pairwise rank consistency. That's why reranking (stage 2) is essential.

---

## 14. Similarity ≠ Relevance — Critical Distinction

Cosine measures **vector proximity**, not **task relevance**:

| Query                          | Top-1 by Cosine              | Is It Relevant?             |
| ------------------------------ | ---------------------------- | --------------------------- |
| "How to install npm?"          | "NPM overview documentation" | Yes                         |
| "Macbook M4 price"             | "Macbook M4 review"          | Related but not pricing     |
| "Kapan jadwal kereta Bandung?" | "Stasiun Bandung fasilitas"  | Related topic, wrong answer |

The gap: cosine captures **what is the document about**, not **does it answer this question**. Reranking fixes this.

### Query Understanding Layer

Before cosine search, process query:

1. **Query expansion:** "macbook m4 price" → "macbook m4 price cost rupiah harga beli"
2. **Query classification:** factual / opinion / comparison → adjust retrieval strategy
3. **Intent parsing:** "jadwal kereta" → filter by schedule-related metadata

These transformations improve cosine quality without modifying the model.

---

## 15. Production Considerations

### Latency Budget

```python
# Typical P99 latency breakdown for search:
embed_query:     5ms   (GPU) /  30ms (CPU)
ANN search:     10ms   (GPU) /  50ms (CPU, 1M docs)
reranker:       50ms   (GPU) / 200ms (CPU, 100 pairs)
total:          65ms   (GPU) / 280ms (CPU)
```

If reranker too slow: skip for simple queries, use cosine score directly + metadata filters.

### FAISS Production Pitfalls

1. **IVF training does not converge:** Dataset too small for ncentroids. Fix: reduce centroids, increase training data.
2. **Index drift:** New documents added but index not retrained. Fix: incremental index (IVF with online updates) or periodic rebuild.
3. **OOD queries:** Query domain different from training corpus. Fix: domain-specific embedder fallback.
4. **Memory corruption:** mmap index files corrupted. Fix: CRC checksums on index files.

### Embedding Versioning

Every model update invalidates all previous embeddings. Plan:

- Pin model version in production
- Maintain version mapping in metadata store
- Staged rollout: new embeddings for new docs, hybrid search with old + new
- Full re-index on major version bump

### Scoring Calibration

Cosine scores from different embedders have different distributions. Never compare absolute cosine values across models:

| Embedder     | Mean Cosine (pos pairs) | Mean Cosine (neg pairs) | Threshold @ F1 |
| ------------ | ----------------------- | ----------------------- | -------------- |
| SBERT-MiniLM | 0.72                    | 0.34                    | 0.53           |
| Ada-002      | 0.81                    | 0.55                    | 0.68           |
| BGE-base     | 0.74                    | 0.38                    | 0.56           |

Calibrate threshold per model using validation set.

---

## 16. SimCLR / Contrastive Learning Framework

Cosine is the backbone of contrastive learning:

```
For each batch:
  - Augment each image x → x_i, x_j (2 views)
  - Encode: h_i = f(x_i), h_j = f(x_j)
  - Project: z_i = g(h_i), z_j = g(h_j)
  - Normalize: z_i = z_i / ||z_i||, z_j = z_j / ||z_j||

  For positive pair (same image):
    cos(z_i, z_j) → maximize → close to 1

  For negative pairs (different images):
    cos(z_i, z_k) → minimize → close to 0

Loss = -log(exp(cos(z_i,z_j)/τ) / Σ exp(cos(z_i,z_k)/τ))
```

τ (temperature) controls sharpness: low τ → peaky distribution, high τ → uniform. τ=0.07 typical.

**InfoNCE = Categorical cross-entropy on cosine scores.** Negative pairs are implicitly other samples in the batch.

---

## 17. Non-Cosine Alternatives for Embedding Comparison

### Learned Similarity (Instead of Fixed Metric)

Train a lightweight comparator instead of hardcoding cosine:

```python
# 2-layer MLP on concatenated embeddings
def learned_sim(e1, e2):
    features = concat([e1, e2, e1*e2, abs(e1-e2)])
    return MLP(features)  # sigmoid output [0,1]
```

More expressive: can learn "e1 > e2 implies opposite meaning" vs "e1 near e2 implies similar". But: requires labeled pairs, not zero-shot.

### Angle Margin (ArcFace-style)

Replace cosine with angular margin:

```
cos(θ + m) — instead of cos(θ)
```

M embeds margin directly into angular space — pushes classes apart in hypersphere. Best for face recognition, fine-grained classification.

### Wasserstein Distance

For distributions rather than point vectors:

```
W(P,Q) = inf E[|x - y|] over couplings
```

Captures shape difference, not just direction. Good for:

- Histograms (bag-of-words)
- Set embeddings
- Long document representation

But: O(d³) to compute — impractical for large-scale retrieval.

---

## 18. Cosine in Multimodal Systems

### CLIP-Style Contrastive

```python
# Image-text contrastive: cosine between I_emb and T_emb
I_emb = normalize(image_encoder(I))
T_emb = normalize(text_encoder(T))

# (batch x batch) similarity matrix
sim = I_emb @ T_emb.T  # cosine because already normalized

# Symmetric cross-entropy loss
loss_i = cross_entropy(sim, labels)  # each image matches its text
loss_t = cross_entropy(sim.T, labels)  # each text matches its image
loss = (loss_i + loss_t) / 2
```

**Why cosine for multimodal?** Image and text embeddings live in different spaces — dot product isn't naturally comparable. Cosine (normalized) projects both to unit sphere, enabling cross-modal comparison.

---

## 19. Soft Cosine & Beyond

### Soft Cosine

Standard cosine treats all dimensions independently. Soft cosine considers dimension correlations:

```
soft_cos(A,B) = A · S · B / √((A·S·A) × (B·S·B))
```

S is a similarity matrix between dimensions (e.g., word similarity matrix). When S = I, soft cosine = regular cosine.

**Cost:** S is d×d — O(d²) compute, O(d²) memory. Impractical for d>300.

### Weighted Cosine

Assign different importance to different dimensions:

```
weighted_cos(A,B) = Σ w_i · A_i · B_i / (||A||_w × ||B||_w)
```

w_i learned during training or derived from attention scores. Simpler than soft cosine.

### Cosine with Attention Pooling

Instead of mean-pooling token embeddings, compute weighted average using attention:

```python
# For sentence embedding: attend tokens to CLS token
attn_weights = softmax(q_cls @ K_layer.T)  # (seq_len,)
sentence_emb = attn_weights @ V_layer       # weighted average
cosine = cosine_similarity(sentence_emb_q, sentence_emb_d)
```

This gives better sentence representation for cosine search.

---

## 20. Practical Debugging — When Cosine Misleads

| Symptom                             | Root Cause                | Diagnosis                                 | Fix                           |
| ----------------------------------- | ------------------------- | ----------------------------------------- | ----------------------------- |
| All pairs cosine >0.9               | Anisotropic embedding     | PCA variance plot                         | Remove top PCA component      |
| All pairs cosine ~0                 | Embedding collapse        | Check embedding std                       | Re-init, add contrastive loss |
| Good on dev, bad on prod            | Domain shift              | Compare train-test embedding distribution | Domain adaptation             |
| Bad for short queries               | Length mismatch           | Plot query vs doc embedding norm          | Query expansion               |
| Bad for rare entities               | Out-of-vocabulary         | Check token overlap                       | BM25 fallback, augment        |
| Retrieval misses exact match        | Tokenization issue        | Check query tokenization                  | Add exact match boosting      |
| Cosine score 0.7 for irrelevant doc | Semantic but not relevant | Manual inspection sample                  | Add reranker stage            |

---

## 11. Conceptual Pathway

Baca juga:

- [[attention-mechanism-deepdive]] — attention pake dot product sebagai similarity score
- [[backpropagation-deepdive]] — gradient dari cosine loss mengalir lewat chain rule
- [[cosine-vs-euclidean-vs-dot]] — perbandingan lebih dalam (kalau ada)
- [[semantic-search-pipeline]] — end-to-end search system (kalau ada)

---

## Referensi

- Mikolov, T. et al. (2013). _Efficient Estimation of Word Representations in Vector Space._ — Word2Vec, asal mula embedding dan cosine.
- Reimers, N., Gurevych, I. (2019). _Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks._ — Triplet loss + cosine untuk semantic search.
- Deng, J. et al. (2019). _ArcFace: Additive Angular Margin Loss for Deep Face Recognition._ — CosFace/ArcFace: state-of-the-art face recognition.
- Johnson, J. et al. (2019). _Billion-scale Similarity Search with GPUs._ — FAISS untuk ANN + cosine search.
- Vaswani, A. et al. (2017). _Attention Is All You Need._ — Scaled dot-product = cosine-like di transformer.
