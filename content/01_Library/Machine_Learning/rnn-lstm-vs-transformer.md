---
title: RNN-LSTM vs Transformer — Architecture and Sequence Modeling Comparison
tags:
- machine-learning
- deep-learning
- transformer
- lstm
- rnn
- mamba
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Perkembangan arsitektur pemodelan sekuensial (*sequence modeling*) mengalami lompatan paradigma yang sangat besar sejak penemuan self-attention. Catatan ini membedah perbandingan arsitektur Rekurensi (RNN/LSTM), Paralelisme (Transformer), dan arsitektur hibrida/State Space Model modern (Mamba), melengkapi pembahasan [[attention-mechanism-deepdive]].

## Daftar Isi

1. [Perbedaan Paradigma Pemrosesan](#1-perbedaan-paradigma-pemrosesan)
2. [Matematika Rekurensi vs Self-Attention](#2-matematika-rekurensi-vs-self-attention)
3. [Kelemahan Kapasitas: Bottleneck Memori & Komputasi](#3-kelemahan-kapasitas-bottleneck-memori--komputasi)
4. [Arsitektur Hibrida Modern (Mamba & RWKV)](#4-arsitektur-hibrida-modern-mamba--rwkv)
5. [Matriks Perbandingan Rekayasa Sistem](#5-matriks-perbandingan-rekayasa-sistem)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Perbedaan Paradigma Pemrosesan

Model sekuensial bertugas memetakan input runtun waktu (*time-series* atau teks) ke dalam representasi vektor kontekstual. Cara kedua arsitektur menangani aliran informasi ini sangat bertolak belakang:

- **RNN / LSTM**: Memproses token satu demi satu secara sekuensial. Untuk membaca token ke-$t$, model wajib menunggu kalkulasi *hidden state* dari token ke-$t-1$. Hal ini membatasi pemanfaatan paralelisme kartu grafis (GPU).
- **Transformer**: Memproses seluruh token secara bersamaan (*fully parallel*) dalam satu langkah komputasi matriks raksasa, mengabaikan batasan waktu melalui *positional encoding*.

---

## 2. Matematika Rekurensi vs Self-Attention

### 2.1 Aliran Komputasi LSTM (Long Short-Term Memory)
LSTM menggunakan mekanisme gerbang (*gates*) untuk mengatur aliran informasi di dalam *cell state* ($c_t$) dan *hidden state* ($h_t$):

$$f_t = \sigma(W_f \cdot [h_{t-1}, x_t] + b_f) \quad \text{(Forget Gate - menentukan apa yang dibuang)}$$
$$i_t = \sigma(W_i \cdot [h_{t-1}, x_t] + b_i) \quad \text{(Input Gate - menentukan informasi baru yang disimpan)}$$
$$\tilde{c}_t = \tanh(W_c \cdot [h_{t-1}, x_t] + b_c) \quad \text{(Kandidat Cell State baru)}$$
$$c_t = f_t \odot c_{t-1} + i_t \odot \tilde{c}_t \quad \text{(Pembaruan Cell State secara linear)}$$
$$o_t = \sigma(W_o \cdot [h_{t-1}, x_t] + b_o) \quad \text{(Output Gate)}$$
$$h_t = o_t \odot \tanh(c_t) \quad \text{(Hidden State akhir)}$$

*Sifat*: Komputasi ini bersifat berantai sekuensial dengan kompleksitas waktu $O(N)$ langkah berurutan untuk panjang sekuens $N$.

### 2.2 Aliran Komputasi Transformer Self-Attention
Transformer membuang seluruh rekurensi dan menggunakan perkalian matriks dot-product paralel:

$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{Q \cdot K^T}{\sqrt{d_k}}\right) \cdot V$$

Dimana matriks $Q, K, V$ dihasilkan secara instan dari seluruh sequence input melalui perkalian bobot proyeksi paralel:
$$Q = XW_Q, \quad K = XW_K, \quad V = XW_V$$

*Sifat*: Komputasi ini berjalan secara $O(1)$ langkah waktu paralel pada GPU, namun membutuhkan memori kuadratis $O(N^2)$ untuk menyimpan matriks kecocokan attention.

---

## 3. Kelemahan Kapasitas: Bottleneck Memori & Komputasi

### 3.1 LSTM: Cell State Bottleneck (Vanishing/Exploding Gradient)
Meskipun LSTM memiliki *forget gate* untuk menjaga informasi jarak jauh, seluruh informasi masa lalu dipaksa untuk masuk ke dalam vektor dimensi tetap ($c_t$). Untuk sequence yang sangat panjang (>1000 token), detail mikroskopis di awal kalimat pasti akan terkikis dan hilang (*lossy compression*).

### 3.2 Transformer: O(N²) Memory Wall
Karena setiap token harus menghitung kecocokan dengan seluruh token lainnya di dalam sequence, penyimpanan matriks skor attention berukuran $N \times N$ membengkak secara kuadratis. Pada sequence sepanjang 100K token, komputasi ini menuntut alokasi VRAM GPU yang sangat ekstrem, membatasi panjang input *context window*.

---

## 4. Arsitektur Hibrida Modern (Mamba & RWKV)

Untuk menyelesaikan dilema "Paralel saat training (seperti Transformer) tapi hemat VRAM saat inference (seperti RNN)", komunitas mengembangkan arsitektur sub-linear/linear:

### 4.1 Mamba (State Space Model - SSM)
Mamba menggunakan formulasi *Selective State Space Model*. Ia membiarkan parameter transisi matriks bergantung pada konten input ($B(x), C(x)$) untuk mempertahankan memori selektif yang dinamis. 
- **Training**: Menggunakan formulasi asosiatif paralel (*parallel scan*) sehingga dapat dilatih secepat Transformer pada GPU.
- **Inference**: Menggunakan formulasi rekurensi linear $O(1)$ memori cache, sehingga sangat hemat VRAM dan cepat saat melakukan streaming generasi token.

### 4.2 RWKV (Receptive Weighted Key Value)
RWKV merumuskan ulang mekanisme attention menjadi formulasi RNN linear yang stabil secara numerik menggunakan bobot eksponensial waktu:
- Menawarkan kecepatan komputasi paralel linear saat latihan, tetapi bertindak sebagai RNN murni saat eksekusi model.

---

## 5. Matriks Perbandingan Rekayasa Sistem

| Karakteristik | RNN / LSTM | Transformer | Mamba (SSM) |
|---|---|---|---|
| **Kompleksitas Training** | $O(N)$ (Sekuensial) | **$O(1)$** (Paralel penuh) | **$O(1)$** (Parallel scan) |
| **Kompleksitas Memori (Inference)** | **$O(1)$** (Fixed state size) | $O(N^2)$ (KV Cache grows) | **$O(1)$** (Fixed state cache) |
| **Kemampuan Kontekstual Jauh** | Buruk (Kualitas menurun tajam) | **Luar Biasa** (Akses instan) | **Sangat Baik** (Hampir tanpa penurunan) |
| **Memory Footprint pada Edge Device**| **Sangat Kecil** | Besar (Membutuhkan optimasi GQA/Quantization) | **Kecil** |
| **Hardware Utilization (GPU)** | Rendah (Gagal melakukan saturasi tensor cores) | **Sangat Tinggi** (Sangat cocok untuk GPU) | **Tinggi** |

---

## 6. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[attention-mechanism-deepdive]] | Penjelasan formula dasar matematika dan jenis-jenis attention yang dibandingkan di sini. |
| [[meta-agent-orchestration]] | Pemilihan model dasar (backbone) untuk kebutuhan latency low-edge device. |
| [[unified-threat-ontology]] | Pemanfaatan model sekuensial untuk mendeteksi runtun waktu serangan (Layer 4/Transport network traffic analysis). |


## 5. Deepdive — Kapan Memilih Arsitektur?

### 5.1 Matriks Keputusan

| Use Case | RNN/LSTM | Transformer | Mamba |
|----------|----------|-------------|-------|
| **Real-time streaming** (speech, sensor) | ✅ (incremental) | ❌ (butuh full seq) | ✅ |
| **Long context** (100K+ token) | ❌ (gradient vanish) | ⚠️ (O(N²) memori) | ✅ (linear) |
| **Latency-sensitive inference** | ✅ (O(1) per step) | ⚠️ (prefill lambat) | ✅ |
| **Parallel training** (GPU besar) | ❌ (sequential) | ✅ (fully parallel) | ✅ (paralel via selective scan) |
| **Kecepatan inference di edge** | ✅ (kecil) | ❌ (model besar) | ✅ (kompak) |
| **Transfer learning** (pretrained) | ⚠️ (jarang) | ✅ (LLM ecosystem) | 🟡 (muncul) |

### 5.2 Alasan Transformer Menang di NLP

1. **Paralelisme**: Training di GPU 1000x lebih efisien dibanding RNN sekuensial — faktor ini saja yang membuat GPT-scale training feasible.
2. **Long-range dependency**: Attention menghubungkan token langsung, tanpa lewat cell state yang lossy.
3. **Scaling law**: Transformer bertahan dengan data + parameter lebih banyak (loss turun konsisten), sedangkan LSTM jenuh.
4. **Ekosistem**: JAX/PyTorch/HuggingFace semua dioptimalkan untuk attention.

### 5.3 Kenapa Mamba/RWKV Muncul (2024)

- **KV cache problem**: Transformer inference O(N) per token karena harus baca seluruh KV cache — mahal untuk sequence panjang.
- **Mamba (S6)**: selective scan — pilih mana yang perlu diingat per token → linear time + linear memory. Di benchmark (Mamba-3B vs Pythia-3B) menang di long-context tasks.
- **RWKV**: recurrent inference dengan training paralel — "Transformer yang bisa jalan seperti RNN".
- **Status 2025**: hybrid (attention + Mamba layer) mulai dipakai (Jamba, Zamba) — attention untuk local pattern, Mamba untuk global context.

## 6. Tool Stack

| Tool | Use |
|------|-----|
| **PyTorch / JAX** | Implementasi RNN/Transformer/Mamba |
| **HuggingFace Transformers** | Pretrained model, tokenizer |
| **Mamba (state-spaces/mamba)** | SSM implementasi (PyTorch) |
| **RWKV.cpp** | RWKV inference ringan |
| **FlashAttention** | Attention memori-efisien (training) |
| **Weights & Biases** | Experiment tracking |

## 7. References

- Attention Is All You Need (Vaswani 2017) — https://arxiv.org/abs/1706.03762
- LSTM (Hochreiter 1997) — https://www.bioinf.jku.at/publications/older/2604.pdf
- Mamba (Gu & Dao 2023) — https://arxiv.org/abs/2312.00752
- RWKV — https://arxiv.org/abs/2305.13048
- FlashAttention — https://arxiv.org/abs/2205.14135
