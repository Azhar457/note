---
title: "Quantum Machine Learning — QML, VQE, Quantum Neural Networks & Kernel Methods"
tags:
  - quantum-ml
  - quantum-computing
  - vqe
  - qnn
  - quantum-kernel
  - qml
  - variational-quantum
aliases:
  - Quantum ML Deep Dive
  - QML Algorithms
  - Variational Quantum Eigensolver
  - Quantum Neural Network
  - QSVM
created: 2026-07-14
updated: 2026-07-14
status: pending
cssclasses:
  - wide-table
---

# ⚛️ QUANTUM MACHINE LEARNING — Ketika Komputasi Kuantum Bertemu ML

**VQE · Quantum Neural Networks · Quantum Kernel Methods · Hybrid Classical-Quantum · NISQ Era**

> [!abstract] Filosofi Fundamental
> Quantum Machine Learning bukanlah "ML yang jalan di komputer kuantum." QML adalah **persimpangan** antara dua paradigma: representasi data dalam ruang Hilbert berdimensi eksponensial dan optimasi gradient-based. Dokumen ini membedah dari first principles: mengapa quantum bisa memberikan advantage untuk ML, bagaimana VQE menjadi backbone algoritma NISQ, arsitektur QNN, keterbatasan barren plateau, dan peta jalan menuju quantum advantage yang terbukti. Bukan hype — ini matematika, fisika, dan kode.

---

## Daftar Isi

- [[#First Principles — Mengapa Quantum untuk ML?]]
- [[#Matematika Dasar — Qubit, Gerbang, Sirkuit]]
- [[#VQE — Variational Quantum Eigensolver]]
- [[#Quantum Neural Networks — Arsitektur]]
- [[#Quantum Kernel Methods — QSVM]]
- [[#Barren Plateau — Musuh Utama QML]]
- [[#Framework & Tools — Implementasi]]
- [[#Step-by-Step Implementasi]]
- [[#Hybrid Quantum-Classical Pipeline]]
- [[#Open Problems & Frontier]]
- [[#Catatan Terkait]]

---

## First Principles — Mengapa Quantum untuk ML?

### Sumber Quantum Advantage

| Area | Classical Complexity | Quantum Speedup | Kenapa? |
|------|--------------------|-----------------|---------|
| **Linear Algebra** (matrix inversion) | $O(n^3)$ | $O(\log n)$* | HHL algorithm — quantum superposition untuk solve linear system |
| **Inner Product** (kernel) | $O(n)$ | $O(\log n)$* | Quantum feature map → dot product dalam ruang Hilbert besar |
| **Optimization** (combinatorial) | Exponential | Polynomial* | QAOA, VQE — parallel exploration of solution space |
| **Sampling** (distribution) | Intractable | Efficient* | Quantum circuits bisa sample dari distribusi yang classical sulit |
| **Gradient Estimation** | $O(p)$ | $O(1)$* | Parameter shift rule — bisa parallelize gradient per parameter |

\* *Teoritis — tergantung problem dan implementasi. Di NISQ era, belum terbukti unconditional advantage.*

### Kapan QML Berpotensi Unggul?

```
Apakah problem punya struktur yang bisa dieksploitasi secara quantum?
├── Ya → Apakah classical ML bisa solve dengan akurat?
│   ├── Ya → Classical wins (lebih murah, stabil, proven)
│   └── Tidak → QML worth exploring
│       ├── Data punya inherent quantum structure?
│       │   ├── Ya → Quantum data (chemistry, physics) → QML kemungkinan besar unggul
│       │   └── Tidak → Feature map harus dipilih hati-hati
│       └── Problem size besar? → Quantum advantage lebih terlihat di skala besar
└── Tidak → Classical ML
```

---

## Matematika Dasar — Qubit, Gerbang, Sirkuit

### Qubit vs Bit

$$|\psi\rangle = \alpha|0\rangle + \beta|1\rangle, \quad |\alpha|^2 + |\beta|^2 = 1$$

Satu qubit bisa representasi **superposisi** dua state. $n$ qubit = superposisi $2^n$ state.

### Gerbang Quantum Penting

| Gerbang | Matriks | Efek |
|---------|---------|------|
| **Hadamard (H)** | $\frac{1}{\sqrt{2}}\begin{bmatrix}1 & 1 \\ 1 & -1\end{bmatrix}$ | Buat superposisi: $|0\rangle \to \frac{|0\rangle+|1\rangle}{\sqrt{2}}$ |
| **Pauli-X (NOT)** | $\begin{bmatrix}0 & 1 \\ 1 & 0\end{bmatrix}$ | Flip: $|0\rangle \to |1\rangle$ |
| **Pauli-Y** | $\begin{bmatrix}0 & -i \\ i & 0\end{bmatrix}$ | Rotasi sumbu Y |
| **Pauli-Z** | $\begin{bmatrix}1 & 0 \\ 0 & -1\end{bmatrix}$ | Phase flip: $|1\rangle \to -|1\rangle$ |
| **CNOT (CX)** | $\begin{bmatrix}1&0&0&0\\0&1&0&0\\0&0&0&1\\0&0&1&0\end{bmatrix}$ | Entanglement: control-target XOR |
| **Rotasi (RX, RY, RZ)** | $e^{-i\theta P/2}$ | Rotasi kontinu — parameterizable |

### Parameterized Quantum Circuit (PQC)

Jantung QML: **sirkuit dengan parameter yang bisa di-optimasi**.

```
|0⟩ ── H ── RY(θ₁) ──●─────────────────── RX(θ₄) ──⟩
                      │
|0⟩ ── H ── RY(θ₂) ──⊕── RY(θ₃) ─────────●───────⟩
                                          │
                                          └── RX(θ₅) ──⟩
```

3 qubit, 5 parameter. Vektor parameter $\theta = [\theta_1, \theta_2, \theta_3, \theta_4, \theta_5]$.

---

## VQE — Variational Quantum Eigensolver

### Paradigma VQE

VQE adalah algoritma hybrid klasikal-kuantum untuk mencari **eigenvalue minimum** dari Hamiltonian $H$.

```
┌─────────────────────────┐        ┌─────────────────────────┐
│   QUANTUM PROCESSOR     │        │   CLASSICAL OPTIMIZER   │
│                         │        │                         │
│  ┌───────────────────┐  │  ⟨H⟩   │  ┌───────────────────┐  │
│  │ Parameterized        │──┼─────┼──► Cari θ baru       │  │
│  │ Circuit U(θ)         │  │     │  │  yang minimalkan  │  │
│  │                      │  │     │  │  expectation value│  │
│  │ Siapkan state trial  │  │     │  │                   │  │
│  │ |ψ(θ)⟩ = U(θ)|0⟩     │  │     │  │ θ ← argmin ⟨H⟩    │  │
│  │                      │◄─┼─────┼──┤                   │  │
│  └───────────────────┘  │  θ_baru│  └───────────────────┘  │
└─────────────────────────┘        └─────────────────────────┘
```

**Langkah:**
1. Siapkan ansatz state $|\psi(\theta)\rangle = U(\theta)|0\rangle$
2. Ukur expectation value $\langle H \rangle = \langle \psi(\theta)| H |\psi(\theta)\rangle$
3. Classical optimizer update $\theta$ untuk minimalkan $\langle H \rangle$
4. Iterasi hingga konvergen

### Ansatz — Template Sirkuit VQE

Ansatz adalah "tebakan" struktur sirkuit. Pilihan ansatz sangat mempengaruhi konvergensi.

| Ansatz | Qubit | Gerbang | Depth | Kapan |
|--------|-------|---------|-------|-------|
| **Hardware-Efficient** | Bebas | RX, RY, RZ, CNOT (nearest-neighbor) | Rendah | Default — cocok untuk hardware noise |
| **UCCSD** (chemistry) | 2 × orbital | Fermionic excitation | Tinggi | Quantum chemistry — physical accuracy |
| **QAOA** | Problem-dependent | Phase + Mixer | Bervariasi | Combinatorial optimization |
| **HEA (Alternating)** | Bebas | Layer RX+CNOT+RY+CNOT | Sedang | General purpose QML |

### Contoh — VQE untuk H₂ Molecule

```python
import pennylane as qml
from pennylane import numpy as np

# Define molecule
H, qubits = qml.qchem.molecular_hamiltonian(
    ["H", "H"],
    coordinates=np.array([0.0, 0.0, -0.6614, 0.0, 0.0, 0.6614]),
    charge=0,
)

# Device
dev = qml.device("default.qubit", wires=qubits)

# Ansatz
def ansatz(params, wires):
    qml.BasisState(np.array([1, 1, 0, 0]), wires=wires)
    for i in range(2):
        qml.DoubleExcitation(params[i], wires=[0, 1, 2, 3])
        qml.SingleExcitation(params[i + 2], wires=[0, 2])
        qml.SingleExcitation(params[i + 4], wires=[1, 3])

# Cost function
@qml.qnode(dev)
def cost_fn(params):
    ansatz(params, wires=range(qubits))
    return qml.expval(H)

# Optimize
opt = qml.AdamOptimizer(stepsize=0.4)
params = np.random.normal(0, np.pi, 6)
for step in range(100):
    params, energy = opt.step_and_cost(cost_fn, params)
    if step % 10 == 0:
        print(f"Step {step}: Energy = {energy:.6f} Ha")
```

---

## Quantum Neural Networks — Arsitektur

### Struktur QNN

```
DATA ENCODING        VARIATIONAL LAYERS       MEASUREMENT
┌────────────┐     ┌──────────────────┐     ┌────────────┐
│ x₁ ── RY  │     │ ┌──┐ ┌──┐ ┌──┐   │     │ ⟨Z₀⟩ = y₁  │
│ x₂ ── RY  │     │ │RY│ │RY│ │RY│   │     │ ⟨Z₁⟩ = y₂  │
│ x₃ ── RY  │────►│ │CN│ │CN│ │CN│   │────►│ ⟨Z₂⟩ = y₃  │
│ ...       │     │ │RY│ │RY│ │RY│   │     │            │
│ x_n ── RY │     │ └──┘ └──┘ └──┘   │     │            │
└────────────┘     └──────────────────┘     └────────────┘
```

### 1. Data Encoding

Cara memasukkan data classical ke quantum state — **sangat mempengaruhi performa**.

| Method | Deskripsi | Qubit per Feature | Complexity |
|--------|-----------|-------------------|------------|
| **Angle Encoding** | $x_i \to RY(x_i)$ | 1 | $O(n)$ |
| **Amplitude Encoding** | $x \to \sum x_i |i\rangle$ | $\log n$ | $O(2^n)$ circuit depth |
| **IQP Encoding** | $x \to e^{i\sum x_i Z_i} H^{\otimes n}$ | 1 | $O(n)$ |
| **Hamiltonian Encoding** | $x \to e^{-iH(x)t}$ | 1-$n$ | Problem-dependent |

**Angle Encoding — Paling Sederhana:**

```python
def angle_encoding(x, wires):
    """Encode classical vector x ke rotation angles"""
    for i, val in enumerate(x):
        qml.RX(val, wires=i)    # atau RY, RZ
```

**Amplitude Encoding — Paling Efisien:**

```python
def amplitude_encoding(x, wires):
    """Encode normalized vector ke amplitude quantum state"""
    qml.AmplitudeEmbedding(features=x, wires=wires, normalize=True)
```

### 2. Variational Layers (Ansatz)

Lapisan yang berisi parameter yang di-training. Struktur umum tiap layer:

```
Layer l:
  1. Single-qubit rotations: RY(θ_{l,1}), RY(θ_{l,2}), ..., RY(θ_{l,n})
  2. Entangling gates: CNOT(0,1), CNOT(1,2), ..., CNOT(n-1, n)
  3. Optional: Second rotation layer — RZ(θ'_{l,i})
```

**StronglyEntanglingLayers (PennyLane):**

```python
@qml.template
def variational_block(params, wires):
    """params shape = (n_layers, n_qubits, 3) — 3 rotation per qubit per layer"""
    for layer in range(params.shape[0]):
        # Rotasi
        for qubit in range(params.shape[1]):
            qml.Rot(*params[layer, qubit], wires=qubit)
        # Entanglement — circulant
        for qubit in range(params.shape[1] - 1):
            qml.CNOT(wires=[qubit, qubit + 1])
        qml.CNOT(wires=[params.shape[1] - 1, 0])
```

### 3. Measurement

Pengukuran menghancurkan quantum state. Output adalah **expectation value** operator $O$:

$$\langle O \rangle = \langle \psi(\theta, x) | O | \psi(\theta, x) \rangle$$

Biasanya $O = Z$ (Pauli-Z) — output di [-1, 1], bisa di-rescale ke range target.

```python
@qml.qnode(dev)
def qnn(x, params):
    angle_encoding(x, wires)
    variational_block(params, wires)
    return [qml.expval(qml.PauliZ(i)) for i in range(n_qubits)]
```

### Quantum GAN (QGAN)

```
Generator (Quantum)              Discriminator (Classical)
┌─────────────────────┐         ┌────────────────────────┐
│                     │  fake    │                        │
│ Noise → PQC → State │──data──►│ Classical Neural Net   │
│        |ψ⟩          │         │ → real/fake            │
└──────┬──────────────┘         └────────────────────────┘
       │ real data (classical)
       ▼
┌──────────────────────────────────────────────────────────┐
│ Loss Functions                                            │
│ Generator: maximize D(G(z))  — quantum parameters         │
│ Discriminator: maximize log(D(x)) + log(1 - D(G(z)))     │
└──────────────────────────────────────────────────────────┘
```

---

## Quantum Kernel Methods — QSVM

### Intuisi

Quantum Kernel Methods menggunakan **quantum feature map** untuk memproyeksikan data ke ruang Hilbert berdimensi sangat tinggi, lalu menghitung kernel (inner product) di ruang itu.

$$K_{QP}(x_i, x_j) = |\langle \phi(x_i) | \phi(x_j) \rangle|^2$$

Di mana $|\phi(x)\rangle = U_\phi(x)|0\rangle$ — state setelah encoding circuit.

### QSVM Pipeline

```python
# 1. Definisikan quantum feature map
def feature_map(x, wires):
    """IQP-style feature map"""
    for i in range(len(x)):
        qml.Hadamard(wires=i)
        qml.RZ(x[i], wires=i)
    for i in range(len(x) - 1):
        qml.CNOT(wires=[i, i + 1])
        qml.RZ(x[i] * x[i + 1], wires=i + 1)
        qml.CNOT(wires=[i, i + 1])

@qml.qnode(dev)
def kernel(x1, x2):
    """Quantum kernel k(x1, x2) = |⟨φ(x1)|φ(x2)⟩|²"""
    feature_map(x1, wires)
    qml.adjoint(feature_map)(x2, wires)  # Inverse
    return qml.probs(wires=[0])

# 2. Hitung kernel matrix
K = np.zeros((len(X_train), len(X_train)))
for i in range(len(X_train)):
    for j in range(i, len(X_train)):
        K[i][j] = K[j][i] = kernel(X_train[i], X_train[j])

# 3. Train SVM dengan kernel matrix
from sklearn.svm import SVC
svm = SVC(kernel="precomputed")
svm.fit(K, y_train)
```

### Kelebihan Quantum Kernel

- **No variational parameters** — langsung compute kernel, hindari barren plateau
- **Proven advantage** — untuk certain data distributions, quantum kernel bisa classical-intractable
- **Integrasi mudah** — drop-in replacement untuk classical kernel di SVM

### Kelemahan

- **Kernel estimation noise** — quantum measurement inherent stochastic
- **Scaling** — kernel matrix $O(N^2)$ quantum circuit executions — mahal
- **Feature map design** — masih trial-and-error, belum ada teori panduan

---

## Barren Plateau — Musuh Utama QML

### Fenomena

Semakin banyak qubit, semakin **gradient cost function mendekati nol secara eksponensial**. Training menjadi mustahil — seperti mencari jarum di ruang berdimensi eksponensial.

$$\text{Variance}[\partial_\theta \langle H \rangle] \sim \mathcal{O}(2^{-n})$$

$n$ = jumlah qubit. Untuk 20 qubit, gradient variance sudah mencapai floating-point underflow.

### Penyebab

1. **Expressivity terlalu tinggi**: Sirkuit terlalu "acak" — parameter space terlalu besar
2. **Entanglement terlalu banyak**: Setiap gerbang CNOT meningkatkan entanglement → randomness
3. **Measurement locality**: Local operator $P_i$ tidak overlap dengan global effect

### Solusi

| Approach | Cara Kerja | Efektivitas |
|----------|------------|-------------|
| **Pretraining** | Latih layer-by-layer | Medium — problem-dependent |
| **Circuit shaping** | Batasi expressivity, kurangi entanglement | High — terbukti efektif |
| **Gradient-free optimizers** | COBYLA, Nelder-Mead | Medium — skalabilitas terbatas |
| **Layer-wise training** | Tambah 1 layer, train, freeze, repeat | Medium |
| **Adaptive ansatz** | Grow circuit secara adaptif | High — ADAPT-VQE, butuh overhead |
| **Correlated parameters** | Kelompokkan parameter yang berkorelasi | Early research |
| **Classical pre-solve** | Gunakan classical approximation sebagai initial point | Praktis |

**Circuit shaping — aturan praktis:**

```
❌ Terlalu expressif:
   Layer: RY ── CNOT ── RY ── CNOT ── RY ── ... (banyak layer)

✅ Cukup expressif untuk task:
   Layer: RY ── CNOT ── RZ ── CNOT ── RY    (depth optimal)
   Hanya 2-3 layer untuk classification sederhana
```

---

## Framework & Tools

| Framework | Backend | QML Features | Bahasa | Produksi? |
|-----------|---------|-------------|--------|-----------|
| **PennyLane** | Simulator + hardware | Full QML (QNN, kernel, VQE, QGAN) | Python | ✅ |
| **Qiskit (IBM)** | IBM Quantum + simulator | Qiskit ML (QSVM, QGAN) | Python | ✅ |
| **TensorFlow Quantum** | Cirq backend | Integrasi TF/Keras | Python | ⚠️ |
| **Braket (AWS)** | Simulator + IonQ/Rigetti | Hybrid jobs | Python | ✅ |
| **Cirq** | Google simulator | Low-level, TFQ integration | Python | ⚠️ |
| **PennyLane-Lightning** | GPU simulator | High-performance, multi-GPU | C++/Python | ✅ |
| **Strawberry Fields** | Photonic quantum | Continuous-variable QML | Python | ⚠️ |

---

## Step-by-Step Implementasi

### Binary Classification dengan QNN

```python
import pennylane as qml
from pennylane import numpy as np
from sklearn.datasets import make_moons

# 1. Data
X, y = make_moons(n_samples=200, noise=0.1)
X = (X - X.mean(0)) / X.std(0)  # Normalisasi

# 2. Device
n_qubits = 4
dev = qml.device("default.qubit", wires=n_qubits)

# 3. Circuit
@qml.qnode(dev)
def circuit(x, params):
    # Encoding
    for i in range(min(len(x), n_qubits)):
        qml.RX(x[i], wires=i)
    
    # Variational layers
    qml.BasicEntanglerLayers(params, wires=range(n_qubits))
    
    # Measurement
    return qml.expval(qml.PauliZ(0))

# 4. Cost
def cost(params, X, y):
    predictions = np.array([circuit(x, params) for x in X])
    return np.mean((predictions - y) ** 2)

# 5. Training
np.random.seed(42)
params = np.random.uniform(0, 2*np.pi, (3, n_qubits, 2))
opt = qml.AdamOptimizer(stepsize=0.1)

for step in range(200):
    params, loss = opt.step_and_cost(cost, params, X, y)
    if step % 20 == 0:
        acc = np.mean((np.array([circuit(x, params) for x in X]) > 0) == y)
        print(f"Step {step}: loss={loss:.4f}, acc={acc:.3f}")
```

### VQE untuk Optimization Problem

```python
# QAOA-style VQE untuk Max-Cut
def maxcut_hamiltonian(graph):
    """Convert Max-Cut problem ke Ising Hamiltonian"""
    H = qml.Hamiltonian([], [])
    for (i, j) in graph.edges:
        H += 0.5 * qml.PauliZ(i) @ qml.PauliZ(j)
    return H

def qaoa_ansatz(params, graph):
    """QAOA p-layer ansatz"""
    gamma, beta = params.reshape(2, -1)
    for i in range(p):
        # Phase separator
        for (u, v) in graph.edges:
            qml.CNOT(wires=[u, v])
            qml.RZ(2 * gamma[i], wires=v)
            qml.CNOT(wires=[u, v])
        # Mixer
        for node in graph.nodes:
            qml.RX(2 * beta[i], wires=node)
```

---

## Hybrid Quantum-Classical Pipeline

### Arsitektur Hybrid

```
┌──────────────────────────────────────────────────────────┐
│                    CLASSICAL LAYER                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Pre-     │  │ Feature  │  │ Post-    │  │ Evaluasi │  │
│  │ process  │─►│ Extract  │─►│ process  │─►│ & Vote   │  │
│  └──────────┘  └────┬─────┘  └──────────┘  └──────────┘  │
│                      │                                      │
│                      ▼                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              QUANTUM LAYER (QNN)                      │   │
│  │  |0⟩ ── Encoding ── Variational ── Measurement       │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

**Mengapa hybrid?**
- **Pre-process**: Classical dimension reduction (PCA) → kurangi qubit needed
- **Feature extract**: Classical NN extract feature → quantum classify
- **Post-process**: Classical ensemble voting dari multiple quantum circuits
- **Error mitigation**: Classical-zero-noise extrapolation (ZNE)

---

## Open Problems & Frontier

| Problem | Status | Impact if Solved |
|---------|--------|-----------------|
| **Barren Plateau** proof | Partial (conjecture + some proofs) | Enable deep QNN |
| **Quantum advantage** for ML | NOT YET PROVEN | Justify quantum investment |
| **Efficient gradient estimation** | Parameter shift rule works | But $O(p)$ circuits per step |
| **Error mitigation** at scale | ZNE, PEC work for | < 100 qubits |
| **Quantum data loading** | QRAM not built yet | Bottleneck for amplitude encoding |
| **Feature map design theory** | Heuristic only | Systematic QML architecture search |
| **Trainability guarantees** | Open | Predict if QNN will converge |

### Peta Jalan Realistis

| Tahun | Milestone |
|-------|-----------|
| **2026-2027** | NISQ devices 1000+ qubits (IBM), error-corrected prototypes |
| **2028-2029** | QML beats classical on **synthetic** quantum data |
| **2030+** | Fault-tolerant quantum → Shor + Grover-scale |
| **?** | QML beats classical on **real-world** classical data |

---

## Catatan Terkait

- **[[quantum-cryptography-deepdive]]** — Quantum cryptography (dasar kuantum)
- **[[hierarchy-classical-ml-algorithms]]** — ML klasik (fondasi untuk QML comparison)
- **[[attention-mechanism-deepdive]]** — Attention mechanism (classical parallel)
- **[[ai-engineering-stack-roadmap]]** — AI infra (hardware quantum vs classical)
- **[[cognitive-architecture-engineering]]** — Cognitive architecture (inspirasi dari nature)

---

> [!tip] Prinsip Praktis
> QML hari ini adalah **eksperimen, bukan produksi.** Jika classical ML sudah memberikan solusi yang memadai, gunakan classical. QML layak dicoba ketika: (a) data Anda memiliki struktur quantum (kimia, fisika partikel), (b) problem classical sangat mahal secara komputasi, (c) Anda siap dengan noise, barren plateau, dan scaling yang belum terbukti. Kerangka berpikir yang benar: **"Bisakah quantum membantu?"** bukan **"Ayo kita quantum-kan semuanya."** HHL dan VQE adalah early wins; QNN masih mencari pijakan.
