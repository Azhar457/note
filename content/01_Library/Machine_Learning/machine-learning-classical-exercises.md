---
title: "MACHINE LEARNING CLASSICAL — Soal, Latihan & Studi Kasus"
tags:
  - machine-learning
  - exercises
  - practice
  - case-studies
aliases:
  - ML Exercises
  - Machine Learning Practice
created: 2026-07-09
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Dari Teori ke Praktik
> Dokumen ini adalah pendamping dari [[Note/01_Library/Machine_Learning/hierarchy-classical-ml-algorithms]]. Setelah memahami arsitektur setiap algoritma, saatnya menguji pemahaman dengan soal konseptual, implementasi kode, dan studi kasus dunia nyata. Setiap bagian mencakup pertanyaan, petunjuk, dan solusi lengkap.

---

## 📚 Format Soal

Setiap soal memiliki:
- **Tipe:** Konseptual / Kode / Studi Kasus
- **Kesulitan:** ⭐ (Dasar) hingga ⭐⭐⭐⭐⭐ (Lanjutan)
- **Algoritma Target:** Algoritma spesifik yang diuji

---

## 🔢 Bagian 1: Regresi Linear & Regularisasi

### Soal 1.1 — Regresi Linear Sederhana ⭐
**Tipe:** Kode  
**Algoritma:** Linear Regression (Normal Equation)

Implementasikan regresi linear dari nol menggunakan Normal Equation. Uji pada dataset buatan: `y = 3*X + 5 + noise`.

```python
# Template
import numpy as np

# Data
np.random.seed(0)
X = 2 * np.random.rand(100, 1)
y = 5 + 3 * X + np.random.randn(100, 1) * 0.5

# TODO: Implementasikan normal equation
```

**Pertanyaan:**
1. Berapa nilai `θ₀` (intercept) dan `θ₁` (slope) yang dihasilkan?
2. Mengapa kita perlu menambahkan kolom 1 ke matriks X?

**Solusi**

```python
X_b = np.c_[np.ones((100, 1)), X]  # tambah kolom bias
theta = np.linalg.inv(X_b.T @ X_b) @ X_b.T @ y
print(f"Intercept: {theta[0][0]:.4f}, Slope: {theta[1][0]:.4f}")
```
Nilai mendekati 5 dan 3. Kolom 1 untuk bias term (θ₀).

---

### Soal 1.2 — Overfitting vs Underfitting ⭐⭐
**Tipe:** Konseptual  
**Algoritma:** Polynomial Regression

Anda memiliki data dengan hubungan non-linear. Anda mencoba regresi linear (degree=1) dan regresi polinomial degree=15.

1. Mana yang akan underfit? Mengapa?
2. Mana yang akan overfit? Apa indikatornya?
3. Teknik apa yang bisa mencegah overfitting pada polynomial regression?

**Solusi**
1. Degree=1 underfit karena terlalu sederhana untuk data non-linear. Bias tinggi.
2. Degree=15 overfit karena terlalu fleksibel, menghafal noise. Variance tinggi.
3. Regularisasi (Ridge/Lasso), kurangi degree, lebih banyak data.

---

### Soal 1.3 — Lasso vs Ridge ⭐⭐⭐
**Tipe:** Konseptual + Kode  
**Algoritma:** Lasso, Ridge Regression

Dataset memiliki 100 fitur, tapi hanya 5 yang relevan. Anda ingin sekaligus melakukan feature selection.

1. Mana yang lebih cocok: Lasso (L1) atau Ridge (L2)? Mengapa?
2. Apa yang terjadi pada koefisien fitur tidak relevan di Lasso?

```python
from sklearn.linear_model import Lasso, Ridge
from sklearn.datasets import make_regression

X, y, true_coef = make_regression(n_samples=100, n_features=20, n_informative=5,
                                   noise=0.1, coef=True, random_state=42)

# TODO: Latih Lasso dan Ridge, bandingkan koefisien
```

**Solusi**
1. Lasso (L1) karena penalti L1 dapat mendorong koefisien ke nol, melakukan feature selection. Ridge (L2) hanya mengecilkan, tidak menolkan.
2. Koefisien fitur tidak relevan akan tepat 0.

```python
lasso = Lasso(alpha=0.1).fit(X, y)
ridge = Ridge(alpha=0.1).fit(X, y)
print(f"Fitur non-zero Lasso: {np.sum(lasso.coef_ != 0)}")
print(f"Fitur non-zero Ridge: {np.sum(ridge.coef_ != 0)}")
```

---

## 🎯 Bagian 2: Klasifikasi KNN & Naive Bayes

### Soal 2.1 — KNN dari Nol ⭐⭐
**Tipe:** Kode  
**Algoritma:** K-Nearest Neighbors

Implementasikan KNN classifier dari nol menggunakan Euclidean distance. Uji pada dataset Iris (2 fitur saja untuk visualisasi).

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split

iris = load_iris()
X = iris.data[:, :2]  # hanya 2 fitur pertama
y = iris.target
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# TODO: Implementasi KNN
```

**Pertanyaan:**
1. Apa yang terjadi jika K=1? Bagaimana decision boundary-nya?
2. Apa kelemahan utama KNN pada dataset berdimensi tinggi?

**Solusi**
1. K=1: Overfit, decision boundary sangat kompleks, sensitif noise.
2. Curse of dimensionality: semua titik tampak sama jauh, distance metric kehilangan makna.

```python
class KNN:
    def __init__(self, k=3):
        self.k = k
    def fit(self, X, y):
        self.X_train, self.y_train = X, y
    def predict(self, X):
        preds = []
        for x in X:
            dists = np.sqrt(np.sum((self.X_train - x)**2, axis=1))
            k_idx = np.argsort(dists)[:self.k]
            k_labels = self.y_train[k_idx]
            preds.append(np.bincount(k_labels).argmax())
        return np.array(preds)

knn = KNN(k=5).fit(X_train, y_train)
acc = np.mean(knn.predict(X_test) == y_test)
print(f"Akurasi: {acc:.2f}")
```

---

### Soal 2.2 — Spam Detection dengan Naive Bayes ⭐⭐⭐
**Tipe:** Studi Kasus  
**Algoritma:** Multinomial Naive Bayes

Anda memiliki dataset email: 500 spam, 500 ham. Setelah text preprocessing, Anda mendapatkan 2000 kata unik.

1. Jelaskan bagaimana Naive Bayes menghitung probabilitas email baru adalah spam.
2. Mengapa "naive"? Apakah asumsi ini realistis untuk teks?
3. Apa yang terjadi jika kata di test set tidak muncul di training set? Bagaimana mengatasinya?

**Solusi**
1. `P(spam|email) ∝ P(spam) * Π P(kata_i|spam)`. Bandingkan dengan `P(ham|email)`, pilih yang lebih besar.
2. "Naive" karena mengasumsikan setiap kata independen. Tidak realistis (kata-kata berkorelasi), tapi surprisingly efektif.
3. Probabilitas nol, bisa membuat seluruh produk nol. Solusi: Laplace smoothing (tambahkan α ke semua count).

```python
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB

# Data dummy
corpus = ["buy cheap pills now", "cheap watches for sale", 
          "meeting agenda monday", "project deadline reminder"]
labels = [1, 1, 0, 0]  # 1=spam, 0=ham

vectorizer = CountVectorizer()
X = vectorizer.fit_transform(corpus)
model = MultinomialNB(alpha=1.0).fit(X, labels)

new_email = ["buy cheap pills"]
X_new = vectorizer.transform(new_email)
print(f"Spam probability: {model.predict_proba(X_new)[0][1]:.4f}")
```

---

## 🌲 Bagian 3: Decision Tree & SVM

### Soal 3.1 — Decision Tree Split ⭐⭐
**Tipe:** Konseptual + Perhitungan  
**Algoritma:** Decision Tree

Dataset biner: 10 sampel, fitur `X` (numerik), label `y` (0/1).

| X | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|----|----|----|----|----|----|----|----|
| y | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1  |

Hitung Gini Impurity sebelum split dan setelah split di threshold X ≤ 5.5. Berapa Information Gain?

**Solusi**
Gini parent = 1 - (0.4² + 0.6²) = 0.48.

Split: kiri (X≤5.5) 5 sampel: [0,0,0,0,1] → Gini = 1 - (0.8²+0.2²) = 0.32. 
Kanan (X>5.5) 5 sampel: [1,1,1,1,1] → Gini = 0.
Gini weighted = (5/10)*0.32 + (5/10)*0 = 0.16.
Information Gain = 0.48 - 0.16 = 0.32.

---

### Soal 3.2 — SVM Kernel ⭐⭐⭐
**Tipe:** Konseptual  
**Algoritma:** SVM

Anda memiliki data dua kelas yang tersusun melingkar (konsentris). Linear SVM gagal memisahkan.

1. Kernel apa yang harus digunakan? Mengapa?
2. Jelaskan secara intuitif apa yang dilakukan kernel trick.
3. Hyperparameter `C` dan `gamma` di SVM RBF. Apa efek jika `C` terlalu besar? `gamma` terlalu besar?

**Solusi**
1. RBF (Gaussian) kernel, karena dapat menangani batas non-linear.
2. Memproyeksikan data ke ruang dimensi lebih tinggi di mana data menjadi linearly separable, tanpa menghitung transformasi secara eksplisit.
3. C besar: margin sempit, overfit, semua titik harus diklasifikasi benar. Gamma besar: pengaruh titik hanya dekat, decision boundary sangat kompleks, overfit.

```python
from sklearn.svm import SVC
from sklearn.datasets import make_circles

X, y = make_circles(n_samples=100, factor=0.5, noise=0.05, random_state=42)
svm_linear = SVC(kernel='linear').fit(X, y)  # Akan gagal
svm_rbf = SVC(kernel='rbf', C=1, gamma=0.5).fit(X, y)  # Berhasil
```

---

### Soal 3.3 — Kapan Menggunakan SVM vs Random Forest? ⭐⭐⭐
**Tipe:** Konseptual  
**Algoritma:** SVM, Random Forest

1. Kapan Anda memilih SVM dibanding Random Forest?
2. Kapan Random Forest lebih baik?
3. Mengapa scaling penting untuk SVM tapi tidak untuk Decision Tree/Random Forest?

**Solusi**
1. SVM: data berdimensi tinggi (teks, bioinformatika), margin jelas, interpretability kurang penting.
2. RF: data heterogen (campuran numerik/kategorikal), butuh feature importance, robust terhadap outlier, data banyak.
3. SVM menggunakan distance-based optimization (margin), sensitif terhadap skala. Decision tree hanya membandingkan nilai fitur, tidak peduli skala.

---

## 🧩 Bagian 4: Clustering & Dimensionality Reduction

### Soal 4.1 — K-Means Elbow Method ⭐⭐
**Tipe:** Kode  
**Algoritma:** K-Means

Generate dataset 4 cluster. Gunakan Elbow Method untuk memilih K optimal.

```python
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt

X, y_true = make_blobs(n_samples=300, centers=4, cluster_std=0.6, random_state=0)

# TODO: Plot inertia untuk K=1 sampai 10
```

**Solusi**

```python
inertias = []
for k in range(1, 11):
    kmeans = KMeans(n_clusters=k, random_state=0, n_init='auto').fit(X)
    inertias.append(kmeans.inertia_)
plt.plot(range(1, 11), inertias, marker='o')
plt.xlabel('K'); plt.ylabel('Inertia')
plt.title('Elbow Method')
plt.show()
# "Elbow" terlihat di K=4.
```

---

### Soal 4.2 — PCA untuk Kompresi Gambar ⭐⭐⭐
**Tipe:** Kode  
**Algoritma:** PCA (via SVD)

Gunakan PCA untuk kompresi gambar grayscale. Tampilkan gambar asli dan rekonstruksi dengan 10, 30, 50 komponen utama. Hitung persentase varians yang dijelaskan.

**Solusi**

```python
from sklearn.decomposition import PCA
from sklearn.datasets import load_sample_image
import matplotlib.pyplot as plt

flower = load_sample_image('flower.jpg')
gray = flower.mean(axis=2)

pca_10 = PCA(10).fit(gray)
pca_30 = PCA(30).fit(gray)
pca_50 = PCA(50).fit(gray)

fig, axes = plt.subplots(1,4, figsize=(16,4))
axes[0].imshow(gray, cmap='gray'); axes[0].set_title('Asli')
axes[1].imshow(pca_10.inverse_transform(pca_10.transform(gray)), cmap='gray'); axes[1].set_title('10 PC')
axes[2].imshow(pca_30.inverse_transform(pca_30.transform(gray)), cmap='gray'); axes[2].set_title('30 PC')
axes[3].imshow(pca_50.inverse_transform(pca_50.transform(gray)), cmap='gray'); axes[3].set_title('50 PC')
plt.show()
```

---

## 🌲 Bagian 5: Ensemble Methods

### Soal 5.1 — Random Forest vs Gradient Boosting ⭐⭐⭐
**Tipe:** Konseptual  
**Algoritma:** Random Forest, Gradient Boosting

1. Apa perbedaan utama cara kerja Random Forest dan Gradient Boosting?
2. Mana yang lebih rentan overfitting? Mengapa?
3. Mengapa Gradient Boosting biasanya lebih akurat tapi lebih lambat?

**Solusi**
1. RF: paralel, tree independen di data bootstrap, voting rata-rata. Boosting: sekuensial, setiap tree mengoreksi error sebelumnya.
2. Boosting lebih rentan overfitting karena terlalu fokus mengoreksi error, bisa menghafal noise. RF lebih robust karena averaging independen.
3. Boosting lebih akurat karena adaptif, tapi sekuensial jadi tidak bisa paralel. RF bisa paralel penuh.

---

### Soal 5.2 — XGBoost Hyperparameter Tuning ⭐⭐⭐⭐
**Tipe:** Kode  
**Algoritma:** XGBoost

Anda memiliki dataset classification dengan 5000 sampel dan 50 fitur. Lakukan hyperparameter tuning untuk `max_depth`, `learning_rate`, dan `n_estimators` menggunakan GridSearchCV.

```python
from sklearn.datasets import make_classification
from sklearn.model_selection import GridSearchCV
from xgboost import XGBClassifier

X, y = make_classification(n_samples=5000, n_features=50, n_informative=30, random_state=42)

# TODO: Tuning parameter
```

**Solusi**

```python
param_grid = {
    'max_depth': [3, 5, 7],
    'learning_rate': [0.01, 0.1, 0.3],
    'n_estimators': [100, 300]
}
xgb = XGBClassifier(use_label_encoder=False, eval_metric='logloss', random_state=42)
grid = GridSearchCV(xgb, param_grid, cv=3, scoring='accuracy', verbose=1)
grid.fit(X, y)
print(f"Best params: {grid.best_params_}, Best score: {grid.best_score_:.4f}")
```

---

## 📈 Bagian 6: Studi Kasus Terintegrasi

### Studi Kasus: Deteksi Penipuan Kartu Kredit ⭐⭐⭐⭐⭐
**Tipe:** Studi Kasus Lengkap  
**Algoritma:** Pipeline ML Klasik

Dataset: transaksi kartu kredit, 10.000 sampel, sangat tidak seimbang (0.1% fraud).

1. Bagaimana Anda menangani ketidakseimbangan kelas?
2. Algoritma apa yang cocok? (Bandingkan 3: Logistic Regression, Random Forest, XGBoost)
3. Metrik apa yang digunakan? (Accuracy tidak cukup!)
4. Bagaimana Anda mendeteksi adversarial transaction (serangan terhadap model)?

**Solusi Kerangka**

```python
from sklearn.metrics import precision_recall_curve, average_precision_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier
from sklearn.model_selection import cross_val_predict

# 1. Resampling: SMOTE oversampling atau class_weight='balanced'
# 2. Algoritma: RF dan XGBoost biasanya unggul. Logistic Regression sebagai baseline.
# 3. Metrik: Precision-Recall AUC, F1-score, bukan accuracy.
# 4. Adversarial: Monitor input distribution drift, gunakan model ensemble, adversarial training.

clf1 = LogisticRegression(class_weight='balanced')
clf2 = RandomForestClassifier(class_weight='balanced')
clf3 = XGBClassifier(scale_pos_weight=99)  # ratio non-fraud:fraud

for name, clf in [('LR', clf1), ('RF', clf2), ('XGB', clf3)]:
    y_scores = cross_val_predict(clf, X, y, cv=5, method='predict_proba')[:,1]
    ap = average_precision_score(y, y_scores)
    print(f"{name}: Average Precision = {ap:.4f}")
```

---

## 📊 Tabel Ringkasan Latihan

| No | Topik | Algoritma | Tipe | Kesulitan |
|----|-------|-----------|------|-----------|
| 1.1 | Regresi Linear | Normal Equation | Kode | ⭐ |
| 1.2 | Overfitting | Polynomial | Konseptual | ⭐⭐ |
| 1.3 | Regularisasi | Lasso vs Ridge | Konsep + Kode | ⭐⭐⭐ |
| 2.1 | KNN | Euclidean | Kode | ⭐⭐ |
| 2.2 | Spam Detection | Naive Bayes | Studi Kasus | ⭐⭐⭐ |
| 3.1 | Gini Impurity | Decision Tree | Hitung | ⭐⭐ |
| 3.2 | SVM Kernel | RBF | Konseptual | ⭐⭐⭐ |
| 3.3 | SVM vs RF | - | Konseptual | ⭐⭐⭐ |
| 4.1 | Elbow Method | K-Means | Kode | ⭐⭐ |
| 4.2 | Kompresi Gambar | PCA | Kode | ⭐⭐⭐ |
| 5.1 | Ensemble | RF vs Boosting | Konseptual | ⭐⭐⭐ |
| 5.2 | Tuning | XGBoost | Kode | ⭐⭐⭐⭐ |
| 6 | Fraud Detection | Pipeline | Studi Kasus | ⭐⭐⭐⭐⭐ |

---

## 🔗 Koneksi ke Dokumen Lain

- [[Note/01_Library/Machine_Learning/hierarchy-classical-ml-algorithms]] — Teori dan implementasi dari nol
- [[math-and-algorithms]] — Fondasi matematis
- [[swarm-ai-imam-robandi]] — Optimasi alternatif
- [[llm-security-red-teaming-attack-surface-ai-layer]] — Adversarial attack pada model ML
- [[research-methodology]] — Evaluasi eksperimen

---

*Machine Learning Classical — Soal & Latihan | Uji Pemahaman dari Regresi hingga Ensemble*
