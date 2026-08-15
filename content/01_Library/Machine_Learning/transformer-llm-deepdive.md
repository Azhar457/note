---
title: "Transformer and LLM Architecture Deep-Dive \u2014 Attention Optimization,\
  \ RoPE, and Inference Mechanics"
tags:
- machine-learning
- transformer
- llm
- deep-learning
- rope
- inference-optimization
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
- callout
---

| Item | Detail |
|------|--------|
| **Summary** | Deep-dive arsitektur Transformer: taksonomi encoder/decoder, anatomi decoder-only, RoPE, MQA/GQA/FlashAttention, KV cache & mekanisme inference. |



[[00_Atlas/hierarchy-llm-ai-systems]] [[00_Atlas/hierarchy-classical-ml-algorithms]] [[about]]

> [!abstract] Ringkasan & Hubungan ke Vault
> Arsitektur Transformer adalah tulang punggung dari seluruh Large Language Model (LLM) modern. Catatan ini membedah arsitektur internal Transformer *decoder-only* tingkat lanjut, inovasi pengodean posisi (RoPE), taktik optimasi komputasi attention (GQA, FlashAttention), serta efisiensi eksekusi (*inference*) melalui KV Cache, melengkapi [[llm-wiki]] dan [[attention-mechanism-roadmap]].

## Daftar Isi

1. [Taksonomi Arsitektur Transformer](#1-taksonomi-arsitektur-transformer)
2. [Anatomi Blok Decoder-Only Kontemporer](#2-anatomi-blok-decoder-only-kontemporer)
3. [Pengodean Posisi: RoPE (Rotary Position Embedding)](#3-pengodean-posisi-rope-rotary-position-embedding)
4. [Optimasi Komputasi Attention: MQA, GQA, dan FlashAttention](#4-optimasi-komputasi-attention-mqa-gqa-dan-flashattention)
5. [Mekanisme Inference & KV Cache](#5-mekanisme-inference--kv-cache)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Taksonomi Arsitektur Transformer

Arsitektur asli Transformer (Vaswani et al., 2017) menggunakan struktur Encoder-Decoder. Namun, evolusi model bahasa raksasa memecahnya menjadi tiga variasi utama:

1. **Encoder-Only (BERT-style)**: Menggunakan self-attention dua arah (*bidirectional attention*) untuk memahami konteks kalimat secara penuh. Sangat baik untuk tugas klasifikasi teks dan ekstraksi informasi.
2. **Decoder-Only (GPT-style)**: Menggunakan causal mask (hanya melihat token sebelumnya) untuk menghasilkan token baru secara autoregresif. Merupakan standar *de facto* untuk LLM generator teks masa kini.
3. **Encoder-Decoder (T5/BART-style)**: Encoder membaca konteks input dan Decoder menghasilkan output. Sangat efisien untuk tugas penerjemahan bahasa atau ringkasan dokumen.

---

## 2. Anatomi Blok Decoder-Only Kontemporer

Berikut adalah skema struktural satu blok layer LLM modern (mengikuti konfigurasi LLaMA/Gemma):

```
                       Input Token Vector (x)
                                 │
         ┌───────────────────────┴───────────────────────┐
         │                                               ▼
         │                                            RMSNorm
         │                                               │
         │                                       Self-Attention (GQA)
         │                                               │
         │                                        Linear Projection
         │                                               │
         ▼                                               ▼
     Residu (+) ◀────────────────────────────────────────┘
         │
         ├───────────────────────┬───────────────────────┐
         │                                               ▼
         │                                            RMSNorm
         │                                               │
         │                                         MLP / SwiGLU
         │                                               │
         ▼                                               ▼
     Residu (+) ◀────────────────────────────────────────┘
         │
         ▼ Output ke Layer Berikutnya
```

### 2.1 Peningkatan Komponen Utama
- **RMSNorm (Root Mean Square Normalization)**: Menggantikan LayerNorm standar untuk mempercepat latihan model sebesar 10-50% tanpa degradasi kualitas dengan membuang perhitungan rata-rata (*mean estimation*):
  $$\text{RMSNorm}(x_i) = \frac{x_i}{\sqrt{\frac{1}{d} \sum_{j=1}^{d} x_j^2 + \epsilon}} \cdot \gamma_i$$
- **SwiGLU Activation**: Menggantikan aktivasi GeLU klasik pada lapisan FFN untuk meningkatkan kemampuan representasi non-linear model.

---

## 3. Pengodean Posisi: RoPE (Rotary Position Embedding)

Untuk mempertahankan informasi urutan kata tanpa batasan panjang sekuens kaku seperti pada *absolute position embedding*, LLM modern menggunakan **RoPE**.

### 3.1 Konsep Matematika RoPE
RoPE menerapkan rotasi geometris pada representasi 2D dari Query ($q$) dan Key ($k$) di ruang kompleks berdasarkan indeks posisi token $m$:

$$R_{\Theta, m}^d = \text{diag}\left( R_{\theta_1, m}, R_{\theta_2, m}, \dots, R_{\theta_{d/2}, m} \right)$$
Dimana sub-matriks rotasi 2D didefinisikan sebagai:
$$R_{\theta_i, m} = \begin{pmatrix} \cos(m\theta_i) & -\sin(m\theta_i) \\ \sin(m\theta_i) & \cos(m\theta_i) \end{pmatrix}$$

**Keunggulan**: Hasil dot-product $(R_m q) \cdot (R_n k)^T$ hanya bergantung pada jarak relatif antar-token ($m - n$), bukan posisi absolutnya. Hal ini memungkinkan model diekstrapolasi untuk memproses konteks yang jauh lebih panjang selama masa eksekusi (*context length extrapolation*).

---

## 4. Optimasi Komputasi Attention: MQA, GQA, dan FlashAttention

Komputasi attention orisinal membutuhkan alokasi memori yang sangat besar. Berikut adalah teknik optimasi utama:

```
Multi-Head Attention (MHA)     Grouped-Query Attention (GQA)     Multi-Query Attention (MQA)
    Q Q Q Q Q Q Q Q                 Q Q Q Q Q Q Q Q                 Q Q Q Q Q Q Q Q
    │ │ │ │ │ │ │ │                 └──┬──┘ └──┬──┘                 └──────┬──────┘
    ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼                    ▼       ▼                           ▼
    K K K K K K K K                    K       K                           K
    V V V V V V V V                    V       V                           V
 (1 Head Q : 1 Head K/V)        (Group Q : 1 Head K/V)           (All Q : 1 Head K/V)
```

1. **MQA (Multi-Query Attention)**: Seluruh kepala query ($Q$) berbagi satu pasang kepala Key ($K$) dan Value ($V$). 
   - *Hasil*: Mengurangi konsumsi memori KV Cache secara drastis saat eksekusi (*inference*), namun sedikit menurunkan akurasi penalaran model.
2. **GQA (Grouped-Query Attention)**: Kompromi terbaik antara MHA dan MQA. Kepala query dikelompokkan (misal: 8 head Q berbagi 1 head K/V). LLaMA 3 menggunakan GQA.
3. **FlashAttention**: Mengeliminasi kebutuhan menulis dan membaca matriks attention berukuran $N \times N$ yang sangat besar dari VRAM GPU lambat (High Bandwidth Memory - HBM) ke memori register GPU cepat (SRAM) dengan membagi komputasi softmax menjadi blok-blok kecil (*tiling*).

---

## 5. Mekanisme Inference & KV Cache

Proses generasi teks pada LLM bersifat autoregresif: untuk menebak token berikutnya, model memproses ulang seluruh sequence sebelumnya.

### 5.1 KV Cache (Key-Value Cache)
Untuk menghindari kalkulasi ulang matriks $K$ dan $V$ dari token lama yang sudah diproses pada setiap iterasi komputasi forward-pass, nilai vektor Key dan Value dari token terdahulu disimpan dalam memori RAM GPU (**KV Cache**).

- Tanpa KV Cache: Kompleksitas komputasi generasi token bertumbuh secara kuadratis $O(N^2)$.
- Dengan KV Cache: Kompleksitas ditekan menjadi linear $O(N)$.
- **Masalah Baru**: KV Cache memakan ruang VRAM yang sangat besar pada batching tingkat tinggi, mendorong penggunaan teknik optimasi layout memori dinamis seperti **PagedAttention** (digunakan pada engine vLLM).

---

## 6. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[attention-mechanism-roadmap]] | Panduan praktis pengkodean blok Multi-Head Attention tingkat dasar. |
| [[rnn-lstm-vs-transformer]] | Analisis komparatif performa Transformer vs arsitektur rekurensi/SSM Mamba. |
| [[llmops-ai-infrastructure]] | Panduan orkestrasi model dan deployment LLM menggunakan framework vLLM/Ollama. |
| [[llm-wiki]] | Gambaran ringkas awal sejarah dan konsep pemodelan bahasa besar. |



> [!callout] 💡
> Evolusi LLM = kompresi biaya compute: RoPE untuk konteks panjang, GQA & FlashAttention untuk menyusutkan memori attention — optimasi inference adalah kunci deployment.
---

audited
---
