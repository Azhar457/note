---
title: Post-Quantum TLS Implementation — Hybrid Key Exchange, ML-KEM, and Handshake
  Optimization
tags:
- post-quantum
- pqc
- tls
- cryptography
- ml-kem
- network-security
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout
  - code-wrap

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Perkembangan komputer kuantum skala besar mengancam algoritma kriptografi asimetris klasik (RSA, ECC, Diffie-Hellman). Catatan ini membedah arsitektur implementasi Post-Quantum Cryptography (PQC) pada protokol TLS 1.3, mekanisme Key Encapsulation (ML-KEM), tanda tangan digital (ML-DSA), serta optimasi performa jaringannya, melengkapi [[pqc-implementation-rust]] dan [[tls-ssl-deepdive]].

## Daftar Isi

1. [Dilema Kriptografi Klasik & Standar NIST PQC](#1-dilema-kriptografi-klasik--standar-nist-pqc)
2. [Mekanisme ML-KEM (Kyber) & Matematika Lattice-Based](#2-mekanisme-ml-kem-kyber--matematika-lattice-based)
3. [Tanda Tangan Digital PQC (ML-DSA / Dilithium)](#3-tanda-tangan-digital-pqc-ml-dsa--dilithium)
4. [Handshake Hybrid TLS 1.3](#4-handshake-hybrid-tls-13)
5. [Bottleneck Jaringan: Fragmentasi Paket IP & Latensi](#5-bottleneck-jaringan-fragmentasi-paket-ip--latensi)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Dilema Kriptografi Klasik & Standar NIST PQC

Algoritma asimetris klasik berbasis masalah faktorisasi prima (RSA) atau logaritma diskrit (ECDH/ECDSA) dapat dipecahkan dalam waktu polinomial menggunakan **Algoritma Shor** pada komputer kuantum yang cukup kuat. 
Untuk mencegah ancaman penyadapan data saat ini yang didekripsi di masa depan (*Harvest Now, Decrypt Later*), industri bermigrasi ke standar **Post-Quantum Cryptography (PQC)** yang disetujui NIST pada tahun 2024:

- **ML-KEM (Module-Lattice Key Encapsulation Mechanism)**: Berbasis algoritma Kyber untuk pertukaran kunci aman.
- **ML-DSA (Module-Lattice Digital Signature Algorithm)**: Berbasis algoritma Dilithium untuk autentikasi dan pembuatan sertifikat.
- **SLH-DSA (Stateless Hash-based Digital Signature Algorithm)**: Berbasis SPHINCS+ untuk tanda tangan cadangan berkeamanan tinggi.

---

## 2. Mekanisme ML-KEM (Kyber) & Matematika Lattice-Based

ML-KEM beroperasi menggunakan masalah matematika **Module Learning With Errors (M-LWE)** di atas kisi-kisi aljabar ring polynomial.

### 2.1 Formulasi M-LWE
Diberikan matriks polynomial ring publik $ A $, vektor rahasia $ s $, dan vektor noise kecil $ e $. Skema enkripsi menghasilkan nilai publik $ t $ sebagai berikut:

$$t = A \cdot s + e \pmod q$$

Menghitung vektor rahasia $ s $ jika hanya diketahui $ A $ dan $ t $ adalah masalah matematika NP-hard (sangat sulit) bahkan untuk komputer kuantum, karena adanya gangguan error vector $ e $.

### 2.2 Parameter Varian ML-KEM

| Varian | Dimensi Kisi (k) | Security Level (NIST) | Padanan Kripto Klasik |
|---|---|---|---|
| **ML-KEM-512** | 2 | Level 1 | AES-128 / SHA-256 / RSA-2048 |
| **ML-KEM-768** | 3 | Level 3 | AES-192 / SHA-384 / ECDSA P-256 |
| **ML-KEM-1024** | 4 | Level 5 | AES-256 / SHA-512 / ECDSA P-384 |

---

## 3. Tanda Tangan Digital PQC (ML-DSA / Dilithium)

ML-DSA menggunakan teknik penolakan penandaan (*Fiat-Shamir dengan Abort*) di atas modul kisi. 
- **Tujuan**: Memastikan penanda tangan membuktikan kepemilikan kunci privat tanpa membocorkan informasi struktural kunci tersebut melalui tanda tangan publik.
- **Kelemahan Utama**: Ukuran kunci publik dan tanda tangan ML-DSA jauh lebih besar dibanding ECDSA (ML-DSA-65 memiliki ukuran signature ~3.3 KB vs ECDSA P-256 yang hanya 64 Byte).

---

## 4. Handshake Hybrid TLS 1.3

Selama masa transisi, dunia keamanan menggunakan skema **Hybrid Key Exchange** untuk menggabungkan algoritma klasik yang terbukti stabil dengan algoritma post-quantum yang baru.

```
      Client                                                                Server
        │                                                                     │
        │  ClientHello                                                        │
        │  - KeyShare: X25519 + ML-KEM-768                                    │
        ├────────────────────────────────────────────────────────────────────▶│
        │                                                                     │
        │                                             ServerHello             │
        │                                             - KeyShare: X25519 +    │
        │                                               ML-KEM-768            │
        │                                             - EncryptedExtensions   │
        │                                             - Certificate (Classic) │
        │                                             - CertificateVerify     │
        │                                             - Finished              │
        │◀────────────────────────────────────────────────────────────────────┤
        │                                                                     │
        │  Finished                                                           │
        ├────────────────────────────────────────────────────────────────────▶│
        │                                                                     │
        │  [Enkripsi Data Aplikasi Terowongan Hybrid]                         │
        │◀───────────────────────────────────────────────────────────────────▶│
```

### 4.1 Mekanisme Derivasi Kunci Hybrid
Saat ClientHello dikirim, klien menyertakan dua bagian key share:
1. Porsi Klasik: Kunci publik $ \text{pk}_{\text{ECDHE}} $ (misal: X25519).
2. Porsi Post-Quantum: Kunci publik $ \text{pk}_{\text{ML-KEM}} $.

Server merespon dengan melakukan enkapsulasi kunci pada kedua algoritma menghasilkan dua rahasia mentah: $ S_{\text{ECDHE}} $ dan $ S_{\text{ML-KEM}} $. Kedua rahasia tersebut digabungkan menggunakan fungsi derivasi kunci (KDF) untuk menghasilkan *Master Secret* akhir:

$$
\text{Shared Secret} = \text{HKDF-Extract}(\text{Salt}, S_{\text{ECDHE}} \mathbin{\Vert} S_{\text{ML-KEM}})
$$

**Keamanan**: Komunikasi tetap aman selama salah satu dari kedua algoritma tersebut belum berhasil dipecahkan (*dual-security guarantee*).

---

## 5. Bottleneck Jaringan: Fragmentasi Paket IP & Latensi

Migrasi ke PQC menimbulkan dampak langsung pada infrastruktur transmisi jaringan:

### 5.1 Masalah MTU & Fragmentasi TCP/IP
Ukuran standar MTU (Maximum Transmission Unit) pada jaringan ethernet adalah **1500 Byte**.
- Handshake klasik (ECDHE + ECDSA) pas di dalam 1 atau 2 paket IP (ClientHello ~300 Byte).
- Handshake hybrid (X25519 + ML-KEM-768) memiliki key share publik yang membengkak hingga ~1.2 KB. Jika menyertakan sertifikat bertanda tangan ML-DSA, ukuran ClientHello/ServerHello dengan mudah melampaui **10 KB**.
- **Akibat**: Paket TLS terpaksa dipecah di layer IP. Router di jaringan tengah sering kali membuang paket IP yang difragmentasi (*IP fragmentation drop*) karena alasan kebijakan keamanan firewall, memicu kegagalan handshake TLS (*handshake timeout*).

### 5.2 Strategi Mitigasi
- **TCP MSS Clamping**: Menyesuaikan ukuran Maximum Segment Size pada router agar TCP membagi segmentasi di level layer transport (lebih ramah firewall dibanding fragmentasi layer IP).
- **Intermediate CA Hybrid**: Hanya menggunakan pertukaran kunci hybrid (ML-KEM + X25519) untuk enkripsi data, namun tetap mempertahankan sertifikat tanda tangan klasik (ECDSA) untuk proses autentikasi selama infrastruktur jaringan global belum sepenuhnya mendukung paket berdimensi besar.

---

## 6. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[pqc-implementation-rust]] | Kode implementasi konkret bahasa Rust untuk pustaka kriptografi pasca-kuantum. |
| [[tls-ssl-deepdive]] | Kerangka kerja dasar arsitektur handshake TLS 1.3 klasik. |
| [[network-security]] | Pengaruh fragmentasi paket IP terhadap stabilitas routing dan aturan firewall. |
| [[unified-threat-ontology]] | Penyelarasan PQC pada Layer 6 (Presentation - Kriptografi & Serialisasi TLS). |
---

audited
---
