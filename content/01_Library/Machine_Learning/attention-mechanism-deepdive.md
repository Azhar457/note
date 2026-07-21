---
tags:
  - deep-learning
  - nlp
  - transformer
  - attention
  - llm
aliases:
  - Attention Mechanism
  - Mekanisme Attention
  - Self-Attention
  - Cross-Attention
  - Scaled Dot-Product Attention
status: seedling
created: 2026-07-11
updated: 2026-07-11
---

# Attention Mechanism: Revolusi Representasi Sequence

> **TL;DR**: Attention = mekanisme yang memungkinkan model memfokuskan "perhatian" pada bagian input yang relevan, dengan bobot dinamis yang dihitung dari kesesuaian (compatibility) antara query dan key. Ini fondasi Transformer. Tanpa attention, LLM, GPT, BERT, dan semua model sequence modern tidak ada.

---

## 1. Problem Sebelum Attention

Sebelum 2017, arsitektur dominan untuk sequence-to-sequence (seq2seq) adalah **RNN / LSTM dengan encoder-decoder**:

```
Encoder: "I love cats" → [h₁, h₂, h₃] → context vector c (last hidden state)
Decoder: c → "Saya" → "suka" → "kucing"
```

### Masalah Fatal

1. **Bottleneck**: Seluruh informasi sequence harus dikompres ke satu vektor context `c`. Untuk kalimat panjang, informasi di awal hilang.
2. **Vanishing gradient**: RNN panjang >50 step gradiennya mati.
3. **Fixed-length context**: Model gak bisa "melihat ke belakang" pas generate kata — cuma modal context vector yang statis.

### Attention Sebagai Solusi

> **Ide utama**: Jangan kompres semua ke satu vektor. Simpan semua hidden state encoder. Pas decoder generate kata, hitung "seberapa relevan" tiap input.

```
Decoder langkah ke-t:
1. Cari kecocokan antara hidden state decoder saat ini (query) dengan semua hidden state encoder (keys)
2. Dapatkan bobot attention → seberapa penting tiap input
3. Weighted sum dari values → context vector yang dinamis per langkah
```

Ini dulu disebut **Bahdanau Attention** (2015). Tapi versi yang benar-benar mengubah segalanya adalah **Transformer** (Vaswani et al., 2017) — yang membuang RNN sama sekali dan hanya pake attention.

---

## 2. Intuisi: Gimana Caranya "Memperhatikan"?

Bayangkan lo baca kalimat: **"Kucing itu mengejar tikus sampai **dia** lelah."**

Siapa "dia"? Kucing? Atau tikus?

Sebagai manusia, lo pake konteks:

- "mengejar" → subjeknya kucing → "dia" kemungkinan besar kucing
- Tapi kalau "tikus lari sampai dia lelah" → "dia" = tikus

**Attention = cara model melakukan hal yang sama.** Menghitung bobot relevansi antar token secara dinamis berdasarkan konteks.

### Analogi: Database Retrieval

Bayangkan attention sebagai sistem query-key-value:

```
Query: "Siapa subjek dari kalimat ini?"
Keys: ["Kucing", "itu", "mengejar", "tikus", "sampai", "dia", "lelah"]
     → score: [0.4,  0.01,  0.3,  0.15, 0.01, 0.1,  0.03]

Hasil: weighted sum dari Values (yang == Keys di self-attention)
       → vektor representasi yang kaya konteks
```

---

## 3. Scaled Dot-Product Attention: Formula Inti

Ini adalah satu formula yang mengubah NLP selamanya:

```
Attention(Q, K, V) = softmax(Q · K^T / √dₖ) · V
```

### Komponen

| Simbol | Nama              | Bentuk          | Fungsi                                       |
| ------ | ----------------- | --------------- | -------------------------------------------- |
| Q      | Query             | (seq_len_q, dₖ) | Apa yang "ditanyakan" — token saat ini       |
| K      | Key               | (seq_len_k, dₖ) | "Indeks" dari semua token — untuk dicocokkan |
| V      | Value             | (seq_len_k, dv) | Informasi yang akan diambil                  |
| dₖ     | Dimensi key/query | skalar          | Scaling factor                               |

### Langkah demi Langkah

**Step 1: Hitung Compatibility (Q · K^T)**

```
score[i][j] = Q[i] · K[j]^T
→ dot product antara query ke-i dan key ke-j
→ Seberapa cocok token i dengan token j (relatif)
```

Bentuk: `(seq_len_q, seq_len_k)` — matriks attention.

**Step 2: Scale (÷ √dₖ)**

Kenapa di-scale? Untuk dimensi besar (dₖ=512+), dot product jadi besar secara proporsional. Softmax di region ekstrem punya gradien sangat kecil → training lambat.

```
scaled = score / √dₖ
```

Contoh: dₖ=512, dot product rata-rata ≈ 0, std ≈ √512 ≈ 22.6. Kalau gak di-scale, softmax-nya jadi almost one-hot → gradien mati.

**Step 3: Softmax (normalisasi)**

```
weights = softmax(scaled, dim=-1)
→ baris ke-i: distribusi probabilitas atas semua key
→ jumlah = 1
```

**Step 4: Weighted Sum**

```
output[i] = Σⱼ weights[i][j] · V[j]
→ vektor context untuk token ke-i
→ length = dv (biasanya = dₖ)
```

### Visualisasi Matriks Attention

```
Q·K^T/√d              softmax              output
┌──────┐   scale    ┌──────┐   row-wise   ┌──────┐
│ 0.8  │            │ 0.5  │   softmax    │ 0.3  │
│ -0.2 │            │ 0.2  │  ─────────▶  │ 0.4  │
│ 0.1  │            │ 0.3  │              │ 0.3  │
└──────┘            └──────┘              └──────┘
```

Baris = query, kolom = key. Semakin terang → semakin diperhatikan token key oleh token query.

---

## 4. Varian Attention

### 4.1 Self-Attention (Intra-Attention)

Q, K, V berasal dari **sequence yang sama**.

```
Input: "Kucing mengejar tikus"
Self-attention: setiap token "memperhatikan" semua token lain
→ "mengejar" → memperhatikan "kucing" (subjek) + "tikus" (objek)
```

Ini yang bikin BERT bisa memahami konteks bidirectional.

**Kapan self-attention gagal:** Gak punya informasi posisi inheren — butuh Positional Encoding tambahan.

### 4.2 Cross-Attention (Encoder-Decoder Attention)

Q dari decoder, K dan V dari encoder.

```
Encoder → "I love cats" → [k1, k2, k3, v1, v2, v3]
Decoder → [<sos>, "Aku"] → q1, q2
Attn(q2, K, V) → token "cats" paling berbobot → "cinta" berikutnya
```

Digunakan di:

- Seq2Seq Transformer (T5, BART)
- Image captioning (Q dari decoder text, KV dari encoder vision)
- Multimodal (LLaVA: Q dari teks, KV dari image encoder)

### 4.3 Multi-Head Attention

Satu attention head fokus ke satu aspek relasi. Multi-head = banyak perspektif:

```
MultiHead(Q,K,V) = concat(head₁,...,headₕ) · Wᴼ
dimana headᵢ = Attention(Q·WᵢQ, K·WᵢK, V·WᵢV)
```

| Head     | Fokus                                  |
| -------- | -------------------------------------- |
| Head 1   | Relasi sintaksis (subjek-verb)         |
| Head 2   | Relasi jarak jauh (pronoun-antecedent) |
| Head 3   | Relasi semantik (entitas-terkait)      |
| Head 4-8 | Mixed patterns                         |

**h=8 atau h=16** di model modern. Masing-masing head punya `dₖ = d_model / h`.

**Peringatan:** Interpretasi head attention harus hati-hati. Head gak selalu punya peran yang konsisten antar random seed. _Attention is not explanation_ (Jain & Wallace, 2019).

### 4.4 Causal / Masked Attention

Untuk **autoregressive decoding** (GPT, LLama):

```
Attention(Q,K,V) = softmax(Q·K^T/√dₖ + M) · V

M[i][j] = 0 jika j ≤ i (boleh lihat masa lalu)
        = -∞ jika j > i (dilarang lihat masa depan)
```

Ini yang memastikan model gak "mencontek" token yang belum di-generate.

### 4.5 Sparse Attention

Untuk sequence super panjang (>8K token), full O(n²) gak muat:

| Varian            | Pola                            | Kompleksitas | Model Contoh         |
| ----------------- | ------------------------------- | ------------ | -------------------- |
| Sliding Window    | Hanya tetangga ±w               | O(n·w)       | Longformer, Mistral  |
| Dilated Sliding   | Seperti CNN dilated             | O(n·w)       | Longformer           |
| Global+Sliding    | Token khusus punya akses global | O(n·w + n·g) | BigBird              |
| Strided Block     | Blok-blok lokal teratur         | O(n√n)       | Sparse Transformer   |
| Sinkhorn Sorting  | Sortir blok dulu                | O(n·k)       | Sinkhorn Transformer |
| ReLA (Recurrence) | Cache + sliding                 | O(n)         | RecurrentGemma       |

**Kapan sparse attention gagal:** Kalau informasi yang dibutuhkan lintas blok dan gak cukup dengan sliding window + global token. Contoh: reasoning multi-hop yang perlu referensi antar bab terpisah.

---

## 5. Positional Encoding

Self-attention **permutation-invariant**: urutan token gak berpengaruh. `"Kucing makan"` == `"makan Kucing"` secara matematis.

### Sinusoidal PE (Original Transformer)

```
PE(pos, 2i)   = sin(pos / 10000^(2i/d_model))
PE(pos, 2i+1) = cos(pos / 10000^(2i/d_model))
```

**Sifat unik:**

- Setiap posisi punya encoding unik
- Jarak relatif bisa di-generalize: `PE(pos+k)` linear function dari `PE(pos)`
- Gak perlu dipelajari — hanya 1 baris kode

### Relative Positional Encoding

Untuk generalization ke panjang sequence yang lebih panjang dari training:

- **RoPE (Rotary PE)**: Q, K di-rotate berdasarkan posisi — dipakai di Llama, Mistral, GPT-NeoX. Biaya tambahan minimal, ekstrak kemampuan length generalization.
- **ALiBi**: Tambah bias linear ke attention score berdasarkan jarak. Lebih simpel dari RoPE, tapi performanya sedikit lebih rendah di equivalen model size.
- **T5's Relative Bias**: Learned bias per posisi bucket — simpel, efektif.

```python
# RoPE pseudocode
def apply_rope(x, positions, d_model):
    # x: (batch, seq_len, n_heads, d_per_head)
    # Rotate pairs of dimensions
    cos = torch.cos(positions * theta)
    sin = torch.sin(positions * theta)
    x_rot = torch.stack([-x[..., 1::2], x[..., ::2]], dim=-1).reshape(x.shape)
    return x * cos + x_rot * sin
```

---

## 6. Kompleksitas: O(n²) — Masalah Utama

Alasan kenapa attention dominan tapi bermasalah:

| Arsitektur         | Kompleksitas per Layer | Memori per Layer (n=4096) |
| ------------------ | ---------------------- | ------------------------- |
| RNN                | O(n · d²)              | O(d) — linear             |
| CNN                | O(k · n · d)           | O(n · d)                  |
| Transformer (Full) | **O(n² · d)**          | **O(n²)** — 16M float     |
| Linear Attention   | O(n · d²)              | O(d²)                     |
| Sparse Attention   | O(n · w · d)           | O(n · w)                  |

Untuk n=100K (RAG context), full attention butuh 10M token matriks — mustahil.

### Optimasi untuk Long Context

| Teknik               | Cara                              | Model               |
| -------------------- | --------------------------------- | ------------------- |
| FlashAttention       | Tiling + kernel fusion GPU        | Semua model modern  |
| Ring Attention       | Distributed attention across GPUs | RingAttention paper |
| Strided/Block Sparse | Skip pattern                      | Mistral, Mixtral    |
| Context Caching      | Cache KV dari prompt              | Sistem RAG          |
| H2O (Heavy Hitter)   | Cache cuma top-k attention heads  | Quantization-aware  |

**FlashAttention** sendiri sudah jadi standar:

```
Standard: O(n²) HBM reads/writes → baca tulis matriks n×n dari VRAM
FlashAttention: O(n²) compute + O(n) HBM → tiling, gak pernah materialize matriks penuh
Result: 2-4x lebih cepat, VRAM 10-20x lebih hemat
```

---

## 7. Attention di Model Modern

### 7.1 Encoder-Only (BERT)

```
Input: [CLS] I love cats [SEP] Cats are great [SEP]
Attention: bidirectional — setiap token lihat semua
Output: [CLS] → klasifikasi kalimat
         Token lainnya → contextual embedding
```

- **Pre-training:** Masked LM + Next Sentence Prediction
- **Fine-tuning:** Klasifikasi, NER, QA, STS

### 7.2 Decoder-Only (GPT, Llama, Claude)

```
Input: "Kucing mengejar tikus karena →"
Kausal attention:
  "Kucing" → cuma lihat "Kucing"
  "mengejar" → lihat "Kucing mengejar"
  "tikus" → lihat "Kucing mengejar tikus"
  "karena" → lihat semua 4 token sebelumnya
→ prediksi token berikutnya
```

### 7.3 Encoder-Decoder (T5, BART)

```
Encoder (bidirectional):
  "The cat" → enriched representation
Cross-Attention (decoder → encoder):
  Decoder token → pilih encoder token yang relevan
Causal attention (decoder internal):
  Kayak GPT, autoregressive
```

### 7.4 Mixture of Experts (MoE)

MoE ganti FFN dengan multiple "expert" networks + router:

```
Input → router → softmax → top-2 experts → weighted sum
```

Attention layer tetap sama. Hanya FFN yang di-MoE-kan. Tapi karena routing butuh pemahaman konteks yang dalam, attention tetap kritis.

**Llama 405B**: 144 layer, 8 KV heads, GQA (Grouped Query Attention). MoE version (Mixtral 8x7B).

### 7.5 Mamba / State Space Models

Alternatif ke attention:

```
SSM: h' = A·h + B·x
     y  = C·h + D·x
```

- Kompleksitas: O(n) — linear, bukan O(n²)
- Seleksi (Mamba): B dan C tergantung input → dynamic selection
- **Kapan unggul:** Sequence sangat panjang (1M+ token) — inference murah
- **Kapan kalah:** Reasoning task — attention lebih baik untuk relasi jarak jauh

---

## 8. Konsep Lanjutan

### Attention Sink

Fenomena di LLM: token pertama (start token) dapet attention weight besar secara tidak proporsional. Ini terjadi karena softmax harus distribusikan probabilitas ke semua token, dan token pertama jadi "sink" — tempat pembuangan attention.

Fix: stabilkan dengan sink token khusus atau re-normalisasi.

### Key-Value (KV) Cache

Pas inference autoregressive:

```
Step 1: compute K1, V1 for token 1 → cache [K1, V1]
Step 2: compute K2, V2 for token 2 → cache [K1, K2, V1, V2]
Step n: reuse cache → compute cuma K_n, V_n
```

**Masalah:** KV cache buat 100K context = 100K × d_model × n_layers × 2 (K+V) × precision. Untuk Llama 70B dengan context 32K: ~12GB VRAM cuma buat KV cache.

**Solusi:**

- GQA (Grouped Query Attention): beberapa query head share 1 key/value head — dipakai di Llama 2 70B, Mistral
- MQA (Multi-Query Attention): semua query head share 1 key/value head — dipakai di Falcon, PaLM
- KV cache quantization: turunkan precision K/V jadi FP8/INT4
- Windowed cache: buang token lama (Mistral)

### Sparse MoE + Attention

Mixtral 8x7B: 46.7B parameter, tapi cuma 12.9B aktif per forward pass.

```
Attention: shared di semua expert
FFN: 8 experts → router pilih top-2 → weighted sum
```

Ini bikin model bisa besar tapi inference tetap efisien.

**Kapan MoE gagal**: Load balancing — kalau router selalu pilih expert yang sama, expert lain gak pernah belajar. Butuh auxiliary loss (load balancing loss) dengan koefisien kecil (~0.01).

---

## 9. Attention is All You Need — Dampak

Paper Vaswani et al. 2017 bukan cuma ngasih model baru — tapi **mengubah paradigma**:

| Sebelum Transformer        | Sesudah Transformer             |
| -------------------------- | ------------------------------- |
| RNN/LSTM untuk sequence    | Hanya attention                 |
| Training sequential 🐌     | Training parallel 🚀            |
| BERT (encoder-attention)   | GPT (decoder-attention)         |
| Transfer learning terbatas | Pre-train + fine-tune dominan   |
| NLP dominan                | Multimodal (ViT, CLIP, Whisper) |
| 100M parameter maks        | 1T+ parameter (MoE)             |

### Kenapa Transformer Menang?

1. **Parallelization**: RNN harus sequential per step. Attention: semua token diproses parallel → training 1000× lebih cepat.
2. **Long-range dependency**: Jarak dua token gak masalah — selalu O(1) hop, lawan RNN yang O(n).
3. **Skalabilitas**: Tambah data + parameter = performa naik reliably (scaling laws).

---

## 11. Full Transformer Architecture Walkthrough

### Encoder Stack

Each encoder layer = 2 sublayers:

1. Multi-Head Self-Attention (MHA)
2. Feed-Forward Network (FFN) — SwiGLU in modern models

```
x = LayerNorm(x + MHA(x, x, x))      # pre-LN
x = LayerNorm(x + FFN(x))
```

### Decoder Stack

Each decoder layer = 3 sublayers:

1. Masked Self-Attention (causal + padding mask)
2. Cross-Attention (Q from decoder, KV from encoder)
3. FFN

```
x = LayerNorm(x + MaskedMHA(x, x, x))
x = LayerNorm(x + CrossAttn(x, enc_K, enc_V))
x = LayerNorm(x + FFN(x))
```

### Dimension Flow (Base Transformer, d=512)

| Layer                 | Input → Output | Parameter Shape   | Count       |
| --------------------- | -------------- | ----------------- | ----------- |
| Embedding             | V × d_model    | (V, 512)          | 16M (V=32K) |
| MHA (8 heads, d_k=64) | 512→512        | 3×512×512+3 bias  | ~1.6M       |
| FFN (d_ff=2048)       | 512→2048→512   | 512×2048+2048×512 | ~3.1M       |
| LayerNorm             | 512→512        | 512×2 (affine)    | 1K          |
| Output proj           | 512→V          | (512, V)          | 16M         |

~65M parameters for base transformer. ~213M for large (d=1024). Llama 70B: d=8192, 80 layers, 64 heads.

### Pre-LN vs Post-LN

| Scheme             | Formula                      | Stability                   | Used By                |
| ------------------ | ---------------------------- | --------------------------- | ---------------------- |
| Post-LN (original) | x' = LN(x + Sublayer(x))     | Unstable, needs >20K warmup | Original Transformer   |
| Pre-LN             | x' = x + Sublayer(LN(x))     | Stable, 1-2K warmup         | GPT, BERT, Llama       |
| Sandwich norm      | LN(x + Sublayer(LN(x)))      | Very stable, ultra-deep     | DeepNet (>1000 layers) |
| Parallel attn+FFN  | x + Attn(LN(x)) + FFN(LN(x)) | Fast (15% speedup)          | PaLM                   |

### FFN Activation Comparison

| Activation | Formula               | Param Count       | Used In              |
| ---------- | --------------------- | ----------------- | -------------------- |
| ReLU       | max(0, xW)            | 2 weight matrices | Original Transformer |
| GELU       | x·Φ(x)                | 2 weight          | BERT, GPT-3          |
| SwiGLU     | Swish(xW1) ⊗ xW3 × W2 | **3** weight      | Llama, Mistral, PaLM |
| ReGLU      | ReLU(xW1) ⊗ xW3 × W2  | 3 weight          | T5                   |
| GeGLU      | GELU(xW1) ⊗ xW3 × W2  | 3 weight          | PaLM                 |

SwiGLU (Llama, Mistral) uses 3 weight matrices — d_ff = 8/3·d_model instead of 4·d_model. Equal parameter count but better performance than ReLU/GELU.

---

## 12. GQA vs MQA — KV Cache Optimization

### Motivation

In autoregressive inference, KV cache stores key-value pairs for every token:

- MHA (standard): KV cache = 2 × n_layers × n_heads × d_k × seq_len × precision
- For Llama 70B, 32K context: ~107 GB for KV cache alone (FP16)

### MQA (Multi-Query Attention)

All query heads share 1 KV head:

- KV cache: 1/n_heads of MHA → ~1.7 GB for same setup
- Quality: -2% perplexity penalty — noticeable but acceptable

### GQA (Grouped Query Attention)

Compromise: divide query heads into groups, each group shares 1 KV head:

- KV cache: n_groups / n_heads of MHA
- Quality: -0.5% perplexity penalty — almost lossless

```
MHA:    Q0 Q1 Q2 Q3 | Q4 Q5 Q6 Q7 → K0 K1 K2 K3 K4 K5 K6 K7 (8 KV heads)
GQA-4:  Q0 Q1 Q2 Q3 | Q4 Q5 Q6 Q7 → K0 K1 K2 K3              (4 KV heads)
GQA-2:  Q0 Q1 Q2 Q3 | Q4 Q5 Q6 Q7 → K0 K1                    (2 KV heads)
MQA:    Q0 Q1 Q2 Q3 | Q4 Q5 Q6 Q7 → K0                        (1 KV head)
```

### Implementation

```python
# GQA: expand KV heads to match Q heads
n_groups = n_heads // n_kv_heads
K = K.repeat_interleave(n_groups, dim=1)
V = V.repeat_interleave(n_groups, dim=1)
# Now shapes match for standard attention computation
```

---

## 13. FlashAttention — How It Works

### The IO Problem

Standard attention:

1. Read Q, K from HBM (high bandwidth memory, ~1.5 TB/s on A100)
2. Compute S = QK^T → write S to HBM (O(n²) writes)
3. Read S from HBM → softmax → write P to HBM
4. Read P, V from HBM → compute P·V → write O to HBM

**Total HBM access: O(n² + n·d)** — dominated by O(n²) for large sequences.

### FlashAttention Solution: Tiling + Online Softmax

1. **Tiling:** Split Q, K, V into blocks that fit in SRAM (192 KB on A100)
2. **Per-block computation:** Load block → compute partial attention → update output
3. **Online softmax rescaling:** Softmax normally needs all scores. FlashAttention tracks running max and sum to avoid materializing the full matrix:

```
for block:
    S = Q_block @ K_block^T
    m_new = max(m_old, row_max(S))
    P = exp(S - m_new)
    l_new = exp(m_old - m_new) * l_old + row_sum(P)
    O = (l_old / l_new) * O + (P @ V_block) / l_new
```

**Result: O(n²·d) compute with O(n·d) HBM accesses.** No full attention matrix ever materialized.

### Performance (A100, n=8192)

| Method              | Time (ms) | VRAM (GB)    | Speedup |
| ------------------- | --------- | ------------ | ------- |
| Standard            | 67        | 2.0 (just S) | 1×      |
| FlashAttn v1        | 27        | 0.1          | 2.5×    |
| FlashAttn v2        | 21        | 0.05         | 3.2×    |
| FlashAttn v3 (H100) | 8         | 0.02         | 8.4×    |

---

## 14. Position Encoding — Deep Comparison

### Why Position Matters

Self-attention is permutation-invariant — "cat eats mouse" == "mouse eats cat" without positional info.

### Sinusoidal PE (Original Transformer)

```
PE(pos, 2i)   = sin(pos / 10000^(2i/d))
PE(pos, 2i+1) = cos(pos / 10000^(2i/d))
```

Properties:

- Each position has unique encoding
- Relative: PE(pos+k) = linear function of PE(pos)
- No learned parameters

### RoPE (Rotary Position Embedding)

Applied to Q and K vectors before attention — not added:

```
q_rotated = RoPE(q, pos)     # rotate per dimension pair
k_rotated = RoPE(k, pos')
score = q_rotated · k_rotated  # depends only on (pos - pos')
```

Advantages:

- **Relative positioning** — score depends on distance, not absolute position
- **Extrapolatable** — can extend to longer sequences (with NTK-aware scaling)
- **Zero inference overhead** — applied once during KV computation

### ALiBi (Attention with Linear Biases)

```python
score(i,j) = q_i · k_j - m · |i - j|
# m = slope per head (geometric: 1/2, 1/4, 1/8, ...)
```

Simplest method. Best extrapolation. Used in some training-efficient models.

### Comparison Matrix

| Method           | Type          | Learned Params   | Extrapolation   | Compute Overhead | Used By               |
| ---------------- | ------------- | ---------------- | --------------- | ---------------- | --------------------- |
| Sinusoidal       | Absolute      | 0                | Poor            | None             | Original Transformer  |
| Learned absolute | Absolute      | O(n)             | None            | None             | BERT                  |
| Learned relative | Relative bias | O(n)             | Limited         | Minimal          | T5                    |
| RoPE             | Relative      | 0 (freq fixed)   | Good (with NTK) | Minimal          | Llama, Mistral, GPT-4 |
| ALiBi            | Relative bias | 0 (slopes fixed) | Excellent       | Minimal          | BLOOM, MPT            |
| xPos             | Relative      | 0                | Good            | Same as RoPE     | Some research         |

### NTK-Aware Scaling / YaRN

Problem: RoPE trained at 4K context → used at 32K. Rotation frequencies too fast at long positions → loss of discrimination.

Solutions:

1. **NTK-aware:** Scale frequency base (10000 → 10000×α) for high frequencies → slower rotation
2. **YaRN:** NTK scaling + attention temperature scaling
3. **Position interpolation:** Map new positions into old range (but loses position resolution)

YaRN recipe: α = (L_new / L_train) × (d / (d-2))

---

## 15. KV Cache Quantization

KV cache is the bottleneck for long-context inference.

### INT8 Quantization

```python
scale = K.abs().max(dim=-1, keepdim=True)[0] / 127.0
K_int8 = (K / scale).round().clamp(-128, 127).to(torch.int8)
# At inference: dequantize to FP16 for attention compute
K_fp16 = K_int8.to(torch.float16) * scale
```

### Compression Ratios

| Method      | Bits     | Ratio vs FP16 | Quality Impact    | Hardware Support     |
| ----------- | -------- | ------------- | ----------------- | -------------------- |
| FP16        | 16       | 1×            | None              | All                  |
| INT8        | 8        | 2×            | Negligible        | All                  |
| FP8         | 8        | 2×            | Negligible        | H100 native          |
| INT4        | 4        | 4×            | Small (+0.3 ppl)  | Requires dequant     |
| NF4         | 4        | 4×            | Minimal           | QLoRA-style          |
| KIVI 2-bit  | 2        | 8×            | Moderate (+1 ppl) | Research             |
| KV sparsity | variable | 2-10×         | Depends           | Attention sink based |

### Attention Sink + Window

Observation: initial tokens (attention sinks) get disproportionate attention weight. KV cache can drop:

- Non-sink tokens in the middle
- Keep first N (sink) + last M (window) tokens
- StreamingLLM: drop everything except sink + recent window

---

## 16. Long Context Training

### Scaling to 32K-128K

| Method                 | Base | Extended | Training Tokens | Quality   |
| ---------------------- | ---- | -------- | --------------- | --------- |
| Position Interpolation | 2K   | 8K       | 10B             | Retains   |
| NTK-aware              | 2K   | 32K      | 1B              | Good      |
| YaRN                   | 4K   | 128K     | 500M            | Excellent |
| Linear scaling         | 4K   | 32K      | 500M            | Moderate  |

### Data Requirements

Long context training needs data with genuine long-range dependencies:

- Books (PG-19, BookCorpus) — narrative coherence >10K tokens
- Code repositories — inter-function dependencies
- Math proofs (ProofPile) — multi-step reasoning
- Legal documents — cross-references across sections

### Ring Attention

Distribute sequence across multiple GPUs — each GPU holds a chunk, attention computed over all chunks via ring communication. Effective for 1M+ token contexts.

---

## 17. Mixture of Experts (MoE) — Production Details

### Routing Mechanism

```python
logits = router(x)  # (batch, seq, n_experts)
weights = softmax(logits, dim=-1)
top_k_weights, top_k_idx = weights.topk(k=2, dim=-1)

# Gather + compute
output = zeros_like(x)
for i, expert in enumerate(expert_list):
    mask = (top_k_idx == i).any(dim=-1)
    if mask.any():
        output[mask] = expert(x[mask])
```

### Load Balancing

Auxiliary loss prevents router collapse (all tokens to 1 expert):

```
L_balance = α · n_experts · Σᵢ (f_i · P_i)
```

f_i = fraction of tokens to expert i, P_i = average router probability for expert i.
α=0.01 typical.

### Capacity Factor

capacity = ceil(cf × tokens_per_batch / n_experts)

| cf       | Effect                           | Best For                    |
| -------- | -------------------------------- | --------------------------- |
| 1.0~1.25 | Efficient compute, risk overflow | Training with large batches |
| 1.5~2.0  | Waste compute, safe              | Inference, variable length  |

**Overflow:** tokens that exceed capacity are discarded (output = input). In practice, <1% overflow at cf=1.25.

### Expert Parallelism

Distribute experts across GPUs: each GPU has subset of experts. Tokens routed to appropriate GPU via all-to-all communication.

---

## 18. Sparse Attention Family

### Computation-Proximity Tradeoff

| Method              | Complexity   | Effective Range      | Used By             |
| ------------------- | ------------ | -------------------- | ------------------- |
| Full attention      | O(n²)        | Unlimited            | GPT-4 (partially)   |
| Sliding window (±w) | O(n·w)       | w=4096               | Mistral, Longformer |
| Dilated sliding     | O(n·w)       | w×dilation           | Longformer          |
| Global tokens       | O(n·w + n·g) | Unlimited via global | BigBird, Longformer |
| Strided/block       | O(n√n)       | Block-aligned        | Sparse Transformer  |
| Sink + window       | O(n·w)       | w + initial N        | StreamingLLM        |

### Mistral's Sliding Window

Mistral uses sliding window attention with w=4096 for each layer. But with 32 layers, effective receptive field = w × n_layers = 4096 × 32 = 128K:

- Layer 1: sees 4K tokens
- Layer 2: sees 4K of layer 1 output (already contextualized) → sees 8K indirectly
- Layer 32: sees 128K tokens

This makes sliding window effectively global for deep models.

### Sparse Attention Failure Modes

1. Cross-block dependencies: if info needed is in a far block not covered by window/global tokens, model fails.
2. Long-range coreference: "the defendant mentioned in Section 3.1.2" — if section is outside window, fails.
3. Multi-hop reasoning: requires spanning multiple non-adjacent regions simultaneously.

---

## 19. Training Diagnostics & Best Practices

### Hyperparameter Defaults

| Model        | d_model | n_layers | n_heads | d_ff  | LR   | Batch (tokens) | Warmup |
| ------------ | ------- | -------- | ------- | ----- | ---- | -------------- | ------ |
| Base (65M)   | 512     | 6        | 8       | 2048  | 3e-4 | 32K            | 2K     |
| Large (350M) | 1024    | 12       | 16      | 4096  | 1e-4 | 64K            | 4K     |
| Llama 3 8B   | 4096    | 32       | 32      | 11008 | 3e-5 | 4M             | 2K     |
| Llama 3 70B  | 8192    | 80       | 64      | 28672 | 3e-5 | 4M             | 20K    |

### Common Training Failures

| Symptom                       | Cause                               | Fix                               |
| ----------------------------- | ----------------------------------- | --------------------------------- |
| Loss → NaN in first 100 steps | High LR + no warmup                 | Add warmup, reduce LR             |
| Slow convergence              | Attention logit scale wrong         | Check √d_k scaling                |
| Attention entropy collapse    | All attention focused on 1-2 tokens | Add regularization, dropout       |
| Excessive memory              | KV cache blowup                     | GQA, FlashAttention, quantization |
| Poor length generalization    | PE not designed for long context    | YaRN/NTK scaling                  |

### Implementation Checklist

- [ ] √d_k scaling correct (not √d_model)
- [ ] RoPE frequencies computed in float32 (numerical stability)
- [ ] Causal mask prevents cross-batch attention (batch × head × seq × seq)
- [ ] FlashAttention enabled (to avoid O(n²) memory)
- [ ] KV cache reset between sequences (don't leak across examples)
- [ ] Attention mask properly handles padding tokens (don't attend to PAD)

### Multi-Token Prediction (MTP)

Alternative to next-token prediction: predict next N tokens simultaneously.

**How it works:**

- Each block has N output heads, each predicting one future token
- Loss = Σ loss(t+n) for n=1..N
- Training: all N predictions supervised
- Inference: only first prediction used (or can branch)

**Why it matters for attention:**

- Forces attention to plan ahead — not just local pattern matching
- Improves long-range attention coherence
- Used in Llama 4, GPT-5 rumored

**Tradeoff:** N=2 gives ~2% ppl improvement, N>4 gives diminishing returns. Compute overhead: ~N× LM head cost.

### Attention in Vision: Vit, DETR

Vision Transformer (ViT) applies self-attention to image patches:

- Image → 16×16 patches → linear projection → positional encoding → transformer
- Patch embeddings treat as token sequence
- Classification via [CLS] token

**Why vision attention works:**

- Global receptive field from layer 1 (CNN needs 30+ layers)
- Flexible to different input sizes (with proper PE)
- Scales with compute (scaling laws apply)

**Key differences:**

- Patches are 2D → need 2D position encoding
- Higher resolution = quadratic blowup in tokens
- Swin Transformer: local windows + shifted windows to reduce O(n²)

### Concise Reference Table: All Attention Variants

| Variant           | Complexity | Params | Context Length | KV Cache     | Best For                 |
| ----------------- | ---------- | ------ | -------------- | ------------ | ------------------------ |
| Full MHA          | O(n²·d)    | 4d²    | Unlimited      | 2·n·h·dₖ     | Quality-first, short ctx |
| Multi-Query (MQA) | O(n²·d)    | ~3d²   | Unlimited      | 2·n·1·dₖ     | Fast inference           |
| GQA (8 groups)    | O(n²·d)    | ~3.5d² | Unlimited      | 2·n·g·dₖ     | Balanced                 |
| Sliding Window    | O(n·w·d)   | 4d²    | w·layers       | 2·w·h·dₖ     | Long docs                |
| Linear Attention  | O(n·d²)    | 4d²    | Unlimited      | None         | Extreme length           |
| FlashAttention    | O(n²·d)    | 4d²    | Unlimited      | None (tiled) | All modern training      |
| Sparse (Strided)  | O(n√n·d)   | 4d²    | Unlimited      | 2·√n·h·dₖ    | Mid-length, efficient    |

- [ ] Weight init: variance scaling per layer (not uniform)
- [ ] Gradient clipping: max_norm=1.0

### Transformer Scaling Laws Summary

Key insights from Kaplan et al. 2020 and Hoffmann et al. 2022 (Chinchilla):

1. **Compute-optimal training:** For a given compute budget C, optimal allocation:
   - Model size N* = C^0.5 (Kaplan) or C^0.46 (Chinchilla)
   - Token count D* = C^0.5 (Kaplan) or C^0.54 (Chinchilla)
   - Chinchilla: models should be trained on ~20× model parameters in tokens

2. **Attention vs FFN scaling:**
   - d_model grows as √(compute)
   - n_layers grows slightly faster
   - n_heads proportional to d_model
   - d_ff ≈ 3.5-4 × d_model (SwiGLU: 8/3 × d_model)

3. **Critical batch size =** `B_critical ≈ 1e6 / (LR)` — batch > critical: efficient but not compute-optimal

4. **Optimal LR for transformer:**
   - AdamW: 3e-4 × (d_model/512)^(-0.5)
   - Weight decay: 0.1
   - β₁=0.9, β₂=0.95

---

## 20. The Road Beyond Attention

### Mamba / State Space Models

```
ht = A·ht-1 + B·xt
yt = C·ht + D·xt
```

- Complexity: O(n) — linear in sequence length
- Selection mechanism: B and C depend on input → dynamic
- **Outperforms:** Long-context retrieval, large-batch generation
- **Struggles:** Multi-step reasoning, in-context learning (vs attention)

### Hybrid Architectures (Jamba, Mamba-Transformer)

Use attention for some layers (every 4th or 8th), Mamba for others:

```
Layer 1-3: Mamba (efficient)
Layer 4: Attention (long-range reasoning)
Layer 5-7: Mamba
Layer 8: Attention
```

Best of both: 3× throughput with 95%+ of pure attention quality.

### Linear Attention

Replace softmax attention with kernel trick:

```
Attention(Q,K,V) = φ(Q) · φ(K)^T · V
```

where φ is a feature map (e.g., elu+1).

Complexity O(n), but quality lags behind softmax for complex reasoning.

---

## 21. Cognitive Pathway

Baca juga:

- [[backpropagation-deepdive]] — gradien attention mengalir lewat softmax + QKV projections
- [[cosine-similarity-deepdive]] — dot product dalam attention = unnormalized cosine
- [[llm-wiki]] — aplikasi attention di LLM skala besar
- [[rnn-lstm-vs-transformer]] — perbandingan arsitektur (kalau ada)

---

## Referensi

- Vaswani, A. et al. (2017). _Attention Is All You Need._ NeurIPS. — **Paper paling berpengaruh di era deep learning modern.**
- Devlin, J. et al. (2019). _BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding._ NAACL. — Encoder-only attention.
- Brown, T.B. et al. (2020). _Language Models are Few-Shot Learners._ NeurIPS. — Decoder-only scaling laws, GPT-3.
- Bahdanau, D. et al. (2015). _Neural Machine Translation by Jointly Learning to Align and Translate._ ICLR. — Attention orisinal.
- Dao, T. et al. (2022). _FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness._ NeurIPS. — GPU optimization standar.
- Gu, A., Dao, T. (2023). _Mamba: Linear-Time Sequence Modeling with Selective State Spaces._ — Alternatif tanpa attention.
- Raffel, C. et al. (2020). _Exploring the Limits of Transfer Learning with a Unified Text-to-Text Transformer._ JMLR. — T5: encoder-decoder + MoE scaling.
- Shazeer, N. (2020). _GLU Variants Improve Transformer._ — SwiGLU activation, dipakai Llama.
- Su, J. et al. (2024). _RoFormer: Enhanced Transformer with Rotary Position Embedding._ — RoPE, standar posisi encoding modern.
- Fedus, W. et al. (2022). _Switch Transformers: Scaling to Trillion Parameter Models with Simple and Efficient Sparsity._ JMLR. — MoE di Transformer.
