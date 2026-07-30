---
tags:
  - deep-learning
  - neural-network
  - backpropagation
  - gradient-descent
aliases:
  - Backpropagation
  - Propagasi Balik
  - Error Backpropagation
status: pending
created: 2026-07-11
updated: 2026-07-11
---

# Backpropagation: Fondasi Training Neural Network

> [!tip] Backpropagation menghitung gradien loss terhadap setiap weight di neural network dengan menyebarkan error dari output ke input via chain rule. Tanpa backprop, NN modern tidak bisa dilatih.

---

## 1. Problem: Gimana Cara Belajar Neural Network?

Neural network punya jutaan parameter (weight, bias). Kita mau nyari nilai weight yang bikin prediksi paling akurat. Pertanyaannya: **gimana cara ngubah weight biar error kecil?**

Solusi naive: coba random weight, lihat error-nya, terus tebak. Gak feasible — ruang parameternya terlalu besar.

Yang diperlukan: informasi arah — **weight mana yang harus digeser naik/turun dan seberapa banyak** untuk mengurangi error. Ini gradien.

> **Gradien** = turunan parsial loss terhadap setiap weight. Menunjuk arah yang paling curam menuju error minimum.

---

## 2. Intuisi: Siapa yang Salah?

Bayangin rantai produksi:
1. Input → weight1 → hidden1 → weight2 → hidden2 → weight3 → output → loss
2. Loss besar → siapa yang salah? weight3? weight2? atau weight1?

Logikanya:
- Weight3 paling dekat sama output → paling jelas siapa yang salah
- Weight1 paling jauh → error-nya "diendapkan" sama weight di depannya

**Backpropagation = bagi-bagi tanggung jawab error secara proporsional dari belakang ke depan.**

---

## 3. Matematika: Chain Rule

### Forward Pass

```
z1 = W1 · x + b1
a1 = σ(z1)              # activation layer 1
z2 = W2 · a1 + b2
a2 = σ(z2)
...
ŷ = softmax(zL)         # output
L = CrossEntropy(y, ŷ)  # loss
```

### Backward Pass — Chain Rule

Chain rule: turunan fungsi komposisi = produk turunan dari outer ke inner.

```
∂L/∂W2 = ∂L/∂ŷ   · ∂ŷ/∂zL   · ∂zL/∂W2
         ^          ^           ^
         loss der   activation  linear layer
```

Dari output layer ke input layer, pola umum untuk layer ke-l:

```
δl = (W_{l+1}^T · δ_{l+1}) ⊙ σ'(zl)    # error signal
∂L/∂Wl = δl · a_{l-1}^T                  # gradien weight
∂L/∂bl = δl                               # gradien bias
```

Untuk output layer (CE + softmax): `∂L/∂zL = ŷ - y` — bentuk sederhana karena turunan CE dan softmax saling cancel.

---

## 4. Kenapa Backprop Bukan Forward Differences?

Forward differences: untuk setiap weight, ubah dikit → lihat perubahan error → hitung gradien. Untuk 1M weight, butuh **1M forward pass** per update.

Backprop: **2 pass** (1 forward + 1 backward). Kompleksitas O(n) vs O(n²).

| Metode | Forward Pass per Update | Skalabilitas |
|--------|------------------------|--------------|
| Forward diff | 1M (untuk 1M weight) | O(n²) — mustahil |
| Backprop | 2 (forward + backward) | O(n) — feasible |

> **Kapan backprop gagal:** Dataset terlalu kecil (overfit), learning rate salah (divergen), atau vanishing gradient (saturating activation).

---

## 5. Gradient Descent Family

### SGD
```
W ← W - η · ∂L/∂W
```
Sederhana, murah memori. Tapi oscillating di saddle point.

### SGD + Momentum
```
v ← β·v + (1-β)·∂L/∂W
W ← W - η·v
```
Akumulasi momentum biar gak stuck di local minima. β=0.9.

### Adam
```
m ← β₁·m + (1-β₁)·g          # first moment
v ← β₂·v + (1-β₂)·g²         # second moment
W ← W - η · m/(√v + ε)       # adaptive LR per parameter
```
Learning rate adaptif per weight. Cocok untuk sebagian besar kasus.
**Kapan gagal:** Generalization gap — Adam bisa overfit lebih cepat dari SGD.

### AdamW — Decoupled Weight Decay
```
W ← W - η · (m/(√v + ε) + λ·W)
```
Weight decay dipisah dari gradien — implementasi L2 yang benar untuk Adam.

### Optimizer Comparison

| Optimizer | Adaptive LR | Momentum | Memory | Best For |
|-----------|------------|----------|--------|----------|
| SGD | ✗ | Optional (manual) | 1× params | CV, large batch |
| SGD+Nesterov | ✗ | Look-ahead | 1× params | Convergence speed |
| Adam | ✓ | ✓ | 2× params | NLP, Transformers |
| AdamW | ✓ | ✓ (decoupled) | 2× params | LLM, ViT (default) |
| RMSprop | ✓ (per-param) | ✗ | 2× params | RNN, online RL |
| Adafactor | ✓ (factorized) | ✓ | 0.5× params | Memory-constrained |

---

## 6. Vanishing & Exploding Gradients

Masalah fundamental backprop: gradien dikalikan terus lewat layer.

### Vanishing Gradient

Di hidden layer dalam, gradien mendekati 0 → weight berhenti belajar.

Penyebab:
- Sigmoid/tanh: turunan max 0.25. Kalikan 20 layer: 0.25²⁰ ≈ 9×10⁻¹³ — praktis nol.
- Deep network → sinyal gradien mati sebelum sampai layer awal.

Fix:
- **ReLU** activation (f'(x)=0 atau 1) — gak ngecil
- **Batch Normalization** — jaga distribusi activation stabil
- **Residual Connections** — shortcut bypass activation
- **LSTM gates** — gating mechanism kontrol aliran gradien di RNN

### Exploding Gradient

Kebalikan: gradien membesar eksponensial → weight jadi NaN.

Penyebab: weight initialization jelek + activation unbounded.

Fix:
- **Gradient Clipping:** potong gradien kalau > threshold (max_norm=1.0)
- **Weight Initialization:** Xavier (tanh), He (ReLU)
- **Layer Normalization** — beda dengan BN, independen dari batch size

### Gradient Clipping Strategies

```python
# Clip by value: individual grad [-clip, clip]
torch.nn.utils.clip_grad_value_(model.parameters(), clip_value=1.0)

# Clip by norm: rescale if norm > max_norm
torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)

# Clip by global norm (recommended): rescale all grads proportionally
# Preserves direction, limits magnitude
```

---

## 7. Implementation — Autodiff

### Automatic Differentiation

Framework (PyTorch, TensorFlow, JAX) gak implement backprop manual. Mereka pake **autodiff** yang merekam computational graph pas forward pass, lalu jalanin backward sesuai topologi.

```python
# Pseudocode autodiff (reverse mode)
class Tensor:
    def __init__(self, data, children=()):
        self.data = data
        self.grad = 0
        self._backward = lambda: None
        self._ctx = children

    def __add__(self, other):
        out = Tensor(self.data + other.data, (self, other))
        def _backward():
            self.grad += out.grad
            other.grad += out.grad
        out._backward = _backward
        return out

    def backward(self):
        topo = topological_sort(self)
        self.grad = 1.0
        for v in reversed(topo):
            v._backward()
```

### MicroBatch Training

Dataset gak muat di GPU → dipecah jadi microbatches:

```python
for batch in dataloader:
    output = model(batch)
    loss = criterion(output, target)
    loss.backward()                  # accumulate gradien
    if step % accumulation == 0:
        optimizer.step()             # update weight
        optimizer.zero_grad()        # reset gradien
```

Gradien diakumulasi dari beberapa microbatches sebelum update. Efeknya sama kayak batch size besar, tapi hemat VRAM.

---

## 8. Weight Initialization — Kunci Konvergensi

Bobot awal menentukan apakah training konvergen cepat, lambat, atau divergen.

### Xavier/Glorot (tanh, sigmoid)
```
W ∼ Uniform(-√(6/(n_in + n_out)), +√(6/(n_in + n_out)))
```
Jaga variance activation tetap konstan antar layer. Variance gak ngecil atau ngebesar.

### He Initialization (ReLU, LeakyReLU)
```
W ∼ Normal(0, √(2/n_in))
```
ReLU matikan setengah neuron → variance butuh 2× Xavier. Ini kompensasi aktivasi yang setengahnya nol.

### Orthogonal Initialization (RNN/LSTM)
```
W = Q  # QR decomposition dari matriks random
```
Jaga norm tetap stabil di recurrent steps. Tanpa ini, RNN >100 langkah vanish/explode.

```python
init.xavier_uniform_(layer.weight)         # tanh
init.kaiming_uniform_(layer.weight, mode='fan_in', nonlinearity='relu')  # ReLU
init.orthogonal_(layer.weight, gain=1.0)   # RNN
```

**Kapan gagal:** Model >100 layer tanpa residual — variance tetap meledak. Butuh scaling khusus (DeepNet, Admin).

---

## 9. Regularization — Cegah Overfit

### Dropout
Training: random matikan neuron p. Inference: semua aktif, weight × (1-p).
- p=0.1 untuk embedding, p=0.3 untuk hidden
- **Kapan gagal:** Model underfit — dropout bikin makin parah

### Weight Decay (L2)
```
L_total = L_data + λ · Σ||W||²
```
λ tipikal 1e-4 (AdamW) atau 5e-4 (SGD). AdamW decouple weight decay dari gradien — lebih stabil.

### Label Smoothing
```
y_smooth = (1-ε)·y_hot + ε/K  # K = jumlah kelas
```
Cross-entropy one-hot dorong logit ke ±∞ — overconfident. Label smoothing jaga tetap "tidak yakin". ε=0.1.

### Stochastic Depth
Random skip layer dengan prob p (layer dalam p lebih besar). Efek ensemble depth bervariasi, gradient flow lebih pendek.
**Kapan gagal:** Skip rate >0.5 → underfit.

### DropConnect vs Dropout vs Stochastic Depth

| Method | What's Dropped | Inference Behavior | Used In |
|--------|---------------|--------------------|---------|
| Dropout | Neuron outputs | Scale by (1-p) | MLP, Transformer |
| DropConnect | Weight connections | Scale by (1-p) | RNN, small nets |
| Stochastic Depth | Entire layer | Use all layers | ResNet, EfficientNet |
| LayerDrop | Entire layer (structured) | Keep strongest layers | RoBERTa |

---

## 10. Learning Rate Scheduling

### Cosine Decay
```
η(t) = η_min + 0.5·(η_max - η_min)·(1 + cos(t/T · π))
```
Penurunan smooth. η_max=3e-4 (Adam), η_min=1e-5. Standar untuk transformer training.

### Linear Warmup + Decay
```
t < warmup:  η = η_max · t / warmup_steps
t ≥ warmup:  η = η_max · (1 - (t - warmup)/(T - warmup))
```
Warmup penting: Adam butuh momen stabil, LayerNorm distribusi belum rapi di awal.
Warmup steps: 500-2000 untuk small model, 2000-10000 untuk LLM.

### OneCycle
η naik linear → turun cosine. Momentum turun 0.95→0.85.
Konvergensi 10× lebih cepat dari SGD. **Gagal:** Hanya SGD, gak cocok Adam.

### Scheduler Comparison

| Scheduler | Shape | Best For | Tuning Effort |
|-----------|-------|----------|---------------|
| Step decay | Sharp drops | CV fine-tuning | Low (γ, step_size) |
| Exponential | Smooth decay | Long training | Low (γ) |
| Cosine | Smooth curve | Transformer, LLM | Moderate (η_max, T) |
| Linear warmup+cosine | Warmup + cosine | Adam optimizers | Moderate |
| OneCycle | Spike up then down | SGD, CV | High (η_max) |
| ReduceLROnPlateau | Adaptive | Any | Low (patience) |

---

## 11. Mixed Precision Training (FP16/BF16)

Forward/backward FP16/BF16, weight update FP32 — 40% VRAM hemat, 1.5-2× throughput.

### FP16
Range ±65K — gradien underflow mudah. Loss scaling: kalikan loss (2⁸-2¹⁶) sebelum backward, bagi update.

### BF16
8-bit exponent (sama FP32) → range sama, gak perlu loss scaling. Tapi butuh Ampere+ (A100, H100, RTX 3090+).

```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()
for batch in dataloader:
    with autocast():
        loss = model(batch)
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
    optimizer.zero_grad()
```

---

## 12. Training Tricks

### EMA (Exponential Moving Average)
```
W_ema = β·W_ema + (1-β)·W, β=0.999
```
Bobot EMA lebih smooth → generalization lebih baik di inference. Biaya 2× parameter (tapi gak perlu gradien).

### Gradient Accumulation
K microbatches → 1 update. Batch size 8→32 tanpa VRAM tambahan.

### Stochastic Weight Averaging (SWA)
Rata-rata bobot dari beberapa checkpoint terakhir. Generalisasi lebih baik dari checkpoint tunggal.

### Lookahead
Slow-moving average dari bobot optimizer. Stabilisasi tanpa tuning LR.

### Sharpness-Aware Minimization (SAM)
```
W' = W + ε·∇L(W)/||∇L(W)||    # cari titik paling tajam
∇L_SAM = ∇L(W')                # gradien di titik tajam
W ← W - η·∇L_SAM               # minimalkan → flat minima
```
2× compute, generalisasi lebih baik. **Gagal:** batch besar.

---

## 13. Loss Landscapes & Optimization Theory

### Kenapa Deep Learning Berhasil?

1. **Overparameterization:** Parameter >> data → banyak local minima sama bagusnya.
2. **Sharp vs Flat Minima:** Flat minima generalisasi lebih baik — SGD alami dorong ke flat.
3. **Dimensi tinggi:** Sebagian besar "local minima" sebenernya saddle point — gradien bisa lewat.

### Loss Landscape Visualization

Loss landscape di dimensi tinggi punya struktur unik:
- Near initialization: chaotic, banyak saddle point
- Near convergence: connected minima (terhubung jalur low-loss)
- Mode connectivity: ada jalur low-loss antar solusi yang terlihat berbeda

### Neural Tangent Kernel (NTK)

Dalam limit infinite width, NN berperilaku seperti kernel method:
- Training dynamics = kernel regression dengan NTK
- NTK konvergen ke stationary point saat width → ∞
- Explain why overparameterized NN generalizes

---

## 14. Normalization — Stabilisasi Training

### Batch Normalization
```
x̂ = (x - μ_batch) / √(σ²_batch + ε)
y = γ·x̂ + β
```
Normalize per channel across batch. Train: μ_batch, σ²_batch. Eval: running mean/var.
**Kapan gagal:** Batch size kecil (<16) — estimasi noisy. RNN — statistik batch gak cocok.

### Layer Normalization
```
x̂ = (x - μ_layer) / √(σ²_layer + ε)
```
Normalize per token across feature. Independen dari batch size — stabil. Standar di transformer.

### RMS Norm
```
x̂ = x / √(mean(x²) + ε)
```
LayerNorm tanpa mean centering. Lebih murah. Dipakai di Llama, Mistral.

### Normalization Comparison

| Norm | Axis | Batch-Dependent | Compute | Used By |
|------|------|:---------------:|:-------:|---------|
| BatchNorm | batch, spatial | ✓ | O(d) | CNN, ResNet |
| LayerNorm | feature | ✗ | O(d) | Transformer, RNN |
| InstanceNorm | spatial | ✗ | O(d) | Style transfer |
| GroupNorm | feature groups | ✗ | O(d) | Small batch CNN |
| RMSNorm | feature (no mean) | ✗ | O(d/2) | Llama, Mistral |

---

## 15. Diagnostic Tools — Debug Training

| Problem | Symptom | Diagnosis | Fix |
|---------|---------|-----------|-----|
| Vanishing grad | Loss turun lambat | Histogram gradien — cek distribution | ReLU, residual, batch norm |
| Exploding grad | Loss → NaN | Max grad magnitude | Gradient clipping, reduce LR |
| Dead ReLU | 80%+ neuron output 0 | Activation histogram | LeakyReLU, PReLU |
| Overfit | Loss train turun, val naik | Plot train vs val loss | Dropout, weight decay, early stop |
| Underfit | Loss train + val tinggi | Model terlalu kecil | Tambah layer/width |
| Warmup needed | Loss spike di awal | Plot first 1000 steps | Linear warmup |
| Batch norm issue | Validation fail train ok | Check running mean/var | eval() mode, sync BN |
| Gradient noise | Loss oscillating | Visualize gradient variance | Increase batch size |

---

## 16. Distributed Training — Beyond Single GPU

### Data Parallel (DDP)
Setiap GPU: forward + backward → all-reduce gradien → average → update.
Komunikasi O(parameters) per step. Skalabilitas hingga 256 GPU.

### Model Parallel (Tensor Parallel)
Split weight across GPUs: W = [W₁ | W₂]. GPU0 computes W₁·x, GPU1 computes W₂·x.
all-gather → concatenate. Komunikasi O(hidden_dim) per layer.

### Pipeline Parallel
Layer 0-7 → GPU0, Layer 8-15 → GPU1. Forward GPU0→GPU1→GPU2. Backward sebaliknya.
Masalah: bubble (GPU idle). 1F1B schedule mengurangi bubble.

### ZeRO (Zero Redundancy Optimizer)
Partisi optimizer state, gradien, parameter across GPUs:
- ZeRO-1: partition optimizer state → 4× saving
- ZeRO-2: + partition gradients → 8×
- ZeRO-3: + partition parameters → linear to GPUs

Standar untuk LLM training.

---

## 17. Advanced Optimization

### Gradient Checkpointing
Forward: simpan cuma activation di beberapa checkpoint layer.
Backward: re-compute activation yang dibuang. Hemat O(√n), lambat 1.3×.

### Gradient Noise Scale
```
GNS = tr(Σ) / ||g||²
```
GNS besar → gradien noisy → butuh batch besar. Ideal batch: sampai GNS ≈ 1.

### Super-Convergence
OneCycle LR + aggressive regularization → 10× faster training.
Teori: large LR bantu lewati saddle point. Prasyarat: batch besar, augmentasi kuat.

### Curriculum Learning
Urutkan training data dari mudah ke sulit:
1. 0-10%: data bersih, sample mudah
2. 10-50%: tambah noise, sample medium
3. 50-100%: full dataset, sample sulit

Convergence lebih cepat untuk beberapa dataset.

### Self-Supervised Pretraining
Sebelum supervised fine-tuning, pretrain dulu:
- Masked Autoencoder (MAE): mask patches → reconstruct gambar
- SimCLR: dua augmentasi gambar sama → cosine close
- Masked Language Modeling (BERT): mask tokens → predict

Pretraining = weight initialization yang jauh lebih baik dari random.

---

## 18. Learning from Limited Data

### Transfer Learning
```
Pretrained → fine-tune → adapt ke domain baru
```
Lebih efektif dari training from scratch untuk dataset <1M samples.

### Fine-tuning Strategy

| Dataset Size | Layers to Unfreeze | LR | Epochs |
|-------------|-------------------|----|--------|
| <1K | Last 1-2 layers | 1e-5 | 10-20 |
| 1K-10K | Last 3-5 layers | 2e-5 | 10-30 |
| 10K-100K | All layers | 3e-5 | 10-50 |
| >100K | All layers (from scratch possible) | 1e-4 | 50-200 |

### Few-Shot Learning
- **MAML:** Train initialization yang bisa adapt dalam 1-5 gradient steps
- **Prototypical Networks:** Embed support set → class prototypes → cosine distance
- **In-context learning:** Tanpa gradient — beri contoh di prompt (LLM)

---

## 19. Backprop Variants & Alternatives

### Synthetic Gradients
Predict gradien dari layer berikutnya — training asynchronous. Tapi prediksi bisa salah → converge lambat.

### Forward-Forward Algorithm
Ganti forward+backward dengan dua forward pass:
1. Positive pass: real data → maximize goodness (∑ activation²)
2. Negative pass: corrupted data → minimize goodness

Gak butuh backward pass → bisa di hardware neuromorphic. Tapi converge lebih lambat.

### Equilibrium Propagation
Untuk energy-based models: perturb equilibrium → measure change → approximate gradient.
Lebih biologically plausible dari backprop.

### RL as Alternative
Ketika gradien gak bisa dihitung (non-differentiable ops):
- Policy gradient (REINFORCE)
- Score function estimator dengan baseline
- REBAR, RELAX (control variates)

---

## 20. Best Practices Summary

### Training Checklist

- [ ] Weight init (He untuk ReLU, Xavier untuk tanh)
- [ ] LR warmup (500-2000 steps)
- [ ] Cosine decay atau linear decay
- [ ] Gradient clipping (max_norm=1.0)
- [ ] Normalization (LN untuk transformer, BN untuk CNN)
- [ ] Data augmentation
- [ ] Regularization: weight decay + dropout
- [ ] Checkpointing (save best by val loss)
- [ ] Monitor: train loss, val loss, grad norm, activation stats

### Debugging Flow

```
Loss NaN? → cek LR, gradient clipping, data normalization
Loss turun lambat? → cek grad norm, activation distribution
Train bagus, val jelek? → overfit → tambah regularization
Train jelek, val bagus? → data leakage → cek preprocessing
Dua-duanya jelek? → model terlalu kecil / bug arsitektur
Loss oscillate? → turunkan LR atau tambah batch size
```

### Activation Function Math

Tiap activation punya turunan berbeda yang langsung impact backprop:

- **Sigmoid:** σ'(x) = σ(x)·(1-σ(x)), max 0.25 → vanish di layer dalam
- **Tanh:** tanh'(x) = 1 - tanh²(x), max 1.0 → lebih baik dari sigmoid
- **ReLU:** f'(x) = 1 jika x>0, 0 jika x≤0 → murah, sparse, **Dead ReLU**
- **LeakyReLU:** f'(x) = 1 jika x>0, α jika x≤0 → solves dead ReLU
- **GELU:** f'(x) ≈ x·Φ(x) — smooth, menggantikan ReLU di model modern
- **SiLU/Swish:** f'(x) = σ(x) + x·σ(x)·(1-σ(x)) — smooth, non-monotonic

ReLU vs GELU di training: GELU +0.1-0.3% accuracy di NLP tasks, tapi 2× compute overhead. Di LLM modern, GELU dan SwiGLU dominan.

### Fisher Information & Gradient

Fisher Information Matrix (FIM) mengukur berapa banyak informasi parameter tentang data:

F = E[∇L · ∇L^T]

Natural Gradient: W ← W - η · F⁻¹ · ∇L
- Lebih akurat dari gradient descent — memperhitungkan curvature
- Tapi F⁻¹ O(d²) — impractical. Approximations: KFAC, Eigengrad.

Adam ≈ diagonal approximation of natural gradient. Ini kenapa Adam efektif — mendekati natural gradient tanpa matriks penuh.

### Weight Averaging vs Ensemble

Ensemble: train N model independen → rata-rata output. Mahal (N× compute).

Weight Averaging: rata-rata N checkpoint dari 1 training run. Lebih murah, hampir sama efektifnya untuk generalization.

SWA (Stochastic Weight Averaging): rata-rata checkpoint dari beberapa epoch terakhir. Lebih baik dari EMA untuk non-linear averaging.

Model Soups: rata-rata weight dari fine-tuning berbeda (beda LR, beda augmentation). Komputasi lebih murah dari ensemble, performa mendekati.

### Learning Rate Finders

Teknik mencari η_max optimal sebelum training penuh:

**LR Range Test (Smith 2017):**
1. Mulai dari η_min (1e-7)
2. Naikkan linear tiap batch sampai η_max (10)
3. Plot loss vs learning rate
4. Pilih η di titik loss turun paling curam

Pattern: loss turun → terus turun → loss naik (divergen). η optimal = 1/10 dari titik divergen.

**Trivial Augment (Wong et al.):**
LR range test + augmentation strength search. Satu run dapet dua hyperparameter.

**Praktik terbaik:** 
- Adam: η_max antara 1e-4 sampai 1e-3
- SGD: η_max antara 0.1 sampai 1.0
- Batch size naik → LR naik (linear scaling rule)

### Cyclic LR

LR berosilasi antara η_min dan η_max:
- Triangular: linear naik/turun
- Cosine: smooth oscillation
- Setiap siklus: beberapa epoch

Efek: keluar dari saddle point lebih cepat, generalization lebih baik. Alternatif lebih murah dari restart.

### Optimizer Scheduling: Switch SGD→Adam

Li et al. 2020: Train dengan SGD dulu → switch ke Adam di akhir.
- SGD: lebih robust ke saddle point
- Adam: lebih presisi untuk fine detail
- Switching point: 70-80% total training

Atau kebalikan: Adam dulu → SGD di akhir untuk generalisasi.
"SWATS" dan "Adam→SGD switching" sudah terbukti di beberapa paper.

### Learning Rate Schedulers: Advanced

**Warmup:** Semua scheduler butuh warmup. Linear warmup = η naik dari 0 ke η_max dalam N steps. N = 500-2000 untuk model kecil, 2000-10000 untuk LLM. Tanpa warmup, Adam bikin gradien liar karena moving average belum stabil.

**Cosine with Restarts (SGDR):** η naik kembali ke η_max setelah tiap siklus — bisa lolos dari local minima. Tiap restart efektif "mulai lagi" dengan weight yang sudah bagus. Gunakan restart period T₀ = 10-50 epoch.

**Polynomial Decay:** η = η_max × (1 - t/T)^p. p=1 (linear), p=2 (quadratic). Lebih lambat dari cosine, cocok untuk transfer learning.

**Constant + Decay:** Hold η_max untuk N% training, decay cosine sisanya. Stabil, gampang tuning.

**Per-parameter LR:** Layer pertama butuh LR lebih kecil dari layer terakhir (bottom layers fitur dasar, sudah cukup baik). Praktik di fine-tuning: LR_emb = LR_head / 10.

```
# Per-layer learning rate di HuggingFace
no_decay = ['bias', 'LayerNorm.weight']
optimizer_grouped_parameters = [
    {'params': [p for n, p in model.named_parameters() if 'encoder.layer.0' in n], 'lr': 1e-5},
    {'params': [p for n, p in model.named_parameters() if 'encoder.layer.11' in n], 'lr': 2e-5},
    ...
]
```

### Gradient Histogram Monitoring

Visualize gradien distribution tiap layer di tensorboard:
- **Grad norm per layer:** Seberapa besar update tiap layer? — kalau beda >10× antar layer, ada masalah
- **Grad/signal ratio:** Seberapa banyak noise relatif terhadap gradient magnitude? Ratio >0.1 berarti gradien didominasi noise
- **Layer saturation:** Percentage of dead neurons — untuk ReLU, >50% dead berarti model mati

Tools: `torch.utils.tensorboard`, `wandb.watch(model)`, `torch.nn.utils.clip_grad_norm_`.

Pattern untuk model sehat: semua layer punya grad norm dalam orde yang sama. Kalau layer dalam (dekat input) punya grad norm 10× lebih kecil dari layer luar → vanishing gradient.

### Practical Code Flow for Training Loop

Full training flow dengan best practices — implements gradient accumulation, mixed precision, gradient clipping, and checkpointing in one clean class:

```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torch.cuda.amp import autocast, GradScaler

class Trainer:
    def __init__(self, model, train_loader, val_loader, config):
        self.model = model
        self.train_loader = train_loader
        self.val_loader = val_loader
        self.config = config
        self.optimizer = torch.optim.AdamW(
            model.parameters(), 
            lr=config.lr, 
            weight_decay=config.weight_decay
        )
        self.scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
            self.optimizer, 
            T_max=config.epochs
        )
        self.scaler = GradScaler('cuda') if config.mixed_precision else None
        self.best_val_loss = float('inf')
        
    def train_epoch(self):
        self.model.train()
        total_loss = 0
        grad_norms = []
        
        for batch in self.train_loader:
            x, y = batch
            self.optimizer.zero_grad()
            
            if self.scaler:
                with autocast():
                    logits = self.model(x)
                    loss = nn.CrossEntropyLoss()(logits, y)
                self.scaler.scale(loss).backward()
                self.scaler.unscale_(self.optimizer)
            else:
                logits = self.model(x)
                loss = nn.CrossEntropyLoss()(logits, y)
                loss.backward()
            
            # Gradient clipping
            grad_norm = torch.nn.utils.clip_grad_norm_(
                self.model.parameters(), 
                max_norm=self.config.clip_norm
            )
            grad_norms.append(grad_norm.item())
            
            # Gradient noise injection (optional — regularization)
            if self.config.grad_noise > 0:
                for p in self.model.parameters():
                    if p.grad is not None:
                        noise = torch.randn_like(p.grad) * self.config.grad_noise
                        p.grad.add_(noise * grad_norm)
            
            if self.scaler:
                self.scaler.step(self.optimizer)
                self.scaler.update()
            else:
                self.optimizer.step()
            
            total_loss += loss.item()
            
        return total_loss / len(self.train_loader), np.mean(grad_norms)
    
    def validate(self):
        self.model.eval()
        total_loss = 0
        
        with torch.no_grad():
            for batch in self.val_loader:
                x, y = batch
                logits = self.model(x)
                loss = nn.CrossEntropyLoss()(logits, y)
                total_loss += loss.item()
                
        avg_loss = total_loss / len(self.val_loader)
        
        if avg_loss < self.best_val_loss:
            self.best_val_loss = avg_loss
            torch.save(self.model.state_dict(), 'best_model.pt')
            print(f"  ✓ New best model: val_loss={avg_loss:.4f}")
            
        return avg_loss
    
    def fit(self):
        for epoch in range(self.config.epochs):
            train_loss, grad_norm = self.train_epoch()
            val_loss = self.validate()
            self.scheduler.step()
            current_lr = self.scheduler.get_last_lr()[0]
            print(f"Epoch {epoch+1:3d}/{self.config.epochs} | "
                  f"train={train_loss:.4f} val={val_loss:.4f} | "
                  f"LR={current_lr:.2e} | grad={grad_norm:.2f}")
```

### Visualizing Gradients (PyTorch Hooks)

```python
# Register hooks untuk monitor gradien per layer
grad_stats = {}

def hook_fn(name):
    def fn(grad):
        grad_stats[name] = {
            'mean': grad.mean().item(),
            'std': grad.std().item(),
            'norm': grad.norm().item(),
            'min': grad.min().item(),
            'max': grad.max().item(),
        }
    return fn

for name, param in model.named_parameters():
    if param.requires_grad:
        param.register_hook(hook_fn(name))
```

Ini berguna untuk debug training. Plot `grad_stats` per epoch untuk lihat layer mana yang vanish/explode.
 
---

## Referensi

- Rumelhart, D.E., Hinton, G.E., Williams, R.J. (1986). *Learning representations by back-propagating errors.* Nature. — Paper paling fundamental tentang backpropagation, yang pertama kali memperkenalkannya secara praktis untuk training neural network.
- Goodfellow, I., Bengio, Y., Courville, A. (2016). *Deep Learning.* MIT Press. Chapters 6, 8. — **Buku referensi utama tentang backpropagation dan optimisasi.**
- Kingma, D.P., Ba, J. (2015). *Adam: A Method for Stochastic Optimization.* ICLR.
- Loshchilov, I., Hutter, F. (2019). *Decoupled Weight Decay Regularization.* ICLR. — AdamW.
- He, K. et al. (2015). *Delving Deep into Rectifiers.* ICCV. — He init.
- Glorot, X., Bengio, Y. (2010). *Understanding the difficulty of training deep feedforward neural networks.* AISTATS.
- Ba, J.L., Kiros, J.R., Hinton, G.E. (2016). *Layer Normalization.* arXiv.
- Ioffe, S., Szegedy, C. (2015). *Batch Normalization.* ICML.
- Foret, P. et al. (2021). *Sharpness-Aware Minimization.* ICLR.
- Smith, L.N. (2018). *A disciplined approach to neural network hyper-parameters.* arXiv.
- Micikevicius, P. et al. (2018). *Mixed Precision Training.* ICLR.
- Rajbhandari, S. et al. (2020). *ZeRO: Memory Optimizations Toward Training Trillion Parameter Models.* SC.
- Paszke, A. et al. (2019). *PyTorch: An Imperative Style, High-Performance Deep Learning Library.* NeurIPS. — Framework deep learning dominan yang menggunakan reverse-mode autodiff.

---

> **Pertanyaan lanjutan:** Kalau udah paham backprop, selanjutnya batch normalization → layer normalization → transformer. Semua itu adalah "patching" masalah yang muncul dari backprop di arsitektur tertentu: residual connections fix vanishing gradient, layer norm stabilisasi distribusi activation, dan attention mechanism menggantikan RNN yang juga korban vanishing gradient.

> **Relasi dengan vault lain:** Backpropagation adalah landing page untuk memahami arsitektur modern. [[cosine-similarity-deepdive]] menjelaskan loss function yang sering dipakai di embedding models (contrastive loss, triplet loss) yang semuanya di-backprop. [[attention-mechanism-deepdive]] menjelaskan transformer di mana gradient mengalir melalui QKV projections dan softmax — pemahaman backprop penting untuk debugging attention training (entropy collapse, attention sink).
