---
title: 'Quantum Error Correction: Surface Code & Threshold'
tags:
- quantum-error-correction
- quantum-computing
- surface-code
- cryptography
aliases:
- QEC
- Surface Code
- Threshold Theorem
- Quantum Error Correction
status: pending
created: 2026-08-04
updated: 2026-08-04
cssclasses:
- wide-table
verification:
  status: unverified
  last_checked: '2026-08-12'
  confidence: LOW
---

> [!abstract]
> Catatan mendalam tentang **Quantum Error Correction (QEC)** — fondasi yang menjaga quantum computer tetap bisa berkomputasi hadapi noise pada physical qubits. Mencakup Shor code, Steane code, surface code, threshold theorem, overhead logical-per-physical qubit, serta eksperimen terbaru Google dan IBM. Vault sudah punya [[quantum-cryptography-primer]], [[post-quantum-tls]], dan [[pqc-implementation-rust]] — catatan ini melengkapi dengan layer fundamental *mengapa* quantum computer belum bisa menghancurkan RSA.

## Daftar Isi
1. [[#1. Masalah: Noise pada Physical Qubit]]
2. [[#2. Prinsip QEC: Redundansi & Entanglement]]
3. [[#3. Stabilizer Codes: Shor & Steane Code]]
4. [[#4. Surface Code: Arsitektur 2D]]
5. [[#5. Threshold Theorem]]
6. [[#6. Logical vs Physical Qubits & Overhead]]
7. [[#7. Fault-Tolerant Quantum Computation]]
8. [[#8. Eksperimen Terbaru: Google & IBM]]
9. [[#9. Koneksi ke Kriptografi: Mengapa Ini Bottleneck]]
10. [[#References]]
11. [[#Koneksi ke Vault]]

## 1. Masalah: Noise pada Physical Qubit

Quantum computer membangun superposition dari **qubit** — unit dasar quantum information. Masalahnya, qubit sangat rapuh: interaksi dengan lingkungan (decoherence) menyebabkan error pada state quantum dalam skala mikrodetik.

| Sumber Noise | Deskripsi | Skala Waktu |
|:-------------|:----------|:------------|
| T1 (amplitude damping) | Relaxation ke ground state | 10-100 μs |
| T2 (dephasing) | Fase qubit tidak koheren | 1-50 μs |
| Gate error | Kesalahan saat operasi qubit | 10^-2 to 10^-4 |
| Measurement error | Kesalahan baca | 10^-2 to 10^-3 |
| Crosstalk | Interaksi antar qubit tak diinginkan | Konstan |

Tanpa QEC, error accumulation membuat hasil perhitungan quantum jadi kacau bahkan untuk algorithm sederhana.

## 2. Prinsip QEC: Redundansi & Entanglement

Kontras penting dengan classical error correction: **quantum tidak bisa di-clone** (no-cloning theorem). Tidak mungkin menyalin qubit `|ψ⟩` menjadi `|ψ⟩|ψ⟩` untuk redundancy musikal. QEC harus menggunakan **entanglement** — mengkodekan logical state di distributed entanglement banyak physical qubits.

QEC bekerja melalui:
1. **Encode logical qubit** ke dalam banyak physical qubits
2. **Syndrome measurement**: mengukur error indicators tanpa menghentikan superposition
3. **Recovery**: fix error berdasarkan syndrome tanpa collapse logical state

## 3. Stabilizer Codes: Shor & Steane Code

**Stabilizer codes** adalah keluarga kode QEC yang menggunakan stabilizer group — set operators yang mengembalikan logical state ke dirinya sendiri.

### Shor Code (9-qubit, 1995)
Kode pertama yang dibuktikan (Shor, 1995) bisa mengoreksi semua jenis error (bit flip, phase flip, combination) dari satu physical qubit:

```
1 logical qubit → 9 physical qubits
Concat: phase flip code (3x) + bit flip code (3x per group)
```

### Steane Code (7-qubit, 1996)
Kode CSS (Calderbank-Shor-Steane) 7-qubit dengan properti better: bisa koreksi 1 error, dan **transversal** gates (fault-tolerant):

```
1 logical qubit → 7 physical qubits
Classical Hamming [7,4,3] code modifikasi
Steane code punya transversal CNOT, X, Z gates
```

| Code | Physical Qubits | Distance | Errors Corrected | Transversal |
|:-----|:---------------:|:--------:|:----------------:|:-----------:|
| Shor [9,1,3] | 9 | 3 | 1 (any type) | Partial |
| Steane [[7,1,3]] | 7 | 3 | 1 (any type) | CNOT, X, Z |
| Surface [d] | d² | d | ⌊(d-1)/2⌋ | Gates via braiding |

## 4. Surface Code: Arsitektur 2D

**Surface code** (Kitaev, 1997; Freedman-Meyer-Luo, 2002) adalah QEC code paling menjanjikan untuk hardware saat ini karena:
- **Nearest-neighbor interactions**: hanya butuh tetangga dekat (2D lattice) — cocok untuk chip superconductor
- **Threshold tinggi**: ~1% physical error rate (vs ~0.001% stabilizer code klasik)
- **Scalable**: logical qubit size bertambah dengan d² physical qubits (distance d)

Struktur surface code:
```
data qubits    ──●──●──●──
                │  │  │  │
sydrome X      ───■──X──■──
                │  │  │  │
data qubits    ──●──●──●──
                │  │  │  │
sydrome Z      ───■──Z──■──
```

Surface code menyimpan informasi secara *topological* — error yang membentuk loop tertutup tidak merusak logical state. Ini yang membuatnya robust.

## 5. Threshold Theorem

**Threshold theorem** (Aliferis-Āḷ, Knill, Preskill) menyatakan: jika error rate per gate berada di bawah threshold, maka apa pun besarnya komputasi bisa dijalankan dengan fault tolerance.

```
Kesalahan       Fault-tolerant  Error
per gate   →    dengan        →   dapat
di bawah        overhead       ditekan
threshold       polinomial     eksponensial
```

| Physical Error Rate | Logical Error After QEC | Practical |
|:--------------------|:------------------------|:----------|
| 1% (surface threshold) | Tekan ke 10^-10+ | Realistic scalable |
| 0.1% | Jauh di bawah threshold | Comfortable |
| 10% | Di atas threshold | QEC gak membantu |
| 0.001% | Sangat nyaman | Stabilizer code pra-tesa |

**Threshold surface code ~1%**: physical gate error rate harus di bawah ~1% agar QEC bekerja. Hardware modern (Google, IBM) sudah mencapai 0.1-0.3% gate error.

## 6. Logical vs Physical Qubits & Overhead

**Physical qubit**: qubit hardware nyata (transmon, trapped ion, etc) — noisy.
**Logical qubit**: qubit yang dikodekan oleh QEC — hampir sempurna.

Overhead sangat besar:

| Operation | Physical Qubits Needed |
|:----------|:----------------------:|
| 1 logical qubit (distance 7) | ~49 physical |
| 1 logical qubit (distance 13) | ~169 physical |
| Run Shor's algorithm (2048-bit RSA) | ~20 juta noisy physical |
| Run Shor's algorithm + QEC | ~[millions] physical |
| Run 1 quantum chemistry calc | ~100-1000 logical |
| Run 1 quantum chemistry calc + QEC | ~100k-1M physical |

**Gidney-Ekerå (2021, arXiv:1905.09749)**: memecahkan RSA-2048 butuh ~20 juta noisy physical qubits atau ~thousands logical qubits dengan QEC, berjalan ~8 jam. Ini sebabnya quantum computer belum mengancam RSA — overhead-nya terlalu besar untuk hardware saat ini (terbaru ~1,000 qubits).

## 7. Fault-Tolerant Quantum Computation

QEC saja tidak cukup — error bisa terjadi **selama operasi koreksi** itu sendiri. Fault-tolerant computation dibutuhkan untuk menjamin error dalam sindrom tidak merusak logical state. Konsep kunci:

- **Transversal gates**: operasi per-qubit yang tidak menyebarkan error antar qubit dalam satu code block
- **Fault-tolerant syndrome extraction**: mengukur sindrom tanpa membocorkan logical state
- **Concatenation**: stacking code (kode di kode) untuk error rate lebih rendah

## 8. Eksperimen Terbaru: Google & IBM

### Google Quantum AI — "Below the Surface Code Threshold" (2024)
Paper **Anderson et al., arXiv:2408.13687** (Bukan 2308.15507 yang ternyata medical imaging) melaporkan breaakthrough: error rate per round turun ke bawah threshold surface code. Menggunakan 72-qubit Willow chip.

### IBM Quantum
IBM merilis roadmap "IBM Quantum System Two" dengan roadmap logical qubits — target 2029: 1,000+ logical qubits dengan QEC. IBM mengklaim error suppression eksponensial dengan distance scaling.

| Eksperimen | Tahun | Qubits | Hasil |
|:-----------|:------|:------:|:------|
| Google Sycamore | 2020 | 54 | Quantum supremacy (noise-limited) |
| Google Willow | 2024 | 105 | Below surface code threshold |
| Google Willow | 2025 | 105 | 6x faster quantum error suppression |
| IBM System Two | 2024 | 1,121 | 156-mode hardware roadmap |
| Quantinuum H2 | 2024 | 56 | Trapped ion dengan logical qubit |

## 9. Koneksi ke Kriptografi: Mengapa Ini Bottleneck

Ini penting untuk [[post-quantum-tls]] dan [[pqc-implementation-rust]]:

- **Shor's algorithm** bisa memecahkan RSA/ECC *jika* quantum computer cukup besar
- Tapi kebutuhan physical qubits untuk RSA-2048 (digunakan oleh TLS) ~20 juta qubits dengan QEC
- Hardware saat ini: Google Willow 105 qubits, IBM System Two 1,121 qubits — **jauh dari 20 juta**
- Dengan kata lain: **RSA masih aman dari quantum attack setidaknya 10-20 tahun ke depan**
- PQC (post-quantum cryptography) adalah persiapan proaktif, bukan respons terhadap ancaman langsung

## References

1. Shor, P. (1995). "Scheme for reducing decoherence in quantum computer memory." *Phys. Rev. A* — arXiv:quant-ph/9507018
2. Steane, A. (1996). "Error correcting codes in quantum theory." — arXiv:quant-ph/9601029
3. Calderbank, A.R. & Shor, P. (1996). "Good quantum error correcting codes exist." — arXiv:quant-ph/9512032
4. Kitaev, A.Y. (1997). "Fault-tolerant quantum computation by anyons." — arXiv:quant-ph/9707021
5. Fowler, A.G. et al. (2012). "Surface codes: Towards practical large-scale quantum computation." — arXiv:1208.0928
6. Dennis, E. et al. (2002). "Topological quantum memory." — arXiv:quant-ph/0110143
7. Gidney, C. & Ekerå, M. (2019). "How to factor 2048 bit RSA integers in 8 hours using 20 million noisy qubits." — arXiv:1905.09749
8. Anderson et al. (2024). "Quantum error correction below the surface code threshold." — arXiv:2408.13687
9. Preskill, J. (1998). "Fault-tolerant quantum computation." — arXiv:quant-ph/9712048
10. Google Quantum AI Blog: https://blog.google/technology/research/google-willow-quantum-chip/
11. Wikipedia: [Quantum error correction](https://en.wikipedia.org/wiki/Quantum_error_correction)
12. Wikipedia: [Surface code](https://en.wikipedia.org/wiki/Surface_code)

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[quantum-cryptography-primer]] | Fondasi quantum computing → memahami QEC |
| [[post-quantum-tls]] | PQC migration — kenapa RSA masih aman (overhead qubit) |
| [[pqc-implementation-rust]] | Implementasi PQC di Rust — konteks real threat |
| [[hierarchy-quantum-cryptography-stack]] | Atlas stack quantum cryptography |
| [[quantum-cryptography-deepdive]] | Teori quantum cryptography |
| [[quantum-machine-learning2]] | Qubit di ML — noise sensitivity |

## 🔍 Verification Report
> [!NOTE]
> **Last Evaluated:** 2026-08-12 20:13
> **Overall Epistemic Status:** **`UNVERIFIED`**

### ❔ Claim 1: Shor code uses 9 physical qubits to encode 1 logical qubit and can correct all types of single physical qubit errors.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 2: Steane code is a 7-qubit CSS code that can correct 1 error and supports transversal CNOT, X, and Z gates.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 3: Surface code requires dÂ² physical qubits to achieve a code distance of d.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.
