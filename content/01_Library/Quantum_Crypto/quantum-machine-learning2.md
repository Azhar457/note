---
title: ⚛️ QUANTUM MACHINE LEARNING — Arsitektur Kognitif di Persimpangan Realitas
tags:
- quantum-computing
- qml
- vqe
- qnn
- hybrid-quantum
aliases:
- Quantum ML
- QML Architecture
- Hybrid Classical-Quantum Intelligence
created: 2026-07-14
updated: 2026-08-14
status: pending
cssclasses:
  - wide-table
  - callout
---

# ⚛️ QUANTUM MACHINE LEARNING — Arsitektur Kognitif di Persimpangan Realitas

**Dari Superposisi ke Advantage: Sebuah Deep Dive ke dalam Pabrik Komputasi Kuantum untuk Kecerdasan Buatan**

> [!abstract] Paradigma Baru Komputasi
> Quantum Machine Learning bukanlah sekadar "ML yang berjalan di komputer kuantum." Ia adalah **perluasan radikal dari ruang fitur** ke dalam ruang Hilbert yang kaya secara eksponensial. Jika komputasi klasik adalah sebuah titik, komputasi kuantum adalah sebuah bola—setiap titik di permukaannya adalah superposisi yang dapat dihuni oleh informasi. Dokumen ini adalah cetak biru arsitektur untuk memanfaatkan properti paradoksikal ini—superposisi, interferensi, dan keterjeratan—bukan sebagai fenomena aneh, melainkan sebagai **alat komputasi fundamental** untuk membangun generasi baru model machine learning.
## 🧬 1. First Principles: Mengapa Kuantum untuk ML? Sebuah Analisis Fundamental

Untuk memahami QML, kita harus meninggalkan metafora klasik dan langsung terjun ke dalam matematika. Sumber *quantum advantage* yang potensial bukanlah mistis; ia berakar pada tiga pilar mekanika kuantum.

1.  **Superposisi (Parallelism Inheren):** Sebuah register klasik `n`-bit hanya dapat merepresentasikan satu dari `2^n` keadaan pada satu waktu. Sebuah register `n`-qubit dapat berada dalam superposisi dari **semua `2^n` keadaan secara simultan**: `|ψ⟩ = Σ c_x |x⟩`. Ini bukan paralelisme klasik; ini adalah kemampuan untuk memproses semua solusi potensial dalam satu operasi kuantum.

2.  **Interferensi (Amplifikasi Sinyal):** Komputasi kuantum adalah tentang mengelola amplitudo probabilitas. Algoritma kuantum dirancang untuk menciptakan interferensi konstruktif pada solusi yang benar (`|c_correct|^2 → 1`) dan interferensi destruktif pada solusi yang salah (`|c_wrong|^2 → 0`). Dalam QML, ini adalah fondasi dari **Quantum Kernel Methods**: fitur map `φ(x)` memproyeksikan data ke ruang di mana pola-pola penting saling memperkuat dan noise saling meniadakan.

3.  **Keterjeratan (Korelasi Non-Klasik):** Ketika qubit terjerat, deskripsi keadaan mereka tidak dapat difaktorkan menjadi bagian-bagian independen. Keadaan sistem adalah korelasi itu sendiri. Ini memungkinkan model untuk menangkap korelasi tingkat tinggi dalam data yang membutuhkan sumber daya eksponensial untuk direpresentasikan oleh model klasik. Sebuah Quantum Neural Network (QNN) pada dasarnya adalah pabrik untuk menciptakan dan memanipulasi korelasi-korelasi ini.

### Analogi Kognitif: Dari Memori ke Ruang Fitur

| Komputasi Klasik | Komputasi Kuantum | Analogi dalam ML |
| :--- | :--- | :--- |
| **Bit** (0 atau 1) | **Qubit** (superposisi α\|0⟩ + β\|1⟩) | Fitur yang tidak pasti atau multi-nilai |
| **Gerbang Logika** (AND, XOR) | **Gerbang Kuantum** (Hadamard, CNOT, Rotasi) | Transformasi data yang *reversible* dan *unitary* |
| **Ruang Input** (R^n) | **Ruang Hilbert** (C^2^n) | Kernel trick yang diproyeksikan ke dimensi sangat tinggi secara eksplisit |
| **Optimasi** (Gradient Descent) | **Prinsip Variasional** (Minimalisasi ⟨H⟩) | Mencari keadaan dasar (*ground state*) dari "Hamiltonian Kehilangan" (Loss Hamiltonian) |
| **Overfitting** | **Barren Plateau** (Gradien lenyap) | Kegagalan mode pelatihan yang unik akibat terlalu banyak ekspresivitas |

---

## 🔩 2. VQE (Variational Quantum Eigensolver) — Pilar Fundamental QML

VQE adalah "Hello, World!" sekaligus *workhorse* dari era NISQ (Noisy Intermediate-Scale Quantum). Ini adalah algoritma hibrida klasik-kuantum yang dirancang untuk memecahkan masalah fundamental dalam kimia kuantum: mencari energi keadaan dasar (eigenvalue minimum) dari sebuah molekul, yang diwakili oleh Hamiltonian `H`.

### 2.1 Paradigma VQE: Sebuah Simfoni Komputasi

VQE adalah tarian antara dua dunia. Ia adalah loop OODA (Observe, Orient, Decide, Act) yang diterapkan pada domain kuantum.

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│   QUANTUM PROCESSOR (QPU)       │     │   CLASSICAL OPTIMIZER (CPU/GPU) │
│                                 │     │                                 │
│  ┌───────────────────────────┐  │ E   │  ┌───────────────────────────┐  │
│  │ Sirkuit Parameterized U(θ)│──┼─────┼─►│ Menerima E = ⟨H⟩          │  │
│  │ Mempersiapkan |ψ(θ)⟩      │  │     │  │                           │  │
│  │                           │  │     │  │ Menghitung ∇E(θ)          │  │
│  │ Mengukur ⟨H⟩ = ⟨ψ\|H\|ψ⟩  │  │     │  │ Memperbarui θ ← θ - η∇E  │  │
│  └───────────────────────────┘  │ θ'  │  └───────────────┬───────────┘  │
│                                 ◄─────┼──────────────────┘              │
└─────────────────────────────────┘     └─────────────────────────────────┘
```

1.  **Act (QPU):** Sirkuit parameterized `U(θ)` mempersiapkan *trial state* `|ψ(θ)⟩`.
2.  **Observe (QPU):** QPU mengukur *expectation value* energi, `⟨H⟩ = ⟨ψ(θ)| H |ψ(θ)⟩`. Ini adalah "loss function" kita.
3.  **Orient (CPU):** Pengoptimal klasik menerima nilai `⟨H⟩` dan menghitung (atau memperkirakan) gradiennya terhadap parameter `θ`.
4.  **Decide (CPU):** Pengoptimal memperbarui parameter `θ` untuk meminimalkan `⟨H⟩`, dan mengirimkannya kembali ke QPU.

### 2.2 Implementasi Praktis: VQE untuk Molekul H₂

Ini adalah contoh kanonik yang mendemonstrasikan seluruh loop VQE. Hamiltonians `H` untuk molekul Hidrogen dihitung, dan sebuah ansatz (tebakan cerdas untuk bentuk sirkuit) dibangun.

```python
# Kode untuk VQE Molekul H₂
import pennylane as qml
from pennylane import numpy as np

# 1. Definisikan Molekul & Hamiltonian H
# Hamiltonian adalah "guru" yang energinya ingin kita minimalkan.
H, qubits = qml.qchem.molecular_hamiltonian(
    ["H", "H"],
    coordinates=np.array([0.0, 0.0, -0.6614, 0.0, 0.0, 0.6614]),
    charge=0,
)
dev = qml.device("default.qubit", wires=qubits)

# 2. Definisikan Ansatz (Tebakan Sirkuit)
# Ansatz UCCSD (Unitary Coupled Cluster Singles and Doubles) adalah pilihan yang
# terinspirasi fisika untuk masalah kimia.
def ansatz(params, wires):
    qml.BasisState(np.array([1, 1, 0, 0]), wires=wires)
    for i in range(2):
        qml.DoubleExcitation(params[i], wires=[0, 1, 2, 3])
        qml.SingleExcitation(params[i + 2], wires=[0, 2])
        qml.SingleExcitation(params[i + 4], wires=[1, 3])

# 3. Definisikan QNode (Cost Function)
@qml.qnode(dev)
def cost_fn(params):
    ansatz(params, wires=range(qubits))
    return qml.expval(H)  # Mengembalikan ⟨H⟩

# 4. Jalankan Loop Optimasi Klasik
opt = qml.AdamOptimizer(stepsize=0.4)
params = np.random.normal(0, np.pi, 6)
for step in range(100):
    params, energy = opt.step_and_cost(cost_fn, params)
    if step % 10 == 0:
        print(f"Step {step}: Energy = {energy:.6f} Ha")
```

Ini bukan sekadar kode; ini adalah **manifestasi fisik dari prinsip variasional dalam mekanika kuantum**, yang diotomatisasi oleh pengoptimal klasik. Sirkuit kuantum bertindak sebagai *function approximator* untuk fungsi gelombang kuantum.

---

## 🧠 3. Arsitektur QNN — Merancang Pabrik Korelasi Kuantum

Quantum Neural Network (QNN) bukanlah tiruan dari NN klasik. Ia adalah arsitektur yang secara fundamental berbeda, dirancang untuk memproses informasi dalam ruang Hilbert. Tiga komponennya—encoding, variational layers, dan measurement—masing-masing memiliki peran kritis.

### 3.1 Data Encoding: Menjembatani Dunia Klasik dan Kuantum

Ini adalah salah satu aspek paling kritis dari QML. Bagaimana Anda merepresentasikan data klasik `x` sebagai keadaan kuantum `|φ(x)⟩`? Metode encoding secara langsung mempengaruhi ekspresivitas, trainability, dan potensi keunggulan kuantum.

| Metode Encoding        | Mekanisme Kuantum           | Koneksi Vault (Biometrik & Kriptografi)           |                                                                                                                                |
| :--------------------- | :-------------------------- | :------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| **Basis Encoding**     | `x (biner) ->               | x⟩`. Setiap bit menjadi qubit.                    | **[[cryptography-biometrics]]** — Representasi langsung dari hash atau kunci kriptografi.                                      |
| **Amplitude Encoding** | `x (vektor) -> Σ x_i        | i⟩`. Data disimpan dalam amplitudo.               | **[[math-and-algorithms]]** — Sangat efisien, tetapi sulit dan mahal untuk dimuat.                                             |
| **Angle Encoding**     | `x (vektor) -> ⊗ RY(x_i)    | 0⟩`. Setiap fitur menjadi rotasi.                 | **[[swarm-ai-imam-robandi]]** — Encoding paling sederhana, cocok untuk PSO/VQE.                                                |
| **IQP Encoding**       | `x -> exp(i Σ x_i Z_i) H^⊗n | 0⟩`. Menciptakan kernel yang sulit secara klasik. | **[[llm-security-red-teaming-attack-surface-ai-layer]]** — Mengubah input sederhana menjadi representasi yang sangat kompleks. |

### 3.2 Data Re-Uploading: Membangun Kedalaman Tanpa Kedalaman Fisik

Sebuah inovasi kunci untuk mengatasi NISQ yang "dangkal" adalah **data re-uploading**. Alih-alih meng-encode data sekali di awal, data di-encode ulang di setiap layer sirkuit.
`|ψ(x,θ)⟩ = U(θ_L)U_φ(x) ... U(θ_1)U_φ(x) |0⟩`
Ini memungkinkan sirkuit yang dangkal untuk menciptakan batas keputusan yang sangat kompleks, mirip dengan cara jaringan dalam klasik menambah lapisan.

### 3.3 Measurement & Output: Menghancurkan Superposisi untuk Mendapatkan Jawaban

Output dari QNN adalah ekspektasi dari operator terukur `O`.
`ŷ(θ, x) = ⟨ψ(x,θ)| O |ψ(x,θ)⟩`
Biasanya, `O = Z` (operator Pauli-Z), memberikan output dalam rentang `[-1, 1]`. Untuk multi-class classification, kita dapat menggunakan multiple readout qubit.

---

## ⚔️ 4. Quantum Support Vector Machine — Intuisi Kernel di Ruang Raksasa

QSVM adalah salah satu jalur paling menjanjikan menuju keunggulan kuantum karena menghindari jebakan pelatihan variasional (barren plateau). QSVM adalah perwujudan murni dari **kernel trick**.

### 4.1 Alur Arsitektur QSVM

1.  **Peta Fitur Kuantum:** Data `x_i` dipetakan ke keadaan kuantum `|φ(x_i)⟩` melalui sirkuit `U_φ(x_i)`.
2.  **Komputasi Kernel Kuantum:** Kernel kuantum dihitung sebagai *overlap* antara dua keadaan fitur: `K_{QP}(x_i, x_j) = |⟨φ(x_i) | φ(x_j)⟩|^2`.
3.  **Klasifikasi Klasik:** Matriks kernel `K` yang dihasilkan dimasukkan ke dalam SVM klasik standar untuk menemukan hyperplane pemisah optimal.

**Keunggulan:** Dengan memilih peta fitur yang tepat, kernel kuantum dapat dihitung secara efisien di perangkat kuantum, sementara perhitungannya mungkin *intractable* untuk komputer klasik. Inilah definisi dari *quantum advantage*.

**Implementasi Kritis:** Komputasi kernel dieksploitasi dengan cerdik menggunakan **Hadamard test**, memanfaatkan interferometri kuantum untuk mengekstrak nilai inner product.

```python
# Implementasi Quantum Kernel
@qml.qnode(dev)
def quantum_kernel(x1, x2):
    """Menghitung |⟨φ(x1)|φ(x2)⟩|²"""
    # Terapkan fitur map untuk x1
    feature_map(x1, wires)
    # Terapkan invers dari fitur map untuk x2 (destructive interference)
    qml.adjoint(feature_map)(x2, wires)
    # Probabilitas mengukur |0...0⟩ adalah |⟨φ(x1)|φ(x2)⟩|²
    return qml.probs(wires=[0])
```

---

## 🛡️ 5. Barren Plateau — Ancaman Eksistensial bagi QML

Jika Differential Privacy adalah "Ring 4" dari keamanan AI klasik, maka **Barren Plateau adalah "Ring 0" dari QML**. Ini adalah kerentanan fundamental yang muncul dari ekspresivitas sirkuit kuantum itu sendiri.

### 5.1 Mekanisme Kegagalan Pelatihan

Untuk sirkuit yang terlalu ekspresif, lanskap loss menjadi sangat datar secara eksponensial dengan bertambahnya jumlah qubit. Gradien loss function terhadap parameter sirkuit menjadi nol rata-rata dan memiliki varians yang lenyap secara eksponensial (`Var[∂_θ E] ~ O(2^{-n})`). Pengoptimal klasik tidak dapat bergerak; ia buta dan lumpuh.

### 5.2 Spektrum Ekspresivitas: Menemukan Titik Manis

Solusi untuk Barren Plateau bukanlah menghindari ekspresivitas, melainkan mengelolanya. Ada spektrum antara sirkuit yang terlalu sederhana (under-parameterized) dan terlalu ekspresif (over-parameterized).

```
┌───────────────────────────────┬─────────────────────────────────┬─────────────────────────────────┐
│ UNDER-PARAMETERIZED           │ SWEET SPOT (Efisien &            │ OVER-PARAMETERIZED              │
│                               │ Trainable)                      │ (Barren Plateau)                │
├───────────────────────────────┼─────────────────────────────────┼─────────────────────────────────┤
│ • Terlalu sederhana           │ • Problem-informed ansatz       │ • Sirkuit acak yang dalam       │
│ • Tidak bisa merepresentasikan│ • Struktur entanglement terbatas│ • Terlalu banyak qubit, terlalu  │
│   solusi                      │ • Correlated parameters         │   banyak gerbang                │
│ • Bias tinggi                 │ • Data re-uploading             │ • Varians gradien ~ 2^(-n)      │
└───────────────────────────────┴─────────────────────────────────┴─────────────────────────────────┘
```

**Koneksi Vault:** Konsep menemukan *sweet spot* dalam kompleksitas model adalah cerminan langsung dari **bias-variance tradeoff** di **[[00_Atlas/hierarchy-classical-ml-algorithms]]**. Barren Plateau adalah manifestasi kuantum dari overfitting yang ekstrem.

---

## 🚀 6. Peta Jalan Menuju Keunggulan Kuantum: Dari NISQ ke Toleransi Kesalahan

QML bukanlah tujuan akhir; ia adalah kendaraan untuk mencapai **Keunggulan Kuantum Praktis**. Perjalanannya bertahap.

| Era | Perangkat Keras | Algoritma Kunci | Tolok Ukur Keberhasilan |
| :--- | :--- | :--- | :--- |
| **2023-2026 (NISQ)** | 100-1000+ qubit, noise tinggi | VQE, QAOA, QSVM, QNN dengan *error mitigation* | **Quantum Utility:** Melakukan tugas yang mustahil disimulasikan secara klasik, meskipun belum berguna secara komersial. |
| **2028+ (Fault-Tolerant)** | Gerbang logis dengan error rate < 10^-10 | HHL, Shor, Grover, algoritma QML yang membutuhkan kedalaman tinggi | **Quantum Advantage:** QML memecahkan masalah dunia nyata (penemuan obat, ilmu material) lebih cepat atau lebih murah daripada superkomputer klasik mana pun. |
| **2035+ (Skala Penuh)** | Komputer kuantum modular dengan ribuan qubit logis | QML otonom, agen kuantum, optimasi rantai pasok global | **Quantum-Native AI:** AI yang lahir dan berjalan secara fundamental di atas perangkat keras kuantum. |

---

## 🔗 7. Koneksi ke Ekosistem Vault

| Domain Vault | Koneksi Fundamental |
| :--- | :--- |
| **[[15-types-of-thinking]]** | QML adalah perwujudan mesin dari *Abstract Thinking* yang ekstrem. Ia beroperasi pada probabilitas dan superposisi, bukan logika biner. |
| **[[math-and-algorithms]]** | Aljabar Linear adalah bahasa ibu QML. Ruang Hilbert, dekomposisi nilai eigen (VQE), dan operasi matriks adalah fondasi dari segalanya. |
| **[[cryptography-biometrics]]** | VQE dan QSVM adalah "pencuri" dari algoritma kriptografi klasik. Mereka mencari "kunci" (keadaan dasar) di ruang kunci yang eksponensial. QML adalah sisi ofensif dari komputasi pasca-kuantum. |
| **[[cognitive-architecture-engineering]]** | Loop VQE (Ansatz -> Ukur -> Optimasi -> Ulangi) adalah cikal bakal dari **OODA Loop Kuantum**. Ia adalah "Meta-Agent" yang menyetir sistem kuantum menuju solusi. |

## 🔍 Verification Report
> [!NOTE]
> **Last Evaluated:** 2026-08-12 20:13
> **Overall Epistemic Status:** **`UNVERIFIED`**

### ❔ Claim 1: An n-qubit register can exist in a superposition of all 2^n states simultaneously.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 2: VQE is a hybrid classical-quantum algorithm designed to find the minimum eigenvalue (ground state energy) of a Hamiltonian H.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 3: Quantum computing uses constructive interference to increase the probability amplitude of correct solutions and destructive interference to decrease the probability amplitude of incorrect solutions.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.