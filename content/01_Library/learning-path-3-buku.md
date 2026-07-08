---
title: "Learning Path — 3 Buku Teknologi (MOC)"
tags:
  - library
aliases:
  - "learning-path-3-buku"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# 📚 MOC — Learning Path Tiga Buku Teknologi

> **Paradigma:** *Algoritma (Book 1) → Proses Berkualitas (Book 2) → Deploy ke Lapangan (Book 3)*

## 📂 Pendahuluan

Tiga buku ini membentuk **3 pilar kompetensi** yang saling melengkapi:

1. **AI & Optimasi** — algoritma cerdas untuk nyari solusi terbaik  
   *Implementasi: PSO, GA, Fuzzy Logic*
2. **Kualitas PL** — jamin proses dan produk gak asal jadi  
   *Framework: SQAP, CMMI, V&V (Verify-Validate)*
3. **Internet Offline** — deploy sistem ke daerah blank spot  
   *Infra: Mikrotik, LAMP Stack, PLTS*

Strategi belajar berbasis teknik "layered learning": tiap konsep dimulai dari teori, lanjut implementasi kode, dilanjut benchmark dan integrasi. Contoh: Fuzzy Logic di AI bisa diaplikasikan ke evaluasi risiko SQAP, atau ke prediksi beban daya di PLTS.

Berikut adalah penjelasan lebih lanjut tentang konsep-konsep tersebut:

* **PSO (Particle Swarm Optimization)**: sebuah algoritma optimasi yang terinspirasi dari perilaku burung dan ikan. Dalam PSO, setiap partikel memiliki posisi dan kecepatan, dan bergerak menuju optimal dengan mempertimbangkan posisi partikel lain.
* **GA (Genetic Algorithm)**: sebuah algoritma optimasi yang terinspirasi dari proses evolusi alam. Dalam GA, setiap individu memiliki genotip dan fenotip, dan berevolusi melalui proses seleksi, crossover, dan mutasi.
* **Fuzzy Logic**: sebuah pendekatan logika yang dapat menangani ketidakpastian dan keragaman. Dalam Fuzzy Logic, setiap variabel memiliki nilai keanggotaan yang berbeda-beda, dan dapat digunakan untuk membuat keputusan yang lebih akurat.

## 🎯 Visi

Tiga buku ini diangkat dari studi kasus nyata di 125 desa di Indonesia, memecahkan 3 tantangan simultan:

1. **Prediksi** — stok POS minimarket via Fuzzy/NN  
   *Accuracy requirement: >90%*  
2. **Validasi** — audit SQAP deployment Moodle  
   *ISO/IEC 12207 compliance*  
3. **Daya Mandiri** — sistem PLTS 5kW untuk 50 pelajar  
   *PP-UPR 88/2016*

Berikut adalah penjelasan lebih lanjut tentang studi kasus tersebut:

* **Studi Kasus 1**: Prediksi stok POS minimarket menggunakan Fuzzy Logic dan Neural Network. Dalam studi kasus ini, kami menggunakan data penjualan untuk memprediksi stok yang dibutuhkan, dan menggunakan Fuzzy Logic untuk menentukan nilai keanggotaan dari variabel-variabel yang digunakan.
* **Studi Kasus 2**: Validasi SQAP deployment Moodle menggunakan ISO/IEC 12207. Dalam studi kasus ini, kami menggunakan framework SQAP untuk memastikan bahwa proses pengembangan dan pengujian sistem memenuhi standar yang ditentukan.
* **Studi Kasus 3**: Sistem PLTS 5kW untuk 50 pelajar menggunakan teknologi Mikrotik dan PLTS. Dalam studi kasus ini, kami menggunakan teknologi Mikrotik untuk mengelola jaringan dan menggunakan PLTS untuk menghasilkan listrik yang dibutuhkan.

## 🔗 Cross-Reference Antar Buku

### AI → Internet Offline  
| Algoritma | Aplikasi | Kode Contoh |
|-----------|----------|-------------|
| **Genetic Algorithm** | Optimasi frekuensi Mikrotik (10-12GHz) |  
```python
def fitness(freq):
    return -interference(freq)  # minimize interference
population = init_population(100)
for gen in 1000:
    fitness = evaluate(population)
    parents = select_parents(fitness)
    offspring = crossover(parents)
    offspring = mutate(offspring, mut_rate=0.1)
    population = replace(population, offspring)
```
| **Fuzzy Logic** | Evaluasi "kualitas akses" (0-1) berdasar kecepatan/latency |  
```python
# Membership function (trapezoidal)
def speed_score(latency, throughput):
    low_access = (latency>500ms) & (throughput<5Mbps) → 0.1
    medium_access = ... → 0.5
    high_access = ... → 0.9
```

Berikut adalah penjelasan lebih lanjut tentang aplikasi Fuzzy Logic dalam evaluasi kualitas akses:

* **Membership Function**: sebuah fungsi yang digunakan untuk menentukan nilai keanggotaan dari variabel-variabel yang digunakan. Dalam contoh di atas, kami menggunakan fungsi trapezoidal untuk menentukan nilai keanggotaan dari variabel latency dan throughput.

## 📅 Jadwal Belajar (12 Minggu)

### Fase 1 — Fondasi (Minggu 1-4)
* **M1**: Analisis kebutuhan (Use Case Diagrams)  
  *Output: Requirements Specification Document*  
* **M2**: Instalasi Python 3.9 + Mikrotik CLI  
  *Setup: `pip install scikit-fuzzy` untuk Fuzzy Logic*

Berikut adalah penjelasan lebih lanjut tentang analisis kebutuhan dan instalasi Python:

* **Analisis Kebutuhan**: sebuah proses untuk menentukan kebutuhan dari sistem yang akan dibangun. Dalam contoh di atas, kami menggunakan Use Case Diagrams untuk menentukan kebutuhan dari sistem.
* **Instalasi Python**: sebuah proses untuk menginstal Python dan library yang dibutuhkan. Dalam contoh di atas, kami menggunakan `pip install scikit-fuzzy` untuk menginstal library Fuzzy Logic.

### Fase 2 — Algoritma Optimasi (Minggu 5-8)
* **M6**: PSO untuk coverage maksimum  
  *Contoh:*
  ```python
  def pso_optimize(antennas, coverage_map):
      particles = [(random_position(), velocity=0) for _ in antennas]
      for it in range(1000):
          pbest = [particle.get_coverage(coverage_map) for particle in particles]
          gbest = max(pbest)
          update_velocities(particles, pbest, gbest)  # velocity = w*current + c1*pbest + c2*gbest
      return particles[gbest_index].positions
  ```
* **M8**: Backpropagation untuk NN stok  
  *Contoh:*
  ```python
  def train_nn(X_train, y_train):
      model = MLPRegressor(hidden_layer_sizes=(50,25), activation='relu', max_iter=1000)
      model.fit(X_train, y_train)
      return model  # Test accuracy: f1_score(y_test, model.predict(X_test))
  ```

Berikut adalah penjelasan lebih lanjut tentang algoritma optimasi dan contoh kode:

* **PSO**: sebuah algoritma optimasi yang digunakan untuk menentukan posisi optimal dari antenna. Dalam contoh di atas, kami menggunakan PSO untuk menentukan posisi optimal dari antenna.
* **Backpropagation**: sebuah algoritma yang digunakan untuk melatih Neural Network. Dalam contoh di atas, kami menggunakan Backpropagation untuk melatih Neural Network untuk memprediksi stok.

## 🧠 Capstone: POS Offline Cerdas

### Arsitektur Sistem
```
+-------------------+   +-------------------+   +-------------------+
|   Fuzzy Logic     |   |     Stacked LSTM  |   ← |  MQTT Bridge      |
| (Kredit Pelanggan) |   | (Stok Prediksi)   |     | (IoT Sensors)     |
+----------+--------+   +----------+--------+     +----------+--------+
           ↓                      ↓                        ↓
+--------------------------------------------+            ↓
|            Mikrotik RB450G (ROS 7)         | ←  +--------v--------+
|   - Wireless Bridge 2.4/5GHz               |     | Mikrotik RB951Ui-2n |
|   - PPPoe Server (300 users)               |     | + PLTS 5kW (24V) |
|   - Radius Server (CheckRadius)            |     | + Battery 48V |
+--------------------------------------------+     +---------------+
```

Berikut adalah penjelasan lebih lanjut tentang arsitektur sistem:

* **Fuzzy Logic**: sebuah komponen yang digunakan untuk menentukan nilai kredit pelanggan. Dalam contoh di atas, kami menggunakan Fuzzy Logic untuk menentukan nilai kredit pelanggan.
* **Stacked LSTM**: sebuah komponen yang digunakan untuk memprediksi stok. Dalam contoh di atas, kami menggunakan Stacked LSTM untuk memprediksi stok.
* **MQTT Bridge**: sebuah komponen yang digunakan untuk menghubungkan sistem dengan IoT Sensors. Dalam contoh di atas, kami menggunakan MQTT Bridge untuk menghubungkan sistem dengan IoT Sensors.

### Kode Implementasi Stok Prediksi
```python
# POS Stok Prediction Module
from datetime import datetime
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

def load_data():
    df = pd.read_csv('sales_data.csv', index_col='date', parse_dates=True)
    df['day_of_week'] = df.index.dayofweek
    df['month'] = df.index.month
    return df

def train_model(df):
    X, y = df.drop('sales', axis=1), df['sales'].shift(-1)  # predict next period
    X_train, X_test = X[:-28], X[-28:]
    y_train, y_test = y[:-28], y[-28:]
    
    # Feature engineering
    X_train['moving_avg_7'] = X_train['sales'].rolling(7).mean()
    X_train['sales_diff'] = X_train['sales'].diff()
    
    model = RandomForestClassifier(n_estimators=100)
    model.fit(X_train, y_train > np.mean(y_train))
    return model, X_test, y_test

def predict(model, new_data):
    proba = model.predict_proba(new_data)[:,1]
    return np.where(proba > 0.6, 'overstock', 'understock')
```

Berikut adalah penjelasan lebih lanjut tentang kode implementasi stok prediksi:

* **Load Data**: sebuah fungsi yang digunakan untuk memuat data penjualan. Dalam contoh di atas, kami menggunakan `pd.read_csv` untuk memuat data penjualan.
* **Train Model**: sebuah fungsi yang digunakan untuk melatih model. Dalam contoh di atas, kami menggunakan `RandomForestClassifier` untuk melatih model.
* **Predict**: sebuah fungsi yang digunakan untuk memprediksi stok. Dalam contoh di atas, kami menggunakan `model.predict_proba` untuk memprediksi stok.

## ✅ Progress Tracking

### Book 1 — AI (Imam Robandi)  
- [ ] **PSO untuk optimasi jarak antena**  
  *Bug: velocity calculation salah* → fix: `velocity = weight * velocity + c1 * (pbest - position) + c2 * (gbest - position)`
- [ ] **NN untuk prediksi stok**  
  *Underfitting → add: hidden_layer_sizes=(100, 50) + L2 regularization*

Berikut adalah penjelasan lebih lanjut tentang progress tracking:

* **PSO**: sebuah komponen yang digunakan untuk menentukan posisi optimal dari antenna. Dalam contoh di atas, kami menggunakan PSO untuk menentukan posisi optimal dari antenna.
* **NN**: sebuah komponen yang digunakan untuk memprediksi stok. Dalam contoh di atas, kami menggunakan NN untuk memprediksi stok.

### Book 2 — Kualitas PL
- [ ] **SQAP untuk pengembangan sistem**  
  *Bug: tidak ada dokumentasi* → fix: buat dokumentasi yang lengkap
- [ ] **V&V untuk pengujian sistem**  
  *Bug: tidak ada pengujian* → fix: lakukan pengujian yang lengkap

Berikut adalah penjelasan lebih lanjut tentang progress tracking:

* **SQAP**: sebuah komponen yang digunakan untuk pengembangan sistem. Dalam contoh di atas, kami menggunakan SQAP untuk pengembangan sistem.
* **V&V**: sebuah komponen yang digunakan untuk pengujian sistem. Dalam contoh di atas, kami menggunakan V&V untuk pengujian sistem.

### Book 3 — Internet Offline
- [ ] **Mikrotik untuk jaringan**  
  *Bug: tidak ada konfigurasi* → fix: lakukan konfigurasi yang lengkap
- [ ] **PLTS untuk listrik**  
  *Bug: tidak ada perencanaan* → fix: lakukan perencanaan yang lengkap

Berikut adalah penjelasan lebih lanjut tentang progress tracking:

* **Mikrotik**: sebuah komponen yang digunakan untuk jaringan. Dalam contoh di atas, kami menggunakan Mikrotik untuk jaringan.
* **PLTS**: sebuah komponen yang digunakan untuk listrik. Dalam contoh di atas, kami menggunakan PLTS untuk listrik.

Dengan demikian, kita dapat melihat bahwa tiga buku ini membentuk **3 pilar kompetensi** yang saling melengkapi, yaitu AI & Optimasi, Kualitas PL, dan Internet Offline. Dengan menggunakan strategi belajar berbasis teknik "layered learning", kita dapat memahami konsep-konsep tersebut dengan lebih baik dan dapat mengaplikasikannya dalam studi kasus nyata.