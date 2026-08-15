---
title: MACHINE LEARNING CLASSICAL — Hierarchy of Algorithms
tags:
- machine-learning
- classical-ml
- supervised-learning
- unsupervised-learning
- ensemble-methods
aliases:
- Classical ML Hierarchy
- Machine Learning Algorithms
- Traditional ML
created: 2026-07-09
updated: 2026-08-14
status: pending
cssclasses:
  - wide-table
---

> [!abstract] The Missing Foundation
> Vault ini penuh dengan topik advanced: Agentic AI, LLM Security, Cognitive Architecture. Tapi ada lubang besar di fondasi: **Machine Learning Klasik**. Sebelum neural network, sebelum transformer, ada algoritma yang menjadi batu loncatan. Dokumen ini adalah peta hierarki dan dokumen pendalaman untuk seluruh supervised dan unsupervised learning klasik—dari KNN hingga Gradient Boosting. Bukan sekadar "panggil `scikit-learn`", tapi paham **mengapa algoritma bekerja, kapan menggunakannya, dan apa kelemahannya.**

---

## 🎯 Mengapa ML Klasik Penting di Era Deep Learning?

1. **Baseline wajib:** Sebelum deploy neural network 100 juta parameter, coba dulu Logistic Regression. Seringkali, model sederhana sudah cukup dan jauh lebih efisien.
2. **Interpretability:** Decision Tree, Naive Bayes, dan Linear Regression bisa dijelaskan ke stakeholder. Deep learning seringkali black box.
3. **Data terbatas:** Saat Anda hanya punya 500 sampel, Random Forest seringkali mengalahkan neural network.
4. **Fondasi konseptual:** Memahami bias-variance tradeoff, regularization, dan maximum likelihood di level klasik membuat Anda lebih siap memahami deep learning.
5. **Keamanan:** Model ML klasik juga bisa diserang (adversarial examples, data poisoning). Fondasi keamanan AI dimulai dari sini.

---

## 📊 Hierarchy of Classical ML Algorithms

```
MACHINE LEARNING CLASSICAL
│
├── SUPERVISED LEARNING (Data Berlabel)
│   ├── REGRESSION (Output Kontinu)
│   │   ├── Linear Regression → Regularized (Ridge, Lasso)
│   │   └── Polynomial Regression
│   │
│   └── CLASSIFICATION (Output Diskrit)
│       ├── Instance-Based → K-Nearest Neighbors (KNN)
│       ├── Probabilistic → Naive Bayes, Logistic Regression
│       ├── Tree-Based → Decision Tree, Random Forest, Gradient Boosting
│       └── Margin-Based → Support Vector Machine (SVM)
│
├── UNSUPERVISED LEARNING (Data Tidak Berlabel)
│   ├── CLUSTERING
│   │   ├── Centroid-Based → K-Means
│   │   ├── Hierarchical → Agglomerative Clustering
│   │   └── Density-Based → DBSCAN
│   │
│   └── DIMENSIONALITY REDUCTION
│       ├── Linear → PCA (Principal Component Analysis)
│       └── Non-Linear → t-SNE, UMAP
│
└── ENSEMBLE METHODS (Gabungan Model)
    ├── Bagging (Bootstrap Aggregating) → Random Forest
    └── Boosting (Sequential Improvement) → AdaBoost, Gradient Boosting, XGBoost
```

---

## 🧬 Level 0: Fondasi Matematis & Evaluasi Model

Sebelum menyentuh algoritma, pahami dulu **bagaimana model belajar dan dievaluasi.**

### Fungsi Loss & Gradient Descent

Inti dari supervised learning: temukan parameter `θ` yang meminimalkan error antara prediksi `hθ(x)` dan label sebenarnya `y`.

- **Linear Regression (MSE):** `J(θ) = (1/2m) * Σ(hθ(xⁱ) - yⁱ)²`
- **Logistic Regression (Cross-Entropy):** `J(θ) = -Σ[yⁱ log(hθ(xⁱ)) + (1-yⁱ) log(1 - hθ(xⁱ))]`

**Gradient Descent:** `θ := θ - α * ∂J/∂θ` — di mana `α` adalah learning rate. Terlalu besar: overshoot, divergen. Terlalu kecil: lambat konvergen.

### Bias-Variance Tradeoff

- **Bias (Underfitting):** Model terlalu sederhana, tidak bisa menangkap pola.
- **Variance (Overfitting):** Model terlalu kompleks, menghafal noise.
- **Tujuan:** Temukan sweet spot.

### Validation & Cross-Validation

Jangan pernah evaluasi model di data training.
- **Holdout:** 70% train, 15% validation, 15% test.
- **K-Fold Cross-Validation:** Bagi data jadi K lipatan. Latih K kali, setiap kali 1 lipatan jadi validasi. Rata-rata hasilnya.

### Metrik Evaluasi

| Metrik | Rumus | Kapan Digunakan |
|--------|-------|-----------------|
| **Accuracy** | (TP+TN)/(TP+TN+FP+FN) | Data seimbang |
| **Precision** | TP/(TP+FP) | Fokus pada false positive (spam detection) |
| **Recall** | TP/(TP+FN) | Fokus pada false negative (kanker detection) |
| **F1-Score** | 2PR/(P+R) | Keseimbangan precision-recall |
| **MSE** | Σ(ŷ - y)² / n | Regression |
| **R²** | 1 - SS_res / SS_tot | Regression (seberapa baik model vs baseline) |

---

## 📈 Level 1: Regression — Memprediksi Nilai Kontinu

### Linear Regression

**Fondasi Matematis:** Cari garis `y = mx + b` (atau hyperplane `y = Xθ`) yang meminimalkan jumlah kuadrat error.

**Algoritma:**
1. **Normal Equation (Closed-Form):** `θ = (XᵀX)⁻¹Xᵀy`. Solusi eksak, tapi mahal di komputasi untuk fitur banyak: O(n³).
2. **Gradient Descent:** Iteratif, skalabel. `θ := θ - α * (1/m) * Xᵀ(Xθ - y)`.

**Regularization:** Mencegah overfitting dengan menambahkan penalti ke loss function.
- **Ridge (L2):** `J(θ) = MSE + λ * Σθⱼ²`. Menekan koefisien mendekati 0.
- **Lasso (L1):** `J(θ) = MSE + λ * Σ|θⱼ|`. Bisa membuat koefisien tepat 0 → feature selection.

**Asumsi Penting:** Linearitas, independensi, homoskedastisitas (varians error konstan), normalitas error.

**Implementasi Python (Normal Equation + Gradient Descent):**
```python
import numpy as np

class LinearRegression:
    def fit_normal(self, X, y):
        X_b = np.c_[np.ones((X.shape[0], 1)), X]  # Tambah bias term
        self.theta = np.linalg.inv(X_b.T @ X_b) @ X_b.T @ y
    
    def fit_gd(self, X, y, lr=0.01, n_iters=1000):
        X_b = np.c_[np.ones((X.shape[0], 1)), X]
        self.theta = np.random.randn(X_b.shape[1])
        for _ in range(n_iters):
            gradients = (1/X_b.shape[0]) * X_b.T @ (X_b @ self.theta - y)
            self.theta -= lr * gradients
    
    def predict(self, X):
        X_b = np.c_[np.ones((X.shape[0], 1)), X]
        return X_b @ self.theta
```

---

## 🎯 Level 2: Classification — Memprediksi Kategori

### K-Nearest Neighbors (KNN)

**Fondasi:** "Burung yang sama terbang bersama." Tidak ada training. Simpan semua data. Untuk memprediksi titik baru, cari K tetangga terdekat, voting.

**Matematis:** `ŷ = mode(y_i untuk i di K tetangga terdekat dari x)`

**Hyperparameter Kritis:**
- **K (jumlah tetangga):** K kecil (1-3): overfit, noise-sensitive. K besar (>30): underfit, smooth boundary.
- **Distance Metric:** Euclidean (L2), Manhattan (L1), Minkowski.

**Kelebihan:** Sederhana, non-parametrik, bisa menangani multi-class secara alami.
**Kelemahan:** "Curse of dimensionality" — di dimensi tinggi, semua titik terlihat berjarak sama. Inference lambat O(n*d) per query.

**Koneksi Vault:** KNN adalah analogi dari `imsi-catcher` — mencari perangkat terdekat berdasarkan kekuatan sinyal. Konsep tetangga terdekat juga dipakai di `maltego` untuk link analysis.

**Implementasi Python (from scratch):**
```python
from collections import Counter
import numpy as np

class KNN:
    def __init__(self, k=3):
        self.k = k
    
    def fit(self, X, y):
        self.X_train = X
        self.y_train = y
    
    def predict(self, X):
        return np.array([self._predict_one(x) for x in X])
    
    def _predict_one(self, x):
        distances = np.sqrt(np.sum((self.X_train - x)**2, axis=1))
        k_idx = np.argsort(distances)[:self.k]
        k_labels = self.y_train[k_idx]
        return Counter(k_labels).most_common(1)[0][0]
```

---

### Naive Bayes

**Fondasi:** Teorema Bayes + asumsi "naif" bahwa semua fitur independen satu sama lain.

**Matematis:** `P(Cₖ|x) ∝ P(Cₖ) * Πᵢ P(xᵢ|Cₖ)`
- `P(Cₖ)`: Prior probability kelas.
- `P(xᵢ|Cₖ)`: Likelihood fitur i diberikan kelas Cₖ.

**Varian berdasarkan likelihood:**
- **Gaussian NB:** `P(xᵢ|C) = N(xᵢ; μc, σc²)`. Untuk data kontinu.
- **Multinomial NB:** `P(xᵢ|C) = (count(xᵢ, C) + α) / (Σ count + α*n_features)`. Untuk text classification (bag-of-words).
- **Bernoulli NB:** Seperti multinomial, tapi biner (ada/tidak).

**Kelebihan:** Cepat, bagus untuk data teks, robust terhadap missing values.
**Kelemahan:** Asumsi independensi hampir selalu salah di dunia nyata. Tapi surprisingly, seringkali masih akurat.

**Koneksi Vault:** Naive Bayes adalah fondasi `google-dorks` — mengklasifikasikan dokumen sebagai "mengandung informasi sensitif" atau tidak.

**Implementasi Python (Gaussian NB from scratch):**
```python
import numpy as np

class GaussianNB:
    def fit(self, X, y):
        self.classes = np.unique(y)
        self.theta = {}  # (mean, var) per kelas per fitur
        for c in self.classes:
            X_c = X[y == c]
            self.theta[c] = (X_c.mean(axis=0), X_c.var(axis=0) + 1e-9)
    
    def _pdf(self, x, mean, var):
        return (1 / np.sqrt(2*np.pi*var)) * np.exp(-((x-mean)**2 / (2*var)))
    
    def predict(self, X):
        posteriors = []
        for c in self.classes:
            prior = np.log(len(self.X_train[self.y_train==c]) / len(self.X_train))
            likelihood = np.sum(np.log(self._pdf(X, *self.theta[c])), axis=1)
            posteriors.append(prior + likelihood)
        return self.classes[np.argmax(posteriors, axis=0)]
```

---

### Logistic Regression

**Fondasi:** Meskipun namanya "regresi", ini adalah **classification**. Fungsinya adalah memetakan output linear ke probabilitas menggunakan fungsi sigmoid.

**Matematis:**
- Linear model: `z = Xθ`
- Sigmoid: `hθ(x) = 1 / (1 + e⁻ᶻ)` → output probabilitas [0,1]
- Decision boundary: `hθ(x) ≥ 0.5 → kelas 1, hθ(x) < 0.5 → kelas 0`

**Optimasi:** Cross-entropy loss + Gradient Descent. Tidak ada closed-form solution.

**Multi-class Extension:** One-vs-Rest (OvR) atau Softmax Regression.

**Koneksi Vault:** Logistic Regression adalah neuron tunggal dengan aktivasi sigmoid—jembatan langsung ke Neural Network ([[swarm-ai-imam-robandi]]).

```python
class LogisticRegression:
    def fit(self, X, y, lr=0.01, n_iters=1000):
        X_b = np.c_[np.ones((X.shape[0], 1)), X]
        self.theta = np.zeros(X_b.shape[1])
        for _ in range(n_iters):
            z = X_b @ self.theta
            preds = 1 / (1 + np.exp(-z))
            gradients = (1/X_b.shape[0]) * X_b.T @ (preds - y)
            self.theta -= lr * gradients
    
    def predict_proba(self, X):
        X_b = np.c_[np.ones((X.shape[0], 1)), X]
        return 1 / (1 + np.exp(-X_b @ self.theta))
    
    def predict(self, X):
        return (self.predict_proba(X) >= 0.5).astype(int)
```

---

### Decision Tree

**Fondasi:** Rekursif mempartisi data menjadi subset yang lebih murni. Setiap split memaksimalkan "information gain" atau meminimalkan "impurity."

**Metric Split:**
- **Gini Impurity:** `Gini = 1 - Σp²ᵢ`. Dipakai oleh CART.
- **Entropy:** `Entropy = -Σpᵢ log₂(pᵢ)`. Information Gain = Entropy(parent) - weighted avg Entropy(children).
- **Regression:** MSE reduction.

**Hyperparameter Penting:**
- **max_depth:** Cegah overfitting.
- **min_samples_split:** Node tidak di-split jika sampel < threshold.
- **criterion:** `gini` atau `entropy`.

**Kelebihan:** Interpretable (bisa divisualisasikan sebagai flowchart), tidak butuh scaling.
**Kelemahan:** Sangat mudah overfit (high variance). Satu perubahan kecil di data bisa mengubah total struktur pohon.

**Koneksi Vault:** Decision tree adalah fondasi Random Forest dan Gradient Boosting. Pola pengambilan keputusan mirip dengan [[ai-comm-protocol-deep-dive]] (decision tree protocol selection).

---

### Support Vector Machine (SVM)

**Fondasi:** Cari **hyperplane** yang memaksimalkan margin antara dua kelas. Titik-titik yang menentukan margin disebut **support vectors.**

**Matematis (Hard Margin):** `min (1/2)||w||²` subject to `yᵢ(w·xᵢ + b) ≥ 1 ∀i`

**Soft Margin (Real World):** Izinkan beberapa titik melanggar margin dengan penalti `C`.
- `C` besar → margin sempit, sedikit pelanggaran → overfit.
- `C` kecil → margin lebar, toleransi pelanggaran → underfit.

**Kernel Trick:** Proyeksikan data ke dimensi lebih tinggi agar linearly separable.
- **Linear:** `K(x, x') = x·x'`
- **Polynomial:** `K(x, x') = (γx·x' + r)ᵈ`
- **RBF (Gaussian):** `K(x, x') = exp(-γ||x-x'||²)` — paling populer.

**Koneksi Vault:** Konsep "margin" dan "support vectors" adalah analogi dari [[dual-use-spectrum-and-ethical-framework]] — titik-titik di perbatasan (support vectors) menentukan batas etika (margin). SVM juga digunakan untuk deteksi adversarial examples.

---

## 🧩 Level 3: Unsupervised Learning — Menemukan Struktur Tersembunyi

### K-Means Clustering

**Fondasi:** Partisi data menjadi K cluster di mana setiap titik ditugaskan ke centroid terdekat.

**Algoritma Lloyd:**
1. Inisialisasi K centroid (acak atau K-Means++).
2. Assignment: Tugaskan setiap titik ke centroid terdekat.
3. Update: Hitung ulang centroid sebagai rata-rata titik di cluster.
4. Ulangi 2-3 sampai konvergen.

**Memilih K:** Elbow Method (plot inertia vs K), Silhouette Score.

**Koneksi Vault:** K-Means adalah fondasi segmentasi di tools seperti `maltego` — mengelompokkan entitas berdasarkan karakteristik.

```python
class KMeans:
    def fit(self, X, k, max_iters=100):
        self.centroids = X[np.random.choice(len(X), k, replace=False)]
        for _ in range(max_iters):
            # Assignment
            distances = np.sqrt(((X - self.centroids[:, np.newaxis])**2).sum(axis=2))
            labels = np.argmin(distances, axis=0)
            # Update
            new_centroids = np.array([X[labels == i].mean(axis=0) for i in range(k)])
            if np.allclose(self.centroids, new_centroids):
                break
            self.centroids = new_centroids
        return labels
```

---

### PCA (Principal Component Analysis)

**Fondasi:** Reduksi dimensi linear. Cari arah (principal components) yang memaksimalkan varians data.

**Matematis:** `C = (1/n) XᵀX` (covariance matrix) → eigenvectors `V` dan eigenvalues `λ`. Pilih `k` eigenvectors dengan `λ` terbesar.

**Koneksi Vault:** PCA adalah fondasi dari [[math-and-algorithms]] (SVD, eigenvalues). Dipakai untuk reduksi dimensi embedding di pipeline AI.

```python
class PCA:
    def fit_transform(self, X, k):
        X_centered = X - X.mean(axis=0)
        cov = (X_centered.T @ X_centered) / (X.shape[0] - 1)
        eigenvalues, eigenvectors = np.linalg.eig(cov)
        idx = np.argsort(eigenvalues)[::-1][:k]
        return X_centered @ eigenvectors[:, idx]
```

---

## 🌲 Level 4: Ensemble Methods — Kekuatan Kolektif

### Random Forest (Bagging)

**Fondasi:** Latih banyak Decision Tree di subset data berbeda (bootstrap) + subset fitur berbeda (feature bagging). Voting mayoritas untuk klasifikasi, rata-rata untuk regresi.

**Mengapa bekerja:** Rata-rata dari banyak model high-variance, low-bias menghasilkan model low-variance, low-bias. Variance berkurang karena error saling meniadakan.

**Koneksi Vault:** Konsep "ensemble" mirip dengan [[agentic-ai-mcp-roadmap]] (multi-agent consensus). Setiap tree adalah "weak learner" yang dikombinasikan menjadi "strong learner."

---

### Gradient Boosting (XGBoost)

**Fondasi:** Alih-alih melatih model paralel (bagging), boosting melatih model **sekuensial**. Setiap model baru mengoreksi error model sebelumnya.

**Algoritma:**
1. Inisialisasi dengan prediksi konstan (rata-rata y).
2. Untuk setiap iterasi:
   - Hitung residual (error) = `y - ŷ_sebelumnya`.
   - Latih Decision Tree kecil untuk memprediksi residual.
   - Update prediksi: `ŷ_baru = ŷ_lama + lr * prediksi_residual`.

**Koneksi Vault:** Gradient Boosting adalah metafora [[test-time-compute-system2]] — iteratif memperbaiki reasoning. XGBoost adalah salah satu algoritma paling sukses di Kaggle.

---

## 📊 Cheat Sheet: Kapan Menggunakan Apa

| Skenario | Algoritma | Alasan |
|----------|-----------|--------|
| Data sedikit, interpretability wajib | Logistic Regression / Decision Tree | Sederhana, bisa dijelaskan |
| Data banyak, non-linear, akurasi > interpretability | Random Forest / XGBoost | Ensemble biasanya menang |
| Data teks (spam, sentiment) | Naive Bayes | Cepat, bagus untuk high-dim sparse |
| Data tidak berlabel, cari kelompok | K-Means / DBSCAN | Unsupervised clustering |
| High-dim data, butuh reduksi dimensi | PCA | Linear, cepat, interpretable |
| Data tidak seimbang (fraud, intrusion) | XGBoost + SMOTE | Boosting + resampling |

---

## 🔗 Koneksi ke Vault

| Dokumen di Vault                                                   | Koneksi                                          |
| ------------------------------------------------------------------ | ------------------------------------------------ |
| [[math-and-algorithms]]                                            | Fondasi matematis semua algoritma di atas        |
| [[swarm-ai-imam-robandi]]                                          | PSO, GA sebagai alternatif optimasi non-gradient |
| [[agentic-ai-mcp-roadmap]]                                         | Agent ensemble ≈ Random Forest untuk agen        |
| [[test-time-compute-system2]]                                      | Boosting ≈ Reasoning iteratif                    |
| [[llm-security-red-teaming-attack-surface-ai-layer\|llm-security]] | Adversarial examples di ML klasik                |
| [[ai-comm-protocol-deep-dive]]                                     | Decision tree untuk protocol selection           |

---

*Machine Learning Classical | Hierarchy of Algorithms | KNN to Gradient Boosting · From Scratch Python*

audited
---
