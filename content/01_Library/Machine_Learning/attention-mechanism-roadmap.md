---
title: Attention Mechanism Learning Roadmap — From Query-Key Matching to Multi-Head
  Attention
tags:
- machine-learning
- deep-learning
- attention
- transformer
- roadmap
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Menguasai mekanisme *attention* merupakan kunci penting untuk memahami bagaimana arsitektur Transformer dan Large Language Model (LLM) bekerja. Catatan ini menyediakan kurikulum terstruktur dan kode praktis untuk merancang modul *attention* dari nol, sebagai pasangan praktis dari berkas teoritis [[attention-mechanism-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Konsep Dasar Matriks Q, K, dan V](#2-fase-1-konsep-dasar-matriks-q-k-dan-v)
3. [Fase 2: Implementasi Scaled Dot-Product Attention (PyTorch)](#3-fase-2-implementasi-scaled-dot-product-attention-pytorch)
4. [Fase 3: Membangun Modul Multi-Head Attention (MHA)](#4-fase-3-membangun-modul-multi-head-attention-mha)
5. [Fase 4: Perakitan Satu Layer Transformer Lengkap](#5-fase-4-perakitan-satu-layer-transformer-lengkap)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini membimbing Anda dari pemahaman dot-product hingga perakitan layer Transformer:

```
[Fase 1: Konsep QKV] ──> [Fase 2: SDPA Coding] ──> [Fase 3: Multi-Head Attn] ──> [Fase 4: Layer Assembly]
- Database Retrieval     - Softmax Normalization   - Matriks Proyeksi Linear   - LayerNorm & Residual
- Vektor Representasi    - Causal Masking          - Concat & Output Projection - SwiGLU / FFN Layer
```

---

## 2. Fase 1: Konsep Dasar Matriks Q, K, dan V

Sebelum menulis kode, Anda harus memahami analogi **Sistem Retrieval Database**:
- **Query (Q)**: Vektor yang mewakili kata saat ini yang ingin kita periksa hubungannya.
- **Key (K)**: Vektor penunjuk (indeks) untuk seluruh kata yang ada dalam kalimat.
- **Value (V)**: Informasi aktual yang terkandung di dalam setiap kata.

Proses attention mengukur kesesuaian (*compatibility score*) antara Query dengan seluruh Key menggunakan perkalian titik (*dot product*), menormalisasinya menjadi bobot probabilitas menggunakan *softmax*, lalu menggunakan bobot tersebut untuk menjumlahkan isi Value.

---

## 3. Fase 2: Implementasi Scaled Dot-Product Attention (PyTorch)

Pada fase ini, Anda menulis fungsi dasar untuk mengalkulasi attention, lengkap dengan scaling factor $\frac{1}{\sqrt{d_k}}$ dan causal mask (untuk generative decoding):

```python
import math
import torch
import torch.nn.functional as F

def scaled_dot_product_attention(q, k, v, mask=None):
    # q, k, v shape: (batch_size, num_heads, seq_len, d_k)
    d_k = q.size(-1)
    
    # 1. Hitung score Q * K^T
    scores = torch.matmul(q, k.transpose(-2, -1)) / math.sqrt(d_k)
    
    # 2. Terapkan Causal Mask jika ada (untuk decoder-only LLM)
    if mask is not None:
        scores = scores.masked_fill(mask == 0, -1e9)
        
    # 3. Normalisasi baris menggunakan Softmax
    attention_weights = F.softmax(scores, dim=-1)
    
    # 4. Weighted sum dari Values
    output = torch.matmul(attention_weights, v)
    
    return output, attention_weights
```

---

## 4. Fase 3: Membangun Modul Multi-Head Attention (MHA)

MHA membagi dimensi representasi model menjadi beberapa kepala (*heads*) agar model dapat melatih "perhatian" pada berbagai hubungan sintaksis secara paralel.

```python
import torch.nn as nn

class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, num_heads):
        super().__init__()
        assert d_model % num_heads == 0, "d_model harus habis dibagi num_heads"
        
        self.d_model = d_model
        self.num_heads = num_heads
        self.d_k = d_model // num_heads
        
        # Matriks proyeksi linear untuk Q, K, V
        self.w_q = nn.Linear(d_model, d_model)
        self.w_k = nn.Linear(d_model, d_model)
        self.w_v = nn.Linear(d_model, d_model)
        
        # Proyeksi output akhir setelah penggabungan (concat)
        self.w_o = nn.Linear(d_model, d_model)

    def forward(self, q, k, v, mask=None):
        batch_size = q.size(0)
        
        # 1. Proyeksi linear ke dimensi d_model, lalu bagi menjadi heads
        q = self.w_q(q).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        k = self.w_k(k).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        v = self.w_v(v).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        
        # 2. Hitung Scaled Dot-Product Attention untuk tiap head
        out, weights = scaled_dot_product_attention(q, k, v, mask)
        
        # 3. Concatenate seluruh head kembali ke dimensi d_model
        out = out.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        
        # 4. Proyeksi linear akhir
        return self.w_o(out), weights
```

---

## 5. Fase 4: Perakitan Satu Layer Transformer Lengkap

Layer ini menggabungkan modul Multi-Head Attention dengan Layer Normalization (Pre-LN) dan Feed-Forward Network (FFN).

```python
class TransformerDecoderLayer(nn.Module):
    def __init__(self, d_model, num_heads, d_ff):
        super().__init__()
        self.mha = MultiHeadAttention(d_model, num_heads)
        self.ln_1 = nn.LayerNorm(d_model)
        self.ln_2 = nn.LayerNorm(d_model)
        
        # Feed-Forward Network sederhana (Linear -> ReLU -> Linear)
        self.ffn = nn.Sequential(
            nn.Linear(d_model, d_ff),
            nn.ReLU(),
            nn.Linear(d_ff, d_model)
        )

    def forward(self, x, mask=None):
        # 1. Pre-LN & Self-Attention + Koneksi Residu (Skip Connection)
        norm_x = self.ln_1(x)
        attn_out, _ = self.mha(norm_x, norm_x, norm_x, mask)
        x = x + attn_out
        
        # 2. Pre-LN & FFN + Koneksi Residu
        norm_x = self.ln_2(x)
        ffn_out = self.ffn(norm_x)
        x = x + ffn_out
        
        return x
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Mengapa kita membutuhkan faktor pembagi $\sqrt{d_k}$ pada rumus attention? Apa akibatnya jika faktor tersebut dihilangkan?

**Solusi**
Untuk dimensi kunci yang besar (misalnya $d_k = 512$), nilai dot-product $Q \cdot K^T$ akan bertumbuh secara signifikan. Hal ini mendorong nilai skor menjauh menuju wilayah ekstrem dari fungsi softmax. Akibatnya:
1. Gradien fungsi softmax pada daerah ekstrem tersebut akan mendekati nol (*vanishing gradient*).
2. Proses pelatihan (*training*) model akan mengalami hambatan berat atau bahkan berhenti belajar.
Dengan membagi menggunakan $\sqrt{d_k}$, kita mengembalikan rata-rata sebaran variansi dot-product mendekati 1.0, menjaga kelancaran aliran balik gradien.

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[attention-mechanism-deepdive]] | Dasar teori, perumusan softmax, serta penjelasan detail FlashAttention & GQA. |
| [[rnn-lstm-vs-transformer]] | Analisis komparatif arsitektur rekurensi dengan arsitektur Transformer paralel. |
| [[backpropagation-roadmap]] | Peta jalan aliran balik gradien yang digunakan untuk melatih bobot proyeksi MHA. |

## 8. Deepdive — Attention Variants & Production Concerns

### 8.1 Variant Matrix

| Variant | Mekanisme | Kelebihan | Kekurangan |
|---------|-----------|-----------|------------|
| **MHA (Multi-Head)** | h proyeksi paralel | Capture berbagai hubungan | O(N²) memori |
| **MQA (Multi-Query)** | Key/Value dishare antar head | KV cache kecil (inference murah) | Kualitas sedikit turun |
| **GQA (Grouped-Query)** | Grup head share KV | Tradeoff MHA/MQA (Llama 2/3 pakai) | Implementasi kompleks |
| **Sliding Window** | Attention terbatas ke window | Linear-ish (Mistral) | Long-range loss |
| **FlashAttention** | IO-aware, tiling | Memori O(N), 2-4x lebih cepat | Kernel CUDA custom |
| **Linear Attention** | Kernel trick, tanpa softmax | Linear time | Quality turun di task tertentu |

### 8.2 Causal Mask & KV Cache

```python
# Causal mask: token hanya bisa attend ke token sebelumnya (generative)
mask = torch.triu(torch.ones(L, L) * float('-inf'), diagonal=1)

# KV Cache: saat inference, Q baru hanya perlu K,V lama → hemat compute
# → MQA/GQA lahir dari sini: share KV antar head → cache lebih kecil
```

### 8.3 Training vs Inference Profile

| Stage | Dominan | Bottleneck |
|-------|---------|-----------|
| Training | Forward + backward | Compute (matmul), memory (activation) |
| Inference | Prefill (semua token) + decode (1 token/step) | KV cache bandwidth |

## 9. Tool Stack

| Tool | Use |
|------|-----|
| **PyTorch** | Implementasi attention |
| **FlashAttention (triton/CUDA)** | Attention efisien |
| **HuggingFace** | Pretrained + inference API |
| **vLLM** | PagedAttention + KV cache mgmt |
| **TensorBoard / W&B** | Attention pattern viz |

## 10. Referensi

- Attention Is All You Need — https://arxiv.org/abs/1706.03762
- FlashAttention — https://arxiv.org/abs/2205.14135
- GQA (Llama 2) — https://arxiv.org/abs/2305.13245
- vLLM PagedAttention — https://arxiv.org/abs/2309.06180
---

audited
---
