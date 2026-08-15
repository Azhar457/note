---
title: "Quantum Cryptography Learning Roadmap — From Qubits to BB84 Protocol Simulation"
tags:
  - quantum-cryptography
  - quantum-computing
  - cryptography
  - qiskit
  - physics
  - roadmap
  - qkd
  - pqc
created: 2026-07-19
updated: 2026-08-15
status: pending
cssclasses:
  - wide-table
  
  - code-wrap
---

# 🔐 QUANTUM CRYPTOGRAPHY ROADMAP — Dari Qubit ke Kunci yang Tidak Bisa Dipecahkan

**Qubit · No-Cloning · BB84 · PQC Migration · Qiskit Simulation · Quantum-Safe TLS**

> [!abstract] Paradigma Keamanan Baru
> Kriptografi kuantum bukanlah "kriptografi yang dijalankan di komputer kuantum." Ia adalah **pergeseran paradigma fundamental** — dari keamanan berbasis kompleksitas matematika (RSA, ECC) menuju keamanan berbasis **hukum fisika**. Komputer kuantum tidak hanya mengancam RSA; mereka juga memungkinkan protokol distribusi kunci yang **aman secara informasi** — aman bahkan terhadap musuh dengan daya komputasi tak terbatas. Catatan ini adalah peta jalan terstruktur: dari representasi qubit dan notasi Dirac, melalui protokol BB84 dan deteksi penyadapan, menuju simulasi praktis dengan Qiskit, dan diakhiri dengan transisi ke Post-Quantum Cryptography (PQC). Ini adalah fondasi untuk memahami mengapa quantum internet berbeda dari internet klasik, dan bagaimana kita bersiap menghadapi era Q-Day.

---

## Daftar Isi

1. [[#1. Kurikulum Belajar 4 Fase — Arsitektur Pembelajaran]]
2. [[#2. Fase 1 — Mekanika Kuantum Dasar & Representasi Qubit]]
3. [[#3. Fase 2 — Protokol QKD (Quantum Key Distribution) BB84]]
4. [[#4. Fase 3 — Transisi Kriptografi Pasca-Kuantum (PQC)]]
5. [[#5. Fase 4 — Hands-on Simulasi BB84 Menggunakan Qiskit]]
6. [[#6. Kumpulan Soal Latihan & Solusi]]
7. [[#7. Quantum Cryptography vs Post-Quantum Cryptography — Perbandingan Fundamental]]
8. [[#8. Implementasi Praktis — BB84 dengan Deteksi Penyadapan]]
9. [[#9. Eksperimen dan Implementasi Nyata]]
10. [[#10. Open Problems dan Frontier]]
11. [[#11. References]]
12. [[#12. Koneksi ke Vault]]

---

## 1. Kurikulum Belajar 4 Fase — Arsitektur Pembelajaran

Peta jalan ini dirancang sebagai **scaffolding kognitif** — membangun dari abstraksi matematis ke implementasi konkret:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ROADMAP QUANTUM CRYPTOGRAPHY                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  │    FASE 1         │    │    FASE 2         │    │    FASE 3         │    │    FASE 4         │
│  │  Qubit & Math     │───►│   QKD BB84       │───►│  PQC Migration   │───►│  Qiskit Sim      │
│  │                   │    │                   │    │                   │    │                   │
│  │ • Superposisi     │    │ • No-Cloning      │    │ • NIST Standards │    │ • Gerbang X, H   │
│  │ • Entanglement    │    │ • Polarization    │    │ • ML-KEM/ML-DSA  │    │ • Simulasi BB84  │
│  │ • Dirac Bra-Ket   │    │ • Eve Detection   │    │ • Hybrid Certs   │    │ • Qubit Measure  │
│  │ • Bloch Sphere    │    │ • Sifting         │    │ • Migration Path │    │ • Error Analysis │
│  └──────────────────┘    └──────────────────┘    └──────────────────┘    └──────────────────┘
│                                                                              │
│  PRASYARAT: Aljabar Linear, Probabilitas Dasar, Python                       │
│  OUTPUT: Memahami QKD, mampu simulasi BB84, paham transisi PQC              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Fase 1 — Mekanika Kuantum Dasar & Representasi Qubit

### 2.1 Qubit — Unit Informasi Quantum

**Qubit** adalah unit dasar informasi kuantum. Berbeda dengan bit klasik yang bernilai 0 atau 1, qubit berada dalam **superposisi linier**:

$$|\psi\rangle = \alpha|0\rangle + \beta|1\rangle$$

Dengan:
- $\alpha, \beta \in \mathbb{C}$ (bilangan kompleks)
- $|\alpha|^2 + |\beta|^2 = 1$ (syarat normalisasi)
- $|\alpha|^2$ = probabilitas mengukur |0⟩
- $|\beta|^2$ = probabilitas mengukur |1⟩

**Representasi Matriks:**
$$|0\rangle = \begin{bmatrix} 1 \\ 0 \end{bmatrix}, \quad |1\rangle = \begin{bmatrix} 0 \\ 1 \end{bmatrix}$$

### 2.2 Notasi Dirac — Bahasa Matematis Quantum

| Notasi | Nama | Fungsi |
|:-------|:-----|:-------|
| $\langle \psi |$ | Bra | Vektor baris (dual) — $\langle \psi | = |\psi\rangle^\dagger$ |
| $| \psi \rangle$ | Ket | Vektor kolom (state) |
| $\langle \phi | \psi \rangle$ | Bra-Ket | Inner product — amplitudo transisi |
| $| \phi \rangle \langle \psi |$ | Outer product | Operator proyeksi |
| $| \psi \rangle \otimes | \phi \rangle$ | Tensor | State gabungan multi-qubit |

**Contoh Inner Product:**
$$\langle 0 | 1 \rangle = 0, \quad \langle 0 | 0 \rangle = 1, \quad \langle 1 | 1 \rangle = 1$$

### 2.3 Bloch Sphere — Visualisasi Qubit

Setiap qubit dapat direpresentasikan sebagai titik pada **Bloch sphere** (bola unit 3D):

$$|\psi\rangle = \cos(\theta/2)|0\rangle + e^{i\phi}\sin(\theta/2)|1\rangle$$

```
                 |0⟩ (puncak)
                    ▲
                   /|\
                  / | \
                 /  |  \
                /   |   \
               /    |    \
              /  θ  |     \
             /      |      \
            /       |       \
    |1⟩ ──►●────────┼────────●──► |0⟩ + |1⟩
            \       |       /
             \      |      /
              \  φ  |     /
               \    |    /
                \   |   /
                 \  |  /
                  \ | /
                   \|/
                    ▼
                |0⟩ - |1⟩ (dasar)
```

- $\theta$: sudut polar (0 = |0⟩, π = |1⟩)
- $\phi$: sudut azimut (fase relatif)

**Titik Penting:**
- |0⟩ dan |1⟩ berada di kutub utara-selatan (basis Z)
- |+⟩ = (|0⟩+|1⟩)/√2 dan |-⟩ = (|0⟩-|1⟩)/√2 berada di ekuator (basis X)
- Rotasi di Bloch sphere = gerbang kuantum

### 2.4 Gerbang Kuantum Dasar untuk Kriptografi

| Gerbang | Matriks | Efek pada Qubit | Peran di QKD |
|:--------|:--------|:----------------|:-------------|
| **X (NOT)** | $\begin{bmatrix}0 & 1 \\ 1 & 0\end{bmatrix}$ | $X|0\rangle = |1\rangle, X|1\rangle = |0\rangle$ | Membuat bit flip |
| **H (Hadamard)** | $\frac{1}{\sqrt{2}}\begin{bmatrix}1 & 1 \\ 1 & -1\end{bmatrix}$ | $H|0\rangle = |+\rangle, H|1\rangle = |-\rangle$ | **Basis switching** (rektilinear ↔ diagonal) |
| **Z (Phase)** | $\begin{bmatrix}1 & 0 \\ 0 & -1\end{bmatrix}$ | $Z|1\rangle = -|1\rangle$ | Phase flip |
| **CNOT** | $\begin{bmatrix}1&0&0&0\\0&1&0&0\\0&0&0&1\\0&0&1&0\end{bmatrix}$ | Entanglement: $CNOT|a,b\rangle = |a, a \oplus b\rangle$ | Dasar untuk quantum teleportation |

### 2.5 Entanglement — Korelasi Non-Klasik

**Entanglement** adalah fenomena di mana dua atau lebih qubit menjadi terkorelasi sedemikian rupa sehingga state sistem tidak dapat difaktorkan:

$$|\psi\rangle_{\text{entangled}} \neq |\psi_A\rangle \otimes |\psi_B\rangle$$

**Bell States (Maximally Entangled):**
$$|\Phi^+\rangle = \frac{|00\rangle + |11\rangle}{\sqrt{2}}, \quad |\Phi^-\rangle = \frac{|00\rangle - |11\rangle}{\sqrt{2}}$$
$$|\Psi^+\rangle = \frac{|01\rangle + |10\rangle}{\sqrt{2}}, \quad |\Psi^-\rangle = \frac{|01\rangle - |10\rangle}{\sqrt{2}}$$

**Peran dalam Kriptografi:**
- **Eve detection:** Jika Eve mengukur satu qubit dari pasangan entangled, state pasangannya langsung berubah (collapse) — deteksi instan.
- **Quantum Teleportation:** Memindahkan state kuantum tanpa mengirim qubit secara fisik.
- **Entanglement-based QKD:** Protokol seperti E91 (Ekert, 1991) menggunakan entanglement untuk distribusi kunci.

---

## 3. Fase 2 — Protokol QKD (Quantum Key Distribution) BB84

### 3.1 No-Cloning Theorem — Fondasi Keamanan

**No-Cloning Theorem** (Wootters & Zurek, 1982):

>Tidak ada operasi unitaris $U$ yang dapat menduplikasi state kuantum sembarang: $U(|\psi\rangle \otimes |0\rangle) \neq |\psi\rangle \otimes |\psi\rangle$ untuk semua $|\psi\rangle$.

**Bukti Sederhana:**
Andaikan ada $U$ yang meng-clone $|\psi\rangle$ dan $|\phi\rangle$:
$$U|\psi\rangle|0\rangle = |\psi\rangle|\psi\rangle, \quad U|\phi\rangle|0\rangle = |\phi\rangle|\phi\rangle$$

Inner product kedua persamaan:
$$\langle \psi | \phi \rangle = (\langle \psi | \phi \rangle)^2 \implies \langle \psi | \phi \rangle \in \{0, 1\}$$

Ini hanya benar jika $|\psi\rangle = |\phi\rangle$ atau ortogonal. Tidak berlaku untuk state sembarang. **Kontradiksi.**

**Implikasi untuk QKD:**
- Eve **tidak bisa** menyalin qubit yang dikirim Alice.
- Satu-satunya cara Eve mendapatkan informasi adalah mengukur qubit — dan pengukuran mengubah state.
- Perubahan ini terdeteksi sebagai peningkatan error rate.

### 3.2 Basis Polarisasi Foton

BB84 menggunakan **foton tunggal** dengan dua basis polarisasi:

| Basis | Simbol | State | Bit |
|:------|:------:|:------|:---:|
| **Rektilinear (+)** | + | |0⟩ (horizontal) / |1⟩ (vertikal) | 0 / 1 |
| **Diagonal (x)** | x | |+⟩ (45°) / |−⟩ (135°) | 0 / 1 |

**Ilustrasi:**
```
Basis Rektilinear:   │    ──    (0 = horizontal, 1 = vertikal)
Basis Diagonal:      /    \     (0 = 45°, 1 = 135°)
```

**Properti Kunci:**
- Jika pengukuran dilakukan dengan basis yang **sama** dengan basis encoding, hasilnya deterministik (bit benar).
- Jika basis **berbeda**, hasilnya acak (50% benar, 50% salah).
- Eve tidak tahu basis mana yang digunakan Alice → harus menebak → 50% kesalahan.

### 3.3 Alur Protokol BB84 — Step-by-Step

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         PROTOKOL BB84 — 7 LANGKAH                            │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  STEP 1: Alice memilih bit acak dan basis acak                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Alice: bit = [0,1,1,0,1,0,0,1] → basis = [+,x,+,+,x,x,+,x]        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  STEP 2: Alice mengirim foton sesuai bit & basis                            │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Foton: |0⟩, |+⟩, |1⟩, |0⟩, |−⟩, |+⟩, |1⟩, |−⟩                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼ (saluran kuantum)                             │
│  STEP 3: Bob mengukur dengan basis acak                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Bob: basis = [+,+,x,x,+,+,x,+] → hasil = [0,1,1,0,1,0,0,1]        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  STEP 4: Alice & Bob mengumumkan basis (saluran klasik)                    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Alice: [+,x,+,+,x,x,+,x] → Bob: [+,+,x,x,+,+,x,+]                 │    │
│  │ MATCH: [✓,✗,✗,✓,✓,✗,✓,✓]                                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  STEP 5: Sifting — hanya bit dengan basis cocok yang dipakai              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Raw Key: [0,0,1,1,1] (dari posisi 1,4,5,7,8)                       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  STEP 6: Verifikasi Error — ambil sampel untuk deteksi Eve                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Sampel 30% → jika error > threshold (10-15%) → abort              │    │
│  │ Jika aman → lanjut                                                 │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  STEP 7: Privacy Amplification & Key Final                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Hash raw key → final key yang aman                                 │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3.4 Deteksi Penyadap (Eve)

**Skenario Intercept-Resend (Eve):**

1. **Eve menangkap foton** yang dikirim Alice.
2. **Eve mengukur** foton dengan basis acak (tidak tahu basis Alice).
3. **Eve mengirim ulang** foton ke Bob berdasarkan hasil pengukurannya.

**Probabilitas Deteksi:**

| Skenario | Probabilitas |
|:---------|:------------:|
| Alice & Bob pakai basis sama, Eve tebak basis sama | 50% × 50% = 25% (Eve tidak ketahuan) |
| Alice & Bob pakai basis sama, Eve tebak basis salah | 50% × 50% = 25% (Eve ketahuan) |
| Alice & Bob pakai basis beda | 50% (data dibuang saat sifting) |

**Total error rate akibat Eve pada bit verifikasi:** ~25%.

**Threshold:** Jika error rate > ~11-15%, kunci dibuang dan protokol diulang.

### 3.5 BB84 — Variasi dan Perbaikan

| Protokol | Tahun | Basis | Fitur Kunci |
|:---------|:-----:|:-----:|:------------|
| **BB84** | 1984 | 2 (+, x) | Protokol asli — most studied |
| **B92** | 1992 | 1 (non-orthogonal) | Hanya 1 basis — lebih sederhana |
| **E91 (Ekert)** | 1991 | 2 | Berbasis entanglement — keamanan dari Bell inequalities |
| **Decoy State** | 2003 | 2 | Menggunakan intensitas berbeda — deteksi serangan foton jamak |
| **Measurement-Device-Independent** | 2012 | 2 | Aman terhadap serangan pada detektor |

---

## 4. Fase 3 — Transisi Kriptografi Pasca-Kuantum (PQC)

### 4.1 Mengapa PQC dan Bukan Hanya QKD?

| Aspek | QKD | PQC |
|:------|:----|:----|
| **Fondasi** | Fisika (hukum kuantum) | Matematika (lattice, code-based) |
| **Infrastruktur** | Serat optik, foton tunggal | Software — jalan di hardware existing |
| **Jangkauan** | Terbatas (~100 km tanpa repeater) | Global (internet) |
| **Biaya** | Mahal (hardware khusus) | Murah (implementasi software) |
| **Keamanan** | Aman secara informasi | Aman komputasional (quantum-resistant) |
| **Kesiapan** | Masih prototipe | Standar NIST sudah rilis (2022) |

**QKD:** Untuk link point-to-point dengan keamanan tertinggi (militer, perbankan).
**PQC:** Untuk seluruh internet — TLS, VPN, email, blockchain.

### 4.2 NIST PQC Standards

| Algoritma | Kategori | Fungsi | Key Size | Signature Size |
|:----------|:---------|:-------|:--------:|:--------------:|
| **ML-KEM (FIPS 203)** | Lattice-based (Kyber) | KEM (Key Encapsulation) | 1,568 B (768) | — |
| **ML-DSA (FIPS 204)** | Lattice-based (Dilithium) | Digital Signature | 1,312 B | 2,420 B |
| **SLH-DSA (FIPS 205)** | Hash-based (SPHINCS+) | Digital Signature | ~1 KB | ~8-30 KB |
| **FN-DSA (FIPS 206)** | Lattice-based (Falcon) | Digital Signature | ~1 KB | ~1 KB |

**NIST Key Sizes Comparison:**

| Algorithm | Public Key | Secret Key | Ciphertext/Signature |
|:----------|:----------:|:----------:|:--------------------:|
| RSA-2048 | 256 B | 256 B | 256 B |
| ECC-256 | 32 B | 32 B | 64 B |
| **ML-KEM-768** | 1,184 B | 2,400 B | 1,088 B |
| **ML-KEM-1024** | 1,568 B | 3,168 B | 1,568 B |
| **ML-DSA-87** | 1,312 B | 2,528 B | 2,420 B |

### 4.3 Hybrid Certificates — Migrasi Bertahap

**Strategi Hybrid:**
```
TLS Certificate = [X.509 (classical)] + [X.509 (PQC)]

Client: Quantum-resistant handshake + Classical handshake
        └── Keduanya harus berhasil → aman
```

**Keuntungan:**
- Tetap aman jika classical atau PQC rusak, asal satu masih kuat.
- Kompatibilitas mundur.
- Mengurangi risiko "eksperimen" PQC yang belum teruji.

### 4.4 Peta Jalan Migrasi PQC

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PQC MIGRATION TIMELINE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  2022    2023    2024    2025    2026    2027    2028    2029    2030+      │
│   │       │       │       │       │       │       │       │       │         │
│   ├───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┤         │
│   │NIST   │       │       │       │       │       │       │       │         │
│   │Final  │       │       │       │       │       │       │       │         │
│   │───────┘       │       │       │       │       │       │       │         │
│   │               │       │       │       │       │       │       │         │
│   │  Experimental │       │       │       │       │       │       │         │
│   │  Deployments  │       │       │       │       │       │       │         │
│   │  (Cloud,     │       │       │       │       │       │       │         │
│   │   Banking)   │       │       │       │       │       │       │         │
│   │──────────────┘       │       │       │       │       │       │         │
│   │                      │       │       │       │       │       │         │
│   │         Mass Adoption│       │       │       │       │       │         │
│   │              Hybrid  │       │       │       │       │       │         │
│   │         ─────────────┘       │       │       │       │       │         │
│   │                              │       │       │       │       │         │
│   │                 Pure PQC     │       │       │       │       │         │
│   │                         ─────┘       │       │       │       │         │
│   │                                      │       │       │       │         │
│   │                              Quantum │       │       │       │         │
│   │                              Computer│       │       │       │         │
│   │                              Matures │       │       │       │         │
│   │                                     ─┴───────┘       │       │         │
│   │                                      Q-Day (2035?)   │       │         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Fase 4 — Hands-on Simulasi BB84 Menggunakan Qiskit

### 5.1 Setup Lingkungan

```bash
# Install Qiskit
pip install qiskit qiskit-aer

# Atau menggunakan environment
conda create -n qiskit python=3.10
conda activate qiskit
pip install qiskit[visualization]
```

### 5.2 Simulasi BB84 — Full Implementation dengan Eve

```python
import random
import numpy as np
from qiskit import QuantumCircuit, transpile
from qiskit_aer import AerSimulator
from qiskit.visualization import plot_histogram

class BB84Simulator:
    """
    Simulasi protokol BB84 dengan Qiskit.
    Mendukung skenario dengan dan tanpa penyadap (Eve).
    """
    
    def __init__(self, num_bits=100, eavesdrop=False):
        self.num_bits = num_bits
        self.eavesdrop = eavesdrop
        self.backend = AerSimulator()
        
        # Hasil
        self.alice_bits = None
        self.alice_bases = None
        self.bob_bases = None
        self.bob_bits = None
        self.raw_key = None
        self.error_rate = None
        
    def _encode_bit(self, bit, basis):
        """
        Encode satu bit menggunakan basis tertentu.
        Return: QuantumCircuit dengan 1 qubit.
        """
        qc = QuantumCircuit(1, 1)
        if bit == 1:
            qc.x(0)  # Flip ke |1⟩
        if basis == 'x':
            qc.h(0)  # Hadamard: pindah ke basis diagonal
        return qc
    
    def _measure_bit(self, qc, basis):
        """
        Ukur qubit dengan basis tertentu.
        Return: bit hasil pengukuran (0 atau 1).
        """
        if basis == 'x':
            qc.h(0)  # Kembalikan dari basis diagonal ke rektilinear
        qc.measure(0, 0)
        
        # Transpile dan jalankan
        transpiled = transpile(qc, self.backend)
        result = self.backend.run(transpiled, shots=1).result()
        counts = result.get_counts()
        return int(list(counts.keys())[0])
    
    def _eve_intercept(self, qc):
        """
        Eve intercept-resend attack.
        Eve mengukur dengan basis acak, lalu mengirim ulang.
        """
        eve_basis = random.choice(['+', 'x'])
        # Eve mengukur
        measured_bit = self._measure_bit(qc, eve_basis)
        # Eve mengirim ulang berdasarkan hasilnya
        new_qc = self._encode_bit(measured_bit, eve_basis)
        return new_qc
    
    def run(self):
        """
        Jalankan simulasi penuh BB84.
        """
        # Step 1: Alice memilih bit dan basis acak
        self.alice_bits = [random.randint(0, 1) for _ in range(self.num_bits)]
        self.alice_bases = [random.choice(['+', 'x']) for _ in range(self.num_bits)]
        
        # Step 2-3: Kirim dan ukur
        self.bob_bases = [random.choice(['+', 'x']) for _ in range(self.num_bits)]
        self.bob_bits = []
        
        for i in range(self.num_bits):
            # Encode oleh Alice
            qc = self._encode_bit(self.alice_bits[i], self.alice_bases[i])
            
            # Eve intercept (jika aktif)
            if self.eavesdrop:
                qc = self._eve_intercept(qc)
            
            # Bob mengukur
            measured = self._measure_bit(qc, self.bob_bases[i])
            self.bob_bits.append(measured)
        
        # Step 4-5: Sifting
        self.raw_key = []
        self.match_positions = []
        for i in range(self.num_bits):
            if self.alice_bases[i] == self.bob_bases[i]:
                self.raw_key.append(self.bob_bits[i])
                self.match_positions.append(i)
        
        # Step 6: Hitung error rate (dengan asumsi beberapa bit dicocokkan)
        errors = 0
        total_checked = min(50, len(self.raw_key))
        for i in range(total_checked):
            pos = self.match_positions[i]
            if self.alice_bits[pos] != self.bob_bits[pos]:
                errors += 1
        self.error_rate = errors / total_checked if total_checked > 0 else 0
        
        return self
    
    def get_summary(self):
        """
        Ringkasan hasil simulasi.
        """
        return {
            'total_bits': self.num_bits,
            'raw_key_length': len(self.raw_key),
            'raw_key': self.raw_key[:20],  # Preview saja
            'error_rate': self.error_rate,
            'eavesdrop_detected': self.error_rate > 0.11,
            'key_usable': self.error_rate < 0.10
        }
    
    def print_report(self):
        """
        Cetak laporan simulasi.
        """
        print("=" * 60)
        print("BB84 SIMULATION REPORT")
        print("=" * 60)
        print(f"Total bits sent:       {self.num_bits}")
        print(f"Basis match rate:      {len(self.raw_key)}/{self.num_bits} ({len(self.raw_key)/self.num_bits*100:.1f}%)")
        print(f"Raw key length:        {len(self.raw_key)}")
        print(f"Error rate (sample):   {self.error_rate*100:.2f}%")
        print(f"Eavesdrop detected:    {'⚠️ YES' if self.error_rate > 0.11 else '✅ NO'}")
        print(f"Key usable:            {'✅ YES' if self.error_rate < 0.10 else '❌ NO'}")
        print("-" * 60)
        print(f"Raw key preview:       {self.raw_key[:20]}")
        print("=" * 60)

# ============================================================================
# EKSEKUSI
# ============================================================================

# 1. Simulasi tanpa Eve (ideal)
print("\n🔐 SIMULASI BB84 — TANPA PENYADAP")
sim_no_eve = BB84Simulator(num_bits=100, eavesdrop=False)
sim_no_eve.run()
sim_no_eve.print_report()

# 2. Simulasi dengan Eve
print("\n🔐 SIMULASI BB84 — DENGAN PENYADAP (EVE)")
sim_with_eve = BB84Simulator(num_bits=100, eavesdrop=True)
sim_with_eve.run()
sim_with_eve.print_report()

# 3. Analisis multiple runs
print("\n📊 ANALISIS MULTI-RUN")
eve_rates = []
no_eve_rates = []
for _ in range(50):
    sim_no = BB84Simulator(num_bits=200, eavesdrop=False)
    sim_no.run()
    no_eve_rates.append(sim_no.error_rate)
    
    sim_ev = BB84Simulator(num_bits=200, eavesdrop=True)
    sim_ev.run()
    eve_rates.append(sim_ev.error_rate)

print(f"Tanpa Eve:  avg error = {np.mean(no_eve_rates)*100:.2f}% (std={np.std(no_eve_rates)*100:.2f}%)")
print(f"Dengan Eve: avg error = {np.mean(eve_rates)*100:.2f}% (std={np.std(eve_rates)*100:.2f}%)")
print(f"Perbedaan:  {np.mean(eve_rates)*100 - np.mean(no_eve_rates)*100:.2f}% point")
```

### 5.3 Visualisasi — Sirkuit BB84

```python
from qiskit.visualization import plot_histogram, plot_bloch_multivector

def visualize_bb84_circuit(bit=1, basis='x'):
    """
    Visualisasi sirkuit untuk satu qubit BB84.
    """
    qc = QuantumCircuit(1, 1)
    
    # Encode
    if bit == 1:
        qc.x(0)
    if basis == 'x':
        qc.h(0)
    
    # Visualisasi state
    qc.save_statevector()
    
    # Simulasi untuk plot
    backend = AerSimulator()
    qc = transpile(qc, backend)
    result = backend.run(qc).result()
    statevector = result.get_statevector()
    
    print(f"State: {statevector}")
    print(f"Basis: {'Diagonal (x)' if basis == 'x' else 'Rektilinear (+)'}")
    print(f"Bit: {bit}")
    
    # Plot Bloch sphere
    plot_bloch_multivector(statevector)

# Contoh
visualize_bb84_circuit(bit=1, basis='x')
```

### 5.4 Deteksi Penyadap — Analisis Error Rate

```python
def detect_eve_analysis():
    """
    Analisis deteksi Eve berdasarkan error rate.
    """
    import matplotlib.pyplot as plt
    
    # Data simulasi
    error_rates_no_eve = []
    error_rates_with_eve = []
    key_lengths = []
    
    for n in [10, 20, 50, 100, 200, 500]:
        # Tanpa Eve
        sim = BB84Simulator(num_bits=n, eavesdrop=False)
        sim.run()
        error_rates_no_eve.append(sim.error_rate)
        
        # Dengan Eve
        sim = BB84Simulator(num_bits=n, eavesdrop=True)
        sim.run()
        error_rates_with_eve.append(sim.error_rate)
        
        key_lengths.append(n)
    
    # Plot
    plt.figure(figsize=(10, 6))
    plt.plot(key_lengths, [e*100 for e in error_rates_no_eve], 'g-o', label='Tanpa Eve')
    plt.plot(key_lengths, [e*100 for e in error_rates_with_eve], 'r-o', label='Dengan Eve')
    plt.axhline(y=11, color='orange', linestyle='--', label='Threshold (11%)')
    plt.xlabel('Jumlah Bit Dikirim')
    plt.ylabel('Error Rate (%)')
    plt.title('Deteksi Penyadap — Error Rate BB84')
    plt.legend()
    plt.grid(True)
    plt.show()

detect_eve_analysis()
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1 — Sifting Efficiency
**Pertanyaan:** Dalam BB84 dengan 100 bit dikirim, berapa panjang raw key yang diharapkan?

**Solusi:**
- Probabilitas Alice dan Bob memilih basis yang sama = 50% (karena masing-masing pilih dari 2 basis).
- Raw key length = 100 × 0.5 = **50 bit** (rata-rata).
- Dengan Eve intercept-resend, raw key tetap 50 bit, tapi error rate meningkat.

### Soal 2 — Eve Detection Probability
**Pertanyaan:** Jika Eve menyadap 100% bit, berapa probabilitas dia lolos deteksi jika Alice-Bob verifikasi 30 bit?

**Solusi:**
- Error rate akibat Eve pada bit verifikasi = 25%.
- Probabilitas lolos deteksi (error < 11%) pada 30 bit:
  - Error rate < 11% → < 3.3 error dari 30 bit.
  - Distribusi binomial: $P(X \leq 3) = \sum_{k=0}^{3} \binom{30}{k} (0.25)^k (0.75)^{30-k}$
  - $P \approx 0.018$ (1.8%).
- **Kesimpulan:** Dengan 30 bit verifikasi, Eve tertangkap 98.2% dari waktu.

### Soal 3 — No-Cloning Theorem
**Pertanyaan:** Mengapa no-cloning theorem adalah fondasi keamanan QKD?

**Solusi:**
- Tanpa no-cloning theorem, Eve bisa menyalin qubit Alice tanpa mengubahnya.
- Dengan salinan, Eve bisa mengukur satu salinan dan mengirim salinan lain ke Bob — tanpa terdeteksi.
- No-cloning theorem membuat **setiap pengukuran Eve merusak state** — deteksi instan.

### Soal 4 — Perbandingan QKD vs PQC
**Pertanyaan:** Dalam skenario migrasi TLS, mengapa PQC lebih praktis daripada QKD?

**Solusi:**
- **Infrastruktur:** QKD butuh serat optik khusus dan foton tunggal → mahal dan terbatas.
- **Jangkauan:** QKD terbatas ~100 km (tanpa repeater quantum); PQC global.
- **Integrasi:** PQC adalah software — bisa di-deploy di server existing; QKD butuh hardware baru.
- **Keamanan:** QKD aman secara informasi; PQC aman komputasional. Untuk sebagian besar aplikasi, PQC sudah cukup.

### Soal 5 — Quantum Hacking
**Pertanyaan:** Bagaimana serangan "photon number splitting" (PNS) bekerja dan bagaimana decoy state mengatasinya?

**Solusi:**
- **Serangan PNS:** Alice mengirim beberapa foton dalam satu pulse (akibat laser tidak sempurna). Eve mengambil satu foton dan mengirim sisanya ke Bob.
- **Deteksi Decoy State:** Alice mengirim pulse dengan intensitas berbeda (signal dan decoy). Eve tidak bisa membedakan, sehingga perubahan intensitas terdeteksi di sisi Bob.

---

## 7. Quantum Cryptography vs Post-Quantum Cryptography — Perbandingan Fundamental

### 7.1 Definisi dan Tujuan

| Aspek | Quantum Cryptography | Post-Quantum Cryptography |
|:------|:---------------------|:--------------------------|
| **Definisi** | Menggunakan prinsip kuantum untuk kriptografi | Algoritma klasik yang aman terhadap serangan kuantum |
| **Tujuan** | Mendistribusikan kunci dengan aman | Enkripsi dan tanda tangan yang tahan kuantum |
| **Fondasi** | Fisika (no-cloning, entanglement) | Matematika (lattice, hash, code) |
| **Contoh** | BB84, E91, decoy-state QKD | ML-KEM, ML-DSA, SPHINCS+ |

### 7.2 Kelebihan dan Keterbatasan

| Aspek | Quantum Crypto | PQC |
|:------|:--------------:|:---:|
| **Keamanan informasi** | ✅ (unconditional) | ❌ (komputasional) |
| **Kompatibilitas existing** | ❌ (butuh hardware baru) | ✅ (software update) |
| **Skalabilitas global** | ❌ (terbatas jarak) | ✅ (internet) |
| **Biaya implementasi** | 💰💰💰 | 💰 |
| **Kesiapan sekarang** | ⚠️ (prototipe) | ✅ (standar NIST) |
| **Resilience terhadap QC** | ✅ (100%) | ✅ (hingga QC matures) |

### 7.3 Model Ancaman Komplementer

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                  STRATEGI KEAMANAN QUANTUM-SAFE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        HYBRID APPROACH                               │    │
│  │                                                                      │    │
│  │  ┌──────────────────┐    ┌──────────────────────────────────────┐   │    │
│  │  │    Classical      │    │     PQC (ML-KEM, ML-DSA)             │   │    │
│  │  │   (RSA/ECC)       │───►│     — Backbone keamanan internet     │   │    │
│  │  │   — untuk         │    │     — Software-based, scalable       │   │    │
│  │  │   kompatibilitas  │    │                                      │   │    │
│  │  └──────────────────┘    └──────────────────────────────────────┘   │    │
│  │                                                                      │    │
│  │                           +                                           │    │
│  │                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────┐   │    │
│  │  │      Quantum Crypto (QKD)                                    │   │    │
│  │  │      — Untuk link kritis (militer, perbankan)               │   │    │
│  │  │      — Keamanan informasi unconditionally secure             │   │    │
│  │  │      — Hardware khusus, terbatas jarak                       │   │    │
│  │  └──────────────────────────────────────────────────────────────┘   │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Implementasi Praktis — BB84 dengan Deteksi Penyadapan

### 8.1 Full Implementation dengan Noise Model

```python
import numpy as np
from qiskit import QuantumCircuit, transpile
from qiskit_aer import AerSimulator, Aer
from qiskit_aer.noise import NoiseModel, depolarizing_error

class BB84WithNoise:
    """
    BB84 dengan noise model realistis.
    """
    
    def __init__(self, num_bits=100, noise_prob=0.02, eve_prob=0.0):
        self.num_bits = num_bits
        self.noise_prob = noise_prob
        self.eve_prob = eve_prob
        self.backend = AerSimulator()
        self.results = {}
        
    def _create_noise_model(self):
        """Buat noise model untuk simulasi realistis."""
        noise_model = NoiseModel()
        error = depolarizing_error(self.noise_prob, 1)
        noise_model.add_all_qubit_quantum_error(error, ['x', 'h', 'measure'])
        return noise_model
    
    def _measurement_with_noise(self, qc, basis, noise_model=None):
        """Ukur dengan basis, dengan atau tanpa noise."""
        if basis == 'x':
            qc.h(0)
        qc.measure(0, 0)
        
        # Transpile
        if noise_model:
            transpiled = transpile(qc, self.backend)
            result = self.backend.run(transpiled, shots=1, noise_model=noise_model).result()
        else:
            transpiled = transpile(qc, self.backend)
            result = self.backend.run(transpiled, shots=1).result()
        
        counts = result.get_counts()
        return int(list(counts.keys())[0])
    
    def run(self):
        """Jalankan simulasi dengan noise."""
        # Alice
        alice_bits = np.random.randint(0, 2, self.num_bits)
        alice_bases = np.random.choice(['+', 'x'], self.num_bits)
        
        # Bob
        bob_bases = np.random.choice(['+', 'x'], self.num_bits)
        bob_bits = []
        
        # Noise model
        noise_model = self._create_noise_model() if self.noise_prob > 0 else None
        
        for i in range(self.num_bits):
            # Encode
            qc = QuantumCircuit(1, 1)
            if alice_bits[i] == 1:
                qc.x(0)
            if alice_bases[i] == 'x':
                qc.h(0)
            
            # Eve (probabilistik)
            if np.random.random() < self.eve_prob:
                eve_basis = np.random.choice(['+', 'x'])
                eve_bit = self._measurement_with_noise(qc, eve_basis, noise_model)
                # Re-encode berdasarkan hasil Eve
                qc = QuantumCircuit(1, 1)
                if eve_bit == 1:
                    qc.x(0)
                if eve_basis == 'x':
                    qc.h(0)
            
            # Bob mengukur
            bob_bit = self._measurement_with_noise(qc, bob_bases[i], noise_model)
            bob_bits.append(bob_bit)
        
        # Sifting
        raw_key = []
        for i in range(self.num_bits):
            if alice_bases[i] == bob_bases[i]:
                raw_key.append(bob_bits[i])
        
        # Hitung QBER (Quantum Bit Error Rate)
        errors = 0
        for i in range(min(50, len(raw_key))):
            idx = [j for j in range(self.num_bits) if alice_bases[j] == bob_bases[j]][i]
            if alice_bits[idx] != bob_bits[idx]:
                errors += 1
        qber = errors / min(50, len(raw_key)) if min(50, len(raw_key)) > 0 else 0
        
        self.results = {
            'raw_key': raw_key,
            'raw_key_len': len(raw_key),
            'qber': qber,
            'secure': qber < 0.11,
            'alice_bits': alice_bits,
            'bob_bits': bob_bits
        }
        return self.results

# ============================================================================
# TEST — EFEK NOISE vs EVE
# ============================================================================

print("📊 QBER: NOISE vs EVE")
print("-" * 50)

# Berbagai skenario
scenarios = [
    ('Ideal', 0.00, 0.00),
    ('Noise 2%', 0.02, 0.00),
    ('Noise 5%', 0.05, 0.00),
    ('Eve 50%', 0.00, 0.50),
    ('Eve 100%', 0.00, 1.00),
    ('Noise 2% + Eve 100%', 0.02, 1.00),
]

for name, noise, eve in scenarios:
    sim = BB84WithNoise(num_bits=200, noise_prob=noise, eve_prob=eve)
    results = sim.run()
    status = "✅ AMAN" if results['secure'] else "❌ TIDAK AMAN"
    print(f"{name:20} | QBER: {results['qber']*100:5.2f}% | {status}")
```

### 8.2 Output yang Diharapkan

```
📊 QBER: NOISE vs EVE
--------------------------------------------------
Ideal                | QBER:  0.00% | ✅ AMAN
Noise 2%             | QBER:  1.50% | ✅ AMAN
Noise 5%             | QBER:  4.20% | ✅ AMAN
Eve 50%              | QBER: 12.50% | ❌ TIDAK AMAN
Eve 100%             | QBER: 25.00% | ❌ TIDAK AMAN
Noise 2% + Eve 100%  | QBER: 26.80% | ❌ TIDAK AMAN
```

---

## 9. Eksperimen dan Implementasi Nyata

| Proyek | Tahun | Deskripsi | Status |
|:-------|:-----:|:----------|:------|
| **DARPA Quantum Network** | 2003 | QKD network 10 km di Boston | Selesai (prototipe) |
| **BBN Quantum Network** | 2004 | QKD dengan decoy state | Selesai |
| **Tokyo QKD Network** | 2010 | 6-node QKD network (45 km) | Selesai |
| **Chinese Micius Satellite** | 2016 | QKD via satelit (1200 km) | Aktif |
| **European Quantum Flagship** | 2018 | OpenQKD project (12 negara) | Aktif |
| **NIST PQC Standards** | 2022 | ML-KEM, ML-DSA, SLH-DSA, FN-DSA | Final |
| **Google Quantum Key Dist** | 2024 | Demonstrasi QKD pada chip superkonduktor | Eksperimental |
| **Quantum Internet Alliance** | 2025+ | Quantum internet Eropa | Fase 1 |

---

## 10. Open Problems dan Frontier

| Problem | Status | Impact |
|:--------|:------:|:------:|
| **Quantum Repeaters** | Eksperimental | Jangkauan QKD global |
| **Device-Independent QKD** | Teoritis | Keamanan tanpa asumsi hardware |
| **Quantum Memory** | Eksperimental | Store-and-forward quantum |
| **Integration with Classical** | Aktif | Hybrid quantum-internet |
| **PQC Standardization** | ✅ | NIST final (2022) |
| **PQC Migration** | Berlangsung | TLS 1.3, SSH, IPSec |
| **Quantum-Safe Blockchain** | Eksperimental | Post-quantum signatures |
| **QKD + PQC Hybrid** | Research | Best of both worlds |

### 10.1 Quantum Repeater

**Masalah:** QKD terbatas ~100 km karena fiber loss.

**Solusi:** Quantum repeater — menggunakan entanglement swapping untuk memperpanjang jangkauan.

**Komponen:**
1. **Entanglement generation:** Buat pasangan entangled di masing-masing segmen.
2. **Entanglement swapping:** Hubungkan entanglement antar segmen.
3. **Quantum memory:** Simpan entanglement sementara.

### 10.2 Device-Independent QKD

**Masalah:** QKD mengasumsikan hardware (detektor, sumber foton) aman.

**Solusi:** Device-independent QKD — keamanan hanya bergantung pada Bell inequalities, bukan pada trust hardware.

**Properti:**
- Tidak perlu trust perangkat.
- Deteksi serangan pada hardware.
- Keamanan dari violation Bell inequality.

---

## 11. References

1. Bennett, C. & Brassard, G. (1984). "Quantum cryptography: Public key distribution and coin tossing." — Proceedings of IEEE International Conference on Computers, Systems and Signal Processing.
2. Wootters, W. & Zurek, W. (1982). "A single quantum cannot be cloned." — Nature 299, 802.
3. Ekert, A. (1991). "Quantum cryptography based on Bell's theorem." — Phys. Rev. Lett. 67, 661.
4. Scarani, V. et al. (2009). "The security of practical quantum key distribution." — Rev. Mod. Phys. 81, 1301.
5. Lo, H.K. et al. (2012). "Measurement-device-independent quantum key distribution." — Phys. Rev. Lett. 108, 130503.
6. NIST FIPS 203: Module-Lattice-Based Key-Encapsulation Mechanism (ML-KEM)
7. NIST FIPS 204: Module-Lattice-Based Digital Signature (ML-DSA)
8. NIST FIPS 205: Stateless Hash-Based Digital Signature (SLH-DSA)
9. NIST FIPS 206: FALCON Digital Signature (FN-DSA)
10. Gisin, N. et al. (2002). "Quantum cryptography." — Rev. Mod. Phys. 74, 145.
11. Gilchrist, A. et al. (2015). "Quantum repeaters." — arXiv:1502.07248.
12. Lo, H.K. & Chau, H. (1999). "Unconditional security of quantum key distribution." — Science 283, 2050.

---

## 12. Koneksi ke Vault

| Catatan | Hubungan |
|:--------|:---------|
| [[quantum-cryptography-deepdive]] | Analisis teoretis — komputasi kuantum, Shor, Grover |
| [[quantum-error-correction-surface-code]] | QEC untuk quantum communication — menjaga integritas qubit |
| [[post-quantum-tls]] | Strategi implementasi PQC di TLS |
| [[pqc-implementation-rust]] | Kode Rust untuk ML-KEM dan ML-DSA |
| [[quantum-machine-learning]] | QML — aplikasi lain dari quantum computing |
| [[cryptography-biometrics]] | Biometrik — overlap dengan QKD untuk authentication |
| [[math-and-algorithms]] | Aljabar linear — fondasi semua quantum |
| [[00_Atlas/hierarchy-quantum-cryptography]] | Peta konsep — kedudukan QKD/PQC dalam quantum cryptography |
| [[00_Atlas/hierarchy-quantum-cryptography-stack]] | Stack lengkap — dari qubit hingga aplikasi quantum-safe |
| [[00_Atlas/hierarchy-cryptography]] | Taksonomi kriptografi klasik vs kuantum |
| [[post-quantum-tls-implementation]] | Implementasi PQC di TLS 1.3 — panduan teknis |
