---
title: Post-Quantum TLS — Implementasi Transport Security Pasca-Kuantum
tags:
  - cryptography
  - post-quantum
  - tls
  - kyber
  - dilithium
  - rustls
  - pqc
aliases:
  - post-quantum-tls
created: '2026-08-04'
updated: '2026-08-04'
status: pending
cssclasses:
  - wide-table
  

---

# 🔐 Post-Quantum TLS — Implementasi Transport Security Pasca-Kuantum

> **Panduan praktis membangun TLS 1.3 dengan KEM (Kyber) + Signature (Dilithium/Falcon) untuk menghadapi era kuantum.** Bukan teori murni — ini implementasi level produksi: hybrid key exchange, certificate chain migration, performance tuning, dan interoperabilitas dengan legacy client. Untuk fondasi matematika, lihat [[quantum-cryptography-primer]] dan [[hierarchy-quantum-cryptography-stack]]. Untuk implementasi Rust, lihat [[pqc-implementation-rust]].

---

## Daftar Isi

- [[#1. Arsitektur Hybrid TLS 1.3 PQC]]
- [[#2. KEM: Kyber — Key Encapsulation Mechanism]]
- [[#3. Signature: Dilithium & Falcon]]
- [[#4. Certificate Chain Migration]]
- [[#5. Hybrid Key Exchange di Rustls / BoringSSL]]
- [[#6. Performance Benchmark & Tuning]]
- [[#7. Interoperabilitas & Fallback Strategy]]
- [[#8. Deployment Checklist Produksi]]

---

## 1. Arsitektur Hybrid TLS 1.3 PQC

### 1.1 Mengapa Hybrid?

```text
┌─────────────────────────────────────────────────────────────────┐
│  TLS 1.3 Classic (Pre-Quantum)                                  │
│  ─────────────────────────────────────────────────────────────  │
│  ClientHello → ServerHello → EncryptedExtensions → Finished    │
│         │              │                    │                   │
│         ▼              ▼                    ▼                   │
│   (EC)DHE          Certificate         Application Data         │
│   Key Exchange     Verify              (AES-GCM / ChaCha20)     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  TLS 1.3 Hybrid PQC (IETF Draft / RFC 9370 style)              │
│  ─────────────────────────────────────────────────────────────  │
│  ClientHello → ServerHello → EncryptedExtensions → Finished    │
│         │              │                    │                   │
│         ▼              ▼                    ▼                   │
│   Hybrid KEM       Hybrid Cert         Application Data         │
│   (Classical +     Chain (Classical    (AES-GCM / ChaCha20)     │
│    PQC Kyber)      + PQC Dilithium)                          │
└─────────────────────────────────────────────────────────────────┘
```

**Prinsip Hybrid:** `shared_secret = KDF(classical_shared || pqc_shared)`. Jika salah satu broken (misal CRQC memecahkan ECDH), PQC component masih aman. **Harus-bukan-boleh** — transitional period 2024-2030+ butuh dual protection.

### 1.2 Threat Model

| Threat | Classical TLS | Hybrid PQC TLS |
|--------|---------------|----------------|
| Passive eavesdrop (record now, decrypt later) | 🔴 Vulnerable (CRQC future) | 🟢 Safe — PQC KEM unbroken |
| Active MitM (certificate forge) | 🟡 Hard (CA compromise) | 🟢 Safe — Dilithium sig unforgeable |
| Downgrade attack | 🟡 Possible | 🟢 Hybrid nego fail = abort |
| Side-channel (timing, cache) | 🟡 ECDH vulnerable | 🟡 Kyber/Dilithium butuh constant-time impl |

---

## 2. KEM: Kyber — Key Encapsulation Mechanism

### 2.1 Parameter Set (NIST PQC Standardization)

| Variant | NIST Security Level | Public Key (bytes) | Ciphertext (bytes) | Shared Secret (bytes) | Target |
|---------|---------------------|-------------------|-------------------|----------------------|--------|
| **Kyber-512** | 1 (AES-128 equiv) | 800 | 768 | 32 | TLS 1.3 hybrid (low latency) |
| **Kyber-768** | 3 (AES-192 equiv) | 1184 | 1088 | 32 | **Recommended default** |
| **Kyber-1024** | 5 (AES-256 equiv) | 1568 | 1568 | 32 | High security, higher latency |

> [!tip] Kyber-768 adalah **sweet spot** untuk TLS: overhead ~1.2KB per handshake vs ~200 bytes ECDH, tapi security margin besar. Kyber-512 cukup untuk kebanyakan deployment tapi margin tipis (level 1).

### 2.2 Kyber Internal Structure (Module-LWE)

```text
Kyber KEM = Module-LWE over R_q = Z_q[X]/(X^n+1) dengan n=256, q=3329

KeyGen():
  1. Sample s ← η_1 (secret), e ← η_1 (error)
  2. A ← uniform matrix (seed ρ)
  3. t = A·s + e          → public key = (ρ, t)
  4. sk = (s, ρ, t, hash(pk))

Encaps(pk):
  1. Sample r ← η_1, e1 ← η_2, e2 ← η_2
  2. u = A^T·r + e1
  3. v = t^T·r + e2 + encode(m)
  4. ct = (u, v)
  5. K = H(m || H(ct))

Decaps(sk, ct):
  1. m' = v - s^T·u
  2. m' = decode(m')
  3. Re-encapsulate dengan m' → ct'
  4. If ct == ct': return K = H(m' || H(ct))
     Else: return K = H(z || H(ct))  # implicit rejection (FO transform)
```

### 2.3 Constant-Time Implementation Requirements

| Operation | Vulnerability | Mitigasi |
|-----------|---------------|----------|
| NTT (Number Theoretic Transform) | Timing via coefficient access | Fixed-loop NTT, no data-dependent branches |
| Polynomial sampling (CBD) | Rejection sampling timing | Constant-time binomial sampling |
| FO Transform (re-encapsulation) | Branch on ct comparison | Constant-time compare + select |
| Hash (SHA3-256/512) | — | Hardware SHA3 (SHA-NI) atau portable constant-time |

> **Referensi implementasi:** `pqc-rust/kyber` crate, `liboqs`, `BoringSSL` PQC branch. Semua production-grade sudah constant-time.

---

## 3. Signature: Dilithium & Falcon

### 3.1 Dilithium (Primary — Lattice-based)

| Variant | NIST Level | Public Key | Signature | Use Case |
|---------|------------|-----------|-----------|----------|
| **Dilithium-2** | 2 | 1312 B | 2420 B | TLS server cert (recommended) |
| **Dilithium-3** | 3 | 1952 B | 3293 B | Root CA, long-term |
| **Dilithium-5** | 5 | 2592 B | 4595 B | Maximum security |

**Struktur Dilithium:** Module-LWE + Module-SIS dengan *Fiat-Shamir with Aborts* — rejection sampling membuat signature size variable tapi bounded.

### 3.2 Falcon (Alternative — NTRU Lattice)

| Variant | NIST Level | Public Key | Signature | Note |
|---------|------------|-----------|-----------|------|
| **Falcon-512** | 1 | 897 B | ~666 B | Smaller sig, but floating-point NTT (harder constant-time) |
| **Falcon-1024** | 5 | 1793 B | ~1280 B | High security |

> [!warning] Falcon butuh **floating-point arithmetic** untuk NTT — sulit constant-time di side-channel resistant hardware. Dilithium preferred untuk TLS certificate (integer-only). Falcon cocok untuk embedded/space-constrained.

### 3.3 Hybrid Certificate Chain

```text
┌────────────────────────────────────────────────────────────┐
│  Hybrid X.509 Certificate (IETF draft-ietf-lamps-pqc)     │
│  ────────────────────────────────────────────────────────  │
│  Subject: server.example.com                               │
│  Issuer: Hybrid CA                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ SubjectPublicKeyInfo:                                │  │
│  │   Algorithm: id-KEM-Kyber768 + id-SIG-Dilithium2    │  │
│  │   Public Key:  [Kyber PK || Dilithium PK]           │  │
│  └──────────────────────────────────────────────────────┘  │
│  Extensions:                                               │
│  - SubjectAltName: DNS:server.example.com                 │
│  - KeyUsage: keyEncipherment, digitalSignature            │
│  - ExtendedKeyUsage: serverAuth                           │
│  - 1.3.6.1.5.5.7.1.24 (TLS Feature) — hybrid flag        │
└────────────────────────────────────────────────────────────┘
```

**Migration Path:**
1. **Phase 1 (2024-2026):** Dual cert — classical (RSA/ECDSA) + PQC (Dilithium) di server, client negotiate hybrid
2. **Phase 2 (2026-2028):** Hybrid cert tunggal (composite key), legacy client fallback ke classical-only
3. **Phase 3 (2028+):** PQC-only, classical deprecated

---

## 4. Certificate Chain Migration

### 4.1 Composite Key vs Dual Cert

| Approach | Pros | Cons |
|----------|------|------|
| **Dual Certificate** (2 cert di chain) | Compatible dengan legacy client, rollback mudah | Chain size 2x, management complexity |
| **Composite Key** (1 cert, 2 PK) | Single cert, smaller chain | Butuh client support composite OID, CA tooling update |
| **Hybrid KEM + Classical Sig** | Transitional, minimal change | Tidak full PQC — sig masih classical |

**Rekomendasi produksi 2026:** **Dual Certificate** — sudah didukung `rustls-pqc`, `BoringSSL`, `OpenSSL 3.5+`. CA seperti DigiCert, GlobalSign sudah pilot.

### 4.2 CA Infrastructure Update

```bash
# Generate hybrid CA (conceptual — tooling belum standar)
# Step 1: Classical CA
openssl genpkey -algorithm ED25519 -out ca_classical.key
openssl req -x509 -new -key ca_classical.key -sha256 -days 3650 -out ca_classical.crt

# Step 2: PQC CA (Dilithium) — butuh liboqs/oqs-provider
# openssl genpkey -provider oqs -algorithm dilithium2 -out ca_pqc.key
# openssl req -x509 -new -key ca_pqc.key -provider oqs -days 3650 -out ca_pqc.crt

# Step 3: Issue hybrid server cert
# Server CSR dengan composite key (Kyber768 + Dilithium2)
# CA sign dengan dual key (classical + PQC)
```

> **Real-world:** Gunakan `oqs-provider` (OpenSSL 3) atau `oqs-rust` untuk generate. CA production pakai HSM yang support PQC (Utimaco, Thales, Futurex — firmware update 2024+).

---

## 5. Hybrid Key Exchange di Rustls / BoringSSL

### 5.1 Rustls PQC (rustls-pqc / aws-lc-rs PQC)

```rust
// Cargo.toml
[dependencies]
rustls = { version = "0.23", features = ["tls12", "aws-lc-rs"] }
aws-lc-rs = { version = "0.23", features = ["pqc"] }  # PQC enabled
# Atau: rustls-pqc = "0.1" (fork terpisah)

// Hybrid Key Exchange Configuration
use rustls::crypto::aws_lc_rs::cipher_suite::TLS13_AES_256_GCM_SHA384;
// PQC cipher suites belum distandarkan di rustls 0.23 stable — pakai branch pqc-experimental

// Contoh konfigurasi server hybrid
let config = rustls::ServerConfig::builder()
    .with_safe_defaults()
    .with_no_client_auth()
    .with_single_cert(certs, key)?;  // cert harus hybrid (dual)

// Client: enable hybrid KEM groups
let mut root_store = rustls::RootCertStore::empty();
root_store.add(&ca_cert)?;
let config = rustls::ClientConfig::builder()
    .with_root_certificates(root_store)
    .with_no_client_auth();
```

### 5.2 Supported Hybrid Groups (Draft IETF)

| Group Name | Classical | PQC | IANA Code (Draft) |
|------------|-----------|-----|-------------------|
| `X25519Kyber768Draft00` | X25519 | Kyber-768 | 0x6399 |
| `SecP256r1Kyber768Draft00` | P-256 | Kyber-768 | 0x639A |
| `X25519Kyber512Draft00` | X25519 | Kyber-512 | 0x639B |

> **Status 2026:** `X25519Kyber768Draft00` adalah **de facto standard** — didukung Cloudflare, Google, AWS, Mozilla. RFC 9370 akan menormalkannya.

### 5.3 BoringSSL / Google Implementation

```cpp
// BoringSSL hybrid KEM (internal)
SSL_CTX_set1_groups_list(ctx, "X25519Kyber768Draft00:X25519:P-256");

// ClientHello akan mengirim supported_groups:
//   0x6399 (X25519Kyber768Draft00), 0x001D (X25519), 0x0017 (P-256)

// Server memilih hybrid group jika client support
```

---

## 6. Performance Benchmark & Tuning

### 6.1 Handshake Overhead Comparison

| Cipher Suite | ClientHello Size | ServerHello Size | Total Handshake Bytes | CPU Cycles (est.) |
|--------------|------------------|------------------|----------------------|-------------------|
| TLS13-AES256-GCM-SHA384 (X25519) | ~200 B | ~300 B | ~1.2 KB | 500K |
| **X25519Kyber768Draft00** | **~1.1 KB** | **~1.4 KB** | **~3.5 KB** | **1.8M** |
| X25519Kyber512Draft00 | ~900 B | ~1.1 KB | ~3.0 KB | 1.4M |
| P-256 + Kyber768 | ~1.1 KB | ~1.4 KB | ~3.5 KB | 2.1M |

**Overhead:** ~2-3x handshake bytes, ~3-4x CPU cycles. **Tapi:** handshake cuma sekali per session — session resumption (PSK) amortisasi overhead.

### 6.2 Optimasi Produksi

```rust
// 1. Session Resumption (PSK) — wajib enable
let config = rustls::ServerConfig::builder()
    .with_safe_defaults()
    .with_client_cert_verifier(Arc::new(verifier))
    .with_single_cert(certs, key)?;
config.max_early_data_size = 0;  // disable 0-RTT untuk security
config.ticketer = rustls::Ticketer::new();  // session ticket

// 2. Connection Pooling / Keep-Alive
// HTTP/2 + TLS hybrid: satu handshake, banyak request

// 3. Hardware Acceleration
// - AWS Nitro Enclaves: AES-NI + SHA-NI
// - Intel QAT: offload Kyber NTT (experimental)
// - ARMv8.4-A: SHA3/SM3 instructions

// 4. Certificate Compression (RFC 8879)
// Compress certificate chain sebelum kirim
// openssl s_client -cert_compression zlib
```

### 6.3 Real-World Latency (Cloudflare Data 2024)

| Metric | Classical | Hybrid (X25519Kyber768) | Delta |
|--------|-----------|-------------------------|-------|
| Handshake latency (p50) | 12 ms | 18 ms | +50% |
| Handshake latency (p99) | 45 ms | 78 ms | +73% |
| CPU per handshake | 0.8 ms | 2.1 ms | +162% |
| Session resumption hit | 85% | 85% | = |

> **Kesimpulan:** Overhead signifikan tapi **acceptable untuk security-critical**. Session resumption mitigasi 85% handshake.

---

## 7. Interoperabilitas & Fallback Strategy

### 7.1 Client Support Matrix (2026)

| Client | Hybrid Support | Version |
|--------|----------------|---------|
| **Chrome** | ✅ X25519Kyber768Draft00 | 116+ (flag), 120+ default |
| **Firefox** | ✅ X25519Kyber768Draft00 | 118+ (flag), 125+ default |
| **Safari** | 🟡 Experimental | 17+ (behind flag) |
| **curl** | ✅ via BoringSSL | 8.6+ |
| **Python requests** | 🟡 Butuh `urllib3` + `pyopenssl` PQC | 2.31+ |
| **Go stdlib** | ✅ X25519Kyber768 | 1.22+ |
| **Rust reqwest** | ✅ via rustls-pqc | 0.12+ |
| **OpenSSL** | ✅ via oqs-provider | 3.5+ |
| **Java** | 🟡 JDK 21+ (experimental) | 21+ |

### 7.2 Fallback Strategy

```text
┌─────────────────────────────────────────────────────────────┐
│  Server Config: Hybrid Priority                             │
│  ─────────────────────────────────────────────────────────  │
│  supported_groups = [                                       │
│    "X25519Kyber768Draft00",  # 1st: Hybrid PQC              │
│    "X25519",                 # 2nd: Classical modern        │
│    "P-256"                   # 3rd: Classical legacy        │
│  ]                                                          │
│                                                             │
│  ClientHello supported_groups:                              │
│  - Modern browser: [X25519Kyber768, X25519, P-256]         │
│    → Server pilih X25519Kyber768 ✅                         │
│  - Legacy client (curl 7.68): [X25519, P-256]              │
│    → Server pilih X25519 ⚠️ (classical only)                │
│  - Very old (IE11): [P-256]                                │
│    → Server pilih P-256 ⚠️ (classical only)                 │
└─────────────────────────────────────────────────────────────┘
```

**Policy:** Tidak pernah fallback ke *non-hybrid* jika client support hybrid. Hanya fallback jika client **tidak** mengirim hybrid group.

---

## 8. Deployment Checklist Produksi

```text
☐ CA Infrastructure: Dual cert issuance (classical + PQC) atau composite key
☐ Server Cert: Hybrid certificate chain deployed
☐ TLS Library: rustls 0.23+pqc / BoringSSL / OpenSSL 3.5+oqs-provider
☐ Cipher Suites: X25519Kyber768Draft00 enabled, priority #1
☐ Session Resumption: PSK tickets enabled, lifetime 24h
☐ Certificate Compression: RFC 8879 enabled (zlib/brotli)
☐ Monitoring: Handshake latency p50/p99, hybrid negotiation rate
☐ Fallback Testing: Legacy client (curl 7.68, Python 3.8) still connect
☐ HSM: PQC firmware loaded (Utimaco/Thales/Futurex 2024+)
☐ Cert Rotation: Automation untuk dual cert (cert-manager + pqc issuer)
☐ Incident Response: Playbook untuk PQC key compromise (rotate both keys)
```

---

## Cross-Link

- **Matematika Dasar** → [[quantum-cryptography-primer]], [[hierarchy-quantum-cryptography-stack]]
- **Implementasi Rust** → [[pqc-implementation-rust]], WAF deepdive (privat)
- **Certificate Mgmt** → [[linux-hardening-audit-praktis]], [[hardening-setup]]
- **Quantum Timeline** → [[quantum-cryptography-roadmap]], [[post-quantum-tls-implementation]]
- **Master Index** → [[master-index]]

---

*Post-Quantum TLS · Hybrid = Classical + PQC · Kyber-768 + Dilithium-2 = Sweet Spot · Session Resumption = Overhead Killer · Dual Cert = Migration Path · 2026 = Production Ready*
---

audited
---
