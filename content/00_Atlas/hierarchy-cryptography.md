---
title: Hierarchy Cryptography
tags:
- atlas
- cryptography
- post-quantum
- blue-team
created: '2026-07-17'
updated: '2026-07-17'
status: active
---

# 🔐 HIERARKI KRIPTOGRAFI — Dari Caesar Cipher (Level 0) sampai Post-Quantum (Level 7)

> Kriptografi adalah **satu-satunya** ilmu di dunia security yang punya **timeline kematian algoritma**: tiap algoritma melewati siklus lahir → adopsi luas → kelemahan ditemukan → deprecated → forbidden. Hierarki ini mengikuti timeline itu — dari cipher klasik yang bisa dipecahkan anak SMA dalam menit, sampai standar NIST 2024 yang tahan terhadap komputer kuantum masa depan. Untuk aplikasi nyata di setiap level + biometrik (sheet 2), lihat [[cryptography-biometrics]].

> [!info] Cara Baca
> Level 0 = cipher klasik (edukasi). Level 7 = standar masa depan (PQC NIST 2024). Yang berlaku praktis hari ini = Level 3–5 (hash, TLS, PKI). Kolom "Tembok Kematian" jujur soal kapan algoritma expire.

---

## Tabel Utama — Level 0 sampai Level 7

| 🔑 Level | 🧠 Algoritma & Pendekatan | ⚡ Sweet Spot & Cara Kerja | ☠️ Tembok Kematian (Kapan Expired) | 🎯 Dipakai Di Mana Hari Ini |
|---|---|---|---|---|
| **Level 0** — Classical Cipher | Caesar, Vigenère, ROT13, Atbash, Rail Fence, Substitution Cipher | Substitusi atau transposisi karakter sederhana. Caesar: geser huruf N posisi. Vigenère: Caesar dengan kunci berulang (kelihatannya kuat, lemah dengan frequency analysis) | **Langsung mati** di hadapan frequency analysis. Huruf E di bahasa Inggris adalah 12.7% — bikin pattern cipher terlihat sehari. Tidak ada computational security whatsoever | CTF pemula, edukasi konsep dasar, puzzle harian, Steganografi sederhana. Bukan untuk production |
| **Level 1** — Symmetric Encryption | DES (mati), 3DES (mati), **AES-128/256** (standar), ChaCha20, Blowfish, Twofish, Camellia | Satu kunci shared untuk enkripsi + dekripsi. AES-256: standar emas, dipakai militer AS, bank sentral, VPN modern. Blowfish (1993) tergantikan AES karena concern key size. DES (56-bit key) dipecahkan EFF DES Cracker dalam 22 jam 1999 | **Key distribution problem**. Bagaimana berbagi kunci aman dengan pihak yang belum pernah bertemu? Ini yang mendorong lahirnya Level 2 (asymmetric). AES-256 sendiri aman sampai quantum computer besar (Grover's algorithm) | HTTPS session key, VeraCrypt, BitLocker, FileVault, disk encryption, VPN tunnel, database encryption at-rest |
| **Level 2** — Asymmetric / Public Key | RSA-2048/4096, **ECC** (Curve25519/P-256), Diffie-Hellman, ElGamal, DSA | Dua kunci: **public** boleh disebar; **private** rahasia. Enkripsi dengan public, dekripsi dengan private. ECC: keamanan setara RSA-2048 dengan kunci 256-bit (lebih efisien mobile). DH: shared secret tanpa kirim. | **Rentan Shor's Algorithm** di quantum computer cukup besar. RSA-1024 mati. ECC aman dari classical tapi vulnerable quantum | TLS handshake (browser ke server), SSH key pair, PGP email, code signing certificate, S/MIME, JWT signing, blockchain wallet |
| **Level 3** — Hash Functions | **MD5** (mati), **SHA-1** (mati), **SHA-256/384/512** (standar), SHA-3 (Keccak), BLAKE3, bcrypt, Argon2, scrypt | One-way function: mudah compute hash(x), **mustahil** balik hash(x) → x. BLAKE3 = tercepat 2024. bcrypt/Argon2 = slow hash untuk password storage. Salt + slow = rainbow table attack mustahil. | MD5 collision (2004). SHA-1 collision (Google SHAttered 2017). Hash tanpa salt = rainbow table vulnerable. SHA-256/512 aman saat ini, **rentan quantum** (Grover's halving security) | Integritas file (checksum SHA-256), password storage (Argon2/bcrypt), blockchain (Bitcoin pakai SHA-256), digital signature, HMAC, deduplication |
| **Level 4** — Protokol Kriptografi | **TLS 1.3**, WireGuard, Signal Protocol, Noise Protocol, SSH, IPsec/IKEv2 | Kombinasi primitif jadi protokol komunikasi aman. TLS 1.3: handshake 1-RTT, forward secrecy wajib, hapus cipher legacy. Signal Protocol: Double Ratchet (WhatsApp, Telegram). WireGuard: VPN modern 4000 baris kode (vs OpenVPN 70.000) | **Implementasi yang salah lebih bahaya dari algoritma lemah.** Padding oracle attack (POODLE 2014), Heartbleed 2014, ROBOT 2017 — semua bug implementasi, bukan algoritma | HTTPS di web, messaging E2E (Signal, WhatsApp), SSH remote access, VPN modern, IoT TLS, REST API over HTTPS |
| **Level 5** — PKI & Certificate Infrastructure | **X.509**, CA hierarchy (Root → Intermediate → End-entity), Certificate Transparency (CT) logs, OCSP, **Certificate Pinning** | PKI = sistem kepercayaan hierarkis. Root CA (bisa di-audit, ~150 di browser) → Intermediate CA → End-entity sertif. Browser hanya percaya Root CA di trust store-nya. CT log publik semua sertifikat diterbitkan, detect fake. | **Root CA compromise = seluruh internet tidak aman untuk domain itu**. DigiNotar 2011, CNNIC 2015. Pinning bisa break app kalau cert rotate. OCSP soft-fail vs hard-fail | HTTPS di seluruh web, code signing, S/MIME email, VPN client auth, IoT device identity, government eID |
| **Level 6** — Zero-Knowledge & Advanced | **ZKP** (Zero-Knowledge Proof), **zk-SNARKs** (Zcash, zkEVM), Homomorphic Encryption (FHE), MPC (Multi-Party Compute), Secret Sharing (Shamir) | ZKP: **buktikan kamu tahu tanpa tunjukkan apa yang kamu tahu.** zk-SNARK: ZKP compact dan verify cepat. FHE: compute data terenkripsi tanpa decrypt (cloud tidak pernah lihat data). MPC: komputasi tanpa ada pihak lihat input. | FHE: **1000–10.000x lebih lambat** dari compute tidak terenkripsi. zk-SNARK butuh trusted setup ceremony. MPC latency tinggi. Belum battle-tested skala production | Privacy-preserving ML, blockchain privacy (Zcash, Monero), e-voting, secure genomic analysis, supply chain provenance |
| **☠️ Level 7** — Post-Quantum Cryptography | **CRYSTALS-Kyber** (NIST FIPS 203), **CRYSTALS-Dilithium** (FIPS 204), **FALCON**, **SPHINCS+**, NTRU, NewHope | Algoritma **tahan quantum** (Shor's tidak bisa pecahkan). NIST 2024 standardisasi 4 algoritma. Berbasis **lattice** (Kyber/Dilithium), hash-based (SPHINCS+), atau code-based (Classic McEliece). | Signature & key **jauh lebih besar** dari RSA/ECC. Performance overhead. Belum battle-tested panjang. **Harvest-now-decrypt-later**: adversary rekam traffic sekarang, decrypt saat quantum cukup | Migrasi infrastruktur kritis (bank, militer, government) — wajib sebelum 2030. Browser mulai hybrid mode (X25519 + Kyber). TLS hybrid handshake roll-out 2025+ |

---

## Peta Visual — Timeline Kematian Algoritma

```
LEWAT ──── SEKARANG ──── MASA DEPAN ──── (quantum aktif ~2030-2035?)

█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Level 0 (Classical)
       ████████████░░░░░░░░░░░░░░░░░░░░░░░░░  Level 1 (DES → AES)
              ████████████████████████████░░░░  Level 2 (RSA, ECC)
                     █████████████████████████  Level 3 (SHA-256)
                            ███████████░░░░░░░░░  Level 4 (TLS 1.3)
                                  ████████████████  Level 5 (PKI/X.509)
                                        ███████████████  Level 6 (ZKP/FHE)
                                              ─↑─
                                       Level 7 (PQC NIST 2024)
                                       Hybrid mode rolling out

█ = "secure production-grade today"
░ = "deprecated, broken, atau soon obsolete"
```

> [!warning] Timeline Kematian — Bukan Teori
> Beberapa algoritma di hierarki ini **mati untuk production use**:
> - **DES (1977)** → dipecahkan 1999 (22 jam, EFF cracker)
> - **MD5 (1992)** → collision 2004 (Wang et al.)
> - **SHA-1 (1995)** → collision Google SHAttered 2017 (USD 110K)
> - **RC4** → dilarang di TLS RFC 7465 (2015)
> - **RSA-1024** → deprecated sejak 2013
> - **3DES** → NIST SP 800-131A (2023): "disallowed after 2023"
>
> Setiap algoritma yang sekarang "aman" di Level 1–5 punya expiry date. Tidak ada exception.

---

## Kenapa Hirarki Ini Penting

### 1. Kriptografi Adalah Satu-Satunya Yang Punya "Expiration Date"

Firewalls, antivirus, IDS — semua security tools tidak punya konsep "mati di tahun X." Kriptografi punya. Standar berubah karena research cryptanalysis berkembang, adversary capability berubah (quantum), atau computational cost turun (Moore's law). Kalau lo pakai algoritma yang "aman hari ini" tanpa cek expiry date, lo rentan 5-10 tahun lagi saat teknologi adversary overtake.

### 2. Adopsi Bertahap, Bukan Switch Instan

Migrasi Level 1–5 → Level 7 bukan migrasi "besok langsung pakai PQC." Algoritma baru butuh:
- Implementasi reference (NIST biasanya publish dalam beberapa tahun setelah standardisasi)
- Library production-grade (OpenSSL, BoringSSL, libsodium)
- Audit & formal verification
- Hardware acceleration (AES-NI punya, CRYSTALS tidak native di CPU lama)
- Adoption period (5–10 tahun untuk sistem kritis)

Maka **hybrid mode** rolling out 2025+:
- TLS pakai X25519 + Kyber768 simultaneously
- Sistem kritis migrasi parallel pathways dulu

### 3. Aturan "Never Roll Your Own Crypto"

Ini bukan semboyan, ini **bias survivor**:
- 90% CTF crypto challenge solvable karena penulis salah implementasi, **bukan karena algoritmanya lemah**
- Heartbleed (2014) = open-source library well-maintained (OpenSSL) masih punya bug memory disclosure
- Padding oracle attack (POODLE, ROBOT) = implementasi legacy yang salah pulih dari error

Maka hierarki Anda **bukan hierarki untuk implementasi** — itu hierarki untuk **pemahaman**. Yang menggunakan crypto tinggal di Level 4–5 (TLS + PKI). Yang **membangun** crypto primitive di bawah itu ada di komunitas riset (L1) yang iface-nya melewati audit 10+ tahun.

### 4. Trust Dependency: Semuanya Rantai

TLS 1.3 (Level 4) pakai X25519 (Level 2) + AES-256 (Level 1) + SHA-256 (Level 3). Kalau salah satu lemah, TLS lemah. Kalau CA Root di trust store lo compromised (Level 5), TLS lo cacat walau algoritma kriptografinya kuat. **Crypto terkuat tidak membantu kalau trust chain lemah.**

Inilah kenapa ada level terpisah untuk PKI (Level 5): trust infrastructure punya failure modes sendiri yang tidak ada di algoritma.

### 5. Quantum = Pre-Solve, Bukan Reaktif

Adversary bisa **rekam traffic hari ini**, simpan ciphertext-nya, dan **dekrip nanti** saat quantum computer cukup besar. Untuk data dengan TTL panjang (government record, financial transaction log, medical record 50 tahun) —

- 2026: AES-256 aman
- 2035: Shor's algorithm + million qubit quantum computer bisa dimulai
- artinya data yang direkam 2026 → dekrip 2035 = bocor

Solusi: **post-quantum migration untuk data sensitif TTL panjang** sekarang, tidak tunggu sampai quantum tiba. Inilah `harvest-now-decrypt-later` threat model.

---

## Plot Twists

> [!danger] Plot Twist 1: ECC Telah Di-Backdoored di Masa Lalu
> Dual_EC_DRBG (2006) — pseudo-random number generator yang distandarisasi NIST. Ditemukan mengandung **NSA backdoor** (Edward Snowden leaks 2013). Vendor besar (RSA Security) menerima USD 10 juta dari NSA untuk menjadikan Dual_EC_DRBG default di products mereka. Setelah pengungkapan NIST mencabut standard (2014). Ini bukti: **standar resmi ≠ aman**. Selalu cek asal-usul standar dan lihathasil analisis independen. NIST sekarang sangat terbuka dengan standardisasi PQC melalui proses kompetisi terbuka 2017–2024 — untuk merestorasi trust.

> [!danger] Plot Twist 2: Quantum Sudah "Ready" di Beberapa Arah
> China (2020): demonstrasi memhack RSA-like encryption dengan quantum komputer kecil (tapi ini masih versi lab). IBM (2023): Condor processor 1.121 qubit. Google Willow (2024): 105 qubit dengan error correction breakthrough. Threshold untuk **Shor's algorithm pada RSA-2048**: ~4.000 logical qubit = ~1 juta physical qubit. Belum ada di 2026. Tapi trajectory-nya jelas — bukan "jika" tapi "kapan." Standardisasi PQC NIST 2024 adalah **response terhadap trajectory itu**, bukan paranoia.

> [!danger] Plot Twist 3: Hash Collision Mudah Dari Yang Kamu Kira
> Google SHAttered (2017) menunjukkan collision SHA-1 cuma butuh USD 110K computation. Collision SHA-256 saat ini masih **mustahil** tapi tidak teoritis mustahil. Dengan hash function, collision != preimage. Artinya attacker bisa bikin **dua dokumen dengan hash identik** (collision attack) tapi masih tidak bisa balik hash → dokumen asli. Untuk integritas file sederhana (checksum download), collision attack berbahaya — bisa swap file berbahaya dengan hash sama. Solusi: SHA-256 + struktur Merkle tree (Git pakai ini).

> [!tip] Plot Twist 4: Implementasi Terbuka = Risiko Audit
> OpenSSL Heartbleed (2014) cuma satu bug dari ribuan bug implementasi open source kripto. Trade-off fundamental:
> - **Open-source** = bisa di-audit semua orang, komunitas bug bounty → **lebih aman long-term**
> - **Closed-source** = lebih cepat patch tapi trust = "katakan vendor" → **lebih rapuh**
> 
> NSA dual-EC backdoor di OpenSSL (RSA BSAFE) awalnya closed-source — semua percaya "standar resmi." Paradoks: **transparency is the cure**, tapi implementasinya berat dengan audit. OpenSSL audit post-Heartbleed terima USD 900K dari Linux Foundation dan sekarang distressed — tapi jumlah kontributor aktif naik signifikan.

> [!tip] Plot Twist 5: Biometrik Bukan Crypto — Tapi Berdua Fundamental
> [[cryptography-biometrics|Hierarki Biometrik]] (Sheet 2 dari-library) menjelaskan kenapa biometrik adalah **faktor kedua** setelah kriptografi. Password (what you know) + crypto (Level 0–5) membentuk **first factor**. Biometric (what you are) + hardware token (what you have) menjadi **second factor**. Hierarki kriptografi **tidak lengkap** tanpa hierarki biometrik — sheet kedua di-library yang memetakan [[cryptography-biometrics|Biometrik & Identitas]] (Password → Behavioral DNA → Neural/BCI).

---

## Migration Roadmap — Sekarang ke Pasca-Quantum

| Fase | Timeline | Target |
|---|---|---|
| **Audit** | 2025–2026 | Inventarisasi semua algoritma kriptografi di stack kamu. RSA-2048? ECC P-256? SHA-1? RC4? |
| **Hybrid TLS** | 2025–2027 | Browser + server pakai **X25519 + Kyber768** secara paralel. Cloudflare sudah roll-out 2024 |
| **Internal Crypto** | 2026–2028 | Database, backup encryption, file encryption migrasi AES-256 → AES-256 + Kyber wrap |
| **Long-TTL Data** | 2026–2030 | Data sensitif TTL panjang (medical, government, financial) migrasi ke PQC ASAP |
| **Quantum Arrival** | ~2035? | Saat quantum dekripsi public key asimtotik feasible, hybrid menjadi sole-PQC |

PQC migration bukan **opsional upgrade** — itu **inevitability yang perlu planning 5-10 tahun**.

---

## Sumber & Telusur Lebih Lanjut

- **Library Sheet 1 (Kriptografi)** → [[cryptography-biometrics]] (Level 0–7 + timeline kematian algoritma)
- **Library Sheet 2 (Biometrik)** → [[cryptography-biometrics]] (Password → Behavioral DNA)
- **Quantum Cryptography Deep Dive** → [[quantum-cryptography-deepdive]] (lattice, hash, code-based)
- **TLS Handshake Detail** → [[tls-ssl-deepdive]] (TLS 1.2 vs 1.3, JA3 fingerprint)
- **HTTP Caching** → [[http-protocol-deepdive]] (digest auth, ETag integrity)
- **Network Layer Analog** → [[hierarchy-network-security]] (TLS ada di Layer 5-6 OSI)
- **Endpoint Boot Chain Analog** → [[hierarchy-endpoint-security]] (secure boot pakai crypto + TPM)
- **Master Index** → [[master-index]]

---

> Hierarki kriptografi adalah hierarki **ketidak-abadian**. Setiap algoritma yang hari ini "aman," besok bisa mati. Tapi yang lebih penting: tiap naik level lo menambahkan **kemampuan + cost**. Lo tidak perlu Level 6 ZKP untuk secure web app — cukup TLS 1.3 (Level 4). Yang penting adalah **tahu level mana lo berada dan kapan harus migrasi**.

*Cryptography Hierarchy | Level 0 (Caesar) → Level 7 (PQC NIST 2024) · Satu-Satunya Hierarki yang Punya Expired Date*
