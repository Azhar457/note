---
title: "Post-Quantum Cryptography (PQC) Implementation in Rust \u2014 Kyber & Dilithium"
tags:
- quantum-cryptography
- post-quantum-crypto
- kyber
- dilithium
- rust
- benchmark
- security
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout
  - code-wrap

verification:
  status: unverified
  last_checked: '2026-08-12'
  confidence: LOW
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Teori kriptografi pasca-kuantum sangat penting untuk dipahami secara konseptual. Namun, tanpa kode praktis, implementasi nyata tidak akan terwujud. Catatan ini menyediakan panduan implementasi langsung kriptografi pasca-kuantum (PQC) menggunakan bahasa Rust, melengkapi pembahasan teori mendalam di [[quantum-cryptography-deepdive]].

## Daftar Isi

1. [Implementasi KEM Kyber dengan Rust](#1-implementasi-kem-kyber-dengan-rust)
2. [Benchmark Performa: PQC vs Klasik (RSA/ECC)](#2-benchmark-performa-pqc-vs-klasik-rsaecc)
3. [Roadmap Migrasi PQC di Lingkungan Produksi](#3-roadmap-migrasi-pqc-di-lingkungan-produksi)
4. [Koneksi ke Vault](#4-koneksi-ke-vault)

---

## 1. Implementasi KEM Kyber dengan Rust

**Kyber** (bagian dari standar ML-KEM oleh NIST) adalah algoritma *Key Encapsulation Mechanism* (KEM) berbasis kisi (*lattice-based*) yang digunakan untuk menyepakati kunci simetris secara aman dari ancaman komputer kuantum (*Shor's Algorithm*).

Berikut adalah contoh implementasi lengkap proses negosiasi kunci (*key exchange*) menggunakan crate `pqc_kyber` di Rust.

### 1.1 Konfigurasi `Cargo.toml`
```toml
[package]
name = "pqc-rust-demo"
version = "0.1.0"
edition = "2021"

[dependencies]
# pqc_kyber menyediakan implementasi Kyber NIST Round 3 yang aman dan cepat
pqc_kyber = "0.7.0" 
rand = "0.8"
```

### 1.2 Kode Implementasi KEM (`src/main.rs`)
```rust
use pqc_kyber::{decapsulate, encapsulate, keypair, KyberError};
use rand::thread_rng;

fn main() -> Result<(), KyberError> {
    let mut rng = thread_rng();

    println!("=== Memulai Proses Post-Quantum KEM (Kyber-768) ===");

    // 1. Penerima (Bob) men-generate keypair (Public Key & Secret Key)
    // Kyber-768 setara dengan tingkat keamanan AES-192
    let keys_bob = keypair(&mut rng)?;
    let public_key_bob = keys_bob.public;
    let secret_key_bob = keys_bob.secret;
    println!("1. Bob berhasil membuat keypair.");
    println!("   Public Key Size: {} bytes", public_key_bob.len());
    println!("   Secret Key Size: {} bytes", secret_key_bob.len());

    // 2. Pengirim (Alice) menggunakan Public Key Bob untuk mengekapsulasi kunci rahasia
    // Menghasilkan Ciphertext (yang dikirim ke Bob) dan Shared Secret Key milik Alice
    let (ciphertext, shared_secret_alice) = encapsulate(&public_key_bob, &mut rng)?;
    println!("2. Alice mengekapsulasi shared secret menggunakan Public Key Bob.");
    println!("   Ciphertext Size: {} bytes", ciphertext.len());
    println!("   Alice Shared Secret (Hex): {:x?}", &shared_secret_alice[0..16]);

    // 3. Bob menerima Ciphertext dari Alice, lalu men-dekapsulasi menggunakan Secret Key miliknya
    // Menghasilkan Shared Secret Key milik Bob
    let shared_secret_bob = decapsulate(&ciphertext, &secret_key_bob)?;
    println!("3. Bob men-dekapsulasi ciphertext menggunakan Secret Key miliknya.");
    println!("   Bob Shared Secret (Hex):   {:x?}", &shared_secret_bob[0..16]);

    // 4. Verifikasi bahwa kedua shared secret adalah sama
    assert_eq!(shared_secret_alice, shared_secret_bob);
    println!("\n[SUKSES] Kunci rahasia berhasil disepakati!");
    println!("Shared Secret cocok dan siap digunakan untuk enkripsi simetris (AES-GCM).");

    Ok(())
}
```

---

## 2. Benchmark Performa: PQC vs Klasik (RSA/ECC)

Algoritma berbasis kisi (*lattice*) memiliki karakteristik performa yang berbeda signifikan dibanding algoritma klasik berbasis pemfaktoran prima (RSA) atau kurva eliptik (ECDH/ECDSA).

### 2.1 Tabel Perbandingan Kinerja

| Parameter | RSA-3072 | ECDH (X25519) | **ML-KEM (Kyber-768)** | **ML-DSA (Dilithium3)** |
|-----------|----------|---------------|------------------------|-------------------------|
| **Fungsi** | Enkripsi/KEM/Sig | Key Exchange (KEM) | **Key Exchange (KEM)** | **Digital Signature** |
| **Keamanan Kuantum**| ❌ Tidak Aman | ❌ Tidak Aman | **✅ Aman (ML-KEM)** | **✅ Aman (ML-DSA)** |
| **Waktu Gen Key** | Sangat Lambat (ms) | Cepat (μs) | **Cepat (μs)** | **Cepat (μs)** |
| **Waktu Enc/Sign** | Cepat (μs) | Cepat (μs) | **Sangat Cepat (μs)** | **Sangat Cepat (μs)** |
| **Waktu Dec/Verify**| Lambat (ms) | Cepat (μs) | **Sangat Cepat (μs)** | **Cepat (μs)** |
| **Public Key Size** | 384 bytes | 32 bytes | **1,184 bytes** | **1,952 bytes** |
| **Ciphertext/Sig** | 384 bytes | 32 bytes | **1,088 bytes** | **3,300 bytes** |

**Key Insight:** Secara kecepatan komputasi (*CPU cycles*), Kyber jauh lebih cepat daripada RSA dan setara dengan ECDH. Namun, ukuran **Public Key** dan **Ciphertext/Signature** PQC jauh lebih besar (1KB-3KB). Ini menyebabkan peningkatan beban latensi transmisi jaringan (*network overhead*).

---

## 3. Roadmap Migrasi PQC di Lingkungan Produksi

Melakukan migrasi langsung ke PQC penuh (*pure PQC*) sangat berisiko karena algoritma baru belum teruji secara klinis di lapangan selama puluhan tahun seperti RSA/ECC. Strategi terbaik adalah menggunakan **Hybrid Cryptography**.

```
                       Client Request (Hybrid TLS ClientHello)
                                         │
                                         ▼
                     ┌───────────────────────────────────────┐
                     │          Kombinasi Kunci              │
                     │   (X25519 ECDH + ML-KEM-768 Kyber)    │
                     └───────────────────┬───────────────────┘
                                         │
                                         ▼
                     ┌───────────────────────────────────────┐
                     │       Proses Derivasi Kunci           │
                     │  HKDF(Shared_ECDH || Shared_Kyber)   │
                     └───────────────────┬───────────────────┘
                                         │
                                         ▼
                     ┌───────────────────────────────────────┐
                     │      Symmetric Key Generated          │
                     │         (AES-256-GCM Key)             │
                     └───────────────────────────────────────┘
```

### 3.1 Fase Migrasi Enterprise

1. **Fase 1: Audit Inventori Kriptografi (Discovery)**
   Identifikasi semua modul perangkat lunak, API, database, dan koneksi TLS yang saat ini menggunakan RSA/ECC. Petakan sertifikat yang akan kedaluwarsa.
2. **Fase 2: Implementasi Hybrid TLS (Transition)**
   Konfigurasikan reverse proxy (seperti WAF/Pingora) untuk mendukung negosiasi kunci hybrid (misalnya cipher group `X25519Kyber768Draft00`). Jika klien tidak mendukung Kyber, koneksi otomatis jatuh kembali (*fallback*) ke X25519 klasik.
3. **Fase 3: Transisi Tanda Tangan Digital (Authentication)**
   Perbarui otoritas sertifikat (CA) internal untuk mulai menerbitkan sertifikat hybrid berbasis **ML-DSA (Dilithium)** untuk autentikasi server.
4. **Fase 4: Post-Quantum Native (Final)**
   Nonaktifkan cipher suite klasik secara bertahap setelah standar NIST diimplementasikan secara global dan perangkat warisan (*legacy*) telah dimigrasikan seluruhnya.

---

## 4. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[quantum-cryptography-deepdive]] | Teori dasar fisika kuantum, algoritma Shor, Grover, dan prinsip matematika kisi (*lattices*). |
| [[waf-reverse-proxy-deepdive]] | Data plane WAF tempat negosiasi kunci hybrid TLS ini diintegrasikan pada tingkat HTTP handshake. |
| WAF development plan (privat) | Roadmap implementasi WAF sebagai prioritas pengembangan #3. |

## 🔍 Verification Report
> [!NOTE]
> **Last Evaluated:** 2026-08-12 20:13
> **Overall Epistemic Status:** **`UNVERIFIED`**

### ✅ Claim 1: Kyber is a lattice-based Key Encapsulation Mechanism (KEM) algorithm.
- **Status:** `VERIFIED` | **Confidence:** `HIGH`
- **Analysis:** Multiple sources confirm that Kyber is a lattice-based Key Encapsulation Mechanism (KEM), also formally standardized as ML-KEM (Module-Lattice-Based Key-Encapsulation Mechanism).
- **Sources:** [1](https://en.wikipedia.org/wiki/ML-KEM), [2](https://www.mdpi.com/2073-8994/18/3/426), [3](https://csrc.nist.gov/pubs/fips/203/final), [4](https://github.com/0xskaper/crystal-kyber)

### ❔ Claim 2: The `pqc_kyber` crate version 0.7.0 provides an implementation of NIST Round 3 Kyber.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.

### ❔ Claim 3: Kyber-768 provides a security level equivalent to AES-192.
- **Status:** `UNVERIFIED` | **Confidence:** `LOW`
- **Analysis:** No relevant web search results could be retrieved to verify this claim.
---

audited
---
