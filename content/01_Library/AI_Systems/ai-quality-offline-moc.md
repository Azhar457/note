---
title: MOC — AI, Software Quality & Offline Infrastructure
tags:
  - library
created: "2026-07-06"
updated: "2026-07-06"
status: pending
---

# 📚 Learning Companion: Tiga Buku Teknologi

## Panduan Belajar Komprehensif — AI, Kualitas Perangkat Lunak & Internet Offline

---

## 🎯 Visi Learning Path

Tiga buku ini membentuk **tiga pilar kompetensi teknologi** yang saling melengkapi:

```
         ┌─────────────────────────────────────┐
         │     🧠 BOOK 1: ARTIFICIAL           │
         │        INTELLIGENCE               │
         │   (Algoritma & Optimasi Cerdas)    │
         │         Imam Robandi              │
         └──────────────┬────────────────────┘
                        │ Algoritma untuk
                        │ optimasi sistem
                        ▼
    ┌─────────────────────────────────────────────┐
    │     🛡️ BOOK 2: KUALITAS PERANGKAT LUNAK     │
    │    (Proses, Standar & Jaminan Mutu)         │
    │      Prof. Dr. Ir. Untung Yuhana (ITS)      │
    │                                              │
    │  Menjamin kualitas sistem yang dibangun     │
    │  dengan algoritma AI dan infrastruktur      │
    │  internet offline                           │
    └────────────────────┬────────────────────────┘
                         │ Standar & proses
                         │ pengembangan
                         ▼
         ┌─────────────────────────────────────┐
         │     🌐 BOOK 3: INTERNET OFFLINE     │
         │   (Infrastruktur & Deployment)      │
         │         Onno W. Purbo               │
         │                                      │
         │  Deploy sistem ke daerah blank      │
         │  spot dengan server lokal, wireless,│
         │  dan konten e-learning              │
         └─────────────────────────────────────┘
```

**Paradigma:** _Algoritma (Book 1) → Proses Berkualitas (Book 2) → Deploy ke Lapangan (Book 3)_

---

## 📅 Rekomendasi Jadwal Belajar (12 Minggu)

### FASE 1: FONDASI (Minggu 1–4)

#### Minggu 1: Konsep Dasar & Pendahuluan

**Book 2 — BAB 1: Pendahuluan (Kualitas Perangkat Lunak)**

- **Topik Utama:** Definisi PL, Kode Etik, Kesalahan PL, Definisi Kualitas, Penjaminan Mutu, Biaya Kualitas, Kultur Kualitas, 5 Dimensi Proyek PL
- **Konsep Kunci:**
  - _Software Quality Assurance (SQA)_ vs _Quality Control (QC)_
  - _Cost of Quality:_ Prevention, Appraisal, Internal Failure, External Failure
  - _5 Dimensi Proyek:_ Ruang lingkup, waktu, biaya, kualitas, risiko
- **Latihan:** Identifikasi 3 kesalahan perangkat lunak yang pernah Anda temui dan klasifikasikan biaya yang ditimbulkannya.

**Book 1 — BAB 1: Kecerdasan Koloni Binatang**

- **Topik Utama:** Swarm Intelligence, Ide Awal, Kecerdasan Tiruan
- **Konsep Kunci:**
  - _Swarm Intelligence:_ Sistem decentral, self-organized, emergent behavior
  - _Stigmergy:_ Komunikasi tidak langsung melalui perubahan lingkungan
- **Latihan:** Amati semut atau lebah di alam. Catat pola perilaku koloni yang menunjukkan emergent intelligence.

**Book 3 — BAB 1: Pendahuluan**

- **Topik Utama:** E-learning, Filosofi Naif E-learning, Mindset Alternatif
- **Konsep Kunci:**
  - _Internet Offline:_ Akses digital tanpa koneksi internet real-time
  - _Paradigma:_ Content di server lokal, bukan cloud
- **Latihan:** List 5 kebutuhan e-learning di daerah tanpa internet.

---

#### Minggu 2: Model & Arsitektur

**Book 2 — BAB 3: Model Kualitas Rekayasa Perangkat Lunak**

- **Topik Utama:** Model McCall, Boehm, FURPS, Ghezzi, Dromey, SATC
- **Konsep Kunci:**
  - _McCall (1977):_ Product Operation, Product Revision, Product Transition
  - _Boehm (1978):_ As-is utility, Maintainability, Portability
  - _FURPS:_ Functionality, Usability, Reliability, Performance, Supportability
  - _Ghezzi (1991):_ Sintaks, Semantik, Pragmatik
  - _Dromey (1995):_ Product-based quality model
- **Tabel Perbandingan:**

| Model  | Tahun | Fokus Utama               | Kelebihan        | Kekurangan                  |
| ------ | ----- | ------------------------- | ---------------- | --------------------------- |
| McCall | 1977  | 3 perspektif kualitas     | Komprehensif     | Usang untuk modern SW       |
| Boehm  | 1978  | Utility + Maintainability | Praktis          | Terbatas scope              |
| FURPS  | 1987  | 5 kategori                | Mudah diingat    | Kurang detail               |
| Ghezzi | 1991  | Formal methods            | Rigorous         | Terlalu teoretis            |
| Dromey | 1995  | Product-based             | Measurable       | Kompleks implementasi       |
| SATC   | 1996  | NASA/mission-critical     | High reliability | Overkill untuk proyek kecil |

- **Latihan:** Pilih 1 model kualitas. Evaluasi aplikasi POS (dari PRD sebelumnya) menggunakan model tersebut.

**Book 1 — BAB 3: Neural Network (Bagian Dasar)**

- **Topik Utama:** Sejarah, Dasar-dasar, Struktur Jaringan Biologis, Arsitektur NN
- **Konsep Kunci:**
  - _Neuron Biologis:_ Dendrit, Soma, Akson, Sinapsis
  - _Neuron Tiruan:_ Input, Weight, Bias, Activation Function, Output
  - _Arsitektur:_ Single Layer, Multi-layer, Competitive
- **Latihan:** Implementasikan perceptron sederhana untuk operasi AND/OR logika.

**Book 3 — BAB 2 & 3: Overview & Desain Server**

- **Topik Utama:** Konsep Internet Offline, Desain Server, Perhitungan Beban
- **Konsep Kunci:**
  - _Server lokal:_ Self-contained, tidak bergantung cloud
  - _Perhitungan beban:_ CPU, RAM, storage, concurrent users
  - _Aplikasi server:_ Moodle, Apache, Kiwix, DNS
- **Latihan:** Hitung kebutuhan server untuk 100 siswa mengakses Moodle secara simultan.

---

#### Minggu 3: Logika & Pengukuran

**Book 1 — BAB 2: Fuzzy Logic**

- **Topik Utama:** Dasar-dasar Fuzzy, Himpunan Fuzzy, Fungsi Keanggotaan, Operator Fuzzy, Aplikasi (Anestesi, Vacuum Cleaner, Kamera, Minyak Isolasi)
- **Konsep Kunci:**
  - _Crisp Set vs Fuzzy Set:_ {0,1} vs [0,1]
  - _Membership Function:_ Triangular, Trapezoidal, Gaussian
  - _Fuzzyfikasi → Inferensi → Defuzzyfikasi_
  - _IF-THEN Rules:_ Basis pengetahuan fuzzy
- **Contoh Aplikasi:**
  - **Pengontrolan Anestesi:** Input (heart rate, blood pressure) → Output (drug dosage)
  - **Vacuum Cleaner:** Input (debris amount, floor type) → Output (suction power)
  - **Kamera:** Input (lighting, distance) → Output (aperture, shutter speed)
- **Latihan:** Buat sistem fuzzy sederhana untuk "kenyamanan ruangan" berdasarkan suhu dan kelembaban. Implementasi di MATLAB.

**Book 2 — BAB 8: Pengukuran Kualitas Perangkat Lunak**

- **Topik Utama:** Metode Pengukuran, CMMI, ISO 25023, Skala Kecil
- **Konsep Kunci:**
  - _Metric:_ Product metric, Process metric, Project metric
  - _ISO 25023:_ System/software quality measurement
  - _CMMI:_ Capability Maturity Model Integration (Level 1-5)
- **Latihan:** Definisikan 5 metric untuk mengukur kualitas sistem POS offline.

---

#### Minggu 4: Verifikasi & Validasi

**Book 2 — BAB 7: Verifikasi dan Validasi**

- **Topik Utama:** Manfaat & Biaya V&V, Teknik V&V, Traceability, Pengujian
- **Konsep Kunci:**
  - _Verifikasi:_ "Are we building the product right?"
  - _Validasi:_ "Are we building the right product?"
  - _Teknik:_ Review, Inspection, Walkthrough, Testing
  - _Traceability:_ Forward & backward tracing
- **Latihan:** Buat traceability matrix untuk fitur "Batching Tagihan WhatsApp" di sistem POS.

**Book 2 — BAB 5: Review dalam Pengembangan PL**

- **Topik Utama:** Jenis-jenis Review, Perbandingan, Studi Kasus
- **Konsep Kunci:**
  - _Code Review:_ Peer review, pair programming
  - _Design Review:_ Arsitektur, pattern
  - _Requirement Review:_ Completeness, consistency
- **Latihan:** Lakukan mock review untuk desain database sistem POS.

---

### FASE 2: ALGORITMA OPTIMASI (Minggu 5–8)

#### Minggu 5: Optimasi Berbasis Populasi — PSO & GA

**Book 1 — BAB 4: Particle Swarm Optimization (PSO)**

- **Topik Utama:** Dasar PSO, Aplikasi, Program MATLAB, Performansi
- **Konsep Kunci:**
  - _Particle:_ Posisi + Kecepatan + Fitness
  - _pbest:_ Personal best position
  - _gbest:_ Global best position
  - _Velocity Update:_ v = w·v + c1·r1·(pbest-x) + c2·r2·(gbest-x)
  - _Position Update:_ x = x + v
- **Aplikasi:** Optimasi fungsi matematis, economic load dispatch, training neural network
- **Latihan:** Implementasikan PSO untuk minimasi fungsi Rastrigin. Plot konvergensi.

**Book 1 — BAB 5: Genetic Algorithm (GA)**

- **Topik Utama:** Dasar GA, Skema Pengodean, Populasi Awal, Seleksi Alam, Aplikasi, MATLAB
- **Konsep Kunci:**
  - _Encoding:_ Binary, Real-valued, Permutation, Tree
  - _Seleksi:_ Roulette Wheel, Tournament, Rank
  - _Crossover:_ One-point, Two-point, Uniform, Arithmetic
  - _Mutation:_ Bit flip, Swap, Inversion, Gaussian
  - _Elitism:_ Mempertahankan individu terbaik
- **Aplikasi:** Optimasi kombinatorial, scheduling, feature selection
- **Latihan:** Gunakan GA untuk optimasi jadwal kelas (timetabling).

**Koneksi ke Book 2:** GA dan PSO bisa digunakan untuk _optimasi parameter_ dalam pengujian perangkat lunak (test case generation, test suite optimization).

---

#### Minggu 6: Swarm Intelligence — ACO & ABC

**Book 1 — BAB 8: Ant Colony Optimization (ACO)**

- **Topik Utama:** Dasar ACO, Sejarah, Sistem Semut Asli, Max-Min Ant System, Ant Colony System, Aplikasi, Program, Performansi
- **Konsep Kunci:**
  - _Pheromone:_ Jejak kimia yang ditinggalkan semut
  - _Pheromone Update:_ Evaporation + Deposit
  - _Transition Probability:_ P = [τ]^α · [η]^β / Σ
  - _MMAS:_ Batas min/max pada pheromone
  - _ACS:_ Local pheromone update + global update
- **Aplikasi:** Traveling Salesman Problem (TSP), routing, scheduling
- **Latihan:** Implementasikan ACO untuk TSP dengan 10 kota. Visualisasi pheromone trail.

**Book 1 — BAB 9: Artificial Bee Colony (ABC)**

- **Topik Utama:** Kecerdasan Berkelompok, Algoritme ABC, Aplikasi
- **Konsep Kunci:**
  - _Employed Bees:_ Mengeksploitasi sumber makanan
  - _Onlooker Bees:_ Memilih sumber berdasarkan probabilitas (waggle dance)
  - _Scout Bees:_ Eksplorasi sumber baru
  - _Limit:_ Batas iterasi tanpa improvement → scout
- **Aplikasi:** Numerical optimization, clustering, neural network training
- **Latihan:** Bandingkan performa ABC vs PSO untuk fungsi benchmark Sphere.

---

#### Minggu 7: Metaheuristik Bio-inspirasi — FA & BA

**Book 1 — BAB 6: Firefly Algorithm (FA)**

- **Topik Utama:** Dasar FA, Karakteristik Kunang-kunang, Intensitas Cahaya, Jarak & Pergerakan, Cara Kerja, Keefisienan, Optimasi Multimodal, Aplikasi (Economic Load Dispatch), Program MATLAB
- **Konsep Kunci:**
  - _Attractiveness:_ β = β₀ · e^(-γ·r²)
  - _Light Intensity:_ I = I₀ · e^(-γ·r²)
  - _Movement:_ xᵢ = xᵢ + β·(xⱼ-xᵢ) + α·(rand-0.5)
  - _Randomization:_ α mengontrol eksplorasi
- **Aplikasi:** Economic Load Dispatch, clustering, image processing
- **Latihan:** Terapkan FA untuk optimasi dispatch 3 generator thermal.

**Book 1 — BAB 7: Bat Algorithm (BA)**

- **Topik Utama:** Dasar BA, Kemampuan Ekolokasi, Variasi & Bat Algorithm, Aplikasi, MATLAB
- **Konsep Kunci:**
  - _Echolocation:_ Frekuensi, Loudness, Pulse Rate
  - _Frequency:_ f = f_min + (f_max - f_min)·β
  - _Velocity:_ vᵢ = vᵢ + (xᵢ - x_best)·f
  - _Position:_ xᵢ = xᵢ + vᵢ
  - _Loudness (A):_ Menurun saat mendekati prey
  - _Pulse Rate (r):_ Meningkat saat mendekati prey
- **Aplikasi:** Engineering optimization, classification, scheduling
- **Latihan:** Implementasikan BA untuk feature selection pada dataset Iris.

---

#### Minggu 8: Neural Network Lanjut & Performansi

**Book 1 — BAB 3 (Lanjutan): Neural Network**

- **Topik Utama:** Perceptron Tunggal, Perceptron Lapisan Jamak, Backpropagation, Struktur JST, Aplikasi (Sistem Pengamanan), Performansi
- **Konsep Kunci:**
  - _Perceptron:_ y = f(Σwᵢxᵢ + b), f = step/sign/sigmoid
  - _Multi-layer Perceptron (MLP):_ Input → Hidden → Output
  - _Backpropagation:_ Chain rule untuk update weight
    - δ_output = (t - y) · f'(net)
    - δ_hidden = Σ(δ_output · w) · f'(net)
    - Δw = η · δ · x
  - _Training Parameters:_ Learning rate, momentum, epoch, error threshold
- **Aplikasi:** Sistem pengamanan (face recognition, intrusion detection)
- **Latihan:** Bangun MLP dengan 1 hidden layer untuk klasifikasi MNIST. Hitung akurasi.

**Book 1 — BAB 3.14: Performansi**

- **Topik Utama:** Metrik performansi NN: Accuracy, Precision, Recall, F1-Score, MSE, RMSE, MAE, Confusion Matrix
- **Latihan:** Evaluasi model NN Anda menggunakan confusion matrix dan ROC curve.

---

### FASE 3: INFRASTRUKTUR & DEPLOYMENT (Minggu 9–11)

#### Minggu 9: Server & Jaringan

**Book 3 — BAB 3 & 4: Desain Server & Jaringan Akses**

- **Topik Utama:** Perhitungan Beban Server, Site Survey, Link Budget, Interferensi, Topologi Wireless
- **Konsep Kunci:**
  - _Link Budget:_ TX Power + Antenna Gain - Path Loss - Margin > RX Sensitivity
  - _Path Loss:_ FSPL = 32.45 + 20log(d) + 20log(f)
  - _Fresnel Zone:_ Area bebas hambatan untuk sinyal
  - _Topologi:_ P2P, P2MP, Mesh
  - _Channel Planning:_ Non-overlapping channels (1, 6, 11 untuk 2.4GHz)
- **Latihan:** Hitung link budget untuk jarak 5km dengan frekuensi 5.8GHz. Antena 24dBi, TX power 20dBm.

**Book 3 — BAB 5 & 6: Instalasi Server**

- **Topik Utama:** SSH, DHCP, Samba, Apache, Moodle, Kiwix, BIND, Raspberry Pi
- **Konsep Kunci:**
  - _LAMP Stack:_ Linux, Apache, MariaDB, PHP
  - _Moodle:_ LMS open-source untuk e-learning
  - _Kiwix:_ Wikipedia offline reader
  - _BIND:_ DNS server lokal
  - _MoodleBox:_ Raspberry Pi + Moodle pre-configured
- **Praktik:** Setup virtual machine dengan Ubuntu Server. Instal Apache + MariaDB + PHP. Test akses lokal.

---

#### Minggu 10: Konten & Akses

**Book 3 — BAB 8: Konten E-learning**

- **Topik Utama:** Restore Course, Perpustakaan Digital, Mirror Web, Wikipedia Offline, Strategi Konten, Ujian/Evaluasi
- **Konsep Kunci:**
  - _Content Strategy:_ Kurasi vs Agregasi
  - _Bank Soal:_ Format GIFT, XML, Aiken
  - _Evaluasi:_ Quiz, Assignment, Forum, SCORM
- **Latihan:** Buat 1 course sederhana di Moodle dengan 3 quiz dan 1 assignment.

**Book 3 — BAB 9: Konfigurasi Jaringan Akses**

- **Topik Utama:** Mikrotik, Linksys WRT610N, Ubiquiti NanoStation, Wajanbolic
- **Konsep Kunci:**
  - _Mikrotik:_ RouterOS, Winbox, konfigurasi hotspot
  - _Ubiquiti:_ AirOS, station/AP mode, alignment tool
  - _Wajanbolic:_ Antena parabola DIY untuk client
- **Praktik:** Konfigurasi Mikrotik sebagai hotspot gateway. Set bandwidth limit per user.

---

#### Minggu 11: Studi Kasus & Manajemen

**Book 3 — BAB 10: Studi Kasus**

- **Topik Utama:** Jasinga, Manado-Ternate-Talaud, Banten-Lampung, Garut (Fiber), Tangsel, Opencourse ITS
- **Pelajaran:**
  - _Jasinga:_ Wireless jarak jauh dengan repeater
  - _Manado-Ternate:_ Multi-hop link antar pulau
  - _Garut:_ Fiber optic di daerah rural
  - _Tangsel:_ E-learning tanpa kuota
- **Latihan:** Desain topologi jaringan untuk desa Anda dengan 3 titik akses.

**Book 3 — BAB 11 & 12: Listrik & Bisnis Proses**

- **Topik Utama:** UPS, PLTS, Inverter, Konverter, Biaya, Bisnis Proses
- **Konsep Kunci:**
  - _PLTS:_ Panel surya → Charge Controller → Battery → Inverter → Load
  - _Sizing:_ Watt peak, Ah battery, inverter capacity
  - _Bisnis Proses:_ Pelayanan masyarakat, siswa, guru, admin
- **Latihan:** Hitung kebutuhan PLTS untuk server + 20 client (total 500W, 8 jam/hari).

**Book 2 — BAB 9: Manajemen Risiko Proyek**

- **Topik Utama:** Proses Risiko, Tantangan, Standar, Pertimbangan Praktis, Penerapan
- **Konsep Kunci:**
  - _Risk Identification:_ Brainstorming, checklist, assumption analysis
  - _Risk Analysis:_ Probability × Impact = Risk Exposure
  - _Risk Response:_ Avoid, Transfer, Mitigate, Accept
- **Latihan:** Identifikasi 5 risiko untuk proyek Internet Offline dan buat risk register.

---

### FASE 4: INTEGRASI & BENCHMARKING (Minggu 12)

#### Minggu 12: Benchmarking & SQAP

**Book 3 — BAB 13: Benchmarking**

- **Topik Utama:** Paket/Second, Bandwidth, mysqlslap, Unixbench, Apache Bench, Siege, dbench, Konsumsi Raspberry Pi
- **Konsep Kunci:**
  - _Throughput:_ Paket/second, requests/second
  - _Stress Test:_ Siege, Apache Bench (ab)
  - _Database Load:_ mysqlslap
  - _System:_ Unixbench (CPU, memory, disk)
- **Praktik:** Benchmark server Moodle Anda dengan ab -n 1000 -c 100. Catat hasil.

**Book 2 — BAB 10 & 11: SQAP & Studi Kasus**

- **Topik Utama:** Perencanaan SQAP, Eksekusi, Studi Kasus
- **Konsep Kunci:**
  - _SQAP (IEEE 730):_ Purpose, reference, management, documentation, standards, review, testing, problem reporting
  - _Audit:_ Proses verifikasi kepatuhan terhadap SQAP
- **Latihan:** Buat SQAP sederhana untuk proyek "Sistem POS Offline" (dari PRD sebelumnya).

**Book 2 — BAB 6: Audit Perangkat Lunak**

- **Topik Utama:** Jenis Audit, Standar, Proses, CMMI, Skala Kecil
- **Konsep Kunci:**
  - _Process Audit:_ Apakah proses diikuti?
  - _Product Audit:_ Apakah produk sesuai spesifikasi?
  - _CMMI Level:_ Initial, Managed, Defined, Quantitatively Managed, Optimizing
- **Latihan:** Lakukan self-audit untuk sistem POS menggunakan checklist CMMI Level 2.

---

## 🔗 Koneksi Antar Buku (Cross-Reference)

### Koneksi 1: AI untuk Optimasi Sistem Offline

- **Book 1 (PSO/GA/ACO)** → **Book 3 (Jaringan Wireless)**
  - Gunakan PSO untuk optimasi penempatan access point (coverage maximization)
  - Gunakan GA untuk optimasi channel assignment (interference minimization)
  - Gunakan ACO untuk routing optimal dalam mesh network

### Koneksi 2: Kualitas untuk AI Systems

- **Book 2 (V&V)** → **Book 1 (Neural Network)**
  - Verifikasi: Apakah NN di-training dengan data yang benar?
  - Validasi: Apakah output NN sesuai ekspektasi domain?
  - Testing: Black-box testing untuk NN (robustness, adversarial)

### Koneksi 3: SQAP untuk Internet Offline

- **Book 2 (SQAP)** → **Book 3 (Server Offline)**
  - SQAP untuk Moodle deployment: backup plan, recovery, security audit
  - Quality metrics untuk konten e-learning: completeness, accuracy, accessibility

### Koneksi 4: Fuzzy Logic untuk Quality Assessment

- **Book 1 (Fuzzy)** → **Book 2 (Pengukuran Kualitas)**
  - Fuzzy untuk penilaian kualitas perangkat lunak yang bersifat subjektif
  - Fuzzy membership untuk metric seperti "usability" atau "maintainability"

---

## 📝 Daftar Praktik & Proyek Hands-On

| #   | Proyek                                                                  | Buku   | Tingkat  | Waktu  |
| --- | ----------------------------------------------------------------------- | ------ | -------- | ------ |
| 1   | Implementasi Perceptron AND/OR                                          | Book 1 | Pemula   | 2 jam  |
| 2   | Sistem Fuzzy "Kenyamanan Ruangan"                                       | Book 1 | Pemula   | 4 jam  |
| 3   | PSO untuk Minimasi Fungsi                                               | Book 1 | Menengah | 3 jam  |
| 4   | GA untuk Timetabling                                                    | Book 1 | Menengah | 4 jam  |
| 5   | ACO untuk TSP 10 Kota                                                   | Book 1 | Menengah | 3 jam  |
| 6   | MLP untuk MNIST                                                         | Book 1 | Lanjut   | 6 jam  |
| 7   | Evaluasi Model Kualitas McCall                                          | Book 2 | Pemula   | 2 jam  |
| 8   | Traceability Matrix POS                                                 | Book 2 | Menengah | 3 jam  |
| 9   | Risk Register Proyek                                                    | Book 2 | Menengah | 2 jam  |
| 10  | SQAP untuk POS Offline                                                  | Book 2 | Lanjut   | 4 jam  |
| 11  | Setup VM LAMP Stack                                                     | Book 3 | Pemula   | 3 jam  |
| 12  | Link Budget 5km                                                         | Book 3 | Menengah | 2 jam  |
| 13  | Moodle Course + Quiz                                                    | Book 3 | Menengah | 4 jam  |
| 14  | Konfigurasi Mikrotik Hotspot                                            | Book 3 | Menengah | 3 jam  |
| 15  | Sizing PLTS untuk Server                                                | Book 3 | Lanjut   | 2 jam  |
| 16  | Benchmark dengan ab & mysqlslap                                         | Book 3 | Lanjut   | 3 jam  |
| 17  | **CAPSTONE:** Deploy POS Offline dengan AI-powered inventory prediction | All    | Expert   | 20 jam |

---

## 🧠 Capstone Project: "Sistem POS Offline Cerdas"

Integrasikan ketiga buku dalam 1 proyek:

### Arsitektur:

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT (Kasir/Admin)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   UI/UX     │  │  Print Nota │  │  Laporan Keuangan  │  │
│  │ (Kustom     │  │  (Thermal)  │  │  (PDF/Excel)        │  │
│  │  Warna)     │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              OFFLINE-FIRST (IndexedDB)                 ││
│  │         ┌─────────────────────────────┐                ││
│  │         │   NN untuk Prediksi Stok    │  ← Book 1    ││
│  │         │   (TensorFlow.js / Brain.js)│                ││
│  │         └─────────────────────────────┘                ││
│  └─────────────────────────────────────────────────────────┘│
└──────────────────────────┬──────────────────────────────────┘
                           │ Sync (saat online)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  SERVER LOKAL (Raspberry Pi)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Apache    │  │   MariaDB   │  │      Moodle         │  │
│  │   (Web)     │  │  (Database) │  │   (E-learning)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Kiwix     │  │   BIND DNS  │  │   Samba File Share  │  │
│  │ (Wikipedia) │  │  (Lokal)    │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                           ▲                                  │
│              ┌────────────┴────────────┐                    │
│              │   Mikrotik / Ubiquiti    │  ← Book 3        │
│              │   (Access Point/Hotspot)   │                    │
│              └────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
                           ▲
              ┌────────────┴────────────┐
              │      PLTS + Battery      │  ← Book 3
              │    (Solar Power System)   │
              └────────────────────────────┘
```

### Quality Assurance (Book 2):

- SQAP untuk deployment
- CMMI Level 2 compliance
- Risk management untuk power outage
- V&V untuk AI prediction accuracy

### AI Components (Book 1):

- **Neural Network:** Prediksi stok barang berdasarkan pola penjualan
- **Fuzzy Logic:** Penilaian kredit pelanggan (hutang)
- **PSO/GA:** Optimasi layout produk di gudang

---

## 📖 Glossary Konsep Kunci

### Dari Book 1 (AI):

| Istilah            | Definisi                                                                 |
| ------------------ | ------------------------------------------------------------------------ |
| Swarm Intelligence | Sistem decentral yang self-organized, terinspirasi perilaku koloni hewan |
| Fuzzy Logic        | Logika yang menangani ketidakpastian dengan derajat keanggotaan [0,1]    |
| Neural Network     | Model komputasi terinspirasi jaringan saraf biologis                     |
| Backpropagation    | Algoritma training NN menggunakan chain rule                             |
| PSO                | Optimasi berbasis perilaku kawanan burung                                |
| GA                 | Optimasi berbasis evolusi alam: seleksi, crossover, mutasi               |
| ACO                | Optimasi berbasis perilaku semut mencari jalur terpendek                 |
| ABC                | Optimasi berbasis perilaku koloni lebah                                  |
| FA                 | Optimasi berbasis perilaku kunang-kunang                                 |
| BA                 | Optimasi berbasis echolocation kelelawar                                 |

### Dari Book 2 (Kualitas PL):

| Istilah       | Definisi                                                                  |
| ------------- | ------------------------------------------------------------------------- |
| SQA           | Software Quality Assurance — aktivitas sistematis untuk menjamin kualitas |
| V&V           | Verification & Validation — verifikasi proses, validasi produk            |
| CMMI          | Capability Maturity Model Integration — model kematangan proses           |
| SQAP          | Software Quality Assurance Plan — dokumen perencanaan SQA                 |
| Traceability  | Kemampuan melacak requirement ke implementasi dan testing                 |
| Metric        | Pengukuran kuantitatif untuk proses, produk, atau proyek                  |
| Audit         | Pemeriksaan formal untuk verifikasi kepatuhan                             |
| Risk Exposure | Probability × Impact dari suatu risiko                                    |

### Dari Book 3 (Internet Offline):

| Istilah          | Definisi                                                       |
| ---------------- | -------------------------------------------------------------- |
| Internet Offline | Akses konten digital tanpa koneksi internet real-time          |
| Link Budget      | Perhitungan daya sinyal dari transmitter ke receiver           |
| Fresnel Zone     | Area elipsoidal yang harus bebas hambatan untuk sinyal optimal |
| Moodle           | Learning Management System open-source                         |
| Kiwix            | Aplikasi untuk membaca Wikipedia secara offline                |
| PLTS             | Pembangkit Listrik Tenaga Surya                                |
| MoodleBox        | Raspberry Pi pre-configured dengan Moodle                      |
| Wajanbolic       | Antena parabola DIY dari wajan untuk client wireless           |

---

## ✅ Checklist Belajar

### Book 1 — Artificial Intelligence

- [ ] Memahami konsep Swarm Intelligence dan stigmergy
- [ ] Mampu membuat himpunan fuzzy dan fungsi keanggotaan
- [ ] Mampu membuat fuzzy inference system sederhana
- [ ] Memahami arsitektur perceptron dan multi-layer neural network
- [ ] Mampu menghitung backpropagation manual untuk 1 iterasi
- [ ] Memahami konsep pbest, gbest, velocity update pada PSO
- [ ] Mampu menjelaskan seleksi, crossover, mutasi pada GA
- [ ] Memahami pheromone update dan transition probability pada ACO
- [ ] Memahami peran employed, onlooker, dan scout bees pada ABC
- [ ] Mampu menjelaskan attractiveness dan intensitas cahaya pada FA
- [ ] Memahami echolocation, loudness, dan pulse rate pada BA
- [ ] Mampu implementasi minimal 3 algoritma di MATLAB/Python

### Book 2 — Kualitas Perangkat Lunak

- [ ] Mampu menjelaskan perbedaan SQA, QC, dan Testing
- [ ] Memahami 6 model kualitas dan mampu membandingkannya
- [ ] Mampu membuat Software Quality Plan
- [ ] Memahami dan mampu melakukan code review
- [ ] Mampu membuat traceability matrix
- [ ] Memahami teknik V&V: review, inspection, walkthrough, testing
- [ ] Mampu mendefinisikan metric untuk proyek PL
- [ ] Memahami proses manajemen risiko dan mampu membuat risk register
- [ ] Mampu membuat SQAP lengkap
- [ ] Memahami CMMI level 1-5 dan mampu assess proyek

### Book 3 — Internet Offline

- [ ] Memahami konsep dan filosofi internet offline
- [ ] Mampu menghitung kebutuhan server (CPU, RAM, storage)
- [ ] Mampu menghitung link budget untuk wireless link
- [ ] Mampu instalasi LAMP stack (Linux, Apache, MariaDB, PHP)
- [ ] Mampu setup Moodle dan membuat course
- [ ] Mampu setup Kiwix untuk Wikipedia offline
- [ ] Mampu konfigurasi Mikrotik sebagai hotspot gateway
- [ ] Mampu setup Raspberry Pi sebagai server (MoodleBox)
- [ ] Mampu merancang topologi jaringan untuk desa
- [ ] Mampu menghitung sizing PLTS untuk server
- [ ] Mampu melakukan benchmark dengan ab, mysqlslap, Unixbench
- [ ] Mampu membuat konten e-learning dan bank soal

---

_Dokumen ini disusun berdasarkan Daftar Isi dari ketiga buku yang difoto. Silakan dipelajari secara sistematis dan praktik langsung untuk pemahaman maksimal._
