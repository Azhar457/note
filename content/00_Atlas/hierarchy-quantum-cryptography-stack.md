---
tags:
  - hierarchy
  - cryptography
  - quantum
  - post-quantum
  - pqc
  - qkd
  - tls
aliases:
  - Quantum Cryptography Stack
  - Classical to Post-Quantum to Quantum Migration
  - Crypto Roadmap Hierarchy
  - Cryptography Layer Map
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🌌 Quantum Cryptography Stack — Dari Klasik ke Post-Quantum sampai Quantum-Native

> [!tip] Cryptography 2026 berada di **titik balik sejarah**: komputer kuantum skala-tinggi ancam algoritma klasik (RSA, ECC), tapi satu-satunya jawaban belum tersedia. Vault punya catatan untuk kriptografi klasik, post-quantum, dan quantum-key-distribution — tapi tidak ada satu dokumen pun yang **memetakan roadmap migrasi lengkap**. Catatan ini memetakan **7 lapisan**, dari math foundation sampai production deployment, dengan timeline spesifik dan decision tree: kapan migrasi, ke algoritma apa, dengan cara bagaimana.

---

## Daftar Isi

1. [[#1. Premise — Mengapa Sekarang?]]
2. [[#2. Seven-Layer Cryptography Stack]]
3. [[#3. Layer 0 — Mathematical Foundation]]
4. [[#4. Layer 1 — Classical Cryptography (1990-2025)]]
5. [[#5. Layer 2 — Transition Phase]]
6. [[#6. Layer 3 — Post-Quantum Cryptography (PQC) Standardized]]
7. [[#7. Layer 4 — Quantum Key Distribution (QKD)]]
8. [[#8. Layer 5 — Quantum-Resilient TLS Migration]]
9. [[#9. Layer 6 — Storage, Identity, and Long-Term Data]]
10. [[#10. Timeline 1990-2035 — Migrasi]]
11. [[#11. Decision Tree — Kapan Migrasi ke Apa]]
12. [[#12. Cross-Reference ke Vault]]
13. [[#References]]

---

## 1. Premise — Mengapa Sekarang?

Tahun 2024-2026 adalah inflection point:

**Driver 1: Harvest-Now-Decrypt-Later (HNDL) Attacks**

- Adversary **menyimpan** encrypted traffic sekarang
- Decrypt nanti saat punya quantum computer
- Target: anything dengan confidentiality >10-15 tahun (medical records, state secrets, IP)

**Driver 2: NIST PQC Standards Published (2024)**

- August 2024: FIPS 203 (ML-KEM / Kyber), FIPS 204 (ML-DSA / Dilithium), FIPS 205 (SLH-DSA / SPHINCS+)
- Migration has begun in earnest

**Driver 3: Quantum Ambition 2030+**

- Google's Willow (Dec 2024), IBM Quantum Heron (2024)
- Logical qubit error rate down 10× per year
- Cryptographically-relevant quantum computer (CRQC): 2029-2035 most estimates

**Driver 4: Long Tail of Compliance**

- Regulatory mandates for PQC migration underway
- CNSA 2.0 (NSA, 2024 timeline)
- EU PQCMigration roadmap (2025)

---

## 2. Seven-Layer Cryptography Stack

```
┌────────────────────────────────────────────────────────┐
│ Layer 6 — Storage, Identity, Long-Term Data             │
├────────────────────────────────────────────────────────┤
│ Layer 5 — Quantum-Resilient TLS / Network Protocols     │
├────────────────────────────────────────────────────────┤
│ Layer 4 — Quantum Key Distribution (QKD)                │
├────────────────────────────────────────────────────────┤
│ Layer 3 — Post-Quantum Cryptography (NIST PQC)        │
├────────────────────────────────────────────────────────┤
│ Layer 2 — Hybrid Crypto (Classical + PQC combined)    │
├────────────────────────────────────────────────────────┤
│ Layer 1 — Classical Cryptography (RSA/ECC/AES/SHA)   │
├────────────────────────────────────────────────────────┤
│ Layer 0 — Mathematical Foundation                       │
└────────────────────────────────────────────────────────┘
        ↑   HIGHER = MORE FORWARD-LOOKING
```

---

## 3. Layer 0 — Mathematical Foundation

### 3.1 Dua Fondasi Matematis

| Fondasi                   | Algoritma yang Berdiri Di Atasnya   | Dipengaruhi Quantum                     |
| ------------------------- | ----------------------------------- | --------------------------------------- |
| **Integer Factorization** | RSA                                 | ✅ Shor's (1994)                        |
| **Discrete Logarithm**    | Diffie-Hellman, DSA, ECDSA, Ed25519 | ✅ Shor's                               |
| **Elliptic Curves (EC)**  | ECDSA, Ed25519, X25519              | ✅ Shor's                               |
| **Symmetric crypto**      | AES, ChaCha20                       | 🟡 Grover's (effective security halved) |
| **Hash functions**        | SHA-256, SHA-3, BLAKE3              | 🟡 Grover's (quadratic speedup)         |
| **Lattice problems**      | Kyber, Dilithium, NTRU              | ❌ Unknown quantum exploit (yet)        |
| **Hash-based signatures** | SPHINCS+, XMSS, LMS                 | ❌ Secure                               |
| **Code-based**            | Classic McEliece                    | ❌ Secure (since 1978)                  |
| **Multivariate**          | Rainbow (broken), MAYO              | 🟡 Some risks                           |
| **Isogeny (broken)**      | SIKE (broken 2022)                  | ❌ Broken (non-quantum)                 |

### 3.2 Shor's vs Grover's Algorithm

| Algorithm  | Target                              | Quantum Speedup | Impact                               |
| ---------- | ----------------------------------- | --------------- | ------------------------------------ |
| **Shor**   | Integer factorization, discrete log | **Exponential** | RSA/ECC broken (2048-bit in hours)   |
| **Grover** | Brute-force search                  | **Quadratic**   | AES-256 → AES-128 effective strength |

**Implikasi:**

- Gunakan AES-256 (Grover's resistance)
- Ganti RSA/ECC dengan lattice/hash-based (Shor's resistance)
- Hash output harus 2× lipat (SHA-256 → SHA-512)

---

## 4. Layer 1 — Classical Cryptography (1990-2025)

### 4.1 Rekomendasi Saat Ini (Pre-PQC)

| Use Case             | Algorithm                 |      Key Size      |
| -------------------- | ------------------------- | :----------------: |
| Symmetric encryption | AES-256-GCM               |      256 bit       |
| Symmetric backup     | ChaCha20-Poly1305         |      256 bit       |
| Hashing              | SHA-3-256, BLAKE3         |      256+ bit      |
| Key exchange         | X25519                    |      256 bit       |
| Signing              | Ed25519                   | 256 bit (pub/priv) |
| Password hashing     | Argon2id                  |  64-128 MB memory  |
| TLS 1.3              | All above via OpenSSL 3.x |         -          |

### 4.2 Status 2026

- **Masih aman untuk kebanyakan kasus** (CRQC masih dalam horizon)
- **Tidak aman untuk long-term confidentiality** (HNDL attack relevan)
- **Sudah deprecated di beberapa compliance** (CNSA 2.0 NSA ban pure-RSA in NSS by 2033)

**Koneksi ke Vault:**

- [[hierarchy-cryptography]] — Master hierarchy kriptografi
- [[hierarchy-digital-plumbing]] — OpenSSL implementasi

---

## 5. Layer 2 — Transition Phase: Hybrid Crypto (2024-2030)

### 5.1 Mengapa Hybrid First?

Migrasi langsung ke PQC **memiliki risiko**:

1. Implementasi PQC baru — bugs di library
2. Standard baru (NIST) masih terus direview
3. Performance trade-offs besar (key size 10-100× larger)
4. Compatibility issue di protokol lama (TLS, JWT, X.509)

**Solusi:** hybrid — jalankan **classical + PQC paralel**. Hasil union — aman dari keduanya.

### 5.2 Pattern Hybrid Key Exchange

```
Traditional TLS:
  Client ← KeyShare (X25519) →  Server
  → shared secret = ECDH(X25519)

Hybrid TLS (X25519+ML-KEM-768):
  Client ← KeyShare (X25519, ML-KEM-768) →  Server
  → shared secret = KDF( ECDH(X25519) || ML-KEM_decaps(pk) )
  → Aman dari quantum attack (PQC) + bug PQC (classical)
```

### 5.3 Hybrid Implementations (2026)

| Implementation     | Algorithms          | Status                          |
| ------------------ | ------------------- | ------------------------------- |
| **TLS 1.3 hybrid** | X25519 + ML-KEM-768 | Chrome + Firefox support (2024) |
| **OpenSSL 3.5+**   | PQC provider        | Released 2025                   |
| **Cisco TLS**      | X25519 + ML-KEM-768 | Production 2025                 |
| **AWS KMS**        | RSA + ML-KEM        | Internal pilot 2024             |
| **IBM HSM**        | ECC + ML-DSA        | Hybrid 2025                     |

### 5.4 Hybrid Trade-offs

| Pro                                   | Con                                                 |
| ------------------------------------- | --------------------------------------------------- |
| Aman dua arah                         | Bandwidth naik ~1-2 KB per handshake                |
| Compliance-friendly (roll-forward)    | Latency naik 10-20% (ML-KEM dilithium lebih lambat) |
| Incremental rollout                   | Lebih kompleks dari pure-PQC                        |
| Backward compatible (melalui TLS 1.3) | 2 algorithm agility perlu                           |

### 5.5 Standar Hybrid

- **IETF draft-ietf-tls-hybrid-kem** — RFC track
- **X25519+ML-KEM-768** — sudah di Chrome/Firefox
- **P384+ML-KEM-1024** — quantum-resistant hybrid
- **X25519+Kyber768** — serupa

---

## 6. Layer 3 — Post-Quantum Cryptography (PQC) Standardized

### 6.1 NIST PQC Standards (Final 2024)

| Standard     | Algoritma           | Use Case                 | Type                 |
| ------------ | ------------------- | ------------------------ | -------------------- |
| **FIPS 203** | ML-KEM (Kyber768)   | Key Encapsulation        | Lattice (Module-LWE) |
| **FIPS 204** | ML-DSA (Dilithium3) | Digital Signature        | Lattice (Module-LWE) |
| **FIPS 205** | SLH-DSA (SPHINCS+)  | Signature (conservative) | Hash-based           |

**Also standardized/non-standardized:**

| Algorithm            | Type              | Status                            |
| -------------------- | ----------------- | --------------------------------- |
| **FN-DSA (Falcon)**  | Lattice signature | NIST standards-track (final near) |
| **Classic McEliece** | Code-based        | Alternate (long keys, slow)       |
| **BIKE**             | Code-based        | Alternate candidate               |
| **HQC**              | Code-based        | Alternate candidate               |
| **MAYO**             | Multivariate      | Under review                      |

### 6.2 Performance Comparison (ML-KEM vs RSA/ECC)

| Algorithm              | Public Key (B) | Ciphertext/Sig (B) | Sign/Enc Time | Verify/Dec Time |
| ---------------------- | :------------: | :----------------: | :-----------: | :-------------: |
| RSA-2048               |      256       |        256         |    1.5 ms     |     0.03 ms     |
| ECDSA P256             |       64       |         64         |    0.05 ms    |     0.1 ms      |
| Ed25519                |       32       |         64         |    0.05 ms    |     0.1 ms      |
| **ML-KEM-768**         |    **1216**    |      **1088**      |  **0.02 ms**  |   **0.03 ms**   |
| **ML-DSA-65**          |    **1952**    |      **3293**      |  **0.5 ms**   |   **0.2 ms**    |
| **SLH-DSA-SHAKE-128s** |     **32**     |      **7856**      |   **50 ms**   |    **5 ms**     |
| Falcon-512             |      897       |        614         |    0.4 ms     |     0.1 ms      |

**Key Insight:** ML-KEM **jauh lebih cepat dari RSA**, tapi **key size 10-100× lebih besar**. Trade-off bandwidth/signature inline.

### 6.3 Implementation Libraries (2026)

| Library                         | Languages              | Algorithms     | Status       |
| ------------------------------- | ---------------------- | -------------- | ------------ |
| **liboqs**                      | C                      | All NIST       | Mainstream   |
| **Open Quantum Safe (liboqs)**  | C, Python bindings     | All            | Production   |
| **pqcrypto (Python)**           | Python wrapping liboqs | All            | Research     |
| **Bouncy Castle (Java)**        | Java                   | ML-KEM, ML-DSA | Production   |
| **openssl-pqc-provider (3.5+)** | C                      | ML-KEM, ML-DSA | Production   |
| **Go BoringSSL PQC**            | Go                     | X25519+ML-KEM  | Production   |
| **AWS s2n PQC**                 | C                      | ML-KEM hybrid  | AWS-internal |

---

## 7. Layer 4 — Quantum Key Distribution (QKD)

### 7.1 Apa QKD Bukan?

QKD **bukan post-quantum cryptography**. QKD adalah metode berbeda:

- **Kirim key melalui quantum channel** (photon polarization)
- **Secara fisik aman** — eavesdropping terdeteksi melalui quantum mechanics
- **Membutuhkan hardware khusus** — fiber optic, single-photon detector, satellite link
- **Distance-limited** — ~100 km per hop di fiber, bisa ribuan km via satellite

### 7.2 Protokol QKD

| Protokol    | Tahun | Mekanisme                      |
| ----------- | :---: | ------------------------------ |
| **BB84**    | 1984  | Photon polarization (4 state)  |
| **E91**     | 1991  | Entangled pairs                |
| **B92**     | 1992  | 2-state                        |
| **BBM92**   | 1992  | Ekstensi E91                   |
| **MDI-QKD** | 2012  | Measurement-device-independent |
| **TF-QKD**  | 2019  | Twin-field, longer distance    |

### 7.3 QKD Networks (2026)

| Network                    | Lokasi    | Status                   |
| -------------------------- | --------- | ------------------------ |
| **Tokyo QKD Network**      | Jepang    | Production (10+ banks)   |
| **Beijing-Shanghai**       | Cina      | 2000 km backbone         |
| **EU Quantum Internet**    | Eropa     | In development           |
| **Madrid Quantum Network** | Spanyol   | Testbed                  |
| **UK Quantum Network**     | UK        | Testbed                  |
| **Korea KQNet**            | Korea     | Production               |
| **Singapore-Singtel**      | Singapura | Testbed                  |
| **DARPA QKD Trials**       | US        | 2024-2026                |
| **Micius Satellite**       | Cina      | Global QKD via satellite |

### 7.4 QKD vs PQC trade-offs

| Aspek      | PQC                 | QKD                          |
| ---------- | ------------------- | ---------------------------- |
| Hardware   | Pure software       | Photon source/detector       |
| Distance   | Unlimited           | ~100 km fiber, sat unlimited |
| Speed      | 100K+ ops/s         | ~10-100 Kbps                 |
| Deployment | TLS upgrade highway | New infrastructure           |
| Cost       | $0 (algoritma)      | $$ - $$$$                    |
| Maturity   | NIST standards done | Limited deployments          |

**Hybrid PQC+QKD** — best of both. QKD untuk high-confidentiality session, PQC for general.

---

## 8. Layer 5 — Quantum-Resilient TLS Migration

### 8.1 Status TLS 2026

- **TLS 1.3** default everywhere
- **Hybrid key exchange** (X25519+ML-KEM-768) implemented in:
  - Chrome 131+ (Sept 2024)
  - Firefox 132+ (Oct 2024)
  - OpenSSL 3.5+
  - AWS CloudFront
  - Cloudflare

### 8.2 Quantum-Resilient TLS Stack

```
┌─────────────────────────────────────────────────────┐
│ Application (HTTPS, gRPC, etc)                       │
├─────────────────────────────────────────────────────┤
│ TLS 1.3 (RFC 8446) + Hybrid KX extensions           │
│   ├─ KeyShare: { x25519: pub1, ml_kem768: pub2 }    │
│   ├─ KDF: ECDH(X25519) || ML-KEM_decaps(...)        │
│   └─ Result: shared secret 32-byte                  │
├─────────────────────────────────────────────────────┤
│ Transport (TCP / QUIC)                                │
└─────────────────────────────────────────────────────┘
```

### 8.3 Migration Checklist (Production)

```
[ ] Update OpenSSL/BoringSSL ke 3.5+ / 2024 edition
[ ] Hybrid keyshare configured in TLS group selection
[ ] Cert verification accepts both classical & hybrid chain
[ ] Test performance with slower x25519+ml-kem768
[ ] EDR/XDR updated to detect anomaly PQC usage
[ ] Monitoring — alert on TLS failures (hybrid tidak bisa fallback)
[ ] Roll-out phase: 1% → 10% → 50% → 100%
[ ] Documented rollback ke X25519-only
```

### 8.4 Browser Support TLS PQC

| Browser      | PQC Hybrid Support          | Date      |
| ------------ | --------------------------- | --------- |
| Chrome 124+  | X25519Kyb768 (legacy group) | 2024      |
| Chrome 131+  | X25519+ML-KEM-768           | 2024-09   |
| Firefox 124+ | X25519Kyb768                | 2024      |
| Firefox 132+ | X25519+ML-KEM-768           | 2024-10   |
| Safari       | RFP / in progress           | 2025-2026 |
| Edge         | Inherits Chrome             | 2024+     |

---

## 9. Layer 6 — Storage, Identity, and Long-Term Data

### 9.1 HNDL: Harvest-Now-Decrypt-Later

Data dengan confidentiality >10-15 tahun perlu **quantum-resistant protection SEKARANG**:

| Data Category         | Confidentiality Period | Migrasi Harus Mulai |
| --------------------- | ---------------------- | ------------------- |
| Geopolitical secrets  | 50+ years              | 2024                |
| Medical genetic data  | Lifetime               | 2024                |
| Industrial R&D        | 10-25 years            | 2025                |
| Financial transaction | 7-10+ years (regs)     | 2026                |
| Government comms      | 20+ years              | 2024                |

### 9.2 Storage Cryptography

| Komponen                   | Pre-PQC                    | PQC Hybrid                               |
| -------------------------- | -------------------------- | ---------------------------------------- |
| **Disk encryption (LUKS)** | AES-256-XTS                | AES-256-XTS unchanged (Grover-resistant) |
| **S3 SSE-KMS**             | AES-256                    | AES-256 — secure storage tetap aman      |
| **Backup**                 | AES-256 + RSA wrapping key | Wrapping key → ML-KEM                    |
| **PGP / GPG**              | RSA-4096                   | ML-KEM-768 + (RSA optional)              |
| **JWT (RS256)**            | RS256                      | ML-DSA-65                                |
| **X.509 cert**             | RSA/ECDSA                  | ML-DSA or hybrid                         |

### 9.3 Identity & PKI Migration

| Component           | Migration                                                                               |
| ------------------- | --------------------------------------------------------------------------------------- |
| **Root CA**         | Tetap RSA/ECC (signs infrequently, long lifetime) — wrap dengan ML-DSA sebagai "shield" |
| **Issuing CA**      | Dual-signed: classical + ML-DSA                                                         |
| **End-entity cert** | Issued dengan ML-DSA                                                                    |
| **CMP/EST**         | Add PQC algorithm negotiation                                                           |
| **CRL/OCSP**        | Signed dengan classical or ML-DSA                                                       |
| **SCEP/CMS**        | Add PQC support                                                                         |

### 9.4 Code Signing & Software Supply Chain

| Tool                       | Pre-PQC   | PQC                       |
| -------------------------- | --------- | ------------------------- |
| Sigstore (cosign)          | ECDSA     | ML-DSA-65                 |
| Sigstore Fulcio            | ECDSA     | ML-DSA-65                 |
| SLSA provenance            | ECDSA     | ML-DSA-65                 |
| TUF (The Update Framework) | RSA/ECDSA | ML-DSA-65                 |
| Microsoft Authenticode     | RSA-2048  | ML-DSA-65 (research 2024) |
| Notary v2                  | ECDSA     | ML-DSA-65                 |

**Koneksi ke Vault:**

- [[hierarchy-cybersecurity-defense-architecture]] — Layer L3 (Cryptography)
- [[hierarchy-it-domain]] — Industry context

---

## 10. Timeline 1990-2035 — Migrasi

```
┌──────────────────────────────────────────────────────────────────┐
│ Era          │ Major Milestone                                    │
├──────────────┼──────────────────────────────────────────────────┤
│ 1990-2000    │ RSA/ECC symmetric dominance                       │
│ 2000-2014    │ TLS 1.0/1.2, ECDSA emerges                       │
│ 2014-2016    │ SHA-1 broken, SHA-256 default                     │
│ 2016-2022    │ Shor awareness, NIST PQC competition launch      │
│ 2022         │ SIKE broken (quantum hype peak)                   │
│ Jul 2022     │ NIST selects 4 PQC algorithms (Kyber, Dilithium, │
│              │ Falcon, SPHINCS+)                                  │
│ Aug 2024     │ FIPS 203/204/205 published (ML-KEM, ML-DSA, SLH-DSA)│
│ Sep-Oct 2024 │ Chrome/Firefox ship X25519+ML-KEM-768 hybrid     │
│ 2025         │ OpenSSL 3.5+ PQC provider mainstream              │
│ 2026         │ Production hybrid everywhere                     │
│ 2027-2029    │ State actors begin PQC-only for high security    │
│ 2030-2032    │ NSA's CNSA 2.0 mandates pure PQC for NSS         │
│ 2030+        │ CRQC (cryptographically relevant quantum) emergence │
│ 2033         │ NIST classical-only ban di NSS complete          │
│ 2035         │ QKD networks production-ready (limited use)      │
│ 2040s        │ Pure PQC + QKD mostly standard                    │
└──────────────────────────────────────────────────────────────────┘
```

### 10.1 Rekomendasi Migrasi Berdasarkan Level Confidentiality

| Confidentiality horizon | Pure PQC mulai produksi | Hybrid production |
| :---------------------: | :---------------------: | :---------------: |
|        <5 years         |          2030           |       2026        |
|       5-10 years        |          2028           |       2025        |
|       10-15 years       |          2026           |       2024        |
|       15-30 years       |          2025           |       2024        |
|        30+ years        |          2024           |       2024        |

---

## 11. Decision Tree — Kapan Migrasi ke Apa

```
                START
                  │
          Confidentiality >15 years? (HNDL relevan)
                /       \
             Yes         No
              │           │
        Long-term       Short-term
              │          ("secure-classical OK for now")
              │              │
    Pure PQC, today      Hybrid tahun ini
    (X25519+ML-KEM)      (X25519+ML-KEM+ML-DSA)
              │              │
       ● Disk encryption unchanged
       ● KMS wrapping key → ML-KEM
       ● Cert → ML-DSA (signed)
       ● Backup → wrap key ML-KEM
              │
        QKD feasible infra?
              / \
           Yes   No
            │     │
     Use QKD for    Pure-PQC
     backbone       suffit
```

---

## 12. Cross-Reference ke Vault

| Layer | Catatan Vault                                                        |
| :---: | -------------------------------------------------------------------- |
| **0** | [[math-and-algorithms]]                                              |
| **1** | [[hierarchy-cryptography]], [[hierarchy-digital-plumbing]] (OpenSSL) |
| **2** | (hybrid-specific belum ada, mungkin tambah nanti)                    |
| **3** | [[post-quantum-tls]] (calon ada), [[quantum-cryptography]]           |
| **4** | [[quantum-machine-learning]], [[quantum-cryptography]]               |
| **5** | [[tls-ssl-deepdive]], [[http-protocol-deepdive]]                     |
| **6** | [[hierarchy-cybersecurity-defense-architecture]] (L3 + L8)           |

---

## References

1. NIST. _"FIPS 203: Module-Lattice-Based Key-Encapsulation Mechanism (ML-KEM)."_ (2024).
2. NIST. _"FIPS 204: Module-Lattice-Based Digital Signature (ML-DSA)."_ (2024).
3. NIST. _"FIPS 205: Stateless Hash-Based Digital Signature (SLH-DSA)."_ (2024).
4. Shor. _"Polynomial-Time Algorithms for Prime Factorization."_ FOCS 1994.
5. Grover. _"A Fast Quantum Mechanical Algorithm for Database Search."_ STOC 1996.
6. NIST. _"Post-Quantum Cryptography."_ https://csrc.nist.gov/projects/post-quantum-cryptography
7. CNSS. _"CNSA 2.0: Quantum-Resistant Cryptography."_ (2022-2024).
8. ETSI. _"Quantum Key Distribution (QKD); Use Cases."_ (2024).
9. IETF. _"draft-ietf-tls-hybrid-kem."_ (2024).
10. Cloudflare. _"Post-Quantum TLS Performance."_ (2024).
11. Google. _"Post-Quantum in Chrome."_ (2024).
12. AWS. _"Hybrid Post-Quantum TLS in CloudFront."_ (2024).
13. CISA. _"Quantum-Readiness Migration to PQC."_ (2024).
14. NSA. _"Quantum Computing and Post-Quantum Cryptography FAQ."_ (2024).
15. Open Quantum Safe Project. _"liboqs documentation."_ https://openquantumsafe.org/
