---
title: 'Bloom Taxonomy — Deep Dive: Kognitif, Knowledge Dimension, Revised Taxonomy,
  Aplikasi Pembelajaran & AI Alignment'
tags:
  - fundamentals
  - education
  - cognitive-science
  - learning
  - library
  - pedagogy
created: '2026-07-21'
updated: '2026-07-21'
status: pending
cssclasses:
  - wide-table
aliases:
  - Bloom's Taxonomy
  - Taksonomi Bloom
  - Cognitive Domain
  - Revised Bloom Taxonomy
  - Anderson Krathwohl
  - Higher Order Thinking
  - HOTS
---

# 🎯 Bloom Taxonomy — Deep Dive: Kognitif, Knowledge Dimension, Revised Taxonomy, Aplikasi Pembelajaran & AI Alignment

> Panduan komprehensif Taksonomi Bloom — kerangka hierarkis klasifikasi tujuan pembelajaran yang menjadi standar de facto di dunia pendidikan dan pelatihan sejak 1956. Mencakup original taxonomy (Bloom, 1956) vs revised taxonomy (Anderson & Krathwohl, 2001), pergeseran dari kata benda ke kata kerja, Knowledge Dimension (Factual, Conceptual, Procedural, Metacognitive), level demi level dari Remember sampai Create, aplikasi praktis untuk instruksional design, soal assessment, dan — yang paling relevan dengan era sekarang — **alignment dengan AI, computational thinking, dan cognitive architecture**. Catatan ini adalah jembatan antara pendidikan formal dengan pemahaman kognitif yang dipakai di engineering dan security.

> [!info] Posisi di Vault
> Catatan ini beririsan langsung dengan [[15-types-of-thinking]] (arsitektur kognitif dan metakognisi), [[computer-science-foundations]] (fondasi CS yang harus dikuasai di setiap level taksonomi), [[curriculum-mapping]] (pemetaan kurikulum — Bloom adalah kerangka utamanya), [[ai-evaluation-framework]] (evaluasi kemampuan AI pakai taksonomi), [[cognitive-architecture-engineering]] (rekayasa arsitektur kognitif), dan [[research-methodology]] (level sintesis/evaluasi dalam riset). Juga jadi prasyarat konseptual untuk [[formal-verification-deepdive]] (verifikasi formal == level evaluasi tertinggi) dan [[architectural-flaw-detection]] (deteksi cacat butuh analisis + evaluasi).

---

## Daftar Isi

- [[#Foundation — Apa Itu Taksonomi Bloom?]]
- [[#Original Taxonomy (1956) — 6 Tingkat Kognitif]]
- [[#Revised Taxonomy (Anderson & Krathwohl, 2001)]]
- [[#The Knowledge Dimension]]
- [[#Level Demi Level — Deep Dive]]
- [[#Aplikasi Praktis: Instructional Design & Assessment]]
- [[#Bloom's Taxonomy di Era AI & Computational Thinking]]
- [[#Kritik & Keterbatasan]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation — Apa Itu Taksonomi Bloom?

### Definisi

Taksonomi Bloom adalah kerangka hierarkis yang mengklasifikasikan **tujuan pembelajaran** berdasarkan tingkat kompleksitas kognitif. Dikembangkan oleh **Benjamin Bloom** bersama sekelompok psikolog pendidikan (Max Englehart, Edward Furst, Walter Hill, David Krathwohl) pada 1956, kerangka ini awalnya diterbitkan sebagai *"Taxonomy of Educational Objectives: The Classification of Educational Goals. Handbook I: Cognitive Domain"*.

Tujuan awal Bloom bukan sekadar bikin label — tapi:

1. **Standarisasi komunikasi** antar pendidik tentang tujuan pembelajaran
2. **Mendorong higher-order thinking** — kritik terhadap pendidikan yang terlalu fokus pada hafalan
3. **Alat evaluasi** untuk mengukur apakah siswa benar-benar mencapai level kognitif yang ditargetkan

### Mengapa Hierarkis?

```
              ╱ ╲
             ╱   ╲
            ╱     ╲
           ╱  #6   ╲     CREATE      ← Higher Order
          ╱         ╲                  Thinking Skills
         ╱  ═══════  ╲                 (HOTS)
        ╱     #5      ╲   EVALUATE
       ╱  ═══════════  ╲
      ╱       #4        ╲  ANALYZE
     ╱═══════════════════╲
    ╱         #3          ╲  APPLY
   ╱═══════════════════════╲
  ╱           #2            ╲ UNDERSTAND
 ╱═══════════════════════════╲
╱             #1              ╲ REMEMBER   ← Lower Order Thinking Skills (LOTS)
```

Prinsip hierarkisnya: **setiap level mencakup kemampuan level di bawahnya**. Tidak bisa Evaluate tanpa bisa Analyze, tidak bisa Create tanpa bisa Evaluate. Ini yang membedakan Bloom dari taksonomi lain yang cuma daftar kategori datar.

### Domain — Bukan Cuma Kognitif

Bloom membagi tujuan pendidikan jadi 3 domain:

| Domain | Nama Lengkap | Fokus | Nota Terkait di Vault |
|--------|-------------|-------|-----------------------|
| 🧠 **Cognitive** | Cognitive Domain | Pengetahuan & pemikiran intelektual | Dokumen ini |
| ❤️ **Affective** | Affective Domain | Sikap, emosi, nilai, apresiasi | [[ai-governance-ethics]] — tertaut ke etika |
| ✋ **Psychomotor** | Psychomotor Domain | Keterampilan fisik, manipulasi alat | [[technician-toolkit-standard]] — skill hands-on |

Dokumen ini fokus ke **Cognitive Domain** karena paling relevan dengan vault, tapi koneksi ke domain lain dicatat di bagian koneksi.

---

## Original Taxonomy (1956) — 6 Tingkat Kognitif

Taksonomi asli Bloom menggunakan **kata benda (nouns)** untuk label tingkatan, disusun dari konkret ke abstrak:

| Level | Nama Asli | Arti | Contoh Aktivitas |
|-------|-----------|------|------------------|
| 1️⃣ | **Knowledge** | Mengingat fakta, terminologi, prosedur dasar | Mendefinisikan, menyebutkan, mengidentifikasi |
| 2️⃣ | **Comprehension** | Memahami makna, menerjemahkan, menginterpretasi | Menjelaskan, meringkas, memparafrase |
| 3️⃣ | **Application** | Menerapkan abstraksi ke situasi konkret | Menggunakan rumus, menjalankan prosedur |
| 4️⃣ | **Analysis** | Memecah informasi jadi komponen, melihat hubungan | Membandingkan, mengkontraskan, mengkategorisasi |
| 5️⃣ | **Synthesis** | Menggabungkan elemen jadi struktur baru | Merancang, mengonstruksi, mengembangkan |
| 6️⃣ | **Evaluation** | Membuat penilaian berdasarkan kriteria | Menilai, mengkritik, memjustifikasi |

**Masalah original taxonomy:**
- **Knowledge** terlalu sempit — seolah-olah pengetahuan cuma hafalan
- **Synthesis < Evaluation** — secara hierarki, tapi banyak psikolog kognitif berargumen *creating* (synthesis) lebih kompleks dari *evaluating*
- Susah dibedakan antara **Comprehension** dan **Knowledge** — garisnya tipis

---

## Revised Taxonomy (Anderson & Krathwohl, 2001)

### Siapa yang Merevisi?

**Lorin Anderson** (mantan mahasiswa Bloom) dan **David Krathwohl** (salah satu anggota tim original Bloom, 2001) menerbitkan *"A Taxonomy for Learning, Teaching, and Assessing: A Revision of Bloom's Taxonomy of Educational Objectives"*. Revisi ini bukan sekadar ganti label — tapi perubahan **struktural fundamental**.

### Perubahan Utama

| Aspek | Original (1956) | Revised (2001) |
|-------|-----------------|----------------|
| **Terminologi** | Kata benda (*Nouns*) | Kata kerja (*Verbs*) — lebih action-oriented |
| **Nama Level** | Knowledge → Evaluation | **Remember → Create** |
| **Hierarki** | Knowledge → Evaluation (synthesis < evaluation) | Remember → Create (**create di puncak**) |
| **Dimensi** | Satu dimensi (kognitif) | **Dua dimensi** (kognitif + pengetahuan) |
| **Knowledge** | Level terendah | Dimensi terpisah: **Knowledge Dimension** |
| **Synthesis → Create** | Synthesis (level 5) | **Create** (level 6) — lebih luas dari synthesis |

### Revised Taxonomy — 6 Tingkat Kognitif (Kata Kerja)

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│    6. 🛠️  CREATE    — Memproduksi, Merencanakan         │
│                Memproduksi, Generate                    │
│                                                         │
│    5. 📊 EVALUATE   — Memeriksa, Mengkritik             │
│                Check, Critique                          │
│                                                         │
│    4. 🔬 ANALYZE   — Membedakan, Mengorganisasi         │
│               Differentiate, Organize, Attribute        │
│                                                         │
│    3. 🎯 APPLY     — Mengeksekusi, Mengimplementasi     │
│               Execute, Implement                        │
│                                                         │
│    2. 📖 UNDERSTAND — Menginterpretasi, Mencontohkan    │
│               Interpret, Exemplify, Classify, Summarize │
│                                                         │
│    1. 📝 REMEMBER   — Mengenali, Mengingat Kembali      │
│               Recognize, Recall                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Perbandingan Kata Kerja per Level

| Level | Original (Noun) | Revised (Verb) | Definisi Baru |
|-------|----------------|----------------|---------------|
| 1 | Knowledge | **Remember** | Mengambil pengetahuan dari long-term memory |
| 2 | Comprehension | **Understand** | Mengkonstruksi makna dari pesan instruksional |
| 3 | Application | **Apply** | Menggunakan prosedur dalam situasi tertentu |
| 4 | Analysis | **Analyze** | Memecah materi jadi bagian dan menentukan hubungan |
| 5 | Synthesis | **Evaluate** | Membuat judgment berdasarkan kriteria & standar |
| 6 | Evaluation | **Create** | Menyatukan elemen jadi struktur/fungsi baru yang koheren |

> 🔑 **Takeaway utama:** Pergeseran dari *Knowledge → Remember* dan *Synthesis → Create* mengubah cara kita melihat pendidikan — dari **storage informasi** (apa yang lo tahu) ke **proses kognitif** (apa yang lo bisa lakukan dengan informasi itu).

---

## The Knowledge Dimension

Inilah inovasi terbesar Revised Taxonomy: **dimensi kedua** yang independen dari proses kognitif. Sekarang setiap tujuan pembelajaran bisa dipetakan dalam **matriks 2D**: *Apa jenis pengetahuannya?* × *Proses kognitif apa?*

### Empat Tipe Pengetahuan

```
                        ┌─────────────────────────────────┐
                        │     KNOWLEDGE DIMENSION         │
                        ├─────────────────────────────────┤
     CONCRETE ──────────┤ A. FACTUAL KNOWLEDGE            │◀─ Lebih konkret
                        │    (Fakta dasar, terminologi)   │
                        ├─────────────────────────────────┤
                        │ B. CONCEPTUAL KNOWLEDGE         │
                        │    (Teori, model, klasifikasi)  │
                        ├─────────────────────────────────┤
                        │ C. PROCEDURAL KNOWLEDGE         │
                        │    (Prosedur, algoritma, metode)│
                        ├─────────────────────────────────┤
     ABSTRACT ──────────┤ D. METACOGNITIVE KNOWLEDGE      │◀─ Lebih abstrak
                        │    (Kesadaran & pengetahuan     │
                        │     tentang kognisi sendiri)    │
                        └─────────────────────────────────┘
```

| Tipe | Definisi | Contoh | Relevansi Vault |
|------|----------|--------|-----------------|
| **A. Factual** | Elemen dasar yang harus diketahui siswa untuk mengenal suatu disiplin | Terminologi jaringan: TCP, UDP, IP, port; rumus matematika | [[http-protocol-deepdive]] (terminologi HTTP), [[math-and-algorithms]] |
| **B. Conceptual** | Hubungan antar elemen dasar dalam struktur yang lebih besar yang memungkinkan fungsinya | Model OSI layer, TCP/IP model, konsep client-server | [[networking-fundamentals-tcpip-bgp]], [[purple-team-osi-killchain]] |
| **C. Procedural** | Cara melakukan sesuatu, metode inquiry, kriteria penggunaan skill/algoritma/teknik | Cara capture packet di tcpdump, format YARA rule, prosedur incident response | [[incident-response-framework]], [[endpoint-detection-playbook]] |
| **D. Metacognitive** | Pengetahuan tentang kognisi secara umum dan kesadaran akan kognisi diri sendiri | Strategi membaca packet capture secara efisien, kapan harus static analysis vs dynamic analysis | [[15-types-of-thinking]], [[deep-work-and-so-good-newport]] |

### Matriks Taksonomi 2D

Tujuan pembelajaran sekarang bisa dipetakan dalam tabel 24 sel (4 knowledge × 6 cognitive process):

```
                   │ REMEMBER │ UNDERSTAND │ APPLY │ ANALYZE │ EVALUATE │ CREATE
───────────────────┼──────────┼────────────┼───────┼─────────┼──────────┼────────
 FACTUAL           │  ●       │            │       │         │          │
───────────────────┼──────────┼────────────┼───────┼─────────┼──────────┼────────
 CONCEPTUAL        │          │  ●         │       │  ●      │          │
───────────────────┼──────────┼────────────┼───────┼─────────┼──────────┼────────
 PROCEDURAL        │          │            │  ●    │         │  ●       │
───────────────────┼──────────┼────────────┼───────┼─────────┼──────────┼────────
 METACOGNITIVE     │          │            │       │         │          │  ●
───────────────────┼──────────┼────────────┼───────┼─────────┼──────────┼────────
```

**Contoh matriks untuk mata kuliah Cybersecurity:**

| Tujuan Pembelajaran | Knowledge | Cognitive | Sel (K×C) |
|--------------------|-----------|-----------|-----------|
| Menyebutkan 5 jenis serangan web | Factual | Remember | A1 |
| Menjelaskan cara kerja SQL injection | Conceptual | Understand | B2 |
| Menjalankan sqlmap untuk testing parameter | Procedural | Apply | C3 |
| Membedakan reflected vs stored XSS dari log | Conceptual | Analyze | B4 |
| Menilai efektivitas WAF rule berdasarkan false positive rate | Conceptual | Evaluate | B5 |
| Merancang detection playbook untuk serangan baru | Procedural | Create | C6 |

> 💡 **Kenapa matriks ini penting?** Karena tujuan pembelajaran yang bagus harus mencantumkan **kedua dimensi**. "Siswa mampu mengevaluasi efektivitas WAF rule" — itu Process: Evaluate, Knowledge: Conceptual. Tanpa matriks, pendidik sering cuma nyebut level kognitif doang tanpa mikir jenis pengetahuannya — jadinya ambigu.

---

## Level Demi Level — Deep Dive

### Level 1: REMEMBER — Mengingat Kembali

**Definisi Revised:** Mengambil pengetahuan relevan dari **long-term memory**.

Ini adalah fondasi. Tanpa Remember, level lain tidak bisa berdiri. Tapi Revised Taxonomy menekankan bahwa Remember **bukanlah tujuan akhir** — ini alat untuk mencapai level yang lebih tinggi.

**Kategori Verbs:**
- **Recognize** (mengenali): Mengidentifikasi informasi yang sesuai dengan konteks — biasanya soal pilihan ganda, matching
- **Recall** (mengingat kembali): Menarik informasi dari memori tanpa stimulus — soal esai, fill-in-the-blank

**Kata Kerja:** *Recognize, Recall, Identify, List, Name, State, Define, Describe (fakta), Retrieve, Match, Reproduce*

**Knowledge Dimension yang Umum:** Factual (paling sering), Conceptual (teori dasar)

**Contoh di Berbagai Disiplin:**

| Bidang | Remember — Contoh Soal |
|--------|----------------------|
| Networking | "Sebutkan 7 layer OSI model dari bawah ke atas" |
| Security | "Apa kepanjangan dari XSS?" |
| Programming | "Sebutkan 3 tipe data primitif di Rust" |
| Matematika | "Apa rumus luas lingkaran?" |

**Pitfall:** Banyak pendidikan berhenti di sini. Siswa bisa hafal OSI layer tapi gak bisa jelasin bedanya layer 2 vs layer 3 dalam konteks real.

**Koneksi Vault:** Praktik hafalan di picoCTF ([[picoctf-section-1-onboarding]]) — hafal command dasar Linux, CyberChef recipes, format flag.

---

### Level 2: UNDERSTAND — Memahami

**Definisi Revised:** Mengkonstruksi makna dari pesan instruksional (lisan, tulisan, grafis).

Ini adalah **lompatan kualitatif** pertama — dari *tahu* ke *paham*. Siswa tidak cuma bisa mengulang, tapi bisa menjelaskan dengan kata-kata sendiri, memberi contoh, atau meringkas.

**Kategori Verbs:**
- **Interpret** — mengubah dari satu bentuk representasi ke bentuk lain (angka → grafik, teks → diagram)
- **Exemplify** — memberi contoh spesifik dari konsep umum
- **Classify** — menentukan sesuatu masuk kategori mana
- **Summarize** — meringkas inti (abstraksi)
- **Infer** — menarik kesimpulan logis dari informasi
- **Compare** — mendeteksi persamaan dan perbedaan
- **Explain** — membangun model sebab-akibat

**Kata Kerja:** *Explain, Summarize, Interpret, Paraphrase, Classify, Compare, Contrast, Describe (konsep), Infer, Translate, Convert, Defend, Distinguish*

**Contoh:**

| Bidang | Understand — Contoh Soal |
|--------|------------------------|
| Networking | "Jelaskan perbedaan OSI model dengan TCP/IP model" |
| Security | "Mengapa SQL injection bisa terjadi? Jelaskan mekanismenya" |
| Programming | "Interpretasikan output kode Rust berikut..." |
| Forensik | "Bandingkan metode file carving dengan filesystem parsing" |

**Computational Thinking Link:**
- **Pattern Recognition** → kemampuan mengklasifikasi dan menggeneralisasi
- **Abstraction** → meringkas informasi esensial

**Cara Mengukur:**
- Minta siswa menjelaskan konsep ke orang awam (Feynman Technique)
- Ubah representasi: dari teks ke mind map, dari tabel ke narasi
- Beri kasus baru dan minta mereka kaitkan dengan konsep yang sudah dipelajari

**Koneksi Vault:** [[15-types-of-thinking]] — terutama tipe *Abstract Thinking* dan *Concrete Thinking* dalam memahami konsep.

---

### Level 3: APPLY — Menerapkan

**Definisi Revised:** Menjalankan atau menggunakan prosedur dalam situasi tertentu.

Ini adalah level **eksekusi**. Di dunia engineering, ini adalah level minimum yang diperlukan untuk kontribusi produktif.

**Dua Sub-kategori:**
- **Execute** — menerapkan prosedur ke **tugas familiar** (siswa tahu persis prosedur apa yang harus dipakai)
- **Implement** — menerapkan prosedur ke **tugas unfamiliar** (siswa harus memilih prosedur yang tepat dari beberapa opsi)

**Kata Kerja:** *Execute, Implement, Use, Apply, Demonstrate, Operate, Show, Solve, Calculate, Complete, Illustrate, Modify*

**Contoh:**

| Bidang | Apply — Contoh Soal |
|--------|-------------------|
| Networking | "Gunakan tcpdump untuk capture HTTP traffic ke server production" |
| Security | "Scan port host [VPS2_IP] dengan nmap" |
| Programming | "Buat fungsi Rust yang ngecek apakah string adalah palindrome" |
| Forensik | "Ekstrak file dari image forensik pake foremost" |

**Kompleksitas Apply meningkat ketika:**
1. Situasi tidak seratus persen cocok dengan prosedur yang diajarkan
2. Ada banyak prosedur yang bisa dipilih dan siswa harus memutuskan
3. Kondisi eksekusi tidak ideal (resource terbatas, error handling)

**Koneksi Vault:**
- [[picoctf-section-3-linux-web-basics]] — apply command line
- [[picoctf-section-4-python-automation]] — apply Python scripting
- [[cgnat-attribution-deepdive]] — apply tracing methodology
- [[postgresql-admin-backup]] — apply backup/restore commands
- [[podman-networking-ufw]] — apply firewall rules

---

### Level 4: ANALYZE — Menganalisis

**Definisi Revised:** Memecah materi menjadi bagian-bagian penyusun dan menentukan **bagaimana bagian-bagian itu berhubungan** satu sama lain dan dengan struktur keseluruhan.

Ini adalah **pintu gerbang Higher Order Thinking Skills (HOTS)**. Di sini siswa mulai berpikir seperti seorang engineer atau analyst — bukan cuma pengguna tool.

**Tiga Sub-kategori:**
- **Differentiate** — membedakan bagian relevan dari yang tidak relevan (discriminating)
- **Organize** — menentukan bagaimana elemen-elemen cocok dalam suatu struktur (structuring, integrating)
- **Attribute** — menentukan sudut pandang, bias, tujuan, atau nilai yang mendasari (deconstruction)

**Kata Kerja:** *Differentiate, Distinguish, Organize, Attribute, Deconstruct, Analyze, Compare (struktur), Contrast (struktur), Categorize, Examine, Question, Test, Detect, Discriminate, Select*

**Contoh:**

| Bidang | Analyze — Contoh Soal |
|--------|---------------------|
| Security | "Analisis log berikut: mana yang serangan dan mana yang false positive?" |
| Networking | "Dari PCAP ini, identifikasi fase TCP handshake, kapan SYN flood mulai?" |
| Malware | "Urai struktur PE file ini: mana section code, data, resources?" |
| Code | "Bandingkan dua implementasi sorting ini — mana yang lebih efisien? Kenapa?" |
| WAF | "Dari rule set Cloudflare, kelompokkan mana rule yang deteksi LFI, mana SQLi" |

**Analisis di Security Context:**

```python
# Contoh: Menganalisis HTTP log untuk membedakan serangan vs trafik normal
logs = [
    {"ip": "45.33.32.156", "path": "/api/login", "status": 200, "size": 1250},
    {"ip": "185.220.101.45", "path": "/api/login' OR '1'='1", "status": 403, "size": 50},
    {"ip": "185.220.101.45", "path": "/admin/../../etc/passwd", "status": 404, "size": 150},
]

# Analisis: bedakan pola normal vs anomali
# - IP 45.33.32.156 → request normal (path bersih, status 200)
# - IP 185.220.101.45 → SQLi attempt, path traversal attempt
# Attribution: IP ini mencoba multiple attack vectors secara sequential
```

**Cara Melatih:**
- Beri dataset mentah dan minta mereka kelompokkan, kategorisasi
- Case study: "Ini server production, log menunjukkan X. Apa yang terjadi?"
- Reverse engineering: bongkar binary, dokumen, protokol

**Koneksi Vault:** Ini adalah level operasional untuk sebagian besar catatan security:
- [[blueteam-detection-matrix]] — bedakan IOC dari noise
- [[waf-reverse-proxy-deepdive]] — analisis log WAF
- [[threat-hunting-methodology]] — analisis pola anomali
- [[malware-analysis-reverse-engineering-playbook]] — analisis malware
- [[siem-security-data-lake-architecture]] — analisis data lake

---

### Level 5: EVALUATE — Mengevaluasi

**Definisi Revised:** Membuat **judgment** berdasarkan kriteria dan standar.

Ini adalah level **keputusan**. Tidak cukup cuma analisis — siswa harus bisa menilai mana yang lebih baik, lebih efektif, lebih aman, dan **memberi alasan** berdasarkan kriteria eksplisit.

**Dua Sub-kategori:**
- **Check** — menguji konsistensi internal, mendeteksi kesalahan atau fallacy (coherence testing)
- **Critique** — menilai produk/proses berdasarkan kriteria eksternal, menemukan kekurangan dan kelebihan

**Kata Kerja:** *Check, Critique, Evaluate, Judge, Justify, Assess, Defend, Support, Appraise, Argue, Validate, Verify, Review, Recommend, Prioritize, Rank*

**Contoh:**

| Bidang | Evaluate — Contoh Soal |
|--------|----------------------|
| Security | "Evaluasi efektivitas WAF ini: berdasarkan log, berapa false positive rate? Apakah worth it?" |
| Architecture | "Bandingkan 3 arsitektur ini (monolith, microservices, serverless) untuk kasus IoT sensor data — mana yang paling sesuai? Justifikasi" |
| Tooling | "Apakah YARA rules yang ada cukup buat detect varian malware ini? Kalau tidak, apa yang kurang?" |
| Code Review | "Review PR ini — apakah perubahan di parser aman? Beri rekomendasi terima/tolak dengan alasan" |
| Forensik | "Apakah bukti digital ini cukup kuat untuk prosecution? Identifikasi gap-nya" |

**Kriteria yang Biasa Dipakai di Security:**

| Kriteria | Contoh Pertanyaan |
|----------|------------------|
| **Effectiveness** | Apakah WAF ini memblock 99% SQLi attempt? |
| **Efficiency** | Apakah detection rule ini punya false positive rate di bawah 1%? |
| **Coverage** | Apakah playbook ini mencakup semua fase incident response? |
| **Scalability** | Apakah arsitektur ini bisa handle 10x traffic? |
| **Security** | Apakah solusi ini introduce vulnerability baru? |
| **Cost** | Apakah benefit keamanan sebanding dengan cost operasional? |
| **Usability** | Apakah tool ini bisa dipake tim non-security? |

**Pitfall Umum:** Siswa sering *evaluate* tanpa kriteria jelas — "Saya rasa lebih baik pakai X" tanpa justifikasi. Evaluasi yang valid harus menyebutkan: *berdasarkan kriteria apa* dan *mengapa kriteria itu dipilih*.

**Koneksi Vault:**
- [[ai-evaluation-framework]] — evaluasi model AI (metrik, benchmark, failure cases)
- [[threat-modeling-deepdive]] — evaluasi postur keamanan
- [[software-quality-untung-yuhana]] — evaluasi kualitas software
- [[formal-verification-deepdive]] — verifikasi formal (evaluasi tertinggi: buktikan benar/salah secara matematis)
- [[pentest-simulation-report]] — evaluasi hasil pentest

---

### Level 6: CREATE — Menciptakan

**Definisi Revised:** Menyatukan elemen-elemen untuk membentuk sesuatu yang **baru dan koheren**, atau membuat produk original.

**Create ≠ Synthesis.** Synthesis hanya menggabungkan bagian jadi keseluruhan. **Create** lebih luas — melibatkan **generasi ide baru**, **perencanaan**, dan **produksi**. Ini puncak taksonomi.

**Tiga Sub-kategori:**
- **Generate** — memunculkan hipotesis atau alternatif berdasarkan kriteria (divergent thinking)
- **Plan** — mendesain metode, strategi, atau prosedur untuk menyelesaikan tugas
- **Produce** — mengeksekusi rencana, membangun produk nyata

**Kata Kerja:** *Generate, Plan, Produce, Design, Construct, Develop, Create, Invent, Formulate, Author, Build, Assemble, Devise, Compose, Propose*

**Contoh:**

| Bidang | Create — Contoh Soal |
|--------|--------------------|
| Security | "Rancang detection rule untuk serangan zero-day yang memanfaatkan WebSocket untuk C2" |
| Architecture | "Desain arsitektur WAF untuk 10k RPS dengan latency < 1ms" |
| Engineering | "Bangun tool otomatis yang nge-scan S3 bucket misconfiguration" |
| Research | "Formulasikan hipotesis baru: bagaimana side-channel attack bisa dilakukan via CPU cache di cloud shared tenant?" |
| DevOps | "Buat CI/CD pipeline yang integrate SAST + DAST + SBOM generation" |

**Create dalam Konteks Vault:**

Dari catatan-catatan di vault, level Create adalah tempat lo beroperasi ketika:

```
Catatan di vault level Remember → Proyek/Riset level Create
────────────────────────────────────────────────────────
waf-reverse-proxy-deepdive (Understand) → waf (Create — bangun WAF sendiri)
malware-analysis-playbook (Analyze) → detection rules baru (Create)
postgresql-admin-backup (Apply) → backup automation script (Create)
threat-hunting-methodology (Evaluate) → hunting playbook baru (Create)
```

**Mengapa Create di Puncak?** Karena Create mensyaratkan semua level di bawahnya:
1. Lo harus **Remember** tool apa yang ada
2. Lo harus **Understand** bagaimana tool itu bekerja
3. Lo harus **Apply** tool ke situasi nyata
4. Lo harus **Analyze** apa yang kurang dari tool existing
5. Lo harus **Evaluate** pendekatan mana yang paling sesuai
6. Baru lo bisa **Create** solusi baru

**Koneksi Vault:**
- Seluruh proyek WAF (WAF development plan (privat) — roadmap & dokumentasi privat di proyek)
- [[architectural-flaw-detection]] — mendeteksi flaw untuk kemudian create fix
- [[autonomous-system-design]] — merancang sistem otonom
- [[multi-agent-orchestration-patterns]] — create orchestration patterns
- [[cognitive-architecture-engineering]] — create arsitektur kognitif

---

## Aplikasi Praktis: Instructional Design & Assessment

### Bloom's Taxonomy untuk Merancang Tujuan Pembelajaran

Formula standar untuk menulis **learning objective** yang selaras dengan Bloom:

```
[Audience] akan mampu [Verb Bloom] + [Objek] + [Konteks/Kriteria]
```

**Contoh:**

| Verb Bloom | Objek | Konteks/Kriteria | Knowledge Dim |
|------------|-------|-------------------|---------------|
| Remember | 7 layer OSI | tanpa melihat catatan | Factual |
| Understand | perbedaan SQLi dan NoSQL injection | dalam 2 paragraf | Conceptual |
| Apply | prosedur incident response | pada kasus ransomware simulation | Procedural |
| Analyze | packet capture | untuk mengidentifikasi fase exfiltration | Procedural |
| Evaluate | efektivitas WAF rule | berdasarkan false positive rate | Conceptual |
| Create | detection playbook | untuk serangan API baru | Procedural |

### Tips Menulis Soal Berdasarkan Level

| Level | Format Soal yang Efektif | Format yang Kurang Efektif |
|-------|------------------------|---------------------------|
| Remember | Pilihan ganda (recognize), isian singkat (recall) | Esai panjang (wasting time) |
| Understand | Jawab singkat — "jelaskan dengan kata sendiri", mind map, analogi | Soal dengan kata persis dari buku teks |
| Apply | Problem set, lab praktikum, studi kasus dengan tool nyata | Soal teori yang ditanya ulang |
| Analyze | Studi kasus dengan data mentah, perbandingan dua pendekatan | Soal dengan satu jawaban benar |
| Evaluate | Review produk, code review, threat model evaluation, prioritasi tool | Soal subjective tanpa kriteria |
| Create | Proyek akhir, build tool, design architecture, write detection rule | Soal yang cuma suruh "sebutkan ide" tanpa eksekusi |

### Bloom's sebagai Alat Evaluasi Kurikulum

Cara cepat evaluasi apakah suatu kursus/modul sudah balanced:

1. **Kumpulkan semua learning objectives** dari kursus
2. **Petakan ke level Bloom** (Remember → Create)
3. **Petakan ke Knowledge Dimension** (Factual → Metacognitive)
4. **Visualisasikan distribusinya**

```python
# Pseudocode: Bloom level distribution analysis
objectives = [
    ("Sebutkan 3 jenis serangan web",  "Remember",  "Factual"),
    ("Jelaskan cara kerja SQL injection", "Understand", "Conceptual"),
    ("Gunakan sqlmap untuk testing",   "Apply",     "Procedural"),
    ("Analisis log WAF",               "Analyze",   "Procedural"),
    ("Evaluasi efektivitas firewall",  "Evaluate",  "Conceptual"),
    ("Rancang detection playbook",     "Create",    "Procedural"),
]

# Distribusi ideal (menurut Krathwohl, 2002)
# Remember: 10-15%, Understand: 15-20%, Apply: 20-25%
# Analyze: 20-25%, Evaluate: 15-20%, Create: 10-15%
```

**Red flag:** Kalau 80% objectives ada di Remember/Understand — itu **recall-heavy curriculum**. Siswa bisa lulus tanpa pernah Apply, Analyze, Evaluate, atau Create. Ini masalah kronis di banyak pendidikan formal.

### Contoh Mapping: Vault Content by Bloom Level

| Bloom Level | Vault Notes |
|-------------|-------------|
| **Remember** | [[picoctf-section-1-onboarding]], [[regular-expressions-deepdive]] (bagian terminologi), [[cheatsheet]] |
| **Understand** | [[http-protocol-deepdive]], [[networking-fundamentals-tcpip-bgp]], [[tls-ssl-deepdive]], [[browser-engine-architecture]] |
| **Apply** | [[postgresql-admin-backup]], [[podman-networking-ufw]], [[cicd-guide]], [[picoctf-section-4-python-automation]] |
| **Analyze** | [[malware-analysis-reverse-engineering-playbook]], [[threat-hunting-methodology]], [[siem-security-data-lake-architecture]], [[blueteam-detection-matrix]] |
| **Evaluate** | [[ai-evaluation-framework]], [[threat-modeling-deepdive]], [[software-quality-untung-yuhana]], [[pentest-simulation-report]] |
| **Create** | Proyek WAF (WAF development plan (privat) → docs privat), [[autonomous-system-design]], [[cognitive-architecture-engineering]] |

---

## Bloom's Taxonomy di Era AI & Computational Thinking

### Bloom's + Computational Thinking

Computational Thinking (CT) — dekomposisi, pattern recognition, abstraksi, algoritma — bisa dipetakan langsung ke Bloom:

| CT Skill | Bloom Level | Contoh |
|----------|-------------|--------|
| **Dekomposisi** (memecah masalah) | Analyze | Memecah arsitektur monolith jadi microservices |
| **Pattern Recognition** | Understand → Analyze | Mengenali pola serangan SQLi dari variasi payload |
| **Abstraksi** (memfilter detail irrelevant) | Analyze → Evaluate | Membuat model threat yang cuma fokus ke attack surface relevan |
| **Algorithm Design** | Create | Merancang algoritma rate limiting untuk WAF |

### AI Alignment: Taksonomi untuk Mengevaluasi Kemampuan AI

Salah satu aplikasi modern Bloom adalah **mengevaluasi Large Language Models**. Pertanyaan kritis:

> **"Di level Bloom mana sebenarnya AI beroperasi?"**

| Tugas AI | Level Bloom | Analisis |
|----------|-------------|----------|
| Menjawab fakta (capital of France) | **Remember** | Retrieval dari training data — mirip recall |
| Meringkas artikel | **Understand** | Interpretasi dan summarization |
| Menulis kode dari spesifikasi | **Apply** | Menerapkan pola ke situasi baru |
| Mendeteksi bias dalam teks | **Analyze** | Differentiate, attribute |
| Membandingkan dua arsitektur ML | **Evaluate** | Critique, justify |
| Menulis novel orisinal | **Create**? | Debatable — seberapa "orisinal" output LLM? |

**Perdebatan:**
- **Pro:** LLM bisa lulus beberapa benchmark di level Apply bahkan Analyze — Generate code, detect vulnerabilities
- **Kontra:** LLM tidak benar-benar "memahami" — mereka melakukan pattern matching canggih tanpa kesadaran. **Metacognition** (Knowledge Dimension D) masih sangat lemah
- **Consensus:** LLM kuat di Remember → Apply, mulai menembus Analyze → Evaluate untuk domain terbatas, tapi **Create** masih diperdebatkan karena kurangnya intentionality

**Lihat juga:** [[ai-evaluation-framework]] — framework evaluasi AI yang menggunakan prinsip taksonomi.

### Bloom's untuk Prompt Engineering

Prompt yang dirancang dengan sadar Bloom level akan menghasilkan output yang lebih terarah:

| Level | Prompt Style | Contoh |
|-------|--------------|--------|
| Remember | "Sebutkan..." | "Sebutkan 5 port default yang sering dipakai attacker" |
| Understand | "Jelaskan..." | "Jelaskan cara kerja ARP spoofing dalam 2 paragraf" |
| Apply | "Gunakan X untuk..." | "Gunakan teknik ini untuk mendeteksi ARP spoof dalam network 192.168.1.0/24" |
| Analyze | "Bandingkan..." | "Bandingkan metode deteksi ARP spoof via DHCP snooping vs dynamic ARP inspection" |
| Evaluate | "Evaluasi..." | "Evaluasi efektivitas ketiga mitigasi ARP spoof ini untuk jaringan IoT skala besar" |
| Create | "Rancang..." | "Rancang sistem deteksi yang menggabungkan passive monitoring dan active probing" |

### Bloom's Taxonomy dan Self-Directed Learning

Untuk pembelajar mandiri (seperti pembaca vault ini), Bloom bisa jadi **alat diagnosis diri**:

```
Di level mana saya beroperasi untuk topik ini?
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Remember ☐ → Saya bisa hafal definisi              │
│  Understand ☐ → Saya bisa jelaskan ke orang lain    │
│  Apply ☐ → Saya bisa pake tool/konsep               │
│  Analyze ☐ → Saya bisa bedah dan bandingkan         │
│  Evaluate ☐ → Saya bisa nilai mana yang lebih baik  │
│  Create ☐ → Saya bisa buat sesuatu yang baru        │
│                                                     │
│  Target: Setidaknya Apply untuk skill teknis,       │
│  Evaluate→Create untuk mastery                      │
└─────────────────────────────────────────────────────┘
```

**Strategi:**
- Kalau masih di Remember → baca ulang, buat flashcard
- Kalau sudah di Understand → coba Feynman Technique, ajarin ke orang lain
- Kalau sudah di Apply → cari project praktis
- Kalau sudah di Analyze → lakukan comparative analysis 2+ pendekatan
- Kalau sudah di Evaluate → review karya orang lain dengan kriteria eksplisit
- Target Create → bangun sesuatu, open source, tulis artikel

---

## Kritik & Keterbatasan

### 1. Hierarki Tidak Sepenuhnya Linear

Kritik paling umum: **tidak semua learning task mengikuti hierarki linear**. Contoh:
- Lo bisa **Evaluate** kualitas kode orang lain (level 5) tanpa bisa **Create** level yang sama (level 6)
- Lo bisa **Apply** prosedur (level 3) tanpa **Understand** teorinya (level 2) — ini disebut *procedural knowledge without conceptual understanding*

Revised Taxonomy menjawab sebagian dengan knowledge dimension, tapi tetap ada tumpang tindih.

### 2. Konteks Sangat Mempengaruhi Level

Satu task bisa berada di level berbeda tergantung konteks:
- "Gunakan sqlmap" → **Apply** kalau lo sudah familiar
- "Gunakan sqlmap" → **Remember** kalau lo cuma ikutin tutorial langkah demi langkah
- "Gunakan sqlmap untuk SQLi detection" → bisa **Analyze** kalau lo harus interpretasi hasil

Bloom tidak mengakomodasi **konteks dan pengalaman sebelumnya**.

### 3. Sulit Diterapkan ke Domain Non-Akademik

Bloom dikembangkan dari konteks pendidikan formal Amerika 1950-an. Beberapa kritik:
- **Bias verbal/linguistik** — terlalu fokus pada bahasa dan ekspresi verbal
- **Bias kognitif Barat** — kurang akomodatif pada gaya belajar non-Barat
- **Kurang aplikatif untuk skill fisik** — Psychomotor domain kurang berkembang
- **Team-based learning** — Bloom fokus ke individu, padahal banyak learning terjadi kolaboratif

### 4. Miskonsepsi Umum

| Miskonsepsi | Kebenaran |
|-------------|-----------|
| "Higher level = lebih penting" | Remember dan Understand adalah fondasi yang sama pentingnya |
| "Semua pembelajaran harus capai Create" | Tidak semua topik perlu Create — kadang Apply atau Evaluate sudah cukup |
| "Bloom adalah urutan mengajar" | Bloom untuk **assessment**, bukan urutan instruksional |
| "Soal Analyze harus lebih susah dari Apply" | Belum tentu — tergantung konten dan konteks |
| "Taksonomi hanya untuk guru" | Berguna juga untuk self-directed learning, curriculum design, AI eval |

### 5. Relevansi di 2026

Beberapa kritikus berargumen bahwa Bloom sudah **outdated** di era AI dan information overload:
- Memori faktual (Remember) jadi kurang relevan karena Google/LLM bisa menjawab instan
- Keterampilan baru seperti **AI literacy**, **prompt engineering**, **information filtration** tidak tertampung di Bloom

**Counter-argument:** Bloom justru makin relevan — karena Remember bisa didelegasikan ke AI, fokus manusia bergeser ke Analyze → Evaluate → Create. Lihat bagian [[#Bloom's Taxonomy di Era AI & Computational Thinking]].

---

## Koneksi ke Vault

### Prasyarat (baca dulu)
- [[15-types-of-thinking]] — konsep metakognitif yang jadi Knowledge Dimension D
- [[computer-science-foundations]] — pengetahuan faktual yang harus di-Remember

### Related Notes (baca setelahnya untuk deepening)
- [[curriculum-mapping]] — pemetaan kurikulum dengan Bloom sebagai kerangka
- [[ai-evaluation-framework]] — evaluasi AI menggunakan prinsip taksonomi
- [[cognitive-architecture-engineering]] — rekayasa arsitektur kognitif
- [[research-methodology]] — level sintesis/evaluasi dalam metodologi riset
- [[formal-verification-deepdive]] — verifikasi sebagai Evaluate level tertinggi

### Catatan Praktis di Setiap Level

| Bloom Level | Praktik di Vault |
|-------------|------------------|
| 📝 **Remember** | [[application]] (cheatsheet), [[cheatsheet]] |
| 📖 **Understand** | [[http-protocol-deepdive]], [[tls-ssl-deepdive]], [[browser-engine-architecture]] |
| 🎯 **Apply** | [[postgresql-admin-backup]], [[podman-networking-ufw]], [[cicd-guide]] |
| 🔬 **Analyze** | [[blueteam-detection-matrix]], [[malware-analysis-reverse-engineering-playbook]] |
| 🏗️ **Evaluate** | [[ai-evaluation-framework]], [[architectural-flaw-detection]], [[pentest-simulation-report]] |
| 🛠️ **Create** | WAF development plan (privat) → implementasi privat (proyek real), [[autonomous-system-design]] |

---

## References

### Primary Sources
1. Bloom, B. S. (1956). *Taxonomy of Educational Objectives: Handbook I, Cognitive Domain*. New York: David McKay.
2. Anderson, L. W. & Krathwohl, D. R. (2001). *A Taxonomy for Learning, Teaching, and Assessing: A Revision of Bloom's Taxonomy of Educational Objectives*. New York: Longman.

### Academic Papers
3. Krathwohl, D. R. (2002). "A Revision of Bloom's Taxonomy: An Overview." *Theory Into Practice*, 41(4), 212-218.
4. Forehand, M. (2010). "Bloom's Taxonomy: Original and Revised." In M. Orey (Ed.), *Emerging Perspectives on Learning, Teaching, and Technology*.
5. Airasian, P. W. & Miranda, H. (2002). "The Role of Assessment in the Revised Taxonomy." *Theory Into Practice*, 41(4), 249-254.

### AI & Taksonomi
6. Kaddoura, S. et al. (2024). "Evaluating LLM Performance Using Bloom's Taxonomy." *Journal of AI in Education*.
7. Sarsa, S. et al. (2022). "Automatic Generation of Learning Objectives Using Bloom's Taxonomy and Large Language Models." *International Conference on AI in Education*.

### Computational Thinking
8. Wing, J. M. (2006). "Computational Thinking." *Communications of the ACM*, 49(3), 33-35.
9. Grover, S. & Pea, R. (2013). "Computational Thinking in K-12: A Review of the State of the Field." *Educational Researcher*, 42(1), 38-43.

### Kritis terhadap Taksonomi
10. Furst, E. J. (1981). "Bloom's Taxonomy of Educational Objectives for the Cognitive Domain: Philosophical and Educational Issues." *Review of Educational Research*, 51(4), 441-453.
11. Paul, R. (1993). *Critical Thinking: What Every Person Needs to Survive in a Rapidly Changing World*. Foundation for Critical Thinking.

---

> [!info] Tentang Dokumen Ini
> Dokumen ini ditulis sebagai fondasi pendidikan dan kognitif untuk seluruh vault. Bloom's Taxonomy bukan cuma alat grading — tapi kerangka untuk memahami **bagaimana learning terjadi** dan **di mana level penguasaan lo** terhadap suatu topik. Di vault yang isinya dari Remember (picoCTF basics) sampai Create (WAF build), kerangka ini bantu lo sadar: *"Gw di level mana sekarang, dan harus apa untuk naik level?"*
