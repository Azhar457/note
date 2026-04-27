---
tags:
  - kriptografi
  - biometrik
  - identitas
  - autentikasi
  - pki
  - zero-trust
  - cryptography
aliases:
  - Crypto Hierarchy
  - Biometrik Levels
  - Auth Stack
created: 2026-04-23
status: operational
---

# 🔐 Kriptografi & Biometrik — Hierarki Lengkap

> Dua disiplin yang membentuk **fondasi kepercayaan digital**: Kriptografi membuktikan *apa yang kamu tahu/punya*, Biometrik membuktikan *siapa kamu secara fisik*. Keduanya membentuk stack autentikasi modern.

---

## Daftar Isi

- [[#Sheet 1 — Kriptografi Dari Caesar Cipher sampai Post-Quantum]]
- [[#Sheet 2 — Biometrik & Identitas Dari Password sampai Behavioral DNA]]
- [[#Trust Chain Bagaimana Keduanya Bekerja Bersama]]

---

## Sheet 1 — Kriptografi: Dari Caesar Cipher sampai Post-Quantum

> **Kriptografi** = ilmu menyembunyikan informasi sehingga hanya pihak yang berhak bisa membacanya.
> Bukan hanya enkripsi — tapi juga: integritas, autentikasi, dan non-repudiation.

| 🔑 Level & Algoritma | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian | 🎯 Dipakai Di |
|---|---|---|---|
| **Level 0** — Classical Cipher *(Caesar, Vigenère, ROT13, Atbash, Rail Fence)* | Substitusi dan transposisi karakter sederhana. Caesar: geser huruf N posisi. Vigenère: Caesar dengan kunci berulang. ROT13: Caesar dengan N=13 (decode = encode lagi). Bisa dipecahkan manual dengan frekuensi analisis. | Frekuensi analisis (huruf E paling sering dalam bahasa Inggris) memecahkan semua cipher klasik dalam menit. Tidak ada keamanan komputasional sama sekali. | CTF pemula, edukasi konsep dasar, puzzle, steganografi sederhana |
| **Level 1** — Symmetric Encryption *(DES, 3DES, AES-128/256, ChaCha20, Blowfish)* | Satu kunci untuk enkripsi dan dekripsi. **AES-256**: standar emas saat ini — dipakai militer, bank, VPN. ChaCha20: alternatif AES yang lebih cepat di perangkat tanpa hardware AES acceleration. DES (56-bit): sudah mati, dipecahkan dalam jam. | **Key distribution problem**: bagaimana berbagi kunci secara aman dengan pihak yang belum pernah bertemu? Ini yang mendorong terciptanya asymmetric crypto. | Enkripsi file (VeraCrypt, BitLocker), HTTPS (session key), VPN tunnel, enkripsi database |
| **Level 2** — Asymmetric / Public Key *(RSA, Diffie-Hellman, ECC, ElGamal, DSA)* | Dua kunci: **public** (boleh disebar) dan **private** (rahasia). Enkripsi dengan public key, dekripsi hanya dengan private key. DH: dua pihak generate shared secret tanpa pernah kirim secret itu sendiri. ECC: keamanan setara RSA-2048 dengan kunci 256-bit (lebih efisien). | RSA-1024 sudah deprecated. RSA-2048 aman dari classical computer, tapi **rentan terhadap Shor's Algorithm di quantum computer** yang cukup besar. | TLS/HTTPS handshake, SSH key pair, PGP email, code signing, certificate |
| **Level 3** — Hash Functions *(MD5, SHA-1, SHA-256, SHA-3, BLAKE3, bcrypt, Argon2)* | One-way function: mudah compute H(x), mustahil balik dari H(x) ke x. **MD5/SHA-1**: sudah broken (collision found). **SHA-256**: aman, dipakai Bitcoin. **bcrypt/Argon2**: hash khusus password — sengaja lambat + salted untuk cegah rainbow table. BLAKE3: tercepat saat ini, dipakai Cloudflare. | MD5 dan SHA-1 collision ditemukan (Google SHAttered 2017). Hash tanpa salt = rentan rainbow table attack. GPU modern bisa brute-force SHA-256 miliaran kali/detik. | Integritas file, password storage, blockchain, digital signature, HMAC |
| **Level 4** — Protokol Kriptografi *(TLS 1.3, Signal Protocol, Noise Protocol, WireGuard, SSH)* | Kombinasi crypto primitif menjadi protokol komunikasi aman. **TLS 1.3**: handshake lebih cepat, forward secrecy wajib, hapus cipher lemah. **Signal Protocol**: E2E encryption dengan Double Ratchet (WhatsApp, Signal, Telegram secret chat pakai ini). **WireGuard**: VPN modern dengan kode 4000 baris vs OpenVPN 70.000 baris. | Implementasi yang salah lebih berbahaya dari algoritma yang lemah. "Never roll your own crypto." Padding oracle, timing attack, downgrade attack pada implementasi buruk. | HTTPS, VPN modern, messaging E2E, SSH remote access |
| **Level 5** — PKI & Certificate Infrastructure *(X.509, CA hierarchy, CT logs, OCSP, Certificate Pinning)* | **PKI (Public Key Infrastructure)**: sistem kepercayaan hierarkis. Root CA → Intermediate CA → End-entity certificate. Browser trust ~150 Root CA. **Certificate Transparency**: log publik semua cert yang pernah diterbitkan — deteksi cert palsu. **Certificate Pinning**: app hanya percaya cert spesifik, bukan semua Root CA. | Root CA compromise = seluruh internet tidak aman (kasus DigiNotar 2011). Pinning bisa menyebabkan app error jika cert rotate. OCSP stapling complexity. | HTTPS di seluruh web, code signing, email S/MIME, VPN client auth, IoT device identity |
| **Level 6** — Zero-Knowledge Proof & Advanced Crypto *(ZKP, zk-SNARKs, Homomorphic Encryption, MPC, Secret Sharing)* | **ZKP**: buktikan bahwa kamu tahu sesuatu tanpa mengungkapkan apa yang kamu tahu. **zk-SNARKs**: ZKP yang compact dan cepat verify (dipakai Zcash, zkEVM). **Homomorphic Encryption**: compute di data terenkripsi tanpa decrypt — cloud bisa proses data sensitif tanpa pernah melihatnya. **MPC (Multi-Party Computation)**: komputasi bersama tanpa ada pihak yang lihat input pihak lain. | Homomorphic encryption masih 1000–10.000x lebih lambat dari unencrypted computation. zk-SNARKs membutuhkan trusted setup. MPC latency tinggi. | Privacy-preserving ML, blockchain privacy, e-voting, secure genomic analysis |
| ☠️ **Level 7** — Post-Quantum Cryptography *(CRYSTALS-Kyber, CRYSTALS-Dilithium, FALCON, SPHINCS+, NTRU)* | Algoritma yang **tahan terhadap quantum computer** (Shor's Algorithm tidak bisa memecahkannya). NIST 2024 telah standardisasi: **CRYSTALS-Kyber** (key encapsulation), **CRYSTALS-Dilithium** (digital signature). Berbasis masalah matematika lattice, bukan faktorisasi bilangan prima. | Ukuran kunci dan signature lebih besar dari RSA/ECC. Performance overhead. Belum battle-tested sepanjang RSA (baru beberapa tahun). Harvest-now-decrypt-later: adversary rekam traffic sekarang, decrypt nanti saat punya quantum computer. | Migrasi infrastruktur kritis (perbankan, militer, pemerintah) — wajib sebelum 2030 |

---

### Timeline Kematian Algoritma

```
SUDAH MATI (jangan dipakai):
DES (1977)     ──────────────✗ 1999 (EFF DES Cracker)
MD5 (1992)     ──────────────────────✗ 2004 (collision)
SHA-1 (1993)   ──────────────────────────────✗ 2017 (SHAttered)
RSA-512        ──────────────✗ 1999
RSA-1024       ────────────────────────────────✗ deprecated 2015

MASIH AMAN (tapi perlu migrasi sebelum quantum era):
AES-256        ████████████████████████████████████ (quantum-safe, kunci cukup besar)
RSA-2048       ████████████████████████░░░░░░░░░░░░ (~2030 quantum threat)
ECC-256        ████████████████████████░░░░░░░░░░░░ (~2030 quantum threat)
SHA-256/3      ████████████████████████████████████ (quantum-safe dengan output 256-bit)

MASA DEPAN:
CRYSTALS-Kyber ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ (standardisasi NIST 2024)
```

---

## Sheet 2 — Biometrik & Identitas: Dari Password sampai Behavioral DNA

> **Autentikasi** menjawab: "Siapa kamu, dan bagaimana kamu membuktikannya?"
> Tiga faktor: **something you know** (password), **something you have** (token), **something you are** (biometrik).

| 🪪 Level & Metode                                                                                                    | ⚡ Cara Kerja & Sweet Spot                                                                                                                                                                                                                                                                                                                                                                                              | ☠️ Tembok Kematian                                                                                                                                                                                                                            | 🎯 Dipakai Di                                                                               |
| -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **Level 0** — Password & PIN *(bcrypt, Argon2, PBKDF2, password manager)*                                            | Yang paling tua dan paling banyak dipakai. Keamanan bergantung pada entropy (panjang + kompleksitas + keunikan). Password manager (Bitwarden, 1Password) generate dan simpan password unik per situs.                                                                                                                                                                                                                  | 81% breach disebabkan password lemah/reused (Verizon DBIR). Phishing bypass semua password complexity. Social engineering lebih mudah dari brute force.                                                                                       | Login semua sistem, enkripsi lokal, PIN ATM                                                 |
| **Level 1** — MFA / 2FA *(TOTP, HOTP, SMS OTP, Authenticator App, Push notification)*                                | Something you know + something you have. **TOTP** (Google Authenticator, Authy): kode 6 digit berubah tiap 30 detik berdasarkan shared secret + timestamp. **FIDO2/WebAuthn**: standar modern, phishing-resistant. SMS OTP: paling lemah — rentan SIM swap.                                                                                                                                                            | SMS 2FA rentan SIM swap attack (bisa dilakukan via social engineering ke operator seluler). Push notification rentan MFA fatigue attack (spam approve sampai user klik). TOTP seed bisa dicuri jika backup tidak aman.                        | Banking app, akun Google/Microsoft, VPN, semua layanan kritikal                             |
| **Level 2** — Biometrik Fisik Tier 1 *(Fingerprint, Face ID, iris scan)*                                             | **Fingerprint**: capacitive sensor mapping minutiae points (ridge ending, bifurcation). **Face ID Apple**: structured light + infrared — 30.000 titik, tidak bisa ditipu foto 2D. **Iris scan**: pattern unik lebih dari fingerprint, stable seumur hidup.                                                                                                                                                             | Fingerprint bisa ditipu dengan gelatin/latent print di device murah. Face ID standar rendah bisa ditipu foto (non-3D IR). **Biometrik tidak bisa diganti** jika bocor — beda dengan password. Database biometrik jadi target sangat berharga. | Smartphone unlock, border control, banking mobile, absensi                                  |
| **Level 3** — Biometrik Fisik Tier 2 *(Vein pattern, palm print, ear shape, DNA)*                                    | **Vein pattern** (jari/telapak): sensor near-infrared scan pola pembuluh darah di bawah kulit — tidak bisa diduplikasi dari foto, tidak berubah seumur hidup. **DNA**: akurasi tertinggi (1 in 10^20+) tapi proses lambat (menit hingga jam).                                                                                                                                                                          | DNA verification tidak real-time. Vein scanner hardware mahal. Semua biometrik fisik: sekali bocor, selamanya bocor.                                                                                                                          | ATM premium Jepang (vein), forensik kriminal (DNA), border control high-security            |
| **Level 4** — Behavioral Biometrics *(Keystroke dynamics, mouse movement, gait analysis, voice pattern)*             | Analisis **cara** kamu berinteraksi, bukan hanya identitas fisik. Keystroke dynamics: kecepatan mengetik, durasi tekan tombol, pola rhythm — unik per individu. Mouse movement: akselerasi, path, kecepatan scroll. Gait: cara berjalan dianalisis dari accelerometer atau kamera. **Continuous authentication**: tidak hanya saat login, tapi sepanjang sesi.                                                         | Behavioral pattern berubah saat stress, sakit, atau lelah — false rejection meningkat. Butuh baseline yang cukup panjang. Bisa dipelajari dan ditiru oleh AI adversarial.                                                                     | Banking fraud detection, enterprise DLP, high-security facility, anti-bot sistem            |
| **Level 5** — Decentralized Identity *(SSI, DID, Verifiable Credentials, SPIFFE/SPIRE, Web3 Identity)*               | **SSI (Self-Sovereign Identity)**: identitas yang kamu kontrol sendiri, bukan disimpan di server pihak ketiga. **DID (Decentralized Identifiers)**: identifier yang di-resolve via blockchain/P2P, bukan DNS/CA hierarchy. **Verifiable Credentials**: credential digital yang bisa diverifikasi tanpa menghubungi issuer. SPIFFE: identitas untuk workload/service (bukan manusia).                                   | Interoperabilitas antar sistem masih fragmentasi. UX kompleks untuk pengguna awam. Recovery jika private key hilang = kehilangan identitas.                                                                                                   | Blockchain, Kubernetes service mesh, EU Digital Identity Wallet (2026), academic credential |
| **Level 6** — Zero Trust Identity *(BeyondCorp, SASE, Continuous Adaptive Risk, Passwordless)*                       | **Zero Trust**: "never trust, always verify" — tidak ada yang dipercaya hanya karena sudah di dalam jaringan. Setiap request diverifikasi ulang berdasarkan: identitas + posture device + lokasi + behavior + konteks. **SASE (Secure Access Service Edge)**: gabungkan network security + identity di cloud. **Passwordless**: FIDO2/Passkeys menggantikan password sepenuhnya (Apple/Google/Microsoft sudah deploy). | Complexity implementasi masif. Legacy system tidak bisa Zero Trust tanpa wrapper. Passkey recovery flow masih membingungkan pengguna.                                                                                                         | Google BeyondCorp (internal Google pakai ini sejak 2009), enterprise modern, cloud-native   |
| ☠️ **Level 7** — Neural & Physiological Biometrics *(BCI, EEG authentication, Neuralink, cardiac rhythm biometrics)* | **Brainwave authentication**: EEG signal unik per individu — pikiran tentang stimulus tertentu menghasilkan signature neural yang bisa dipakai sebagai "passthought". **Cardiac rhythm**: ECG dari smartwatch sebagai continuous auth. **BCI (Brain-Computer Interface)**: Neuralink dan kompetitor — identitas dari sinyal neural langsung.                                                                           | Masih penelitian, belum produksi skala besar. EEG sensor saat ini masih perlu headset khusus. BCI invasif butuh operasi. Privasi: siapa yang punya akses ke data otak?                                                                        | Penelitian akademis, high-security militar, awal deployment di smartwatch health            |

---

## Trust Chain: Bagaimana Keduanya Bekerja Bersama

```
LAYER 7: Neural/BCI
    │ (who you are at the deepest level)
LAYER 6: Zero Trust Continuous Auth
    │ (verify every request, every time)
LAYER 5: Decentralized Identity
    │ (you own your identity)
LAYER 4: Behavioral Biometrics
    │ (how you act, not just who you are)
LAYER 3: Physical Biometrics Tier 2
    │ (vein, DNA — unforgeable)
LAYER 2: Physical Biometrics Tier 1
    │ (fingerprint, face — current standard)
LAYER 1: MFA / 2FA
    │ (something you have)
LAYER 0: Password / PIN
    │ (something you know)
    ▼
TRUST GRANTED — akses diberikan

Kriptografi bekerja di setiap layer:
- Biometrik template disimpan sebagai hash (tidak bisa di-reverse)
- Channel komunikasi dilindungi TLS
- Identity token ditandatangani secara kriptografis
- Seluruh chain dibuktikan oleh PKI
```

>[!info] Passkeys — Revolusi yang Sedang Terjadi Sekarang
>Apple, Google, Microsoft sudah deploy **Passkeys** (FIDO2/WebAuthn) — menggabungkan kriptografi asymmetric + biometrik device (Face ID/fingerprint) untuk login tanpa password sama sekali. Private key tidak pernah meninggalkan device. Phishing-resistant by design. Ini adalah konvergensi Level 2 Kriptografi + Level 2 Biometrik dalam satu gesture.

>[!warning] Biometrik Bukan Silver Bullet
>Password bocor → ganti password.
>Biometrik bocor → **tidak bisa diganti seumur hidup**.
>Ini mengapa biometrik harus selalu dikombinasikan dengan faktor lain, dan template biometrik **tidak boleh disimpan dalam bentuk raw** — harus dalam bentuk yang tidak bisa di-reverse ke data aslinya.

---

## 🔗 Lihat Juga

- [[RE_HARDWARE_HACKING]]
- [[NETWORK_SECURITY]]
- [[OSINT_RF_HIERARCHY]]
- [[INFRASTRUKTUR_CLOUD]]

---

*Kriptografi & Biometrik | Dari Caesar Cipher sampai Post-Quantum · Dari Password sampai Neural Auth*
