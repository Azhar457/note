---
title: RNN-LSTM vs Transformer — Architecture and Sequence Modeling Comparison
tags:
  - machine-learning
  - deep-learning
  - transformer
  - lstm
  - rnn
  - mamba
created: "2026-07-19"
updated: "2026-07-19"
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Perkembangan arsitektur pemodelan sekuensial (_sequence modeling_) mengalami lompatan paradigma yang sangat besar sejak penemuan self-attention. Catatan ini membedah perbandingan arsitektur Rekurensi (RNN/LSTM), Paralelisme (Transformer), dan arsitektur hibrida/State Space Model modern (Mamba), melengkapi pembahasan [[attention-mechanism-deepdive]].

## Daftar Isi

1. [Perbedaan Paradigma Pemrosesan](#1-perbedaan-paradigma-pemrosesan)
2. [Matematika Rekurensi vs Self-Attention](#2-matematika-rekurensi-vs-self-attention)
3. [Kelemahan Kapasitas: Bottleneck Memori & Komputasi](#3-kelemahan-kapasitas-bottleneck-memori--komputasi)
4. [Arsitektur Hibrida Modern (Mamba & RWKV)](#4-arsitektur-hibrida-modern-mamba--rwkv)
5. [Matriks Perbandingan Rekayasa Sistem](#5-matriks-perbandingan-rekayasa-sistem)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Perbedaan Paradigma Pemrosesan

Model sekuensial bertugas memetakan input runtun waktu (_time-series_ atau teks) ke dalam representasi vektor kontekstual. Cara kedua arsitektur menangani aliran informasi ini sangat bertolak belakang:

- **RNN / LSTM**: Memproses token satu demi satu secara sekuensial. Untuk membaca token ke-$t$, model wajib menunggu kalkulasi _hidden state_ dari token ke-$t-1$. Hal ini membatasi pemanfaatan paralelisme kartu grafis (GPU).
- **Transformer**: Memproses seluruh token secara bersamaan (_fully parallel_) dalam satu langkah komputasi matriks raksasa, mengabaikan batasan waktu melalui _positional encoding_.

---

## 2. Matematika Rekurensi vs Self-Attention

### 2.1 Aliran Komputasi LSTM (Long Short-Term Memory)

LSTM menggunakan mekanisme gerbang (_gates_) untuk mengatur aliran informasi di dalam _cell state_ ($c_t$) dan _hidden state_ ($h_t$):

$$f_t = \sigma(W_f \cdot [h_{t-1}, x_t] + b_f) \quad \text{(Forget Gate - menentukan apa yang dibuang)}$$
$$i_t = \sigma(W_i \cdot [h_{t-1}, x_t] + b_i) \quad \text{(Input Gate - menentukan informasi baru yang disimpan)}$$
$$\tilde{c}_t = \tanh(W_c \cdot [h_{t-1}, x_t] + b_c) \quad \text{(Kandidat Cell State baru)}$$
$$c_t = f_t \odot c_{t-1} + i_t \odot \tilde{c}_t \quad \text{(Pembaruan Cell State secara linear)}$$
$$o_t = \sigma(W_o \cdot [h_{t-1}, x_t] + b_o) \quad \text{(Output Gate)}$$
$$h_t = o_t \odot \tanh(c_t) \quad \text{(Hidden State akhir)}$$

_Sifat_: Komputasi ini bersifat berantai sekuensial dengan kompleksitas waktu $O(N)$ langkah berurutan untuk panjang sekuens $N$.

### 2.2 Aliran Komputasi Transformer Self-Attention

Transformer membuang seluruh rekurensi dan menggunakan perkalian matriks dot-product paralel:

$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{Q \cdot K^T}{\sqrt{d_k}}\right) \cdot V$$

Dimana matriks $Q, K, V$ dihasilkan secara instan dari seluruh sequence input melalui perkalian bobot proyeksi paralel:
$$Q = XW_Q, \quad K = XW_K, \quad V = XW_V$$

_Sifat_: Komputasi ini berjalan secara $O(1)$ langkah waktu paralel pada GPU, namun membutuhkan memori kuadratis $O(N^2)$ untuk menyimpan matriks kecocokan attention.

---

## 3. Kelemahan Kapasitas: Bottleneck Memori & Komputasi

### 3.1 LSTM: Cell State Bottleneck (Vanishing/Exploding Gradient)

Meskipun LSTM memiliki _forget gate_ untuk menjaga informasi jarak jauh, seluruh informasi masa lalu dipaksa untuk masuk ke dalam vektor dimensi tetap ($c_t$). Untuk sequence yang sangat panjang (>1000 token), detail mikroskopis di awal kalimat pasti akan terkikis dan hilang (_lossy compression_).

### 3.2 Transformer: O(N²) Memory Wall

Karena setiap token harus menghitung kecocokan dengan seluruh token lainnya di dalam sequence, penyimpanan matriks skor attention berukuran $N \times N$ membengkak secara kuadratis. Pada sequence sepanjang 100K token, komputasi ini menuntut alokasi VRAM GPU yang sangat ekstrem, membatasi panjang input _context window_.

---

## 4. Arsitektur Hibrida Modern (Mamba & RWKV)

Untuk menyelesaikan dilema "Paralel saat training (seperti Transformer) tapi hemat VRAM saat inference (seperti RNN)", komunitas mengembangkan arsitektur sub-linear/linear:

### 4.1 Mamba (State Space Model - SSM)

Mamba menggunakan formulasi _Selective State Space Model_. Ia membiarkan parameter transisi matriks bergantung pada konten input ($B(x), C(x)$) untuk mempertahankan memori selektif yang dinamis.

- **Training**: Menggunakan formulasi asosiatif paralel (_parallel scan_) sehingga dapat dilatih secepat Transformer pada GPU.
- **Inference**: Menggunakan formulasi rekurensi linear $O(1)$ memori cache, sehingga sangat hemat VRAM dan cepat saat melakukan streaming generasi token.

### 4.2 RWKV (Receptive Weighted Key Value)

RWKV merumuskan ulang mekanisme attention menjadi formulasi RNN linear yang stabil secara numerik menggunakan bobot eksponensial waktu:

- Menawarkan kecepatan komputasi paralel linear saat latihan, tetapi bertindak sebagai RNN murni saat eksekusi model.

---

## 5. Matriks Perbandingan Rekayasa Sistem

| Karakteristik                         | RNN / LSTM                                     | Transformer                                   | Mamba (SSM)                              |
| ------------------------------------- | ---------------------------------------------- | --------------------------------------------- | ---------------------------------------- |
| **Kompleksitas Training**             | $O(N)$ (Sekuensial)                            | **$O(1)$** (Paralel penuh)                    | **$O(1)$** (Parallel scan)               |
| **Kompleksitas Memori (Inference)**   | **$O(1)$** (Fixed state size)                  | $O(N^2)$ (KV Cache grows)                     | **$O(1)$** (Fixed state cache)           |
| **Kemampuan Kontekstual Jauh**        | Buruk (Kualitas menurun tajam)                 | **Luar Biasa** (Akses instan)                 | **Sangat Baik** (Hampir tanpa penurunan) |
| **Memory Footprint pada Edge Device** | **Sangat Kecil**                               | Besar (Membutuhkan optimasi GQA/Quantization) | **Kecil**                                |
| **Hardware Utilization (GPU)**        | Rendah (Gagal melakukan saturasi tensor cores) | **Sangat Tinggi** (Sangat cocok untuk GPU)    | **Tinggi**                               |

---

## 6. Koneksi ke Vault

| Catatan                          | Hubungan                                                                                                          |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| [[attention-mechanism-deepdive]] | Penjelasan formula dasar matematika dan jenis-jenis attention yang dibandingkan di sini.                          |
| [[meta-agent-orchestration]]     | Pemilihan model dasar (backbone) untuk kebutuhan latency low-edge device.                                         |
| [[unified-threat-ontology]]      | Pemanfaatan model sekuensial untuk mendeteksi runtun waktu serangan (Layer 4/Transport network traffic analysis). |
