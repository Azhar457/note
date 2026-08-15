---
title: Biometric Authentication Security Deepdive
tags:
- biometrics
- authentication
- iam
- presentation-attack
- template-protection
- identity
- library
aliases:
- biometric-auth-security
- biometric-security-deepdive
- keamanan-biometrik
created: '2026-08-04'
updated: '2026-08-04'
status: pending
cssclasses:
  - wide-table
  

---

> [!abstract]
> Biometrik menjawab pertanyaan autentikasi tertua yang tidak pernah benar-benar terjawab password: *something you are*. Tapi "kamu" bukanlah string yang bisa diganti — sekali template biometrik bocor, ia bocor selamanya. Deepdive ini menelusuri dua medan perang utama biometrik modern: **Presentation Attack Detection (PAD)** melawan spoofing fisik/digital, dan **Biometric Template Protection (BTP)** melawan kebocoran irreversibel. Keduanya distandardisasi (ISO/IEC 30107 dan 24745), keduanya saling melengkapi, dan keduanya gagal bila diterapkan parsial — persis pola yang sama dengan keamanan WAF yang hanya memblokir di satu lapisan.

## Daftar Isi
1. [Kenapa Biometrik Berbeda dari Password](#kenapa-biometrik-berbeda-dari-password)
2. [Lanskap Ancaman: Attack Tree Autentikasi Biometrik](#lanskap-ancaman-attack-tree-autentikasi-biometrik)
3. [Presentation Attack Detection (ISO/IEC 30107)](#presentation-attack-detection-isoiec-30107)
4. [Liveness Detection: Teknik dan Batasannya](#liveness-detection-teknik-dan-batasannya)
5. [Biometric Template Protection (ISO/IEC 24745)](#biometric-template-protection-isoiec-24745)
6. [Cancelable Biometrics: Transformasi Non-Invertibel](#cancelable-biometrics-transformasi-non-invertibel)
7. [Biometric Cryptosystems: Fuzzy Extractor dan Secure Sketch](#biometric-cryptosystems-fuzzy-extractor-dan-secure-sketch)
8. [FIDO2, WebAuthn, dan Passkeys: Biometrik sebagai Lokal Authenticator](#fido2-webauthn-dan-passkeys-biometrik-sebagai-lokal-authenticator)
9. [Behavioral Biometrics dan Continuous Authentication](#behavioral-biometrics-dan-continuous-authentication)
10. [Metrik Evaluasi: FAR, FRR, EER, dan Serangan Adversarial](#metrik-evaluasi-far-frr-eer-dan-serangan-adversarial)
11. [Arsitektur Referensi: Biometrik yang Aman End-to-End](#arsitektur-referensi-biometrik-yang-aman-end-to-end)
12. [Koneksi ke Vault](#koneksi-ke-vault)
13. [References](#references)

---

## Kenapa Biometrik Berbeda dari Password

Password adalah *knowledge factor*: ia bisa di-hash, di-reset, dan diganti. Biometrik adalah *inherence factor*: ia adalah properti fisik atau perilaku yang melekat pada tubuh — dan justru di situlah letak perbedaan fundamentalnya dalam model keamanan.

> [!note] Perbedaan Kunci
> Password bocor → reset. Biometrik bocor → **tidak ada tombol reset untuk sidik jari**. Konsekuensi ini mengubah seluruh desain sistem: template tidak boleh disimpan dalam bentuk yang bisa diekstrak balik, dan verifikasi tidak boleh bergantung pada satu sampel statis.

Perbedaan ini bukan sekadar filosofi — ia mengubah arsitektur. Sistem password menyimpan *verifier* (hash) dan membandingkan deterministik. Sistem biometrik menyimpan *reference template* dan membandingkan secara **probabilistik**: dua pengambilan sampel dari jari yang sama tidak pernah identik karena pose, tekanan, dan sensor. Maka verifikasi biometrik selalu melibatkan threshold similarity, yang membuka kelas serangan yang tidak ada di dunia password: **presentation attack** (memalsukan jari/wajah/suara) dan **template attack** (mengekstrak template untuk replay atau cross-matching).

Tabel berikut membandingkan ketiga faktor autentikasi dalam kerangka risiko:

| Properti | Knowledge (password) | Possession (token/FIDO) | Inherence (biometrik) |
|---|---|---|---|
| Revocability | ✅ Mudah diganti | ✅ Mudah diganti | ❌ Tidak bisa diganti |
| Uniqueness | ❌ Bisa sama (reuse) | 🟡 Bisa dicuri bersama | ✅ Melekat pada tubuh |
| Phishing resistance | ❌ Kredensial bisa diketik di situs palsu | ✅ (FIDO2: origin-bound) | ✅ Sampel tidak bisa "diketik" |
| Replay | Hash server-side | Challenge-response | ❌ Tanpa PAD, sampel bisa diputar ulang |
| Server compromise | Hash bisa dipindah (offline crack) | Private key non-exportable | ❌ Template bocor = permanen |
| Usability | Buruk (password fatigue) | Sedang | ✅ Terbaik (tanpa effort) |

Poin terakhir yang sering diabaikan: biometrik pada **perangkat lokal** (Face ID, fingerprint sensor) adalah autentikator yang sangat kuat karena sampel tidak pernah meninggalkan Secure Enclave. Biometrik pada **server** (biometric-on-file) adalah masalah keamanan yang berbeda sama sekali — di situlah PAD dan BTP menjadi wajib. Deepdive ini membedakan kedua konteks itu secara eksplisit di setiap bagian.

---

## Lanskap Ancaman: Attack Tree Autentikasi Biometrik

Attack tree berikut memetakan seluruh jalur kompromi sistem biometrik, dikelompokkan ke lapisan serangan:

```
ATTACK TREE — SISTEM AUTENTIKASI BIOMETRIK
│
├─ 1. PRESENTATION ATTACK (spoofing pada sensor)
│   ├─ 1a. Physical spoof: foto 2D, video replay, mask 3D, gelatin fingerprint, iris print
│   ├─ 1b. Synthetic spoof: deepfake wajah, cloned voice (TTS/VC)
│   ├─ 1c. Adversarial perturbation: patch kecil yang membuat classifier salah klasifikasi
│   └─ 1d. Partial/coordinated: kombinasi sampel asli + palsu (hybrid)
│
├─ 2. TEMPLATE ATTACK (kompromi database / jalur komunikasi)
│   ├─ 2a. DB breach: raw template dicuri → replay ke verifier
│   ├─ 2b. Cross-matching: template dari DB A dipakai di sistem B (unlinkability gagal)
│   ├─ 2c. Reconstruction: template dicoba di-reverse ke citra asli (invertibility)
│   └─ 2d. Hill-climbing: umpan balik skor similarity dipakai untuk iterasi mendekati match
│
├─ 3. SYSTEM ATTACK (bukan biometrik-nya, tapi infrastruktur)
│   ├─ 3a. Man-in-the-middle: sampel diganti di jalur sensor → matcher
│   ├─ 3b. Matcher substitution: mengganti modul pembanding
│   ├─ 3c. Database manipulation: insert template attacker
│   ├─ 3d. Decision override: memotong hasil matcher dan memaksa accept
│   └─ 3e. Denial of service: membanjiri dengan sampel invalid
│
└─ 4. ENROLLMENT / IDENTITY ATTACK
    ├─ 4a. Identity fraud: mendaftar dengan identitas orang lain
    ├─ 4b. Duplicate enrollment: satu orang banyak identitas (sybil)
    └─ 4c. Poisoning: menyuntikkan sampel korban saat enrollment
```

> [!warning] Pelajaran Penting
> PAD (lapisan 1) hanya menangani spoofing di sensor. **Template protection** (lapisan 2) menangani kompromi database. Sebuah sistem bisa punya PAD sempurna dan tetap bocor total lewat DB breach yang mengekspos raw template — atau sebaliknya. Produk komersial sering hanya mempromosikan liveness; insinyur keamanan harus mengecek keduanya.

---

## Presentation Attack Detection (ISO/IEC 30107)

ISO/IEC 30107 adalah standar yang mendefinisikan terminologi, framework, dan evaluasi untuk deteksi serangan presentasi. Bagian-bagiannya:

- **30107-1**: Framework — mendefinisikan *presentation attack* (PA), *presentation attack instrument* (PAI), *presentation attack detection* (PAD), dan skema klasifikasi PAI (spoof, disguise, cosmetic alteration, non-conformant).
- **30107-2**: Data formats — format pertukaran data hasil PAD.
- **30107-3**: Testing dan reporting — prosedur evaluasi yang memberi metrik standar seperti *Attack Presentation Classification Error Rate* (APCER) dan *Bona Fide Presentation Classification Error Rate* (BPCER).

Dua metrik kunci dari 30107-3:

| Metrik | Definisi | Analogi |
|---|---|---|
| **APCER** | Proporsi attack presentations yang *tidak* terdeteksi (diterima sebagai asli) | False acceptance dari sisi attacker |
| **BPCER** | Proporsi bona fide (asli) yang *salah* diklasifikasikan sebagai attack | False rejection dari sisi pengguna sah |
| **IAPMR** | Impostor Attack Presentation Match Rate — seberapa sering attack match dengan template korban | Efektivitas serangan secara end-to-end |

Konsep penting: **PAD bukan binary**. Evaluasi selalu trade-off antara APCER dan BPCER, mirip FAR/FRR pada matcher. Produk yang mengklaim "100% anti-spoofing" berarti menguji pada dataset PAI tertentu — bukan berarti kebal terhadap PAI baru (zero-day presentation attack). Standar 30107-3 juga membedakan level liveness (misalnya iBeta Level 1 = static capture, Level 2 = active/dynamic challenge), yang sering dikutip vendor sebagai sertifikasi.

---

## Liveness Detection: Teknik dan Batasannya

Liveness detection adalah jantung PAD untuk biometrik wajah dan iris. Tekniknya berevolusi dari statis ke dinamis ke pasif-dalam:

| Generasi | Teknik | Contoh | Kelemahan |
|---|---|---|---|
| G1 — Static | Texture/reflection analysis: cek kualitas citra, moiré, glint mata | Deteksi foto 2D via tekstur | Kalah oleh print berkualitas tinggi, mask 3D |
| G2 — Active challenge | User diminta berkedip, menoleh, tersenyum | Bank mobile onboarding | Bisa dibypass video replay yang menjalankan aksi |
| G3 — Depth/3D | Structured light, stereo camera, ToF; cek geometri 3D | Face ID (dot projector 30k titik), ToF selfie | Butuh hardware khusus; mask 3D presisi tinggi masih ancaman |
| G4 — Passive liveness | Deep neural network mengklasifikasi citra asli vs attack tanpa interaksi | PAD CNN (iBeta Level 2 cert) | Black-box; rawan adversarial perturbation |
| G5 — Multimodal/contextual | Gabung wajah + mikro-gerakan + tekstur + suara + metadata perangkat | EKYC modern | Kompleksitas integrasi tinggi |

Batas fundamental: **liveness mengukur "sampel ini datang dari tubuh hidup", bukan "sampel ini milik orang yang tepat"**. Deepfake generatif yang sangat realistis menyerang titik ini — sebuah video sintetis wajah korban dengan gerakan natural tidak "mati" menurut classifier liveness. Di situlah peran *injection attack detection* (mengecek sumber input: kamera asli vs virtual camera) dan *identity binding* (mencocokkan sampel dengan dokumen/device) menjadi penting.

---

## Biometric Template Protection (ISO/IEC 24745)

ISO/IEC 24745 menetapkan tiga properti yang harus dipenuhi perlindungan template biometrik:

1. **Irreversibility** — tidak mungkin (secara komputasional) merekonstruksi data biometrik asli dari reference template.
2. **Unlinkability** — template dari subjek yang sama di dua aplikasi berbeda tidak bisa dicocokkan (cross-matching dicegah). Setiap aplikasi memakai transformasi berbeda.
3. **Renewability/Revocability** — bila template dikompromi, bisa diterbitkan template baru dari data biometrik yang sama (atau dibatalkan total).

Ketiga properti ini membentuk segitiga yang sulit: transformasi yang membuat template *unlinkable* sekaligus *revocable* cenderung menurunkan akurasi matching, karena transformasi non-invertibel menghilangkan informasi. Trade-off ini adalah masalah riset inti BTP — tabel perbandingan pendekatan:

| Pendekatan | Irreversibility | Unlinkability | Revocability | Dampak akurasi | Contoh |
|---|---|---|---|---|---|
| Raw template (tanpa proteksi) | ❌ | ❌ | ❌ | — (baseline) | Legacy DB |
| Encryption (AES) | 🟡 (reversible dgn kunci) | ❌ (satu kunci) | 🟡 | Netral | Encrypted DB |
| Cancelable biometrics | ✅ (non-invertibel) | ✅ (transform per-app) | ✅ (ganti transform) | Turun sedikit | BioHashing, random projection |
| Biometric cryptosystem (fuzzy extractor) | ✅ (hanya helper data) | ✅ (salt per-app) | ✅ (ganti salt) | Turun (error correction) | Fuzzy commitment, secure sketch |
| Homomorphic encryption | 🟡 (matematis aman, tapi matching di ciphertext) | ✅ | ✅ | Turun drastis (noise HE) | HE-based matching (riset) |

---

## Cancelable Biometrics: Transformasi Non-Invertibel

Cancelable biometrics bekerja dengan menerapkan **transformasi parametrik** pada template (atau fitur) sehingga:

- Hasilnya *non-invertibel*: dari `T(template, k)` tidak bisa didapat `template` tanpa brute force `k`.
- Parameter `k` bersifat per-aplikasi → *unlinkable*.
- Bila `k` bocor/kompromi, ganti `k` → template baru → *revocable*.

Contoh skema kanonik:

```
FITUR BIOMETRIK x (mis. vektor 512-d)
        │
        ▼
BIOHASHING / RANDOM PROJECTION:
  y = sign( A · x )        A = matriks acak (parameter k)
        │
        ▼
TEMPLATE YANG DISIMPAN: bitstring y (non-invertibel dari x)
        │
        ▼
MATCHING: Hamming distance antara y₁ dan y₂
  (threshold menentukan accept/reject)
```

Keterbatasan yang sudah terdokumentasi di literatur: transformasi linear (seperti BioHashing klasik) rentan terhadap *hill-climbing* dan *stolen-token* attack bila parameter `k` diketahui — karena matching terjadi di ruang transformasi, attacker dengan akses `k` bisa melakukan iterasi. Skema modern menjawab dengan transformasi non-linear, *random orthonormal projection*, dan deep learning-based cancelable transforms yang mempelajari representasi sekaligus non-invertibel.

---

## Biometric Cryptosystems: Fuzzy Extractor dan Secure Sketch

Berbeda dengan cancelable biometrics yang menyimpan *template hasil transformasi*, biometric cryptosystems menyimpan **helper data** dan meleburkan biometrik dengan kriptografi. Dua primitif kunci diperkenalkan oleh Dodis et al. (2004):

- **Secure Sketch**: menyimpan `ss = sketch(x)` sedemikian sehingga bila input `x'` dekat dengan `x` (jarak < t), `recover(ss, x')` mengembalikan `x` persis. Helper data tidak membocorkan `x` secara langsung, tapi *mengurangi entropi*-nya — informasi tentang `x` memang bocor melalui sketch, dan ini diukur secara kuantitatif.
- **Fuzzy Extractor**: mengekstrak **key seragam** `R` dari biometrik `x` dengan bantuan helper `P`. Properti penting: `R` bisa dipakai sebagai kunci kriptografi (mis. untuk enkripsi), dan *Gen/Rep* bersifat re-usable dengan salt berbeda → revocable.

Konsekuensi keamanan yang jarang dipahami:

1. **Entropi biometrik itu kecil.** Sidik jari punya entropi efektif jauh di bawah 256-bit; iris lebih tinggi tapi tetap tidak setara kunci acak. Maka `R` yang diekstrak tidak pernah "seseragam" kunci dari CSPRNG — kombinasi dengan password/PIN (*key amplification*) sering diperlukan untuk mencapai kekuatan kunci penuh.
2. **Helper data tidak pernah zero-knowledge.** `P` selalu bocor sebagian informasi. Ukuran bocornya ditentukan oleh parameter *entropy loss*, dan desain yang baik meminimalkannya.
3. **Error correction adalah biaya.** Karena dua sampel biometrik tidak identik, fuzzy extractor butuh kode koreksi error (BCH, Reed-Solomon, polar codes). Koreksi error yang besar = toleransi noise tinggi = keamanan lebih rendah.

---

## FIDO2, WebAuthn, dan Passkeys: Biometrik sebagai Lokal Authenticator

Paradoks biometrik terpecahkan oleh arsitektur FIDO2: **biometrik tidak pernah menjadi rahasia bersama (shared secret)**. Dalam model ini:

- Biometrik hanya membuka kunci **private key** yang tersimpan di Secure Enclave/TPM perangkat — sample tidak pernah dikirim ke server.
- Server hanya menyimpan **public key** yang tidak berguna bila bocor.
- Autentikasi memakai challenge-response dengan *origin binding*: signature hanya valid untuk origin (domain) tertentu → **phishing-resistant**, karena situs palsu tidak bisa memanfaatkan kredensial yang ditandatangani untuk domain berbeda.

```
PERANGKAT PENGGUNA                     SERVER (Relying Party)
┌─────────────────────────┐            ┌──────────────────────────┐
│ Secure Enclave          │            │  Public key (dari enroll)│
│  • private key (non-    │            │  • challenge → verify    │
│    exportable)          │            │  • signature → verify    │
│  • biometrik hanya      │            │  • origin check          │
│    membuka akses kunci  │            └──────────────────────────┘
└─────────────────────────┘
   ▲ sampel biometrik TIDAK PERNAH
   │ keluar dari perangkat
   └── face/fingerprint → Enclave
```

NIST SP 800-63B (revisi 4, 2025) mengkodifikasi ini: **AAL3** mengharuskan authenticator kriptografis dengan private key non-exportable dan phishing resistance — dan FIDO2/WebAuthn adalah satu-satunya kelas yang secara luas tersedia memenuhi keduanya. *Passkeys* adalah implementasi konsumen: discoverable credential yang tersinkron lintas perangkat (via cloud keychain), dengan biometrik sebagai user verification.

> [!note] Implikasi untuk Insinyur
> Di konteks enterprise, biometrik-on-file (server-side matching) harus dibatasi untuk skenario yang memang membutuhkannya (mis. verifikasi identitas onboarding EKYC). Untuk *login berulang*, FIDO2/WebAuthn selalu lebih unggul: serangan terhadap biometrik menjadi serangan terhadap perangkat, dan kompromi server tidak mengekspos apa pun yang bisa direplay.

---

## Behavioral Biometrics dan Continuous Authentication

Physical biometrics menjawab "siapa kamu" sekali di pintu masuk. Behavioral biometrics menjawab "apakah ini masih kamu" **sepanjang sesi** — dengan menganalisis *pola interaksi*: keystroke dynamics (dwell time, flight time antar tombol), mouse movement, gait (dari accelerometer), touch gestures, dan device usage profile.

Ciri khas yang membedakannya dari biometrik fisik:

| Aspek | Physical biometrics | Behavioral biometrics |
|---|---|---|
| Sampel | Statis, sekali capture | Streaming, kontinu |
| Verifikasi | One-shot | Sliding window + risk scoring |
| Stabilitas | Tinggi (fisiologi) | Rendah (berubah saat stres/lelah/sakit) |
| False reject | Terkendali | Lebih sering (perubahan ritme) |
| Serangan utama | Presentation attack | Imitasi/adversarial generation |
| Peran | Identity gate | Risk signal (dipadukan dengan policy) |

Dalam praktik, behavioral biometrics jarang menjadi *satu-satunya* gate — ia menjadi **risk signal** dalam continuous authentication: skor anomali menurunkan trust, memicu step-up authentication (mis. ulangi biometrik fisik, atau TOTP). Kelemahan riset yang harus diwaspadai: model behavioral bisa ditiru oleh adversarial generator bila dataset latihnya bocor, dan false-reject naik signifikan pada pengguna dengan pola tidak stabil — trade-off yang sama dengan PAD (APCER vs BPCER).

---

## Metrik Evaluasi: FAR, FRR, EER, dan Serangan Adversarial

Semua sistem biometrik dievaluasi dengan metrik kesalahan yang saling terkait:

| Metrik | Definisi | Implikasi |
|---|---|---|
| **FAR** (False Acceptance Rate) | Proporsi impostor yang diterima | Semakin rendah semakin aman; naik saat threshold longgar |
| **FRR** (False Rejection Rate) | Proporsi pengguna sah yang ditolak | Semakin rendah semakin nyaman; naik saat threshold ketat |
| **EER/CER** (Equal/Crossover Error Rate) | Titik di mana FAR = FRR | Angka tunggal pembanding akurasi antar sistem |
| **APCER/BPCER** (PAD) | Kesalahan klasifikasi attack vs asli | Metrik khusus liveness (ISO 30107-3) |
| **IAPMR** | Attack match rate end-to-end | Efektivitas attack yang lolos PAD *dan* match |

Pelajaran penting: **tidak ada threshold yang menang di kedua arah**. FAR dan FRR adalah trade-off; memilih titik operasi adalah keputusan bisnis (bank memilih FAR sangat rendah, aplikasi konsumen memilih FRR rendah). Vendor yang mempromosikan akurasi 99% biasanya melaporkan pada EER atau dataset yang menguntungkan — verifikasi selalu pada dataset dan threshold yang sama.

**Adversarial machine learning** menambah dimensi baru: perturbation kecil (patch pada wajah, noise pada suara) yang tak terlihat manusia bisa membuat matcher salah klasifikasi — baik false accept (attack) maupun false reject (denial of service). Ini menyerang dua arah dan tidak terselesaikan oleh PAD konvensional, karena inputnya *asli* — hanya dimodifikasi secara mikro.

---

## Arsitektur Referensi: Biometrik yang Aman End-to-End

Mensintesis seluruh bagian di atas menjadi arsitektur yang bisa diterapkan:

```
ENROLLMENT                          VERIFICATION
─────────                           ────────────
Capture sensor                      Capture sensor
   │  (PAD: liveness +              │  (PAD: liveness +
   │   injection detection)         │   injection detection)
   ▼                                ▼
Feature extraction                  Feature extraction
   │                                │
   ▼                                ▼
Template protection                 Transform dengan parameter k
(cancelable / fuzzy extractor)      yang SAMA (per-user, per-app)
   │                                │
   ▼                                ▼
Simpan HANYA: helper data           Matching di ruang transformasi
atau transformed template           (threshold + FAR/FRR policy)
   │                                │
   ▼                                ▼
Audit log (tanpa data               Decision → risk score →
biometrik mentah)                   step-up / grant
```

Checklist non-negotiable:

1. **PAD wajib** (ISO 30107-3) — tanpa liveness, foto/video cukup untuk bypass.
2. **Template protection wajib** (ISO 24745) — irreversibility, unlinkability, renewability.
3. **Tidak pernah menyimpan raw sample atau template ter-enkripsi saja** — enkripsi dengan kunci yang sama berarti satu kunci bocor = semua template terbuka.
4. **Biometrik lokal (FIDO2) diutamakan untuk login** — server-side matching hanya untuk skenario verifikasi identitas.
5. **Rate limiting dan anomaly detection** — mencegah hill-climbing dan brute-force berulang.
6. **Audit log tanpa data sensitif** — log cukup menyimpan event dan decision, bukan sampel.
7. **Proses revocability yang teruji** — jalur recovery saat template kompromi harus nyata, bukan teori.

---

## Koneksi ke Vault

- [[hierarchy-biometrics]] — peta level 0-7 evolusi autentikasi; deepdive ini mengisi detail teknis level 2-4 (fisik + behavioral) dan level 6 (zero trust/passkeys).
- [[hierarchy-identity-trust]] — kerangka trust chain; BTP dan PAD adalah dua sisi dari *identity proofing* yang aman.
- [[identity-and-access-management]] — fondasi IAM; bagian FIDO2/passkeys di sini memperdalam MFA phishing-resistant.
- [[hierarchy-cryptography]] — fuzzy extractor dan helper data adalah aplikasi kriptografi pada data noisy; relevan dengan topik cryptographic key derivation.
- [[active-directory-windows-security-deepdive]] — implementasi identity di Windows (Windows Hello memakai model FIDO2/TPM yang sama).
- [[hierarchy-threat-modeling]] — attack tree di bagian 2 bisa dipakai sebagai contoh langsung threat modeling berbasis asset.
- [[hierarchy-endpoint-security]] — biometrik lokal (Secure Enclave/TPM) adalah kontrol endpoint-level.

---

## References

1. ISO/IEC 30107-3 — Biometric presentation attack detection — testing and reporting. https://www.iso.org/standard/83828.html
2. ISO/IEC 24745:2022 — Biometric information protection. https://www.iso.org/standard/75302.html
3. NIST SP 800-63B-4 — Digital Identity Guidelines: Authentication & Authenticator Management. https://pages.nist.gov/800-63-4/sp800-63b/authenticators/
4. FIDO Alliance — Passkeys (WebAuthn/FIDO2 overview). https://fidoalliance.org/passkeys/
5. Patel, V.M. et al. — Cancelable Biometrics: A Review (IEEE Signal Processing Magazine). https://engineering.jhu.edu/vpatel36/wp-content/uploads/2018/08/SPM_CB_v6.pdf
6. Wang, et al. — Cancelable Biometric Template Generation Using Random Feature Transformations (arXiv:2503.15648). https://arxiv.org/abs/2503.15648
7. Dodis, Y., Ostrovsky, R., Reyzin, L. — Fuzzy Extractors: How to Generate Strong Keys from Biometrics and Other Noisy Data (EUROCRYPT 2004). https://arxiv.org/abs/cs/0402007
8. Uhl, A. — A Survey on Biometric Cryptosystems and Cancelable Biometrics (EURASIP J. Inf. Security). https://arxiv.org/pdf/1904.00264
9. Yang, W. et al. — A Survey on Biometrics Authentication (arXiv:2212.08224). https://arxiv.org/abs/2212.08224
10. Europol — Biometric vulnerabilities: Ensuring future law enforcement capabilities. https://www.europol.europa.eu/cms/sites/default/files/documents/Biometric-vulnerabilities.pdf
11. Continual Learning for Behavioral Biometrics — Continuous Authentication for Mobile Devices (MDPI Technologies). https://www.mdpi.com/2227-7080/14/7/451
12. IEEE — Continuous Authentication Using Behavioral Biometrics (ACM CCS talk). https://dl.acm.org/doi/10.1145/3041008.3041019
13. Signzy — FAR vs FRR: Biometric Error Rates, EER & Banking Use Explained. https://www.signzy.com/general-glossary/far-frr-biometric-error-rates
14. iProov — Dynamic Liveness & ISO 19795 evaluation. https://www.iproov.com/certifications
15. Biometric Update — 2025 Face Liveness Market Report and Buyer's Guide. https://www.biometricupdate.com/wp-content/uploads/2025/11/Biometric-Update-2025-Facial-Liveness-Report.pdf
---

audited
---
