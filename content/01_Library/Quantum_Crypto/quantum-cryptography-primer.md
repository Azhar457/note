---
title: Quantum Cryptography Primer — Fondasi Matematika & Protokol Kuantum
tags:
  - cryptography
  - quantum
  - qkd
  - qrng
  - bb84
  - e91
  - lattice
  - isogeny
  - pqc
aliases:
  - quantum-cryptography-primer
  - quantum-cryptography
created: '2026-08-04'
updated: '2026-08-04'
status: completed
cssclasses:
  - wide-table
  - callout

---

# ⚛️ Quantum Cryptography Primer — Fondasi Matematika & Protokol Kuantum

> **Dasar-dasar kriptografi kuantum: QKD (Quantum Key Distribution), QRNG (Quantum RNG), dan PQC (Post-Quantum Cryptography).** Bukan tutorial — ini **referensi matematika & protokol** untuk memahami *mengapa* protokol kuantum aman dan *bagaimana* PQC lattice-based bekerja. Untuk implementasi TLS praktis, lihat [[post-quantum-tls]]. Untuk roadmap migrasi, lihat [[quantum-cryptography-roadmap]]. Untuk hierarki domain, lihat [[hierarchy-quantum-cryptography]] dan [[Note/01_Library/Quantum_Crypto/hierarchy-quantum-cryptography-stack]].

---

## Daftar Isi

- [[#1. Dua Paradigma: QKD vs PQC]]
- [[#2. Quantum Key Distribution (QKD)]]
- [[#3. Quantum Random Number Generator (QRNG)]]
- [[#4. Post-Quantum Cryptography (PQC) — Lattice-Based]]
- [[#5. Code-Based & Hash-Based Signatures]]
- [[#6. Isogeny-Based Cryptography (SIKE/CSIDH)]]
- [[#7. Security Proofs & Assumptions]]
- [[#8. Implementation Pitfalls]]

---

## 1. Dua Paradigma: QKD vs PQC

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                        QUANTUM CRYPTOGRAPHY LANDSCAPE                      │
├─────────────────────────────────┬──────────────────────────────────────────┤
│         QKD (Physics-based)     │         PQC (Math-based)                 │
├─────────────────────────────────┼──────────────────────────────────────────┤
│ • Keamanan berbasis hukum fisika│ • Keamanan berbasis kerumitan komputasi  │
│   (ketidakpastian Heisenberg)   │   (hard problem matematika)              │
│ • Butuh channel kuantum (fiber/ │ • Jalan di channel klasik (internet)     │
│   free-space)                   │ • Tidak butuh hardware khusus            │
│ • Distance limited (~100-500km  │ • Distance unlimited                     │
│   fiber, ~1200km satellite)     │ • Algoritma: Kyber, Dilithium, SPHINCS+  │
│ • Rate: kbps - Mbps             │ • Throughput: Gbps (software)            │
│ • Protokol: BB84, E91, MDI-QKD  │ • Standar: NIST PQC, IETF RFC           │
│ • Use case: Gov, militer, bank  │ • Use case: TLS, VPN, email, blockchain  │
└─────────────────────────────────┴──────────────────────────────────────────┘
```

> **Key Insight:** QKD = *key distribution* saja (butuh authenticated channel klasik). PQC = *full cryptography* (KEM + Signature + KEM). **Keduanya komplementer** — QKD untuk link kritis (data center interconnect), PQC untuk internet luas.

---

## 2. Quantum Key Distribution (QKD)

### 2.1 BB84 Protocol (Bennett-Brassard 1984)

```text
Alice                                                                Bob
────                                                                 ────
│                                                                    │
│  1. Generate random bits:     b = [0,1,1,0,1,0,0,1...]            │
│  2. Choose random bases:      basis = [Z,X,Z,Z,X,X,Z,X...]        │
│     Z = rectilinear (0°/90°), X = diagonal (45°/135°)             │
│                                                                    │
│  3. Encode qubits:            │0⟩_Z, │1⟩_X, │1⟩_Z, │0⟩_Z...       │──►│
│     (photon polarization)      │                                   │
│                                                                    │
│                                                    4. Measure in   │
│                                                    random bases:   │
│                                                    basis' =        │
│                                                    [Z,Z,X,Z,X,Z...]│
│                                                                    │
│  5. Public channel: announce bases (basis, basis')                │◄──│
│                                                                    │
│  6. Sift: keep bits where basis == basis'                         │
│     sifted key = [b_i where basis_i == basis'_i]                  │
│                                                                    │
│  7. Error estimation: sample subset, compute QBER                 │
│     If QBER > 11% → abort (eavesdropper detected)                 │
│                                                                    │
│  8. Error correction: Cascade / LDPC → identical key              │
│                                                                    │
│  9. Privacy amplification: Universal hashing → final secret key   │
│     len(final) = len(sifted) * (1 - h(QBER) - leak_EC)           │
└────                                                                ────
```

**QBER (Quantum Bit Error Rate) Threshold:**
- **BB84:** 11% (teoritis), ~7-8% (praktis dengan error correction overhead)
- **E91 (Ekert):** 7.1% (CHSH violation based)
- **MDI-QKD:** 2.7% (measurement-device-independent)

### 2.2 E91 Protocol (Ekert 1991) — Entanglement-Based

```text
Entangled Source (e.g., SPDC crystal)
        │
        ├── Photon A ──► Alice (measurement: 0°, 45°, 90°, 135°)
        │
        └── Photon B ──► Bob   (measurement: 22.5°, 67.5°, 112.5°, 157.5°)

CHSH Inequality Test:
  S = |E(a,b) - E(a,b') + E(a',b) + E(a',b')| ≤ 2 (classical)
  Quantum mechanics: S = 2√2 ≈ 2.828 > 2

If S > 2 → entanglement verified → no eavesdropper (monogamy of entanglement)
Key generated from correlated measurements at matching bases
```

### 2.3 MDI-QKD (Measurement-Device-Independent QKD)

```text
Alice ──►│           │◄── Bob
         │  Relay    │     (Untrusted measurement node)
         │  (Bell    │
         │  State    │
         │  Meas.)   │
         └───────────┘

- Relay bisa di-operasikan adversary!
- Security berbasis entanglement swapping
- Immune ke detector side-channel attacks
- Rate lebih rendah, distance lebih jauh (500km+ fiber)
- Komersial: ID Quantique, Toshiba, QuantumCTek
```

### 2.4 QKD Practical Parameters

| Parameter | Typical Value | State-of-the-Art |
|-----------|---------------|------------------|
| **Distance (fiber)** | 50-100 km | 500 km (ultra-low loss) |
| **Distance (satellite)** | 1200 km (Micius) | Global (constellation) |
| **Secret Key Rate** | 1 kbps - 1 Mbps | 10 Mbps (lab) |
| **Detector** | InGaAs APD / SNSPD | SNSPD (superconducting) |
| **Wavelength** | 1550 nm (C-band) | 1550 nm / 1310 nm |
| **QBER** | 1-5% | <1% |

---

## 3. Quantum Random Number Generator (QRNG)

### 3.1 Entropy Sources

| QRNG Type | Entropy Source | Rate | Certification |
|-----------|----------------|------|---------------|
| **Photon Arrival Time** | Poisson process (time between photons) | 10 Mbps - 1 Gbps | NIST SP 800-90B |
| **Photon Counting (SPAD)** | Vacuum fluctuations / shot noise | 100 Mbps - 10 Gbps | NIST, BSI |
| **Homodyne Detection** | Vacuum state quadrature measurement | 1-100 Gbps | Highest rate |
| **Phase Fluctuation** | Laser phase diffusion | 10 Gbps+ | Chip-scale |
| **RAM-based (classical)** | DRAM startup values / SRAM PUF | kbps | Not true QRNG |

### 3.2 QRNG in Cryptography

```rust
// Contoh integrasi QRNG hardware (ID Quantique Quantis)
use rand::RngCore;

struct QuantisQRNG {
    device: hidapi::HidDevice,
}

impl RngCore for QuantisQRNG {
    fn next_u32(&mut self) -> u32 {
        let mut buf = [0u8; 4];
        self.device.read(&mut buf).unwrap();
        u32::from_le_bytes(buf)
    }
    fn fill_bytes(&mut self, dest: &mut [u8]) {
        self.device.read(dest).unwrap();
    }
    fn try_fill_bytes(&mut self, dest: &mut [u8]) -> Result<(), rand::Error> {
        self.device.read(dest).map_err(|_| rand::Error::new(rand::ErrorKind::Unavailable))
    }
}

// Gunakan untuk: nonce, IV, ephemeral key, salt
let mut qrng = QuantisQRNG::new();
let nonce: [u8; 12] = qrng.gen();  // ChaCha20-Poly1305 nonce
let salt: [u8; 32] = qrng.gen();   // Argon2 salt
```

> **Warning:** QRNG hardware **bisa gagal silently** (laser degraded, detector dead). Selalu pakai **health test** (NIST SP 800-90B continuous test) dan **fallback ke CSPRNG** (ChaCha20/CTR_DRBG) dengan entropy injection.

---

## 4. Post-Quantum Cryptography (PQC) — Lattice-Based

### 4.1 Hard Problems

| Problem | Description | Best Known Attack | Security Level |
|---------|-------------|-------------------|----------------|
| **SIS (Short Integer Solution)** | Find short x: A·x = 0 mod q | Lattice reduction (BKZ) | Basis Dilithium, Falcon |
| **LWE (Learning With Errors)** | Find s: b = A·s + e mod q | Lattice reduction, dual attack | Basis Kyber, FrodoKEM |
| **Module-LWE/Module-SIS** | Structured lattice (polynomial rings) | Same, but smaller dimension | **Kyber, Dilithium** (NIST standard) |
| **Ring-LWE** | Polynomial ring Z_q[X]/(X^n+1) | NTRU-style attacks | NewHope (not selected) |

### 4.2 Kyber (ML-KEM) — Deep Dive

**Parameter Set (FIPS 203):**

| Param | Kyber-512 | Kyber-768 | Kyber-1024 |
|-------|-----------|-----------|------------|
| n (poly degree) | 256 | 256 | 256 |
| k (module rank) | 2 | 3 | 4 |
| q (modulus) | 3329 | 3329 | 3329 |
| η₁ (secret dist) | 3 | 2 | 2 |
| η₂ (error dist) | 2 | 2 | 2 |
| δ (failure prob) | 2⁻¹³⁸ | 2⁻¹⁶⁴ | 2⁻¹⁷⁴ |
| Classical security | 118 bits | 181 bits | 251 bits |
| Quantum security | 106 bits | 164 bits | 229 bits |

**NTT (Number Theoretic Transform) — Kyber's Secret Sauce:**

```text
Polynomial multiplication in R_q = Z_q[X]/(X^256+1):
Naive: O(n²) = 65,536 muls
NTT:    O(n log n) ≈ 256 * 8 = 2,048 muls  → 32x speedup!

NTT requires: q ≡ 1 (mod 2n) → 3329 ≡ 1 (mod 512) ✓
Primitive root: g = 17 (generator of multiplicative group)

Forward NTT:  â = NTT(a)  — pointwise multiply  —  â ⊙ b̂
Inverse NTT:  c = NTT⁻¹(â ⊙ b̂)  — result polynomial
```

### 4.3 Dilithium (ML-DSA) — Deep Dive

**Fiat-Shamir with Aborts:**

```text
Sign(sk, μ):
  1. Sample y ← S_γ¹ (masking vector)
  2. w = A·y                     (commitment)
  3. c = H(μ || w)               (challenge, via SHAKE256)
  4. z = y + c·s₁                (response)
  5. If ‖z‖_∞ ≥ γ₁ or ‖A·z - c·t‖_∞ ≥ γ₂:
       RESTART (abort)           ← rejection sampling!
  6. h = HighBits(A·z - c·t)     (hint for verification)
  7. σ = (c, z, h)

Verify(pk, μ, σ):
  1. c, z, h = σ
  2. w' = A·z - c·t₁ + LowBits(h)  (reconstruct w)
  3. Check c == H(μ || w') && ‖z‖_∞ < γ₁
```

**Rejection sampling probability:** ~5-10% per attempt → expected 1.05-1.1 iterations. Constant-time implementation **wajab** mask retry loop.

---

## 5. Code-Based & Hash-Based Signatures

### 5.1 Classic McEliece (KEM) — Code-Based

| Variant | Public Key | Ciphertext | Security | Note |
|---------|------------|------------|----------|------|
| **mceliece348864** | 261 KB | 128 B | 128-bit | Largest PK, but fastest decaps |
| **mceliece460896** | 524 KB | 188 B | 192-bit | High security |
| **mceliece6688128** | 1044 KB | 240 B | 256-bit | Very large PK |

**Struktur:** Goppa code → generator matrix G → public key = G' = S·G·P (scrambled). Ciphertext = m·G' + e. Decaps = Patterson decoding.

> **Trade-off:** Public key **sangat besar** (MB-level) → tidak cocok untuk TLS certificate (bandwidth). Cocok untuk email encryption, firmware signing (key embedded).

### 5.2 SPHINCS+ (Signature) — Hash-Based

| Variant | Signature | Public Key | Security | Speed |
|---------|-----------|------------|----------|-------|
| **SPHINCS+-SHA256-128s** | 8 KB | 32 B | 128-bit | Slow (stateless) |
| **SPHINCS+-SHA256-128f** | 17 KB | 32 B | 128-bit | Fast |
| **SPHINCS+-SHAKE256-128s** | 8 KB | 32 B | 128-bit | Slow |

**Struktur:** Merkle tree + FORS (few-time sig) + WOTS+ (one-time sig). **Stateless** — tidak butuh state management (beda XMSS/LMS).

> **Use case:** Root CA long-term signing, firmware verification, blockchain (stateless). Tidak untuk TLS leaf cert (signature terlalu besar → handshake bloat).

---

## 6. Isogeny-Based Cryptography (SIKE/CSIDH)

### 6.1 SIKE (Supersingular Isogeny Key Encapsulation)

> **⚠️ BROKEN 2022** — Castryck-Decru attack memecahkan SIKE dalam jam di laptop. **JANGAN PAKAI.**

**Pelajaran:** Isogeny-based butuh parameter lebih besar → performance drop drastis. CSIDH (commutative group action) masih berdiri tapi tidak distandardkan NIST.

### 6.2 CSIDH (Commutative Supersingular Isogeny Diffie-Hellman)

| Variant | Public Key | Shared Secret | Security | Status |
|---------|------------|---------------|----------|--------|
| **CSIDH-512** | 64 B | 64 B | ~128-bit classical | Active research |
| **CSIDH-1024** | 128 B | 128 B | ~256-bit classical | Active research |

**Keunggulan:** Key size **sangat kecil** (64 bytes vs 800+ Kyber). **Kekurangan:** Computation lambat (isogeny walk), side-channel resistant implementation sulit, belum NIST standard.

---

## 7. Security Proofs & Assumptions

### 7.1 Reductionist Security

| Scheme | Hard Problem | Reduction Type | Tightness |
|--------|--------------|----------------|-----------|
| **Kyber** | Module-LWE | IND-CCA2 via FO Transform | Tight (up to constant) |
| **Dilithium** | Module-SIS + SelfTargetMSIS | EUF-CMA via Fiat-Shamir | Non-tight (forking lemma) |
| **SPHINCS+** | Hash collision + PRF | EUF-CMA (standard model) | Tight |
| **Classic McEliece** | Syndrome Decoding | IND-CCA2 via Kobara-Imai | Tight |

### 7.2 Quantum Random Oracle Model (QROM)

Semua proof PQC modern butuh **QROM** — adversary bisa query random oracle dalam superposition. FO transform di Kyber **sudah proven secure di QROM** (Hofheinz-Hovelmanns-Kiltz 2017). Dilithium Fiat-Shamir **butuh QROM analysis tambahan** (Don et al. 2022).

---

## 8. Implementation Pitfalls

| Pitfall | Consequence | Mitigasi |
|---------|-------------|----------|
| **Non-constant-time NTT** | Timing attack → key recovery | Fixed-loop NTT, no secret-dependent branches |
| **Rejection sampling leak** | Signature timing → private key | Constant-time mask + dummy iterations |
| **Insufficient entropy** | Weak keys, predictable nonce | QRNG + CSPRNG fallback, health test |
| **Side-channel (cache, power)** | Key extraction via Flush+Reload | Constant-time memory access, masking |
| **Fault injection** | Skip verification, bypass abort | Redundant computation, checksum |
| **Parameter mismatch** | Interop failure, downgrade | Strict parameter validation, test vectors |

---

## Cross-Link

- **PQC TLS Implementasi** → [[post-quantum-tls]], [[pqc-implementation-rust]]
- **QKD/QRNG Hardware** → [[hardware-architecture]], [[quantum-cryptography-roadmap]]
- **Lattice Math** → [[Note/01_Library/Quantum_Crypto/hierarchy-quantum-cryptography-stack]], [[hierarchy-quantum-cryptography]]
- **NIST Standard** → [[quantum-cryptography-deepdive]] (existing 7540 words)
- **Master Index** → [[master-index]]

---

*Quantum Cryptography Primer · QKD = Physics-based Key Dist · QRNG = True Entropy Source · PQC = Math-based Full Crypto · Lattice (Kyber/Dilithium) = NIST Standard · Code/Hash/Isogeny = Alternatives · Constant-Time = Non-Negotiable*
