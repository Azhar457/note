---
title: 🔬 Quantum Computing & Cryptography — Deep Dive
tags:
- library
- quantum-crypto
created: '2026-07-02'
updated: '2026-07-06'
status: pending
cssclasses:
  - wide-table
  - callout

source: comprehensive-research
confidence: high
Tingkat kesulitan: advanced
topics: ''
---

# 🔬 Quantum Computing & Cryptography — Deep Dive

> *"If you think you understand quantum mechanics, you don't understand quantum mechanics."* — Richard Feynman  
> *"The only way to prove you understand quantum cryptography is to actually break RSA with a quantum computer."* — Anonymous cryptographer

> [!INFO] 📖 Overview
> **Quantum computing** represents a paradigm shift from classical bits to **qubits** that exploit superposition, entanglement, and interference. This note covers the full spectrum: from qubit fundamentals and quantum gates through Shor's and Grover's algorithms, the **NIST PQC standardization process**, post-quantum cryptographic primitives (CRYSTALS-Kyber, CRYSTALS-Dilithium, FALCON, SPHINCS+), quantum key distribution (BB84, satellite QKD), quantum error correction using surface codes, hardware modalities (superconducting, trapped ion, photonic, topological), the **Y2Q threat timeline**, crypto agility, and migration strategies including hybrid certificates and PQ/TLS. Written in **Bahasa Indonesia campur English** for a bilingual technical audience.

---

## 📋 Daftar Isi

1. [[#1 Qubit Fundamentals — Superposition, Entanglement, Measurement]]
2. [[#2 Quantum Gates — Pauli, Hadamard, CNOT, Toffoli, SWAP]]
3. [[#3 Quantum Circuit dan Quantum State Representation]]
4. [[#4 Shor's Algorithm — RSA/DH/ECDSA Breakdown]]
5. [[#5 Grover's Algorithm — Symmetric Key Speedup]]
6. [[#6 Post-Quantum Cryptography — NIST PQC Overview]]
7. [[#7 CRYSTALS-Kyber — Key Encapsulation Mechanism]]
8. [[#8 CRYSTALS-Dilithium — Digital Signature]]
9. [[#9 FALCON — Fast Fourier Lattice-Based Signature]]
10. [[#10 SPHINCS+ — Stateless Hash-Based Signature]]
11. [[#11 NIST PQC Standardization Timeline]]
12. [[#12 Quantum-Safe Migration — Hybrid Certificates dan PQ/TLS]]
13. [[#13 Quantum Key Distribution (QKD) — BB84 Protocol]]
14. [[#14 Satellite QKD — Micius dan Beyond]]
15. [[#15 Quantum Hardware — Superconducting Qubits]]
16. [[#16 Quantum Hardware — Trapped Ion dan Photonic]]
17. [[#17 Quantum Hardware — Topological Qubits dan Majorana]]
18. [[#18 Quantum Error Correction — Surface Codes]]
19. [[#19 Logical Qubits dan Fault-Tolerant Threshold]]
20. [[#20 Threat Timeline Y2Q — Kapan RSA-2048 Jatuh?]]
21. [[#21 Crypto Agility — Hybrid Key Exchange dan Migration]]
22. [[#22 Quantum Random Number Generators (QRNG)]]
23. [[#23 Quantum-Safe TLS dan Internet Standards]]
24. [[#24 Summary dan Next Steps]]

---

## 1. Qubit Fundamentals — Superposition, Entanglement, Measurement

### 1.1 Konsep Dasar Qubit

Unlike classical bit yang hanya bisa bernilai `0` atau `1`, sebuah **qubit** (quantum bit) bisa berada dalam **superposition** — kombinasi linear dari kedua state:

$$\ket{\psi} = \alpha\ket{0} + \beta\ket{1}$$

di mana $\ket{0}$ dan $\ket{1}$ adalah basis states (biasanya basis Z / computational basis), dan $\alpha, \beta \in \mathbb{C}$ dengan kondisi normalisasi:

$$|\alpha|^2 + |\beta|^2 = 1$$

| Konsep | Analogi Klasik | Penjelasan Quantum |
|--------|---------------|-------------------|
| Bit vs Qubit | 0 atau 1 | 0, 1, atau superposition keduanya sekaligus |
| Measurement | Instant read | Collapse superposition, destroy informasi |
| Gate | AND/OR/NOT | Unitary transformation, reversible |
| Copy | Mudah | **No-Cloning Theorem** — qubit tidak bisa dicopy |

### 1.2 Superposition

Superposition memungkinkan qubit mengeksplorasi banyak jalur komputasi secara simultan. Ini adalah sumber **quantum parallelism**:

$$\ket{\psi} = \frac{1}{\sqrt{2}}(\ket{0} + \ket{1})$$

Setelah Hadamard gate, qubit berada di superposition equal. Ketika diukur, probabilitas 50% untuk $\ket{0}$ dan 50% untuk $\ket{1}$.

> [!WARNING] ⚠️ Measurement Collapse  
> Mengukur qubit **menghancurkan superposition**. Hasil yang didapat adalah `0` atau `1` dengan probabilitas $|\alpha|^2$ atau $|\beta|^2$. Setelah measurement, qubit berada di basis state sesuai hasil measurement — semua informasi tentang fase hilang.

### 1.3 Entanglement

**Entanglement** adalah fenomena quantum di mana dua atau lebih qubit menjadi berkorelasi secara instant — tidak peduli seberapa jauh jarak mereka. Einstein menyebutnya *"spooky action at a distance"*.

$$\ket{\Phi^+} = \frac{1}{\sqrt{2}}(\ket{00} + \ket{11})$$

Pasangan Bell states yang umum:

| Bell State | Formula | Penggunaan |
|-----------|---------|-----------|
| $\ket{\Phi^+}$ | $\frac{1}{\sqrt{2}}(\ket{00} + \ket{11})$ | QKD, teleportation |
| $\ket{\Phi^-}$ | $\frac{1}{\sqrt{2}}(\ket{00} - \ket{11})$ | QKD variant |
| $\ket{\Psi^+}$ | $\frac{1}{\sqrt{2}}(\ket{01} + \ket{10})$ | Superdense coding |
| $\ket{\Psi^-}$ | $\frac{1}{\sqrt{2}}(\ket{01} - \ket{10})$ | Error detection |

Ketika dua qubit entangled, mengukur satu qubit **secara instant** menentukan state qubit lainnya:

```python
# Classical XOR vs Quantum Entanglement
def classical_entangled():
    # Classically correlated, not truly entangled
    import random
    b1 = random.choice([0, 1])
    b2 = b1  # correlated, tapi bukan quantum
    return b1, b2

def quantum_entangled():
    # True Bell state entanglement
    # Setelah CNOT + Hadamard, qubit 0 dan 1:
    # measuring 0 -> instantly know 1
    return "50% (|00⟩ or |11⟩) — instant collapse"
```

### 1.4 Measurement Problem dan Interpretasi

Measurement dalam quantum mechanics masih menjadi topik debat filosofis:

| Interpretasi | Penjelasan | Proponent |
|-------------|-----------|-----------|
| Copenhagen | Collapse terjadi saat observasi | Bohr, Heisenberg |
| Many-Worlds | Semua outcome terjadi — parallel universes | Everett |
| Pilot-Wave | Deterministic dengan hidden variables | de Broglie, Bohm |
| QBism | Informasi subjektif dari agent | Fuchs, Caves |

Untuk tujuan komputasi, **Copenhagen interpretation** paling pragmatis: measurement collapse, get classical output.

---

## 2. Quantum Gates — Pauli, Hadamard, CNOT, Toffoli, SWAP

### 2.1 Families of Quantum Gates

Quantum gates adalah **unitary operators** (memenuhi $U^\dagger U = I$) — artinya semua quantum computing bersifat **reversible** kecuali measurement.

### 2.2 Single-Qubit Gates

| Gate | Matrix | Action | Simbol |
|------|--------|--------|--------|
| **Pauli-X** (NOT) | $\begin{bmatrix}0 & 1 \\ 1 & 0\end{bmatrix}$ | Flip: $\ket{0} \rightarrow \ket{1}$ | ⊕ |
| **Pauli-Y** | $\begin{bmatrix}0 & -i \\ i & 0\end{bmatrix}$ | Bit + phase flip | — |
| **Pauli-Z** | $\begin{bmatrix}1 & 0 \\ 0 & -1\end{bmatrix}$ | Phase flip: $\ket{1} \rightarrow -\ket{1}$ | ⊙ |
| **Hadamard (H)** | $\frac{1}{\sqrt{2}}\begin{bmatrix}1 & 1 \\ 1 & -1\end{bmatrix}$ | Create superposition | H |
| **Phase (S)** | $\begin{bmatrix}1 & 0 \\ 0 & i\end{bmatrix}$ | 90° phase rotation | S |
| **T Gate** | $\begin{bmatrix}1 & 0 \\ 0 & e^{i\pi/4}\end{bmatrix}$ | 45° phase rotation | T |

### 2.3 Multi-Qubit Gates

| Gate | Input → Output | Matrix | Penggunaan |
|------|---------------|--------|-----------|
| **CNOT** | $\ket{AB} \rightarrow \ket{A}\ket{A \oplus B}$ | $4 \times 4$ (controlled-X) | Entanglement generator |
| **Toffoli** (CCNOT) | $\ket{ABC} \rightarrow \ket{AB}\ket{C \oplus (A \land B)}$ | $8 \times 8$ | Universal reversible computing |
| **SWAP** | $\ket{AB} \rightarrow \ket{BA}$ | $4 \times 4$ | Qubit routing |
| **Fredkin** (CSWAP) | Controlled SWAP | $8 \times 8$ | Reversible circuit |

### 2.4 Quantum Gate Decomposition — Universal Gate Sets

Setiap unitary operation bisa didekomposisi menjadi set **universal quantum gates**:

**Universal sets:**
1. `{H, CNOT, T}` — Clifford + T (paling umum untuk fault-tolerant)
2. `{Toffoli}` — single gate universal (tapi praktisnya expensive)
3. `{CNOT, single-qubit rotations}` — untuk NISQ devices

```python
# Quantum Gate Simulation (classical statevector simulator)
import numpy as np

def hadamard(qstate, qubit_idx):
    """Apply Hadamard gate on statevector"""
    H = np.array([[1, 1], [1, -1]]) / np.sqrt(2)
    if qubit_idx == 0:
        full_gate = np.kron(H, np.identity(2))
    else:
        full_gate = np.kron(np.identity(2), H)
    return full_gate @ qstate

def cnot(qstate, control=0, target=1):
    """Apply CNOT gate"""
    CNOT = np.array([
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 0, 1],
        [0, 0, 1, 0]
    ])
    return CNOT @ qstate

# Create Bell state
psi0 = np.array([1, 0, 0, 0])  # |00>
psi = hadamard(psi0, 0)
psi = cnot(psi, 0, 1)
print(f"Bell state: {psi}")  # [1/√2, 0, 0, 1/√2]
```

### 2.5 Gate Fidelity dan Error Rates

| Platform | Single-Qubit Gate Fidelity | Two-Qubit Gate Fidelity |
|----------|---------------------------|------------------------|
| Superconducting (IBM) | 99.9% | 99.0-99.7% |
| Trapped Ion (Quantinuum) | 99.99% | 99.8% |
| Photonic (Xanadu) | 99.0% | 97.0% |
| Neutral Atom (QuEra) | 99.5% | 98.5% |

> [!TIP] 💡 Gate fidelity adalah ukuran seberapa dekat gate actual dengan gate ideal. Dihitung dari **process fidelity** — perbandingan output state aktual vs theoretical.

---

## 3. Quantum Circuit dan Quantum State Representation

### 3.1 Representasi State dalam Komputasi Quantum

Sebuah quantum state dengan $n$ qubit direpresentasikan sebagai vector di **Hilbert space** berdimensi $2^n$:

$$\ket{\psi} = \sum_{i=0}^{2^n-1} c_i \ket{i}$$

di mana $\sum |c_i|^2 = 1$ dan $\ket{i}$ adalah basis computational ($\ket{00...0}$ sampai $\ket{11...1}$).

### 3.2 Quantum Circuit Model

Quantum circuit terdiri dari:
- **Qubit lines** (horizontal lines)
- **Gates** (applied sequentially left-to-right)
- **Measurement** (akhir circuit, collapse ke classical bit)
- **Classical registers** (untuk output)

```
Visual representation (simplified):
   |0⟩ ---H---●---M ⟩ 0
   |0⟩ -----X-----M ⟩ 0
```

### 3.3 Noise Models — Depolarizing, Amplitude Damping

NISQ (Noisy Intermediate-Scale Quantum) devices punya noise signifikan:

| Noise Channel | Effect | Parameter |
|--------------|--------|-----------|
| Depolarizing | Randomly replace state with maximally mixed | Error rate $p$ |
| Amplitude Damping | Energy relaxation ($T_1$ decay) | $T_1$ time |
| Dephasing | Phase randomization ($T_2$ decay) | $T_2$ time |
| Readout Error | Wrong classification saat measurement | Readout fidelity |

Quantum simulations di classical computer **tidak mengalami noise** — salah satu alasan kenapa simulator tidak bisa menggantikan quantum hardware untuk validasi algoritma noise-sensitive.

---

## 4. Shor's Algorithm — RSA/DH/ECDSA Breakdown

### 4.1 Mengapa Shor's Algorithm Revolusioner?

**Shor's Algorithm** (Peter Shor, 1994) adalah algoritma quantum polynomial-time untuk:
1. **Integer factorization** — memecah $n = p \times q$ (basis RSA)
2. **Discrete logarithm** — memecah DH dan ECDSA

### 4.2 Analisis Kompleksitas

| Algoritma | Complexity Klasik | Complexity Quantum |
|-----------|-----------------|-------------------|
| Factor RSA-2048 | ~$10^{15}$ tahun (GNFS) | ~$10^8$ detik (dengan error correction) |
| Discrete Log (256-bit EC) | ~$2^{128}$ | ~$2^{64}$ Grover |
| Goldilocks (448-bit EC) | ~$2^{224}$ | ~$2^{112}$ Grover |

### 4.3 Shor's Algorithm — Langkah-langkah

1. **Reduction**: Cari period dari $f(x) = a^x \mod n$
2. **Quantum Phase Estimation (QPE)**: Gunakan Quantum Fourier Transform (QFT) untuk extract period
3. **Continued Fraction**: Classical post-processing untuk extract $r$ (period)
4. **GCD Calculation**: Dari period $r$, cari faktor nontrivial: $\gcd(a^{r/2} \pm 1, n)$

```python
# High-level pseudocode untuk Shor's Algorithm
def shor_factor(n: int):
    """Find a non-trivial factor of n using Shor's algorithm"""
    assert n % 2 != 0, "n must be odd"
    
    # Step 1: random a < n
    a = random.randint(2, n-1)
    if gcd(a, n) != 1:
        return gcd(a, n)  # lucky
    
    # Step 2: Quantum period finding
    # |0⟩⊗m|0⟩⊗L ─H⊗m─► 1/√(2^m) Σ_x |x⟩ |0⟩
    # ─ Controlled-U^{x} ─► 1/√(2^m) Σ_x |x⟩ |a^x mod n⟩
    # ─ IQFT ─► measure ─► period r
    
    # Step 3: Classical post-processing
    # Measure phase φ ≈ s/r, use continued fraction to find r
    
    # Step 4: Extract factor
    # If r is even and a^(r/2) ≠ ±1 mod n:
    #   factor = gcd(a^(r/2) - 1, n) or gcd(a^(r/2) + 1, n)
    # Else: retry with different a
    
    r = quantum_period_finding(a, n)
    
    if r % 2 == 0 and pow(a, r//2, n) != n-1:
        return gcd(pow(a, r//2, n) - 1, n)
    else:
        return shor_factor(n)  # retry
```

### 4.4 Resource Requirements untuk Memecah RSA-2048

| Resource | Estimasi |
|----------|---------|
| Logical qubits | ~20 million |
| Physical qubits (surface code, d=27) | ~20 billion |
| T gates | ~$4 \times 10^{11}$ |
| Runtime (dengan parallelization) | ~8 jam — 8 hari |
| Magic state factories | Ribuan |

### 4.5 Impact untuk Kriptografi Asymmetric

| Cryptosystem | Key Size Aman Klasik | Key Size Aman Pasca-Quantum |
|-------------|-------------------|---------------------------|
| RSA | 3072-bit | **Broken by Shor** |
| DH | 3072-bit | **Broken by Shor** |
| ECDSA / EdDSA | 256-bit | **Broken by Shor** |
| ECDH (X25519) | 256-bit | **Broken by Shor** |

> [!DANGER] ☢️ Implikasi  
> Semua kriptografi **public-key klasik** (RSA, ECDSA, DH, DSA) akan **runtuh total** ketika quantum computer dengan ~20 juta logical qubits tersedia. Tidak ada peningkatan key size yang bisa menyelamatkan — algoritmanya sendiri yang inherently insecure terhadap Shor.

---

## 5. Grover's Algorithm — Symmetric Key Speedup

### 5.1 Quantum Search — Quadratic Speedup

**Grover's Algorithm** (Lov Grover, 1996) memberikan **quadratic speedup** untuk unstructured search:

$$O(N) \xrightarrow{\text{Grover}} O(\sqrt{N})$$

### 5.2 Implikasi untuk Symmetric Cryptography

| Algoritma | Key Length Klasik | Key Length Pasca-Quantum (Grover) |
|-----------|-----------------|---------------------------------|
| AES-128 | 128-bit (~$2^{128}$) | **~$2^{64}$** — tidak aman |
| AES-192 | 192-bit (~$2^{192}$) | ~$2^{96}$ — masih aman |
| AES-256 | 256-bit (~$2^{256}$) | ~$2^{128}$ — aman |
| SHA-256 (digest) | 256-bit (~$2^{256}$) | **~$2^{128}$** — collision |
| SHA-384 | 384-bit (~$2^{384}$) | ~$2^{192}$ — aman |

### 5.3 Grover's Algorithm Steps

1. **Initialize**: Superposition equal dari semua $N$ states
2. **Oracle**: Mark target state dengan phase flip ($-1$)
3. **Diffusion operator**: Amplify amplitude dari target
4. **Iterate**: Ulangi ~$\pi/4 \sqrt{N}$ kali
5. **Measure**: Collapse ke target dengan probabilitas tinggi

```python
# Grover's Algorithm — Simplified Circuit Logic
def grover_search(N, oracle):
    """
    Find marked element in N items in O(√N) quantum queries.
    
    Args:
        N: Number of items (must be power of 2)
        oracle: Function that returns 1 for target, 0 otherwise
    """
    iterations = int(np.pi/4 * np.sqrt(N))
    
    # Step 1: Uniform superposition
    state = hadamard_on_all(N)
    
    for _ in range(iterations):
        # Step 2: Apply oracle (phase flip target)
        state = phase_oracle(state, oracle)
        # Step 3: Diffusion operator (inversion about mean)
        state = diffusion_operator(state)
    
    return measure(state)
```

### 5.4 Mitigation Strategy

Untuk mitigasi Grover pada symmetric crypto:
- **Gandakan key size**: AES-128 → AES-256 (double key, double cost untuk classical, double cost untuk quantum)
- **Gunakan hash dengan output lebih panjang**: SHA-256 → SHA-384
- **Post-quantum MAC**: Gunakan key panjang (256+ bit) untuk HMAC

---

## 6. Post-Quantum Cryptography — NIST PQC Overview

### 6.1 Definisi dan Scope

**Post-Quantum Cryptography (PQC)** adalah kriptografi yang **running di classical computer** tetapi **aman terhadap quantum attacker**. Beda dengan QKD yang butuh quantum hardware — PQC purely matematis.

### 6.2 Enam Kandidat Terpilih NIST (2022-2024)

| Family | KEM (Key Encapsulation) | Signature | Basis Matematis |
|--------|------------------------|-----------|----------------|
| **CRYSTALS** | **Kyber** 🔒 | **Dilithium** ✍️ | Module Learning With Errors (MLWE) |
| **FALCON** | — | **FALCON** 🦅 | NTRU / Lattice (Gaussian) |
| **SPHINCS+** | — | **SPHINCS+** 🌲 | Stateless Hash-Based |
| **BIKE** | BIKE | — | QC-MDPC Codes |
| **Classic McEliece** | Classic McEliece | — | Goppa Codes |
| **HQC** | HQC | — | Quasi-Cyclic Codes |

### 6.3 Families Matematis

**Lattice-based** (Kyber, Dilithium, FALCON):
- Basis: Learning With Errors (LWE), Module-LWE, NTRU
- Keamanan direduksi ke **shortest vector problem (SVP)** — believed quantum-hard
- Efisien, key size moderate, signatures compact

**Hash-based** (SPHINCS+):
- Basis: Keamanan dari cryptographic hash functions
- Stateless (tidak perlu maintain state)
- Signature besar, tapi proven security

**Code-based** (Classic McEliece, BIKE, HQC):
- Basis: Syndrome decoding — NP-hard problem
- Key size sangat besar (Classic McEliece: ~1MB), BIKE dan HQC lebih kecil
- Security track record panjang (McEliece dari 1978)

---

## 7. CRYSTALS-Kyber — Key Encapsulation Mechanism

### 7.1 Overview

**CRYSTALS-Kyber** (ditulis sebagai **Kyber**) adalah **KEM** (Key Encapsulation Mechanism) yang dipilih NIST untuk standar PQC KEM. Berbasis **Module-LWE** (Learning With Errors) dengan parameter modul $k$ dan modulus $q$.

### 7.2 Parameter Sets

| Parameter | Kyber-512 | Kyber-768 | Kyber-1024 |
|-----------|----------|----------|-----------|
| Security Level | NIST 1 (128-bit) | NIST 3 (192-bit) | NIST 5 (256-bit) |
| $k$ (module rank) | 2 | 3 | 4 |
| $n$ (polynomial degree) | 256 | 256 | 256 |
| $q$ (modulus) | 3329 | 3329 | 3329 |
| Public Key Size | 800 B | 1,184 B | 1,568 B |
| Ciphertext Size | 768 B | 1,088 B | 1,568 B |
| Shared Secret | 256 bit | 256 bit | 256 bit |

### 7.3 Cara Kerja Simplified

```python
# CRYSTALS-Kyber — High-Level (extremely simplified)
class KyberKEM:
    def __init__(self, k=3):  # Kyber-768
        self.k = k
        self.n = 256
        self.q = 3329
    
    def keygen(self):
        """
        Key Generation:
        1. Sample random s (secret) dari small polynomial distribution
        2. Generate public matrix A (uniform random) ∈ R_q^(k×k)
        3. Compute t = A*s + e (where e is small error)
        4. Public key: (t, seed_A), Secret key: s
        """
        A = self.sample_uniform_matrix()
        s = self.sample_small_polynomial()  # secret
        e = self.sample_small_polynomial()  # error
        t = A @ s + e
        return (t, A), s
    
    def encaps(self, pk):
        """
        Encapsulation:
        1. Sample random secret s' and error e', e''
        2. Compute u = A^T * s' + e'
        3. Compute v = t^T * s' + e'' + encode(message)
        4. Hash v → shared secret
        """
        t, A = pk
        s_prime = self.sample_small_polynomial()
        e_prime = self.sample_small_polynomial()
        u = A.T @ s_prime + e_prime
        v = t @ s_prime + ...  # + encoded message
        return (u, v), shared_secret
    
    def decaps(self, sk, ct):
        """Decapsulation — decrypt ciphertext back to shared secret"""
        (u, v) = ct
        s = sk
        # Decrypt: m' = v - u^T * s
        # Then re-encrypt to verify (K-PKE.Encrypt with implicit reject)
        return shared_secret
```

### 7.4 Kelebihan dan Kekurangan

| Aspect | Rating | Notes |
|--------|--------|-------|
| Key size | ✅ Moderat | 800-1568 bytes — acceptable untuk TLS |
| Performance | ✅ Cepat | ~50-100 µs untuk key gen/encap |
| Security | ✅ Proven | Reduction to Module-LWE |
| Maturity | ✅ Standardized | NIST FIPS 203 (draft) |
| Side-channel | ⚠️ Perlu hati-hati | Constant-time implementation critical |

### 7.5 Standardization Code

- **NIST FIPS 203**: ML-KEM (Kyber)
- **IETF**: `X25519Kyber768` hybrid (draft)
- **OQS Provider**: OpenSSL 3 provider hybrid

---

## 8. CRYSTALS-Dilithium — Digital Signature

### 8.1 Overview

**CRYSTALS-Dilithium** adalah **digital signature scheme** berbasis **Module-LWE** — dipilih NIST sebagai primary PQC signature standard.

### 8.2 Parameter Sets

| Parameter | Dilithium-2 | Dilithium-3 | Dilithium-5 |
|-----------|-----------|-----------|-----------|
| Security Level | NIST 2 (128-bit) | NIST 3 (192-bit) | NIST 5 (256-bit) |
| $(k, \ell)$ | $(4, 4)$ | $(5, 5)$ | $(6, 6)$ |
| $q$ | 8,380,417 | 8,380,417 | 8,380,417 |
| Public Key Size | 1,312 B | 1,952 B | 2,592 B |
| Signature Size | 2,420 B | 3,293 B | 4,595 B |
| Signing Speed | 2× ECDSA | 1.5× ECDSA | ~ECDSA |

### 8.3 Fiat-Shamir with Abort

Dilithium menggunakan **Fiat-Shamir transform** dengan **abort** — ciri khas lattice-based signatures:

1. **Commit**: Sample masking $y$, compute $w = Ay$
2. **Challenge**: $c = H(w, msg)$
3. **Response**: $z = y + cs$
4. **Check & Abort**: Jika $z$ terlalu besar → abort dan retry

```python
# Dilithium Signature — Simplified
def dilithium_sign(sk, msg):
    """Fiat-Shamir with Abort signature"""
    A, s1, s2 = sk  # secret: small s1, s2
    k, ell = len(A), len(s1)
    
    while True:
        # Masking
        y = sample_uniform_gamma1()  # large masking value
        w = decompose_polynomial(A @ y, alpha=2*gamma2)
        w1 = high_bits(w)  # keep high bits
        
        # Challenge
        c = shake256_extend(w1, msg)
        
        # Response
        z = y + c * s1
        
        # Abort condition - check infinity norm
        if max_norm_inf(z) > gamma1 - beta:
            continue  # abort, retry
        if max_norm_inf(w - c * s2) > gamma2 - beta:
            continue  # abort, retry
        
        return (c, z)  # signature
    
def dilithium_verify(pk, msg, sig):
    """Verify Fiat-Shamir signature"""
    t1, A = pk  # t1 = high bits of t = As1 + s2
    c, z = sig
    
    # Recompute challenge
    w_prime = high_bits(A @ z - c * t1, alpha=2*gamma2)
    c_prime = shake256_extend(w_prime, msg)
    
    return c == c_prime
```

### 8.4 Standardization

- **NIST FIPS 204**: ML-DSA (Dilithium)
- Kompatibel dengan FIPS 186-5 (EC-DSA) untuk hybrid mode

---

## 9. FALCON — Fast Fourier Lattice-Based Signature

### 9.1 Overview

**FALCON** menggunakan **NTRU lattice** dengan **Gaussian sampling** dan **Fast Fourier Trapping**. Signature compact — terkecil di antara kandidat PQC NIST.

### 9.2 Perbandingan Signature Sizes

| Scheme | Public Key | Signature | Catatan |
|--------|-----------|-----------|---------|
| **FALCON-512** | 897 B | **666 B** | ✅ Tersignature terkecil |
| **FALCON-1024** | 1,793 B | 1,280 B | Untuk level 5 |
| Dilithium-2 | 1,312 B | 2,420 B | Signatures lebih besar |
| SPHINCS+-128s | 32 B | 7,856 B | Signature jauh lebih besar |

### 9.3 NTRU Trapdoor Sampling — Kompleksitas

FALCON men-sampling short vector dari NTRU lattice **tanpa abort** (berbeda dari Fiat-Shamir):

```python
# FALCON signature — conceptually simplified
def falcon_sign(sk, msg):
    """
    Trapdoor Gaussian sampling on NTRU lattice.
    Uses fast Fourier transform (FFT) over polynomial ring.
    """
    f, g, F, G = sk  # NTRU trapdoor basis
    
    # Compute salt + hash
    salt, c = hash_to_point(msg)
    
    # Solve:
    # s1 = r - c*f (mod q)
    # s2 = r - c*g (mod q)
    # where r is sampled using F, G as trapdoor
    
    # Gaussian sampling with FFT-based rejection
    # (much faster than naive lattice sampling)
    
    s1, s2 = ntru_fft_sampling(f, g, F, G, c)
    return (salt, s1_compressed, s2_compressed)
```

### 9.4 Kapan Pakai FALCON vs Dilithium?

| Scenario | Recommended | Reason |
|----------|------------|--------|
| TLS handshake | Kyber + Dilithium | Better ecosystem support |
| Blockchain (small TX) | **FALCON** | Signature size critical |
| Embedded / IoT | **FALCON** | Compact signatures |
| High-throughput server | Dilithium | Faster verification |
| Regulatory compliance | **Keduanya** | NIST supports both |

---

## 10. SPHINCS+ — Stateless Hash-Based Signature

### 10.1 Overview

**SPHINCS+** adalah signature scheme **hash-based** tanpa state. Tidak bergantung pada lattice assumptions — hanya membutuhkan **secure hash function**.

### 10.2 Hyper-Tree Structure

```
SPHINCS+ hierarchy:
        Root PK
           |
    ┌── WOTS+ Tree ──┐  (Few-time signatures)
    │    FORS Tree   │  (Forest of Random Subsets)
    │                 │
   Many WOTS+ trees   │  (Multiple layers, L-trees)
    │                 │
   Leaves = one-time  │  (Each leaf signs exactly once)
    │                 │
   ──── Hyper-tree ───┘  (Multiple levels for many signatures)
```

### 10.3 Parameter Sets

| Parameter | SPHINCS+-128s | SPHINCS+-128f | SPHINCS+-256s |
|-----------|-------------|-------------|-------------|
| Security | NIST 2 (128) | NIST 2 (128) | NIST 5 (256) |
| Signature Size | 7,856 B | 16,960 B | 29,792 B |
| Public Key | 32 B | 32 B | 64 B |
| Private Key | 64 B | 64 B | 128 B |
| Signing Speed | **Slow** (slow mode) | **Fast** (fast mode) | Slow |

### 10.4 Kelebihan

- **Minimal assumptions**: Hanya butuh secure hash — quantum-safe selama hash function aman
- **Proven security**: Conservative security model
- **Stateless**: Tidak perlu state tracking untuk WOTS+ — ideal untuk distributed systems

### 10.5 Kekurangan

- **Signature besar** (~8-30 KB) — bisa jadi masalah untuk bandwidth-limited environments
- **Signing lambat** (terutama slow mode) — butuh banyak iterasi hash
- **Better suited** untuk code signing, firmware updates (low frequency signing)

---

## 11. NIST PQC Standardization Timeline

### 11.1 Timeline Lengkap

| Tahun | Event | Detail |
|-------|-------|--------|
| **2016** | NIST Call for Proposals | PQC standardization dimulai |
| **2017** | Round 1 | 69 submissions (diterima) |
| **2019** | Round 2 | 26 kandidat lanjut |
| **2020** | Round 3 | 15 kandidat finalis + alternates |
| **Jul 2022** | **Round 3 Selection** | **Kyber dan Dilithium** terpilih untuk standardisasi |
| **2023** | Round 4 | BIKE, Classic McEliece, HQC, SIKE (SIKE broken oleh Castryck-Decru) |
| **Aug 2024** | **FIPS 203, 204, 205 Final** | **ML-KEM (Kyber), ML-DSA (Dilithium), SLH-DSA (SPHINCS+)**, FN-DSA (FALCON) di finalize |
| **2025** | FIPS Publication | FIPS 203, 204, 205 resmi diterbitkan |
| **2026+** | Additional Signatures | NIST call for additional signature schemes (beyond lattice) |

### 11.2 SIKE — Ketika Kandidat NIST PQC Dihancurkan

**SIKE** (Supersingular Isogeny Key Encapsulation) adalah kandidat NIST Round 4 yang **dihancurkan total** oleh **Castryck-Decru attack** (2022):

- Attack: Ekstrak secret key dari public key dalam waktu **~1 jam** di single-core
- Implikasi: SIDH/SIKE tidak lagi viable untuk PQC
- **Pelajaran**: Security reduction tidak cukup — cryptanalysis harus diuji dalam praktik

> [!WARNING] ⚠️ Pelajaran dari SIKE  
> Jangan deploy kriptografi baru tanpa bertahun-tahun cryptanalysis publik. SIKE memiliki security proof yang bagus, tetapi implementasi supersingular isogeny memiliki struktur matematis yang bisa dieksploitasi.

### 11.3 Current Standardization Status (Mid-2026)

| Standard | Algorithm | Status |
|----------|----------|--------|
| **FIPS 203** | ML-KEM (Kyber) | ✅ **Published** (2024-08-13) |
| **FIPS 204** | ML-DSA (Dilithium) | ✅ **Published** (2024-08-13) |
| **FIPS 205** | SLH-DSA (SPHINCS+) | ✅ **Published** (2024-10-30) |
| **FIPS 206** | FN-DSA (FALCON) | ✅ **Published** (2025-03) |
| NIST SP 800-227 | Hybrid Schemes | In progress |
| IETF CFRG | X25519Kyber768 | Experimental RFC |

---

## 12. Quantum-Safe Migration — Hybrid Certificates dan PQ/TLS

### 12.1 Strategi Hybrid

**Hybrid approach**: Gunakan **kedua kriptografi** — klasik (ECDH/ECDSA) + PQC (Kyber/Dilithium) — dalam satu session:

```
TLS 1.3 Hybrid Handshake (Conceptual):

ClientHello
  + key_share: [X25519, Kyber-768]
  + signature_algos: [ECDSA, ML-DSA-65]

ServerHello
  + key_share: [X25519, Kyber-768]

Key Schedule:
  shared_secret = HKDF(X25519(ss)) || HKDF(Kyber(ss))
  → combined: attacker must break BOTH to decrypt
```

### 12.2 Hybrid Certificate Chains

```
Hybrid X.509 Certificate Structure:

Subject: example.com
SubjectPublicKeyInfo:
  - algorithm: Composite (OID for hybrid)
  - public_key:
      - X25519 (classical)
      - ML-KEM-768 (post-quantum)

Certificate Signature:
  - signed_with: ECDSA (classical)
  - signed_with: ML-DSA-65 (post-quantum)
```

### 12.3 OQS Provider — OpenSSL 3 Integration

**OpenQuantumSafe (OQS)** menyediakan OpenSSL 3 provider untuk hybrid TLS:

```bash
# Install OQS Provider
git clone https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider
cmake -DOPENSSL_ROOT_DIR=/usr/local/ssl ..
make -j$(nproc)
make install

# Test Kyber + X25519 hybrid
openssl s_server -cert server-cert.pem \
  -groups x25519_kyber768 \
  -provider oqsprovider \
  -provider default
```

### 12.4 Migration Roadmap

| Phase | Timeline | Action |
|-------|----------|--------|
| **Awareness** | Now — 2026 | Inventory crypto inventory systems, identify RSA/DH/ECDSA usage |
| **Hybrid Integration** | 2026 — 2028 | Deploy hybrid certs (X.509 composite), enable PQ/TLS in browsers |
| **Migration** | 2028 — 2032 | Default ke PQC-only, deprecate classical key exchange |
| **Hardening** | 2032+ | Remove classical fallback, PQC-only infrastructure |

---

## 13. Quantum Key Distribution (QKD) — BB84 Protocol

### 13.1 Apa Itu QKD?

**Quantum Key Distribution** menggunakan **foton** untuk mendistribusikan cryptographic key antara dua pihak (Alice dan Bob) dengan **information-theoretic security**. Keamanan dijamin oleh **quantum mechanics** — bukan computational hardness.

### 13.2 BB84 Protocol (Bennett-Brassard 1984)

BB84 adalah protokol QKD pertama dan paling terkenal:

1. **Preparation**: Alice mengirim foton dengan basis acak ($+$ atau $\times$)
2. **Measurement**: Bob mengukur dengan basis acak
3. **Basis Reconciliation**: Alice dan Bob publikkan basis yang dipakai (bukan nilai bit)
4. **Sifting**: Hanya bit dengan basis matching yang dipakai — discard sisanya
5. **Parameter Estimation**: Cek error rate — jika > threshold → eavesdropping detected
6. **Error Correction**: Cascade atau LDPC untuk koreksi error pada sifted key
7. **Privacy Amplification**: Hash function untuk kompres informasi leaked ke Eve

```python
# BB84 Protocol Simulation (Simplified)
import random

def bb84_protocol(n_bits=100):
    """Simulasi BB84 QKD"""
    alice_bits = [random.randint(0, 1) for _ in range(n_bits)]
    alice_bases = [random.choice(['+', 'x']) for _ in range(n_bits)]
    bob_bases = [random.choice(['+', 'x']) for _ in range(n_bits)]
    
    # Bob measurement (simulate photon detection)
    bob_bits = []
    for ab, bb, bit in zip(alice_bases, bob_bases, alice_bits):
        if ab == bb:
            bob_bits.append(bit)  # correct measurement
        else:
            bob_bits.append(random.randint(0, 1))  # random if basis mismatch
    
    # Basis reconciliation (public discussion)
    matching_indices = [i for i in range(n_bits) 
                        if alice_bases[i] == bob_bases[i]]
    
    # Sifted key: matching bits only
    alice_sifted = [alice_bits[i] for i in matching_indices]
    bob_sifted = [bob_bits[i] for i in matching_indices]
    
    # Error estimation (subset)
    sample = random.sample(range(len(alice_sifted)), min(10, len(alice_sifted)))
    qber = sum(alice_sifted[i] != bob_sifted[i] for i in sample) / len(sample)
    
    if qber > 0.11:  # 11% threshold for BB84 with decoy states
        return None, qber  # Eavesdropping detected!
    
    # Error correction + privacy amplification
    final_key = privacy_amplification(
        error_correction(alice_sifted, bob_sifted)
    )
    return final_key, qber
```

### 13.3 Decoy State Protocol

BB84 asli rawan **Photon Number Splitting (PNS) attack** untuk practical photon sources. **Decoy state** (Hwang, 2003; Lo-Ma-Chen, 2005) mengirim foton dengan intensitas berbeda:

- **Signal state**: Intensitas normal (μ)
- **Decoy states**: Intensitas berbeda (v < μ, w, dll.)
- **Vacuum**: No photon

Dengan membandingkan gain dan error rate dari different intensitas, Alice-Bob bisa mendeteksi PNS attack.

### 13.4 QKD Link Budget

| Parameter | Nilai | Catatan |
|-----------|-------|---------|
| Sekret key rate (50 km fiber) | ~1-10 Mbps | State-of-art |
| Sekret key rate (100 km fiber) | ~100 kbps | Harga fiber loss |
| Sekret key rate (satellite-ke-ground) | ~1-10 kbps | Dipengaruhi cuaca |
| Dark count rate | ~10⁻⁶ per gate | Detektor SPAD |
| QBER threshold | ~11% | Decoy BB84 |

---

## 14. Satellite QKD — Micius dan Beyond

### 14.1 Micius Satellite (China)

**Micius** (2016) adalah satelit QKD pertama di dunia:

| Achievement | Detail |
|------------|--------|
| Satelit-ke-ground QKD | Kirim key dari 500 km orbit |
| Intercontinental QKD | China → Austria (7,600 km) |
| Quantum entanglement distribution | 1,200 km (jarak terjauh) |
| Microwave-based QKD | First demonstration |
| Key rate | ~1 kbps dari space-ke-ground |

### 14.2 Arsitektur QKD Satelit

```
          ┌──────────────────────┐
          │   Micius Satellite   │
          │  ┌──────────────┐   │
          │  │ Entangled     │   │
          │  │ Photon Source │   │
          │  └──────┬───────┘   │
          └─────────┼────────────┘
                    │
      ┌─────────────┴─────────────┐
      │                           │
   Ground A                   Ground B
   (Beijing)                  (Vienna)
```

### 14.3 Tantangan Satellite QKD

| Challenge | Issue | Mitigation |
|-----------|-------|-----------|
| Atmospheric turbulence | Beam distortion, phase noise | Adaptive optics |
| Daytime background | Solar noise | Narrow filters, tracking |
| Pointing stability | Micro-vibrations | Active tracking (AOD) |
| Cloud cover | Blocked line-of-sight | Multiple ground stations |
| Key rate | Limited by diffraction | Larger telescope apertures |

### 14.4 Next-Generation Satellite QKD

- **Eagle-1** (ESA, 2024-2025): Low-cost microsat QKD demonstrator
- **QKDSat** (UK): Space-to-ground QKD network
- **QUARC** (Japan): Quantum satellite constellation
- **Klystrone** (USA): Entanglement-based satellite network

---

## 15. Quantum Hardware — Superconducting Qubits

### 15.1 Bagaimana Superconducting Qubit Bekerja

Superconducting qubits adalah **circuit QED** — menggunakan Josephson junction sebagai nonlinear inductor:

```python
# Superconducting qubit Hamiltonian (Transmon)
# H = 4E_c n^2 - E_J cos(φ)
# E_c = charging energy, E_J = Josephson energy
# Ratio E_J/E_c >> 1 → Transmon regime (less sensitive to charge noise)
```

### 15.2 Major Players

| Company | Platform | Qubits (2026) | Rekor |
|---------|----------|--------------|-------|
| **IBM** | Superconducting (Falcon → Condor) | 1,121+ | Condor (1,121 qubit), Heron (133, improved gate) |
| **Google** | Superconducting (Sycamore → Willow) | 105+ (Willow) | Beyond-classical (2019), Willow error correction breakthrough |
| **Rigetti** | Superconducting (Ankaa) | 84-336 | Multi-chip modular |
| **IQM** | Superconducting (Adonis) | 20-54 | Co-design approach |

### 15.3 Google Willow (2024-2025)

Google's **Willow** processor adalah milestone besar:

- 105 qubits dengan **error correction surface code**
- **Below threshold**: Error rate menurun secara eksponensial ketika surface code scale bertambah
- **Beyond 10^6 year computation**: Random circuit sampling dalam ~5 menit — classical Frontier supercomputer dalam 10²⁵ tahun
- **Density and T1**: Qubit dengan coherence time ~100 µs

### 15.4 IBM Quantum Roadmap

| Year | Processor | Key Feature |
|------|-----------|-------------|
| 2023 | Condor (1,121) + Heron (133) | High qubit count + improved gate |
| 2024 | Heron (improved) | 5,000+ 2-qubit gates before error |
| 2025 | Flamingo | Multi-chip QPU interconnect |
| 2026 | — | Parallel multi-QPU, 100+ logical qubits |
| 2027+ | — | ~200 logical qubits, error correction scaling |

---

## 16. Quantum Hardware — Trapped Ion dan Photonic

### 16.1 Trapped Ion — Quantinuum dan IonQ

**Trapped ion** menggunakan ion yang terperangkap di **Paul trap**, dimanipulasi dengan laser:

| Aspect | Karakteristik |
|--------|-------------|
| Gate fidelity | **Tertinggi** — 99.99% single, 99.8% two-qubit |
| Coherence time | Sangat panjang (menit hingga jam) |
| Connectivity | All-to-all (karena ion bisa bergerak) |
| Scalability | Challenging — ion count limited |

**Quantinuum H2**: 56 trapped ion qubits dengan all-to-all connectivity. **IonQ Aria** dan **Forte**: 36 qubit generasi terbaru.

### 16.2 Photonic Quantum Computing — Xanadu dan PsiQuantum

**Photonic** menggunakan photon sebagai qubit:

| Aspect | Karakteristik |
|--------|-------------|
| Qubit implementation | Foton dalam optical waveguide/silicon photonics |
| Temperatur operasi | Room temperature (tapi detektor perlu cryogenic) |
| Entanglement | Berbasis beam splitter dan nonlinear optics |
| Lost mechanism | Photon loss — tantangan terbesar |

### 16.3 Perbandingan Modalitas Hardware

| Parameter | Superconducting | Trapped Ion | Photonic | Neutral Atom |
|-----------|---------------|------------|----------|-------------|
| **Qubit count** | 100+ (1,000+) | 30-60 | 216 (Xanadu) | 256+ (QuEra) |
| **Gate fidelity** | 99.9% | **99.99%** | 99.0% | 99.5% |
| **Coherence time** | ~100 µs | **~10 min** | ~ms | ~1 s |
| **Temperatur** | ~15 mK | Room temp (trap) + laser | Room temp / cryogenic | ~10 µK (laser cooling) |
| **Scalability** | Chip fabrication | Ion transport challenges | Loss scaling | +1D/2D arrays |

---

## 17. Quantum Hardware — Topological Qubits dan Majorana

### 17.1 Konsep Topological Qubits

**Topological qubits** menggunakan **anyons** — quasipartikel dalam 2D — untuk encoding informasi dalam **topological states** yang inherently protected dari noise lokal. Ini adalah holy grail quantum computing:

- **Inherent error protection**: Topological state tidak terpengaruh oleh local perturbations
- **Braid-based operations**: Quantum logic melalui braiding anyons (bukan gate per qubit)

### 17.2 Majorana Zero Modes — Status Terkini

**Majorana zero modes** (MZM) adalah quasipartikel yang identik dengan antipartikelnya (Majorana fermion). Microsoft menghabiskan ~$10B untuk research ini:

| Tahun | Event |
|-------|-------|
| 2018 | Microsoft mengklaim deteksi Majorana (Delft experiment) — kemudian **retracted** |
| 2021 | Nature paper: topological gap protocol — klaim lebih kuat |
| 2023 | Microsoft Mars: 3 topological qubits dengan error rate sangat rendah |
| 2024 | Microsoft melanjutkan — topological qubit array kecil |
| 2025 | Progress pada topological braiding — masih dalam research |

### 17.3 Perbandingan Error Protection

```
Error correction approach:
                          Error Rate
┌──────────────────────────────────────────────┐
│ Superconducting   │ 10⁻² ── surface code ──► │ 10⁻⁶ logical │
│ Trapped ion       │ 10⁻⁴ ── surface code ──► │ 10⁻⁸ logical │
│ Topological (ideal)│ 10⁻⁶ ── (inherent) ──► │ 10⁻⁶ physical │
│ Topological (goal) │ 10⁻⁶ ── minor assist ──► 10⁻¹² logical │
└──────────────────────────────────────────────┘
```

Topological qubit butuh **lebih sedikit error correction** — jika berhasil, mempercepat path ke fault-tolerant quantum oleh faktor ~100-1000×.

---

## 18. Quantum Error Correction — Surface Codes

### 18.1 Kenapa Error Correction Dibutuhkan?

Quantum bits sangat rentan terhadap noise. Tanpa QEC, quantum computation bisa mencapai **maksimal ~1000 gates** sebelum error accumulated menjadi sepenuhnya salah.

### 18.2 Surface Code — Prinsip Kerja

**Surface code** adalah QEC code yang menggunakan grid 2D dari **data qubits** dan **measurement qubits**:

```
Surface Code Layout (d=3):
    ┌───┬───┬───┐
    │ D │ Z │ D │      D = data qubit
    ├───┼───┼───┤      Z = Z-basis stabilizer (measure)
    │ X │ D │ X │      X = X-basis stabilizer (measure)
    ├───┼───┼───┤
    │ D │ Z │ D │
    └───┴───┴───┘

Distance d = 3 → correct (d-1)/2 = 1 error
Physical qubits = (2d-1)² = 25 for d=5
```

| Code Distance (d) | Physical Qubits (2D grid) | Correctable Errors |
|------------------|--------------------------|-------------------|
| 3 | (2×3−1)² = 25 | 1 |
| 5 | (2×5−1)² = 81 | 2 |
| 7 | (2×7−1)² = 169 | 3 |
| 9 | (2×9−1)² = 289 | 4 |
| d | (2d-1)² | $\lfloor (d-1)/2 \rfloor$ |

### 18.3 Google Willow — Below Threshold Milestone

Google Willow (2024) menunjukkan **error suppression** eksponensial:

```
Surface code scaled from d=3 to d=7 on Willow:

d=3:  Logical error ~3×10⁻³ per cycle
d=5:  Logical error ~2×10⁻⁴ per cycle  (15× improvement)
d=7:  Logical error ~3×10⁻⁵ per cycle  (100× from d=3)

→ Below threshold: every increase in code distance
  LOWERs logical error rate
```

### 18.4 Magic State Distillation

**T gates** tidak bisa langsung diimplementasikan fault-tolerantly di surface code. Butuh **magic state distillation**:

```python
# Magic state |A⟩ = |0⟩ + e^(iπ/4)|1⟩
# Kebutuhan resource sangat besar:
# Untuk 10⁹ T gates dengan logical error 10⁻¹²:
#    - Dibutuhkan ~10⁶ magic state factories
#    - Total physical qubits ~20 million untuk RSA-2048
```

---

## 19. Logical Qubits dan Fault-Tolerant Threshold

### 19.1 Definisi Logical vs Physical Qubit

| Konsep | Penjelasan |
|--------|-----------|
| **Physical qubit** | Qubit real di hardware — noisy, short coherence |
| **Logical qubit** | Encoded dalam banyak physical qubits — protected oleh QEC |
| **Overhead** | ~1000 physical qubits / logical qubit (surface code, d=7) |

### 19.2 Fault-Tolerant Threshold Theorem

> **Fault-Tolerant Threshold Theorem**: Jika physical error rate di bawah threshold tertentu, quantum computation bisa dilakukan dengan arbitrary accuracy dengan mengorbankan overhead polynomial.

**Threshold values**:
| Platform | Estimated Threshold |
|----------|-------------------|
| Superconducting (IBM/Google) | ~0.5-1% |
| Trapped ion | ~1-3% |
| Topological | ~10% (theoretical) |

### 19.3 Resource Estimates — Menuju FTQC

| Milestone | Logical Qubits | Physical Qubits | Gate Fidelity | Use Case |
|-----------|---------------|----------------|---------------|----------|
| **NISQ** (<2025) | 0 (no FT) | 50-1,000 | 99-99.9% | Heuristic optimization |
| **Early FT** (2025-2028) | ~10-100 | 10K-100K | 99.99% | QEC demo, chemistry |
| **100 FT qubits** (2028-2030) | ~100 | 100K-1M | 99.99% | Crypto (Shor 2048 masih jauh) |
| **FT Cryptography** (2035+) | ~20M | ~20B | <0.1% | **RSA-2048 factorization** |

---

## 20. Threat Timeline Y2Q — Kapan RSA-2048 Jatuh?

### 20.1 Definisi Y2Q

**Y2Q** (Year to Quantum) adalah titik di mana quantum computer bisa memecah RSA-2048 dalam waktu <24 jam dengan biaya <$1B.

### 20.2 Estimasi Berbagai Lembaga

| Sumber | Estimasi Y2Q | Metodologi |
|--------|-------------|-----------|
| **Global Risk Institute (2024)** | **40-60% kemungkinan 2035** | Expert survey |
| **McKinsey** | 2035-2040 | Technology adoption curve |
| **NSA** | "Significant risk before 2035" | Classified |
| **IBM** | 2030s (extrapolation roadmap) | Hardware roadmap |
| **Google/Willow team** | "Below threshold at 105 qubits" | Experimental (faktor 10⁶ masih perlu) |
| **IT-Harvest (2025)** | 15% chance by 2030, 50% by 2035 | Composite model |

### 20.3 Qubit Requirement untuk RSA-2048

```
RSA-2048 factorization quantum resource roadmap:

Year   Max Logical Qubits    RSA-2048 Possible?
─────────────────────────────────────────────────
2026   ~1-5 (small QEC)      ❌ No
2028   ~10-50                ❌ No  
2030   ~50-200               ❌ No (need 20M)
2032   ~200-1,000            ❌ No
2034   ~1,000-5,000          ❌ Still far
2036   ~5,000-50,000         ❌ Maybe research demo
2038   ~50,000-500,000       ❌ Getting closer
2040   ~500K-5M              ❌ Almost
2042   ~5M-50M               ✅ Probably
```

### 20.4 Risk Assessment oleh NIST dan NSA

| Organization | Stance |
|-------------|--------|
| **NSA** (CNSA 2.0) | "Migrate to PQC by 2035" — CNSA suite 2.0 |
| **NIST** | "Harus mulai migrate sekarang" |
| **CISA** | "Quantum-readiness adalah national security priority" |
| **BSI** (German) | PQC migration timeline 2030+ |

### 20.5 Kapan Grover Threat Terjadi?

Grover's threat berbeda — butuh lebih sedikit qubits tapi butuh **sequential depth**:

| Target | Logical Qubits | Depth (gates) | Timeline |
|--------|---------------|---------------|----------|
| AES-128 brute force | ~4,800 | ~$2^{64}$ | Extremely long — **sequential** depth besar |
| SHA-256 collision | ~10,000 | ~$2^{85}$ | Juga jangka panjang |

> [!TIP] 💡  
> Grover quadratic speedup untuk symmetric crypto bisa dimitigasi dengan double key size (AES-128 → AES-256). Shor polynomial speedup untuk asymmetric crypto **tidak bisa** dimitigasi dengan key size — perlu **migrasi ke PQC**.

---

## 21. Crypto Agility — Hybrid Key Exchange dan Migration

### 21.1 Definisi Crypto Agility

**Crypto agility** adalah kemampuan sistem untuk **mengganti algoritma kriptografi dengan cepat** tanpa perubahan infrastruktur besar. Ini essential untuk era quantum:

### 21.2 Hybrid Key Exchange (HKE)

**IETF draft** untuk hybrid key exchange menggabungkan classical + PQC:

```
HRR: hybrid key_share modes:
  - X25519Kyber768 (ECDH + ML-KEM)
  - P256Kyber768 (ECDH + ML-KEM)
  - X448Dilithium5 (for signatures)

Key Schedule (TLS 1.3 hybrid implementation):
                         ↓
                  Combine(SS1 || SS2)
                         ↓
                  Derive-Secret(...)
                         ↓
               Traffic Secret (hybrid)
```

### 21.3 Signal Protocol (Double Ratchet) — PQC Hybrid

Signal Foundation dan PQShield mengembangkan hybrid untuk Double Ratchet:

```python
# Hybrid Double Ratchet — Concept
class PQDoubleRatchet:
    def __init__(self, sk, pk_pq):
        # Classic: X25519 key agreement
        # PQ: CRYSTALS-Kyber KEM
        self.classic_dh = X25519(sk)
        self.pq_kem = KyberKEM()
        
    def ratchet_step(self, dh_output, pq_ct):
        """
        Hybrid ratchet step:
        1. Classic DH → shared_secret_1
        2. PQ KEM → shared_secret_2
        3. Combine: HKDF(secret_1 || secret_2)
        4. Derive nex root key
        """
        ss_classic = self.classic_dh.dh(dh_output)
        ss_pq = self.pq_kem.decaps(pq_ct)
        combined = hkdf(b"2026:pq-hybrid", ss_classic + ss_pq)
        return combined
```

### 21.4 Migration Steps untuk Enterprise

| Phase | Action | Timeline |
|-------|--------|----------|
| **1. Crypto inventory** | Catalog semua penggunaan RSA/ECDSA, TLS versi | Now |
| **2. PQC-compatible libraries** | Update ke OpenSSL 3 + OQS provider | 2026-2027 |
| **3. Hybrid certificates** | Deploy composite certs (X.509 hybrid) | 2027-2028 |
| **4. Code signature** | PQ + classical dual signing | 2027-2029 |
| **5. Document signature** | PQ signing untuk compliance | 2028-2030 |
| **6. Fallback removal** | Disable classical-only key exchange | 2030-2035 |

### 21.5 Tantangan Crypto Agility

| Challenge | Explanation |
|-----------|------------|
| **Performance overhead** | PQ signatures ~1-3 KB (vs ECDSA 64-72 B) |
| **Protocol ossification** | TLS, SSH, IKE sudah rigid — update spec butuh tahunan |
| **Side-channel resistance** | PQ implementations baru — belum mature constant-time |
| **Key size explosion** | Kyber PK ~1.2 KB, McEliece ~1 MB |
| **Network packet size** | TCP MSS, DNS, cert chain size — bisa fragment |

---

## 22. Quantum Random Number Generators (QRNG)

### 22.1 Mengapa QRNG?

RNG adalah fondasi keamanan kriptografi. **Quantum RNG** menggunakan quantum processes yang **intrinsically random** (berbeda dari classical PRNG yang deterministic).

### 22.2 QRNG Mechanisms

| Method | Process | Rate |
|--------|---------|------|
| **Beam splitter** | Photon path superposition | Mbps |
| **Phase noise** | Vacuum fluctuation sampling | Gbps |
| **Shot noise** | Photon counting statistics | Gbps |
| **Spontaneous** | Parametric down-conversion | Mbps |

### 22.3 Commercial QRNG Chips

| Company | Product | Speed | Size | Price |
|---------|---------|-------|------|-------|
| **ID Quantique** | Quantis | 16-64 Mbps | PCIe/USB | ~$1K-5K |
| **QuNu Labs** | QRNG chip | 1+ Gbps | Chip-scale | OEM |
| **IBM** | Quantum safe credential | N/A | Server-grade | Integrated |
| **Cambridge Quantum** | QRNG via TKET | N/A | Cloud | API |

---

## 23. Quantum-Safe TLS dan Internet Standards

### 23.1 IETF Quantum-Safe WG

**IETF** memiliki working groups aktif untuk PQC integration:

| Draft | Status | Detail |
|-------|--------|--------|
| **draft-ietf-tls-hybrid-design** | Active | TLS hybrid key exchange spec |
| **draft-ietf-tls-hybrid-kem** | Active | KEM-based hybrid in TLS |
| **draft-ietf-lamps-pq-composite-keys** | Active | X.509 PQ composite certs |
| **draft-ietf-ipsecme-qss** | Active | Quantum-safe IKEv2 |
| **draft-ietf-openpgp-pqc** | Active | OpenPGP PQC integration |
| **draft-jose-cose-pqc** | Active | COSE/JOSE PQC |

### 23.2 Browser PQ/TLS Support (2026)

| Browser | PQ/TLS Status |
|---------|---------------|
| **Chrome** | ✅ X25519Kyber768 sejak Chrome 116 (2023) |
| **Firefox** | ✅ X25519Kyber768 di eval — shipping in 127+ (2024) |
| **Safari** | ❌ Belum PQ — Apple intelligence? |
| **Edge** | ✅ Juga Chrome-based (X25519Kyber768) |
| **Curl** | ✅ OQS provider support |
| **OpenSSH** | ⚠️ Hybrid KEM draft — belum standard |

### 23.3 Post-Quantum VPN

```yaml
# WireGuard + PQC — Conceptual Hybrid
[Interface]
PrivateKey = <X25519>
PQPrivateKey = <ML-KEM-768>

[Peer]
PublicKey = <X25519 peer>
PQPublicKey = <ML-KEM-768 peer>
PresharedKey = <combined_psh>
AllowedIPs = 10.0.0.0/24
```

---

## 24. Summary dan Next Steps

### 24.1 Key Takeaways

1. **Shor's algorithm** akan **memecah RSA, ECDSA, DH** seketika — tidak ada mitigasi key size
2. **NIST PQC standards** sudah final (FIPS 203/204/205/206) — Kyber, Dilithium, SPHINCS+, FALCON
3. **Hybrid approach** (classical + PQC) adalah strategi migrasi paling aman
4. **Y2Q timeline**: 50% chance RSA-2048 jatuh antara 2035-2040
5. **Crypto agility** harus dimulai sekarang — inventory, hybrid certs, PQ/TLS
6. **QKD** melengkapi PQC untuk distribusi key information-theoretic — tapi bukan replacement untuk PKI
7. **Quantum error correction** sudah below threshold (Google Willow 2024) — jalan menuju FTQC terbuka

### 24.2 Recommended Reading

- [[comprehensive-threat-directory]] — Threat modeling untuk quantum era
- [[math-and-algorithms]] — Mathematical foundations of lattice cryptography
- [[military-sigint-deepdive]] — SIGINT implications of cryptanalysis
- [[hierarchy-ai-levels]] — AI + quantum convergence

### 24.3 Watch List

```python
# Y2Q watch items — track these milestones
watch_items = {
    "logical_qubits": [
        ("100 logical qubits", "Quantum chemical simulation viable"),
        ("1,000 logical qubits", "Small optimization problems"),
        ("20,000 logical qubits", "RSA-2048 research demo"),
        ("20,000,000 logical qubits", "RSA-2048 practical break"),
    ],
    "crypto_migration": [
        ("2026-2027", "X25519Kyber768 standard browser deployment"),
        ("2028", "CNSA 2.0 compliance deadline (US gov)"),
        ("2030", "European quantum-safe mandate"),
        ("2035", "Full PQC migration target")
    ],
    "error_correction": [
        ("QEC below threshold", "✅ ACHIEVED (Google Willow 2024)"),
        ("10 logical qubits", "2025-2026"),
        ("100 logical qubits", "2028-2030"),
    ]
}
```

### 24.4 Tools dan References

| Sumber | Link | Type |
|--------|------|------|
| NIST FIPS 203 | https://csrc.nist.gov/pubs/fips/203/final | Standard |
| OpenQuantumSafe | https://openquantumsafe.org/ | Library |
| Quantum Algorithm Zoo | https://quantumalgorithmzoo.org/ | Reference |
| NIST PQC Portal | https://csrc.nist.gov/projects/post-quantum-cryptography | Portal |
| Qiskit Textbook | https://qiskit.org/textbook/ | Tutorial |

---

> [!QUOTE] 📝 Catatan Akhir  
> *"The quantum threat is not a question of 'if' but 'when'. Cryptography must be quantum-ready before the first RSA-breaking computer is built — not after."*  
> — ***Vault 801 — Deep Note Catalogus, 2026-07-02***
---

audited
---
