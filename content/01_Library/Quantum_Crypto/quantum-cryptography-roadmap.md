---
title: "Quantum Cryptography Learning Roadmap \u2014 From Qubits to BB84 Protocol\
  \ Simulation"
tags:
- quantum-cryptography
- quantum-computing
- cryptography
- qiskit
- physics
- roadmap
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
- callout
verification:
  status: unverified
  last_checked: '2026-08-12'
  confidence: LOW
---


| Item | Detail |
|------|--------|
| **Summary** | Peta jalan kriptografi kuantum: qubit & mekanika → protokol QKD BB84 → transisi PQC (ML-KEM/ML-DSA) → simulasi Qiskit. |






[[00_Atlas/hierarchy-quantum-cryptography]] [[00_Atlas/hierarchy-quantum-cryptography-stack]] [[00_Atlas/hierarchy-cryptography]] [[00_Atlas/overview]]

> [!abstract] Ringkasan & Hubungan ke Vault
> Era komputasi kuantum menuntut pergeseran total dari keamanan berbasis kompleksitas matematika ke keamanan berbasis hukum fisika. Catatan ini merancang peta jalan belajar terstruktur dari konsep qubit dasar hingga simulasi protokol distribusi kunci kuantum (QKD) menggunakan Qiskit Python, sebagai pasangan praktis dari berkas teoritis [[quantum-cryptography-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Mekanika Kuantum Dasar & Representasi Qubit](#2-fase-1-mekanika-kuantum-dasar--representasi-qubit)
3. [Fase 2: Protokol QKD (Quantum Key Distribution) BB84](#3-fase-2-protokol-qkd-quantum-key-distribution-bb84)
4. [Fase 3: Transisi Kriptografi Pasca-Kuantum (PQC)](#4-fase-3-transisi-kriptografi-pasca-kuantum-pqc)
5. [Fase 4: Hands-on Simulasi BB84 Menggunakan Qiskit](#5-fase-4-hands-on-simulasi-bb84-menggunakan-qiskit)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini membimbing Anda dari mekanika kuantum dasar hingga penulisan sirkuit kuantum:

```
[Fase 1: Qubit & Math] ──> [Fase 2: QKD BB84] ──> [Fase 3: PQC Migration] ──> [Fase 4: Qiskit Sim]
- Superposisi & Entanglement- No-cloning Theorem      - NIST PQC Standards        - Gerbang Kuantum (X, H)
- Notasi Dirac Bra-Ket      - Basis Polarisasi Photon  - ML-KEM & ML-DSA           - Simulasi BB84 Python
- Bloch Sphere              - Intersepsi Eve detection - Hybrid Certs Migration    - Pengukuran Qubit
```

---

## 2. Fase 1: Mekanika Kuantum Dasar & Representasi Qubit

Sebelum mempelajari kriptografi kuantum, Anda wajib menguasai representasi matematika dari **Qubit** (Quantum Bit):

- **Qubit State**: Berbeda dengan bit klasik yang bernilai 0 atau 1, qubit berada dalam kondisi superposisi linier dari kedua keadaan:
  $$\lvert\psi\rangle = \alpha \lvert0\rangle + \beta \lvert1\rangle$$
  Dimana amplitudo probabilitas $\alpha, \beta \in \mathbb{C}$ memenuhi syarat normalisasi:
  $$\lvert\alpha\rvert^2 + \lvert\beta\rvert^2 = 1$$
- **Entanglement (Keterikatan)**: Kondisi di mana dua partikel terhubung secara eksklusif sehingga keadaan satu partikel secara instan menentukan keadaan partikel pasangannya, meskipun dipisahkan jarak kosmis (digunakan untuk teletransportasi kuantum dan deteksi penyadapan).

---

## 3. Fase 2: Protokol QKD (Quantum Key Distribution) BB84

BB84 (ditemukan oleh Charles Bennett dan Gilles Brassard pada tahun 1984) adalah protokol distribusi kunci pertama yang memanfaatkan prinsip hukum fisika kuantum untuk menjamin kerahasiaan:

### 3.1 Hukum Fisika Pendukung
- **No-Cloning Theorem**: Menyatakan bahwa tidak mungkin membuat salinan identik yang sempurna dari status kuantum yang tidak dikenal. Penyadap (Eve) tidak bisa menduplikasi qubit tanpa mengubah keadaannya.
- **Efek Pengukuran**: Pengukuran terhadap status superposisi akan memaksa qubit runtuh (*collapse*) ke salah satu keadaan basis secara permanen.

### 3.2 Alur Protokol BB84
1. Alice mengirimkan serangkaian foton yang dipolarisasi secara acak menggunakan salah satu dari dua basis: **Rektilinear (+)** atau **Diagonal (x)**.
2. Bob mengukur foton yang diterima menggunakan basis pilihan acaknya sendiri.
3. Melalui saluran publik klasik, Alice dan Bob mencocokkan basis yang mereka gunakan (tanpa menyebutkan hasil pengukurannya).
4. Mereka membuang pengukuran yang basisnya tidak cocok, menyisakan rentetan bit kunci rahasia (*Raw Key*).

---

## 4. Fase 3: Transisi Kriptografi Pasca-Kuantum (PQC)

Perbedaan mendasar antara QKD dan PQC:
- **QKD (Hardware)**: Membutuhkan infrastruktur fisik serat optik khusus untuk mentransmisikan foton tunggal (sangat mahal).
- **PQC (Software)**: Algoritma matematika baru yang aman dari serangan komputer kuantum dan dapat langsung dijalankan di atas jaringan internet TCP/IP standar saat ini (seperti ML-KEM).

---

## 5. Fase 4: Hands-on Simulasi BB84 Menggunakan Qiskit

Berikut adalah implementasi Python menggunakan pustaka **Qiskit** dari IBM untuk menyimulasikan proses transfer qubit antara Alice dan Bob:

```python
from qiskit import QuantumCircuit, Aer, execute
import random

def simulate_bb84(num_bits=100):
    # 1. Alice menghasilkan bit klasik acak dan basis acak
    alice_bits = [random.randint(0, 1) for _ in range(num_bits)]
    alice_bases = [random.choice(['+', 'x']) for _ in range(num_bits)]
    
    # 2. Alice menyiapkan sirkuit kuantum untuk mentransmisikan qubit
    qubits = []
    for bit, basis in zip(alice_bits, alice_bases):
        qc = QuantumCircuit(1, 1)
        if bit == 1:
            qc.x(0) # Ubah state ke |1>
        if basis == 'x':
            qc.h(0) # Hadamard gate untuk mengubah ke basis diagonal
        qubits.append(qc)
        
    # 3. Bob memilih basis pengukurannya secara acak
    bob_bases = [random.choice(['+', 'x']) for _ in range(num_bits)]
    
    # 4. Bob melakukan pengukuran terhadap sirkuit kuantum yang diterima
    bob_bits = []
    backend = Aer.get_backend('qasm_simulator')
    
    for i, qc in enumerate(qubits):
        if bob_bases[i] == 'x':
            qc.h(0) # Kembalikan ke basis rektilinear jika Bob memilih x
        qc.measure(0, 0)
        
        result = execute(qc, backend, shots=1).result()
        counts = result.get_counts()
        measured_bit = int(list(counts.keys())[0])
        bob_bits.append(measured_bit)
        
    # 5. Pencocokan Basis (Sifting)
    shared_key = []
    for i in range(num_bits):
        if alice_bases[i] == bob_bases[i]:
            shared_key.append(bob_bits[i])
            
    return shared_key

# Jalankan simulasi
key = simulate_bb84(20)
print(f"Kunci Rahasia Hasil Kesepakatan: {key}")
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Bagaimana Alice dan Bob mendeteksi keberadaan penyadap (Eve) yang mencoba mengintersepsi foton di tengah transmisi protokol BB84?

**Solusi**
Alice dan Bob menyisihkan sebagian kecil kunci hasil sifting mereka (misal 10%) untuk dicocokkan secara terbuka di saluran publik.
- Jika tidak ada penyadap: Kesalahan bit (*Bit Error Rate* - BER) harusnya mendekati 0%.
- Jika Eve menguping: Karena Eve tidak tahu basis yang digunakan Alice, ia terpaksa menebak basis untuk mengukur dan mengirim ulang foton ke Bob. Tindakan ini memicu runtuhnya keadaan kuantum secara acak.
Bob akan mendeteksi peningkatan nilai BER mendekati **25%** pada bit verifikasi. Jika BER > ambang batas tertentu (misal 11%), Alice dan Bob menyimpulkan saluran telah disadap, membuang seluruh kunci, dan membuat ulang kunci baru.

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[quantum-cryptography-deepdive]] | Analisis teoretis mendalam mengenai komputasi kuantum, gerbang logika kuantum, dan algoritma Shor/Grover. |
| [[post-quantum-tls-implementation]] | Strategi penerapan algoritma asimetris pasca-kuantum untuk enkripsi web TLS 1.3. |
| [[pqc-implementation-rust]] | Struktur penulisan kode Rust untuk algoritma lattice-based cryptography. |

## 🔍 Verification Report
> [!NOTE]
> **Last Evaluated:** 2026-08-12 20:13
> **Overall Epistemic Status:** **`UNVERIFIED`**

### ❔ Claim 1: The qubit state is a linear superposition of states |0> and |1> where the probability amplitudes Î± and Î² satisfy |Î±|Â² + |Î²|Â² = 1.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 2: The No-Cloning Theorem states that it is impossible to create an identical copy of an unknown quantum state.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 3: BB84 uses two bases for photon polarization: Rectilinear (+) and Diagonal (x).
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

> [!callout] 💡
> Keamanan pasca-kuantum bukan sekadar algoritma baru — no-cloning theorem menjadikan QKD mendeteksi penyadapan secara fisik, bukan hanya matematis.
