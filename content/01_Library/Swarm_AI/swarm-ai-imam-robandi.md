---
title: "Swarm Intelligence & Algoritma Optimasi — Imam Robandi"
tags:
  - ai
  - swarm-intelligence
  - optimization
  - PSO
  - GA
  - ACO
  - ABC
  - FA
  - BA
  - neural-network
  - fuzzy-logic
aliases:
  - "Book 1 AI"
  - "Robandi"
created: 2026-07-05
updated: 2026-07-05
status: active
---

# 🧠 Swarm Intelligence & Algoritma Optimasi

> Buku: **Artificial Intelligence** — Imam Robandi  
> Fokus: Algoritma optimasi terinspirasi alam + Neural Network + Fuzzy Logic  
> Praktik tanpa MATLAB → pakai Python + NumPy/SciPy

---

## 1. Kecerdasan Koloni Binatang (Swarm Intelligence)

**Konsep:**

- **Sistem desentral** — tiap agen mandiri, gak ada komandan
- **Self-organized** — pola kompleks muncul dari interaksi sederhana
- **Emergent behavior** — perilaku kolektif > jumlah individu
- **Stigmergy** — komunikasi lewat perubahan lingkungan (semut tinggalkan pheromone, lebah dance)

**Analogi:**

- Semut cari makanan → tinggalkan jejak → jalur terpendek jadi paling kuat
- Burung terbang → ikuti tetangga → kawanan kompak
- Ikan berenang → hindari predator → formasi rapat

**Implementasi Python sederhana (simulasi swarm):**

```python
import numpy as np
import matplotlib.pyplot as plt

# Simulasi: 20 partikel nyari titik minimum
# Gak perlu library mahal — cukup numpy
```

---

## 2. Fuzzy Logic

**Crisp vs Fuzzy:**

- Crisp: `{0, 1}` — dingin/panas, hidup/mati
- Fuzzy: `[0, 1]` — agak dingin, lumayan panas, sangat hangat

**3 Langkah Fuzzy:**

1. **Fuzzifikasi** — input tegas → derajat keanggotaan
2. **Inferensi** — IF-THEN rules → output fuzzy
3. **Defuzzifikasi** — output fuzzy → nilai tegas

**Fungsi Keanggotaan:**

- Triangular: `max(0, min((x-a)/(b-a), (c-x)/(c-b)))`
- Trapezoidal: `max(0, min((x-a)/(b-a), 1, (d-x)/(d-c)))`
- Gaussian: `exp(-(x-μ)²/(2σ²))`

**Contoh — Kenyamanan Ruangan:**

```
IF suhu PANAS AND kelembaban TINGGI THEN nyaman RENDAH
IF suhu SEJUK AND kelembaban SEDANG THEN nyaman TINGGI
```

**Praktik (no MATLAB):** `scikit-fuzzy` atau implementasi manual numpy.

---

## 3. Particle Swarm Optimization (PSO)

**Konsep:** Kawanan burung/tan sekolah. Setiap partikel punya posisi + kecepatan.

**Formula:**

```
vᵢ = w·vᵢ + c₁·r₁·(pbestᵢ - xᵢ) + c₂·r₂·(gbest - xᵢ)
xᵢ = xᵢ + vᵢ
```

- `w` = inertia weight (eksplorasi vs eksploitasi)
- `c₁, c₂` = cognitive & social coefficient
- `r₁, r₂` = random [0,1]
- `pbest` = posisi terbaik partikel itu
- `gbest` = posisi terbaik seluruh swarm

**Parameter penting:**

| Parameter      | Efek                    |
| -------------- | ----------------------- |
| w tinggi (0.9) | Eksplorasi global       |
| w rendah (0.4) | Eksploitasi lokal       |
| c₁ > c₂        | Cenderung personal best |
| c₂ > c₁        | Cenderung social best   |

**Aplikasi:**

- Optimasi fungsi matematis (Rastrigin, Sphere, Rosenbrock)
- Economic Load Dispatch (pembagian beban generator)
- Training neural network (ganti backprop)

**Praktik:** 30 baris Python numpy selesai.

---

## 4. Genetic Algorithm (GA)

**Konsep:** Evolusi Darwin — seleksi alam, kawin silang, mutasi.

**Langkah:**

1. **Encoding** — representasi solusi (binary, real, permutation)
2. **Populasi awal** — generate random
3. **Evaluasi fitness** — nilai fungsi objektif
4. **Seleksi** — pilih induk (roulette wheel, tournament, rank)
5. **Crossover** — kawin silang (one-point, two-point, uniform)
6. **Mutation** — mutasi acak (bit flip, swap, gaussian)
7. **Elitism** — pertahanan individu terbaik
8. **Ulang** step 3-7 sampai konvergen

**Perbandingan GA vs PSO:**

| Aspek       | GA                     | PSO                   |
| ----------- | ---------------------- | --------------------- |
| Cara        | Evolusi populasi       | Gerakan kawanan       |
| Memori      | Gak ada                | pbest + gbest         |
| Parameter   | Rate crossover, mutasi | w, c1, c2             |
| Konvergensi | Lambat tapi stabil     | Cepet tapi bisa lokal |

**Aplikasi:**

- Penjadwalan (timetabling, scheduling)
- Optimasi kombinatorial (TSP, knapsack)
- Feature selection untuk ML

---

## 5. Ant Colony Optimization (ACO)

**Konsep:** Semut cari makanan — tinggalkan pheromone, ikuti jejak terkuat.

**Formula:**

```
Pᵢⱼ = [τᵢⱼ]ᵃ · [ηᵢⱼ]ᵇ / Σ([τ]ᵃ · [η]ᵇ)
```

- `τ` = pheromone (jejak)
- `η` = heuristic (1/jarak)
- `α, β` = bobot pheromone vs heuristic

**Pheromone Update:**

```
τᵢⱼ = (1-ρ)·τᵢⱼ + Δτᵢⱼ
```

- `ρ` = evaporation rate (mencegah konvergensi prematur)

**Varian penting:**

- **MMAS** (Max-Min Ant System) — batasi pheromone biar gak ekstrem
- **ACS** (Ant Colony System) — local update + global update

**Aplikasi:** TSP (Traveling Salesman Problem), routing jaringan, scheduling.

**Praktik:** ACO untuk TSP 10 kota — visualisasi jalur semut.

---

## 6. Artificial Bee Colony (ABC)

**Konsep:** 3 jenis lebah:

- **Employed** — eksploitasi sumber makanan, bagi info lewat waggle dance
- **Onlooker** — lihat dance, pilih sumber terbaik
- **Scout** — ninggalin sumber jelek, cari baru

**Parameter:**

- `limit` = batas iterasi tanpa improvement → jadi scout
- `SN` = jumlah employed bees = jumlah onlooker bees

---

## 7. Firefly Algorithm (FA)

**Konsep:** Kunang-kunang — yang lebih terang tarik yang lebih redup.

**Formula:**

```
β = β₀ · e^(-γ·r²)
xᵢ = xᵢ + β·(xⱼ - xᵢ) + α·(rand - 0.5)
```

- `β₀` = attractiveness awal
- `γ` = absorption coefficient
- `α` = random walk (keberanian jelajah)

**Aplikasi:** Economic Load Dispatch, clustering, image processing.

---

## 8. Bat Algorithm (BA)

**Konsep:** Kelelawar — echolocation: frekuensi, loudness, pulse rate.

**Formula:**

```
f = f_min + (f_max - f_min)·β
vᵢ = vᵢ + (xᵢ - x_best)·f
xᵢ = xᵢ + vᵢ
```

- **Loudness (A):** menurun saat dekat mangsa
- **Pulse Rate (r):** meningkat saat dekat mangsa

**Aplikasi:** Feature selection, engineering optimization, classification.

---

## 9. Neural Network

**Neuron Tiruan:**

```
y = f(Σ wᵢxᵢ + b)
```

**Activation Function:**

- Step: `1 if x > 0 else 0`
- Sigmoid: `1/(1+e⁻ˣ)`
- Tanh: `(eˣ-e⁻ˣ)/(eˣ+e⁻ˣ)`
- ReLU: `max(0, x)`

**Backpropagation (inti):**

```
δ_output = (target - output) · f'(net)
δ_hidden = Σ(δ_output · w) · f'(net)
Δw = η · δ · input
```

**Metrik Performansi:**

| Metrik    | Rumus                 |
| --------- | --------------------- |
| Accuracy  | (TP+TN)/(TP+TN+FP+FN) |
| Precision | TP/(TP+FP)            |
| Recall    | TP/(TP+FN)            |
| F1-Score  | 2·P·R/(P+R)           |

---

## 🔗 Koneksi ke Buku Lain

- **PSO/GA/ACO** → optimasi penempatan access point (Book 3)
- **Fuzzy Logic** → penilaian kualitas PL subjektif (Book 2)
- **NN** → prediksi stok POS offline (Capstone)

---

## ✅ Ringkasan Praktik

| Algoritma | Implementasi                | Gak perlu            |
| --------- | --------------------------- | -------------------- |
| PSO       | Python numpy                | MATLAB               |
| GA        | Python numpy                | Toolbox mahal        |
| ACO       | Python numpy + matplotlib   | Lisensi              |
| Fuzzy     | scikit-fuzzy / manual numpy | MATLAB Fuzzy Toolbox |
| NN        | numpy / scikit-learn        | GPU cluster          |

> **Kunci:** Pahami _mekanisme_ — kenapa swarm bisa optimasi, kenapa crossover perlu, kenapa backprop jalan. Tool tinggal estafet.
