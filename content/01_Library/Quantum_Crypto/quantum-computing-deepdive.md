---
tags:
  - quantum
  - qubit
  - hardware
  - programming
  - algorithms
  - error-correction
aliases:
  - Quantum Computing Deep Dive
  - Dari Qubit ke Quantum Advantage
  - Quantum Stack Lengkap
  - Quantum Computing Researcher Reference
status: seedling
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# ⚛️ Quantum Computing — Dari Prinsip ke Praktik

> [!tip] Tidak seperti bit klasik, qubit adalah "bullet dengan nama Anda" — ia menggunakan superposisi, entanglement, dan interferensi untuk mempercepat komputasi tertentu secara eksponensial. Catatan ini mencakup seluruh stack quantum computing dari postulat matematis (Born rule, Bloch sphere, operator), gerbang universal, algoritma (Shor, Grover, VQE, QAOA, QPE), hardware (5 platform qubit + metrik), error correction (surface code + Google Willow 2024), pemrograman (Qiskit, Cirq, Q#), dan batas fundamental (BQP, no-cloning, decoherence, threshold theorem). Domain kuantum yang **sama sekali belum tersentuh di vault** — vault hanya punya sisi kriptografi.

---

## Teorema Threshold (Fault-Tolerance)

**Teorema** (Aharonov & Ben-Or, 1997; Kitaev, 1997): Jika error rate fisik per gate $p < p_{\text{th}} \approx 1\%$, maka kita dapat menjalankan sirkuit quantum dengan panjang $L$ dan error maksimum $\epsilon$ menggunakan $O(\text{poly}(\log(L/\epsilon)))$ overhead — asalkan error $p$ di bawah threshold.

**Milestone — Google Willow (Dec 2024):**

- Surface code $d = 7$, 105 qubit fisik → logical qubit dengan error rate ($\epsilon_{\text{logical}} \approx 0.15\%$) LEBIH RENDAH dari qubit fisik penyusun ($\epsilon_{\text{physical}} \approx 2.8\%$).
- Paper: "Quantum error correction below the surface code threshold" — Nature, 2024.
- Implikasi: **Threshold tercapai — scalability sekarang masalah engineering, bukan fisika fundamental.**

---

## 5. Hardware — Platform Qubit

### 5.1 DiVincenzo Criteria (2000)

Lima syarat yang harus dipenuhi sistem untuk komputasi quantum yang berguna:

1. **Scalability** — qubit count bisa ditingkatkan
2. **Initialization** — semua qubit bisa di-reset ke $|0\rangle$ dengan fidélitas > 99%
3. **Coherence** — $T_2 > 10^4 t_g$ (waktu dephasing > 10.000 gate time)
4. **Universal gates** — set gerbang universal bisa diimplementasikan
5. **Measurement** — qubit individu bisa diukur dengan fidélitas > 90%

### 5.2 Superconducting Qubit (IBM, Google, Rigetti)

**Mekanisme:** Josephson junction — lapisan insulator di antara dua superconductor → sirkuit LC anharmonik dengan level energi diskrit.

$$ H = 4E_C \hat{n}^2 - E_J \cos\hat{\phi}, \quad E_J \gg E_C \ (\text{transmon}) $$

| Parameter               |         Nilai (2026)          |
| ----------------------- | :---------------------------: |
| T1 (relaxation)         |          100–500 μs           |
| T2 (dephasing)          |           50–200 μs           |
| F1Q (single-qubit gate) |             99.9%             |
| F2Q (CNOT)              |  99.6% (IBM), 99.8% (Google)  |
| Gate time               |           20–100 ns           |
| Suhu operasi            | 15 mK (dilution refrigerator) |

**Pemain:**

- **IBM Quantum:** Heavy-hex lattice, Quantum Condor target 1.121 qubit (2025), IBM Quantum Network.
- **Google Quantum AI:** Sycamore (53 qubit, 2019) → Willow (105 qubit, 2024) — below-threshold QEC.
- **Rigetti:** Ankaa-3 (84 qubit), multi-chip architecture.

**Kelebihan:** Gate cepat (ns), fabrikasi semikonduktor, integrasi dengan kontrol elektronik CMOS.
**Kelemahan:** Coherence pendek (μs), cross-talk antar qubit tetangga, butuh cryogenic besar.

### 5.3 Trapped Ion (Quantinuum, IonQ)

**Mekanisme:** Ion atomik ($^{171}\text{Yb}^+$, $^{43}\text{Ca}^+$) di-perangkap oleh Paul trap (RF + DC) dalam ultra-high vacuum. Qubit di-encode di hyperfine ground state.

$$ |0\rangle = |F=0, m_F=0\rangle, \quad |1\rangle = |F=1, m_F=0\rangle $$

| Parameter     |  Nilai   |
| ------------- | :------: |
| T2 coherence  | ~1 detik |
| F1Q           |  99.97%  |
| F2Q (MS gate) |  99.9%   |
| Gate time     | 1–100 μs |

**Kelebihan:** Fidélitas tertinggi di semua platform, all-to-all connectivity (setiap qubit bisa berinteraksi dengan qubit lain), coherence detik, semua ion identik (tidak ada variasi fabrikasi).
**Kelemahan:** Gate lambat (μs), skalabilitas terbatas (sulit >100 ion satu trap), butuh laser ultra-stabil.

**Pemain:**

- **Quantinuum (Honeywell):** H2 — 56 qubit, fidélitas logis tertinggi.
- **IonQ:** Aria (25 qubit), accessible via cloud (AWS, Azure, GCP).

### 5.4 Photonic (Xanadu, PsiQuantum)

**Mekanisme:** Qubit di-encode dalam properti foton (polarization, time-bin, path). Komputasi dilakukan via interferensi foton di beamsplitter + pengukuran.

**Kelebihan:** Suhu ruang, coherence panjang (foton hampir tidak berinteraksi dengan lingkungan), kecepatan komunikasi (fiber optik), fabrikasi CMOS-compatible (waveguide, modulator).
**Kelemahan:** Gerbang dua-qubit probabilistik (butuh multiplexing/time-multiplexing), loss foton di serat/detektor, sulit membuat deterministik entanglement.

**Pemain:**

- **Xanadu:** Borealis — 216 squashed mode, Gaussian boson sampling.
- **PsiQuantum:** Fusion-based quantum computing, target 1 juta qubit — fabrikasi di foundry semikonduktor standar.

### 5.5 Silicon Spin (Intel, QuTech)

**Mekanisme:** Spin elektron dalam quantum dot pada substrat silikon $^{28}\text{Si}$ (isotope-purified untuk menghilangkan nuclear spin noise).

| Parameter |       Nilai       |
| --------- | :---------------: |
| T2        | 1–10 ms (silicon) |
| F1Q       |       99.9%       |
| Gate time |     10–100 ns     |
| Suhu      |       ~1 K        |

**Kelebihan:** Ukuran sangat kecil (~50 nm), bisa diintegrasi dengan CMOS foundry (memanfaatkan fabrikasi transistor yang sudah mature), density tinggi.
**Kelemahan:** Scalability quantum dot masih eksperimental, fidelity lebih rendah dari superconducting untuk 2Q gate.

**Pemain:**

- **Intel:** Tunnel Falls — 12 qubit, diproduksi di D1 fab (300 mm wafer).
- **CEA-Leti / Quobly:** FD-SOI spin qubit.
- **Diraq:** Silicon CMOS-compatible qubit, target ~10 mK.

### 5.6 Topological (Microsoft — belum terbukti)

**Mekanisme:** Qubit di-encode dalam Majorana Zero Mode (MZM) — quasiparticle yang muncul di nanowire superkonduktor. Proteksi topologi: error rate sangat rendah secara alamiah.

**Status 2026:** Masih kontroversial. Microsoft klaim 2022 → retracted 2023. Eksperimen dari Delft (QuTech) dan Copenhagen memberikan bukti paling kuat untuk MZM — tapi belum mencapai qubit operasional.

**Jika berhasil:** Bisa mempercepat timeline fault-tolerant quantum computing 5-10 tahun karena error correction yang jauh lebih sederhana.

### 5.7 Tabel Perbandingan Hardware

| Metrik             | Superconducting | Trapped Ion |  Photonic   | Silicon Spin |  Topological  |
| ------------------ | :-------------: | :---------: | :---------: | :----------: | :-----------: |
| T2 time            |    10–500 μs    |     1 s     |  ∞ (foton)  |   1–10 ms    | ~ (protected) |
| F1Q                |      99.9%      |   99.97%    |    99.8%    |    99.9%     |       —       |
| F2Q                |      99.6%      |    99.9%    | ~98% (prob) |    99.6%     |       —       |
| Gate time          |    20–100 ns    |  1–100 μs   |    ~1 ns    |  10–100 ns   |       —       |
| Suhu               |      15 mK      |     4 K     |    Room     |     ~1 K     |     15 mK     |
| Qubit count (2026) |      ~1000      |     56      |    ~100     |     ~12      |   0 (belum)   |
| Scalability        |     Medium      |     Low     |    High     |     High     |    (High)     |
| Fabrikasi          |     Custom      |   Custom    |    CMOS     |     CMOS     |    Custom     |

### 5.8 Decoherence

**Sumber noise:**

| Sumber        | Asal                                | Mitigasi                                |
| ------------- | ----------------------------------- | --------------------------------------- |
| Charge noise  | Fluktuasi tegangan di gate/junction | Transmon ($E_J \gg E_C$)                |
| Flux noise    | Fluktuasi medan magnet              | Magnetic shielding, echo                |
| Photon noise  | Blackbody radiation                 | Cryogenic attenuator, IR filter         |
| Quasiparticle | Cooper pair broken                  | Material purity, gap engineering        |
| Nuclear spin  | Spin bath di substrate              | Isotope purification ($^{28}\text{Si}$) |
| Phonon        | Lattice vibration                   | Sub-mK temperatur                       |

**Landauer bound vs quantum:** Gerbang quantum idealnya reversible → tidak ada energi minimum per operasi (tidak seperti $kT\ln 2$ Landauer untuk bit erase). Namun realitas hardware: cryogenic cooling untuk 1.000 qubit = ~10 kW listrik.

---

## 6. Quantum Error Correction

### 6.1 Mengapa Kita Butuh QEC

- Error rate fisik $p \approx 10^{-3}$ per gate
- Target: $10^{-15}$ untuk algoritma fault-tolerant (setara ECC memory)
- Butuh logical qubit dengan error rate lebih rendah dari fisik

### 6.2 Surface Code

**Struktur:**

```
Data qubit:   ●──●──●──●
              │  │  │  │
              ●──●──●──●
              │  │  │  │
              ●──●──●──●
Ancilla:      ○ (X-stabilizer)
              ○ (Z-stabilizer)
```

**Parameter kunci:**

- Code distance $d$ — jarak minimum antara dua error yang tidak terdeteksi
- Number of physical qubits: $2d^2 - 1$
- Threshold: $p_{\text{th}} \approx 1\%$
- Scaling error: $\epsilon_{\text{logical}} \propto (p/p_{\text{th}})^{(d+1)/2}$

**Overhead:**

| $d$ | Physical qubits/logical | $\epsilon_{\text{logical}}$ (at $p=10^{-3}$) |
| :-: | :---------------------: | :------------------------------------------: |
|  3  |           17            |                  $10^{-5}$                   |
|  7  |           97            |                  $10^{-11}$                  |
| 15  |           449           |                  $10^{-25}$                  |
| 17  |           577           |                  $10^{-30}$                  |

**Google Willow 2024 — Milestone:** $d = 7$ → logical error rate ($0.15\%$) < physical error rate ($2.8\%$). Threshold tercapai!

### 6.3 Logical Qubit Overhead

Untuk menjalankan Shor's algorithm pada 2048-bit RSA:

- ~3.000 logical qubit
- ~577 physical qubit per logical qubit ($d=17$)
- **Total: ~1,7 juta physical qubit** — belum tercapai 2026, tapi roadmap IBM/Google menargetkan 2030-2035.

---

## 7. Algoritma Quantum

### 7.1 Klasifikasi

| Algoritma                   |   Speedup    | Aplikasi                                                   | Tahun |
| --------------------------- | :----------: | ---------------------------------------------------------- | :---: |
| **Shor**                    | Eksponensial | Faktorisasi, logaritma diskrit                             | 1994  |
| **Grover**                  |  Kuadratik   | Search unstructured, SAT, kriptografi simetris             | 1996  |
| **QPE**                     | Eksponensial | Simulasi kimia (estimasi eigenvalue)                       | 1995  |
| **VQE**                     |   (Hybrid)   | Ground state energy                                        | 2014  |
| **QAOA**                    |  Heuristic   | MaxCut, optimasi kombinatorial                             | 2014  |
| **Amplitude Amplification** |  Kuadratik   | Generalisasi Grover                                        | 2000  |
| **HHL**                     | Eksponensial | Linear systems solving (matrix inversion)                  | 2009  |
| **QSVT**                    |  Framework   | Quantum Singular Value Transform — unifies semua algoritma | 2018  |

### 7.2 Shor's Algorithm — Detail

**Input:** $N = pq$ (produk dua prima)

**Langkah:**

1. Pilih $a$ acak, $1 < a < N$
2. Hitung $g = \gcd(a, N)$. Jika $g > 1$, return $g$.
3. Cari period $r$ dari $f(x) = a^x \bmod N$ menggunakan **Quantum Fourier Transform**
4. Faktor: $p = \gcd(a^{r/2} - 1, N)$

**Kompleksitas:**

- Classical: $O(\exp((\log N)^{2/3}))$ (General Number Field Sieve)
- Quantum: $O((\log N)^3)$ — **eksponensial speedup**

**Sirkuit depth untuk 2048-bit RSA:** ~$10^{12}$ T-gates → butuh ~1,7 juta physical qubit.

### 7.3 Grover's Algorithm — Detail

**Input:** Oracle $O_f$ yang mengidentifikasi 1 item target dari $N$ item

**Langkah:**

```
Prepare uniform superposition → Repeat √N times:
  1. Oracle: flip sign of target amplitude
  2. Diffusion: invert about mean
→ Measure
```

**Kompleksitas:** $O(\sqrt{N})$ — kuadratik speedup.

**Implikasi:** Kriptografi simetris (AES) hanya butuh key length 2× lebih panjang. AES-128 → setara AES-64? Tidak — AES-256 tetap aman (Grover adalah quantum attack terbaik untuk AES, dan $G(\text{AES-256}) \approx 2^{128}$ — masih aman).

### 7.4 Variational Quantum Eigensolver (VQE)

**Arsitektur hybrid classical-quantum:**

```
Classical optimizer (COBYLA, SPSA)
    ──→ θ
    │    ↓
    │   Quantum circuit (U(θ))
    │    ↓
    └── E(θ) = ⟨ψ(θ)|H|ψ(θ)⟩ (estimasi)
```

**Kompleksitas:** Parameter $O(\text{poly}(n))$ untuk mencapai chemical accuracy ($\approx 1.6 \times 10^{-3}$ Hartree).

**Aplikasi:** Kimia kuantum — simulasi molekul (katalis, baterai, obat) yang tidak bisa disimulasi secara classical.

### 7.5 Quantum Supremacy Timeline

|    Tahun    | Milestone                  | Detail                                                           |
| :---------: | -------------------------- | ---------------------------------------------------------------- |
|    2019     | Google Sycamore (53 qubit) | Random circuit sampling — 200 detik vs 10.000 tahun (diklaim)    |
|    2020     | IBM dispute                | 2,5 hari di Summit supercomputer dengan optimized simulation     |
|    2023     | Xanadu Borealis            | Gaussian boson sampling — 216 squashed mode                      |
|    2024     | Google Willow              | **Below-threshold QEC** — milestone lebih penting dari supremacy |
| 2027 (est.) | Quantum advantage?         | Masalah berguna praktis (simulasi kimia, optimasi)               |

**Quantum advantage** (bermanfaat praktis) → masih belum tercapai. Supremacy menggunakan masalah yang sengaja dibuat untuk menunjukkan kecepatan, bukan masalah berguna.

---

## 8. Pemrograman Quantum

### 8.1 Framework SDK

| Framework      | Vendor    |  Bahasa  |       Paradigma       |       Simulator        | Target Hardware       |
| -------------- | --------- | :------: | :-------------------: | :--------------------: | --------------------- |
| **Qiskit 1.x** | IBM       |  Python  |   Circuit imperatif   | Aer (statevector, GPU) | IBM Quantum           |
| **Cirq**       | Google    |  Python  |     Moment-based      |         Custom         | Sycamore, Willow      |
| **Q#**         | Microsoft | Q# (DSL) | Declarative + adjoint |         Trace          | Azure Quantum         |
| **Braket**     | Amazon    |  Python  |   Provider-agnostic   |        SV1, TN1        | Rigetti, IonQ, D-Wave |
| **Pennylane**  | Xanadu    |  Python  |      Hybrid QML       |     Default.qubit      | Multiple              |

### 8.2 Contoh Program — Shor's Algorithm (Qiskit)

```python
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit.algorithms import Shor
from qiskit.utils import QuantumInstance

# Shor's algorithm built-in
shor = Shor(quantum_instance=QuantumInstance(
    backend=Aer.get_backend('qasm_simulator'),
    shots=1024
))
result = shor.factor(15)  # N=15 → finds p=3, q=5
print(f"Factors: {result.factors}")
```

### 8.3 Tantangan Pemrograman Quantum

| Masalah                   | Akar                          | Solusi                                               |
| ------------------------- | ----------------------------- | ---------------------------------------------------- |
| **No-cloning**            | Teorema Wootters-Zurek (1982) | Error correction via stabilizer codes (bukan backup) |
| **Measurement collapse**  | Born rule                     | Quantum state tomography (banyak sample)             |
| **Error predominance**    | Decohrence ~μs                | Error mitigation (ZNE, Pauli twirling) + QEC         |
| **Non-portability**       | Topologi hardware berbeda     | Transpiler mapping (routing, basis gate)             |
| **Simulation bottleneck** | $2^n$ state complex           | Tensor network simulator (TN1) untuk >50 qubit       |

### 8.4 OpenQASM 3.0

Standar IEEE untuk representasi sirkuit quantum:

```
OPENQASM 3.0;
include "stdgates.inc";

qubit[2] q;
bit[2] c;

h q[0];
cx q[0], q[1];
c = measure q;

if (c[0] == 1) {
    reset q[0];
}
```

---

## 9. Batas Fundamental

### 9.1 BQP (Bounded-error Quantum Polynomial Time)

$$ P \subseteq BQP \subseteq PSPACE $$

$P \neq BQP$? Belum terbukti — tapi semua bukti menunjukkan BQP mengandung masalah yang tidak ada di $P$ (Shor's algorithm).

### 9.2 Apakah BQP = NP?

**Tidak diyakini.** Shor's algorithm tidak menyelesaikan NP-complete. Grover's algorithm memberikan speedup kuadratik — bukan eksponensial — untuk search unstructured. Tidak ada bukti quantum computing bisa menyelesaikan NP-complete dalam polynomial time.

### 9.3 No-cloning Theorem

$$ \nexists U: U(|\psi\rangle \otimes |0\rangle) = |\psi\rangle \otimes |\psi\rangle \quad \forall |\psi\rangle $$

**Konsekuensi:**

- Tidak bisa "backup" qubit — error correction harus menggunakan kode stabilizer
- BB84 quantum key distribution aman: eavesdropper tidak bisa menyalin qubit
- Quantum machine learning tidak bisa "copy data" — butuh pendekatan berbeda

### 9.4 CHSH Game (Bell Inequality)

**Percobaan:** Alice dan Bob masing-masing mendapat bit $x, y$ acak. Mereka harus mengembalikan $a, b$ sehingga $a \oplus b = x \land y$.

|           Strategi           |     Max Win Probability     |
| :--------------------------: | :-------------------------: |
|  Classical (deterministik)   |             75%             |
|    Classical (randomized)    |    75% (Bell's theorem)     |
| **Quantum** (entangled pair) | **~85.4%** ($\cos^2 \pi/8$) |

**Makna:** Quantum correlation > classical correlation. Ini bukan "komunikasi lebih cepat" — probabilitas menang lebih tinggi karena entanglement memberikan korelasi non-klasik.

**Aspect 1982, Hensen 2015:** — eksperimen real mengkonfirmasi Bell violation. Alam memang non-lokal.

---

## 10. Koneksi ke Vault

| Catatan                                  | Hubungan                                                                     |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| [[hierarchy-quantum-cryptography-stack]] | Shor's algorithm break RSA → PQC migration; QKD via BB84                     |
| [[hierarchy-llm-ai-systems]]             | Quantum ML — VQE, quantum kernels, hybrid classical-quantum                  |
| [[hierarchy-compiler-design]]            | Quantum transpiler sebagai compiler — mapping logical→physical qubit         |
| [[hierarchy-failure-modes-resilience]]   | Quantum error correction sebagai contoh fault tolerance di sistem non-klasik |
| [[hierarchy-abstraction-layers]]         | Quantum computing sebagai lapisan baru dalam hierarchy komputasi             |

---

## References

1. Nielsen, M. A. & Chuang, I. L. _"Quantum Computation and Quantum Information."_ 10th anniversary ed., Cambridge University Press, 2010.
2. Preskill, J. _"Quantum Computing in the NISQ Era and Beyond."_ Quantum 2, 79 (2018). arXiv:1801.00862.
3. Arute, F. et al. _"Quantum Supremacy Using a Programmable Superconducting Processor."_ Nature 574, 505–510 (2019). arXiv:1910.11333.
4. Google Quantum AI. _"Quantum Error Correction Below the Surface Code Threshold."_ Nature (Dec 2024). arXiv:2412.04779.
5. Shor, P. W. _"Polynomial-Time Algorithms for Prime Factorization and Discrete Logarithms."_ SIAM J. Comput. 26(5), 1484–1509 (1997).
6. Grover, L. K. _"A Fast Quantum Mechanical Algorithm for Database Search."_ STOC 1996.
7. Kjaergaard, M. et al. _"Superconducting Qubits: Current State of Play."_ Annual Review of Condensed Matter Physics 11, 369–395 (2020). arXiv:1905.13641.
8. Bruzewicz, C. D. et al. _"Trapped-Ion Quantum Computing: Progress and Promise."_ Applied Physics Reviews 6, 021314 (2019). arXiv:1904.04178.
9. DiVincenzo, D. P. _"The Physical Implementation of Quantum Computation."_ Fortschritte der Physik 48(9–11), 771–783 (2000).
10. Kitaev, A. Y. _"Fault-Tolerant Quantum Computation by Anyons."_ Annals of Physics 303(1), 2–30 (2003).
11. Aharonov, D. & Ben-Or, M. _"Fault-Tolerant Quantum Computation with Constant Error Rate."_ SIAM J. Comput. 38(4), 1207–1282 (2008). Earlier in STOC 1997.
12. Fowler, A. G. et al. _"Surface Codes: Towards Practical Large-Scale Quantum Computation."_ Physical Review A 86, 032324 (2012). arXiv:1208.0928.
13. Cross, A. W. et al. _"OpenQASM 3: A Broader and Deeper Quantum Assembly Language."_ ACM Trans. Quantum Comput. 3(3), 1–43 (2022). arXiv:2104.14722.
14. Bravyi, S. et al. _"The Future of Quantum Computing: A View from 2023."_ (Overview of hardware/scalability.)
15. IBM Quantum. _"The IBM Quantum Development Roadmap."_ 2024.
16. Peruzzo, A. et al. _"A Variational Eigenvalue Solver on a Photonic Quantum Processor."_ Nature Communications 5, 4213 (2014).
17. Harrow, A. W. et al. _"Quantum Algorithm for Linear Systems of Equations (HHL)."_ PRL 103, 150502 (2009).
18. Gilyén, A. et al. _"Quantum Singular Value Transformation and Beyond."_ STOC 2019. arXiv:1806.01838.
19. Wootters, W. K. & Zurek, W. H. _"A Single Quantum Cannot Be Cloned."_ Nature 299, 802–803 (1982).
20. Aspect, A. et al. _"Experimental Realization of Einstein-Podolsky-Rosen-Bohm Gedankenexperiment."_ Physical Review Letters 49, 91 (1982).
21. Hensen, B. et al. _"Loophole-Free Bell Inequality Violation Using Electron Spins Separated by 1.3 km."_ Nature 526, 682–686 (2015).
22. Arute, F. et al. _"Is Quantum Computing an Enabling Technology for Artificial General Intelligence?"_ (2024) — quantum AI implications.
