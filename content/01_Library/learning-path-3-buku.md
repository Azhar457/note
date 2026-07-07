---
title: "Learning Path — 3 Buku Teknologi (MOC)"
tags:
  - MOC
  - learning-path
  - ai
  - software-quality
  - internet-offline
aliases:
  - "Learning Companion Tiga Buku"
created: 2026-07-05
updated: 2026-07-05
status: active
---

<think>
Alright, I need to help the user expand their technical documentation to over 1100 words. Let me start by analyzing the existing content.

The original document has sections on three books forming a learning path, cross-references between them, a study schedule, a capstone project, progress tracking, and some code examples. The user wants more detailed examples, troubleshooting scenarios, and in-depth explanations.

First, I'll add more code examples. The current ones are for PSO and Fuzzy Logic. Expanding to include a GA example would be good. Also, adding more detailed code comments and explanations will help.

Next, troubleshooting scenarios. Each book's progress tracking has items to check. For each book, I can create a section with typical issues and solutions. For example, in AI, issues might include overfitting in neural networks or incorrect PSO parameters. For SQAP, problems could be misalignments in quality metrics. For Internet Offline, deployment issues like network coverage or power supply problems are common. Including specific steps to diagnose and resolve these would add value.

For architectural explanations, each book's concepts can be elaborated. For AI, explaining swarm intelligence's application in network optimization. For SQAP, diving into traceability matrices in software quality. In Internet Offline, detailing how PLTS sizing calculations work.

I need to ensure the expansion is natural and doesn't feel forced. Each added section should complement the existing content without redundancy. Also, maintaining the original structure and tone is essential.

Let me check the word count. The user wants over 1100 words. Adding another 200-300 words should suffice. Including a new troubleshooting section with three scenarios and expanding the capstone project with a code example and architecture will cover this.

I'll start by updating the existing code examples, then add a detailed troubleshooting section with three problems. Finally, enhance the capstone project by discussing its architecture and providing a code snippet for the prediction model. Each addition will be clearly labeled with headers to maintain structure.
</think>

# 📚 MOC — Learning Path Tiga Buku Teknologi

> **Paradigma:** _Algoritma (Book 1) → Proses Berkualitas (Book 2) → Deploy ke Lapangan (Book 3)_

## 📂 Pendahuluan

Tiga buku ini membentuk **3 pilar kompetensi** yang saling melengkapi:

1. **AI & Optimasi** — algoritma cerdas untuk nyari solusi terbaik  
   _Implementasi: PSO, GA, Fuzzy Logic_
2. **Kualitas PL** — jamin proses dan produk gak asal jadi  
   _Framework: SQAP, CMMI, V&V (Verify-Validate)_
3. **Internet Offline** — deploy sistem ke daerah blank spot  
   _Infra: Mikrotik, LAMP Stack, PLTS_

Strategi belajar berbasis teknik "layered learning": tiap konsep dimulai dari teori, lanjut implementasi kode, dilanjut benchmark dan integrasi. Contoh: Fuzzy Logic di AI bisa diaplikasikan ke evaluasi risiko SQAP, atau ke prediksi beban daya di PLTS.

---

## 🎯 Visi

Tiga buku ini diangkat dari studi kasus nyata di 125 desa di Indonesia, memecahkan 3 tantangan simultan:

1. **Prediksi** — stok POS minimarket via Fuzzy/NN  
   _Accuracy requirement: >90%_
2. **Validasi** — audit SQAP deployment Moodle  
   _ISO/IEC 12207 compliance_
3. **Daya Mandiri** — sistem PLTS 5kW untuk 50 pelajar  
   _PP-UPR 88/2016_

---

## 🔗 Cross-Reference Antar Buku

### AI → Internet Offline

| Algoritma             | Aplikasi                               | Kode Contoh |
| --------------------- | -------------------------------------- | ----------- |
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

---

## 📅 Jadwal Belajar (12 Minggu)

### Fase 1 — Fondasi (Minggu 1-4)

- **M1**: Analisis kebutuhan (Use Case Diagrams)  
  _Output: Requirements Specification Document_
- **M2**: Instalasi Python 3.9 + Mikrotik CLI  
  _Setup: `pip install scikit-fuzzy` untuk Fuzzy Logic_

### Fase 2 — Algoritma Optimasi (Minggu 5-8)

- **M6**: PSO untuk coverage maksimum  
  _Contoh:_
  ```python
  def pso_optimize(antennas, coverage_map):
      particles = [(random_position(), velocity=0) for _ in antennas]
      for it in range(1000):
          pbest = [particle.get_coverage(coverage_map) for particle in particles]
          gbest = max(pbest)
          update_velocities(particles, pbest, gbest)  # velocity = w*current + c1*pbest + c2*gbest
      return particles[gbest_index].positions
  ```
- **M8**: Backpropagation untuk NN stok POS  
  _Contoh:_
  ```python
  def train_nn(X_train, y_train):
      model = MLPRegressor(hidden_layer_sizes=(50,25), activation='relu', max_iter=1000)
      model.fit(X_train, y_train)
      return model  # Test accuracy: f1_score(y_test, model.predict(X_test))
  ```

---

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

---

## ✅ Progress Tracking

### Book 1 — AI (Imam Robandi)

- [ ] **PSO untuk optimasi jarak antena**  
      _Bug: velocity calculation salah_ → fix: `velocity = weight * velocity + c1 * (pbest - position) + c2 * (gbest - position)`
- [ ] **NN untuk prediksi stok**  
      _Underfitting → add: hidden_layer_sizes=(100, 50) + L2 regularization_

### Book 2 — Kualitas PL
