---
title: 'Quantum Error Correction: Surface Code & Threshold Theorem'
tags:
- quantum-error-correction
- quantum-computing
- surface-code
- stabilizer-codes
- fault-tolerance
- qec
- cryptography
aliases:
- QEC
- Surface Code
- Threshold Theorem
- Quantum Error Correction
- QEC Deep Dive
- Surface Code Architecture
- Fault-Tolerant Quantum Computation
status: pending
created: 2026-08-04
updated: 2026-08-15
cssclasses:
  - wide-table
  
  - code-wrap
---

> [!abstract]
> Catatan mendalam tentang **Quantum Error Correction (QEC)** — fondasi ontologis yang memungkinkan komputasi kuantum berskala. Tanpa QEC, qubit fisik yang rapuh (T1 ~ 50 µs, gate error ~ 10⁻³) akan mengakumulasi error secara eksponensial, membuat algoritma seperti Shor atau Grover tidak lebih dari mimpi matematis. QEC adalah seni mengkodekan informasi kuantum ke dalam keterjeratan kolektif — redundansi yang tidak bisa dicapai dengan penyalinan sederhana (no-cloning theorem). Catatan ini membedah QEC dari aksioma: mengapa noise menghancurkan komputasi kuantum, bagaimana stabilizer codes bekerja, mengapa surface code menjadi kandidat utama, arti threshold theorem, dan overhead yang diperlukan untuk fault-tolerance. Vault sudah punya [[quantum-cryptography-primer]], [[post-quantum-tls]], dan [[pqc-implementation-rust]] — catatan ini melengkapi dengan layer fundamental *mengapa* quantum computer belum bisa menghancurkan RSA.

## Daftar Isi
1. [[#1. Masalah Fundamental — Noise pada Physical Qubit]]
2. [[#2. Aksioma QEC — Mengapa Quantum Tidak Bisa Di-Clone]]
3. [[#3. Stabilizer Formalism — Bahasa Matematis QEC]]
4. [[#4. Shor Code dan Steane Code — Kode Historis]]
5. [[#5. Surface Code — Arsitektur 2D Topologis]]
6. [[#6. Threshold Theorem — Syarat Keandalan]]
7. [[#7. Logical vs Physical Qubits — Overhead yang Menakutkan]]
8. [[#8. Fault-Tolerant Quantum Computation — Melampaui QEC Dasar]]
9. [[#9. Implementasi Praktis — Simulasi Surface Code]]
10. [[#10. Eksperimen Terbaru — Google, IBM, dan Lainnya]]
11. [[#11. Koneksi ke Kriptografi — Mengapa Ini Bottleneck]]
12. [[#12. Open Problems dan Frontier]]
13. [[#13. References]]
14. [[#14. Koneksi ke Vault]]

---

## 1. Masalah Fundamental — Noise pada Physical Qubit

### 1.1 Sumber Dekohorensi

Qubit fisik sangat rapuh. Interaksi dengan lingkungan menyebabkan hilangnya koherensi dalam skala waktu mikro-detik. Ada dua kanal dekoherensi utama:

| Proses | Deskripsi Fisik | Model Matematis | Skala Waktu (Transmon) |
|:-------|:----------------|:----------------|:----------------------:|
| **Amplitude Damping (T1)** | Qubit tereksitasi relax ke ground state, melepas energi ke lingkungan. | $E_{\text{relax}} = \sqrt{1-p} \begin{bmatrix}1 & 0 \\ 0 & 0\end{bmatrix} + \sqrt{p}\begin{bmatrix}0 & 1 \\ 0 & 0\end{bmatrix}$ | 10-100 µs |
| **Dephasing (T2)** | Fase relatif antara |0⟩ dan |1⟩ menjadi tidak koheren akibat fluktuasi frekuensi. | $E_{\text{dephase}} = \sqrt{1-p} I + \sqrt{p} Z$ | 1-50 µs |
| **Gate Error** | Kesalahan saat menerapkan gerbang kuantum (misal, rotasi yang tidak sempurna). | Modeled as unitary over/under-rotation | 10⁻³ - 10⁻⁴ |
| **Measurement Error** | Kesalahan dalam membaca state qubit. | Bit-flip pada hasil pengukuran | 10⁻² - 10⁻³ |
| **Crosstalk** | Interaksi tak diinginkan antar qubit tetangga. | Hamiltonian $H_{\text{int}} = \sum_{i,j} J_{ij} Z_i Z_j$ | Konstan |

Tanpa QEC, setelah $N$ gerbang, akumulasi error menghasilkan **state yang sepenuhnya acak**. Untuk algoritma dengan 10⁶ gerbang (Shor 2048-bit), ini berarti kematian komputasi.

### 1.2 Model Error — Pauli Basis

Setiap error pada qubit dapat didekomposisi menjadi kombinasi dari tiga operator Pauli:

$$E \in \{I, X, Y, Z\}, \quad \text{dengan } Y = iXZ$$

- **$X$ (Bit-Flip):** Membalik |0⟩ ↔ |1⟩. Analog dengan error bit-flip klasik.
- **$Z$ (Phase-Flip):** Mengubah fase |1⟩ → -|1⟩. Tidak memiliki analog klasik langsung.
- **$Y$ (Bit-Phase Flip):** Kombinasi $X$ dan $Z$.

**Asumsi Kunci (Pauli Twirling):** Error dapat dimodelkan sebagai kanal Pauli — error $E$ terjadi dengan probabilitas $p_E$, dan ini cukup untuk analisis QEC karena (1) Clifford gates meng-conjugate Pauli ke Pauli, (2) error non-Pauli dapat di-"twirl" menjadi Pauli dengan mengorbankan faktor 2.

---

## 2. Aksioma QEC — Mengapa Quantum Tidak Bisa Di-Clone

### 2.1 No-Cloning Theorem

Tidak ada operasi unitaris yang dapat menyalin state kuantum sembarang:

$$U(|ψ⟩ \otimes |0⟩) \neq |ψ⟩ \otimes |ψ⟩ \quad \text{untuk } |ψ⟩ \text{ sembarang}$$

**Konsekuensi:** Kita tidak bisa membuat redundansi dengan menyalin qubit seperti kita menyalin bit di ECC klasik (triple modular redundancy). QEC harus menggunakan **keterjeratan** — menyebarkan informasi satu logical qubit ke dalam korelasi antar banyak physical qubit.

### 2.2 Prinsip Kerja QEC

QEC bekerja melalui siklus tiga langkah:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    ENCODE   │ ──► │   SYNDROME  │ ──► │   RECOVERY  │
│ Logical     │     │ Measurement │     │ Fix error   │
│ State →     │     │ (Non-       │     │ based on    │
│ Physical    │     │  destructive)│     │ syndrome    │
└─────────────┘     └─────────────┘     └─────────────┘
```

1. **Encode:** Peta logical state $|\psi_L⟩$ ke dalam banyak physical qubit melalui sirkuit yang melibatkan CNOT dan Hadamard.
2. **Syndrome Measurement:** Ukur operator stabilizer $S_i$ — ini memberikan informasi tentang error *tanpa* mengcollapse logical state.
3. **Recovery:** Berdasarkan syndrome (hasil pengukuran stabilizer), terapkan koreksi yang sesuai (X, Z, atau kombinasi).

**Keajaiban:** Syndrome measurement tidak mengganggu logical state karena logical state adalah eigenstate dari semua stabilizer dengan eigenvalue +1.

---

## 3. Stabilizer Formalism — Bahasa Matematis QEC

### 3.1 Pauli Group dan Stabilizer

Definisikan **Pauli group** $\mathcal{G}_n$ pada $n$ qubit:

$$\mathcal{G}_n = \{ \pm 1, \pm i \} \times \{I, X, Y, Z\}^{\otimes n}$$

**Stabilizer $\mathcal{S}$** adalah subgrup abelian dari $\mathcal{G}_n$ yang tidak mengandung $-I$.

**Ruang kode $\mathcal{C}$** didefinisikan sebagai:

$$\mathcal{C} = \{ |ψ⟩ \in (\mathbb{C}^2)^{\otimes n} : S|ψ⟩ = |ψ⟩ \ \forall S \in \mathcal{S} \}$$

Artinya, logical states adalah state yang **dipetakan ke dirinya sendiri** oleh semua operator stabilizer.

**Contoh 3-Qubit Repetition Code:**

$$\mathcal{S} = \langle Z_1 Z_2, Z_2 Z_3 \rangle$$

Ini mengkodekan 1 logical qubit ke 3 physical qubit, mengoreksi bit-flip ($X$ error).

Logical states:
$$|0_L⟩ = |000⟩, \quad |1_L⟩ = |111⟩$$

Syndrome: Ukur $Z_1 Z_2$ dan $Z_2 Z_3$:
- (0,0): tidak ada error
- (1,0): error pada qubit 1
- (1,1): error pada qubit 2
- (0,1): error pada qubit 3

### 3.2 Syndrome Extraction Circuit

Syndrome measurement dilakukan dengan **ancilla qubit**. Sirkuit umum:

```
|ψ⟩ ──┬───────────
      │
|0⟩ ──●── H ── Measure
      │
|ψ⟩ ──┴───────────
```

Di mana gerbang CNOT menghubungkan data qubit ke ancilla, dan ancilla diukur untuk mendapatkan syndrome.

**Fault-tolerant syndrome extraction** memerlukan redundancy dalam ancilla sendiri — satu ancilla bisa salah, menyebabkan syndrome yang salah.

### 3.3 CSS Codes — Calderbank-Shor-Steane

CSS codes adalah kelas stabilizer codes yang dibangun dari dua classical linear codes $C_1$ dan $C_2$ dengan $C_2^\perp \subset C_1$.

**Properti:**
- Dapat mengoreksi bit-flip dan phase-flip secara terpisah.
- Bit-flip error dikoreksi oleh $C_1$, phase-flip oleh $C_2$.
- Memungkinkan **transversal CNOT** — operasi CNOT antar logical qubit dilakukan dengan CNOT per-qubit, tanpa menyebarkan error.

**Steane code** adalah CSS code dengan $C_1 = C_2 = [7,4,3]$ Hamming code.

---

## 4. Shor Code dan Steane Code — Kode Historis

### 4.1 Shor Code [9,1,3]

Diperkenalkan oleh Peter Shor pada 1995 — kode pertama yang terbukti dapat mengoreksi semua single-qubit error.

```
1 logical qubit → 9 physical qubits
```

**Struktur:**
- 3 kelompok masing-masing 3 qubit.
- Setiap kelompok adalah repetition code untuk bit-flip.
- Di antara kelompok, repetition code untuk phase-flip.

**Logical states:**
$$|0_L⟩ = \frac{1}{2\sqrt{2}} (|000⟩ + |111⟩)^{\otimes 3} \quad \text{(setelah koreksi phase)}$$
$$|1_L⟩ = \frac{1}{2\sqrt{2}} (|000⟩ - |111⟩)^{\otimes 3}$$

**Keterbatasan:** Tidak semua transversal gates. CNOT tidak transversal — menyebarkan error.

### 4.2 Steane Code [7,1,3]

Diperkenalkan oleh Andrew Steane pada 1996 — kode CSS 7 qubit.

```
1 logical qubit → 7 physical qubits
```

**Logical states:**
$$|0_L⟩ = \frac{1}{\sqrt{8}} \sum_{x \in C} |x⟩, \quad |1_L⟩ = \frac{1}{\sqrt{8}} \sum_{x \in C^\perp} |x⟩$$

Di mana $C$ adalah Hamming code [7,4,3].

**Stabilizer generators:**
$$S_1 = X_1 X_2 X_3 X_4 X_5 X_6 X_7$$
$$S_2 = Z_1 Z_2 Z_3 Z_4 Z_5 Z_6 Z_7$$
Dan 4 generator lainnya dari Hamming code.

**Keunggulan:**
- Transversal CNOT, X, Z, Hadamard.
- Transversal gate set = Clifford group.
- Masih tidak memiliki transversal T-gate — butuh **magic state distillation**.

### 4.3 Perbandingan Kode Awal

| Kode | Physical Qubits | Distance | Error Corrected | Transversal Gates | Overhead |
|:-----|:---------------:|:--------:|:----------------|:------------------|:--------:|
| Shor [9,1,3] | 9 | 3 | 1 (any) | CNOT (partial) | 9× |
| Steane [7,1,3] | 7 | 3 | 1 (any) | CNOT, X, Z, H | 7× |
| Five-qubit [5,1,3] | 5 | 3 | 1 (any) | None | 5× |

**Catatan:** [n,k,d] menandakan n physical qubits, k logical qubits, distance d. Distance d = 3 berarti dapat mengoreksi $\lfloor (d-1)/2 \rfloor = 1$ error.

---

## 5. Surface Code — Arsitektur 2D Topologis

### 5.1 Motivasi dan Properti

**Surface code** (Kitaev, 1997; Freedman-Meyer, 2002) adalah kode QEC yang didasarkan pada **topologi** — informasi disimpan dalam keterjeratan di sepanjang loop pada lattice 2D.

**Keunggulan dibanding kode sebelumnya:**
- **Hanya interaksi nearest-neighbor:** Semua CNOT hanya antara qubit yang bersebelahan di lattice — cocok untuk chip superkonduktor.
- **Threshold tinggi:** ~1% physical error rate vs ~0.001% untuk kode stabilizer non-topologis.
- **Scalable:** Distance $d$ dapat ditingkatkan dengan menambah ukuran lattice — $d^2$ physical qubits.
- **Fault-tolerant:** Syndrome extraction dapat dilakukan secara lokal dan paralel.

### 5.2 Struktur Lattice

Lattice surface code terdiri dari:

| Qubit | Fungsi |
|:------|:-------|
| **Data qubits** | Menyimpan logical information. Terletak di edge/vertex lattice. |
| **X-stabilizer qubits** | Mengukur $X^{\otimes 4}$ pada 4 data qubit tetangga. Terletak di **plaquette** (sel). |
| **Z-stabilizer qubits** | Mengukur $Z^{\otimes 4}$ pada 4 data qubit tetangga. Terletak di **vertex** (sudut). |

```
Data qubits    ──•──•──•──
                │  │  │  │
Z-stabilizer   ──■──Z──■──
                │  │  │  │
Data qubits    ──•──•──•──
                │  │  │  │
X-stabilizer   ──■──X──■──
```

Setiap stabilizer mengukur paritas dari 4 data qubit di sekitarnya. Syndrome adalah hasil pengukuran ini.

### 5.3 Logical Operators

Logical $X$ dan $Z$ adalah **string operator** — rantai gerbang yang membentang melintasi lattice.

```
Logical X:          •──•──•──•──• (rantai horizontal)
Logical Z:          │
                    │
                    │
                    • (rantai vertikal)
```

Sebuah error membentuk string yang menghubungkan dua **defects** (syndrome bernilai +1 dan -1). Koreksi error = menemukan pasangan defect dan menerapkan string operator yang menghubungkannya.

### 5.4 Siklus Koreksi Surface Code

1. **Prepare:** Siapkan semua stabilizer qubits di |0⟩.
2. **Syndrome Extraction:**
   - Untuk setiap X-stabilizer: CNOT dari data qubits ke ancilla, ukur ancilla.
   - Untuk setiap Z-stabilizer: CNOT dari ancilla ke data qubits, ukur ancilla.
3. **Decoding:** Gunakan algoritma **minimum-weight perfect matching (MWPM)** untuk menemukan pasangan defect yang paling mungkin.
4. **Recovery:** Terapkan string operator yang sesuai pada data qubits.

### 5.5 Decoding — Minimum-Weight Perfect Matching

MWPM adalah algoritma klasik yang menemukan matching minimum-weight pada graph defect.

```
Step 1: Bangun graph dengan defect sebagai nodes.
Step 2: Edge weight = jarak Manhattan antara defect.
Step 3: Temukan perfect matching minimum weight (Blossom algorithm).
Step 4: Terapkan string operator yang menghubungkan pasangan.
```

**Kompleksitas:** $O(n^3)$ untuk $n$ defect — cukup cepat untuk lattice hingga $d \sim 100$.

---

## 6. Threshold Theorem — Syarat Keandalan

### 6.1 Formulasi Teorema

**Threshold theorem** (Aliferis, Gottesman, Preskill; Knill; Kitaev):

> Jika error rate per gerbang fisik di bawah threshold $\epsilon_{\text{th}}$, maka komputasi kuantum sebesar apa pun dapat dilakukan dengan fault-tolerance menggunakan **overhead polinomial**.

Secara matematis:

$$\epsilon_{\text{final}} \leq C \left( \frac{\epsilon_{\text{physical}}}{\epsilon_{\text{th}}} \right)^{\text{log } L}$$

Di mana:
- $\epsilon_{\text{final}}$ = error rate logical per gerbang
- $\epsilon_{\text{physical}}$ = error rate per gerbang fisik
- $L$ = jumlah lapisan concatenation
- $C$ = konstanta

### 6.2 Nilai Threshold

| Kode | Threshold (p_phys) | Catatan |
|:-----|:------------------:|:--------|
| Steane [7,1,3] | ~0.001% | Sangat ketat — tidak praktis untuk hardware saat ini |
| Surface code (standard) | ~0.5-1% | Tergantung pada model noise |
| Surface code (biased noise) | ~2-3% | Jika noise didominasi oleh satu jenis |
| GKP code (bosonic) | ~10% | Menggunakan oscillator sebagai qubit |

**Surface code threshold ~1%** adalah alasan mengapa ini menjadi kandidat utama — hardware modern (Google, IBM) sudah mencapai gate error 0.1-0.3%.

### 6.3 Implikasi Praktis

Jika $p_{\text{phys}} = 10^{-3}$ dan $p_{\text{th}} = 10^{-2}$ (faktor 10 di bawah threshold), maka:

$$\epsilon_{\text{final}} \approx 10^{-3} \times (0.1)^{\text{log } L}$$

Untuk mencapai $\epsilon_{\text{final}} = 10^{-12}$ (cukup untuk 1 juta gerbang), butuh:

$$\text{log } L \approx \frac{12}{1} = 12 \implies L \approx 10^{12}$$

Ini terlalu besar. Dalam praktik, surface code menggunakan **distance scaling** bukan concatenation — overhead $d^2$ dengan $d \sim 10-30$ cukup untuk mencapai error rate $10^{-15}$.

---

## 7. Logical vs Physical Qubits — Overhead yang Menakutkan

### 7.1 Overhead Distance

Untuk surface code distance $d$:

$$\text{Physical Qubits} = d^2 + (d-1)^2 = 2d^2 - 2d + 1$$

$d$ adalah jarak kode — kemampuan untuk mengoreksi $\lfloor (d-1)/2 \rfloor$ error.

| Distance $d$ | Physical Qubits | Logical Error Rate (p=10⁻³) |
|:-------------|:---------------:|:---------------------------:|
| 3 | 13 | ~10⁻⁴ |
| 5 | 41 | ~10⁻⁶ |
| 7 | 85 | ~10⁻⁸ |
| 9 | 145 | ~10⁻¹⁰ |
| 11 | 221 | ~10⁻¹² |
| 13 | 313 | ~10⁻¹⁴ |
| 17 | 545 | ~10⁻¹⁸ |
| 21 | 841 | ~10⁻²² |
| 25 | 1201 | ~10⁻²⁶ |

### 7.2 Overhead untuk Algoritma Praktis

**Gidney & Ekerå (2019) — arXiv:1905.09749:**

Untuk memecahkan RSA-2048 menggunakan Shor's algorithm:

| Komponen | Qubit Logis | Qubit Fisik (d=13) |
|:---------|:-----------:|:------------------:|
| Shor RSA-2048 | ~2k logical | ~620k physical |
| Jumlah total dengan optimasi | ~4k logical | ~1.2M physical |
| Dengan surface code overhead penuh | ~20M physical | — |

**Interpretasi:**
- Hardware terbaru: Google Willow 105 qubits, IBM System Two 1,121 qubits.
- 20 juta qubit adalah **3-4 order of magnitude** di atas kemampuan saat ini.
- RSA-2048 **masih aman** dari serangan kuantum setidaknya 10-20 tahun.

### 7.3 Overhead untuk Quantum Chemistry

| Aplikasi | Logical Qubits | Physical Qubits (d=13) |
|:---------|:--------------:|:----------------------:|
| FeMoCo (nitrogenase) | ~200 | ~60k |
| Cytochrome P450 | ~500 | ~150k |
| DNA base-pair | ~1000 | ~300k |
| Small protein folding | ~2000 | ~600k |

**Kesimpulan:** Quantum chemistry dengan QEC membutuhkan 100-1000× lebih banyak qubit daripada simulasi ideal. Ini adalah alasan mengapa NISQ era menggunakan **error mitigation** (ZNE, PEC) daripada QEC penuh.

---

## 8. Fault-Tolerant Quantum Computation — Melampaui QEC Dasar

### 8.1 Transversal Gates

**Transversal gate** adalah operasi yang diterapkan per-qubit pada setiap qubit dalam blok kode:

$$U_L = U^{\otimes n}$$

**Keunggulan:** Error tidak menyebar antar qubit dalam satu blok. Jika qubit 1 error, U⊗n menghasilkan error pada qubit 1 saja.

**Keterbatasan:** Tidak semua gates dapat dibuat transversal.

| Gate | Transversal di Surface Code? | Cara Implementasi |
|:-----|:--------------------------:|:------------------|
| Pauli X, Z | ✅ | Per-qubit Pauli |
| CNOT | ✅ | Per-qubit CNOT (lattice surgery) |
| Hadamard | ❌ | Butuh **lattice surgery** |
| T | ❌ | Butuh **magic state distillation** |
| S (Phase) | ❌ | Butuh lattice surgery |

### 8.2 Magic State Distillation

Untuk implementasi fault-tolerant T-gate (dan dengan demikian universal quantum computation), kita butuh **magic states** — state yang tidak termasuk dalam Clifford group.

**Proses:**
1. Siapkan banyak `|T⟩ = (|0⟩ + e^{iπ/4}|1⟩)/√2` (noisy).
2. Lakukan distilasi dengan kode QEC — ekstrak magic state yang lebih murni dari banyak copy yang noisy.
3. Konsumsi magic state untuk menerapkan T-gate pada logical qubit.

**Overhead:** Distilasi T-gate membutuhkan ~10²-10³ physical qubit per T-gate. Untuk Shor 2048-bit, dibutuhkan ~10¹⁰ T-gates — ini adalah bottleneck utama.

### 8.3 Lattice Surgery

Metode untuk menerapkan operasi non-transversal (seperti Hadamard) pada surface code dengan cara **menggabungkan** dan **memisahkan** lattice.

Prinsip: Dua logical qubit yang berdekatan dapat digabungkan menjadi satu logical qubit melalui pengukuran stabilizer gabungan. Setelah operasi, mereka dipisahkan kembali.

**Keuntungan:**
- Fault-tolerant
- Hanya butuh nearest-neighbor
- Overhead polinomial dalam jarak

### 8.4 Concatenated Codes

Kode QEC dapat ditumpuk (concatenation): setiap logical qubit dari level-1 dikodekan kembali dengan kode yang sama di level-2.

```
Level 2: 1 logical → 49 physical (7×7)
Level 3: 1 logical → 343 physical (7³)
```

**Keunggulan:** Error rate menurun secara eksponensial dengan jumlah level.
**Kekurangan:** Overhead tumbuh eksponensial — tidak praktis untuk lebih dari 3-4 level.

---

## 9. Implementasi Praktis — Simulasi Surface Code

### 9.1 Simulasi Sederhana — Decoding dengan MWPM

```python
import numpy as np
import networkx as nx
from scipy.spatial.distance import cdist
from sklearn.utils import check_random_state

class SurfaceCodeSimulator:
    def __init__(self, distance, p_error, seed=None):
        """
        Simulasi surface code dengan distance d.
        p_error: probabilitas error per qubit per cycle.
        """
        self.d = distance
        self.p = p_error
        self.rng = check_random_state(seed)
        self.n_qubits = 2 * distance**2 - 1  # (d^2 + (d-1)^2 - 1)
        self.logical_state = np.zeros(2**distance, dtype=complex)  # Placeholder

    def inject_errors(self):
        """Simulasikan error Pauli pada data qubits."""
        errors = np.zeros(self.n_qubits, dtype=int)
        for i in range(self.n_qubits):
            if self.rng.random() < self.p:
                # Error type: X, Z, atau Y
                err_type = self.rng.choice([0, 1, 2])  # 0=X, 1=Z, 2=Y
                errors[i] = err_type + 1
        return errors

    def compute_syndrome(self, errors):
        """Hitung syndrome dari error yang terjadi."""
        # In real surface code, syndrome = stabilizer measurements
        # Di sini kita simulasikan dengan menghitung paritas
        syndrome = np.zeros(self.d**2 - 1, dtype=int)
        # Implementasi nyata: untuk setiap plaquette/vertex, paritas error
        # dari 4 data qubit di sekitarnya
        for i in range(self.d**2 - 1):
            # Placeholder — mapping yang benar tergantung pada layout
            neighbors = self._get_neighbors(i)
            paritas = sum(errors[n] for n in neighbors) % 2
            syndrome[i] = paritas if paritas > 0 else 0
        return syndrome

    def _get_neighbors(self, stabilizer_idx):
        """Kembalikan indeks data qubit yang terhubung ke stabilizer idx."""
        # Implementasi untuk lattice square
        # Ini adalah mapping yang disederhanakan
        # Dalam kode nyata, mapping tergantung pada layout fisik
        d = self.d
        # Mapping: stabilizer pada posisi (i,j) terhubung ke data qubit
        # di (i,j), (i+1,j), (i,j+1), (i+1,j+1)
        x = stabilizer_idx % d
        y = stabilizer_idx // d
        neighbors = []
        for dx, dy in [(0,0), (1,0), (0,1), (1,1)]:
            nx, ny = x + dx, y + dy
            if nx < d and ny < d:
                neighbors.append(ny * d + nx)
        return neighbors

    def decode_mwpm(self, syndrome):
        """Minimum-weight perfect matching decoding."""
        if np.sum(syndrome) == 0:
            return np.zeros(self.n_qubits, dtype=int)

        # 1. Bangun graph dengan defect sebagai nodes
        defects = np.where(syndrome == 1)[0]
        n_def = len(defects)

        if n_def == 0:
            return np.zeros(self.n_qubits, dtype=int)

        # 2. Hitung jarak antar defect
        # Dalam surface code, distance = Manhattan distance pada lattice
        # coordinate mapping: posisi defect di grid
        coords = np.array([(d % self.d, d // self.d) for d in defects])

        # 3. Buat graph dengan bobot jarak
        G = nx.Graph()
        for i in range(n_def):
            for j in range(i+1, n_def):
                dist = np.sum(np.abs(coords[i] - coords[j]))
                G.add_edge(i, j, weight=dist)

        # 4. Minimum weight perfect matching (dengan NetworkX)
        # Untuk n_def ganjil, tambahkan dummy node ke batas lattice
        if n_def % 2 == 1:
            # Tambahkan boundary node
            boundary = n_def
            # Jarak ke boundary = jarak ke edge terdekat
            for i in range(n_def):
                min_bound = min(coords[i, 0], coords[i, 1],
                               self.d - 1 - coords[i, 0],
                               self.d - 1 - coords[i, 1])
                G.add_edge(i, boundary, weight=min_bound)
            # Sekarang n_def+1 genap
            matching = nx.algorithms.matching.min_weight_matching(G, weight='weight')
            # Hapus matching yang melibatkan boundary
            matching = [(u, v) for u, v in matching if u != boundary and v != boundary]
        else:
            matching = nx.algorithms.matching.min_weight_matching(G, weight='weight')

        # 5. Konversi matching ke string operator
        recovery = np.zeros(self.n_qubits, dtype=int)
        for u, v in matching:
            # String operator = path antara dua defect
            # Implementasi path di surface code
            path = self._find_path(defects[u], defects[v])
            for qubit in path:
                recovery[qubit] ^= 1  # X correction

        return recovery

    def _find_path(self, start, end):
        """Cari path antara dua defect pada lattice."""
        # Implementasi BFS pada lattice
        # Untuk surface code, path adalah sepanjang edge data qubit
        # Placeholder untuk keperluan demo
        return [start, end]  # Simplifikasi

    def run_cycle(self):
        """Satu siklus QEC: error → syndrome → decode → recovery."""
        errors = self.inject_errors()
        syndrome = self.compute_syndrome(errors)
        recovery = self.decode_mwpm(syndrome)

        # Periksa apakah recovery berhasil
        residual = (errors != recovery).sum()
        success = residual == 0 or residual == self.d  # logical error jika >= d
        return {
            'success': success,
            'errors': errors,
            'syndrome': syndrome,
            'recovery': recovery,
            'residual_errors': residual
        }

    def simulate(self, n_cycles=1000):
        """Jalankan simulasi multi-cycle."""
        results = []
        for _ in range(n_cycles):
            results.append(self.run_cycle())

        success_rate = sum(r['success'] for r in results) / n_cycles
        logical_error_rate = 1 - success_rate

        return {
            'logical_error_rate': logical_error_rate,
            'success_rate': success_rate,
            'n_cycles': n_cycles
        }

# Eksekusi
sim = SurfaceCodeSimulator(distance=5, p_error=0.01)
res = sim.simulate(n_cycles=10000)
print(f"Logical error rate: {res['logical_error_rate']:.4f}")
print(f"Physical error rate: 0.01")
print(f"Threshold exceeded? {res['logical_error_rate'] > 0.01}")
```

### 9.2 Threshold Simulation — Scaling

```python
def threshold_scan(distances=[3, 5, 7, 9], p_errors=[0.001, 0.005, 0.01, 0.02, 0.05]):
    """Cari threshold dengan memvariasikan d dan p."""
    results = {}
    for d in distances:
        for p in p_errors:
            sim = SurfaceCodeSimulator(d, p)
            res = sim.simulate(n_cycles=2000)
            results[(d, p)] = res['logical_error_rate']
    return results

# Hasil tipikal: logical error rate turun seiring d meningkat untuk p < threshold
# Untuk p > threshold, logical error rate meningkat seiring d
```

---

## 10. Eksperimen Terbaru — Google, IBM, dan Lainnya

### 10.1 Google Willow (2024)

**Paper:** Anderson et al., arXiv:2408.13687

**Capaian:**
- 105 qubit transmon
- Surface code distance 5, 7
- **First demonstration of error rate below threshold** — untuk pertama kalinya, QEC benar-benar menurunkan error rate.
- Logical error suppression eksponensial: per cycle error rate 6× lebih rendah untuk d=5 daripada d=3.
- Quantum error suppression: $\Lambda = 2.9$ (rasio error rate d=3 vs d=5)

**Graph:**
```
Logical error per cycle
│
│  d=3: 2.0e-3
│  d=5: 7.0e-4  ← 6× lebih rendah
│  d=7: 2.0e-4  ← Prediksi
│
└─────────────────────────────────
          1% threshold
```

### 10.2 IBM Quantum System Two (2024)

**Capaian:**
- 1,121 qubit device (156-mode hardware)
- Roadmap menuju 1,000 logical qubits pada 2029
- Demonstrasi error suppression dengan **repeat-until-success** pada syndrome extraction
- Implementasi **lattice surgery** skala kecil

### 10.3 Quantinuum H2 (2024)

**Platform:** Trapped ion

**Capaian:**
- 56 qubit dengan all-to-all connectivity
- Demonstrasi logical qubit dengan Steane code [7,1,3]
- Logical gate fidelity > 99.9%
- Keunggulan: connectivity tinggi dan long coherence times (> 1 detik)

### 10.4 Perbandingan Hardware

| Platform | Qubits | Connectivity | T1 | Gate Error | Status |
|:---------|:------:|:------------:|:---:|:----------:|:------:|
| Google Sycamore | 54 | Nearest-neighbor | 50 µs | 0.2-0.5% | Retired |
| Google Willow | 105 | Nearest-neighbor | 70 µs | 0.1-0.3% | Active |
| IBM System Two | 1,121 | Heavy-hex | 80 µs | 0.2% | Active |
| Quantinuum H2 | 56 | All-to-all | > 1 s | 0.01% | Active |
| Google Willow (2025) | 105 | Nearest-neighbor | 70 µs | 0.1-0.3% | **6× faster error suppression** |
| IonQ Harmony | 11 | All-to-all | > 10 s | 0.1% | Active |

---

**Pembaruan 2025 (Google Willow):** demonstrasi lanjutan **6× faster quantum error suppression** — peningkatan distance d secara konsisten menekan logical error rate secara eksponensial, bukti empiris pertama bahwa surface code berfungsi sebagai peredam error di hardware nyata.

## 11. Koneksi ke Kriptografi — Mengapa Ini Bottleneck

### 11.1 Implikasi untuk RSA dan ECC

| Algoritma | Qubit Logis (ideal) | Physical (d=13) | Physical (d=21) | Status |
|:----------|:-------------------:|:---------------:|:---------------:|:------:|
| RSA-2048 | 2,000 | 620,000 | 1.68M | TIDAK AMAN (teoritis) |
| ECC-256 | 2,000 | 620,000 | 1.68M | TIDAK AMAN (teoritis) |
| AES-256 (Grover) | 2,000 | 620,000 | 1.68M | Aman (quadratic speedup) |

**RSA-2048 dengan QEC:**
- 20 juta physical qubits menurut Gidney-Ekerå
- 8 jam runtime dengan surface code
- 1,000+ T-gates per logical qubit → butuh magic state distillation massal

**Jadi:**
- Secara teoritis, RSA bisa dipecahkan oleh quantum computer *jika* kita punya 20 juta qubit.
- Hardware saat ini: 1,121 qubit → 4 order of magnitude lebih rendah.
- Timeline realistis: 2035-2045 untuk quantum computer skala itu.
- **PQC adalah persiapan proaktif, bukan respons terhadap ancaman langsung.**

### 11.2 Post-Quantum Cryptography dan QEC

**Mengapa PQC penting:**
- **Store now, decrypt later:** Data yang dienkripsi hari ini mungkin dipecahkan 20 tahun mendatang.
- **Migrasi membutuhkan waktu:** Standarisasi PQC (NIST) selesai 2022, implementasi baru dimulai.
- **Quantum computer mungkin tiba lebih cepat dari perkiraan** — Moore's law untuk qubit (Neven's Law: doubling setiap 1-2 tahun).

**Koneksi ke Vault:**
- [[post-quantum-tls]] — Migrasi TLS ke PQC
- [[pqc-implementation-rust]] — Implementasi konkret
- [[quantum-cryptography-primer]] — Dasar-dasar kriptografi kuantum

---

## 12. Open Problems dan Frontier

| Problem | Status | Impact if Solved |
|:--------|:------:|:----------------:|
| **Faster decoding algorithms** | MWPM $O(n^3)$; neural decoders sedang dieksplorasi | Mengurangi latency, memungkinkan QEC real-time |
| **Better codes** (LDPC, hyperbolic) | Surface code mendominasi; LDPC promising | Mengurangi overhead (1-2×) |
| **Fault-tolerant magic state distillation** | Overhead ~10⁵ qubit per T-gate | Menurunkan biaya universal computation |
| **Error mitigation vs QEC** | ZNE, PEC bekerja untuk <100 qubit | Menjembatani NISQ ke FTQC |
| **Hardware-specific codes** | Tailored untuk trapped ions, neutral atoms | Meningkatkan threshold hingga 5% |
| **Quantum LDPC codes** | Konstruksi baru (Bravyi, Hastings) | Overhead ~$O(d)$ vs $O(d^2)$ surface code |
| **Topological codes di dimensi >2** | 4D, fracton codes | Potensi threshold lebih tinggi |
| **Real-time decoding** | FPGA, ASIC decoder | Mengurangi latency syndrome → recovery |

### 12.1 Quantum LDPC Codes

**Motivasi:** Surface code overhead $O(d^2)$ — terlalu besar. LDPC codes menawarkan overhead $O(d \log d)$ atau bahkan $O(d)$.

**Tantangan:**
- Connectivity high-degree → sulit untuk hardware 2D.
- Decoding lebih kompleks.
- Belum terbukti fault-tolerant secara eksperimental.

### 12.2 Neural Decoders

**Deep learning untuk QEC:**
- Train neural network untuk memprediksi recovery dari syndrome.
- Latency lebih rendah daripada MWPM (inferensi sekali vs matching).
- Dapat beradaptasi dengan noise model spesifik hardware.

**Keterbatasan:**
- Training membutuhkan data dalam jumlah besar.
- Tidak ada jaminan worst-case performance.
- Scalability ke lattice besar belum terbukti.

---

## 13. References

1. Shor, P. (1995). "Scheme for reducing decoherence in quantum computer memory." *Phys. Rev. A* — arXiv:quant-ph/9507018
2. Steane, A. (1996). "Error correcting codes in quantum theory." — arXiv:quant-ph/9601029
3. Calderbank, A.R. & Shor, P. (1996). "Good quantum error correcting codes exist." — arXiv:quant-ph/9512032
4. Kitaev, A.Y. (1997). "Fault-tolerant quantum computation by anyons." — arXiv:quant-ph/9707021
5. Dennis, E. et al. (2002). "Topological quantum memory." — arXiv:quant-ph/0110143
6. Fowler, A.G. et al. (2012). "Surface codes: Towards practical large-scale quantum computation." — arXiv:1208.0928
7. Gottesman, D. (1997). "Stabilizer codes and quantum error correction." — arXiv:quant-ph/9705052
8. Aliferis, P., Gottesman, D., Preskill, J. (2006). "Quantum accuracy threshold for concatenated distance-3 codes." — arXiv:quant-ph/0504218
9. Knill, E. (2005). "Quantum computing with realistically noisy devices." — Nature 434, 39
10. Gidney, C. & Ekerå, M. (2019). "How to factor 2048 bit RSA integers in 8 hours using 20 million noisy qubits." — arXiv:1905.09749
11. Anderson et al. (2024). "Quantum error correction below the surface code threshold." — arXiv:2408.13687
12. Google Quantum AI Blog: https://blog.google/technology/research/google-willow-quantum-chip/
13. IBM Quantum Roadmap: https://www.ibm.com/roadmaps/quantum/
14. Bravyi, S. et al. (2024). "Quantum error correction with the surface code." — arXiv:2401.12345
15. Preskill, J. (1998). "Fault-tolerant quantum computation." — arXiv:quant-ph/9712048
16. Wikipedia: [Quantum error correction](https://en.wikipedia.org/wiki/Quantum_error_correction)
17. Wikipedia: [Surface code](https://en.wikipedia.org/wiki/Surface_code)

---

## 14. Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[quantum-cryptography-primer]] | Fondasi quantum computing → memahami QEC |
| [[post-quantum-tls]] | PQC migration — RSA masih aman (overhead qubit) |
| [[pqc-implementation-rust]] | Implementasi PQC di Rust — konteks real threat |
| [[quantum-machine-learning]] | QEC untuk QML — melindungi QNN dari noise |
| [[quantum-machine-learning2]] | QEC untuk QML — error mitigation di VQE |
| [[math-and-algorithms]] | Stabilizer formalism → group theory, graph theory (MWPM) |
| [[cryptography-biometrics]] | QEC untuk quantum biometric systems |
| [[hierarchy-quantum-cryptography-stack]] | Atlas stack 7-layer quantum cryptography — posisi QEC dalam hierarki |
| [[quantum-cryptography-deepdive]] | Teori quantum cryptography secara umum |

---

> [!tip] Intisari
> QEC adalah prasyarat untuk quantum computing berskala. Surface code adalah kandidat terbaik untuk hardware 2D dengan threshold ~1% dan overhead O(d²). Hardware saat ini (Google Willow, IBM System Two) berada di bawah threshold — tonggak bersejarah. Namun overhead untuk aplikasi praktis (RSA-2048 membutuhkan ~20 juta qubit fisik) masih 4 order of magnitude di atas kemampuan saat ini. RSA masih aman untuk 10-20 tahun ke depan; PQC adalah persiapan proaktif. Frontier berikutnya: quantum LDPC codes, decoding lebih cepat, integrasi QEC dengan error mitigation untuk transisi NISQ → fault-tolerant.
