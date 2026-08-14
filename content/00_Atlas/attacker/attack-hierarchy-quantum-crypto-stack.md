---
title: Attack Perspective — Quantum Cryptography Stack (Red Team)
tags: [attack,red-team,quantum,pqc,harvest-now,shor]
source: hierarchy-quantum-cryptography-stack.md + hierarchy-quantum-cryptography.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Quantum Crypto Stack — Perspektif Penyerang

> Ancaman kuantum bukan teori masa depan — **Harvest-Now-Decrypt-Later (HNDL)** aktif sekarang. Setiap traffic TLS yang direkam hari ini akan terbuka saat quantum computer cukup besar (~2030-2035).

## 1. Timeline Ancaman Kuantum

```
SEKARANG (2024-2026):
 ├── HNDL aktif — passive TLS recording (no detection)
 ├── RSA-2048/ECC-256 masih aman dari serangan klasik
 └── PQC hybrid mode (X25519 + Kyber) mulai deploy di browser

2026-2030:
 ├── PQC migration gap — orgs yang belum migrasi = vulnerable
 ├── Implementasi bug PQC (kode baru, belum battle-tested)
 └── Side-channel pada lattice crypto (algoritma baru = leak baru)

2030-2035?:
 ├── Shor's algorithm → RSA/ECC mati (jika quantum cukup besar)
 ├── Grover's → AES-256 menjadi 128-bit (masih aman)
 └── Semua traffic HNDL → terbuka
```

## 2. Attack Vector Kuantum

| Vektor | Mitre/Threat | Konkret | Evasion | Detection Gap |
|--------|-------------|---------|---------|----------------|
| **HNDL** | Passive interception | Rekam TLS traffic → simpan → decrypt saat quantum aktif | Pasif — tidak ada trace | Tidak bisa deteksi (recording = no interaction) |
| **PQC migration gap** | T1201 (Exploit) | Orgs belum migrasi PQC → RSA/ECC traffic → HNDL vulnerable | N/A — serangan pasif | Orgs tidak aware traffic sudah direkam |
| **PQC implementasi bug** | T1190 (Exploit) | Kode PQC baru → buffer overflow, timing leak, side-channel | Custom exploit pada implementasi baru | Belum ada signature untuk PQC exploit |
| **Side-channel lattice** | T1542 (Hardware) | Lattice crypto (Kyber/Dilithium) → timing/cache leak — algoritma baru = side-channel baru | Hardware-level = no EDR signal | Side-channel = hardware, EDR blind |
| **Grover's (symmetric)** | N/A | AES-256 → 128-bit security (masih aman) — AES-128 → 64-bit (mati) | N/A — quantum attack | Quantum computer belum ada |

## 3. PQC Migration Attack Surface

| Komponen | Status Migrasi | Attack Surface | Red Team Opportunity |
|----------|---------------|----------------|---------------------|
| **Browser (TLS)** | Hybrid (X25519 + Kyber) rolling out | Implementasi bug, fallback ke classic | Intercept → downgrade ke non-PQC |
| **VPN (WireGuard/IPsec)** | Belum migrasi | Semua VPN traffic = HNDL vulnerable | Passive recording → decrypt later |
| **SSH** | OpenSSH 9.0+ hybrid | Server lama = classic only | Passive record → Shor's later |
| **KMS/HSM** | Vendor mulai PQC | Key rotation gap → classic key stored | HNDL → key extraction later |
| **Code signing** | Belum migrasi | Signature forgeable post-quantum | Forge signature saat quantum aktif |
| **Blockchain** | Belum migrasi (ECC) | Wallet key forgeable post-quantum | Quantum → forge signature → steal fund |

## 4. NIST PQC Standards (2024)

| Standard | Algoritma | Tipe | Use Case | Size (key/sig) |
|----------|-----------|------|----------|----------------|
| **FIPS 203** | ML-KEM (Kyber) | Lattice-based | Key encapsulation | 1568 bytes (key) — jauh lebih besar dari X25519 (32 byte) |
| **FIPS 204** | ML-DSA (Dilithium) | Lattice-based | Digital signature | 1312 bytes (sig) — jauh lebih besar dari Ed25519 (64 byte) |
| **FIPS 205** | SLH-DSA (SPHINCS+) | Hash-based | Digital signature (stateless) | 7856 bytes (sig) — sangat besar |
| **FIPS 206** | Falcon | Lattice-based (NTRU) | Digital signature (compact) | 617 bytes (sig) |

## 5. Tool Stack Quantum Attack (Conceptual)

| Tool/Platform | Use | Status |
|---------------|-----|--------|
| **Quantum simulator** (Qiskit, Cirq, Q#) | Simulasi Shor's/Grover's | Aktif — research, terlalu lambat untuk real attack |
| **Passive TLS recorder** | Capture + store TLS traffic | Aktif — HNDL, any network tap |
| **PQC implementation fuzzer** | Bug hunting di PQC library | Aktif — oqs-provider, liboqs |
| **Side-channel analyzer** | Timing/cache analysis PQC | Aktif — research, ChipWhisperer |

## 6. Referensi
- NIST PQC — https://csrc.nist.gov/projects/post-quantum-cryptography
- FIPS 203 (Kyber) — https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf
- FIPS 204 (Dilithium) — https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.204.pdf
- liboqs (Open Quantum Safe) — https://github.com/open-quantum-safe/liboqs
- Qiskit (IBM Quantum) — https://qiskit.org/
- Cloudflare PQC Deployment — https://blog.cloudflare.com/pq-2024/