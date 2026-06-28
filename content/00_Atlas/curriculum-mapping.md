---
tags:
  - kurikulum
  - learning-path
  - matematika
  - CS
  - security
  - roadmap
aliases:
  - Kurikulum Mapping
  - Learning Path
  - Mata Kuliah CS Bridge
created: 2026-04-25
status: active
---

# 🎓 KURIKULUM MAPPING — Pendidikan Matematika → CS/Security

> Peta jembatan antara kurikulum resmi jurusan dan vault CS/Security yang sudah dibangun. Posisi ini langka: matematika formal yang dalam + minat systems/security = kombinasi yang tidak dimiliki mayoritas engineer.

> [!tip] Keunggulan Posisi Ini
> Mayoritas anak CS lemah di math formal (Teori Bilangan, Analisis Real, Struktur Aljabar). Mayoritas anak Math tidak tahu cara kerja sistem komputer. Kamu berada di **titik temu** — lokasi paling subur untuk penemuan baru dan karir yang tidak biasa.

---

## Tier 1 — 🔴 Langsung Dipakai, Prioritas Tinggi

### Aljabar Linear

```
Kuliah cover : Vektor, matriks, eigenvalue, transformasi linear
CS/Security  : SEMUA neural network (setiap layer = matrix multiply)
               PCA untuk dimensionality reduction
               Computer graphics (rotation, projection matrix)
               Kriptografi (lattice-based post-quantum crypto)
Masuk ke     : MATEMATIKA_ALGORITMA.md → Sheet Linear Algebra
Aksi         : Sambungkan kuliah dengan implementasi NumPy/PyTorch
               Setiap operasi matrix di kuliah → coba implementasi kode
```

### Pengantar Teori Bilangan

```
Kuliah cover : Divisibilitas, GCD, aritmetika modular, bilangan prima
CS/Security  : FONDASI LANGSUNG RSA, Diffie-Hellman, ECC
               Fermat little theorem → dipakai di RSA
               Chinese Remainder Theorem → dipakai di RSA optimization
               Euler totient → dipakai di key generation
Masuk ke     : KRIPTOGRAFI_BIOMETRIK.md → Level 2 Asymmetric Crypto
               MATEMATIKA_ALGORITMA.md → Teori Bilangan
Aksi         : Implementasi RSA dari scratch pakai Python setelah belajar
               modul ini — tidak ada cara lebih baik untuk validasi paham
```

### Pengantar Statistika + Statistika Pendidikan

```
Kuliah cover : Distribusi, uji hipotesis, p-value, regresi, ANOVA
CS/Security  : Research Methodology (p-value, confidence interval)
               ML evaluation (precision, recall, F1, AUC-ROC)
               Security: timing attack analysis butuh statistik
               Network anomaly detection = statistik behavioral
Masuk ke     : RESEARCH_METHODOLOGY.md → Sheet Analysis & Interpretation
               MATEMATIKA_ALGORITMA.md → Probabilitas Diskrit
Aksi         : Pelajari perbedaan statistik deskriptif vs inferensial
               dengan konteks security — bukan pendidikan
```

### Pemrograman Komputer 1 & 2

```
Kuliah cover : Dasar algoritma, struktur kontrol, fungsi, OOP (kemungkinan)
CS/Security  : Entry point ke SEMUA yang teknis di vault
               Tanpa ini, semua hierarki di vault hanya teori
Masuk ke     : FONDASI_CS.md (sebagai prasyarat)
               Semua file lain sebagai implementasi
Aksi         : Jangan berhenti di level kuliah
               Target: bisa baca kode orang lain di GitHub
               Target: bisa debug tanpa takut error
               Bahasa rekomendasi: Python (cepat) + C (fundamental)
```

### Metode Numerik

```
Kuliah cover : Floating point, iterasi Newton-Raphson, interpolasi,
               integrasi numerik, PDE numerik
CS/Security  : Floating point error → sumber bug subtle di kriptografi
               Implementasi neural network butuh numerical stability
               Iterasi = fondasi gradient descent di ML
               Signal processing (FFT = numerik)
Masuk ke     : MATEMATIKA_ALGORITMA.md
Aksi         : Implementasi semua metode di kuliah dengan Python/NumPy
               bukan hanya hitung manual
```

---

## Tier 2 — 🟡 Berguna, Perlu Disambungkan Aktif

### Kalkulus 1 & 2

```
Kuliah cover : Limit, turunan, integral, deret Taylor, multivariabel
CS/Security  : Gradient descent = turunan (backpropagation di DL)
               Deret Taylor → approximation dalam numerical method
               Integral → probability distribution (area under curve)
               Multivariabel → optimization landscape di ML
Masuk ke     : MATEMATIKA_ALGORITMA.md
Gap          : Kuliah biasanya tidak tunjukkan koneksi ke ML
               Kamu harus buat koneksi ini sendiri
Aksi         : Setiap konsep kalkulus → cari "ini dipakai di ML bagaimana"
```

### Pengantar Analisis Real 1 & 2

```
Kuliah cover : Epsilon-delta, konvergensi, kontinuitas, deret,
               metrik space, teorema nilai rata-rata
CS/Security  : Melatih berpikir formal dan proof — meta-skill
               Konvergensi → ML convergence guarantee
               Metrik space → distance function di ML (fondasi kNN, clustering)
               Teorema nilai rata-rata → analisis algoritma formal
Masuk ke     : MATEMATIKA_ALGORITMA.md + RESEARCH_METHODOLOGY.md
Nilai        : Bukan kontennya yang langsung terpakai, tapi
               kemampuan berpikir rigorous yang dilatih di sini
               SANGAT langka di kalangan engineer
```

### Pengantar Struktur Aljabar

```
Kuliah cover : Group, ring, field, homomorphism, isomorphism
CS/Security  : Group theory → FONDASI kriptografi kurva eliptik (ECC)
               Field → Finite field GF(2^8) dipakai di AES S-Box
               Ring → Lattice-based post-quantum crypto (CRYSTALS-Kyber)
               Galois field → coding theory, error correction
Masuk ke     : KRIPTOGRAFI_BIOMETRIK.md → Level 7 Post-Quantum
               MATEMATIKA_ALGORITMA.md
Aksi         : Saat belajar grup, langsung tanyakan:
               "Grup ini dipakai di kriptografi mana?"
```

### Pengantar Dasar Matematika

```
Kuliah cover : Logika proposisional, himpunan, relasi, fungsi, induksi
CS/Security  : Logika → fondasi AI Level 0 (IF-THEN), SAT solver
               Himpunan → relational algebra (database)
               Induksi → proof teknik untuk algoritma correctness
               Fungsi bijektif → fondasi kriptografi (one-way function)
Masuk ke     : MATEMATIKA_ALGORITMA.md → Sheet Matematika Diskrit
```

### Fungsi Kompleks

```
Kuliah cover : Bilangan kompleks, fungsi analitik, transformasi konformal,
               integral kontur, deret Laurent, residu
CS/Security  : FFT (Fast Fourier Transform) = fondasi signal processing
               RF/SIGINT: analisis sinyal di domain frekuensi
               Quantum computing: amplitudo quantum = bilangan kompleks
               Kriptografi: beberapa skema pakai grup di bilangan kompleks
Masuk ke     : OSINT_RF_HIERARCHY.md (koneksi ke signal processing)
               MATEMATIKA_ALGORITMA.md
Nilai        : Jarang dibutuhkan langsung, tapi buka pintu ke
               signal processing dan quantum computing secara formal
```

### Geometri Dasar & Geometri Transformasi

```
Kuliah cover : Euclid, transformasi (rotasi, refleksi, translasi, dilatasi),
               geometri koordinat, vektor geometri
CS/Security  : Computer graphics: setiap transformasi 3D = matrix 4x4
               Computer vision: homography, camera projection matrix
               Robotics: kinematik, frame transformation (SE(3))
               SLAM: peta 3D = akumulasi transformasi
Masuk ke     : MATEMATIKA_ALGORITMA.md → Linear Algebra (transformasi)
               EMBEDDED_SYSTEMS.md → Sensor Fusion (frame transform)
```

---

## Tier 3 — 🟢 Nilai Tidak Langsung, Konteks Riset

### Metode Survey

```
Kuliah cover : Desain kuesioner, sampling, analisis data survei
CS/Security  : User study dalam research (usability, security UX)
               HCI research: evaluasi interface security tool
               Social engineering research: survei untuk threat modeling
Masuk ke     : RESEARCH_METHODOLOGY.md → Sheet Tipe Penelitian
```

### Metodologi Pembelajaran Matematika + Kapita Selekta

```
Kuliah cover : Pendekatan penelitian, desain pembelajaran, analisis kritis
CS/Security  : Research methodology mindset yang overlap
               Kapita selekta = survey topik terkini → mirip literature review
Masuk ke     : RESEARCH_METHODOLOGY.md
```

### Pengantar Analisis Real (aspek proof)

```
Nilai tidak langsung : Kemampuan membaca dan menulis mathematical proof
                       → diperlukan untuk membaca paper kriptografi
                       → diperlukan untuk formal verification (security)
                       → paling langka di kalangan software engineer
```

---

## Tier 4 — ⚪ Konteks Jurusan, Tidak Masuk Vault CS

| Mata Kuliah                             | Catatan                                                                                                                      |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Problematika Pendidikan Matematika**  | Domain pendidikan murni                                                                                                      |
| **Media Pembelajaran**                  | Relevan jika kamu buat security awareness training suatu hari                                                                |
| **Kurikulum & Pembelajaran**            | Domain pendidikan murni                                                                                                      |
| **Micro Teaching**                      | Tapi: kemampuan mengajar kompleks = kemampuan jelaskan teknis ke non-teknis. Berguna di security awareness, presentasi riset |
| **Perencanaan Pembelajaran Matematika** | Domain pendidikan murni                                                                                                      |

> [!info] Catatan Tier 4
> Jangan buang skill ini sepenuhnya. Kemampuan **menjelaskan konsep kompleks secara sederhana** (Feynman Technique) yang dilatih di mata kuliah pendidikan adalah skill yang sangat langka di kalangan engineer dan peneliti.

---

## Self-Study Wajib — Yang Tidak Ada di Kurikulum

Ini gap yang harus ditutup sendiri karena tidak ada di kurikulum Pendidikan Matematika:

| Topik                         | Kenapa Wajib                       | Resource                                           | Target Waktu         |
| ----------------------------- | ---------------------------------- | -------------------------------------------------- | -------------------- |
| **Algoritma & Struktur Data** | Fondasi semua engineering          | CLRS (buku) + LeetCode (praktik)                   | Semester ini paralel |
| **Jaringan Komputer**         | Fondasi Network Security           | Tanenbaum "Computer Networks" + Wireshark langsung | Semester depan       |
| **OS Fundamentals**           | Fondasi semua yang low-level       | xv6 MIT (baca + run)                               | Semester depan       |
| **Linux Command Line**        | Tool utama semua security research | `man` pages + OverTheWire Bandit (wargame)         | Bulan ini            |
| **Git & Version Control**     | Wajib untuk semua proyek           | Pro Git (gratis online)                            | Minggu ini           |

---

## Learning Path Visual

```
SEKARANG (Aktif Kuliah)
│
├── Pemrog 1 & 2 ──────────────────────────────────────────► Python + C
│   └── Paralel self-study: Algoritma & DS (LeetCode)
│
├── Aljabar Linear ─────────────────────────────────────────► NumPy impl
│   └── Sambungkan: PyTorch tensor = matrix operation
│
├── Teori Bilangan ─────────────────────────────────────────► RSA scratch
│   └── Sambungkan: implementasi RSA tanpa library
│
└── Statistika ─────────────────────────────────────────────► Python scipy
    └── Sambungkan: ML evaluation metric

SEMESTER BERIKUTNYA
│
├── Struktur Aljabar ───────────────────────────────────────► ECC deep dive
├── Analisis Real ──────────────────────────────────────────► Proof skill
├── Self-study: Jaringan + OS ──────────────────────────────► FONDASI_CS
└── Mulai CTF (picoCTF → pwn.college)

MENENGAH
│
├── Semua vault sudah punya fondasi matematika formal
├── Pilih 1-2 spesialisasi dari hierarki yang sudah ada
└── Mulai research: baca paper → reproduce → extend → publish

JANGKA PANJANG
│
└── Titik temu Math formal + CS Security = kontribusi original
    Kemungkinan area: kriptografi pasca-kuantum, formal verification,
    privacy-preserving ML, atau yang belum terpikirkan sekarang
```

---

## Satu Insight Penting

> [!warning] Jebakan yang Perlu Dihindari
> Banyak mahasiswa Pendidikan Matematika yang jago math tapi tidak pernah sambungkan ke implementasi nyata. Dan banyak mahasiswa CS yang bisa coding tapi tidak punya fondasi formal untuk memahami _mengapa_ sesuatu bekerja atau _membuktikan_ bahwa sesuatu aman.
>
> Kamu punya kesempatan untuk tidak jatuh di salah satu jebakan ini.
> **Setiap konsep math yang dipelajari di kuliah → cari implementasinya dalam kode.**
> **Setiap sistem yang dipelajari di vault → tanyakan fondasi matematikanya apa.**
> Dua arah. Terus menerus.

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[math-and-algorithms|Matematika & Algoritma]] — destinasi utama sebagian besar mata kuliah
- [[cryptography-biometrics|Kriptografi & Biometrik]] — aplikasi Teori Bilangan + Struktur Aljabar
- [[research-methodology|Research Methodology]] — aplikasi Statistika + Metode Survey
- [[computer-science-foundations|Computer Science Foundations]] — jembatan dari Pemrograman ke systems

---

_Kurikulum Mapping | Pendidikan Matematika → CS/Security Learning Path_
