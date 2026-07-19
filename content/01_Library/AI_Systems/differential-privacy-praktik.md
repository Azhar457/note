---
title: "Differential Privacy & Privacy-Preserving ML — Deep Dive: Epsilon, Laplace, RAPPOR, PATE, DP-SGD, Tooling"
tags:
  - differential-privacy
  - privacy
  - machine-learning
  - cryptography
  - federated-learning
aliases:
  - "differential-privacy-praktik"
created: "2026-07-18"
updated: "2026-07-18"
status: operational
cssclasses:
  - wide-table
---

# 🔒 Differential Privacy & Privacy-Preserving ML — Deep Dive: Epsilon, Laplace, RAPPOR, PATE, DP-SGD, Tooling

> Panduan komprehensif differential privacy dari konsep epsilon sampai implementasi DP-SGD. Mencakup mekanisme DP (Laplace, Gaussian, Exponential), RAPPOR untuk federated data collection, PATE untuk private model training, DP-SGD untuk deep learning, dan perbandingan library (OpenDP, Opacus, diffprivlib, SmartNoise). Vault udah punya [[cryptography-biometrics]] (teori kriptografi Level 6: ZKP, FHE), [[digital-privacy-anonymity]] (Tor/I2P di network layer), [[synthetic-data-privacy]] (data sintetik), dan [[ai-governance-ethics]] (regulatory framework). Catatan ini mengisi gap: **implementasi praktis privacy-preserving tech** yang jadi jembatan antara teori dan production.

> [!info] Posisi di Vault
> Nota ini terkait dengan [[cryptography-biometrics]] (DP adalah implementasi praktis dari privacy tech yang dibahas di Level 6), [[digital-privacy-anonymity]] (DP melengkapi privacy di data layer — network layer sudah dibahas Tor/I2P), [[synthetic-data-privacy]] (data sintetik sering dikombinasikan dengan DP), [[ai-governance-ethics]] (EU AI Act mewajibkan privacy-preserving techniques untuk high-risk AI), [[adversarial-machine-learning]] (membership inference attack adalah motivasi utama DP), dan [[machine-learning-classical-hierarchy]] (DP-SGD bisa diterapkan di semua model).

---

## Daftar Isi

- [[#Konsep Inti — Epsilon Privacy Budget]]
- [[#Mekanisme DP]]
- [[#Komposisi — Sequential vs Parallel]]
- [[#RAPPOR — Federated Data Collection]]
- [[#PATE — Private Aggregation of Teacher Ensembles]]
- [[#DP-SGD — Training Model dengan Differential Privacy]]
- [[#Local vs Central DP]]
- [[#Tooling & Library Comparison]]
- [[#Koneksi ke Vault]]

---

## Konsep Inti — Epsilon Privacy Budget

### Formal Definition

Suatu algoritma acak M memenuhi (ε, δ)-differential privacy jika untuk semua dataset D dan D' yang berbeda 1 baris, dan semua subset S dari output:

```
Pr[M(D) ∈ S] ≤ e^ε · Pr[M(D') ∈ S] + δ
```

### Artinya dalam Bahasa Manusia

Menambahkan atau menghapus **satu baris data** tidak mengubah distribusi output secara signifikan. Attacker tidak bisa bedain apakah data seorang individu ada dalam dataset atau tidak.

### Memilih Epsilon

| ε Value    | Privacy Level                                  | Noise            | Utility       | Contoh Use Case                      |
| ---------- | ---------------------------------------------- | ---------------- | ------------- | ------------------------------------ |
| 0.01 - 0.1 | **Sangat Kuat** — almost no info leakage       | Noise dominan    | Rendah        | Sensus publik, data kesehatan publik |
| 0.1 - 1.0  | **Kuat** — individu tidak bisa diidentifikasi  | Signifikan       | Sedang        | Statistik agregat, riset publik      |
| 1.0 - 5.0  | **Sedang** — bedain grup, bukan individu       | Moderate         | Tinggi        | Internal analytics product           |
| 5.0 - 10.0 | **Lemah** — individu bisa di-reidentifikasi    | Minimal          | Sangat Tinggi | Internal debugging, non-publik       |
| >10.0      | **Sangat Lemah** — almost no privacy guarantee | Hampir tidak ada | Hampir asli   | Data sintetik yang identity-stripped |

> [!warning] Apple & Google pakai ε tinggi
> Apple dulunya klaim ε = 1-2 untuk keyboard suggestions, tapi riset independen nemuin effective ε > 10 karena komposisi query. Google RAPPOR di Chrome pake ε ~ 1-3. **Jangan percaya klaim ε sendirian — selalu verifikasi dengan empirical privacy audit.**

### Budget Management

Setiap query menghabiskan sebagian epsilon budget. Total ε untuk satu dataset sebaiknya ≤ 1 untuk publikasi eksternal.

**Komposisi sequential:** total ε = ε₁ + ε₂ + ... + εₙ (worst case)
**Komposisi parallel:** total ε = max(ε₁, ε₂, ..., εₙ) — kalau query di subset disjoint

## Mekanisme DP

### 1. Laplace Mechanism

Fungsi dasar untuk **numerik** (count, sum, mean).

```
M(D) = f(D) + Lap(Δf / ε)

Δf = sensitivity = max |f(D) - f(D')| untuk D dan D' beda 1 baris
```

**Contoh:** Hitung jumlah unik visitor website.

```
Δf = 1 (tambah/hapus 1 orang ubah count sebesar 1)
ε = 0.1
Noise = Laplace(10)
Output = real_count + noise
```

### 2. Gaussian Mechanism

Untuk (ε, δ)-DP dengan δ kecil (biasanya < 1/n).

```
M(D) = f(D) + N(0, σ²)

σ = Δf · √(2 ln(1.25/δ)) / ε
```

Lebih fleksibel dari Laplace (bisa tune δ), tapi δ = probability kebocoran kecil.

### 3. Exponential Mechanism

Untuk **non-numerik** — pilih item terbaik dari set terbatas.

```
Pr[output = r] ∝ exp(ε · u(r) / 2Δu)

di mana u = utility function, Δu = sensitivity dari u
```

**Contoh:** Pilih fitur paling signifikan tanpa expose distribusi pastinya.

## Komposisi — Sequential vs Parallel

### Sequential Composition

Kalau jalanin N query berturut-turut dengan mekanisme DP yang independen:

```
Total_ε = ε₁ + ε₂ + ... + εₙ
```

Ini **worst case** — cocok untuk queries on overlapping datasets.

### Parallel Composition

Kalau query di subset disjoint (partition dataset):

```
Total_ε = max(ε₁, ε₂, ..., εₙ)
```

Kenapa? Karena setiap baris data cuma masuk 1 partition, jadi cuma kena 1 query.

### Advanced Composition

Better bound untuk sequential:

```
Total_ε ≈ √(2k ln(1/δ')) · ε + k · ε · (e^ε - 1)
```

Ini lebih ketat dari sequential composition untuk k besar — memungkinkan lebih banyak query dengan total ε yang sama.

## RAPPOR — Federated Data Collection

> **Randomized Aggregatable Privacy-Preserving Ordinal Response** (Google, 2014). Digunakan Google Chrome untuk kumpulin statistik usage tanpa tau data individu.

### Arsitektur

```
Client-side:
  1. Nilai asli → Bloom filter (vektor bit)
  2. Permanent randomized response (PRR) — 1x per nilai
  3. Instantaneous randomized response (IRR) — tiap report

Server-side:
  4. Kumpulin ribuan noisy report
  5. Dekonvolusi: estimasi distribusi asli
  6. Output: statistik agregat
```

### Security Guarantee

- Server **tidak pernah lihat data asli**
- Individual report **tidak bisa di-deanonymize**
- Hanya distribusi agregat yang bisa direcover
- Privacy tergantung ε dan jumlah participant (lebih banyak = lebih akurat)

### Kapan Pakai RAPPOR?

✅ Produk dengan banyak user (>10K)
✅ Butuh insight agregat, bukan individual
✅ Data sensitif (browsing history, lokasi, health)

❌ Dataset kecil (<1000 user) — noise terlalu besar
❌ Butuh data individual untuk debugging
❌ Data publik yang sudah aman

## PATE — Private Aggregation of Teacher Ensembles

> Private Aggregation of Teacher Ensembles — training model ML dengan DP tanpa akses langsung ke data sensitif.

### Flow

```
Data Sensitif → Teacher 1 → Prediksi (noised via gaussian)
             → Teacher 2 → Prediksi (noised)
             → Teacher N → Prediksi (noised)
                           |
                 Agregasi suara + DP noise (PATE mechanism)
                           |
                 Student Model (train di publik data + label DP)
```

### Cara Kerja

1. **Teacher models** (N model) di-train di partition data sensitif
2. Tiap teacher generate prediksi untuk data publik
3. **PATE mechanism** agregasi suara guru + DP noise
4. **Student model** di-train di data publik dengan label dari PATE
5. Student model bisa dipublikasi tanpa expose data sensitif

### Advantages vs DP-SGD

| Aspek            | PATE                                       | DP-SGD                                    |
| ---------------- | ------------------------------------------ | ----------------------------------------- |
| Training Code    | Teacher standard training, no modification | Butuh gradient clipping + noise injection |
| Privacy Analysis | Sederhana (count queries)                  | Complex (moment accountant)               |
| Scalability      | Limited by ensemble size                   | Scales to large models                    |
| Best For         | Small-med model, classification            | Large model, any task                     |

## DP-SGD — Training Model dengan Differential Privacy

Modifikasi SGD standard untuk training deep learning dengan DP guarantee.

### Algoritma

```
For each batch:
  1. Forward pass → compute loss for each sample
  2. Backward pass → compute gradient for each sample (per-sample gradient)
  3. Clip gradient: g_i = g_i / max(1, ||g_i||₂ / C)   — batasi norm ke C
  4. Aggregate: g_bar = (1/B) * Σ g_i + N(0, σ²)       — noise
  5. Update: θ = θ - η · g_bar
```

### Parameter Kunci

| Parameter           | Efek                                                  | Typical Value |
| ------------------- | ----------------------------------------------------- | ------------- |
| **C** (clip norm)   | Semakin kecil, semakin banyak info hilang             | 0.1 - 1.0     |
| **σ** (noise scale) | Semakin besar, semakin private (ε kecil)              | 0.1 - 10      |
| **B** (batch size)  | Semakin besar, semakin bagus privacy-utility tradeoff | 256 - 4096    |
| **Epochs**          | Semakin banyak, semakin banyak ε dikonsumsi           | 1 - 10        |

### Library

| Library           | Framework  | Fitur                                     | Best For           |
| ----------------- | ---------- | ----------------------------------------- | ------------------ |
| **Opacus** (Meta) | PyTorch    | DP-SGD, privacy accountant, virtual batch | PyTorch user       |
| **TF Privacy**    | TensorFlow | DP-SGD, DP-Adam                           | TensorFlow user    |
| **JAX DP**        | JAX        | DP-SGD, DP optimizer                      | JAX user, research |
| **Flax DP**       | Flax/JAX   | DP-SGD in Flax                            | JAX production     |

## Local vs Central DP

| Aspek                         | Local DP                                       | Central DP                          |
| ----------------------------- | ---------------------------------------------- | ----------------------------------- |
| **Siapa yang noise-in data?** | Client (browser, app)                          | Server (trusted aggregator)         |
| **Trust model**               | Trust nobody (server juga gak bisa lihat data) | Trust server (server lihat data)    |
| **Noise level**               | Tinggi (per-client noise)                      | Rendah (server bisa aggregate dulu) |
| **Utility**                   | Rendah untuk dataset kecil                     | Tinggi                              |
| **Use Case**                  | Google Chrome, Apple iOS telemetry             | Sensus, database publikasi          |
| **Contoh Implementasi**       | RAPPOR                                         | OpenDP, SmartNoise                  |

## Tooling & Library Comparison

| Library                           | Mekanisme                      | Bahasa           | DP Type       | Best For                          |
| --------------------------------- | ------------------------------ | ---------------- | ------------- | --------------------------------- |
| **OpenDP** (Harvard)              | Laplace, Gaussian, Exponential | Python, Rust     | Central       | Statistik agregat, riset, edukasi |
| **diffprivlib** (IBM)             | Semua mekanisme dasar          | Python           | Central/Local | Eksperimen, pembelajaran          |
| **Opacus** (Meta)                 | DP-SGD                         | Python (PyTorch) | Central       | Deep learning model training      |
| **SmartNoise** (Microsoft)        | SQL query dengan DP            | Python, R        | Central       | SQL database dengan DP            |
| **PipelineDP** (Google/OpenMined) | DP pipeline                    | Python           | Local/Central | Production data pipeline          |
| **Tumult Analytics**              | DP untuk dataframe             | Python           | Central       | Analisis dataframe dengan DP      |

---

## Koneksi ke Vault

- [[cryptography-biometrics]] — Teori kriptografi Level 6 (ZKP, FHE, MPC): DP adalah implementasi praktis
- [[digital-privacy-anonymity]] — Privasi di network layer (Tor, I2P, Mixnet): DP melengkapi di data layer
- [[synthetic-data-privacy]] — Data sintetik + DP = privacy guarantee yang provable
- [[ai-governance-ethics]] — EU AI Act: DP adalah technical requirement untuk high-risk AI
- [[adversarial-machine-learning]] — Membership inference attack: motivasi utama differential privacy
- [[machine-learning-classical-hierarchy]] — DP-SGD bisa diterapkan di supervised & unsupervised
- [[ai-engineering-stack-roadmap]] — Posisi privacy dalam AI engineering stack
