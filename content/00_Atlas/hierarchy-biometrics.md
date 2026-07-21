---
title: Hierarchy Biometrics
tags:
- atlas
- biometrics
- identity
- authentication
- zero-trust
created: '2026-07-17'
updated: '2026-07-17'
status: active
---

# 🪪 HIERARKI BIOMETRIK & IDENTITAS — Dari Password (Level 0) sampai Neural/BCI (Level 7)

> Setiap autentikasi menjawab: **"Siapa kamu, dan bagaimana kamu membuktikannya?"** Hirarki ini memetakan evolusi identitas dari *something you know* (password) → *something you have* (MFA/token) → *something you are* (biometrik fisik) → *how you act* (behavioral) → *you own your identity* (SSI) → *verify every request* (Zero Trust) → *who you are at neural level* (BCI). Setiap level menambah factor, tapi juga menambah complexity. Untuk tabel teknis lengkap + trust chain kriptografi, lihat [[cryptography-biometrics]].

> [!info] Cara Baca
> Level 0 = universal (siapa pun punya password). Level 7 = eksperimental (hanya penelitian/militer tinggi). Level 2–4 adalah production-standard hari ini. Level 5–6 adalah **trend masa depan 2026–2030**. Kolom "Tembok Kematian" jujur soal kapan factor itu gagal.

---

## Tabel Utama — Level 0 sampai Level 7

| 🪪 Level | 🧠 Metode & Teknologi | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian (Kapan Gagal) | 🎯 Dipakai Di Mana Hari Ini |
|---|---|---|---|---|
| **Level 0** — Password & PIN | `bcrypt`, `Argon2`, `PBKDF2`, Password Manager (Bitwarden, 1Password) | Paling tua, paling banyak dipakai. Keamanan = entropy (panjang + kompleksitas + keunikan). Password manager generate & simpan unik per situs | 81% breach dari password lemah/reused (Verizon DBIR). Phishing bypass SEMUA complexity. Social engineering > brute force. **Tidak pernah sufficient sendirian** | Login semua sistem, enkripsi lokal, PIN ATM, legacy app |
| **Level 1** — MFA / 2FA | TOTP (Google Auth, Authy), HOTP, SMS OTP, Push Notification, **FIDO2/WebAuthn** | Something you know + something you have. TOTP: kode 6 digit/30 detik dari shared secret. FIDO2: **standar modern, phishing-resistant**. SMS: paling lemah | **SMS** = SIM swap trivial. Push = MFA fatigue (spam approve). TOTP seed dicuri kalau backup tidak aman. **FIDO2 adalah satu-satunya yang benar-benar phishing-resistant** | Banking, Google/Microsoft/VPN, layanan kritis, enterprise SSO |
| **Level 2** — Biometrik Fisik Tier 1 | Fingerprint (capacitive minutiae), **Face ID** (structured light 30k titik), Iris scan | Face ID Apple: IR + dot projector — tidak ditipu foto 2D. Iris: pattern stabil seumur hidup, unik > fingerprint | Fingerprint tipu gelatin/latent print (device murah). Face ID non-IR tipu foto. **Biometrik tidak bisa diganti seumur hidup** — beda password. Database biometrik = target premium | Smartphone unlock, border control, banking mobile, absensi kantor |
| **Level 3** — Biometrik Fisik Tier 2 | Vein pattern (near-IR), Palm print, Ear shape, **DNA** | Vein: scan pembuluh darah di bawah kulit — tidak duplikasi dari foto, stabil seumur hidup. DNA: akurasi 1:10^20+ | DNA tidak real-time (menit–jam). Hardware vein mahal. **Semua biometrik fisik: sekali bocor = selamanya bocor** | ATM premium Jepang (vein), forensik (DNA), border control high-security |
| **Level 4** — Behavioral Biometrics | Keystroke dynamics, mouse movement, gait analysis, voice pattern, **Continuous Auth** | Analisis *cara* interaksi, bukan identitas fisik. Keystroke: rhythm, dwell time, flight time unik. Continuous auth = verifikasi sepanjang sesi | Pola berubah saat stress/sakit/leluh → false reject naik. Butuh baseline lama. **Bisa ditiru AI adversarial** (model extraction) | Banking fraud detection, enterprise DLP, high-security facility, anti-bot |
| **Level 5** — Decentralized Identity | **SSI** (Self-Sovereign), **DID**, Verifiable Credentials, SPIFFE/SPIRE, Web3 Identity | **Kamu kontrol identitas sendiri**, bukan server pihak 3. DID resolve via blockchain/P2P, bukan DNS/CA. VC diverifikasi tanpa kontak issuer. SPIFFE = identity untuk workload/service | Interoperabilitas fragmentasi. UX kompleks pengguna awam. **Private key hilang = identitas hilang** (no recovery) | Blockchain, K8s service mesh, EU Digital Identity Wallet (2026), academic credential |
| **Level 6** — Zero Trust Identity | **BeyondCorp**, **SASE**, Continuous Adaptive Risk, **Passwordless** (FIDO2/Passkeys) | "Never trust, always verify" — setiap request diverifikasi: identitas + device posture + lokasi + behavior + konteks. Passkey = FIDO2 + biometrik device = **login tanpa password** | Implementasi complexity masif. Legacy butuh wrapper. Passkey recovery flow membingungkan. **Butuh mature IAM + device trust** | Google BeyondCorp (2009), enterprise cloud-native, Zscaler/Cloudflare Access |
| **☠️ Level 7** — Neural & Physiological | **BCI**, EEG authentication (passthought), **Neuralink**, cardiac rhythm (ECG smartwatch) | EEG: signal unik per individu → "passthought" (pikir stimulus tertentu = signature). ECG: continuous auth dari smartwatch. BCI: identitas langsung dari sinyal neural | Masih penelitian, bukan produksi skala. EEG butuh headset khusus. BCI invasif butuh operasi. **Privasi: siapa punya akses data otak?** | Penelitian akademis, high-security militer, early smartwatch health |

---

## Peta Visual — Trust Chain Vertikal

```
LAYER 7: Neural/BCI
    │ (who you are at the deepest level — signal saraf)
LAYER 6: Zero Trust Continuous Auth
    │ (verify every request, every time — context-aware)
LAYER 5: Decentralized Identity (SSI/DID)
    │ (you own your identity — no central authority)
LAYER 4: Behavioral Biometrics
    │ (how you act, not just who you are — continuous)
LAYER 3: Physical Biometrics Tier 2
    │ (vein, DNA — unforgeable biological)
LAYER 2: Physical Biometrics Tier 1
    │ (fingerprint, face — current mass standard)
LAYER 1: MFA / 2FA (Something You Have)
    │ (TOTP, FIDO2, hardware token)
LAYER 0: Password / PIN (Something You Know)
    │ (bcrypt, Argon2, password manager)
    ▼
TRUST GRANTED — akses diberikan

KRIPTOGRAFI BEKERJA DI SETIAP LAYER:
- Biometrik template disimpan sebagai hash (tidak reversible)
- Channel komunikasi dilindungi TLS (Level 4 Kriptografi)
- Identity token ditandatangani kriptografis (JWT, PASETO)
- Seluruh chain dibuktikan oleh PKI (Level 5 Kriptografi)
```

> [!warning] Biometrik Bukan Silver Bullet
> Password bocor → **ganti password**.
> Biometrik bocor → **tidak bisa diganti seumur hidup**.
> Ini mengapa biometrik harus selalu dikombinasikan dengan faktor lain, dan template biometrik **tidak boleh disimpan raw** — harus dalam bentuk yang tidak bisa di-reverse ke data aslinya (fuzzy extractor, secure enclave, cancelable biometrics).

---

## Kenapa Hirarki Ini Penting

### 1. Evolution = Menambah Factor, Bukan Ganti

Hirarki bukan linear replacement — **setiap level menambah layer factor**:
- Level 0: 1 factor (knowledge)
- Level 1: 2 factor (knowledge + possession)
- Level 2: 3 factor (knowledge + possession + inherence)
- Level 4: continuous factor (behavior sepanjang sesi)
- Level 6: contextual factor (device posture + network + location + behavior)

Organisasi yang lompat Level 0 → Level 6 tanpa melewati Level 1–3 akan gagal karena **dependency chain**. Zero Trust butuh device identity (Level 5/6) yang butuh cryptographic identity (Level 2 Kriptografi) yang butuh PKI (Level 5 Kriptografi).

### 2. Biometrik Template ≠ Biometrik Data

Banyak organisasi salah: menyimpan **raw fingerprint image** atau **face embedding vector** di database. Kalau database itu bocor → attacker punya **biometrik mentah** yang bisa dipakai buat spoof sensor lain (presentation attack).

Best practice universal:
- **Fuzzy extractor / helper data** → generate key dari biometrik tanpa simpan template
- **Secure Enclave / TPM / TEE** → biometrik tidak pernah keluar hardware
- **Cancelable biometrics** → transformasi non-invertible (revocable biometrics)
- **ISO/IEC 24745** standar untuk biometric template protection

Hirarki Level 2–3 di sini **asumsi** implementasi aman — tapi production reality sering skip ini.

### 3. Passkeys = Konvergensi Level 2 Kriptografi + Level 2 Biometrik

Apple/Google/Microsoft (2022–2024) deploy **Passkeys (FIDO2/WebAuthn)**:
- Private key **tidak pernah keluar device** (secure enclave)
- Unlock private key = biometrik device (Face ID / fingerprint / Windows Hello)
- **Phishing-resistant by design** — origin-bound credential, tidak bisa di-phish ke domain lain
- Cross-device sync via iCloud Keychain / Google Password Manager (encrypted end-to-end)

Ini **revolusi yang sedang terjadi sekarang**. Level 1 (TOTP/SMS) → Level 6 (Passwordless) transisi massal 2025–2027.

### 4. Decentralized Identity (Level 5) Mengubah Trust Model

PKI tradisional (Level 5 Kriptografi): **CA hierarchy** → browser trust Root CA (~150). Kalau CA compromised → seluruh domain tidak aman (DigiNotar 2011).

SSI/DID: **Kunci publik = identifier**. Tidak ada CA. Resolve via blockchain/DHT/P2P. User **pegang private key**. Verifiable Credentials = claim yang diverifikasi tanpa kontak issuer (zero-knowledge proof).

Trade-off:
- ✅ No single point of trust failure
- ✅ User sovereignty
- ❌ Recovery kalau key hilang = **identitas hilang permanen**
- ❌ UX kompleks (wallet, seed phrase, DID method)
- ❌ Interoperabilitas fragmentasi (did:web, did:key, did:ion, did:ethr, dll)

### 5. Zero Trust (Level 6) Bukan Produk — Itu Arsitektur

Vendor jual "Zero Trust solution" tapi Zero Trust adalah **prinsip arsitektur**:
- **Verify explicitly** — selalu autentikasi & otorisasi (tidak percaya network location)
- **Least privilege access** — just-in-time, just-enough access (JIT/JEA)
- **Assume breach** — segmentasi mikro, deteksi lateral movement, encrypt everything

Implementasi butuh: Identity Provider (IdP) mature + Device Trust (MDM/EDR) + Network Segmentation (micro-segmentation) + Policy Engine (OPA/Rego) + Continuous Monitoring (SIEM/UEBA).

Organisasi yang "beli Zero Trust" tapi IdP-nya lemah, device unmanaged, jaringan flat — **bukan Zero Trust, cuma marketing**.

---

## Plot Twists

> [!danger] Plot Twist 1: Biometrik Bisa Di-Churi Tanpa Kamu Sadari (dan Tidak Bisa Di-Ganti)
> 2015: OPM breach (US Office of Personnel Management) — **5.6 juta fingerprint** karyawan federal dicuri. 2019: BioStar 2 (biometric access control) — 27.8 juta record fingerprint + face bocor publik. Berbeda password, **kamu tidak bisa ganti jari tangan**. Inilah kenapa cancelable biometrics (ISO 24745) wajib untuk deployment skala besar — tapi kebanyakan vendor skip karena "terlalu ribet."

> [!danger] Plot Twist 2: MFA Fatigue Attack — Manusia Adalah Titik Lemah
> 2022: Uber breach — attacker spam push notification MFA ke karyawan sampai **lelaku dan approve**. 2023: MGM Resorts — social engineering + MFA fatigue → ransomware. **Push-based MFA (Microsoft Authenticator, Duo Push) rentan MFA fatigue**. Solusi: **number matching** (user input angka di layar) + **location context** + **FIDO2/WebAuthn** (tidak ada push, hanya biometrik lokal). TOTP lebih aman dari push notification.

> [!danger] Plot Twist 3: SIM Swap = Bypass SMS 2FA Dalam Menit
> SMS OTP (Level 1 paling lemah) masih dipakai bank & gov Indonesia. Attacker: social engineering ke call center operator seluler → port nomor ke SIM baru → terima OTP. **Biaya SIM swap: Rp 50.000–500.000 + social engineering skill**. Impact: akses banking, email, crypto exchange. Solusi: **hapus SMS OTP**, wajibkan TOTP/FIDO2. Bank Indonesia sudah arahkan (2023) tapi adopsi lambat.

> [!tip] Plot Twist 4: Behavioral Biometrics Bisa Di-Tiru AI (Adversarial ML)
> Keystroke dynamics, mouse movement, gait — semuanya **bisa di-modelkan** oleh attacker yang punya cukup data. Paper 2023: "DeepMasterPrints" → generative AI bikin fingerprint sintetis yang match banyak user. Paper 2024: "PassGPT" → generative password model. Paper 2024: "Behavioral cloning" → merekam session user, latih policy network, replay. **Behavioral biometrics tanpa continuous challenge-response = static target**.

> [!info] Plot Twist 5: Passkey Recovery Masih Unsolved UX Problem
> User kehilangan device yang punya passkey → bagaimana recovery?
> - Apple: iCloud Keychain escrow (butuh device Apple lain + password Apple ID)
> - Google: Google Password Manager (butuh login Google account + device trusted)
> - Microsoft: Windows Hello + Microsoft Authenticator backup
> - Cross-platform: **belum standar**. FIDO Alliance kerja pada "credential exchange protocol" tapi belum final.
> Inilah hambatan adopsi enterprise massal — **recovery flow yang confusing membuat IT support rollback ke password**.

> [!info] Plot Twist 6: Neural/BCI (Level 7) Akan Bikin "Passthought" Jadi Factor
> "Passthought" = pikir stimulus tertentu (misal: "bayangkan rumah masa kecil") → EEG signature unik → authenticate. **Tidak ada yang bisa di-curi** karena ada di otak. Tapi: EEG headset sekarang mahal (USD 300–1000), noise sensitivity tinggi, butuh training kalibrasi per user. Neuralink (invasive) demonstration 2024: tetraplegic player chess dengan pikiran. **Privasi otak = privacy frontier paling ekstrem** — siapa punya hak data neural signature kamu?

---

## Migration Roadmap — 2026 Menuju Passwordless + Zero Trust

| Fase | Timeline | Action Items |
|---|---|---|
| **Audit & Baseline** | 2025 Q4 | Inventarisasi semua autentikasi method. Identifikasi SMS OTP, password-only, legacy MFA |
| **Kill SMS OTP** | 2026 Q1–Q2 | Wajibkan TOTP/FIDO2 untuk semua akses kritis. Deploy authenticator app enterprise (Microsoft Authenticator, Authy, 1Password) |
| **Deploy FIDO2/WebAuthn** | 2026 Q2–Q3 | Passkey support di semua aplikasi internal & customer-facing. Hardware key (YubiKey) untuk admin & high-value |
| **Device Trust + Posture** | 2026 Q3–Q4 | MDM/EDR enrollment wajib. Device health check (OS patch, disk encryption, AV) sebelum akses resource |
| **Continuous Auth Pilot** | 2027 Q1 | Behavioral biometrics (keystroke/mouse) untuk high-risk session (admin panel, financial approval) |
| **Zero Trust Architecture** | 2027–2028 | Micro-segmentation, policy engine (OPA), identity-aware proxy, JIT/JEA access |
| **Decentralized Identity** | 2028+ | DID/VC untuk partner ecosystem, supply chain, academic credential (EU DI Wallet 2026 driver) |
| **Neural/BCI Watch** | 2030+ | Monitor penelitian EEG passthought, cardiac rhythm continuous auth — evaluasi untuk ultra-high-security niche |

Passwordless bukan endpoint — itu **starting line** untuk Zero Trust.

---

## Sumber & Telusur Lebih Lanjut

- **Library Sheet 2 (Biometrik Lengkap)** → [[cryptography-biometrics]] (Level 0–7 tabel + trust chain diagram)
- **Library Sheet 1 (Kriptografi)** → [[cryptography-biometrics]] (AES, RSA, ECC, PQC — kripto yang melindungi biometrik)
- **Zero Trust Architecture** → [[cloud-infrastructure]] (BeyondCorp, SASE, identity-aware proxy)
- **Endpoint Detection (Device Posture)** → [[endpoint-detection-playbook]] (EDR, device health, persistence)
- **Hardware Security (Secure Enclave/TPM)** → [[hardware-hacking-re]] (TEE, TPM 2.0, secure boot)
- **Network Identity (Zero Trust Network)** → [[hierarchy-network-security]] (Layer 7 identity-aware)
- **Master Index** → [[master-index]]

---

> Hirarki biometrik adalah hirarki **kepercayaan yang semakin dalam**. Password = percaya kamu tahu rahasia. MFA = percaya kamu punya device. Biometrik = percaya kamu *adalah* kamu. Behavioral = percaya kamu *berperilaku* seperti kamu. Zero Trust = **tidak percaya apa pun, verifikasi terus-menerus**. Neural = percaya *sinyal otak* kamu.
>
> Organisasi yang paham hirarki ini tidak "beli MFA" — mereka **desain trust chain** dari Level 0 sampai level yang threat model mereka butuhkan.

*Biometrics & Identity Hierarchy | Level 0 (Password) → Level 7 (Neural/BCI) · Dari Something You Know ke Who You Are at Neural Level*