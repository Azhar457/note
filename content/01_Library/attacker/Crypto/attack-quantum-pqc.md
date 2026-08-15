---
title: Attack Perspective — Quantum Crypto & PQC (Red Team)
tags:
- attack
- red-team
- quantum
- pqc
- harvest-now
- shor
- kyber
- hybrid
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---
# Quantum Crypto & PQC — Perspektif Penyerang

> Ancaman kuantum = HNDL (Harvest-Now-Decrypt-Later) aktif sekarang. Setiap TLS traffic direkam hari ini → terbuka saat quantum cukup besar. Red team: passive recording, PQC implementation bug, side-channel lattice, downgrade attack.

## 1. Timeline Ancaman

```
SEKARANG (2024-2026):
  ├── HNDL aktif — passive TLS recording
  ├── RSA/ECC masih aman (classical)
  └── PQC hybrid (X25519 + Kyber) mulai deploy
    ↓
2026-2030:
  ├── PQC migration gap — belum migrasi = vulnerable
  ├── PQC implementasi bug (kode baru)
  └── Side-channel lattice (algoritma baru = leak baru)
    ↓
2030-2035:
  ├── Shor's → RSA/ECC mati (quantum besar)
  ├── Grover's → AES-256 → 128-bit (masih aman)
  └── Semua traffic HNDL → terbuka
```

## 2. Attack Vector

| Vektor | Konkret | Evasion | Detection Gap |
|--------|---------|---------|----------------|
| **HNDL** | Rekam TLS → simpan → decrypt saat quantum | Pasif = no trace | Tidak bisa deteksi |
| **Migration Gap** | Orgs belum PQC → RSA traffic vulnerable | N/A (pasif) | Orgs tidak aware |
| **PQC Bug** | Implementasi baru → overflow, timing leak | Custom exploit | No signature |
| **Side-channel Lattice** | Kyber/Dilithium timing/cache leak | Hardware = no EDR | Hardware-level |
| **Downgrade** | Fallback ke classic → HNDL window | Downgrade = silent | TLS version monitor = rare |
| **Hybrid Weakness** | Hybrid = salah satu component lemah → downgrade | Component attack | Hybrid audit = rare |

## 3. NIST PQC Standards

| Standard | Algoritma | Tipe | Key Size |
|----------|-----------|------|----------|
| FIPS 203 | ML-KEM (Kyber) | KEM | 1568 bytes |
| FIPS 204 | ML-DSA (Dilithium) | Signature | 1312 bytes |
| FIPS 205 | SLH-DSA (SPHINCS+) | Signature | 7856 bytes |
| FIPS 206 | Falcon | Signature | 617 bytes |

## 4. Attack Chain (HNDL + Migration Gap)

```
Passive Recording:
  ├── Network tap / ISP / Wi-Fi → capture TLS
  ├── Store: encrypted traffic + metadata
  └→ No detection (passive)
    ↓
Target Selection:
  ├── High-value: bank, gov, military, corporate VPN
  ├── Long-lived: keys used for years
  └→ Prioritize: data still sensitive in 2030+
    ↓
Future Decrypt (quantum ready):
  ├── Shor's → factor RSA / solve ECC → private key
  ├── Decrypt stored traffic
  └→ Full historical data exposure
    ↓
Active Attack (now):
  ├── Downgrade TLS 1.3 → 1.2 → weaker cipher → easier future
  ├── Downgrade hybrid → classic only → HNDL window
  └→ SSL strip → plaintext → immediate
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **liboqs** | PQC implementation (test/bug hunt) |
| **oqs-provider** | OpenSSL PQC integration |
| **Qiskit / Cirq** | Quantum algorithm simulation (Shor's) |
| **testssl.sh** | TLS cipher/version audit (downgrade path) |
| **tshark** | TLS traffic capture (HNDL storage) |

## 6. Referensi
- NIST PQC — https://csrc.nist.gov/projects/post-quantum-cryptography
- FIPS 203 — https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf
- liboqs — https://github.com/open-quantum-safe/liboqs
- Cloudflare PQC — https://blog.cloudflare.com/pq-2024/
- HNDL — https://en.wikipedia.org/wiki/Harvest_now,_decrypt_later

## Konkret — Harvest Now, Decrypt Later (Testable)

### Quantum Threat Timeline

```
Current: RSA-2048, ECC-256 (ECDH) — aman dari komputer klasik
Shor (quantum): pemfaktoran dalam O(log N) → RSA/ECC broken
Grover (quantum): brute force quadratic speedup → AES-128 → AES-256 equivalent

Timeline estimasi (IBM/Google roadmap):
- 2025-2030: 1000-10000 qubit (noisy)
- 2030-2035: fault-tolerant → Shor viable
- 2035-2045: RSA-2048 breakable dalam <1 jam

Target: Harvest Now, Decrypt Later (HNDL)
- Store TLS traffic encrypted → decrypt later (5-10 years)
- Secret: symmetric keys, long-lived secrets (diplomacy, intelligence)
```

### Kyber / Dilithium (NIST PQC Standard)

```bash
# NIST 2024: FIPS 203 (Kyber / ML-KEM), FIPS 204 (Dilithium / ML-DSA)
# 1. Open Quantum Safe (liboqs)
git clone https://github.com/open-quantum-safe/liboqs
cd liboqs && mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja install

# 2. OQS-provider (OpenSSL 3.x patch)
git clone https://github.com/open-quantum-safe/oqs-provider
# Build + install → enable Kyber/Dilithium di OpenSSL

# 3. TLS handshake dengan Kyber
openssl s_client -connect host:443 -groups kyber768
# 4. Sign dengan Dilithium
openssl req -new -key key.pem -out csr.pem -sigopt dilithium3
```

### Hybrid (Transition Strategy)

```
# X25519Kyber768Draft00 — Cloudflare/Google hybrid
# TLS 1.3 hybrid key exchange: classical (X25519) + PQ (Kyber768)
# Jika Kyber broken: X25519 masih aman
# Jika X25519 broken (quantum): Kyber masih aman

# Test hybrid:
openssl s_client -connect cloudflare.com:443 -groups X25519Kyber768Draft00
# Hasil: kunci hybrid, aman dari kedua threat model
```
---

audited
---
