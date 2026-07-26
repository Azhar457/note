---
title: Swarm Intelligence & Algoritma Optimasi — Deep Dive
tags:
  - swarm-intelligence
  - optimization
  - evolutionary-computation
  - neural-network
  - fuzzy-logic
aliases:
  - Swarm Intelligence Deep Dive
  - Algoritma Optimasi
  - Nature-Inspired AI
created: "2026-07-05"
updated: 2026-07-09
status: operational
cssclasses:
  - wide-table
---

> [!abstract] Lebih dari Sekadar Metafora
> Algoritma yang terinspirasi alam bukanlah analogi puitis. Mereka adalah implementasi komputasional dari **proses fisik dan biologis yang telah dioptimalkan oleh evolusi selama miliaran tahun.** Dari jalur feromon semut hingga echolocation kelelawar, setiap mekanisme adalah solusi teruji untuk masalah optimasi, pencarian, dan pengambilan keputusan dalam lingkungan yang tidak pasti. Dokumen ini membedah fondasi matematis dan implementasi Python dari inti Kecerdasan Buatan Klasik, menghubungkannya dengan era komputasi modern.

---

## 🧬 1. Kecerdasan Koloni Binatang (Swarm Intelligence) — Dari Agen Sederhana ke Sistem Kompleks

### Fondasi Epistemologis: Mengapa Ini Bekerja?

Swarm Intelligence (SI) adalah studi tentang sistem desentralisasi di mana agen-agen sederhana, melalui interaksi lokal dan umpan balik lingkungan, menghasilkan **kecerdasan global**. Tidak ada cetak biru pusat; kecerdasan adalah properti _emergent_ dari sistem.

**Prinsip Matematis Inti:**

- **Desentralisasi:** Setiap agen `i` hanya memiliki informasi lokal `L_i`. Keputusan `D_i` dibuat hanya berdasarkan `L_i`.
- **Umpan Balik Positif:** Solusi yang baik diperkuat (contoh: feromon pada jalur pendek).
- **Umpan Balik Negatif:** Solusi yang buruk diabaikan atau dihukum (contoh: penguapan feromon), mencegah konvergensi prematur ke optimum lokal.
- **Stigmergi:** Komunikasi termediasi lingkungan. Agen `A` mengubah lingkungan `E`. Agen `B` merespons perubahan di `E`. Ini adalah **memori kolektif non-simbolik.**

### Analogi Alam:

- **Semut** cari makanan → tinggalkan jejak feromon → jalur terpendek jadi paling kuat
- **Burung** terbang → ikuti tetangga → kawanan kompak tanpa tabrakan
- **Ikan** berenang → hindari predator → formasi rapat sebagai satu kesatuan

---

## 🐝 2. Fuzzy Logic — Kuantifikasi Ketidakpastian Linguistik

### Fondasi Epistemologis: Melampaui Biner

Dunia bukanlah `{0, 1}`. Fuzzy Logic, yang diperkenalkan oleh Lotfi Zadeh, menyediakan kerangka matematis untuk menangani **ketidakpastian linguistik** dan **ketidakjelasan konseptual**. Ini bukan probabilitas; ini adalah derajat kebenaran.

**Definisi Formal:**
Sebuah himpunan fuzzy `A` dalam semesta `X` didefinisikan oleh **fungsi keanggotaan** `μ_A: X → [0, 1]`. Untuk setiap `x ∈ X`, `μ_A(x)` adalah derajat keanggotaan `x` di `A`.

**Crisp vs Fuzzy:**

| Crisp                   | Fuzzy                                 |
| ----------------------- | ------------------------------------- |
| `{0, 1}` — dingin/panas | `[0, 1]` — agak dingin, lumayan panas |
| Himpunan tegas          | Himpunan kabur                        |
| Logika biner            | Derajat kebenaran                     |

**Arsitektur Sistem Fuzzy (3 Langkah):**

1. **Fuzzifikasi (Fuzzification):** Input tegas `x₀` dikonversi menjadi derajat keanggotaan `μ_A(x₀)` untuk setiap himpunan fuzzy yang relevan.
2. **Inferensi (Inference):** Aturan linguistik IF-THEN dievaluasi. Operator: AND = `min`, OR = `max`. Aturan dievaluasi secara paralel.
3. **Defuzzifikasi (Defuzzification):** Output fuzzy dikonversi kembali menjadi nilai tegas. Metode paling umum: **Centroid**: `y = ∫ y·μ_output(y) dy / ∫ μ_output(y) dy`.

### Fungsi Keanggotaan Umum:

| Tipe            | Rumus                                      |
| --------------- | ------------------------------------------ |
| **Triangular**  | `max(0, min((x-a)/(b-a), (c-x)/(c-b)))`    |
| **Trapezoidal** | `max(0, min((x-a)/(b-a), 1, (d-x)/(d-c)))` |
| **Gaussian**    | `exp(-(x-μ)²/(2σ²))`                       |

### Praktik Python (`scikit-fuzzy`):

```python
import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl

# 1. Definisikan Variabel Linguistik
suhu = ctrl.Antecedent(np.arange(15, 35, 1), 'suhu')
kelembaban = ctrl.Antecedent(np.arange(0, 100, 1), 'kelembaban')
nyaman = ctrl.Consequent(np.arange(0, 11, 1), 'nyaman')

# 2. Fungsi Keanggotaan
suhu['dingin'] = fuzz.trapmf(suhu.universe, [15, 15, 22, 25])
suhu['sejuk'] = fuzz.trapmf(suhu.universe, [22, 25, 28, 31])
suhu['panas'] = fuzz.trapmf(suhu.universe, [28, 31, 35, 35])
kelembaban['rendah'] = fuzz.trapmf(kelembaban.universe, [0, 0, 40, 60])
kelembaban['sedang'] = fuzz.trapmf(kelembaban.universe, [40, 60, 70, 80])
kelembaban['tinggi'] = fuzz.trapmf(kelembaban.universe, [60, 80, 100, 100])
nyaman['rendah'] = fuzz.trapmf(nyaman.universe, [0, 0, 3, 5])
nyaman['sedang'] = fuzz.trapmf(nyaman.universe, [3, 5, 6, 8])
nyaman['tinggi'] = fuzz.trapmf(nyaman.universe, [6, 8, 10, 10])

# 3. Aturan Inferensi
rule1 = ctrl.Rule(suhu['panas'] & kelembaban['tinggi'], nyaman['rendah'])
rule2 = ctrl.Rule(suhu['sejuk'] & kelembaban['sedang'], nyaman['tinggi'])
rule3 = ctrl.Rule(suhu['panas'] & kelembaban['rendah'], nyaman['sedang'])

# 4. Sistem & Simulasi
kontrol_nyaman = ctrl.ControlSystem([rule1, rule2, rule3])
simulasi = ctrl.ControlSystemSimulation(kontrol_nyaman)
simulasi.input['suhu'] = 29
simulasi.input['kelembaban'] = 85
simulasi.compute()
print(f"Output kenyamanan: {simulasi.output['nyaman']:.2f}")
```

### Praktik Custom NumPy (inti tanpa library):

```python
import numpy as np

def triangular(x, a, b, c):
    return np.maximum(0, np.minimum((x-a)/(b-a), (c-x)/(c-b)))

def centroid(x, membership):
    return np.sum(x * membership) / np.sum(membership)

x = np.linspace(0, 10, 100)
nyaman_agregat = triangular(x, 2, 4, 7)
nilai_tegas = centroid(x, nyaman_agregat)
print(f"Nilai tegas (centroid manual): {nilai_tegas:.2f}")
```

---

## ⚡ 3. Particle Swarm Optimization (PSO) — Koreografi Sosial di Ruang Solusi

### Fondasi Epistemologis: Memori Kolektif dalam Dinamika Fisik

PSO mensimulasikan perilaku sosial hewan (kawanan burung, gerombolan ikan) di mana setiap partikel adalah solusi kandidat dalam ruang pencarian. Partikel bergerak berdasarkan **pengalaman pribadi (cognitive)** dan **pengaruh sosial (social)**.

**Model Matematis Formal:**
Untuk setiap partikel `i` pada iterasi `t`:

- `x_i(t)` adalah posisi (solusi kandidat).
- `v_i(t)` adalah kecepatan (arah dan besar langkah).
- `pbest_i` adalah posisi terbaik yang pernah dikunjungi partikel `i`.
- `gbest` adalah posisi terbaik yang pernah dikunjungi oleh seluruh kawanan.

**Update Kecepatan dan Posisi:**

```
v_i(t+1) = ω·v_i(t) + c₁·r₁·(pbest_i - x_i(t)) + c₂·r₂·(gbest - x_i(t))
x_i(t+1) = x_i(t) + v_i(t+1)
```

- `ω` (Inertia Weight): Menyeimbangkan eksplorasi dan eksploitasi. `ω` tinggi (0.9) = jelajah global, `ω` rendah (0.4) = fokus lokal.
- `c₁, c₂` (Acceleration Coefficients): Biasanya `c₁ = c₂ = 2.0`.
- `r₁, r₂`: Bilangan acak `~U(0,1)` — mencegah determinisme.

### Parameter Penting:

| Parameter | Efek                    |
| --------- | ----------------------- |
| `w = 0.9` | Eksplorasi global       |
| `w = 0.4` | Eksploitasi lokal       |
| `c₁ > c₂` | Cenderung personal best |
| `c₂ > c₁` | Cenderung social best   |

### Implementasi Python Vectorized (NumPy):

```python
import numpy as np

def pso_vectorized(func, dim, n_particles=30, max_iter=100, bounds=(-10, 10)):
    lb, ub = bounds
    pos = np.random.uniform(lb, ub, (n_particles, dim))
    vel = np.random.uniform(-abs(ub-lb), abs(ub-lb), (n_particles, dim))

    fitness = np.apply_along_axis(func, 1, pos)
    pbest_pos = pos.copy()
    pbest_fit = fitness.copy()
    gbest_idx = np.argmin(fitness)
    gbest_pos = pos[gbest_idx].copy()
    gbest_fit = fitness[gbest_idx]

    w_max, w_min = 0.9, 0.4
    c1, c2 = 2.0, 2.0

    for t in range(max_iter):
        w = w_max - (w_max - w_min) * t / max_iter
        r1 = np.random.rand(n_particles, dim)
        r2 = np.random.rand(n_particles, dim)

        vel = (w*vel + c1*r1*(pbest_pos-pos) + c2*r2*(gbest_pos-pos))
        max_vel = 0.5 * (ub - lb)
        vel = np.clip(vel, -max_vel, max_vel)
        pos += vel
        pos = np.clip(pos, lb, ub)

        new_fitness = np.apply_along_axis(func, 1, pos)
        improved = new_fitness < pbest_fit
        pbest_pos[improved] = pos[improved]
        pbest_fit[improved] = new_fitness[improved]

        current_gbest_idx = np.argmin(pbest_fit)
        if pbest_fit[current_gbest_idx] < gbest_fit:
            gbest_pos = pbest_pos[current_gbest_idx].copy()
            gbest_fit = pbest_fit[current_gbest_idx]

    return gbest_pos, gbest_fit

# Contoh: Rastrigin function
def rastrigin(x):
    return 10*len(x) + np.sum(x**2 - 10*np.cos(2*np.pi*x))

best_pos, best_val = pso_vectorized(rastrigin, dim=5, n_particles=50, max_iter=200)
print(f"Best: {best_pos}, Min: {best_val:.6f}")
```

### Aplikasi PSO:

- Optimasi fungsi matematis (Rastrigin, Sphere, Rosenbrock)
- **Economic Load Dispatch** — pembagian beban generator
- Training neural network (sebagai alternatif backprop)

---

## 🧬 4. Genetic Algorithm (GA) — Evolusi Digital

### Fondasi Epistemologis: Seleksi, Variasi, dan Hereditas

GA adalah model komputasi dari evolusi Darwin. Populasi solusi kandidat (kromosom) bersaing untuk bertahan hidup. Solusi yang lebih "fit" memiliki probabilitas lebih tinggi untuk menurunkan materi genetiknya.

### Langkah GA:

1. **Encoding** — representasi solusi (binary, real-value, permutation)
2. **Populasi awal** — generate random
3. **Evaluasi fitness** — nilai fungsi objektif
4. **Seleksi** — pilih induk (roulette wheel, tournament, rank)
5. **Crossover** — kawin silang (one-point, two-point, uniform, blend)
6. **Mutation** — mutasi acak (bit flip, swap, gaussian)
7. **Elitism** — pertahankan individu terbaik
8. **Ulang** step 3-7 sampai konvergen

### Komponen Detail:

| Komponen      | Metode         | Cara Kerja                                                   |
| ------------- | -------------- | ------------------------------------------------------------ |
| **Seleksi**   | Tournament     | Pilih `k` random, ambil terbaik. `k` kontrol tekanan seleksi |
| **Crossover** | BLX-α (real)   | `child = parent1 + α·(parent2-parent1)`, α=0.5               |
| **Mutation**  | Gaussian       | `x = x + N(0, σ)`, σ tentukan besar langkah                  |
| **Elitism**   | Copy N terbaik | Jamin fitness terbaik tidak pernah turun                     |

### Perbandingan GA vs PSO:

| Aspek       | GA                            | PSO                         |
| ----------- | ----------------------------- | --------------------------- |
| Cara        | Evolusi populasi              | Gerakan kawanan             |
| Memori      | Tidak ada                     | pbest + gbest               |
| Parameter   | Crossover rate, mutation rate | w, c1, c2                   |
| Konvergensi | Lambat tapi stabil            | Cepat tapi bisa jebak lokal |

### Implementasi Python GA Real-Value:

```python
import numpy as np

def genetic_algorithm(func, dim, pop_size=50, max_gen=100, bounds=(-10, 10),
                      crossover_rate=0.9, mutation_rate=0.1, elite_size=2):
    lb, ub = bounds
    pop = np.random.uniform(lb, ub, (pop_size, dim))
    fitness = np.apply_along_axis(func, 1, pop)

    for gen in range(max_gen):
        # Elitism
        elite_idx = np.argsort(fitness)[:elite_size]
        new_pop = pop[elite_idx].copy()

        while len(new_pop) < pop_size:
            # Tournament Selection (k=3)
            idx = np.random.choice(pop_size, 3, replace=False)
            parent1 = pop[idx[np.argmin(fitness[idx])]]
            idx = np.random.choice(pop_size, 3, replace=False)
            parent2 = pop[idx[np.argmin(fitness[idx])]]

            if np.random.rand() < crossover_rate:
                alpha = 0.5
                child1 = parent1 + alpha * (parent2 - parent1)
                child2 = parent2 + alpha * (parent1 - parent2)
            else:
                child1, child2 = parent1.copy(), parent2.copy()

            if np.random.rand() < mutation_rate:
                child1 += np.random.normal(0, 0.5, dim)
            if np.random.rand() < mutation_rate:
                child2 += np.random.normal(0, 0.5, dim)

            child1 = np.clip(child1, lb, ub)
            child2 = np.clip(child2, lb, ub)
            new_pop = np.vstack([new_pop, child1, child2])

        pop = new_pop[:pop_size]
        fitness = np.apply_along_axis(func, 1, pop)

    best_idx = np.argmin(fitness)
    return pop[best_idx], fitness[best_idx]
```

---

## 🐜 5. Ant Colony Optimization (ACO) — Logika Kolektif Berbasis Jejak

### Fondasi Epistemologis: Probabilitas Berdasarkan Sejarah

ACO meniru perilaku semut mencari jalur terpendek. Semut menyimpan **feromon** di jalur yang mereka lalui. Semut berikutnya cenderung memilih jalur dengan konsentrasi feromon lebih tinggi, menciptakan umpan balik positif untuk solusi yang baik.

### Model Probabilistik (Ant System):

```
Pᵢⱼᵏ = [τᵢⱼ]ᵅ · [ηᵢⱼ]ᵇ / Σ_l [τᵢₗ]ᵅ · [ηᵢₗ]ᵇ
```

- `τᵢⱼ` (pheromone): Jejak kimiawi, memori kolektif.
- `ηᵢⱼ = 1/dᵢⱼ` (heuristic): Visibilitas, daya tarik lokal.
- `α`: Bobot feromon (`α=0` → greedy heuristic).
- `β`: Bobot heuristik (`β=0` → hanya feromon, stagnan).

### Update Feromon:

```
τᵢⱼ ← (1 - ρ)·τᵢⱼ + Σ_k Δτᵢⱼᵏ
```

- `ρ` (evaporation rate): Melupakan sejarah lama, mencegah optimum lokal.
- `Δτᵢⱼᵏ = 1 / Lₖ` jika semut `k` lewat jalur `(i,j)`.

### Varian Penting:

- **MMAS** (Max-Min Ant System) — batasi pheromone agar tidak ekstrem
- **ACS** (Ant Colony System) — local update + global update

### Implementasi Python ACO untuk TSP:

```python
import numpy as np

class TSP_ACO:
    def __init__(self, n_ants, n_iterations, alpha, beta, rho, Q=1):
        self.n_ants = n_ants
        self.n_iterations = n_iterations
        self.alpha = alpha
        self.beta = beta
        self.rho = rho
        self.Q = Q

    def solve(self, distance_matrix):
        n_cities = len(distance_matrix)
        pheromone = np.ones((n_cities, n_cities)) * 0.1
        best_path = None
        best_length = float('inf')

        for _ in range(self.n_iterations):
            all_paths = []
            all_lengths = []
            for _ in range(self.n_ants):
                path = self._construct_path(distance_matrix, pheromone)
                length = self._path_length(distance_matrix, path)
                all_paths.append(path)
                all_lengths.append(length)
                if length < best_length:
                    best_path, best_length = path, length

            pheromone *= (1 - self.rho)
            for path, length in zip(all_paths, all_lengths):
                deposit = self.Q / length
                for i in range(len(path)-1):
                    pheromone[path[i]][path[i+1]] += deposit
                pheromone[path[-1]][path[0]] += deposit

        return best_path, best_length

    def _construct_path(self, dist_matrix, pheromone):
        n = len(dist_matrix)
        start = np.random.randint(n)
        unvisited = list(range(n))
        unvisited.remove(start)
        path = [start]
        while unvisited:
            probs = self._get_probs(pheromone, dist_matrix, path[-1], unvisited)
            next_city = np.random.choice(unvisited, p=probs)
            path.append(next_city)
            unvisited.remove(next_city)
        return path

    def _get_probs(self, pheromone, dist_matrix, current, unvisited):
        tau = np.array([pheromone[current][j]**self.alpha for j in unvisited])
        eta = np.array([(1.0/dist_matrix[current][j])**self.beta for j in unvisited])
        probs = tau * eta
        return probs / np.sum(probs)

    def _path_length(self, dist_matrix, path):
        n = len(path)
        return sum(dist_matrix[path[i]][path[i+1]] for i in range(n-1)) + dist_matrix[path[-1]][path[0]]
```

---

## 🐝 6. Artificial Bee Colony (ABC) — Eksplorasi dan Eksploitasi Terpisah

ABC memodelkan tiga jenis lebah dengan peran berbeda, menciptakan keseimbangan eksplorasi (scout) dan eksploitasi (employed dan onlooker).

| Jenis Lebah  | Peran                                                                                    |
| ------------ | ---------------------------------------------------------------------------------------- |
| **Employed** | Eksploitasi sumber makanan, bagi info lewat waggle dance                                 |
| **Onlooker** | Menonton dance, pilih sumber terbaik secara probabilistik (`Pᵢ = fitnessᵢ / Σ fitnessⱼ`) |
| **Scout**    | Tinggalkan sumber jelek setelah `limit` iterasi tanpa improvement, cari baru acak        |

### Implementasi Singkat:

```python
def artificial_bee_colony(func, dim, n_bees=30, max_iter=100, bounds=(-10, 10), limit=10):
    lb, ub = bounds
    n_employed = n_bees // 2
    n_onlooker = n_bees - n_employed

    foods = np.random.uniform(lb, ub, (n_employed, dim))
    fitness = np.apply_along_axis(func, 1, foods)
    trials = np.zeros(n_employed)

    for t in range(max_iter):
        # Employed phase
        for i in range(n_employed):
            k = np.random.choice(n_employed)
            while k == i: k = np.random.choice(n_employed)
            j = np.random.randint(dim)
            new_food = foods[i].copy()
            new_food[j] = foods[i][j] + np.random.uniform(-1, 1) * (foods[i][j] - foods[k][j])
            new_food = np.clip(new_food, lb, ub)
            new_fitness = func(new_food)
            if new_fitness < fitness[i]:
                foods[i] = new_food; fitness[i] = new_fitness; trials[i] = 0
            else: trials[i] += 1

        # Onlooker phase
        probs = (1/(1+np.abs(fitness))) / np.sum(1/(1+np.abs(fitness)))
        for i in range(n_onlooker):
            chosen = np.random.choice(n_employed, p=probs)
            k = np.random.choice(n_employed)
            while k == chosen: k = np.random.choice(n_employed)
            j = np.random.randint(dim)
            new_food = foods[chosen].copy()
            new_food[j] = foods[chosen][j] + np.random.uniform(-1, 1) * (foods[chosen][j] - foods[k][j])
            new_food = np.clip(new_food, lb, ub)
            new_fitness = func(new_food)
            if new_fitness < fitness[chosen]:
                foods[chosen] = new_food; fitness[chosen] = new_fitness; trials[chosen] = 0
            else: trials[chosen] += 1

        # Scout phase
        for i in range(n_employed):
            if trials[i] > limit:
                foods[i] = np.random.uniform(lb, ub, dim)
                fitness[i] = func(foods[i])
                trials[i] = 0

    best_idx = np.argmin(fitness)
    return foods[best_idx], fitness[best_idx]
```

---

## 🦗 7. Algoritma Lainnya: Firefly & Bat Algorithm

### Firefly Algorithm (FA)

**Prinsip:** Daya tarik kunang-kunang berbanding lurus dengan kecerahannya dan berbanding terbalik dengan kuadrat jarak. Ini adalah PSO tanpa kecepatan, dengan daya tarik gravitasi yang terlokalisasi.

```
xᵢ = xᵢ + β₀·e^(-γ·rᵢⱼ²)·(xⱼ - xᵢ) + α·(rand - 0.5)
```

- `β₀` = attractiveness maksimum
- `γ` = absorption coefficient (`γ→0` = global, `γ→∞` = acak)
- `α` = random walk

**Aplikasi:** Economic Load Dispatch, Clustering, Image Processing

### Bat Algorithm (BA)

**Prinsip:** Mikro-kelelawar menggunakan echolocation. Frekuensi pulsa `f`, loudness `A`, pulse rate `r`. Saat mendekati mangsa, loudness menurun (`A_i → 0`) dan pulse rate meningkat (`r_i → 1`).

```
f = f_min + (f_max - f_min)·β
vᵢ = vᵢ + (xᵢ - x_best)·f
xᵢ = xᵢ + vᵢ
```

**Aplikasi:** Feature selection, Engineering optimization, Classification

---

## 🧠 8. Neural Network — Approximator Fungsi Universal

### Fondasi Epistemologis

Neural network adalah komposisi fungsi non-linear yang memetakan input `X` ke output `Y`. Sebuah neuron tunggal: `y = f(W·X + b)`. Stacking neuron menciptakan representasi hierarkis.

### Activation Functions:

| Fungsi  | Rumus               | Turunan                 |
| ------- | ------------------- | ----------------------- |
| Step    | `1 if x > 0 else 0` | `0` (gak bisa backprop) |
| Sigmoid | `1/(1+e⁻ˣ)`         | `σ(x)·(1-σ(x))`         |
| Tanh    | `(eˣ-e⁻ˣ)/(eˣ+e⁻ˣ)` | `1 - tanh²(x)`          |
| ReLU    | `max(0, x)`         | `1 if x>0 else 0`       |

### Backpropagation: Aturan Rantai dalam Graf Komputasi

Backpropagation adalah kalkulus diferensial efisien (aturan rantai) pada graf komputasi.

```
δ_L = ∇_a L ⊙ f'(z_L)                      // Gradien di output
δ_l = (W_{l+1}ᵀ · δ_{l+1}) ⊙ f'(z_l)       // Propagasi mundur
∇_W_l = δ_l · a_{l-1}ᵀ                      // Gradien terhadap bobot
```

### Implementasi NN Sederhana (NumPy):

```python
import numpy as np

class SimpleNN:
    def __init__(self, layers, lr=0.01):
        self.lr = lr
        self.W = [np.random.randn(layers[i], layers[i+1]) * np.sqrt(2./layers[i])
                  for i in range(len(layers)-1)]
        self.b = [np.zeros((1, layers[i+1])) for i in range(len(layers)-1)]

    def _sigmoid(self, x):
        return 1 / (1 + np.exp(-x))

    def forward(self, X):
        self.a = [X]
        self.z = []
        for W, b in zip(self.W, self.b):
            z = np.dot(self.a[-1], W) + b
            self.z.append(z)
            self.a.append(self._sigmoid(z))
        return self.a[-1]

    def backward(self, X, y):
        delta = (self.a[-1] - y) * self.a[-1] * (1 - self.a[-1])
        for i in range(len(self.W)-1, -1, -1):
            dW = np.dot(self.a[i].T, delta)
            db = np.sum(delta, axis=0, keepdims=True)
            self.W[i] -= self.lr * dW
            self.b[i] -= self.lr * db
            if i > 0:
                delta = np.dot(delta, self.W[i].T) * self.a[i] * (1 - self.a[i])

# XOR Example
X = np.array([[0,0],[0,1],[1,0],[1,1]])
y = np.array([[0],[1],[1],[0]])
nn = SimpleNN([2, 3, 1], lr=1.0)
for _ in range(10000):
    nn.forward(X)
    nn.backward(X, y)
print(nn.forward(X))
```

---

## 📊 Metrik & Evaluasi

| Metrik                   | Rumus                   | Makna                          |
| ------------------------ | ----------------------- | ------------------------------ |
| **Accuracy**             | (TP+TN)/(TP+TN+FP+FN)   | Seberapa sering model benar    |
| **Precision**            | TP/(TP+FP)              | Ketepatan prediksi positif     |
| **Recall (Sensitivity)** | TP/(TP+FN)              | Kemampuan menangkap target     |
| **F1-Score**             | 2·P·R/(P+R)             | Harmonic mean presisi & recall |
| **Best Fitness**         | `min f(x)`              | Kualitas solusi terbaik        |
| **Convergence Curve**    | Plot fitness vs iterasi | Kecepatan konvergensi          |

---

## 🔗 Koneksi ke Vault

| Konsep                  | Dokumen                                                        |
| ----------------------- | -------------------------------------------------------------- |
| PSO/GA/ACO → optimasi   | [[ai-engineering-stack-roadmap]] (MLOps hyperparameter tuning) |
| Fuzzy Logic → penilaian | [[software-quality-untung-yuhana]] (kualitas perangkat lunak)  |
| NN → prediksi           | [[test-time-compute-system2]] (system 1 vs system 2)           |
| Swarm → multi-agent     | [[meta-agent-orchestration]] (agent orchestration)             |
| ACO → agent routing     | [[aco-agent-routing-deepdive]] (pheromone dispatch)            |
| Emergent behavior       | [[cognitive-architecture-engineering]] (emergent cognition)    |

---

## ✅ Ringkasan Praktik

| Algoritma | Tool Python              | Prinsip Inti                          | Gak Perlu            |
| --------- | ------------------------ | ------------------------------------- | -------------------- |
| **PSO**   | `numpy`                  | Vektor kecepatan + pbest/gbest        | MATLAB               |
| **GA**    | `numpy`                  | Seleksi + Crossover + Mutasi          | Toolbox mahal        |
| **ACO**   | `numpy`                  | Feromon + Probabilitas + Evaporasi    | Lisensi              |
| **Fuzzy** | `scikit-fuzzy` / `numpy` | Derajat keanggotaan [0,1] + IF-THEN   | MATLAB Fuzzy Toolbox |
| **ABC**   | `numpy`                  | 3 fase agen (Employed,Onlooker,Scout) | Library khusus       |
| **NN**    | `numpy` / `scikit-learn` | Backpropagation on Computation Graph  | GPU cluster          |

> [!tip] Kunci Penguasaan
> Jangan hanya menyalin kode. Pahami **mengapa** partikel PSO bisa berayun jika `ω>1`, **mengapa** crossover dalam GA mempertukarkan blok bangunan (schema theorem), dan **mengapa** backprop efisien. Jika Anda bisa menjelaskan mekanisme ini tanpa melihat buku, Anda bukan hanya pengguna, tetapi **insinyur kecerdasan.**
